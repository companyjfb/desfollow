import { User, Search, List, Eye } from 'lucide-react';

const HowItWorks = () => {
  const steps = [
    {
      icon: User,
      title: "Digite seu @",
      description: "Informe seu nome de usuário do Instagram para começar a análise",
      color: "from-neon-pink to-neon-purple"
    },
    {
      icon: Search,
      title: "Análise automática",
      description: "Nossa IA analisa todos os seus seguidores e quem você segue",
      color: "from-neon-purple to-neon-orange"
    },
    {
      icon: List,
      title: "Lista completa",
      description: "Receba uma lista detalhada de quem não te segue de volta",
      color: "from-neon-orange to-neon-pink"
    },
    {
      icon: Eye,
      title: "Tome decisões",
      description: "Você decide o que fazer com cada perfil da lista",
      color: "from-neon-pink to-instagram-blue"
    }
  ];

  return (
    <section className="py-12 md:py-20 bg-gradient-to-b from-purple-900 to-slate-900">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12 md:mb-16">
          <h2 className="text-2xl md:text-4xl lg:text-5xl font-bold text-white mb-4 md:mb-6 font-inter">
            Como <span className="text-white">funciona</span>
          </h2>
          <p className="text-base md:text-xl text-white max-w-2xl mx-auto">
            Em apenas alguns cliques, descubra todos os perfis que não te seguem de volta
          </p>
        </div>

        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 md:gap-8">
            {steps.map((step, index) => (
              <div 
                key={index}
                className="relative group"
              >
                {/* Connection line - Hidden on mobile */}
                {index < steps.length - 1 && (
                  <div className="hidden lg:block absolute top-1/2 left-full w-full h-0.5 bg-gradient-to-r from-neon-pink/50 to-transparent transform -translate-y-1/2 z-0">
                    <div className="absolute right-2 top-1/2 transform -translate-y-1/2 w-2 h-2 bg-neon-pink rounded-full"></div>
                  </div>
                )}

                <div className="bg-white/5 backdrop-blur-md rounded-2xl md:rounded-3xl p-5 md:p-6 border border-white/10 hover:border-neon-pink/50 transition-all duration-300 transform hover:scale-105 animate-fade-in relative z-10"
                     style={{ animationDelay: `${index * 0.2}s` }}>
                  {/* Step number */}
                  <div className="absolute -top-3 -left-3 w-6 h-6 md:w-8 md:h-8 bg-gradient-to-r from-neon-pink to-neon-purple rounded-full flex items-center justify-center text-white font-bold text-xs md:text-sm">
                    {index + 1}
                  </div>

                  {/* Icon */}
                  <div className={`bg-gradient-to-r ${step.color} p-3 md:p-4 rounded-xl md:rounded-2xl w-fit mb-4 md:mb-6 group-hover:animate-pulse-glow mx-auto`}>
                    <step.icon className="w-6 h-6 md:w-8 md:h-8 text-white" />
                  </div>

                  {/* Content */}
                  <h3 className="text-lg md:text-xl font-bold text-white mb-2 md:mb-3 font-inter text-center">{step.title}</h3>
                  <p className="text-white/90 text-center leading-relaxed text-sm md:text-base">{step.description}</p>
                </div>
              </div>
            ))}
          </div>

          {/* CTA Section */}
          <div className="text-center mt-12 md:mt-16">
            <div className="bg-gradient-to-r from-neon-pink/10 to-neon-orange/10 backdrop-blur-md rounded-2xl md:rounded-3xl p-6 md:p-8 border border-neon-pink/20 max-w-2xl mx-auto">
              <h3 className="text-xl md:text-2xl font-bold text-white mb-3 md:mb-4 font-inter">
                Pronto para descobrir a verdade?
              </h3>
              <p className="text-white/90 mb-4 md:mb-6 text-sm md:text-base">
                Junte-se a milhares de pessoas que já descobriram quem realmente as segue
              </p>
              <div className="flex flex-col sm:flex-row gap-3 md:gap-4 justify-center">
                <div className="bg-white/10 backdrop-blur-md rounded-xl md:rounded-2xl p-3 md:p-4 border border-white/20">
                  <div className="text-xl md:text-3xl font-bold text-white mb-1">+50k</div>
                  <div className="text-white/80 text-xs md:text-sm">Usuários ativos</div>
                </div>
                <div className="bg-white/10 backdrop-blur-md rounded-xl md:rounded-2xl p-3 md:p-4 border border-white/20">
                  <div className="text-xl md:text-3xl font-bold text-white mb-1">4.9★</div>
                  <div className="text-white/80 text-xs md:text-sm">Avaliação média</div>
                </div>
                <div className="bg-white/10 backdrop-blur-md rounded-xl md:rounded-2xl p-3 md:p-4 border border-white/20">
                  <div className="text-xl md:text-3xl font-bold text-white mb-1">30d</div>
                  <div className="text-white/80 text-xs md:text-sm">Garantia</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;