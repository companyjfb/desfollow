/**
 * Converte URLs de imagens do Instagram para usar diretamente a API de proxy
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
    // Usa diretamente a API de proxy que funciona
    const apiProxyUrl = window.location.hostname === 'localhost' 
      ? `http://localhost:8000/api/proxy-image?url=${encodeURIComponent(originalUrl)}`
      : `https://api.desfollow.com.br/api/proxy-image?url=${encodeURIComponent(originalUrl)}`;
    
    console.log('🔄 Convertendo URL Instagram (API direta):', {
      original: originalUrl,
      proxy: apiProxyUrl
    });
    
    return apiProxyUrl;
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