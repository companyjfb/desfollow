import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { Button } from "@/components/ui/button";
import { ArrowLeft, Crown, Lock, Zap, Users, TrendingDown, AlertTriangle, Shield, CheckCircle, Star, Target, ArrowRight, ChevronLeft, ChevronRight } from 'lucide-react';
import InstagramImage from '@/components/InstagramImage';
import { StatusResponse } from '../utils/ghosts';
import { useScanCache } from '../hooks/use-scan-cache';
import { useUrlParams } from '../hooks/use-url-params';

interface GhostUser {
  username: string;
  full_name: string;
  profile_pic_url: string;
  is_private: boolean;
  is_verified: boolean;
}

interface ProfileInfo {
  username: string;
  full_name: string;
  profile_pic_url: string;
  profile_pic_url_hd: string;
  biography: string;
  is_private: boolean;
  is_verified: boolean;
  followers_count: number;
  following_count: number;
  posts_count: number;
}

interface ScanData {
  status: string;
  count: number;
  sample: string[];
  all: string[];
  ghosts_details: GhostUser[];
  real_ghosts: GhostUser[];
  famous_ghosts: GhostUser[];
  real_ghosts_count: number;
  famous_ghosts_count: number;
  followers_count: number;  // Quantos seguidores analisamos
  following_count: number;  // Quantos seguindo analisamos
  profile_followers_count: number;  // Total de seguidores do perfil
  profile_following_count: number;  // Total de seguindo do perfil
  profile_info: ProfileInfo;
}

// Componente de imagem com retry automático contínuo
const RobustImage: React.FC<{
  src: string;
  alt: string;
  className?: string;
  fallback?: string;
}> = ({ src, alt, className, fallback = '/placeholder.svg' }) => {
  return (
    <InstagramImage
      src={src}
      alt={alt}
      className={className}
      fallback={fallback}
      maxRetries={15} // Mais tentativas para imagens importantes
      retryDelay={1500} // Delay menor para retry mais ágil
    />
  );
};

const Results = () => {
  const { username } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { getCachedOrFetchScan } = useScanCache();
  const { buildUrlWithParams, buildQueryString, debugParams, preservedParams } = useUrlParams();
  
  const [scanData, setScanData] = useState<ScanData | null>(location.state?.scanData || null);
  const [isLoading, setIsLoading] = useState(false);
  const [fromCache, setFromCache] = useState(location.state?.fromCache || false);
  const [isPaidUser, setIsPaidUser] = useState(false);
  const [isCheckingPayment, setIsCheckingPayment] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [cardsPerPage] = useState(100);
  
  // Função para verificar status de assinatura
  const checkSubscriptionStatus = async (targetUsername: string) => {
    try {
      setIsCheckingPayment(true);
      const response = await fetch(`https://api.desfollow.com.br/api/subscription/check/${targetUsername}`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      
      console.log('💳 Status da assinatura:', data);
      console.log(`📅 Assinatura ativa: ${data.has_active_subscription}`);
      console.log(`📅 Dias restantes: ${data.days_remaining}`);
      console.log(`📅 Expira em: ${data.current_period_end}`);
      
      setIsPaidUser(data.has_active_subscription || false);
    } catch (error) {
      console.error('❌ Erro ao verificar assinatura:', error);
      setIsPaidUser(false);
    } finally {
      setIsCheckingPayment(false);
    }
  };
  
  // 🔍 DEBUG: Log para verificar dados
  console.log('🔍 DEBUG - Username:', username);
  console.log('🔍 DEBUG - Is Paid User:', isPaidUser);
  console.log('🔍 DEBUG - Is Checking Payment:', isCheckingPayment);
  console.log('🔍 DEBUG - Scan Data:', scanData);
  console.log('🔍 DEBUG - Real Ghosts:', scanData?.real_ghosts?.length || 0);
  console.log('🔍 DEBUG - Famous Ghosts:', scanData?.famous_ghosts?.length || 0);
  console.log('🔍 DEBUG - Total Ghosts:', scanData?.count || 0);
  
  // Verificar assinatura quando carrega a página
  useEffect(() => {
    if (username) {
      checkSubscriptionStatus(username);
    }
  }, [username]);

  // Buscar dados se não estão disponíveis no state
  useEffect(() => {
    const loadScanData = async () => {
      if (!scanData && username) {
        console.log('📭 Dados não encontrados no state. Buscando em cache/banco...');
        setIsLoading(true);
        
        try {
          const cachedData = await getCachedOrFetchScan(username);
          
          if (cachedData) {
            console.log('✅ Dados carregados do cache/banco');
            setScanData(cachedData);
            setFromCache(true);
          } else {
            console.log('📭 Nenhum dado encontrado. Redirecionando para nova análise...');
            const analyzingUrl = buildUrlWithParams(`/analyzing/${username}`);
            console.log('🔗 Redirecionando para ANÁLISE com parâmetros preservados:', analyzingUrl);
            navigate(analyzingUrl);
          }
        } catch (error) {
          console.error('❌ Erro ao carregar dados:', error);
          navigate('/');
        } finally {
          setIsLoading(false);
        }
      }
    };
    
    loadScanData();
  }, [username, scanData, navigate, getCachedOrFetchScan]);
  
  // Loading state
  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-white mx-auto mb-4"></div>
          <p className="text-white text-lg">Carregando dados...</p>
        </div>
      </div>
    );
  }
  
  // Se não tem dados, redirecionar
  if (!scanData) {
    return null; // useEffect vai redirecionar
  }
  
  // Combina pessoas reais e verificadas, priorizando pessoas reais
  const allGhosts = [];
  
  // Adiciona pessoas reais primeiro (não verificadas apenas)
  if (scanData?.real_ghosts) {
    const realNonVerified = scanData.real_ghosts.filter(user => !user.is_verified);
    allGhosts.push(...realNonVerified.map(user => ({
      ...user,
      type: 'real'
    })));
  }
  
  // Adiciona pessoas verificadas depois (incluindo de real_ghosts se verificadas)
  if (scanData?.famous_ghosts) {
    allGhosts.push(...scanData.famous_ghosts.map(user => ({
      ...user,
      type: 'verified'
    })));
  }
  
  // Adiciona verificados que estavam em real_ghosts
  if (scanData?.real_ghosts) {
    const realButVerified = scanData.real_ghosts.filter(user => user.is_verified);
    allGhosts.push(...realButVerified.map(user => ({
      ...user,
      type: 'verified'
    })));
  }
  
  // Determinar se usuário tem acesso completo - APENAS por pagamento
  const hasFullAccess = isPaidUser;
  
  // ✅ ORDEM OTIMIZADA: Primeiro reais, depois verificados
  const allProfiles = allGhosts.map(user => ({
    name: user.username,
    fullName: user.full_name,
    avatar: user.profile_pic_url || "/placeholder.svg",
    isPrivate: user.is_private,
    isVerified: user.is_verified,
    type: user.type
  }));
  
  // Para usuários sem pagamento: mostra apenas 5 primeiros + 10 bloqueados
  const freeUserProfiles = allProfiles.slice(0, 5);
  const blockedProfiles = allProfiles.slice(5, 15); // Máximo 10 bloqueados
  
  // Calcular paginação CORRIGIDA
  // Reset página quando dados mudam
  useEffect(() => {
    setCurrentPage(1);
  }, [scanData]);

  let visibleProfiles = [];
  let totalPages = 1;
  
  if (hasFullAccess) {
    // Para usuários pagos: paginação completa
    const totalProfiles = allProfiles.length;
    totalPages = Math.ceil(totalProfiles / cardsPerPage);
    const startIndex = (currentPage - 1) * cardsPerPage;
    const endIndex = startIndex + cardsPerPage;
    visibleProfiles = allProfiles.slice(startIndex, endIndex);
  } else {
    // Para usuários não pagos: apenas 5 cards, sem paginação
    visibleProfiles = freeUserProfiles;
    totalPages = 1;
  }

  // 🔍 DEBUG: Verificar dados processados e ORDENAÇÃO
  console.log('🔍 DEBUG - Real Ghosts (raw):', scanData?.real_ghosts?.length || 0);
  console.log('🔍 DEBUG - Famous Ghosts (raw):', scanData?.famous_ghosts?.length || 0);
  console.log('🔍 DEBUG - All Ghosts Length:', allGhosts.length);
  console.log('🔍 DEBUG - All Profiles Length:', allProfiles.length);
  console.log('🔍 DEBUG - Visible Profiles Length:', visibleProfiles.length);
  console.log('🔍 DEBUG - Total Pages:', totalPages);
  console.log('🔍 DEBUG - Current Page:', currentPage);
  console.log('🔍 DEBUG - Has Full Access:', hasFullAccess);
  
  // 🎯 DEBUG: Verificar ORDEM dos primeiros cards
  console.log('🎯 ORDEM DOS PRIMEIROS 10 CARDS:');
  allProfiles.slice(0, 10).forEach((profile, index) => {
    console.log(`   ${index + 1}. @${profile.name} - Tipo: ${profile.type} - Verificado: ${profile.isVerified}`);
  });
  
  // 🎯 DEBUG: Verificar se usuários não pagos veem pessoas REAIS primeiro
  if (!hasFullAccess) {
    console.log('👤 USUÁRIO NÃO PAGO - Primeiros 5 cards:');
    visibleProfiles.forEach((profile, index) => {
      console.log(`   ${index + 1}. @${profile.name} - Tipo: ${profile.type} - Verificado: ${profile.isVerified}`);
    });
  }

  // Perfis bloqueados (simulados) - apenas para usuários normais
  const blurredProfiles = Array.from({ length: 8 }, (_, i) => ({
    name: `user_${i + 1}`,
    avatar: `/lovable-uploads/${['c86c9416-e19f-4e6c-b96a-981764455220.png', 'a1ff2d2a-90ed-4aca-830b-0fa8e772a3ad.png', 'e4cc8fae-cf86-4234-83bc-7a4cbb3e3537.png'][i % 3]}`
  }));

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  // ✅ MOSTRAR VALORES REAIS (sem multiplicação falsa)
  const totalGhosts = scanData?.count || 0;
  const realGhostsCount = scanData?.real_ghosts_count || 0;
  const famousGhostsCount = scanData?.famous_ghosts_count || 0;
  const profileFollowersCount = scanData?.profile_followers_count || scanData?.profile_info?.followers_count || 0;  // Total do perfil
  const profileFollowingCount = scanData?.profile_following_count || scanData?.profile_info?.following_count || 0;  // Total do perfil

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 p-4">
      <div className="max-w-4xl mx-auto">
        
        {/* Header */}
        <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-6 border border-white/10 shadow-2xl mb-8">
          
          <div className="flex items-center justify-between mb-6">
            <Button
              onClick={() => navigate('/')}
              variant="ghost"
              className="text-white hover:bg-white/10 p-3 rounded-xl transition-all duration-200"
            >
              <ArrowLeft className="w-5 h-5 mr-2" />
              Voltar
            </Button>
            <div className="flex items-center">
              <img src="/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png" alt="Desfollow Logo" className="w-8 h-8 mr-3" />
              <h1 className="text-xl font-bold bg-gradient-to-r from-blue-400 via-purple-400 to-orange-400 bg-clip-text text-transparent">Desfollow</h1>
            </div>
          </div>
          
          <div className="text-center">
            <h2 className="text-3xl font-bold text-white mb-2">Análise Completa</h2>
            
            {/* Informações do perfil - Estilo Instagram minimalista */}
            {scanData?.profile_info && (
              <div className="mt-6 flex items-center justify-center space-x-4">
                <RobustImage
                  src={scanData.profile_info.profile_pic_url_hd || scanData.profile_info.profile_pic_url}
                  alt={scanData.profile_info.full_name || username}
                  className="w-16 h-16 rounded-full border-2 border-white/20 object-cover"
                />
                <div className="text-left">
                  <div className="text-white font-semibold text-lg">{scanData.profile_info.full_name || username}</div>
                  <div className="text-gray-300 text-sm">@{scanData.profile_info.username || username}</div>
                  <div className="flex items-center space-x-4 text-gray-400 text-xs mt-1">
                    <span>{profileFollowersCount} seguidores</span>
                    <span>{profileFollowingCount} seguindo</span>
                    <span>{scanData.profile_info.posts_count || 0} posts</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>



        {/* Stats Cards removidos conforme solicitação */}

        {/* Results Section */}
        <div className="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 shadow-2xl overflow-hidden">
          {/* Section Header */}
          <div className="bg-gradient-to-r from-red-500/10 to-orange-500/10 p-6 border-b border-white/10">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-2xl font-bold text-white mb-2">Parasitas Identificados</h3>
                <p className="text-white/70">Perfis que não retribuem o follow</p>
              </div>
              {/* Badge de quantidade removido conforme solicitação */}
            </div>
          </div>

          {/* Visible Profiles - Todos os perfis juntos */}
          <div className="p-6">
            {visibleProfiles.length > 0 && (
              <>
                <div className="space-y-4 mb-8">
                  {visibleProfiles.map((profile, index) => (
                                          <div key={index} className={`bg-gradient-to-r from-white/5 to-white/10 backdrop-blur-md rounded-xl p-5 border border-white/10 transition-all duration-300 shadow-lg ${
                        profile.type === 'verified' ? 'hover:border-blue-400/50' : 'hover:border-red-400/50'
                      }`}>
                        <div className="flex items-center space-x-4">
                          <div className="relative">
                            <RobustImage
                              src={profile.avatar}
                              alt={profile.name}
                              className={`w-14 h-14 rounded-full object-cover border-2 shadow-lg ${
                                profile.type === 'verified' ? 'border-blue-400/50' : 'border-red-400/50'
                              }`}
                            />
                            <div className={`absolute -bottom-1 -right-1 rounded-full p-1 ${
                              profile.type === 'verified' ? 'bg-blue-500' : 'bg-red-500'
                            }`}>
                              {profile.type === 'verified' ? (
                                <Star className="w-3 h-3 text-white" />
                              ) : (
                                <TrendingDown className="w-3 h-3 text-white" />
                              )}
                            </div>
                          </div>
                        <div className="flex-1">
                          <div className="mb-2">
                            <div className="flex items-center space-x-2 mb-1">
                              <h4 className="font-bold text-white text-lg">@{profile.name}</h4>
                            </div>
                            <p className="text-gray-300 text-sm mb-2">{profile.fullName}</p>
                            <div className={`rounded-full px-3 py-1 inline-block ${
                              profile.type === 'verified' 
                                ? 'bg-blue-500/20 border border-blue-500/30' 
                                : 'bg-red-500/20 border border-red-500/30'
                            }`}>
                              <span className={`font-semibold text-sm ${
                                profile.type === 'verified' ? 'text-blue-400' : 'text-red-400'
                              }`}>NÃO SEGUE</span>
                            </div>
                          </div>
                          <div className="flex items-center space-x-2 text-white/70 text-sm">
                            {profile.isPrivate && (
                              <span className="flex items-center">
                                <Lock className="w-3 h-3 mr-1" />
                                Perfil privado
                              </span>
                            )}
                            {profile.isVerified && (
                              <span className="flex items-center text-blue-400">
                                <CheckCircle className="w-3 h-3 mr-1" />
                                Verificado
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )}

            {/* No Ghosts Message */}
            {visibleProfiles.length === 0 && (
              <div className="text-center py-12">
                <div className="text-6xl mb-4">🎉</div>
                <h3 className="text-xl font-bold text-white mb-2">Parabéns!</h3>
                <p className="text-gray-300">Não encontramos nenhum ghost! Todos te seguem de volta.</p>
              </div>
            )}

            {/* Locked Profiles Grid - Mostra quando há mais de 4 ghosts (apenas para usuários não pagos) */}
            {totalGhosts > 4 && !hasFullAccess && (
              <>
                <h4 className="text-lg font-bold text-white mb-4">🔒 Mais Perfis Bloqueados</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
                  {blurredProfiles.map((profile, index) => (
                    <div key={index} className="bg-gradient-to-r from-white/5 to-white/10 backdrop-blur-md rounded-xl p-4 border border-white/10 relative overflow-hidden">
                      <div className="absolute inset-0 bg-gradient-to-r from-black/60 to-black/40 backdrop-blur-sm z-10 rounded-xl flex items-center justify-center">
                        <Lock className="w-6 h-6 text-white/80" />
                      </div>
                      <div className="flex items-center space-x-3 blur-sm">
                        <RobustImage
                          src={profile.avatar}
                          alt={profile.name}
                          className="w-10 h-10 rounded-full object-cover border-2 border-white/30"
                        />
                        <div className="flex-1">
                          <div>
                            <h4 className="font-bold text-white mb-1">@{profile.name}</h4>
                            <div className="text-red-400 text-sm font-semibold mb-2">NÃO SEGUE</div>
                          </div>
                          <div className="flex items-center space-x-3 text-white/70 text-sm">
                            <span>1.2K seguidores</span>
                            <span>2.1K seguindo</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )}

            {/* Paginação funcional para usuários pagos quando há mais de 100 resultados */}
            {hasFullAccess && totalPages > 1 && (
              <div className="flex flex-col items-center space-y-4 mb-8">
                {/* Informação sobre total e página atual */}
                <div className="text-white/70 text-sm">
                  Mostrando {((currentPage - 1) * cardsPerPage) + 1} - {Math.min(currentPage * cardsPerPage, allProfiles.length)} de {allProfiles.length} perfis
                </div>
                
                {/* Controles de paginação */}
                <div className="flex items-center justify-center space-x-2">
                  <Button
                    onClick={() => {
                      setCurrentPage(prev => Math.max(1, prev - 1));
                      scrollToTop();
                    }}
                    disabled={currentPage === 1}
                    variant="ghost"
                    size="sm"
                    className="text-white hover:bg-white/10 disabled:opacity-50"
                  >
                    <ChevronLeft className="w-5 h-5 mr-2" />
                    Anterior
                  </Button>
                  
                  <div className="flex items-center space-x-1">
                    {/* Primeira página */}
                    {currentPage > 3 && (
                      <>
                        <Button
                          onClick={() => {
                            setCurrentPage(1);
                            scrollToTop();
                          }}
                          variant="ghost"
                          size="sm"
                          className="w-8 h-8 text-white hover:bg-white/10"
                        >
                          1
                        </Button>
                        {currentPage > 4 && <span className="text-white/50 text-sm">...</span>}
                      </>
                    )}
                    
                    {/* Páginas ao redor da atual */}
                    {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                      let pageNum;
                      if (totalPages <= 5) {
                        pageNum = i + 1;
                      } else if (currentPage <= 3) {
                        pageNum = i + 1;
                      } else if (currentPage >= totalPages - 2) {
                        pageNum = totalPages - 4 + i;
                      } else {
                        pageNum = currentPage - 2 + i;
                      }
                      
                      if (pageNum < 1 || pageNum > totalPages) return null;
                      
                      return (
                        <Button
                          key={pageNum}
                          onClick={() => {
                            setCurrentPage(pageNum);
                            scrollToTop();
                          }}
                          variant={currentPage === pageNum ? "default" : "ghost"}
                          size="sm"
                          className={`w-8 h-8 ${
                            currentPage === pageNum 
                              ? "bg-blue-600 text-white hover:bg-blue-700" 
                              : "text-white hover:bg-white/10"
                          }`}
                        >
                          {pageNum}
                        </Button>
                      );
                    })}
                    
                    {/* Última página */}
                    {currentPage < totalPages - 2 && totalPages > 5 && (
                      <>
                        {currentPage < totalPages - 3 && <span className="text-white/50 text-sm">...</span>}
                        <Button
                          onClick={() => {
                            setCurrentPage(totalPages);
                            scrollToTop();
                          }}
                          variant="ghost"
                          size="sm"
                          className="w-8 h-8 text-white hover:bg-white/10"
                        >
                          {totalPages}
                        </Button>
                      </>
                    )}
                  </div>
                  
                  <Button
                    onClick={() => {
                      setCurrentPage(prev => Math.min(totalPages, prev + 1));
                      scrollToTop();
                    }}
                    disabled={currentPage === totalPages}
                    variant="ghost"
                    size="sm"
                    className="text-white hover:bg-white/10 disabled:opacity-50"
                  >
                    Próxima
                    <ChevronRight className="w-5 h-5 ml-2" />
                  </Button>
                </div>
              </div>
            )}
            
            {/* Status da paginação */}
            <div className="text-center mb-8">
              <div className="bg-gradient-to-r from-yellow-500/20 to-orange-500/20 backdrop-blur-xl rounded-xl p-4 border border-yellow-500/30">
                <p className="text-yellow-400 font-semibold text-sm mb-2">
                  {hasFullAccess ? 
                    `📊 Página ${currentPage} de ${totalPages} - Mostrando ${visibleProfiles.length} de ${allProfiles.length} perfis` :
                    "🔒 Conteúdo Bloqueado - Apenas 5 de " + allProfiles.length + " perfis visíveis"
                  }
                </p>
                {!hasFullAccess && (
                  <p className="text-white/70 text-xs">Desbloqueie todos os perfis com o plano premium</p>
                )}
              </div>
            </div>
          </div>

          {/* Upgrade CTA - apenas para usuários não pagos */}
          {!hasFullAccess && (
            <div className="bg-gradient-to-br from-blue-600/20 via-purple-600/20 to-pink-600/20 backdrop-blur-xl rounded-2xl p-8 border border-blue-500/30 text-center shadow-2xl">
              <div className="mb-6">
                <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-yellow-400 to-orange-500 rounded-full mb-6 shadow-lg">
                  <Crown className="w-10 h-10 text-white" />
                </div>
                <h3 className="text-3xl font-bold text-white mb-3">Desbloqueie a Lista Completa</h3>
                <p className="text-white/90 text-xl mb-2">Veja todos os {totalGhosts} perfis que não te seguem de volta</p>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div className="bg-blue-600/30 backdrop-blur-md rounded-2xl p-6 border border-blue-400/30 shadow-lg">
                  <div className="text-4xl font-bold text-yellow-400 mb-2">{totalGhosts}</div>
                  <div className="text-white text-base font-medium">Parasitas</div>
                </div>
                <div className="bg-blue-600/30 backdrop-blur-md rounded-2xl p-6 border border-blue-400/30 shadow-lg">
                  <div className="text-4xl font-bold text-yellow-400 mb-2">100%</div>
                  <div className="text-white text-base font-medium">Precisão</div>
                </div>
                <div className="bg-blue-600/30 backdrop-blur-md rounded-2xl p-6 border border-blue-400/30 shadow-lg">
                  <div className="text-4xl font-bold text-yellow-400 mb-2">30d</div>
                  <div className="text-white text-base font-medium">Garantia</div>
                </div>
              </div>

              <div className="space-y-6">
                <Button
                  onClick={() => {
                    // NOVA ESTRATÉGIA: Usar hook para preservar TODOS os parâmetros
                    const baseUrl = 'https://checkout.perfectpay.com.br/pay/PPU38CPTT5E';
                    
                    // Debug dos parâmetros atuais
                    debugParams();
                    
                    // Construir query string GARANTINDO username + backup + preservados
                    const additionalParams = {
                      // 1. GARANTIR SEMPRE: Parâmetro dedicado username
                      username: username || '',
                      
                      // 2. GARANTIR SEMPRE: UTM personalizado como backup
                      utm_perfect: username || '',
                      
                      // 3. GARANTIR SEMPRE: SRC como backup adicional  
                      src: `user_${username || 'unknown'}`,
                      
                      // 4. UTMs padrão do Desfollow (sempre enviar, podem sobrescrever)
                      utm_source: preservedParams.utm_source || 'desfollow',
                      utm_campaign: preservedParams.utm_campaign || 'subscription', 
                      utm_medium: preservedParams.utm_medium || 'webapp',
                      
                      // 5. UTM content como backup extra (preservar se existir)
                      utm_content: preservedParams.utm_content || username || '',
                      
                      // 6. URL de redirecionamento com parâmetros preservados
                      redirect_url: `https://desfollow.com.br${buildUrlWithParams(`/results/${username}`, { payment: 'success' })}`,
                    };
                    
                    const checkoutParams = buildQueryString(additionalParams);
                    
                    const checkoutUrl = `${baseUrl}?${checkoutParams}`;
                    
                    // LOGS DETALHADOS PARA GARANTIR QUE TUDO ESTÁ CORRETO
                    console.log('🎯 USERNAME GARANTIDO:', username);
                    console.log('🎯 PARÂMETROS OBRIGATÓRIOS:');
                    console.log('   - username:', additionalParams.username);
                    console.log('   - utm_perfect:', additionalParams.utm_perfect);
                    console.log('   - src:', additionalParams.src);
                    console.log('   - utm_content:', additionalParams.utm_content);
                    console.log('🎯 PARÂMETROS PRESERVADOS:', preservedParams);
                    console.log('🎯 PARÂMETROS FINAIS:', additionalParams);
                    console.log('🔗 URL COMPLETA DO CHECKOUT:', checkoutUrl);
                    
                    window.location.href = checkoutUrl;
                  }}
                  className="w-full bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 hover:from-blue-600 hover:via-purple-600 hover:to-orange-600 text-white font-bold py-5 px-8 rounded-2xl text-xl transition-all duration-300 transform hover:scale-105 shadow-2xl border-0"
                >
                  <Zap className="w-6 h-6 mr-3" />
                  Desbloquear por R$ 29,90
                </Button>
                
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-white/80 text-sm">
                  <div className="flex items-center justify-center sm:justify-start">
                    <Shield className="w-4 h-4 mr-2 text-green-400" />
                    <span className="font-medium">Pagamento seguro</span>
                  </div>
                  <div className="flex items-center justify-center sm:justify-center">
                    <CheckCircle className="w-4 h-4 mr-2 text-blue-400" />
                    <span className="font-medium">Garantia 30 dias</span>
                  </div>
                  <div className="flex items-center justify-center sm:justify-end">
                    <Star className="w-4 h-4 mr-2 text-yellow-400" />
                    <span className="font-medium">4.9/5 avaliação</span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Results;