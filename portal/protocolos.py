import json
from pathlib import Path
from typing import Optional

DATA_DIR = Path(__file__).parent / "data" / "protocolos"

CATEGORIAS = {
    "PREP": {"nome": "Preparação", "icone": "🛡️", "cor": "#17313A"},
    "SOBR": {"nome": "Sobrevivência", "icone": "⚔️", "cor": "#8B0000"},
    "AGUA": {"nome": "Água", "icone": "💧", "cor": "#1565C0"},
    "ALIM": {"nome": "Alimentação", "icone": "🌾", "cor": "#827717"},
    "SAUD": {"nome": "Saúde", "icone": "🏥", "cor": "#C62828"},
    "NAVE": {"nome": "Navegação", "icone": "🧭", "cor": "#4E342E"},
    "ENER": {"nome": "Energia", "icone": "⚡", "cor": "#F57F17"},
    "COMU": {"nome": "Comunicação", "icone": "📡", "cor": "#6A1B9A"},
    "DESA": {"nome": "Desastres", "icone": "🌪️", "cor": "#E65100"},
    "MANU": {"nome": "Manutenção", "icone": "🔧", "cor": "#37474F"},
    "AGRI": {"nome": "Agricultura", "icone": "🌱", "cor": "#2E7D32"},
    "SEGU": {"nome": "Segurança", "icone": "🔒", "cor": "#1B5E20"},
    "LOGI": {"nome": "Logística", "icone": "📦", "cor": "#4A148C"},
    "TECH": {"nome": "Tecnologia/IA", "icone": "🤖", "cor": "#006064"},
}

NIVEIS = {
    1: {"nome": "Básico", "cor": "#4CAF50", "desc": "Conhecimento essencial, sem equipamento especializado"},
    2: {"nome": "Intermediário", "cor": "#FF9800", "desc": "Requer algum preparo e materiais básicos"},
    3: {"nome": "Avançado", "cor": "#F44336", "desc": "Requer treinamento e equipamentos específicos"},
    4: {"nome": "Especialista", "cor": "#9C27B0", "desc": "Conhecimento técnico profundo"},
}

PRIORIDADES = {
    "critica": {"nome": "Crítica", "cor": "#C62828", "icone": "🔴"},
    "alta":    {"nome": "Alta", "cor": "#E65100", "icone": "🟠"},
    "media":   {"nome": "Média", "cor": "#F9A825", "icone": "🟡"},
    "normal":  {"nome": "Normal", "cor": "#2E7D32", "icone": "🟢"},
}


def carregar_protocolos() -> list[dict]:
    protocolos = []
    if not DATA_DIR.exists():
        return protocolos
    for arquivo in sorted(DATA_DIR.glob("**/*.json")):
        try:
            dados = json.loads(arquivo.read_text(encoding="utf-8"))
            if isinstance(dados, list):
                protocolos.extend(dados)
            else:
                protocolos.append(dados)
        except (json.JSONDecodeError, OSError):
            continue
    return protocolos


def buscar_protocolos(
    query: str = "",
    categoria: str = "",
    nivel: Optional[int] = None,
    prioridade: str = "",
) -> list[dict]:
    todos = carregar_protocolos()
    resultados = todos

    if categoria:
        resultados = [p for p in resultados if p.get("categoria") == categoria]

    if nivel is not None:
        resultados = [p for p in resultados if p.get("nivel") == nivel]

    if prioridade:
        resultados = [p for p in resultados if p.get("prioridade") == prioridade]

    if query:
        q = query.lower()
        resultados = [
            p for p in resultados
            if q in p.get("titulo", "").lower()
            or q in p.get("resumo", "").lower()
            or q in " ".join(p.get("tags", [])).lower()
        ]

    return resultados


def obter_protocolo(protocolo_id: str) -> Optional[dict]:
    for p in carregar_protocolos():
        if p.get("id") == protocolo_id:
            return p
    return None


def contar_por_categoria() -> dict[str, int]:
    todos = carregar_protocolos()
    contagem = {cat: 0 for cat in CATEGORIAS}
    for p in todos:
        cat = p.get("categoria", "")
        if cat in contagem:
            contagem[cat] += 1
    return contagem
