from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text, JSON, ForeignKey, Boolean, Float, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import os
from dotenv import load_dotenv
import logging

load_dotenv()

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255))
    email = Column(String(255), unique=True, nullable=True)
    hashed_password = Column(String(255), nullable=True)  # Para autenticação
    profile_pic_url = Column(Text)
    profile_pic_url_hd = Column(Text)
    biography = Column(Text)
    is_private = Column(Boolean, default=False)
    is_verified = Column(Boolean, default=False)
    followers_count = Column(Integer, default=0)
    following_count = Column(Integer, default=0)
    posts_count = Column(Integer, default=0)
    last_updated = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relacionamentos
    scans = relationship("Scan", back_populates="user")
    followers = relationship("UserFollower", foreign_keys="UserFollower.following_id", back_populates="following")
    following = relationship("UserFollower", foreign_keys="UserFollower.follower_id", back_populates="follower")

class Scan(Base):
    __tablename__ = "scans"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    username = Column(String(255), nullable=False, index=True)
    target_username = Column(String(255), nullable=True)  # Para compatibilidade com o banco
    job_id = Column(String(255), unique=True, nullable=False, index=True)
    status = Column(String(50), nullable=False)  # queued, running, done, error
    followers_count = Column(Integer, default=0)
    following_count = Column(Integer, default=0)
    ghosts_count = Column(Integer, default=0)
    real_ghosts_count = Column(Integer, default=0)
    famous_ghosts_count = Column(Integer, default=0)
    profile_info = Column(JSON)
    ghosts_data = Column(JSON)  # Lista completa de ghosts
    real_ghosts = Column(JSON)  # Ghosts reais
    famous_ghosts = Column(JSON)  # Ghosts famosos
    error_message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relacionamentos
    user = relationship("User", back_populates="scans")

class UserFollower(Base):
    __tablename__ = "user_followers"
    
    id = Column(Integer, primary_key=True, index=True)
    follower_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Quem segue
    following_id = Column(Integer, ForeignKey("users.id"), nullable=False)  # Quem é seguido
    is_following_back = Column(Boolean, default=False)  # Se segue de volta
    is_ghost = Column(Boolean, default=False)  # Se é ghost
    ghost_type = Column(String(50))  # real, famous, none
    last_checked = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relacionamentos
    follower = relationship("User", foreign_keys=[follower_id], back_populates="following")
    following = relationship("User", foreign_keys=[following_id], back_populates="followers")

class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Float, nullable=False)
    currency = Column(String(3), default="BRL")
    status = Column(String(50), nullable=False)  # pending, completed, failed
    payment_method = Column(String(50))
    transaction_id = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Configuração do banco
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    logger.error("❌ DATABASE_URL não encontrado no arquivo .env")
    raise ValueError("DATABASE_URL é obrigatório para conectar ao Supabase")

logger.info(f"🔗 Conectando ao Supabase: {DATABASE_URL[:50]}...")

try:
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,  # Verifica conexão antes de usar
        pool_recycle=3600,   # Reconecta a cada hora
        echo=False           # Set to True for SQL debugging
    )
    # Testar conexão imediatamente
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    logger.info("✅ Conexão com Supabase estabelecida com sucesso!")
    
except Exception as e:
    logger.error(f"❌ Erro ao conectar com Supabase: {e}")
    logger.error(f"❌ Verifique: 1) DATABASE_URL no .env, 2) psycopg2-binary instalado, 3) Conectividade de rede")
    raise

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_tables():
    """Cria todas as tabelas no banco de dados"""
    Base.metadata.create_all(bind=engine)

def get_db():
    """Retorna uma sessão do banco de dados"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Funções utilitárias para o banco
def get_or_create_user(db, username, profile_info=None):
    """Obtém ou cria um usuário no banco"""
    user = db.query(User).filter(User.username == username).first()
    
    if not user:
        # Gerar email padrão baseado no username se não fornecido
        default_email = f"{username}@desfollow.com.br"
        
        user = User(
            username=username,
            email=default_email,  # Email padrão para evitar constraint NOT NULL
            full_name=profile_info.get('full_name') if profile_info else None,
            profile_pic_url=profile_info.get('profile_pic_url') if profile_info else None,
            profile_pic_url_hd=profile_info.get('profile_pic_url_hd') if profile_info else None,
            biography=profile_info.get('biography') if profile_info else None,
            is_private=profile_info.get('is_private', False) if profile_info else False,
            is_verified=profile_info.get('is_verified', False) if profile_info else False,
            followers_count=profile_info.get('followers_count', 0) if profile_info else 0,
            following_count=profile_info.get('following_count', 0) if profile_info else 0,
            posts_count=profile_info.get('posts_count', 0) if profile_info else 0
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    elif profile_info:
        # Atualizar dados do perfil
        user.full_name = profile_info.get('full_name', user.full_name)
        user.profile_pic_url = profile_info.get('profile_pic_url', user.profile_pic_url)
        user.profile_pic_url_hd = profile_info.get('profile_pic_url_hd', user.profile_pic_url_hd)
        user.biography = profile_info.get('biography', user.biography)
        user.is_private = profile_info.get('is_private', user.is_private)
        user.is_verified = profile_info.get('is_verified', user.is_verified)
        user.followers_count = profile_info.get('followers_count', user.followers_count)
        user.following_count = profile_info.get('following_count', user.following_count)
        user.posts_count = profile_info.get('posts_count', user.posts_count)
        user.last_updated = datetime.utcnow()
        db.commit()
    
    return user

def save_scan_result(db, job_id, username, status, profile_info=None, ghosts_data=None, error_message=None):
    """Salva o resultado de um scan no banco"""
    print(f"💾 [DATABASE] Salvando scan: job_id={job_id}, status={status}")
    print(f"💾 [DATABASE] Profile info: {profile_info.get('followers_count', 0) if profile_info else 0} seguidores")
    print(f"💾 [DATABASE] Ghosts data: {ghosts_data.get('ghosts_count', 0) if ghosts_data else 0} ghosts")
    
    user = get_or_create_user(db, username, profile_info)
    
    scan = db.query(Scan).filter(Scan.job_id == job_id).first()
    
    if not scan:
        scan = Scan(
            job_id=job_id,
            user_id=user.id,
            username=username,
            status=status
        )
        db.add(scan)
    
    scan.status = status
    scan.profile_info = profile_info
    
    if ghosts_data:
        # Corrigir: usar 'ghosts' ao invés de 'all'
        scan.ghosts_data = ghosts_data.get('ghosts', [])
        scan.real_ghosts = ghosts_data.get('real_ghosts', [])
        scan.famous_ghosts = ghosts_data.get('famous_ghosts', [])
        scan.ghosts_count = ghosts_data.get('ghosts_count', len(ghosts_data.get('ghosts', [])))
        scan.real_ghosts_count = ghosts_data.get('real_ghosts_count', len(ghosts_data.get('real_ghosts', [])))
        scan.famous_ghosts_count = ghosts_data.get('famous_ghosts_count', len(ghosts_data.get('famous_ghosts', [])))
    
    if profile_info:
        scan.followers_count = profile_info.get('followers_count', 0)
        scan.following_count = profile_info.get('following_count', 0)
    
    # Atualizar com contadores reais se disponíveis nos ghosts_data
    if ghosts_data:
        # Usar contadores reais do perfil se disponíveis
        if ghosts_data.get('profile_followers_count'):
            scan.followers_count = ghosts_data.get('profile_followers_count', scan.followers_count)
        if ghosts_data.get('profile_following_count'):
            scan.following_count = ghosts_data.get('profile_following_count', scan.following_count)
    
    # Salvar mensagem de erro se fornecida
    if error_message:
        scan.error_message = error_message
    
    scan.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(scan)
    
    return scan

def get_user_scan_history(db, username):
    """Obtém o histórico de scans de um usuário"""
    return db.query(Scan).filter(Scan.username == username).order_by(Scan.created_at.desc()).all()

def get_cached_user_data(db, username):
    """Obtém dados em cache de um usuário - apenas se VÁLIDOS e RECENTES"""
    user = db.query(User).filter(User.username == username).first()
    if user:
        # Verificar se os dados são válidos (não zerados)
        followers_count = user.followers_count or 0
        
        # Verificar idade dos dados (não mais que 24 horas)
        from datetime import datetime, timedelta
        if user.last_updated:
            age = datetime.utcnow() - user.last_updated
            max_age = timedelta(hours=24)
            if age > max_age:
                print(f"⚠️ Cache muito antigo para {username}: {age.total_seconds()/3600:.1f}h")
                return None
        
        # Só retornar se há dados válidos
        if followers_count > 0:
            print(f"✅ Cache válido encontrado para {username}: {followers_count} seguidores")
            return {
                'profile_info': {
                    'username': user.username,
                    'full_name': user.full_name,
                    'profile_pic_url': user.profile_pic_url,
                    'profile_pic_url_hd': user.profile_pic_url_hd,
                    'biography': user.biography,
                    'is_private': user.is_private,
                    'is_verified': user.is_verified,
                    'followers_count': user.followers_count,
                    'following_count': user.following_count,
                    'posts_count': user.posts_count
                },
                'last_updated': user.last_updated
            }
        else:
            print(f"⚠️ Cache com dados zerados encontrado para {username} - ignorando")
    
    return None 