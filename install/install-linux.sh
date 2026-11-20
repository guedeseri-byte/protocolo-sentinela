#!/usr/bin/env bash
set -euo pipefail

# ══════════════════════════════════════════════════════════════
# PROTOCOLO SENTINELA — Instalador Linux (Ubuntu/Debian)
# Sistema Offline de Preparação, Sobrevivência e Continuidade
# ══════════════════════════════════════════════════════════════

SENTINELA_VERSION="0.1.0"
SENTINELA_DIR="${SENTINELA_DIR:-/opt/protocolo-sentinela}"
REPO_URL="https://github.com/guedeseri-byte/protocolo-sentinela"

# Cores
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

# ── Verificações ─────────────────────────────────────────────

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Execute como root: sudo bash $0"
    fi
}

check_os() {
    if [ ! -f /etc/os-release ]; then
        error "Sistema operacional não suportado."
    fi
    . /etc/os-release
    case "$ID" in
        ubuntu|debian|linuxmint|pop)
            log "Sistema detectado: $PRETTY_NAME"
            ;;
        fedora|rhel|centos|rocky|alma)
            warn "Suporte experimental para $PRETTY_NAME"
            ;;
        *)
            warn "Distribuição $ID não testada. Prosseguindo..."
            ;;
    esac
}

check_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  log "Arquitetura: x86_64" ;;
        aarch64) log "Arquitetura: ARM64" ;;
        armv7l)  log "Arquitetura: ARMv7 (funcionalidade limitada)" ;;
        *)       error "Arquitetura $ARCH não suportada." ;;
    esac
}

check_resources() {
    MEM_GB=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
    DISK_GB=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | tr -d 'G')

    log "Memória RAM: ${MEM_GB} GB"
    log "Espaço livre: ${DISK_GB} GB"

    if [ "$MEM_GB" -lt 4 ]; then
        warn "Recomendado: 8 GB+ de RAM. Instalação mínima possível com ${MEM_GB} GB."
    fi

    if [ "$DISK_GB" -lt 20 ]; then
        error "Espaço insuficiente. Mínimo: 20 GB livres (encontrado: ${DISK_GB} GB)."
    fi
}

# ── Instalação de dependências ───────────────────────────────

install_docker() {
    if command -v docker &>/dev/null; then
        log "Docker já instalado: $(docker --version)"
        return
    fi

    log "Instalando Docker..."
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    log "Docker instalado com sucesso."
}

install_sentinela() {
    log "Criando diretório: $SENTINELA_DIR"
    mkdir -p "$SENTINELA_DIR"

    if command -v git &>/dev/null; then
        log "Clonando repositório..."
        git clone "$REPO_URL" "$SENTINELA_DIR" 2>/dev/null || {
            warn "Clone falhou. Copiando arquivos locais se disponíveis..."
            if [ -f "$(dirname "$0")/../docker-compose.yml" ]; then
                cp -r "$(dirname "$0")/.." "$SENTINELA_DIR"
            else
                error "Não foi possível obter os arquivos do projeto."
            fi
        }
    else
        warn "Git não encontrado. Instalando..."
        apt-get install -y -qq git
        git clone "$REPO_URL" "$SENTINELA_DIR"
    fi

    cd "$SENTINELA_DIR"

    if [ ! -f .env ]; then
        cp .env.example .env
        log "Arquivo .env criado a partir do exemplo."
    fi
}

# ── Perfil de instalação ─────────────────────────────────────

select_profile() {
    echo ""
    echo -e "${AMBER}Escolha o perfil de instalação:${NC}"
    echo ""
    echo "  1) Essencial   — Portal + Biblioteca (Kiwix) + Busca"
    echo "                   ~5 GB após download de conteúdo"
    echo ""
    echo "  2) Padrão      — Essencial + Educação (Kolibri)"
    echo "                   ~20 GB após download de conteúdo"
    echo ""
    echo "  3) Completa    — Padrão + IA Offline (Ollama + Open WebUI)"
    echo "                   ~40 GB+ após download de modelos"
    echo ""
    read -rp "Opção [1/2/3]: " PROFILE

    case "$PROFILE" in
        1)
            COMPOSE_PROFILES=""
            log "Perfil: Essencial"
            ;;
        2)
            COMPOSE_PROFILES="--profile educacao"
            log "Perfil: Padrão (com Educação)"
            ;;
        3)
            COMPOSE_PROFILES="--profile educacao --profile ia"
            log "Perfil: Completa (com Educação + IA)"
            ;;
        *)
            COMPOSE_PROFILES=""
            log "Perfil: Essencial (padrão)"
            ;;
    esac
}

# ── Iniciar serviços ─────────────────────────────────────────

start_services() {
    cd "$SENTINELA_DIR"
    log "Construindo e iniciando serviços..."
    # shellcheck disable=SC2086
    docker compose $COMPOSE_PROFILES up -d --build

    echo ""
    log "Protocolo Sentinela está rodando!"
    echo ""

    IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Acesse no navegador:                           ║${NC}"
    echo -e "${GREEN}║                                                  ║${NC}"
    echo -e "${GREEN}║  Local:   http://localhost                       ║${NC}"
    echo -e "${GREEN}║  Rede:    http://${IP}                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Outros dispositivos na mesma rede podem acessar pelo IP acima."
    echo ""
}

# ── Main ─────────────────────────────────────────────────────

main() {
    banner
    check_root
    check_os
    check_arch
    check_resources
    install_docker
    install_sentinela
    select_profile
    start_services
}

main "$@"
