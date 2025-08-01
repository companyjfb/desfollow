-- Script SQL para adicionar novas colunas no Supabase
-- Executar este script no painel SQL do Supabase

-- Adicionar colunas para separar dados analisados vs dados do perfil
ALTER TABLE scans 
ADD COLUMN IF NOT EXISTS profile_followers_count INTEGER DEFAULT 0;

ALTER TABLE scans 
ADD COLUMN IF NOT EXISTS profile_following_count INTEGER DEFAULT 0;

-- Comentários das colunas para documentação
COMMENT ON COLUMN scans.followers_count IS 'Quantos seguidores conseguimos analisar/capturar';
COMMENT ON COLUMN scans.following_count IS 'Quantos seguindo conseguimos analisar/capturar';
COMMENT ON COLUMN scans.profile_followers_count IS 'Total de seguidores do perfil (dados originais do Instagram)';
COMMENT ON COLUMN scans.profile_following_count IS 'Total de seguindo do perfil (dados originais do Instagram)';

-- Verificar se as colunas foram criadas
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'scans' 
  AND column_name IN ('followers_count', 'following_count', 'profile_followers_count', 'profile_following_count')
ORDER BY column_name;