import { Button } from "@/components/ui/button";
import { CheckCircle, Zap, Shield, CreditCard } from 'lucide-react';

const Pricing = () => {
  const features = [
    "Análise completa de seguidores",
    "Lista detalhada de não seguidores",
    "Relatórios exportáveis",
    "Interface intuitiva e segura",
    "Suporte 24/7",
    "Atualizações gratuitas"
  ];

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <section id="pricing" className="py-12 md:py-20 bg-gradient-to-b from-purple-900 to-slate-900">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12 md:mb-16">
          <h2 className="text-2xl md:text-4xl lg:text-5xl font-bold text-white mb-4 md:mb-6 font-inter">
            <span className="text-white">Oferta Especial</span>
          </h2>
          <p className="text-base md:text-xl text-white max-w-2xl mx-auto mb-6 md:mb-8">
            Descubra quem não te segue de volta no Instagram com nossa garantia de 30 dias.
          </p>
        </div>

        {/* Single Plan - Centered and More Attractive */}
        <div className="max-w-sm mx-auto">
          <div className="bg-gradient-to-br from-neon-orange/30 to-neon-pink/30 backdrop-blur-md rounded-2xl md:rounded-3xl p-8 md:p-10 border-2 border-neon-orange relative overflow-hidden transform hover:scale-105 transition-all duration-300 shadow-2xl">
            {/* Glow Effect */}
            <div className="absolute inset-0 bg-gradient-to-br from-neon-orange/40 to-neon-pink/40 blur-xl -z-10"></div>
            
            {/* Popular Badge */}
            <div className="absolute top-3 right-3 md:top-4 md:right-4 bg-gradient-to-r from-neon-orange to-neon-pink text-white px-3 py-1 md:px-4 md:py-2 rounded-full text-xs md:text-sm font-bold animate-pulse">
              MAIS POPULAR
            </div>
            
            <div className="relative z-10">
              <div className="text-center mb-6 md:mb-8">
                <div className="bg-white/10 rounded-full w-16 h-16 md:w-20 md:h-20 flex items-center justify-center mx-auto mb-4 md:mb-6">
                  <Zap className="w-8 h-8 md:w-10 md:h-10 text-neon-orange" />
                </div>
                
                <h3 className="text-2xl md:text-3xl font-bold text-white mb-3 md:mb-4">Plano Premium</h3>
                
                <div className="flex items-center justify-center mb-4 md:mb-6">
                  <span className="text-4xl md:text-6xl font-bold text-white">R$ 29</span>
                  <span className="text-lg md:text-2xl text-white/80 ml-2">,00</span>
                </div>
                
                <div className="bg-neon-orange/20 rounded-full px-4 py-2 md:px-6 md:py-3 mb-4 md:mb-6">
                  <span className="text-neon-orange font-bold text-sm md:text-lg">🔥 Oferta Limitada</span>
                </div>
                
                <Button 
                  onClick={scrollToTop}
                  className="w-full bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 hover:from-blue-600 hover:via-purple-600 hover:to-orange-600 text-white font-semibold py-4 md:py-6 text-sm md:text-xl rounded-xl md:rounded-2xl transition-all duration-300 transform hover:scale-105 animate-pulse-glow shadow-lg"
                >
                  <CreditCard className="w-4 h-4 md:w-6 md:h-6 mr-2 md:mr-3" />
                  <span className="block md:hidden">Descobrir Agora</span>
                  <span className="hidden md:block">Descobrir Agora - Garantia de 30 dias</span>
                </Button>
              </div>
            </div>
          </div>
        </div>

        {/* Features */}
        <div className="max-w-2xl mx-auto mt-8 md:mt-12">
          <div className="bg-white/5 backdrop-blur-md rounded-2xl md:rounded-3xl p-6 md:p-8 border border-white/20">
            <h4 className="text-lg md:text-xl font-bold text-white mb-4 md:mb-6 text-center">Tudo que você precisa:</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4">
              {features.map((feature, index) => (
                <div key={index} className="flex items-center space-x-3">
                  <CheckCircle className="w-4 h-4 md:w-5 md:h-5 text-neon-pink flex-shrink-0" />
                  <span className="text-white/90 text-sm md:text-base">{feature}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Guarantee */}
        <div className="text-center mt-8 md:mt-12">
          <div className="inline-flex items-center bg-green-500/20 rounded-full px-3 py-2 md:px-6 md:py-3 border border-green-500/30">
            <Shield className="w-4 h-4 md:w-6 md:h-6 text-green-400 mr-2 md:mr-3" />
            <span className="text-green-400 font-semibold text-xs md:text-base">
              <span className="block md:hidden">Garantia 30 dias - 100% reembolso</span>
              <span className="hidden md:block">Garantia de 30 dias - 100% do seu dinheiro de volta</span>
            </span>
          </div>
          <p className="text-white/80 mt-3 md:mt-4 max-w-md mx-auto text-sm md:text-base">
            Não gostou? Devolvemos todo seu dinheiro, sem perguntas.
          </p>
        </div>
      </div>
    </section>
  );
};

export default Pricing;