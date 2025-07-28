
import { Mail, MessageCircle, Shield, FileText, HelpCircle } from 'lucide-react';

const Footer = () => {
  return (
    <footer className="bg-slate-900 py-12 md:py-16">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 md:gap-8 mb-8 md:mb-12">
          {/* Brand */}
          <div className="col-span-1 text-center md:text-left">
            <div className="flex items-center justify-center md:justify-start mb-4 md:mb-6">
              <img src="/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png" alt="Desfollow Logo" className="w-10 h-10 md:w-12 md:h-12 mr-2 md:mr-3" />
              <h3 className="text-lg md:text-xl font-bold bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 bg-clip-text text-transparent font-inter">Desfollow</h3>
            </div>
            <p className="text-slate-400 mb-4 md:mb-6 text-sm md:text-base">
              A ferramenta mais inteligente para descobrir quem não te segue de volta no Instagram.
            </p>
            <div className="flex justify-center md:justify-start space-x-3 md:space-x-4">
              <a href="#" className="bg-white/10 p-2 md:p-3 rounded-full hover:bg-neon-pink/20 transition-colors">
                <img src="/lovable-uploads/b7dde072-9f5b-476f-80ea-ff351b4129bd.png" alt="Desfollow Logo" className="w-4 h-4 md:w-5 md:h-5" />
              </a>
              <a href="#" className="bg-white/10 p-2 md:p-3 rounded-full hover:bg-neon-pink/20 transition-colors">
                <Mail className="w-4 h-4 md:w-5 md:h-5 text-white" />
              </a>
              <a href="#" className="bg-white/10 p-2 md:p-3 rounded-full hover:bg-neon-pink/20 transition-colors">
                <MessageCircle className="w-4 h-4 md:w-5 md:h-5 text-white" />
              </a>
            </div>
          </div>

          {/* Product */}
          <div className="text-center md:text-left">
            <h4 className="text-white font-semibold mb-4 md:mb-6 text-sm md:text-base">Produto</h4>
            <ul className="space-y-2 md:space-y-3">
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">Como funciona</a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">Preços</a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">Depoimentos</a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">API</a></li>
            </ul>
          </div>

          {/* Support */}
          <div className="text-center md:text-left">
            <h4 className="text-white font-semibold mb-4 md:mb-6 text-sm md:text-base">Suporte</h4>
            <ul className="space-y-2 md:space-y-3">
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors flex items-center justify-center md:justify-start text-sm md:text-base">
                <HelpCircle className="w-3 h-3 md:w-4 md:h-4 mr-2" />
                Central de Ajuda
              </a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">FAQ</a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">Contato</a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">Status</a></li>
            </ul>
          </div>

          {/* Legal */}
          <div className="text-center md:text-left">
            <h4 className="text-white font-semibold mb-4 md:mb-6 text-sm md:text-base">Legal</h4>
            <ul className="space-y-2 md:space-y-3">
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors flex items-center justify-center md:justify-start text-sm md:text-base">
                <FileText className="w-3 h-3 md:w-4 md:h-4 mr-2" />
                Termos de Uso
              </a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors flex items-center justify-center md:justify-start text-sm md:text-base">
                <Shield className="w-3 h-3 md:w-4 md:h-4 mr-2" />
                Política de Privacidade
              </a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">Cookies</a></li>
              <li><a href="#" className="text-slate-400 hover:text-neon-pink transition-colors text-sm md:text-base">LGPD</a></li>
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div className="pt-6 md:pt-8 border-t border-slate-800">
          <div className="flex flex-col md:flex-row justify-between items-center text-center md:text-left">
            <p className="text-slate-400 text-xs md:text-sm mb-3 md:mb-0">
              © 2024 Desfollow. Todos os direitos reservados.
            </p>
            <div className="flex items-center justify-center space-x-4 md:space-x-6 text-xs md:text-sm text-slate-400">
              <span>🇧🇷 Feito no Brasil</span>
              <span>•</span>
              <span>Suporte 24/7</span>
              <span>•</span>
              <span>Pagamento seguro</span>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
