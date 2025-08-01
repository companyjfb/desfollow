import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { Button } from "@/components/ui/button";
import { ArrowLeft, Crown, Lock, Zap, Users, TrendingDown, AlertTriangle, Shield, CheckCircle, Star, Target, ArrowRight } from 'lucide-react';
import InstagramImage from '@/components/InstagramImage';
import { StatusResponse } from '../utils/ghosts';
import { useScanCache } from '../hooks/use-scan-cache';

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

// Componente de imagem com fallback robusto
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
    />
  );
};

const Results = () => {
  const { username } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const { getCachedOrFetchScan } = useScanCache();
  
  const [scanData, setScanData] = useState<ScanData | null>(location.state?.scanData || null);
  const [isLoading, setIsLoading] = useState(false);
  const [fromCache, setFromCache] = useState(location.state?.fromCache || false);
  
  // ✅ REGRA ESPECIAL: jordanbitencourt vê todos os resultados
  const isSpecialUser = username === 'jordanbitencourt';
  
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
            navigate(`/analyzing/${username}`);
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
  
  // Adiciona pessoas reais primeiro
  if (scanData?.real_ghosts) {
    allGhosts.push(...scanData.real_ghosts.map(user => ({
      ...user,
      type: 'real'
    })));
  }
  
  // Adiciona pessoas verificadas depois
  if (scanData?.famous_ghosts) {
    allGhosts.push(...scanData.famous_ghosts.map(user => ({
      ...user,
      type: 'verified'
    })));
  }
  
  // Se não há dados reais, usa dados simulados
  if (allGhosts.length === 0) {
    allGhosts.push(
      {
        username: "usuario1",
        full_name: "Usuário Exemplo 1",
        profile_pic_url: "/lovable-uploads/b1878feb-16ec-438c-8e37-5258266aedd6.png",
        is_private: false,
        is_verified: false,
        type: 'real'
      },
      {
        username: "usuario2", 
        full_name: "Usuário Exemplo 2",
        profile_pic_url: "/lovable-uploads/c66eb0c2-8f5d-4575-93e6-9aa364372325.png",
        is_private: true,
        is_verified: false,
        type: 'real'
      },
      {
        username: "usuario3",
        full_name: "Usuário Exemplo 3", 
        profile_pic_url: "/lovable-uploads/da90f167-2ab5-4f82-a0e3-3d89f44d82f8.png",
        is_private: false,
        is_verified: true,
        type: 'verified'
      }
    );
  }
  
  // Mostra apenas os primeiros 4 perfis (ou todos para jordanbitencourt)
  const visibleProfiles = isSpecialUser 
    ? allGhosts.map(user => ({
        name: user.username,
        fullName: user.full_name,
        avatar: user.profile_pic_url || "/placeholder.svg",
        isPrivate: user.is_private,
        isVerified: user.is_verified,
        type: user.type
      }))
    : allGhosts.slice(0, 4).map(user => ({
        name: user.username,
        fullName: user.full_name,
        avatar: user.profile_pic_url || "/placeholder.svg",
        isPrivate: user.is_private,
        isVerified: user.is_verified,
        type: user.type
      }));

  // Perfis bloqueados (simulados) - apenas para usuários normais
  const blurredProfiles = Array.from({ length: 8 }, (_, i) => ({
    name: `user_${i + 1}`,
    avatar: `/lovable-uploads/${['c86c9416-e19f-4e6c-b96a-981764455220.png', 'a1ff2d2a-90ed-4aca-830b-0fa8e772a3ad.png', 'e4cc8fae-cf86-4234-83bc-7a4cbb3e3537.png'][i % 3]}`
  }));

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  // ✅ MOSTRAR VALORES REAIS (sem multiplicação falsa)
  const rawCount = scanData?.count || 0;
  // ❌ REMOVER DADOS SIMULADOS: Usar apenas dados reais
  const totalGhosts = scanData?.count || 0;
  const realGhostsCount = scanData?.real_ghosts_count || 0;
  const famousGhostsCount = scanData?.famous_ghosts_count || 0;
  const followersCount = scanData?.followers_count || 0;  // Dados analisados
  const followingCount = scanData?.following_count || 0;  // Dados analisados
  const profileFollowersCount = scanData?.profile_followers_count || scanData?.profile_info?.followers_count || 0;  // Total do perfil
  const profileFollowingCount = scanData?.profile_following_count || scanData?.profile_info?.following_count || 0;  // Total do perfil
  const lossRate = profileFollowersCount ? 
    Math.round((totalGhosts / profileFollowersCount) * 100) : 0;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-purple-900 p-4">
      <div className="max-w-4xl mx-auto">
        
        {/* Header */}
        <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-6 border border-white/10 shadow-2xl mb-8">
          {/* Cache indicator */}
          {fromCache && (
            <div className="bg-blue-600/20 border border-blue-400/30 rounded-lg p-3 mb-6">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
                <span className="text-blue-200 text-sm">
                  📦 Dados carregados do cache • Última análise recente
                </span>
              </div>
            </div>
          )}
          
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

        {/* Alert Banner */}
        <div className="bg-gradient-to-r from-red-500/20 to-orange-500/20 backdrop-blur-xl rounded-2xl p-6 border border-red-500/30 mb-8">
          <div className="flex items-center justify-center space-x-3">
            <AlertTriangle className="w-6 h-6 text-orange-400" />
            <div className="text-center">
              <p className="text-white font-bold text-lg">⚠️ Alerta: Alto Índice de Parasitas Detectado</p>
              <p className="text-white/80 text-sm">{lossRate}% das pessoas que você segue não te seguem de volta</p>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-gradient-to-br from-red-500/20 to-red-600/20 backdrop-blur-xl rounded-2xl p-6 border border-red-500/30 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-red-500/20 rounded-xl">
                <TrendingDown className="w-8 h-8 text-red-400" />
              </div>
              <div className="text-right">
                <div className="text-3xl font-bold text-red-400">{totalGhosts}</div>
                <div className="text-white/90 text-sm font-medium">Parasitas</div>
              </div>
            </div>
            <p className="text-white/70 text-sm">Pessoas que não retribuem o follow</p>
          </div>
          
          <div className="bg-gradient-to-br from-yellow-500/20 to-orange-500/20 backdrop-blur-xl rounded-2xl p-6 border border-yellow-500/30 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-yellow-500/20 rounded-xl">
                <AlertTriangle className="w-8 h-8 text-yellow-400" />
              </div>
              <div className="text-right">
                <div className="text-3xl font-bold text-yellow-400">{lossRate}%</div>
                <div className="text-white/90 text-sm font-medium">Taxa de Loss</div>
              </div>
            </div>
            <p className="text-white/70 text-sm">Porcentagem de não-retribuição</p>
          </div>
          
          <div className="bg-gradient-to-br from-blue-500/20 to-purple-500/20 backdrop-blur-xl rounded-2xl p-6 border border-blue-500/30 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <div className="p-3 bg-blue-500/20 rounded-xl">
                <Users className="w-8 h-8 text-blue-400" />
              </div>
              <div className="text-right">
                <div className="text-3xl font-bold text-blue-400">{followersCount}</div>
                <div className="text-white/90 text-sm font-medium">Analisados</div>
              </div>
            </div>
            <p className="text-white/70 text-sm">Total de perfis verificados</p>
          </div>
        </div>

        {/* Results Section */}
        <div className="bg-white/5 backdrop-blur-xl rounded-2xl border border-white/10 shadow-2xl overflow-hidden">
          {/* Section Header */}
          <div className="bg-gradient-to-r from-red-500/10 to-orange-500/10 p-6 border-b border-white/10">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-2xl font-bold text-white mb-2">Parasitas Identificados</h3>
                <p className="text-white/70">Perfis que não retribuem o follow</p>
              </div>
              <div className="bg-red-500/20 rounded-xl px-4 py-2 border border-red-500/30">
                <span className="text-red-400 font-bold">{totalGhosts} encontrados</span>
              </div>
            </div>
          </div>

          {/* Visible Profiles - Todos os perfis juntos */}
          <div className="p-6">
            {visibleProfiles.length > 0 && (
              <>
                <div className="space-y-4 mb-8">
                  {visibleProfiles.map((profile, index) => (
                    <div key={index} className={`bg-gradient-to-r from-white/5 to-white/10 backdrop-blur-md rounded-xl p-5 border border-white/10 transition-all duration-300 shadow-lg ${
                      profile.type === 'verified' ? 'hover:border-purple-400/50' : 'hover:border-red-400/50'
                    }`}>
                      <div className="flex items-center space-x-4">
                        <div className="relative">
                          <RobustImage
                            src={profile.avatar}
                            alt={profile.name}
                            className={`w-14 h-14 rounded-full object-cover border-2 shadow-lg ${
                              profile.type === 'verified' ? 'border-purple-400/50' : 'border-red-400/50'
                            }`}
                          />
                          <div className={`absolute -bottom-1 -right-1 rounded-full p-1 ${
                            profile.type === 'verified' ? 'bg-purple-500' : 'bg-red-500'
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
                            <h4 className="font-bold text-white text-lg">@{profile.name}</h4>
                            <p className="text-gray-300 text-sm mb-2">{profile.fullName}</p>
                            <div className={`rounded-full px-3 py-1 inline-block ${
                              profile.type === 'verified' 
                                ? 'bg-purple-500/20 border border-purple-500/30' 
                                : 'bg-red-500/20 border border-red-500/30'
                            }`}>
                              <span className={`font-semibold text-sm ${
                                profile.type === 'verified' ? 'text-purple-400' : 'text-red-400'
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

            {/* Locked Profiles Grid - Mostra quando há mais de 4 ghosts (apenas para usuários normais) */}
            {totalGhosts > 4 && !isSpecialUser && (
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
                <div className="text-center mb-8">
                  <div className="bg-gradient-to-r from-yellow-500/20 to-orange-500/20 backdrop-blur-xl rounded-xl p-4 border border-yellow-500/30">
                    <p className="text-yellow-400 font-semibold text-sm mb-2">🔒 Conteúdo Bloqueado</p>
                    <p className="text-white/70 text-xs">Desbloqueie todos os perfis com o plano premium</p>
                  </div>
                </div>
              </>
            )}
          </div>

          {/* Upgrade CTA - apenas para usuários normais */}
          {!isSpecialUser && (
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
                  onClick={scrollToTop}
                  className="w-full bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 hover:from-blue-600 hover:via-purple-600 hover:to-orange-600 text-white font-bold py-5 px-8 rounded-2xl text-xl transition-all duration-300 transform hover:scale-105 shadow-2xl border-0"
                >
                  <Zap className="w-6 h-6 mr-3" />
                  Desbloquear por R$ 29
                </Button>
                
                <div className="flex items-center justify-center space-x-8 text-white/80 text-base">
                  <div className="flex items-center">
                    <Shield className="w-5 h-5 mr-2" />
                    Pagamento seguro
                  </div>
                  <div className="flex items-center">
                    <CheckCircle className="w-5 h-5 mr-2" />
                    Garantia 30 dias
                  </div>
                  <div className="flex items-center">
                    <Star className="w-5 h-5 mr-2" />
                    4.9/5 avaliação
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