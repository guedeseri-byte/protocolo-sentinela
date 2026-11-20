#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════
# PROTOCOLO SENTINELA — Download de Conteúdo Offline
# Baixa ZIMs (Kiwix), canais Kolibri e modelos de IA
# ══════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
AMBER='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${AMBER}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
info()  { echo -e "${BLUE}[i]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ── Diretórios de dados ──────────────────────────────────────

KIWIX_DATA="${PROJECT_DIR}/data/kiwix"
KOLIBRI_DATA="${PROJECT_DIR}/data/kolibri"
DOCS_DATA="${PROJECT_DIR}/data/documentos"
MAPS_DATA="${PROJECT_DIR}/data/mapas"

mkdir -p "$KIWIX_DATA" "$KOLIBRI_DATA" "$DOCS_DATA" "$MAPS_DATA"

# ── ZIM files para Kiwix ─────────────────────────────────────

ZIMS=(
    # Wikipedia PT-BR (mini ~1.2 GB, maxi ~10 GB)
    "https://download.kiwix.org/zim/wikipedia/wikipedia_pt_all_mini_latest.zim"
    # Wikibooks PT-BR
    "https://download.kiwix.org/zim/wikibooks/wikibooks_pt_all_maxi_latest.zim"
    # Wikcionário PT-BR
    "https://download.kiwix.org/zim/wiktionary/wiktionary_pt_all_maxi_latest.zim"
    # Projeto Gutenberg (livros domínio público)
    "https://download.kiwix.org/zim/gutenberg/gutenberg_pt_all_latest.zim"
    # Wikivoyage PT-BR (guias de viagem/sobrevivência)
    "https://download.kiwix.org/zim/wikivoyage/wikivoyage_pt_all_maxi_latest.zim"
)

download_zims() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   DOWNLOAD — Biblioteca Kiwix (ZIM files)       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    for url in "${ZIMS[@]}"; do
        filename=$(basename "$url")
        filepath="${KIWIX_DATA}/${filename}"

        if [ -f "$filepath" ]; then
            log "Já existe: $filename"
            continue
        fi

        info "Baixando: $filename"
        info "Fonte: $url"
        echo ""

        if command -v wget &>/dev/null; then
            wget -c -P "$KIWIX_DATA" "$url" || warn "Falha ao baixar $filename"
        elif command -v curl &>/dev/null; then
            curl -L -C - -o "$filepath" "$url" || warn "Falha ao baixar $filename"
        else
            error "wget ou curl não encontrado."
        fi

        log "Concluído: $filename"
        echo ""
    done

    # Copiar para o volume do Docker
    info "Para carregar no Kiwix, copie os ZIMs para o volume Docker:"
    echo "  docker cp ${KIWIX_DATA}/. sentinela-kiwix:/data/"
    echo "  docker restart sentinela-kiwix"
    echo ""
}

# ── Kolibri — Canais educacionais ────────────────────────────

download_kolibri_channels() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   DOWNLOAD — Canais Kolibri                     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    if ! docker ps --format '{{.Names}}' | grep -q sentinela-kolibri; then
        warn "Kolibri não está rodando. Inicie com: docker compose --profile educacao up -d"
        return
    fi

    # Khan Academy PT-BR
    info "Importando Khan Academy (Português)..."
    docker exec sentinela-kolibri kolibri manage importchannel network "95a52b386f2c485cb97dd60901674a98" || warn "Falha no canal Khan Academy"
    docker exec sentinela-kolibri kolibri manage importcontent network "95a52b386f2c485cb97dd60901674a98" || warn "Falha no conteúdo Khan Academy"
    log "Khan Academy PT-BR importado."

    # CK-12 (Ciências e Matemática)
    info "Importando CK-12 (Ciências)..."
    docker exec sentinela-kolibri kolibri manage importchannel network "efe9d138987a4b2e85b3c27384a8de23" || warn "Falha no canal CK-12"
    docker exec sentinela-kolibri kolibri manage importcontent network "efe9d138987a4b2e85b3c27384a8de23" || warn "Falha no conteúdo CK-12"
    log "CK-12 importado."

    echo ""
    log "Canais Kolibri importados. Acesse: http://localhost/educacao/"
    echo ""
}

# ── Ollama — Modelos de IA ───────────────────────────────────

MODELOS_IA=(
    "qwen3:8b"
    "llama3.1:8b"
)

download_modelos_ia() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   DOWNLOAD — Modelos de IA (Ollama)             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    if ! docker ps --format '{{.Names}}' | grep -q sentinela-ollama; then
        warn "Ollama não está rodando. Inicie com: docker compose --profile ia up -d"
        return
    fi

    for modelo in "${MODELOS_IA[@]}"; do
        info "Baixando modelo: $modelo"
        docker exec sentinela-ollama ollama pull "$modelo" || warn "Falha ao baixar $modelo"
        log "Modelo $modelo disponível."
        echo ""
    done

    echo ""
    log "Modelos de IA prontos. Acesse: http://localhost/ia/"
    echo ""
}

# ── Documentos brasileiros (fontes públicas) ─────────────────

download_documentos() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   DOWNLOAD — Documentos brasileiros              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    DOCS=(
        # Defesa Civil — Manual de Desastres
        "https://www.gov.br/mdr/pt-br/assuntos/protecao-e-defesa-civil/publicacoes/arquivos/manual-de-desastres-vol-1.pdf"
        # Ministério da Saúde — Primeiros Socorros
        "https://bvsms.saude.gov.br/bvs/publicacoes/manual_primeiros_socorros.pdf"
        # Embrapa — Horta em Pequenos Espaços
        "https://www.infoteca.cnptia.embrapa.br/infoteca/bitstream/doc/1101975/1/Horta-em-pequenos-espacos.pdf"
    )

    for url in "${DOCS[@]}"; do
        filename=$(basename "$url")
        filepath="${DOCS_DATA}/${filename}"

        if [ -f "$filepath" ]; then
            log "Já existe: $filename"
            continue
        fi

        info "Baixando: $filename"
        if command -v wget &>/dev/null; then
            wget -q -P "$DOCS_DATA" "$url" 2>/dev/null || warn "Falha: $filename (URL pode ter mudado)"
        elif command -v curl &>/dev/null; then
            curl -sL -o "$filepath" "$url" 2>/dev/null || warn "Falha: $filename (URL pode ter mudado)"
        fi
    done

    log "Documentos salvos em: $DOCS_DATA"
    info "Estes documentos serão indexados pelo RAG da IA para consulta offline."
    echo ""
}

# ── Menu principal ───────────────────────────────────────────

show_menu() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║     PROTOCOLO SENTINELA — Download de Conteúdo  ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "  1) Tudo (recomendado — requer ~15 GB de espaço)"
    echo "  2) Apenas Biblioteca (ZIM files para Kiwix)"
    echo "  3) Apenas Educação (canais Kolibri)"
    echo "  4) Apenas IA (modelos Ollama)"
    echo "  5) Apenas Documentos brasileiros"
    echo "  0) Sair"
    echo ""
    read -rp "Opção: " choice

    case "$choice" in
        1) download_zims; download_kolibri_channels; download_modelos_ia; download_documentos ;;
        2) download_zims ;;
        3) download_kolibri_channels ;;
        4) download_modelos_ia ;;
        5) download_documentos ;;
        0) exit 0 ;;
        *) warn "Opção inválida." ;;
    esac
}

# ── Argumento direto ─────────────────────────────────────────

if [ $# -gt 0 ]; then
    case "$1" in
        --all)       download_zims; download_kolibri_channels; download_modelos_ia; download_documentos ;;
        --zim)       download_zims ;;
        --kolibri)   download_kolibri_channels ;;
        --ia)        download_modelos_ia ;;
        --docs)      download_documentos ;;
        --help|-h)
            echo "Uso: $0 [--all|--zim|--kolibri|--ia|--docs]"
            echo "  Sem argumentos: menu interativo"
            ;;
        *) error "Argumento desconhecido: $1" ;;
    esac
else
    show_menu
fi

echo ""
log "Download concluído!"
echo ""
