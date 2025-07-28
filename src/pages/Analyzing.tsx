import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Search, Users, Zap, CheckCircle } from 'lucide-react';
import { startScan, pollScan } from '../utils/ghosts';

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
        // Marca o tempo de início globalmente
        (window as any).scanStartTime = Date.now();
        console.log('🚀 Scan iniciado em:', new Date().toISOString());
        
        // Inicia o scan
        const jobId = await startScan(username);
        console.log('Job iniciado:', jobId);
        
        // Progresso baseado no tempo - chega a 90% em 45 segundos
        const startTime = Date.now();
        const duration = 45000; // 45 segundos para chegar a 90%
        const targetProgress = 90;
        
        const progressInterval = setInterval(() => {
          const elapsed = Date.now() - startTime;
          const progressPercent = Math.min((elapsed / duration) * targetProgress, targetProgress);
          
          // Usa Math.floor para evitar decimais e NUNCA diminui
          const currentProgress = Math.floor(progressPercent);
          setProgress(prev => Math.max(prev, currentProgress)); // Nunca diminui
        }, 200); // Atualiza a cada 200ms para movimento mais suave
        
        // Polling do status
        let attempts = 0;
        const maxAttempts = 120; // 10 minutos máximo
        
        const pollInterval = setInterval(async () => {
          attempts++;
          
          try {
            const status = await pollScan(jobId.job_id);
            setScanStatus(status);
            
            console.log('Status recebido:', status);
            console.log('Profile info:', status.profile_info);
            console.log('Followers count:', status.profile_info?.followers_count);
            console.log('Count (parasitas):', status.count);
            console.log('⏱️ Tempo desde início:', Date.now() - ((window as any).scanStartTime || 0), 'ms');
            
            // Atualiza os steps baseado no progresso
            const currentProgress = Math.floor((Date.now() - startTime) / duration * targetProgress);
            
            if (status.status === 'queued') {
              setCurrentStep(0);
            } else if (status.status === 'running') {
              // Steps mais graduais baseados no tempo
              if (currentProgress < 25) {
                setCurrentStep(1); // Analisando seguidores
              } else if (currentProgress < 50) {
                setCurrentStep(2); // IA processando dados
              } else {
                setCurrentStep(3); // Finalizando
              }
              
              // Verifica se os dados do perfil chegaram durante o processo
              if (status.profile_info?.followers_count && !realFollowersCount) {
                console.log('🎯 Dados do perfil detectados durante running:', status.profile_info.followers_count);
                setRealFollowersCount(status.profile_info.followers_count);
              }
              
              // Verifica se os dados dos parasitas chegaram durante o processo
              if (status.count !== undefined && !realParasitesCount) {
                console.log('🎯 Dados dos parasitas detectados durante running:', status.count);
                setRealParasitesCount(status.count);
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
              

              
              // Aguarda um pouco para mostrar 100%
              setTimeout(() => {
                navigate(`/results/${username}`, { 
                  state: { 
                    scanData: status,
                    username: username 
                  } 
                });
              }, 1500);
              
              clearInterval(pollInterval);
            } else if (status.status === 'error') {
              setError(status.error || 'Erro desconhecido');
              setProgress(0);
              clearInterval(progressInterval);
              clearInterval(pollInterval);
            }
          } catch (err) {
            console.error('Erro ao verificar status:', err);
            if (attempts >= maxAttempts) {
              setError('Tempo limite excedido. Tente novamente.');
              setProgress(0);
              clearInterval(progressInterval);
              clearInterval(pollInterval);
            }
          }
        }, attempts < 50 ? 50 : 1000); // Polling ULTRA frequente nos primeiros 50 segundos (50ms)
        
        return () => {
          clearInterval(progressInterval);
          clearInterval(pollInterval);
        };
        
      } catch (err) {
        console.error('Erro ao iniciar scan:', err);
        setError('Erro ao conectar com o servidor. Verifique sua conexão.');
        setProgress(0);
      }
    };

    runAnalysis();
  }, [username, navigate]);

  // Captura dados do perfil assim que chegarem - PRIORIDADE MÁXIMA
  useEffect(() => {
    console.log('🔍 Verificando dados do perfil:', scanStatus?.profile_info);
    
    if (scanStatus?.profile_info?.followers_count) {
      const realFollowers = scanStatus.profile_info.followers_count;
      console.log('🚨 PRIORIDADE MÁXIMA: Dados do perfil recebidos!');
      console.log('📊 Seguidores obtidos:', realFollowers);
      console.log('🎯 Status atual:', scanStatus.status);
              console.log('⏱️ Tempo desde início:', Date.now() - (window as any).scanStartTime || 0, 'ms');
      
      setRealFollowersCount(realFollowers);
      
      // INICIA CONTAGEM IMEDIATAMENTE se ainda não foi iniciada
      if (simulatedFollowers === 0) {
        console.log('🚀 INICIANDO CONTAGEM DE SEGUIDORES IMEDIATAMENTE!');
        setSimulatedFollowers(realFollowers);
      }
    }
    
    // NOTA: Parasitas são capturados em um useEffect separado para evitar conflitos
  }, [scanStatus?.profile_info?.followers_count]);

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
    // Só inicia a contagem se temos o valor real de seguidores
    if (realFollowersCount <= 0) {
      console.log('⏳ Aguardando dados do perfil...');
      return;
    }
    
    console.log('🚀 INICIANDO CONTAGEM SIMULADA com', realFollowersCount, 'seguidores');
    console.log('⏱️ Tempo desde início:', Date.now() - ((window as any).scanStartTime || 0), 'ms');
    
    const startTime = Date.now();
    const duration = 30000; // 30 segundos para completar
    const delayBeforeParasites = 15000; // 15 segundos de delay para parasitas
    
    const numbersInterval = setInterval(() => {
      const elapsed = Date.now() - startTime;
      
      // Seguidores: começa a aumentar gradualmente até o valor real em 30 segundos
      const followersProgress = Math.min(elapsed / duration, 1);
      const currentFollowers = Math.floor(followersProgress * realFollowersCount);
      setSimulatedFollowers(currentFollowers);
      
      // Parasitas: só começam após 15 segundos, simulando até 22
      if (elapsed < delayBeforeParasites) {
        setSimulatedParasites(0);
      } else {
        const parasitesElapsed = elapsed - delayBeforeParasites;
        const parasitesDuration = duration - delayBeforeParasites;
        const parasitesProgress = Math.min(parasitesElapsed / parasitesDuration, 1);
        
        // Simula até 22 parasitas (valor real será usado no final)
        const targetParasites = 22;
        const currentParasites = Math.floor(parasitesProgress * targetParasites);
        setSimulatedParasites(currentParasites);
      }
      
      console.log('📈 Contagem:', { 
        elapsed: Math.floor(elapsed/1000) + 's', 
        followers: currentFollowers, 
        parasites: elapsed < delayBeforeParasites ? 0 : Math.floor((elapsed - delayBeforeParasites) / (duration - delayBeforeParasites) * 22)
      });
      
      if (elapsed >= duration) {
        clearInterval(numbersInterval);
        console.log('✅ Contagem simulada finalizada');
      }
    }, 100); // Atualiza a cada 100ms para movimento suave

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
      // Progresso baseado no tempo - chega a 90% em 45 segundos
      const startTime = Date.now();
      const duration = 45000; // 45 segundos para chegar a 90%
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

  // Fallback para steps simulado se não houver status real
  useEffect(() => {
    if (!scanStatus) {
      // Steps baseados no tempo - 1 minuto total
      const startTime = Date.now();
      const duration = 60000; // 60 segundos
      
      const stepInterval = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const progressPercent = (elapsed / duration) * 100;
        
        // Steps mais graduais
        if (progressPercent < 25) {
          setCurrentStep(0); // Conectando ao Instagram
        } else if (progressPercent < 50) {
          setCurrentStep(1); // Analisando seguidores
        } else if (progressPercent < 80) {
          setCurrentStep(2); // IA processando dados
        } else {
          setCurrentStep(3); // Finalizando
        }
        
        if (progressPercent >= 100) {
          clearInterval(stepInterval);
        }
      }, 1000); // Verifica a cada segundo

      return () => clearInterval(stepInterval);
    }
  }, [scanStatus]);



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
                onClick={() => window.location.reload()}
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
            <p className="text-white/80 text-sm">Aguarde enquanto nossa IA faz a varredura</p>
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
          <div className="mt-8 grid grid-cols-2 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-white">
                {simulatedParasites}
              </div>
              <div className="text-white/70 text-xs">Parasitas encontrados</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-white">
                {simulatedFollowers}
              </div>
              <div className="text-white/70 text-xs">Seguidores do usuário</div>
            </div>
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