import os
from pathlib import Path
from typing import Optional

import httpx
from fastapi import FastAPI, Request, Query
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from protocolos import (
    CATEGORIAS, NIVEIS, PRIORIDADES,
    carregar_protocolos, buscar_protocolos, obter_protocolo, contar_por_categoria,
)
from icons import SVG_ICONS, ACESSO_ICONS

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
    {"id": "preparacao", "icone": "🛡️", "nome": "Preparação", "desc": "Plano familiar, kits e avaliação de riscos", "cor": "#D6A64F", "categoria": "PREP"},
    {"id": "sobrevivencia", "icone": "🏕️", "nome": "Sobrevivência", "desc": "Segurança em ambientes naturais brasileiros", "cor": "#315B4C", "categoria": "SOBR"},
    {"id": "agua", "icone": "💧", "nome": "Água e Saneamento", "desc": "Reserva, tratamento e higiene", "cor": "#2196F3", "categoria": "AGUA"},
    {"id": "alimentacao", "icone": "🥫", "nome": "Alimentação", "desc": "Estoque, conservação e planejamento nutricional", "cor": "#FF9800", "categoria": "ALIM"},
    {"id": "saude", "icone": "🏥", "nome": "Saúde", "desc": "Primeiros socorros e protocolos do SUS/SAMU", "cor": "#F44336", "categoria": "SAUD"},
    {"id": "navegacao", "icone": "🗺️", "nome": "Navegação", "desc": "Mapas offline, IBGE e OpenStreetMap", "cor": "#4CAF50", "categoria": "NAVE"},
    {"id": "energia", "icone": "⚡", "nome": "Energia", "desc": "Consumo, baterias, solar e geradores", "cor": "#FFC107", "categoria": "ENER"},
    {"id": "comunicacao", "icone": "📡", "nome": "Comunicação", "desc": "Rádio, rede local e plano de contatos", "cor": "#9C27B0", "categoria": "COMU"},
    {"id": "desastres", "icone": "🌊", "nome": "Desastres", "desc": "Enchentes, deslizamentos, tempestades e evacuação", "cor": "#E91E63", "categoria": "DESA"},
    {"id": "manutencao", "icone": "🔧", "nome": "Manutenção", "desc": "Reparos, ferramentas e construção", "cor": "#795548", "categoria": "MANU"},
    {"id": "agricultura", "icone": "🌱", "nome": "Agricultura", "desc": "Embrapa, cultivo, solo e manejo", "cor": "#8BC34A", "categoria": "AGRI"},
    {"id": "seguranca", "icone": "🏠", "nome": "Segurança", "desc": "Proteção pessoal, familiar e comunitária", "cor": "#607D8B", "categoria": "SEGU"},
    {"id": "logistica", "icone": "📦", "nome": "Logística", "desc": "Inventário, validade e autonomia", "cor": "#FF5722", "categoria": "LOGI"},
    {"id": "tecnologia", "icone": "🤖", "nome": "Tecnologia e IA", "desc": "IA offline, RAG, busca e assistente local", "cor": "#17313A", "categoria": "TECH"},
]

for mod in MODULOS:
    mod["svg"] = SVG_ICONS.get(mod["id"], "")

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


# ── Páginas principais ───────────────────────────────────────

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    servicos = {}
    for key, svc in SERVICOS_EXTERNOS.items():
        servicos[key] = {**svc, "online": await check_service(svc["url"])}

    total_protocolos = len(carregar_protocolos())
    contagem = contar_por_categoria()

    return templates.TemplateResponse("index.html", {
        "request": request,
        "modulos": MODULOS,
        "servicos": servicos,
        "version": app.version,
        "total_protocolos": total_protocolos,
        "contagem": contagem,
        "acesso_icons": ACESSO_ICONS,
    })


@app.get("/modulo/{modulo_id}", response_class=HTMLResponse)
async def modulo(request: Request, modulo_id: str):
    mod = next((m for m in MODULOS if m["id"] == modulo_id), None)
    if not mod:
        return HTMLResponse("<h1>Módulo não encontrado</h1>", status_code=404)

    protocolos = buscar_protocolos(categoria=mod.get("categoria", ""))

    return templates.TemplateResponse("modulo.html", {
        "request": request,
        "modulo": mod,
        "protocolos": protocolos,
        "niveis": NIVEIS,
        "prioridades": PRIORIDADES,
    })


# ── Protocolo individual ─────────────────────────────────────

@app.get("/protocolo/{protocolo_id}", response_class=HTMLResponse)
async def protocolo(request: Request, protocolo_id: str):
    p = obter_protocolo(protocolo_id)
    if not p:
        return HTMLResponse("<h1>Protocolo não encontrado</h1>", status_code=404)

    cat_info = CATEGORIAS.get(p.get("categoria", ""), {})
    nivel_info = NIVEIS.get(p.get("nivel"), {})
    prio_info = PRIORIDADES.get(p.get("prioridade", ""), {})

    return templates.TemplateResponse("protocolo.html", {
        "request": request,
        "protocolo": p,
        "categoria": cat_info,
        "nivel": nivel_info,
        "prioridade": prio_info,
    })


# ── Busca ─────────────────────────────────────────────────────

@app.get("/busca", response_class=HTMLResponse)
async def busca(
    request: Request,
    q: str = Query("", description="Termo de busca"),
    categoria: str = Query("", description="Filtrar por categoria"),
    nivel: Optional[int] = Query(None, description="Filtrar por nível"),
):
    resultados = buscar_protocolos(query=q, categoria=categoria, nivel=nivel)
    return templates.TemplateResponse("busca.html", {
        "request": request,
        "query": q,
        "categoria_filtro": categoria,
        "nivel_filtro": nivel,
        "resultados": resultados,
        "categorias": CATEGORIAS,
        "niveis": NIVEIS,
        "total": len(resultados),
    })


# ── Central de Protocolos ─────────────────────────────────────

@app.get("/protocolos", response_class=HTMLResponse)
async def central_protocolos(request: Request):
    todos = carregar_protocolos()
    contagem = contar_por_categoria()
    criticos = [p for p in todos if p.get("prioridade") == "critica"]

    return templates.TemplateResponse("central.html", {
        "request": request,
        "total": len(todos),
        "contagem": contagem,
        "categorias": CATEGORIAS,
        "criticos": criticos,
        "niveis": NIVEIS,
        "prioridades": PRIORIDADES,
    })


# ── Modo de Emergência ────────────────────────────────────────

@app.get("/ferramentas", response_class=HTMLResponse)
async def ferramentas(request: Request):
    return templates.TemplateResponse("ferramentas.html", {"request": request})


@app.get("/emergencia", response_class=HTMLResponse)
async def emergencia(request: Request):
    criticos = buscar_protocolos(prioridade="critica")
    return templates.TemplateResponse("emergencia.html", {
        "request": request,
        "protocolos": criticos,
        "categorias": CATEGORIAS,
    })


# ── API ───────────────────────────────────────────────────────

@app.get("/api/status")
async def status():
    servicos = {}
    for key, svc in SERVICOS_EXTERNOS.items():
        servicos[key] = await check_service(svc["url"])
    return {
        "versao": app.version,
        "nome": "Protocolo Sentinela",
        "servicos": servicos,
        "protocolos": len(carregar_protocolos()),
    }


@app.get("/api/protocolos")
async def api_protocolos(
    q: str = "",
    categoria: str = "",
    nivel: Optional[int] = None,
    prioridade: str = "",
):
    return buscar_protocolos(query=q, categoria=categoria, nivel=nivel, prioridade=prioridade)


@app.get("/api/protocolo/{protocolo_id}")
async def api_protocolo(protocolo_id: str):
    p = obter_protocolo(protocolo_id)
    if not p:
        return {"error": "Protocolo não encontrado"}
    return p
