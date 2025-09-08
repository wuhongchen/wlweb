from typing import List, Union
from pydantic import validator, Field
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "your-secret-key-here-change-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # CORS origins
    BACKEND_CORS_ORIGINS: List[str] = Field(default=["http://localhost:3000", "http://localhost:5173", "http://localhost:5174"], alias="CORS_ORIGINS")
    
    @validator("BACKEND_CORS_ORIGINS", pre=True)
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    # Database
    MYSQL_SERVER: str = "localhost"
    MYSQL_USER: str = "wlweb_user"
    MYSQL_PASSWORD: str = "123456"
    MYSQL_DB: str = "wlweb_game_middleware"
    MYSQL_PORT: int = 3306
    
    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        # Use SQLite for development if MySQL is not available
        import os
        if os.getenv("USE_SQLITE", "false").lower() == "true":
            return "sqlite:///./game_middleware.db"
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_SERVER}:{self.MYSQL_PORT}/{self.MYSQL_DB}"
    
    # Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    REDIS_PASSWORD: str = ""
    
    @property
    def REDIS_URL(self) -> str:
        if self.REDIS_PASSWORD:
            return f"redis://:{self.REDIS_PASSWORD}@{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
    
    model_config = {
        "env_file": ".env",
        "case_sensitive": True,
        "env_nested_delimiter": "__"
    }

settings = Settings()