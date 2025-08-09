import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Eye, Users, Zap } from 'lucide-react';
import { useUrlParams } from '../hooks/use-url-params';

const Header = () => {
  const [username, setUsername] = useState('');
  const [showResults, setShowResults] = useState(false);
  const navigate = useNavigate();
  const { buildUrlWithParams, debugParams } = useUrlParams();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (username.trim()) {
      // Remove @ if user typed it
      const cleanUsername = username.replace('@', '');
      
      // Construir URL preservando TODOS os parâmetros UTM
      const targetUrl = buildUrlWithParams(`/analyzing/${cleanUsername}`);
      
      // Debug para verificar parâmetros
      debugParams();
      console.log('🔗 Navegando da PÁGINA INICIAL com parâmetros preservados:', targetUrl);
      
      navigate(targetUrl);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    let value = e.target.value;
    
    // Se o usuário digitou @ no meio, remove
    value = value.replace(/@/g, '');
    
    // Se o valor não começa com @, adiciona
    if (value && !value.startsWith('@')) {
      value = '@' + value;
    }
    
    setUsername(value);
  };

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <header className="relative min-h-screen bg-gradient-to-br from-instagram-blue via-blue-600 to-purple-800 overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0 bg-gradient-to-r from-neon-pink/10 via-neon-purple/10 to-neon-orange/10 animate-pulse"></div>
      <div className="absolute top-20 left-10 w-32 h-32 bg-neon-pink/20 rounded-full blur-xl animate-float"></div>
      <div className="absolute bottom-40 right-20 w-40 h-40 bg-neon-purple/20 rounded-full blur-xl animate-float" style={{ animationDelay: '1s' }}></div>
      <div className="absolute top-1/2 left-1/4 w-24 h-24 bg-neon-orange/20 rounded-full blur-xl animate-float" style={{ animationDelay: '2s' }}></div>

      <div className="relative z-10 container mx-auto px-4">
        <div className="text-center max-w-4xl mx-auto min-h-screen flex flex-col justify-center py-12">
          {/* Logo/Brand */}
          <div className="flex items-center justify-center mb-6">
            <img src="/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png" alt="Desfollow Logo" className="w-12 h-12 mr-4" />
            <h2 className="text-4xl font-bold bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 bg-clip-text text-transparent font-inter drop-shadow-lg">Desfollow</h2>
          </div>

          {/* Urgent Badge */}
          <div className="mb-4">
            <div className="inline-flex items-center bg-red-500/20 border border-red-500/40 rounded-full px-3 py-1 animate-pulse">
              <div className="w-2 h-2 bg-red-500 rounded-full mr-2 animate-ping"></div>
              <span className="text-white font-bold text-xs">🔥 +100K PESSOAS JÁ DESCOBRIRAM</span>
            </div>
          </div>

          {/* Main Headlines */}
          <div className="relative mb-4">
            <div className="absolute inset-0 bg-gradient-to-r from-neon-pink/20 via-neon-purple/20 to-neon-orange/20 blur-3xl animate-pulse-glow"></div>
            <h1 className="relative text-3xl md:text-5xl lg:text-6xl font-bold text-white mb-3 font-inter animate-fade-in leading-tight">
              <span className="block text-white drop-shadow-2xl">
                Descubra agora quem não te segue de volta
              </span>
            </h1>
          </div>

          {/* Aggressive subtitle */}
          <div className="relative mb-6">
            <p className="relative text-base md:text-lg lg:text-xl text-white font-inter animate-fade-in leading-relaxed max-w-2xl mx-auto px-4 text-center" style={{ animationDelay: '0.2s' }}>
              Te seguiu pra ganhar seguidor, te deixou quando cresceu.<br />
              <span className="text-white font-bold">O Desfollow te mostra quem só queria hype.</span>
            </p>
          </div>

          {/* Stats Row */}
          <div className="grid grid-cols-3 gap-2 mb-6 max-w-sm mx-auto">
            <div className="bg-white/10 backdrop-blur-md rounded-lg p-3 border border-white/20 animate-fade-in" style={{ animationDelay: '0.3s' }}>
              <div className="text-lg font-bold text-white mb-1">274</div>
              <div className="text-white/80 text-xs">Falsos seguidores</div>
            </div>
            <div className="bg-white/10 backdrop-blur-md rounded-lg p-3 border border-white/20 animate-fade-in" style={{ animationDelay: '0.4s' }}>
              <div className="text-lg font-bold text-white mb-1">2.3M</div>
              <div className="text-white/80 text-xs">Contas analisadas</div>
            </div>
            <div className="bg-white/10 backdrop-blur-md rounded-lg p-3 border border-white/20 animate-fade-in" style={{ animationDelay: '0.5s' }}>
              <div className="text-lg font-bold text-white mb-1">3min</div>
              <div className="text-white/80 text-xs">Tempo médio</div>
            </div>
          </div>


          {/* User Input Section */}
          {!showResults ? (
            <div className="max-w-lg mx-auto animate-scale-up px-4" style={{ animationDelay: '0.7s' }}>
              <div className="bg-white/15 backdrop-blur-md rounded-2xl p-8 border-2 border-white/30 shadow-2xl">
                <form onSubmit={handleSubmit} className="space-y-6">
                  <div className="relative group">
                    <div className="absolute -inset-1 bg-gradient-to-r from-neon-pink via-neon-purple to-neon-orange rounded-xl blur opacity-50 group-hover:opacity-70 transition duration-300"></div>
                    <div className="relative">
                      <Input
                        type="text"
                        placeholder="Digite seu usuário @"
                        value={username}
                        onChange={handleInputChange}
                        className="bg-white/20 border-white/30 text-white placeholder:text-white/70 text-lg py-5 px-5 rounded-xl backdrop-blur-md focus:border-neon-pink focus:ring-neon-pink focus:ring-2 transition-all duration-300 pr-12 font-medium"
                      />
                      <img src="/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png" alt="Desfollow Logo" className="absolute right-4 top-1/2 transform -translate-y-1/2 w-6 h-6 opacity-60" />
                    </div>
                  </div>
                  <div className="relative group">
                    <div className="absolute -inset-1 bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 rounded-2xl blur opacity-80 group-hover:opacity-100 transition duration-300"></div>
                    <Button 
                      type="submit"
                      className="relative w-full bg-gradient-to-r from-blue-600 via-purple-600 to-orange-500 hover:from-blue-700 hover:via-purple-700 hover:to-orange-600 text-white font-bold py-6 text-lg md:text-xl rounded-2xl transition-all duration-300 transform hover:scale-105 shadow-2xl"
                    >
                      <Eye className="w-5 h-5 md:w-6 md:h-6 mr-3" />
                      <span className="block md:hidden">ESCANEAR</span>
                      <span className="hidden md:block">ESCANEAR AGORA</span>
                    </Button>
                  </div>
                </form>
              </div>
            </div>
          ) : (
            <div className="max-w-sm mx-auto animate-scale-up px-4">
              <div className="relative group">
                <div className="absolute -inset-1 bg-gradient-to-r from-neon-pink via-neon-purple to-neon-orange rounded-xl blur opacity-40 animate-pulse-glow"></div>
                <div className="relative bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/20">
                  <div className="flex items-center justify-center mb-4">
                    <div className="relative">
                      <div className="absolute inset-0 bg-neon-pink rounded-full blur-lg opacity-50 animate-pulse"></div>
                      <Users className="relative w-10 h-10 text-neon-pink" />
                    </div>
                  </div>
                  <h3 className="text-xl font-bold text-white mb-2 text-center">😱 RESULTADO CHOCANTE!</h3>
                  <p className="text-red-400 font-bold text-center mb-4 text-sm">Você está sendo usado por:</p>
                  <div className="bg-black/40 rounded-xl p-4 mb-4 border border-white/10">
                    <p className="text-3xl font-bold text-neon-pink mb-2 text-center animate-glow-pulse">274 pessoas</p>
                    <p className="text-white/80 text-center text-sm mb-3">que NÃO te seguem de volta</p>
                    <div className="bg-red-500/20 border border-red-500/40 rounded-lg p-2 mb-3">
                      <p className="text-red-400 font-bold text-xs text-center">⚠️ Isso representa 67% do seu following!</p>
                    </div>
                    <div className="mt-3 space-y-2">
                      {['@usuario_falso_1', '@perfil_inativo_2', '@conta_fantasma_3'].map((user, index) => (
                        <div key={index} className="bg-white/5 rounded-lg p-2 text-white/40 blur-sm border border-white/10 text-xs">
                          {user}
                        </div>
                      ))}
                      <div className="text-center text-white/60 text-xs pt-1">+ 271 outros parasitas...</div>
                    </div>
                  </div>
                  <div className="relative group">
                    <div className="absolute -inset-1 bg-gradient-to-r from-neon-orange to-neon-pink rounded-xl blur opacity-70 group-hover:opacity-90 transition duration-300"></div>
                    <Button 
                      onClick={() => navigate('/analyzing/seu_usuario')}
                      className="relative w-full bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 hover:from-blue-600 hover:via-purple-600 hover:to-orange-600 text-white font-bold py-4 text-sm md:text-base rounded-xl transition-all duration-300 transform hover:scale-105"
                    >
                      <Zap className="w-4 h-4 md:w-5 md:h-5 mr-2" />
                      <span className="block md:hidden">VER LISTA</span>
                      <span className="hidden md:block">VER LISTA COMPLETA</span>
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          )}

        </div>
      </div>
    </header>
  );
};

export default Header;