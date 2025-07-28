import { Clock, AlertCircle, Zap, CheckCircle, X, Eye, Shield, TrendingUp } from 'lucide-react';

const Comparison = () => {
  const manualMethod = [
    {
      icon: Clock,
      title: "Tempo desperdiçado",
      description: "Horas checando perfil por perfil manualmente",
      color: "text-red-400"
    },
    {
      icon: AlertCircle,
      title: "Dados imprecisos",
      description: "Fácil perder pessoas ou contar errado",
      color: "text-red-400"
    },
    {
      icon: X,
      title: "Processo frustrante",
      description: "Cansativo e desmotivante fazer na mão",
      color: "text-red-400"
    },
    {
      icon: Eye,
      title: "Limitação visual",
      description: "Só consegue ver poucos perfis por vez",
      color: "text-red-400"
    }
  ];

  const desfollowMethod = [
    {
      icon: Zap,
      title: "Resultado instantâneo",
      description: "Análise completa em apenas 30 segundos",
      color: "text-green-400"
    },
    {
      icon: CheckCircle,
      title: "100% preciso",
      description: "IA analisa todos os dados sem erros",
      color: "text-green-400"
    },
    {
      icon: Shield,
      title: "Totalmente seguro",
      description: "Sem acesso à sua conta, só dados públicos",
      color: "text-green-400"
    },
    {
      icon: TrendingUp,
      title: "Lista completa",
      description: "Vê todos os não-seguidores de uma vez",
      color: "text-green-400"
    }
  ];

  return (
    <section className="py-12 md:py-20 bg-gradient-to-b from-slate-900 to-purple-900">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12 md:mb-16">
          <h2 className="text-2xl md:text-4xl lg:text-5xl font-bold text-white mb-4 md:mb-6 font-inter">
            <span className="text-white">Método Manual</span> vs <span className="bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 bg-clip-text text-transparent">Desfollow</span>
          </h2>
          <p className="text-base md:text-xl text-white max-w-2xl mx-auto">
            Veja a diferença entre perder tempo fazendo na mão ou usar nossa tecnologia
          </p>
        </div>

        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 md:gap-8">
            
            {/* Método Manual */}
            <div className="bg-red-500/10 backdrop-blur-md rounded-2xl md:rounded-3xl p-6 md:p-8 border border-red-500/20 relative">
              <div className="absolute top-3 right-3 md:top-4 md:right-4 bg-red-500/20 rounded-full px-2 py-1 md:px-3 md:py-1">
                <span className="text-red-400 font-bold text-xs">❌ ANTIGO</span>
              </div>
              
              <div className="mb-6 md:mb-8 mt-6 md:mt-0">
                <h3 className="text-xl md:text-2xl font-bold text-white mb-2 md:mb-3">Fazendo Manualmente</h3>
                <p className="text-white/80 text-sm md:text-base">O jeito difícil e demorado</p>
              </div>

              <div className="space-y-4 md:space-y-6">
                {manualMethod.map((item, index) => (
                  <div key={index} className="flex items-start space-x-3 md:space-x-4">
                    <div className="bg-red-500/20 p-2 md:p-3 rounded-xl flex-shrink-0">
                      <item.icon className={`w-4 h-4 md:w-5 md:h-5 ${item.color}`} />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-white font-semibold mb-1 text-sm md:text-base">{item.title}</h4>
                      <p className="text-white/70 text-xs md:text-sm leading-relaxed">{item.description}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="mt-6 md:mt-8 bg-red-500/10 rounded-xl p-4 md:p-6 border border-red-500/20">
                <div className="text-center">
                  <div className="text-2xl md:text-3xl font-bold text-red-400 mb-2">1 dia inteiro</div>
                  <div className="text-white/80 text-sm md:text-base">Tempo médio gasto</div>
                </div>
              </div>
            </div>

            {/* Com Desfollow */}
            <div className="bg-green-500/10 backdrop-blur-md rounded-2xl md:rounded-3xl p-6 md:p-8 border border-green-500/20 relative">
              <div className="absolute top-3 right-3 md:top-4 md:right-4 bg-green-500/20 rounded-full px-2 py-1 md:px-3 md:py-1">
                <span className="text-green-400 font-bold text-xs">✅ INTELIGENTE</span>
              </div>
              
              <div className="mb-6 md:mb-8 mt-6 md:mt-0">
                <h3 className="text-xl md:text-2xl font-bold text-white mb-2 md:mb-3">Com Desfollow</h3>
                <p className="text-white/80 text-sm md:text-base">Tecnologia que faz tudo por você</p>
              </div>

              <div className="space-y-4 md:space-y-6">
                {desfollowMethod.map((item, index) => (
                  <div key={index} className="flex items-start space-x-3 md:space-x-4">
                    <div className="bg-green-500/20 p-2 md:p-3 rounded-xl flex-shrink-0">
                      <item.icon className={`w-4 h-4 md:w-5 md:h-5 ${item.color}`} />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-white font-semibold mb-1 text-sm md:text-base">{item.title}</h4>
                      <p className="text-white/70 text-xs md:text-sm leading-relaxed">{item.description}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="mt-6 md:mt-8 bg-green-500/10 rounded-xl p-4 md:p-6 border border-green-500/20">
                <div className="text-center">
                  <div className="text-2xl md:text-3xl font-bold text-green-400 mb-2">30 segundos</div>
                  <div className="text-white/80 text-sm md:text-base">Tempo médio gasto</div>
                </div>
              </div>
            </div>
          </div>

          {/* CTA Section */}
          <div className="text-center mt-12 md:mt-16">
            <div className="bg-gradient-to-r from-blue-500/10 via-purple-500/10 to-orange-500/10 backdrop-blur-md rounded-2xl md:rounded-3xl p-6 md:p-8 border border-blue-500/20 max-w-2xl mx-auto">
              <h3 className="text-xl md:text-2xl font-bold text-white mb-3 md:mb-4 font-inter">
                Pare de perder tempo!
              </h3>
              <p className="text-white/90 mb-4 md:mb-6 text-sm md:text-base">
                Descubra em 30 segundos o que levaria um dia inteiro para fazer manualmente
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
                <div className="bg-white/5 rounded-xl p-3 md:p-4 border border-white/10">
                  <div className="text-lg md:text-xl font-bold text-white mb-1">2.880x</div>
                  <div className="text-white/80 text-xs md:text-sm">Mais rápido</div>
                </div>
                <div className="bg-white/5 rounded-xl p-3 md:p-4 border border-white/10">
                  <div className="text-lg md:text-xl font-bold text-white mb-1">100%</div>
                  <div className="text-white/80 text-xs md:text-sm">Preciso</div>
                </div>
                <div className="bg-white/5 rounded-xl p-3 md:p-4 border border-white/10">
                  <div className="text-lg md:text-xl font-bold text-white mb-1">0%</div>
                  <div className="text-white/80 text-xs md:text-sm">Esforço</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Comparison;