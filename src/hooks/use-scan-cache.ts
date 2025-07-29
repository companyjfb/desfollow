import { useState, useEffect } from 'react';

interface ScanData {
  status: string;
  count: number;
  sample: string[];
  all: string[];
  ghosts_details: any[];
  real_ghosts: any[];
  famous_ghosts: any[];
  real_ghosts_count: number;
  famous_ghosts_count: number;
  profile_info: any;
}

interface StatusResponse {
  status: string;
  count?: number;
  sample?: string[];
  all?: string[];
  ghosts_details?: any[];
  real_ghosts?: any[];
  famous_ghosts?: any[];
  real_ghosts_count?: number;
  famous_ghosts_count?: number;
  profile_info?: any;
  error?: string;
}

interface CachedScanData {
  data: ScanData;
  timestamp: number;
  username: string;
}

const CACHE_EXPIRY_HOURS = 24; // Cache expira em 24 horas
const STORAGE_KEY_PREFIX = 'desfollow_scan_';

export const useScanCache = () => {
  
  const isExpired = (timestamp: number): boolean => {
    const now = Date.now();
    const expiry = CACHE_EXPIRY_HOURS * 60 * 60 * 1000; // 24h em ms
    return (now - timestamp) > expiry;
  };

  const convertToScanData = (response: StatusResponse): ScanData => {
    return {
      status: response.status,
      count: response.count || 0,
      sample: response.sample || [],
      all: response.all || [],
      ghosts_details: response.ghosts_details || [],
      real_ghosts: response.real_ghosts || [],
      famous_ghosts: response.famous_ghosts || [],
      real_ghosts_count: response.real_ghosts_count || 0,
      famous_ghosts_count: response.famous_ghosts_count || 0,
      profile_info: response.profile_info || {}
    };
  };

  const saveScanToCache = (username: string, scanData: ScanData | StatusResponse) => {
    try {
      // Converter StatusResponse para ScanData se necessário
      const normalizedData: ScanData = ('count' in scanData && typeof scanData.count === 'number') 
        ? scanData as ScanData 
        : convertToScanData(scanData as StatusResponse);
      
      const cacheData: CachedScanData = {
        data: normalizedData,
        timestamp: Date.now(),
        username: username.toLowerCase()
      };
      
      localStorage.setItem(
        `${STORAGE_KEY_PREFIX}${username.toLowerCase()}`, 
        JSON.stringify(cacheData)
      );
      
      console.log(`💾 Scan salvo no cache local para: @${username}`);
    } catch (error) {
      console.warn('⚠️ Erro ao salvar no cache local:', error);
    }
  };

  const getScanFromCache = (username: string): ScanData | null => {
    try {
      const cached = localStorage.getItem(`${STORAGE_KEY_PREFIX}${username.toLowerCase()}`);
      
      if (!cached) {
        console.log(`📭 Nenhum cache encontrado para: @${username}`);
        return null;
      }

      const cacheData: CachedScanData = JSON.parse(cached);
      
      if (isExpired(cacheData.timestamp)) {
        console.log(`⏰ Cache expirado para: @${username} (${Math.round((Date.now() - cacheData.timestamp) / (1000 * 60 * 60))}h atrás)`);
        localStorage.removeItem(`${STORAGE_KEY_PREFIX}${username.toLowerCase()}`);
        return null;
      }

      console.log(`✅ Cache válido encontrado para: @${username} (${Math.round((Date.now() - cacheData.timestamp) / (1000 * 60))} min atrás)`);
      return cacheData.data;
    } catch (error) {
      console.warn('⚠️ Erro ao ler cache local:', error);
      return null;
    }
  };

  const getScanFromHistory = async (username: string): Promise<ScanData | null> => {
    try {
      console.log(`🔍 Buscando histórico no banco para: @${username}`);
      
      const response = await fetch(`/api/user/${username}/history`);
      
      if (!response.ok) {
        console.log(`📭 Nenhum histórico encontrado no banco para: @${username}`);
        return null;
      }

      const scans = await response.json();
      
      if (!scans || scans.length === 0) {
        console.log(`📭 Histórico vazio para: @${username}`);
        return null;
      }

      const latestScan = scans[0];
      
      // Verificar se o scan é recente (menos de 24h)
      const scanAge = Date.now() - new Date(latestScan.created_at).getTime();
      const ageInHours = scanAge / (1000 * 60 * 60);
      
      if (ageInHours > CACHE_EXPIRY_HOURS) {
        console.log(`⏰ Scan do banco muito antigo para: @${username} (${Math.round(ageInHours)}h atrás)`);
        return null;
      }

      // Converter formato do banco para formato do frontend
      const scanData: ScanData = {
        status: 'done',
        count: latestScan.ghosts_count || 0,
        sample: latestScan.ghosts_data?.slice(0, 10) || [],
        all: latestScan.ghosts_data || [],
        ghosts_details: latestScan.ghosts_data || [],
        real_ghosts: latestScan.real_ghosts || [],
        famous_ghosts: latestScan.famous_ghosts || [],
        real_ghosts_count: latestScan.real_ghosts_count || 0,
        famous_ghosts_count: latestScan.famous_ghosts_count || 0,
        profile_info: latestScan.profile_info || {}
      };

      console.log(`✅ Dados encontrados no banco para: @${username} (${Math.round(ageInHours * 60)} min atrás)`);
      
      // Salvar no cache local para próximas consultas
      saveScanToCache(username, scanData);
      
      return scanData;
    } catch (error) {
      console.warn('⚠️ Erro ao buscar histórico no banco:', error);
      return null;
    }
  };

  const getCachedOrFetchScan = async (username: string): Promise<ScanData | null> => {
    console.log(`🔍 Buscando dados para: @${username}`);
    
    // 1. Tentar cache local primeiro
    let scanData = getScanFromCache(username);
    if (scanData) {
      return scanData;
    }

    // 2. Buscar no histórico do banco
    scanData = await getScanFromHistory(username);
    if (scanData) {
      return scanData;
    }

    // 3. Nenhum dado encontrado
    console.log(`📭 Nenhum dado encontrado para: @${username}`);
    return null;
  };

  const clearExpiredCache = () => {
    try {
      const keys = Object.keys(localStorage);
      let cleared = 0;
      
      keys.forEach(key => {
        if (key.startsWith(STORAGE_KEY_PREFIX)) {
          try {
            const cached = localStorage.getItem(key);
            if (cached) {
              const cacheData: CachedScanData = JSON.parse(cached);
              if (isExpired(cacheData.timestamp)) {
                localStorage.removeItem(key);
                cleared++;
              }
            }
          } catch (error) {
            // Remove chaves corrompidas
            localStorage.removeItem(key);
            cleared++;
          }
        }
      });
      
      if (cleared > 0) {
        console.log(`🧹 ${cleared} caches expirados removidos`);
      }
    } catch (error) {
      console.warn('⚠️ Erro ao limpar cache expirado:', error);
    }
  };

  // Limpar cache expirado ao inicializar
  useEffect(() => {
    clearExpiredCache();
  }, []);

  return {
    saveScanToCache,
    getScanFromCache,
    getScanFromHistory,
    getCachedOrFetchScan,
    clearExpiredCache
  };
}; 