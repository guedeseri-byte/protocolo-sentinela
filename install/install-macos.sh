#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════
# PROTOCOLO SENTINELA — Instalador macOS
# Sistema Offline de Preparação, Sobrevivência e Continuidade
# ══════════════════════════════════════════════════════════════

SENTINELA_VERSION="0.1.0"
SENTINELA_DIR="${SENTINELA_DIR:-$HOME/protocolo-sentinela}"
REPO_URL="https://github.com/guedeseri-byte/protocolo-sentinela"

RED='\033[0;31m'
GREEN='\033[0;32m'
AMBER='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║          PROTOCOLO SENTINELA v${SENTINELA_VERSION}            ║"
    echo "║   Preparação. Conhecimento. Autonomia.          ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${AMBER}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }

check_macos() {
    if [ "$(uname)" != "Darwin" ]; then
        error "Este instalador é para macOS. Use install-linux.sh para Linux."
    fi
    MACOS_VERSION=$(sw_vers -productVersion)
    log "macOS $MACOS_VERSION detectado"

    ARCH=$(uname -m)
    log "Arquitetura: $ARCH"
}

check_resources() {
    MEM_GB=$(sysctl -n hw.memsize | awk '{printf "%.0f", $1/1024/1024/1024}')
    DISK_GB=$(df -g / | awk 'NR==2 {print $4}')

    log "Memória RAM: ${MEM_GB} GB"
    log "Espaço livre: ${DISK_GB} GB"

    if [ "$MEM_GB" -lt 4 ]; then
        warn "Recomendado: 8 GB+ de RAM."
    fi
    if [ "$DISK_GB" -lt 20 ]; then
        error "Espaço insuficiente. Mínimo: 20 GB livres."
    fi
}

install_homebrew() {
    if command -v brew &>/dev/null; then
        log "Homebrew já instalado."
    else
        log "Instalando Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_docker() {
    if command -v docker &>/dev/null; then
        log "Docker já instalado: $(docker --version)"
        return
    fi

    log "Instalando Docker Desktop via Homebrew..."
    brew install --cask docker

    warn "Docker Desktop instalado. Abra-o pela primeira vez para concluir a configuração."
    warn "Depois, execute este script novamente."
    open -a Docker
    exit 0
}

install_sentinela() {
    if [ -d "$SENTINELA_DIR" ] && [ -f "$SENTINELA_DIR/docker-compose.yml" ]; then
        log "Projeto já existe em $SENTINELA_DIR"
    else
        if ! command -v git &>/dev/null; then
            brew install git
        fi
        log "Clonando repositório..."
        git clone "$REPO_URL" "$SENTINELA_DIR" 2>/dev/null || {
            warn "Clone falhou. Copiando arquivos locais..."
            mkdir -p "$SENTINELA_DIR"
            cp -r "$(dirname "$0")/.." "$SENTINELA_DIR"
        }
    fi

    cd "$SENTINELA_DIR"

    if [ ! -f .env ]; then
        cp .env.example .env
        log "Arquivo .env criado."
    fi
}

select_profile() {
    echo ""
    echo -e "${AMBER}Escolha o perfil de instalação:${NC}"
    echo ""
    echo "  1) Essencial   — Portal + Biblioteca (~5 GB)"
    echo "  2) Padrão      — Essencial + Educação (~20 GB)"
    echo "  3) Completa    — Padrão + IA Offline (~40 GB+)"
    echo ""
    read -rp "Opção [1/2/3]: " PROFILE

    case "$PROFILE" in
        2) COMPOSE_PROFILES="--profile educacao" ;;
        3) COMPOSE_PROFILES="--profile educacao --profile ia" ;;
        *) COMPOSE_PROFILES="" ;;
    esac
}

start_services() {
    cd "$SENTINELA_DIR"
    log "Construindo e iniciando serviços..."
    # shellcheck disable=SC2086
    docker compose $COMPOSE_PROFILES up -d --build

    IP=$(ipconfig getifaddr en0 2>/dev/null || echo "localhost")

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Protocolo Sentinela está rodando!               ║${NC}"
    echo -e "${GREEN}║                                                  ║${NC}"
    echo -e "${GREEN}║  Local:   http://localhost                       ║${NC}"
    echo -e "${GREEN}║  Rede:    http://${IP}                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

main() {
    banner
    check_macos
    check_resources
    install_homebrew
    install_docker
    install_sentinela
    select_profile
    start_services
}

main "$@"
