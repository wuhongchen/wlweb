import redis
from .config import settings

# Redis连接池
redis_pool = redis.ConnectionPool.from_url(
    settings.REDIS_URL,
    max_connections=20,
    decode_responses=True
)

# Redis客户端
redis_client = redis.Redis(connection_pool=redis_pool)

def get_redis():
    """获取Redis客户端"""
    return redis_client