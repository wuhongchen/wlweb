import os
from typing import List, Union
from pydantic import field_validator, Field
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "your-secret-key-here-change-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # CORS origins
    BACKEND_CORS_ORIGINS: str = Field(default="http://localhost:3000,http://localhost:5173,http://localhost:5174", alias="CORS_ORIGINS")
    
    @property
    def CORS_ORIGINS_LIST(self) -> List[str]:
        """Convert CORS origins string to list"""
        if isinstance(self.BACKEND_CORS_ORIGINS, str):
            if self.BACKEND_CORS_ORIGINS.startswith("[") and self.BACKEND_CORS_ORIGINS.endswith("]"):
                import json
                try:
                    return json.loads(self.BACKEND_CORS_ORIGINS)
                except json.JSONDecodeError:
                    pass
            return [origin.strip() for origin in self.BACKEND_CORS_ORIGINS.split(",") if origin.strip()]
        return [self.BACKEND_CORS_ORIGINS]
    
    # Database
    MYSQL_SERVER: str = "localhost"
    MYSQL_USER: str = "wlweb_user"
    MYSQL_PASSWORD: str = "123456"
    MYSQL_DB: str = "wlweb_game_middleware"
    MYSQL_PORT: int = 3306
    
    @property
    def SQLALCHEMY_DATABASE_URI(self) -> str:
        # 优先使用环境变量DATABASE_URL
        import os
        database_url = os.getenv("DATABASE_URL")
        if database_url:
            return database_url
        # 使用SQLite作为备选
        if os.getenv("USE_SQLITE", "false").lower() == "true":
            return "sqlite:///./game_middleware.db"
        # 使用配置的MySQL连接
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_SERVER}:{self.MYSQL_PORT}/{self.MYSQL_DB}"
    

    
    model_config = {
        "env_file": ".env",
        "case_sensitive": True,
        "env_nested_delimiter": "__"
    }

settings = Settings()