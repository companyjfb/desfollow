# Sistema de Limpeza Automática 3 Minutos

## 📋 Visão Geral

Este sistema foi criado para resolver o problema de acúmulo de jobs ativos na API backend do Desfollow. Com o sistema anterior (30 minutos), jobs órfãos se acumulavam desnecessariamente quando múltiplos usuários faziam scans simultaneamente.

### 🎯 Problema Resolvido
- **Antes**: Jobs ficavam ativos por até 30 minutos
- **Status reportado**: `{"status":"healthy","jobs_active":9}` 
- **Agora**: Jobs são limpos após 3 minutos
- **Resultado**: Sempre poucos jobs ativos

## ⚙️ Configuração do Sistema

### Cronometragem Otimizada
- **Jobs running**: Limpos após 3 minutos
- **Jobs queued**: Limpos após 2 minutos  
- **Verificação**: A cada 30 segundos
- **Limpeza forçada**: Se jobs > 5

### Baseado no Comportamento do Frontend
- Frontend faz polling a cada 5 segundos
- Máximo de 120 tentativas (10 minutos total)
- Scan típico demora 30-90 segundos
- Jobs > 3 minutos = órfãos ou falhas

## 🚀 Instalação

### 1. Configuração Automática
```bash
# No servidor (VPS)
./configurar_limpeza_3_minutos.sh
```

### 2. Verificação Manual
```bash
# Verificar se está funcionando
./testar_limpeza_3_minutos.sh

# Monitorar em tempo real
watch -n 2 'curl -s http://api.desfollow.com.br/health | python3 -m json.tool'
```

## 📁 Arquivos do Sistema

### Scripts Principais
- `sistema_limpeza_3_minutos.py` - Sistema principal de limpeza
- `configurar_limpeza_3_minutos.sh` - Script de instalação 
- `testar_limpeza_3_minutos.sh` - Script de teste
- `desfollow-limpeza-3min.service` - Serviço systemd

### Localização no VPS
```
/root/desfollow/sistema_limpeza_3_minutos.py
/etc/systemd/system/desfollow-limpeza-3min.service
/var/log/desfollow/limpeza_3min.log
```

## 🔧 Comandos de Gerenciamento

### Controle do Serviço
```bash
# Ver status
systemctl status desfollow-limpeza-3min

# Iniciar
systemctl start desfollow-limpeza-3min

# Parar
systemctl stop desfollow-limpeza-3min

# Reiniciar
systemctl restart desfollow-limpeza-3min

# Ver logs em tempo real
journalctl -u desfollow-limpeza-3min -f
```

### Monitoramento da API
```bash
# Verificar jobs ativos
curl -s http://api.desfollow.com.br/health | python3 -m json.tool

# Monitorar continuamente
watch -n 5 'curl -s http://api.desfollow.com.br/health | python3 -m json.tool'
```

## 📊 Como Funciona

### 1. Limpeza do Cache Local
- Verifica `/tmp/desfollow_jobs.json`
- Remove jobs running > 3 minutos
- Remove jobs queued > 2 minutos

### 2. Limpeza do Banco Supabase
- Atualiza status para 'error' 
- Jobs running > 3 minutos
- Jobs queued > 2 minutos

### 3. Limpeza Forçada (se necessário)
- Se API reporta > 5 jobs ativos
- Força todos os jobs para 'error'
- Limpa cache completamente

### 4. Monitoramento
- Verifica API health
- Log detalhado de atividades
- Estatísticas a cada 10 ciclos

## 🔍 Logs e Debugging

### Arquivo de Log Principal
```bash
tail -f /var/log/desfollow/limpeza_3min.log
```

### Logs do Systemd
```bash
journalctl -u desfollow-limpeza-3min -f
```

### Estrutura do Log
```
2024-01-15 14:30:15 - INFO - 🔄 Ciclo 42 - 14:30:15
2024-01-15 14:30:15 - INFO - 🚀 Iniciando limpeza completa...
2024-01-15 14:30:15 - INFO - ✅ Cache limpo: 0 jobs órfãos removidos
2024-01-15 14:30:15 - INFO - 📊 Stats banco (24h): {'done': 45, 'error': 12}
2024-01-15 14:30:15 - INFO - 📊 API Health: 2 jobs ativos
2024-01-15 14:30:15 - INFO - ✅ Sistema limpo - nenhum job órfão encontrado
```

## ⚠️ Solução de Problemas

### Problema: Muitos Jobs Ativos
```bash
# 1. Verificar se serviço está rodando
systemctl status desfollow-limpeza-3min

# 2. Reiniciar serviço
systemctl restart desfollow-limpeza-3min

# 3. Limpeza manual imediata
./limpar_jobs_rapido.sh

# 4. Verificar logs de erro
journalctl -u desfollow-limpeza-3min -n 20
```

### Problema: Serviço Não Inicia
```bash
# Verificar erro específico
systemctl status desfollow-limpeza-3min -l

# Testar script manualmente
python3 /root/desfollow/sistema_limpeza_3_minutos.py

# Verificar dependências
python3 -c "import psycopg2, requests, dotenv; print('Deps OK')"
```

### Problema: Conexão com Banco
```bash
# Testar conexão
python3 -c "
import sys
sys.path.append('/root/desfollow')
from sistema_limpeza_3_minutos import conectar_supabase
conn = conectar_supabase()
print('OK' if conn else 'ERRO')
"
```

## 📈 Monitoramento Recomendado

### Dashboard Simples
```bash
# Criar alias útil no .bashrc
alias jobs='curl -s http://api.desfollow.com.br/health | python3 -m json.tool'
alias logs='journalctl -u desfollow-limpeza-3min -f'
alias status='systemctl status desfollow-limpeza-3min'
```

### Alertas Automáticos
O sistema automaticamente:
- ✅ Reporta atividade normal
- ⚠️ Alerta se jobs > 5 
- 🚨 Força limpeza se necessário

## 🔄 Comparação com Sistema Anterior

| Aspecto | Sistema Antigo | Sistema Novo |
|---------|----------------|--------------|
| Tempo de limpeza | 30 minutos | 3 minutos |
| Frequência | 5 minutos | 30 segundos |
| Threshold alerta | 50 jobs | 5 jobs |
| Logs | Básico | Detalhado |
| Monitoramento | Manual | Automático |

## 🎯 Resultados Esperados

Com o novo sistema, você deve ver:
- **Jobs ativos**: Sempre ≤ 5 (na maioria das vezes 0-2)
- **Responsividade**: Scans mais rápidos
- **Estabilidade**: Menos problemas de timeout
- **Logs**: Visibilidade completa do sistema

## 📞 Suporte

Se o sistema não estiver funcionando conforme esperado:
1. Execute `./testar_limpeza_3_minutos.sh`
2. Verifique os logs com `journalctl -u desfollow-limpeza-3min -f`
3. Compare with sistema antigo se necessário

O sistema foi projetado para ser robusto e auto-recuperável, mantendo sempre baixo o número de jobs ativos. 