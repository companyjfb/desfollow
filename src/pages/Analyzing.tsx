import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Search, Users, Zap, CheckCircle } from 'lucide-react';
import { startScan, pollScan } from '../utils/ghosts';
import { useScanCache } from '../hooks/use-scan-cache';
import { useToast } from "@/hooks/use-toast";
import { useUrlParams } from '../hooks/use-url-params';

interface ScanStatus {
  status: 'queued' | 'running' | 'done' | 'error';
  count?: number;
  sample?: string[];
  all?: string[];
  ghosts_details?: any[];
  real_ghosts?: any[];
  famous_ghosts?: any[];
  real_ghosts_count?: number;
  famous_ghosts_count?: number;
  profile_info?: any;
  error?: string;
}

const Analyzing = () => {
  const { username } = useParams<{ username: string }>();
  const navigate = useNavigate();
  const { getCachedOrFetchScan, saveScanToCache } = useScanCache();
  const { toast } = useToast();
  const { buildUrlWithParams, debugParams } = useUrlParams();
  const [progress, setProgress] = useState(0);
  const [currentStep, setCurrentStep] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [scanStatus, setScanStatus] = useState<ScanStatus | null>(null);
  const [simulatedParasites, setSimulatedParasites] = useState(0);
  const [simulatedFollowers, setSimulatedFollowers] = useState(0);
  const [realFollowersCount, setRealFollowersCount] = useState(0); // Começa com 0, será atualizado com valor real
  const [realParasitesCount, setRealParasitesCount] = useState(0);

  const steps = [
    {
      icon: Search, 
      title: "Conectando ao Instagram",
      description: "Acessando dados públicos do perfil @" + username,
      color: "from-blue-500 to-purple-500"
    },
    {
      icon: Users, 
      title: "Analisando seguidores",
      description: "Escaneando lista de seguidores e seguindo",
      color: "from-purple-500 to-pink-500"
    },
    {
      icon: Zap, 
      title: "Processando dados",
      description: "IA comparando listas e identificando parasitas",
      color: "from-pink-500 to-orange-500"
    },
    {
      icon: CheckCircle, 
      title: "Finalizando análise", 
      description: "Preparando relatório completo",
      color: "from-orange-500 to-red-500"
    }
  ];

  useEffect(() => {
    if (!username) {
      navigate('/');
      return;
    }

    const runAnalysis = async () => {
      try {
        console.log('🔍 Verificando dados existentes antes de iniciar scan...');
        
        // Verificar se já temos dados em cache ou banco
        const existingScanData = await getCachedOrFetchScan(username);
        
        if (existingScanData) {
          console.log('✅ Dados encontrados! Redirecionando para resultados...');
          
          // Preservar parâmetros UTM ao navegar para resultados
          const resultsUrl = buildUrlWithParams(`/results/${username}`);
          debugParams();
          console.log('🔗 Navegando para RESULTADOS com parâmetros preservados:', resultsUrl);
          
          navigate(resultsUrl, { 
            state: { 
              scanData: existingScanData,
              username: username,
              fromCache: true
            } 
          });
          return;
        }
        
        console.log('📭 Nenhum dado encontrado. Iniciando novo scan...');
        
        // Marca o tempo de início globalmente
        (window as any).scanStartTime = Date.now();
        console.log('🚀 Scan iniciado em:', new Date().toISOString());
        
        // Inicia o scan
        const jobId = await startScan(username);
        console.log('Job iniciado:', jobId);
        
        // Progresso baseado no tempo - chega a 90% em 5 minutos
        const startTime = Date.now();
        const duration = 300000; // 5 minutos (300 segundos) para chegar a 90%
        const targetProgress = 90;
        
        const progressInterval = setInterval(() => {
          const elapsed = Date.now() - startTime;
          const progressPercent = Math.min((elapsed / duration) * targetProgress, targetProgress);
          
          // Usa Math.floor para evitar decimais e NUNCA diminui
          const currentProgress = Math.floor(progressPercent);
          setProgress(prev => Math.max(prev, currentProgress)); // Nunca diminui
        }, 200); // Atualiza a cada 200ms para movimento mais suave
        
        // Polling do status com backoff progressivo
        let attempts = 0;
        const maxAttempts = 120; // 10 minutos máximo
        
        const getPollingInterval = (attempt: number) => {
          // 🔧 Polling otimizado: máximo 1 requisição a cada 10 segundos
          return 10000; // Sempre 10 segundos
        };
        
        const pollWithBackoff = async () => {
          try {
            attempts++;
            
            // Fazer polling
            const status = await pollScan(jobId.job_id);
            setScanStatus(status);
            
            // Log mais detalhado para debug
            console.log(`🔄 [${attempts}] Status: ${status.status}, Profile: ${status.profile_info?.followers_count || 0} seguidores, Count: ${status.count || 0}`);
            console.log(`🔍 [${attempts}] Profile Info:`, status.profile_info);
            console.log(`🔍 [${attempts}] Followers Count no status:`, status.followers_count);
            console.log(`🔍 [${attempts}] Following Count no status:`, status.following_count);
            
            if (status.status === 'running') {
              // Capturar dados do perfil assim que chegarem
              if (status.profile_info?.followers_count && !realFollowersCount) {
                console.log('🎯 Dados do perfil detectados:', status.profile_info.followers_count);
                setRealFollowersCount(status.profile_info.followers_count);
              }
              
              // Continuar polling com backoff
              if (attempts < maxAttempts) {
                const interval = getPollingInterval(attempts);
                setTimeout(pollWithBackoff, interval);
              }
            } else if (status.status === 'done') {
              setProgress(100);
              setCurrentStep(3);
              clearInterval(progressInterval);
              
              // Verifica se os dados do perfil chegaram (mesmo que seja no final)
              if (status.profile_info?.followers_count && !realFollowersCount) {
                console.log('🎯 Dados do perfil detectados no final:', status.profile_info.followers_count);
                setRealFollowersCount(status.profile_info.followers_count);
              }
              
              // Salvar dados completos no cache
              console.log('💾 Salvando dados do scan no cache...');
              saveScanToCache(username, status);
              
              // Aguarda pelo menos 5 segundos em "Finalizando análise"
              setTimeout(() => {
                // Preservar TODOS os parâmetros UTM na navegação para results
                const resultsUrl = buildUrlWithParams(`/results/${username}`);
                debugParams();
                console.log('🔗 Navegando para RESULTADOS FINAIS com parâmetros preservados:', resultsUrl);
                
                navigate(resultsUrl, { 
                  state: { 
                    scanData: status,
                    username: username 
                  } 
                });
              }, 5000); // Mínimo 5 segundos na etapa final
              
            } else if (status.status === 'error') {
              const errorMessage = status.error || 'Erro desconhecido';
              
              // Verificar se é erro de perfil privado
              if (errorMessage.toLowerCase().includes('privado')) {
                toast({
                  title: "🔒 Perfil Privado Detectado",
                  description: "Não é possível analisar contas privadas. Por favor, torne seu perfil público temporariamente para realizar a análise.",
                  duration: 10000,
                  variant: "destructive"
                });
              }
              
              setError(errorMessage);
              setProgress(0);
              clearInterval(progressInterval);
            }
          } catch (err) {
            console.error('Erro ao verificar status:', err);
            if (attempts >= maxAttempts) {
              setError('Tempo limite excedido. Tente novamente.');
              setProgress(0);
              clearInterval(progressInterval);
            } else {
              // Tentar novamente com backoff em caso de erro
              const interval = getPollingInterval(attempts);
              setTimeout(pollWithBackoff, interval);
            }
          }
        };
        
        // Iniciar polling
        pollWithBackoff();
        
        return () => {
          clearInterval(progressInterval);
        };
        
      } catch (err) {
        console.error('Erro ao iniciar scan:', err);
        setError('Erro ao conectar com o servidor. Verifique sua conexão.');
        setProgress(0);
      }
    };

    runAnalysis();
  }, [username]); // 🚀 CORREÇÃO: Removidas dependências que causam loop infinito

  // Captura dados do perfil assim que chegarem - PRIORIDADE MÁXIMA
  useEffect(() => {
    console.log('🔍 Verificando dados do perfil:', scanStatus?.profile_info);
    console.log('🔍 Status atual:', scanStatus?.status);
    console.log('🔍 realFollowersCount atual:', realFollowersCount);
    
    if (scanStatus?.profile_info?.followers_count) {
      const realFollowers = scanStatus.profile_info.followers_count;
      console.log('🚨 PRIORIDADE MÁXIMA: Dados do perfil recebidos!');
      console.log('📊 Seguidores obtidos:', realFollowers);
      console.log('🎯 Status atual:', scanStatus.status);
      console.log('⏱️ Tempo desde início:', Date.now() - (window as any).scanStartTime || 0, 'ms');
      
      // FORÇA atualização sempre que dados chegarem
      console.log('🔄 FORÇANDO atualização de realFollowersCount para:', realFollowers);
      setRealFollowersCount(realFollowers);
    }
    
    // NOTA: Parasitas são capturados em um useEffect separado para evitar conflitos
  }, [scanStatus?.profile_info?.followers_count, scanStatus?.status]);

  // Debug: log sempre que scanStatus mudar
  useEffect(() => {
    console.log('📊 ScanStatus mudou:', {
      status: scanStatus?.status,
      profile_info: scanStatus?.profile_info,
      followers_count: scanStatus?.profile_info?.followers_count,
      count: scanStatus?.count
    });
  }, [scanStatus]);

  // Controla os números simulados - PRIORIDADE MÁXIMA
  useEffect(() => {
    console.log('🔄 useEffect da contagem EXECUTADO! realFollowersCount:', realFollowersCount);
    
    // Só inicia a contagem se temos o valor real de seguidores
    if (realFollowersCount <= 0) {
      console.log('⏳ Aguardando dados do perfil... realFollowersCount:', realFollowersCount);
      return;
    }
    
    console.log('🚀 INICIANDO CONTAGEM SIMULADA com', realFollowersCount, 'seguidores');
    console.log('⏱️ Tempo desde início:', Date.now() - ((window as any).scanStartTime || 0), 'ms');
    console.log('🎯 Status atual do scan:', scanStatus?.status);
    console.log('🎯 Scan data completo:', scanStatus);
    
    const startTime = Date.now();
    const duration = 210000; // 3 minutos e 30 segundos total (2 min analisando + 1.5 min processando)
    const delayBeforeParasites = 120000; // 2 minutos de delay para parasitas (só na fase de processamento)
    
    // INICIAR CONTAGEM IMEDIATAMENTE
    console.log('🎯 INICIANDO contagem IMEDIATAMENTE!');
    setSimulatedFollowers(1); // Começar com 1 para mostrar que iniciou
    
    const numbersInterval = setInterval(() => {
      const elapsed = Date.now() - startTime;
      
      // Contagem de seguidores: crescimento gradual até valor real em 5 minutos
      const countingDuration = 300000; // 5 minutos total para chegar ao valor real
      const countingProgress = Math.min(elapsed / countingDuration, 1);
      const currentFollowers = Math.max(1, Math.floor(countingProgress * realFollowersCount)); // Mínimo 1
      
      setSimulatedFollowers(currentFollowers);
      
      // Parasitas: só começam na fase de processamento (após 2min10s)
      if (elapsed < 130000) {
        setSimulatedParasites(0);
      } else {
        const parasitesElapsed = elapsed - 130000;
        const parasitesDuration = 90000; // 1.5 minutos para processar
        const parasitesProgress = Math.min(parasitesElapsed / parasitesDuration, 1);
        
        // 🎯 SIMULAÇÃO: Simula até 126 parasitas (valor real será usado no final)
        const targetParasites = 126;
        const currentParasites = Math.floor(parasitesProgress * targetParasites);
        setSimulatedParasites(currentParasites);
      }
      
      // Log menos frequente para não sobrecarregar
      if (Math.floor(elapsed / 1000) % 5 === 0) { // A cada 5 segundos
        console.log('📈 Contagem (a cada 5s):', { 
          elapsed: Math.floor(elapsed/1000) + 's', 
          followers: currentFollowers, 
          parasites: elapsed < 130000 ? 0 : Math.floor((elapsed - 130000) / 90000 * 126),
          progress: `${Math.floor(countingProgress * 100)}%`,
          realFollowersCount
        });
      }
      
      if (elapsed >= countingDuration) {
        clearInterval(numbersInterval);
        console.log('✅ Contagem simulada finalizada');
      }
    }, 100); // Atualiza a cada 100ms

    return () => clearInterval(numbersInterval);
  }, [realFollowersCount]); // REMOVIDO scanStatus?.status para evitar reinicialização

  // Atualiza apenas os parasitas quando o scan terminar (sem afetar seguidores)
  useEffect(() => {
    if (scanStatus?.status === 'done' && scanStatus?.count !== undefined) {
      const realParasites = scanStatus.count;
      console.log('🎯 Scan terminou: Atualizando parasitas para valor real:', realParasites);
      console.log('📊 Seguidores mantidos em:', simulatedFollowers);
      
      setRealParasitesCount(realParasites);
      setSimulatedParasites(realParasites);
      
      // NÃO altera os seguidores - mantém o valor final da contagem
      console.log('✅ Parasitas atualizados, seguidores mantidos!');
    }
  }, [scanStatus?.status, scanStatus?.count, simulatedFollowers]);

  // Fallback para progresso simulado se não houver status real
  useEffect(() => {
    if (!scanStatus) {
      // Progresso baseado no tempo - chega a 90% em 5 minutos
      const startTime = Date.now();
      const duration = 300000; // 5 minutos (300 segundos) para chegar a 90%
      const targetProgress = 90;
      
      const interval = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const progressPercent = Math.min((elapsed / duration) * targetProgress, targetProgress);
        
        // Usa Math.floor para evitar decimais e NUNCA diminui
        const currentProgress = Math.floor(progressPercent);
        setProgress(prev => Math.max(prev, currentProgress)); // Nunca diminui
        
        if (progressPercent >= targetProgress) {
          clearInterval(interval);
          
          // Quando chega a 90%, vai para 100% (sem interferir na contagem)
          setTimeout(() => {
            setProgress(100);
          }, 1000);
        }
      }, 200); // Atualiza a cada 200ms para movimento mais suave

      return () => clearInterval(interval);
    }
  }, [scanStatus]); // Remove realFollowersCount da dependência

  // Sistema de etapas com tempos específicos
  useEffect(() => {
    const startTime = Date.now();
    
    const stepInterval = setInterval(() => {
      const elapsed = Date.now() - startTime;
      
      // Tempos específicos para cada etapa:
      // 0-10s: Conectando ao Instagram
      // 10s-2m10s: Analisando seguidores (2 minutos)
      // 2m10s-3m40s: Processando dados (1 minuto e 30 segundos)
      // 3m40s+: Finalizando análise (até scan terminar, mínimo 5s)
      
      if (elapsed < 10000) {
        setCurrentStep(0); // Conectando ao Instagram
      } else if (elapsed < 130000) { // 10s + 2min = 130s
        setCurrentStep(1); // Analisando seguidores
      } else if (elapsed < 220000) { // 130s + 1.5min = 220s
        setCurrentStep(2); // Processando dados
      } else {
        setCurrentStep(3); // Finalizando análise
      }
      
      // Se o scan terminou, força para etapa final
      if (scanStatus?.status === 'done') {
        setCurrentStep(3);
        clearInterval(stepInterval);
      }
    }, 1000); // Verifica a cada segundo

    return () => clearInterval(stepInterval);
  }, [scanStatus?.status]);



  // Se houver erro, mostra mensagem de erro
  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-instagram-blue via-blue-600 to-purple-800 flex items-center justify-center p-4">
        <div className="max-w-md w-full">
          <div className="bg-white/10 backdrop-blur-md rounded-2xl p-8 border border-white/20 shadow-2xl">
            <div className="text-center">
              <div className="text-6xl mb-4">❌</div>
              <h2 className="text-xl font-bold text-white mb-2">Erro na Análise</h2>
              <p className="text-white/80 text-sm mb-6">{error}</p>
              <button 
                onClick={() => window.location.href = '/'}
                className="px-6 py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-colors"
              >
                Tentar Novamente
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-instagram-blue via-blue-600 to-purple-800 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        <div className="bg-white/10 backdrop-blur-md rounded-2xl p-8 border border-white/20 shadow-2xl">
          
          {/* Header */}
          <div className="text-center mb-8">
            <div className="flex items-center justify-center mb-4">
              <img src="/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png" alt="Desfollow Logo" className="w-10 h-10 mr-3" />
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 bg-clip-text text-transparent">Desfollow</h1>
            </div>
            <h2 className="text-xl font-bold text-white mb-2">Analisando @{username}</h2>
            <p className="text-white/80 text-sm mb-4">Aguarde enquanto nossa IA faz a varredura</p>
            
            {/* Aviso importante */}
            <div className="bg-orange-500/20 border border-orange-500/40 rounded-xl p-4 mb-4 max-w-sm mx-auto">
              <div className="flex items-center justify-center mb-2">
                <div className="w-2 h-2 bg-orange-500 rounded-full mr-2 animate-pulse"></div>
                <span className="text-orange-300 font-bold text-xs">IMPORTANTE</span>
              </div>
              <p className="text-white/90 text-xs leading-relaxed" style={{ fontSize: '11px !important' }}>
                A análise pode demorar entre <span className="font-bold text-orange-300">3-5 minutos</span>.<br/>
                <span className="font-bold">Não feche esta página</span> para não interromper o processo.
              </p>
            </div>
          </div>

          {/* Progress Bar */}
          <div className="mb-8">
            <div className="bg-white/20 rounded-full h-3 mb-2">
              <div 
                className="bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 h-3 rounded-full transition-all duration-300 ease-out"
                style={{ width: `${progress}%` }}
              ></div>
            </div>
            <div className="text-center text-white font-bold text-lg">{progress}%</div>
          </div>

          {/* Current Step */}
          <div className="space-y-6">
            {steps.map((step, index) => {
              const Icon = step.icon;
              const isActive = index === currentStep;
              const isCompleted = index < currentStep;
              
              return (
                <div 
                  key={index}
                  className={`flex items-center space-x-4 p-3 rounded-xl transition-all duration-500 ${
                    isActive ? 'bg-white/20 scale-105' : 'bg-white/5'
                  }`}
                >
                  <div className={`p-3 rounded-xl ${
                    isActive ? `bg-gradient-to-r ${step.color}` : 
                    isCompleted ? 'bg-green-500' : 'bg-white/10'
                  }`}>
                    <Icon className={`w-5 h-5 ${
                      isActive || isCompleted ? 'text-white' : 'text-white/50'
                    }`} />
                  </div>
                  <div className="flex-1">
                    <h3 className={`font-semibold ${
                      isActive ? 'text-white' : 'text-white/70'
                    }`}>{step.title}</h3>
                    <p className={`text-sm ${
                      isActive ? 'text-white/90' : 'text-white/50'
                    }`}>{step.description}</p>
                  </div>
                  {isCompleted && (
                    <CheckCircle className="w-5 h-5 text-green-400" />
                  )}
                </div>
              );
            })}
          </div>

          {/* Stats */}
          <div className="mt-8">
            <div className="text-center">
              <div className="text-3xl font-bold text-white">
                {simulatedFollowers.toLocaleString()}
              </div>
              <div className="text-white/70 text-sm">Seguidores analisados</div>
            </div>
            
            {/* Mostrar parasitas apenas se houver */}
            {simulatedParasites > 0 && (
              <div className="mt-4 text-center">
                <div className="text-xl font-bold text-orange-400">
                  {simulatedParasites}
                </div>
                <div className="text-white/70 text-xs">Parasitas detectados</div>
              </div>
            )}
          </div>

          {/* Loading Animation */}
          <div className="mt-8 flex justify-center">
            <div className="flex space-x-2">
              <div className="w-3 h-3 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full animate-bounce"></div>
              <div className="w-3 h-3 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
              <div className="w-3 h-3 bg-gradient-to-r from-pink-500 to-orange-500 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};

export default Analyzing;