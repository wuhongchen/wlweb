from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from .config import settings

# 优先使用环境变量中的数据库连接字符串
database_url = os.environ.get("DATABASE_URL")
if not database_url:
    database_url = settings.SQLALCHEMY_DATABASE_URI

# 确保数据库连接使用UTF-8编码
if database_url and "mysql" in database_url and "charset" not in database_url:
    separator = "&" if "?" in database_url else "?"
    database_url = f"{database_url}{separator}charset=utf8mb4"

engine = create_engine(
    database_url,
    pool_pre_ping=True,
    pool_recycle=300,
    echo=False
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()