import React, { useState, useEffect } from 'react';
import { getInstagramImageUrl } from '../utils/instagram-image-url';

interface InstagramImageProps {
  src: string;
  alt: string;
  className?: string;
  fallback?: string;
}

const InstagramImage: React.FC<InstagramImageProps> = ({ 
  src, 
  alt, 
  className, 
  fallback = '/placeholder.svg' 
}) => {
  const [imgSrc, setImgSrc] = useState<string>('');
  const [hasError, setHasError] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Usar proxy transparente automaticamente para imagens Instagram
    const processedUrl = getInstagramImageUrl(src);
    console.log('🔄 Processando imagem:', { original: src, processed: processedUrl });
    
    setImgSrc(processedUrl);
    setHasError(false);
    setIsLoading(true);
  }, [src]);

  const handleError = () => {
    if (!hasError) {
      setHasError(true);
      console.log('❌ Erro ao carregar imagem (proxy transparente falhou):', imgSrc);
      
      // Se o proxy transparente falhou, tenta o proxy da API como backup
      if (src.includes('instagram.com') || src.includes('cdninstagram.com') || src.includes('fbcdn.net') || src.includes('scontent')) {
        const apiProxyUrl = window.location.hostname === 'localhost' 
          ? `http://localhost:8000/api/proxy-image?url=${encodeURIComponent(src)}`
          : `https://api.desfollow.com.br/api/proxy-image?url=${encodeURIComponent(src)}`;
        console.log('🔄 Tentando proxy da API como backup:', apiProxyUrl);
        setImgSrc(apiProxyUrl);
        setHasError(false);
        return;
      }
      
      // Se não funcionou, usa o fallback
      setImgSrc(fallback);
    } else {
      // Se já tentou tudo e falhou, usa o fallback
      console.log('❌ Todas as tentativas falharam, usando fallback');
      setImgSrc(fallback);
    }
  };

  const handleLoad = () => {
    setIsLoading(false);
    console.log('✅ Imagem carregada com sucesso:', imgSrc);
  };

  return (
    <div className={`relative ${className}`}>
      {isLoading && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse rounded-full flex items-center justify-center">
          <div className="w-4 h-4 border-2 border-gray-400 border-t-transparent rounded-full animate-spin"></div>
        </div>
      )}
      <img
        src={imgSrc}
        alt={alt}
        className={`${className} ${isLoading ? 'opacity-0' : 'opacity-100'} transition-opacity duration-300`}
        onError={handleError}
        onLoad={handleLoad}
        crossOrigin="anonymous"
      />
    </div>
  );
};

export default InstagramImage; 