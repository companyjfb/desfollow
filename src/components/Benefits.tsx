
import { Clock, Shield, UserX, Zap } from 'lucide-react';

const Benefits = () => {
  const benefits = [
    {
      icon: Clock,
      title: "Economize tempo",
      description: "Não perca horas checando perfil por perfil. Nossa IA faz tudo em segundos."
    },
    {
      icon: Shield,
      title: "Garantia de 30 dias",
      description: "Não gostou? Devolvemos 100% do seu dinheiro em até 30 dias, sem perguntas."
    },
    {
      icon: UserX,
      title: "Identifique contas inativas",
      description: "Descubra contas que você segue mas que não retribuem o follow."
    },
    {
      icon: Zap,
      title: "Resultados instantâneos",
      description: "Sistema inteligente que analisa seus seguidores e mostra quem não te segue de volta."
    }
  ];

  return (
    <section className="py-12 md:py-20 bg-gradient-to-b from-slate-900 to-instagram-blue">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12 md:mb-16">
          <h2 className="text-2xl md:text-4xl lg:text-5xl font-bold text-white mb-4 md:mb-6 font-inter">
            Por que usar o <span className="text-white">Desfollow</span>?
          </h2>
          <p className="text-base md:text-xl text-white max-w-2xl mx-auto">
            A ferramenta mais inteligente para descobrir quem não te segue de volta no Instagram.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 md:gap-8">
          {benefits.map((benefit, index) => (
            <div 
              key={index}
              className="bg-white/5 backdrop-blur-md rounded-2xl md:rounded-3xl p-6 md:p-8 border border-white/10 hover:border-neon-pink/50 transition-all duration-300 transform hover:scale-105 hover:shadow-2xl animate-fade-in group"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <div className="bg-gradient-to-r from-neon-pink to-neon-purple p-3 md:p-4 rounded-xl md:rounded-2xl w-fit mb-4 md:mb-6 group-hover:animate-pulse-glow">
                <benefit.icon className="w-6 h-6 md:w-8 md:h-8 text-white" />
              </div>
              <h3 className="text-lg md:text-xl font-bold text-white mb-3 md:mb-4 font-inter">{benefit.title}</h3>
              <p className="text-white/90 leading-relaxed text-sm md:text-base">{benefit.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Benefits;
