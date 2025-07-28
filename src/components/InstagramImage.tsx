import React, { useState, useEffect } from 'react';

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
  const [imgSrc, setImgSrc] = useState<string>(src);
  const [hasError, setHasError] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    setImgSrc(src);
    setHasError(false);
    setIsLoading(true);
  }, [src]);

  const handleError = () => {
    if (!hasError) {
      setHasError(true);
      console.log('❌ Erro ao carregar imagem:', src);
      
      // Se é uma URL do Instagram, tenta usar o proxy
      if (src.includes('instagram.com') || src.includes('cdninstagram.com')) {
        const proxyUrl = `http://localhost:8000/api/proxy-image?url=${encodeURIComponent(src)}`;
        console.log('🔄 Tentando proxy:', proxyUrl);
        setImgSrc(proxyUrl);
        setHasError(false);
        return;
      }
      
      // Se não funcionou, usa o fallback
      setImgSrc(fallback);
    } else {
      // Se já tentou o proxy e falhou, usa o fallback
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