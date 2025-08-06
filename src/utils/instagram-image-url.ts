/**
 * Converte URLs de imagens do Instagram para usar o proxy transparente do Nginx
 */
export function getInstagramImageUrl(originalUrl: string): string {
  // Se não é uma URL de imagem do Instagram/Facebook, retorna original
  if (!originalUrl || typeof originalUrl !== 'string') {
    return originalUrl;
  }

  // Detecta URLs do Instagram/Facebook CDN
  const isInstagramImage = originalUrl.includes('instagram.com') || 
                          originalUrl.includes('cdninstagram.com') || 
                          originalUrl.includes('fbcdn.net') || 
                          originalUrl.includes('scontent');

  if (!isInstagramImage) {
    return originalUrl;
  }

  try {
    // Remove protocolo da URL original
    const urlWithoutProtocol = originalUrl.replace(/^https?:\/\//, '');
    
    // Constrói URL do proxy transparente
    const baseUrl = window.location.hostname === 'localhost' 
      ? 'http://localhost:3000'  // Para desenvolvimento local
      : 'https://www.desfollow.com.br';  // Para produção
    
    const proxyUrl = `${baseUrl}/instagram-proxy/${urlWithoutProtocol}`;
    
    console.log('🔄 Convertendo URL Instagram:', {
      original: originalUrl,
      proxy: proxyUrl
    });
    
    return proxyUrl;
  } catch (error) {
    console.error('❌ Erro ao converter URL Instagram:', error);
    return originalUrl;
  }
}

/**
 * Hook para converter URLs de imagens automaticamente
 */
export function useInstagramImageUrl(originalUrl: string): string {
  return getInstagramImageUrl(originalUrl);
}