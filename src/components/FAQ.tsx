import { useState } from 'react';
import { ChevronDown, Shield, Clock, UserCheck, Star } from 'lucide-react';

const FAQ = () => {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const faqs = [
    {
      question: "Como vocês descobrem quem não me segue de volta?",
      answer: "Analisamos sua lista de seguidores e quem você segue, fazendo uma comparação inteligente para identificar exatamente quem não retribui o follow. Tudo de forma segura e respeitando os termos do Instagram."
    },
    {
      question: "É seguro usar o Desfollow?",
      answer: "Sim, totalmente seguro! Não pedimos sua senha, apenas fazemos a análise pública dos seus seguidores. Utilizamos apenas informações públicas disponíveis no Instagram, respeitando todos os termos de uso."
    },
    {
      question: "Quanto tempo leva para ver os resultados?",
      answer: "O processo é quase instantâneo! Após inserir seu nome de usuário, nossa análise leva apenas alguns segundos para mostrar a lista completa de quem não te segue de volta."
    },
    {
      question: "Posso usar em contas privadas?",
      answer: "Sim, funciona tanto para contas públicas quanto privadas. A análise é feita de forma segura independente do tipo de conta que você possui."
    },
    {
      question: "Vocês guardam minhas informações?",
      answer: "Não guardamos nenhuma informação pessoal. Fazemos apenas a análise momentânea e você recebe os resultados imediatamente. Respeitamos totalmente sua privacidade."
    },
    {
      question: "E se eu não gostar do resultado?",
      answer: "Oferecemos 30 dias de garantia total! Se não ficar satisfeito com o serviço, devolvemos 100% do valor pago, sem perguntas."
    },
    {
      question: "Posso usar quantas vezes quiser?",
      answer: "Sim! Com sua assinatura, você pode fazer análises ilimitadas da sua conta sempre que quiser atualizar sua lista de não-seguidores."
    },
    {
      question: "Funciona em todos os tipos de conta?",
      answer: "Sim, funciona para contas pessoais, empresariais e de criadores de conteúdo. Não importa o tamanho da sua conta, nossa análise é eficiente para todos."
    }
  ];

  const toggleFAQ = (index: number) => {
    setOpenIndex(openIndex === index ? null : index);
  };

  return (
    <section className="py-12 md:py-20 bg-gradient-to-b from-slate-900 to-instagram-blue">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12 md:mb-16">
          <h2 className="text-2xl md:text-4xl lg:text-5xl font-bold text-white mb-4 md:mb-6 font-inter">
            Perguntas <span className="text-white">Frequentes</span>
          </h2>
          <p className="text-base md:text-xl text-white max-w-2xl mx-auto">
            Tire suas dúvidas sobre como descobrir quem não te segue de volta
          </p>
        </div>

        <div className="max-w-4xl mx-auto">
          <div className="space-y-3 md:space-y-4">
            {faqs.map((faq, index) => (
              <div 
                key={index}
                className="bg-white/5 backdrop-blur-md rounded-xl md:rounded-2xl border border-white/10 hover:border-neon-pink/30 transition-all duration-300 animate-fade-in"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <button
                  onClick={() => toggleFAQ(index)}
                  className="w-full text-left p-4 md:p-6 flex items-center justify-between focus:outline-none"
                >
                  <h3 className="text-base md:text-lg font-semibold text-white pr-3 md:pr-4">{faq.question}</h3>
                  <ChevronDown 
                    className={`w-4 h-4 md:w-5 md:h-5 text-neon-pink transition-transform duration-300 flex-shrink-0 ${
                      openIndex === index ? 'rotate-180' : ''
                    }`}
                  />
                </button>
                
                <div className={`overflow-hidden transition-all duration-300 ${
                  openIndex === index ? 'max-h-96 opacity-100' : 'max-h-0 opacity-0'
                }`}>
                  <div className="px-4 pb-4 md:px-6 md:pb-6">
                    <p className="text-white/90 leading-relaxed text-sm md:text-base">{faq.answer}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Trust badges */}
          <div className="mt-12 md:mt-16 grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
            <div className="text-center">
              <div className="bg-gradient-to-r from-neon-pink to-neon-purple p-3 md:p-4 rounded-xl md:rounded-2xl w-fit mx-auto mb-2 md:mb-3">
                <Shield className="w-5 h-5 md:w-6 md:h-6 text-white" />
              </div>
              <h4 className="text-white font-semibold mb-1 text-sm md:text-base">100% Seguro</h4>
              <p className="text-white/80 text-xs md:text-sm">Sem acesso à sua conta</p>
            </div>
            
            <div className="text-center">
              <div className="bg-gradient-to-r from-neon-purple to-neon-orange p-3 md:p-4 rounded-xl md:rounded-2xl w-fit mx-auto mb-2 md:mb-3">
                <Clock className="w-5 h-5 md:w-6 md:h-6 text-white" />
              </div>
              <h4 className="text-white font-semibold mb-1 text-sm md:text-base">Instantâneo</h4>
              <p className="text-white/80 text-xs md:text-sm">Resultados em segundos</p>
            </div>
            
            <div className="text-center">
              <div className="bg-gradient-to-r from-neon-orange to-neon-pink p-3 md:p-4 rounded-xl md:rounded-2xl w-fit mx-auto mb-2 md:mb-3">
                <UserCheck className="w-5 h-5 md:w-6 md:h-6 text-white" />
              </div>
              <h4 className="text-white font-semibold mb-1 text-sm md:text-base">Confiável</h4>
              <p className="text-white/80 text-xs md:text-sm">+50k usuários satisfeitos</p>
            </div>
            
            <div className="text-center">
              <div className="bg-gradient-to-r from-neon-pink to-instagram-blue p-3 md:p-4 rounded-xl md:rounded-2xl w-fit mx-auto mb-2 md:mb-3">
                <Star className="w-5 h-5 md:w-6 md:h-6 text-white" />
              </div>
              <h4 className="text-white font-semibold mb-1 text-sm md:text-base">Garantia</h4>
              <p className="text-white/80 text-xs md:text-sm">30 dias de garantia</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default FAQ;