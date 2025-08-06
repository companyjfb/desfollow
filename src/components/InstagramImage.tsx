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
    // Usar API de proxy diretamente para imagens Instagram
    const processedUrl = getInstagramImageUrl(src);
    console.log('🔄 Processando imagem:', { original: src, processed: processedUrl });
    
    setImgSrc(processedUrl);
    setHasError(false);
    setIsLoading(true);
  }, [src]);

  const handleError = () => {
    if (!hasError) {
      setHasError(true);
      console.log('❌ Erro ao carregar imagem via API:', imgSrc);
      
      // Se a API falhou, usa o fallback diretamente
      setImgSrc(fallback);
    } else {
      // Se já tentou e falhou, usa o fallback
      console.log('❌ Usando fallback após falha');
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