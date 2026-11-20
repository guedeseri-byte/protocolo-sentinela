import os
from pathlib import Path

import httpx
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI(
    title="Protocolo Sentinela",
    description="Sistema Offline de Preparação, Sobrevivência e Continuidade Operacional",
    version="0.1.0",
)

BASE_DIR = Path(__file__).parent
app.mount("/static", StaticFiles(directory=BASE_DIR / "static"), name="static")
templates = Jinja2Templates(directory=BASE_DIR / "templates")

KIWIX_URL = os.getenv("KIWIX_URL", "http://kiwix:8080")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
OPENWEBUI_URL = os.getenv("OPENWEBUI_URL", "http://open-webui:8080")

MODULOS = [
    {"id": "preparacao", "icone": "🛡️", "nome": "Preparação", "desc": "Plano familiar, kits e avaliação de riscos", "cor": "#D6A64F"},
    {"id": "sobrevivencia", "icone": "🏕️", "nome": "Sobrevivência", "desc": "Segurança em ambientes naturais brasileiros", "cor": "#315B4C"},
    {"id": "agua", "icone": "💧", "nome": "Água e Saneamento", "desc": "Reserva, tratamento e higiene", "cor": "#2196F3"},
    {"id": "alimentacao", "icone": "🥫", "nome": "Alimentação", "desc": "Estoque, conservação e planejamento nutricional", "cor": "#FF9800"},
    {"id": "saude", "icone": "🏥", "nome": "Saúde", "desc": "Primeiros socorros e protocolos do SUS/SAMU", "cor": "#F44336"},
    {"id": "navegacao", "icone": "🗺️", "nome": "Navegação", "desc": "Mapas offline, IBGE e OpenStreetMap", "cor": "#4CAF50"},
    {"id": "energia", "icone": "⚡", "nome": "Energia", "desc": "Consumo, baterias, solar e geradores", "cor": "#FFC107"},
    {"id": "comunicacao", "icone": "📡", "nome": "Comunicação", "desc": "Rádio, rede local e plano de contatos", "cor": "#9C27B0"},
    {"id": "desastres", "icone": "🌊", "nome": "Desastres", "desc": "Enchentes, deslizamentos, tempestades e evacuação", "cor": "#E91E63"},
    {"id": "manutencao", "icone": "🔧", "nome": "Manutenção", "desc": "Reparos, ferramentas e construção", "cor": "#795548"},
    {"id": "agricultura", "icone": "🌱", "nome": "Agricultura", "desc": "Embrapa, cultivo, solo e manejo", "cor": "#8BC34A"},
    {"id": "seguranca", "icone": "🏠", "nome": "Segurança", "desc": "Proteção pessoal, familiar e comunitária", "cor": "#607D8B"},
    {"id": "logistica", "icone": "📦", "nome": "Logística", "desc": "Inventário, validade e autonomia", "cor": "#FF5722"},
    {"id": "tecnologia", "icone": "🤖", "nome": "Tecnologia e IA", "desc": "IA offline, RAG, busca e assistente local", "cor": "#17313A"},
]

SERVICOS_EXTERNOS = {
    "biblioteca": {"nome": "Biblioteca (Kiwix)", "url": KIWIX_URL, "path": "/biblioteca"},
    "ia": {"nome": "Assistente IA", "url": OLLAMA_URL, "path": "/ia"},
}


async def check_service(url: str) -> bool:
    try:
        async with httpx.AsyncClient(timeout=2.0) as client:
            r = await client.get(url)
            return r.status_code < 500
    except Exception:
        return False


@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    servicos = {}
    for key, svc in SERVICOS_EXTERNOS.items():
        servicos[key] = {**svc, "online": await check_service(svc["url"])}

    return templates.TemplateResponse("index.html", {
        "request": request,
        "modulos": MODULOS,
        "servicos": servicos,
        "version": app.version,
    })


@app.get("/modulo/{modulo_id}", response_class=HTMLResponse)
async def modulo(request: Request, modulo_id: str):
    mod = next((m for m in MODULOS if m["id"] == modulo_id), None)
    if not mod:
        return HTMLResponse("<h1>Módulo não encontrado</h1>", status_code=404)
    return templates.TemplateResponse("modulo.html", {
        "request": request,
        "modulo": mod,
    })


@app.get("/api/status")
async def status():
    servicos = {}
    for key, svc in SERVICOS_EXTERNOS.items():
        servicos[key] = await check_service(svc["url"])
    return {
        "versao": app.version,
        "nome": "Protocolo Sentinela",
        "servicos": servicos,
    }
