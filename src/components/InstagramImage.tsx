import React, { useState, useEffect, useRef } from 'react';
import { getInstagramImageUrl } from '../utils/instagram-image-url';

interface InstagramImageProps {
  src: string;
  alt: string;
  className?: string;
  fallback?: string;
  maxRetries?: number;
  retryDelay?: number;
}

const InstagramImage: React.FC<InstagramImageProps> = ({ 
  src, 
  alt, 
  className, 
  fallback = '/placeholder.svg',
  maxRetries = 10,
  retryDelay = 2000 
}) => {
  const [imgSrc, setImgSrc] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  const [retryCount, setRetryCount] = useState(0);
  const retryTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    // Reset retry counter quando a URL src mudar
    setRetryCount(0);
    
    // Usar API de proxy diretamente para imagens Instagram
    const processedUrl = getInstagramImageUrl(src);
    console.log('🔄 Processando imagem:', { original: src, processed: processedUrl });
    
    setImgSrc(processedUrl);
    setIsLoading(true);
    
    // Limpar timeout anterior se existir
    if (retryTimeoutRef.current) {
      clearTimeout(retryTimeoutRef.current);
    }
  }, [src]);

  // Limpar timeout quando componente desmonta
  useEffect(() => {
    return () => {
      if (retryTimeoutRef.current) {
        clearTimeout(retryTimeoutRef.current);
      }
    };
  }, []);

  const handleError = () => {
    console.log(`❌ Erro ao carregar imagem (tentativa ${retryCount + 1}/${maxRetries}):`, imgSrc);
    
    if (retryCount < maxRetries) {
      // Incrementar contador de retry
      const newRetryCount = retryCount + 1;
      setRetryCount(newRetryCount);
      
      // Aguardar um pouco antes de tentar novamente
      retryTimeoutRef.current = setTimeout(() => {
        console.log(`🔄 Tentativa ${newRetryCount}/${maxRetries} - Recarregando imagem:`, imgSrc);
        
        // Força o reload da imagem adicionando um timestamp
        const processedUrl = getInstagramImageUrl(src);
        const urlWithTimestamp = `${processedUrl}&retry=${newRetryCount}&t=${Date.now()}`;
        setImgSrc(urlWithTimestamp);
      }, retryDelay);
    } else {
      console.log(`❌ Máximo de tentativas (${maxRetries}) excedido. Parando tentativas.`);
      setIsLoading(false); // Para o loading após esgotar tentativas
    }
  };

  const handleLoad = () => {
    setIsLoading(false);
    console.log(`✅ Imagem carregada com sucesso (após ${retryCount} tentativas):`, imgSrc);
    
    // Reset retry counter quando imagem carrega com sucesso
    setRetryCount(0);
    
    // Limpar timeout se imagem carregou
    if (retryTimeoutRef.current) {
      clearTimeout(retryTimeoutRef.current);
    }
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