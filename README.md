<p align="center">
  <img src="portal/static/img/logo.png" alt="Protocolo Sentinela" width="120">
</p>

<h1 align="center">PROTOCOLO SENTINELA</h1>

<p align="center">
  <strong>Preparação · Conhecimento · Autonomia</strong><br>
  Sistema Offline de Preparação, Sobrevivência e Continuidade
</p>

<p align="center">
  <img src="https://img.shields.io/badge/versão-0.1.0-blue" alt="Versão">
  <img src="https://img.shields.io/badge/licença-MIT-green" alt="Licença">
  <img src="https://img.shields.io/badge/status-MVP-orange" alt="Status">
</p>

---

## O que é

O **Protocolo Sentinela** é um servidor local que reúne conhecimento essencial para funcionar **100% offline**. Inspirado no [Project NOMAD](https://projectnomad.us), adaptado para a realidade brasileira com conteúdo de fontes como Embrapa, SUS, Exército Brasileiro, Defesa Civil, IBGE e Fiocruz.

Roda em qualquer computador com Docker — do notebook até um Raspberry Pi. Uma vez instalado e com conteúdo baixado, funciona para sempre sem internet.

## Funcionalidades

| Serviço | Descrição | Perfil |
|---------|-----------|--------|
| **Portal Web** | Interface central com 14 módulos temáticos | Sempre ativo |
| **Kiwix** | Wikipedia PT-BR, Wikibooks, Gutenberg offline | Sempre ativo |
| **Kolibri** | Plataforma educacional offline (Khan Academy PT-BR) | `educacao` |
| **Ollama** | Execução local de LLMs (Sabiá-3, Tucano, Qwen3) | `ia` |
| **Open WebUI** | Interface de chat para IA local com RAG | `ia` |

### 14 Módulos

🛡️ Preparação · ⚔️ Sobrevivência · 💧 Água · 🌾 Alimentação · 🏥 Saúde · 🧭 Navegação · ⚡ Energia · 📡 Comunicação · 🌪️ Desastres · 🔧 Manutenção · 🌱 Agricultura · 🔒 Segurança · 📦 Logística · 🤖 Tecnologia/IA

## Requisitos

| | Mínimo | Recomendado |
|--|--------|-------------|
| **RAM** | 4 GB | 8 GB (16 GB com IA) |
| **Disco** | 20 GB | 100 GB+ (com conteúdo e modelos) |
| **Docker** | v24+ | v27+ |
| **SO** | Ubuntu 22.04 / Windows 10 / macOS 12 | Ubuntu 24.04 / Windows 11 / macOS 14 |

## Instalação Rápida

### Linux (Ubuntu/Debian)

```bash
sudo bash install/install-linux.sh
```

### Windows

```powershell
# Executar como Administrador
.\install\install-windows.ps1
```

### macOS

```bash
bash install/install-macos.sh
```

### Manual (qualquer OS com Docker)

```bash
git clone https://github.com/guedeseri-byte/protocolo-sentinela
cd protocolo-sentinela
cp .env.example .env

# Essencial (Portal + Biblioteca)
docker compose up -d

# Com Educação
docker compose --profile educacao up -d

# Completo (Educação + IA Offline)
docker compose --profile educacao --profile ia up -d
```

## Acesso

Após iniciar, acesse no navegador:

| Serviço | URL |
|---------|-----|
| Portal (início) | `http://localhost` |
| Biblioteca (Kiwix) | `http://localhost/biblioteca/` |
| IA (Open WebUI) | `http://localhost/ia/` |
| Educação (Kolibri) | `http://localhost/educacao/` |

Outros dispositivos na mesma rede acessam pelo IP da máquina.

## Estrutura do Projeto

```
protocolo-sentinela/
├── docker-compose.yml      # Orquestração dos serviços
├── .env.example             # Variáveis de configuração
├── portal/                  # Aplicação web FastAPI
│   ├── main.py              # Rotas e lógica
│   ├── templates/           # HTML (Jinja2)
│   ├── static/css/          # Estilos dark mode
│   └── static/img/          # Logo e assets
├── deploy/
│   └── caddy/Caddyfile      # Proxy reverso
├── install/                 # Instaladores por OS
│   ├── install-linux.sh
│   ├── install-windows.ps1
│   └── install-macos.sh
├── modules/                 # Conteúdo dos 14 módulos
├── content/                 # Catálogo e manifestos
├── tools/                   # Ferramentas (inventário, calculadoras)
├── scripts/                 # Scripts utilitários
└── tests/                   # Testes funcionais e offline
```

## Perfis de Instalação

| Perfil | Serviços | Espaço estimado |
|--------|----------|-----------------|
| **Essencial** | Portal + Kiwix + Caddy | ~5 GB |
| **Padrão** | Essencial + Kolibri | ~20 GB |
| **Completo** | Padrão + Ollama + Open WebUI | ~40 GB+ |

## Modelos de IA Recomendados

Para uso com Ollama no perfil Completo:

| Modelo | Tamanho | Idioma | Uso |
|--------|---------|--------|-----|
| **Sabiá-3** (Maritaca AI) | 8B | PT-BR nativo | Consultas gerais |
| **Tucano** (C4AI-USP) | 8B | PT-BR nativo | Texto e análise |
| **Qwen3** | 8B | Multilíngue | Raciocínio e código |
| **Llama 3.1** | 8B | Multilíngue | Uso geral |

```bash
# Baixar modelo após instalação
docker exec sentinela-ollama ollama pull sabia-3
```

## Comandos Úteis

```bash
# Ver status dos serviços
docker compose ps

# Ver logs
docker compose logs -f portal

# Parar tudo
docker compose down

# Atualizar
git pull && docker compose up -d --build
```

## Roadmap

- [x] **Fase 1** — Infraestrutura base (Docker, Portal, Kiwix)
- [ ] **Fase 2** — Conteúdo curado (protocolos, manuais, guias)
- [ ] **Fase 3** — IA offline com RAG sobre documentos locais
- [ ] **Fase 4** — Mapas offline (OpenStreetMap + IBGE)
- [ ] **Fase 5** — Modo de Emergência (interface simplificada)
- [ ] **Fase 6** — Central de Protocolos (taxonomia PREP/AGUA/ALIM/SAUD)
- [ ] **Fase 7** — Resiliência comunitária e mesh networking

## Aviso Legal

> ⚠️ **Este sistema é uma ferramenta de apoio educacional e informativo.**
> Em emergências reais, ligue **SAMU 192** ou **Bombeiros 193**.
> O Protocolo Sentinela não substitui orientação profissional médica, técnica ou de segurança.

## Licença

MIT — veja [LICENSE](LICENSE) para detalhes.

---

<p align="center">
  <strong>PROTOCOLO SENTINELA</strong><br>
  <em>Preparação. Conhecimento. Autonomia.</em>
</p>
