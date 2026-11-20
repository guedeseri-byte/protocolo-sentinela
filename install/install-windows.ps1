# ══════════════════════════════════════════════════════════════
# PROTOCOLO SENTINELA — Instalador Windows (via WSL2 + Docker)
# Sistema Offline de Preparação, Sobrevivência e Continuidade
# ══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$SENTINELA_VERSION = "0.1.0"

function Write-Banner {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║          PROTOCOLO SENTINELA v$SENTINELA_VERSION            ║" -ForegroundColor Cyan
    Write-Host "  ║   Preparação. Conhecimento. Autonomia.          ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Log   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "  [XX] $msg" -ForegroundColor Red; exit 1 }

# ── Verificações ─────────────────────────────────────────────

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Err "Execute como Administrador: clique com botão direito no PowerShell e escolha 'Executar como administrador'."
    }
}

function Test-Resources {
    $mem = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    $disk = [math]::Round((Get-PSDrive C).Free / 1GB)

    Write-Log "Memória RAM: $mem GB"
    Write-Log "Espaço livre (C:): $disk GB"

    if ($mem -lt 4) {
        Write-Warn "Recomendado: 8 GB+ de RAM."
    }
    if ($disk -lt 20) {
        Write-Err "Espaço insuficiente. Mínimo: 20 GB livres (encontrado: $disk GB)."
    }
}

# ── WSL2 ─────────────────────────────────────────────────────

function Install-WSL2 {
    $wslInstalled = $false
    try {
        $wslVersion = wsl --version 2>$null
        if ($LASTEXITCODE -eq 0) { $wslInstalled = $true }
    } catch {}

    if ($wslInstalled) {
        Write-Log "WSL2 já instalado."
    } else {
        Write-Log "Instalando WSL2 (pode reiniciar o computador)..."
        wsl --install --no-distribution
        Write-Warn "WSL2 instalado. Se solicitado, REINICIE o computador e execute este script novamente."
        Write-Host ""
        Read-Host "Pressione Enter para continuar (ou feche e reinicie se necessário)"
    }
}

# ── Docker Desktop ───────────────────────────────────────────

function Install-DockerDesktop {
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Log "Docker Desktop já instalado."
        return
    }

    Write-Log "Baixando Docker Desktop..."
    $installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"

    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

    Write-Log "Instalando Docker Desktop (isso pode demorar)..."
    Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet", "--accept-license" -Wait

    Write-Warn "Docker Desktop instalado. Abra-o manualmente e aguarde inicializar."
    Write-Warn "Depois, execute este script novamente para continuar a instalação."
}

function Test-Docker {
    try {
        $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Docker funcionando: v$dockerVersion"
            return $true
        }
    } catch {}

    Write-Warn "Docker não está respondendo. Verifique se o Docker Desktop está aberto e funcionando."
    return $false
}

# ── Instalação do Sentinela ──────────────────────────────────

function Install-Sentinela {
    $sentinelaDir = "$env:USERPROFILE\protocolo-sentinela"

    if (Test-Path "$sentinelaDir\docker-compose.yml") {
        Write-Log "Projeto já existe em $sentinelaDir"
    } else {
        Write-Log "Clonando repositório..."
        try {
            git clone "https://github.com/guedeseri-byte/protocolo-sentinela" $sentinelaDir
        } catch {
            Write-Warn "Git não encontrado. Instalando via winget..."
            winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
            $env:PATH += ";C:\Program Files\Git\cmd"
            git clone "https://github.com/guedeseri-byte/protocolo-sentinela" $sentinelaDir
        }
    }

    Set-Location $sentinelaDir

    if (-not (Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Log "Arquivo .env criado."
    }
}

# ── Perfil de instalação ─────────────────────────────────────

function Select-Profile {
    Write-Host ""
    Write-Host "  Escolha o perfil de instalação:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1) Essencial   - Portal + Biblioteca (~5 GB)"
    Write-Host "  2) Padrão      - Essencial + Educação (~20 GB)"
    Write-Host "  3) Completa    - Padrão + IA Offline (~40 GB+)"
    Write-Host ""
    $choice = Read-Host "  Opção [1/2/3]"

    switch ($choice) {
        "2" { return "--profile educacao" }
        "3" { return "--profile educacao --profile ia" }
        default { return "" }
    }
}

# ── Iniciar ──────────────────────────────────────────────────

function Start-Sentinela {
    param($profiles)

    Write-Log "Construindo e iniciando serviços..."
    $cmd = "docker compose $profiles up -d --build"
    Invoke-Expression $cmd

    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.PrefixOrigin -eq "Dhcp" } | Select-Object -First 1).IPAddress

    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║  Protocolo Sentinela está rodando!               ║" -ForegroundColor Green
    Write-Host "  ║                                                  ║" -ForegroundColor Green
    Write-Host "  ║  Local:   http://localhost                       ║" -ForegroundColor Green
    Write-Host "  ║  Rede:    http://$ip                   ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

# ── Main ─────────────────────────────────────────────────────

Write-Banner
Test-Admin
Test-Resources
Install-WSL2
Install-DockerDesktop

if (Test-Docker) {
    Install-Sentinela
    $profiles = Select-Profile
    Start-Sentinela -profiles $profiles
} else {
    Write-Warn "Abra o Docker Desktop, aguarde inicializar e execute este script novamente."
}
