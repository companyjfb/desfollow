
import { Star, Heart, ThumbsUp } from 'lucide-react';

const Testimonials = () => {
  const testimonials = [
    {
      name: "Bianca Duarte",
      avatar: "/lovable-uploads/b1878feb-16ec-438c-8e37-5258266aedd6.png",
      text: "Achei que era coisa da minha cabeça, mas o Desfollow mostrou quem deixou de me seguir sem dó",
      likes: 247,
      verified: true,
      timestamp: "há 1h"
    },
    {
      name: "Lucas Amaral",
      avatar: "/lovable-uploads/e68925cd-de9e-4a40-af01-9140ea754f19.png",
      text: "Tinha gente que me respondia todo dia e mesmo assim deixou de me seguir. Falsidade bateu forte.",
      likes: 182,
      verified: true,
      timestamp: "há 3h"
    },
    {
      name: "Lívia Costa",
      avatar: "/lovable-uploads/33aa29b9-8e1b-4bbd-a830-a39142d2eef1.png",
      text: "Postava story e jurava que tava arrasando... até ver que metade que assiste nem me segue mais.",
      likes: 156,
      verified: false,
      timestamp: "há 5h"
    },
    {
      name: "Bruno Teixeira",
      avatar: "/lovable-uploads/9f866110-593f-4b97-8114-69e63345ffb3.png",
      text: "Usei o Desfollow por curiosidade. Acabei levando um choque de realidade.",
      likes: 203,
      verified: true,
      timestamp: "há 2h"
    },
    {
      name: "Camila Ribeiro",
      avatar: "/lovable-uploads/c86c9416-e19f-4e6c-b96a-981764455220.png",
      text: "Gente que curte tudo e comenta, mas deixou de me seguir há semanas 😒",
      likes: 189,
      verified: true,
      timestamp: "há 4h"
    },
    {
      name: "Henrique Silva",
      avatar: "/lovable-uploads/e4cc8fae-cf86-4234-83bc-7a4cbb3e3537.png",
      text: "Descobri que meus stories viraram entretenimento gratuito pra gente que nem me acompanha mais.",
      likes: 167,
      verified: false,
      timestamp: "há 6h"
    },
    {
      name: "Talita Nunes",
      avatar: "/lovable-uploads/a1ff2d2a-90ed-4aca-830b-0fa8e772a3ad.png",
      text: "Me senti mais leve depois de limpar quem só me usava de termômetro e não seguia de volta.",
      likes: 224,
      verified: true,
      timestamp: "há 1h"
    },
    {
      name: "Matheus Azevedo",
      avatar: "/lovable-uploads/82f11f27-4149-4c8f-b121-63897652035d.png",
      text: "O aplicativo me entregou nomes que eu nem imaginava. Gente próxima que já tinha deixado de me seguir faz tempo.",
      likes: 195,
      verified: true,
      timestamp: "há 3h"
    },
    {
      name: "Juliana Monteiro",
      avatar: "/lovable-uploads/c66eb0c2-8d6f-4575-93e6-9aa364372325.png",
      text: "Ela se acha tão famosa que me deixou de seguir mas continua vendo tudo. O Desfollow só confirmou o recalque.",
      likes: 312,
      verified: true,
      timestamp: "há 7h"
    },
    {
      name: "Bruna Ribeiro",
      avatar: "/lovable-uploads/f0a979d5-6bb6-41bf-b8da-6791918e6540.png",
      text: "Sempre desconfiei daquela 'amiga'. O Desfollow mostrou que ela me largou faz tempo, mas ainda vive assistindo meus stories.",
      likes: 278,
      verified: true,
      timestamp: "há 4h"
    },
    {
      name: "Camila Borges",
      avatar: "/lovable-uploads/af2d2ebb-fbfe-482f-8498-03515c511b97.png",
      text: "Quando vi que minha melhor amiga me deixou de seguir, eu travei. E o pior? Ainda via todos os meus stories. O Desfollow me mostrou a verdade que eu ignorava.",
      likes: 267,
      verified: true,
      timestamp: "há 2h"
    },
    {
      name: "Letícia Ramos",
      avatar: "/lovable-uploads/8e9dfc00-1145-43b9-9f22-4a3de6e807ca.png",
      text: "Descobri que meu ex me deixou de seguir, mas continuava vendo tudo que eu postava. Sério… que vergonha alheia. O Desfollow entregou na hora",
      likes: 234,
      verified: true,
      timestamp: "há 5h"
    }
  ];

  return (
    <section className="py-16 md:py-24 bg-gradient-to-b from-instagram-blue via-purple-900 to-slate-900 relative overflow-hidden">
      {/* Background effects */}
      <div className="absolute inset-0 bg-gradient-to-r from-purple-600/10 via-pink-600/10 to-blue-600/10 animate-pulse"></div>
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-pink-500/20 rounded-full blur-3xl animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-500/20 rounded-full blur-3xl animate-pulse delay-1000"></div>
      
      <div className="container mx-auto px-4 relative z-10">
        <div className="text-center mb-16 md:mb-20">
          <div className="inline-block">
            <h2 className="text-3xl md:text-5xl lg:text-6xl font-bold text-white mb-6 md:mb-8 font-inter leading-tight">
              O que nossos usuários <br />
              <span className="bg-gradient-to-r from-pink-400 via-purple-400 to-blue-400 bg-clip-text text-transparent animate-pulse">
                estão dizendo
              </span>
            </h2>
          </div>
          <p className="text-lg md:text-2xl text-white/90 max-w-3xl mx-auto mb-8 md:mb-10 font-medium">
            Milhares de pessoas já descobriram quem não as segue de volta.
          </p>
          <div className="inline-flex items-center bg-gradient-to-r from-green-500/30 to-emerald-500/30 rounded-full px-6 py-3 md:px-8 md:py-4 border border-green-400/50 mb-8 md:mb-12 shadow-lg backdrop-blur-md">
            <span className="text-green-300 font-bold text-sm md:text-lg">✓ 30 dias de garantia total</span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 md:gap-8 max-w-7xl mx-auto">
          {testimonials.map((testimonial, index) => (
            <div 
              key={index}
              className="group bg-gradient-to-br from-white/15 to-white/5 backdrop-blur-xl rounded-2xl md:rounded-3xl p-6 md:p-8 border border-white/30 hover:border-pink-400/60 transition-all duration-500 transform hover:scale-110 hover:-translate-y-2 animate-fade-in shadow-2xl hover:shadow-pink-500/25"
              style={{ animationDelay: `${index * 0.15}s` }}
            >
              {/* Story-like header */}
              <div className="flex items-center mb-4 md:mb-5">
                <div className="relative">
                  <div className="absolute -inset-1 bg-gradient-to-r from-pink-500 via-purple-500 to-blue-500 rounded-full blur opacity-60 group-hover:opacity-100 animate-pulse"></div>
                  <img 
                    src={testimonial.avatar} 
                    alt={testimonial.name}
                    className="relative w-12 h-12 md:w-14 md:h-14 rounded-full border-3 border-white/50 object-cover shadow-lg"
                  />
                  <div className="absolute -bottom-1 -right-1 bg-gradient-to-r from-pink-500 to-purple-500 rounded-full p-1 shadow-lg">
                    <div className="bg-white rounded-full p-1">
                      <Heart className="w-3 h-3 md:w-4 md:h-4 text-pink-500 fill-current animate-pulse" />
                    </div>
                  </div>
                </div>
                <div className="ml-3 flex-1">
                  <div className="flex items-center">
                    <span className="text-white font-bold text-sm md:text-base">{testimonial.name}</span>
                    {testimonial.verified && (
                      <div className="ml-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full p-1 shadow-md">
                        <div className="w-3 h-3 md:w-4 md:h-4 bg-white rounded-full flex items-center justify-center">
                          <div className="w-1.5 h-1.5 bg-blue-500 rounded-full"></div>
                        </div>
                      </div>
                    )}
                  </div>
                  <span className="text-white/70 text-xs md:text-sm">{testimonial.timestamp}</span>
                </div>
              </div>

              {/* Content */}
              <p className="text-white/95 mb-4 md:mb-5 text-sm md:text-base leading-relaxed font-medium group-hover:text-white transition-colors duration-300">
                {testimonial.text}
              </p>

              {/* Engagement */}
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3 md:space-x-4">
                  <button className="flex items-center space-x-1.5 text-pink-400 hover:text-pink-300 transition-colors duration-300 group-hover:scale-110">
                    <Heart className="w-4 h-4 md:w-5 md:h-5 fill-current animate-pulse" />
                    <span className="text-sm font-bold">{testimonial.likes}</span>
                  </button>
                  <button className="flex items-center space-x-1.5 text-white/80 hover:text-white transition-colors duration-300 group-hover:scale-110">
                    <ThumbsUp className="w-4 h-4 md:w-5 md:h-5" />
                    <span className="text-sm font-medium">Curtir</span>
                  </button>
                </div>
                <div className="flex space-x-0.5">
                  {[...Array(5)].map((_, i) => (
                    <Star 
                      key={i} 
                      className="w-4 h-4 md:w-5 md:h-5 text-yellow-400 fill-current animate-pulse group-hover:scale-110" 
                      style={{ animationDelay: `${i * 0.1}s` }}
                    />
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Testimonials;
