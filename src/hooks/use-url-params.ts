import { useLocation } from 'react-router-dom';

/**
 * Hook para preservar parâmetros UTM através de todas as páginas
 */
export const useUrlParams = () => {
  const location = useLocation();

  // Extrair todos os parâmetros da URL atual
  const urlParams = new URLSearchParams(location.search);
  
  // Lista completa de parâmetros a preservar
  const preservedParams = {
    // UTMs tradicionais
    utm_source: urlParams.get('utm_source'),
    utm_medium: urlParams.get('utm_medium'),
    utm_campaign: urlParams.get('utm_campaign'),
    utm_content: urlParams.get('utm_content'),
    utm_term: urlParams.get('utm_term'),
    
    // Parâmetros customizados
    src: urlParams.get('src'),
    fbclid: urlParams.get('fbclid'),
    gclid: urlParams.get('gclid'),
    
    // Parâmetros específicos do Perfect Pay
    utm_perfect: urlParams.get('utm_perfect'),
    
    // Outros parâmetros que podem existir
    ref: urlParams.get('ref'),
    affiliate: urlParams.get('affiliate'),
    promo: urlParams.get('promo'),
    
    // Status de pagamento
    payment: urlParams.get('payment'),
  };

  /**
   * Constrói uma query string com os parâmetros preservados
   */
  const buildQueryString = (additionalParams: Record<string, string | null> = {}) => {
    const params = new URLSearchParams();
    
    // Adicionar parâmetros preservados
    Object.entries(preservedParams).forEach(([key, value]) => {
      if (value) params.set(key, value);
    });
    
    // Adicionar parâmetros adicionais
    Object.entries(additionalParams).forEach(([key, value]) => {
      if (value) params.set(key, value);
    });
    
    return params.toString();
  };

  /**
   * Constrói uma URL completa com parâmetros preservados
   */
  const buildUrlWithParams = (path: string, additionalParams: Record<string, string | null> = {}) => {
    const queryString = buildQueryString(additionalParams);
    return queryString ? `${path}?${queryString}` : path;
  };

  /**
   * Função para debug - mostra todos os parâmetros capturados
   */
  const debugParams = () => {
    console.log('🔗 Parâmetros URL preservados:', preservedParams);
    const filteredParams = Object.fromEntries(
      Object.entries(preservedParams).filter(([_, value]) => value !== null)
    );
    console.log('🔗 Parâmetros não-nulos:', filteredParams);
    return filteredParams;
  };

  return {
    preservedParams,
    buildQueryString,
    buildUrlWithParams,
    debugParams,
  };
};