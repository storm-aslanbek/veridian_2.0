import uvicorn
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles  # <--- ИМПОРТ 1
from app.routers import auth, users, banking, services

app = FastAPI(title="Veridian Banking API")

# ... (Middleware остается без изменений) ...
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Подключаем API роутеры (ОНИ ДОЛЖНЫ БЫТЬ ПЕРВЫМИ)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(banking.router)
app.include_router(services.router)

# 2. Подключаем папку web (Flutter) как статику
# html=True означает, что при запросе корня "/" будет отдаваться index.html
if os.path.exists("web"):
    app.mount("/", StaticFiles(directory="web", html=True), name="static")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)