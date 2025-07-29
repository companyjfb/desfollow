// Detecta automaticamente o host correto baseado na origem atual
const getApiBaseUrl = () => {
  const host = window.location.hostname;
  const protocol = window.location.protocol; // 'http:' ou 'https:'
  
  // Para produção, usa a API subdomain com o mesmo protocolo
  if (host === 'desfollow.com.br' || host === 'www.desfollow.com.br') {
    return `${protocol}//api.desfollow.com.br/api`;
  }
  
  // Para api.desfollow.com.br, usa o mesmo host
  if (host === 'api.desfollow.com.br') {
    return `${protocol}//api.desfollow.com.br/api`;
  }
  
  // Para outros domínios, tenta usar o mesmo host
  return `${protocol}//${host}/api`;
};

const API_BASE_URL = getApiBaseUrl();

export interface ScanRequest {
  username: string;
}

export interface ScanResponse {
  job_id: string;
}

export interface StatusResponse {
  status: 'queued' | 'running' | 'done' | 'error';
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

/**
 * Inicia um scan para encontrar usuários que não retribuem o follow.
 */
export async function startScan(username: string): Promise<ScanResponse> {
  const response = await fetch(`${API_BASE_URL}/scan`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ username }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'Erro ao iniciar scan');
  }

  return response.json();
}

/**
 * Verifica o status de um scan em andamento.
 */
export async function pollScan(jobId: string): Promise<StatusResponse> {
  const response = await fetch(`${API_BASE_URL}/scan/${jobId}`);

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.detail || 'Erro ao verificar status');
  }

  return response.json();
}

/**
 * Health check da API.
 */
export async function healthCheck(): Promise<{ status: string; jobs_active: number }> {
  const response = await fetch(`${API_BASE_URL}/health`);

  if (!response.ok) {
    throw new Error('API não está respondendo');
  }

  return response.json();
} 