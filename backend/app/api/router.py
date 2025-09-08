from fastapi import APIRouter
from .endpoints import auth, users, terminals, tasks, stats, account_assets, system_config, game_accounts

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(terminals.router, prefix="/terminals", tags=["terminals"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
api_router.include_router(stats.router, prefix="/statistics", tags=["statistics"])
api_router.include_router(account_assets.router, prefix="/account-assets", tags=["account-assets"])
api_router.include_router(system_config.router, prefix="/system-config", tags=["system-config"])
api_router.include_router(game_accounts.router, prefix="/game-accounts", tags=["game-accounts"])