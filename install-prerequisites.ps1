# ============================================================================
# Kiro SAP ABAP Power - Instalador de Prerequisitos
# ============================================================================
# Descripcion: Instala automaticamente Python y Git si no estan instalados
# Uso: .\install-prerequisites.ps1
# ============================================================================

$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

Write-Host ""
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host "  Kiro SAP ABAP Power - Instalador de Prerequisitos" -ForegroundColor $ColorInfo
Write-Host "  Amrize BP - 2026" -ForegroundColor $ColorInfo
Write-Host "================================================================" -ForegroundColor $ColorInfo
Write-Host ""

# ============================================================================
# Funcion: Verificar si tiene permisos de administrador
# ============================================================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# Funcion: Verificar si winget esta disponible
# ============================================================================
function Test-Winget {
    try {
        $wingetVersion = winget --version 2>&1
        return $true
    } catch {
        return $false
    }
}

# ============================================================================
# Funcion: Instalar Python
# ============================================================================
function Install-Python {
    Write-Host "[1/2] Verificando Python..." -ForegroundColor $ColorInfo
    
    # Verificar si Python ya esta instalado
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            
            if ($major -ge 3 -and $minor -ge 10) {
                Write-Host "  [OK] Python $pythonVersion ya esta instalado" -ForegroundColor $ColorSuccess
                return $true
            } else {
                Write-Host "  [!] Python $pythonVersion encontrado, pero se requiere 3.10+" -ForegroundColor $ColorWarning
                Write-Host "  Instalando Python 3.12..." -ForegroundColor $ColorInfo
            }
        }
    } catch {
        Write-Host "  [!] Python no encontrado. Instalando..." -ForegroundColor $ColorWarning
    }
    
    # Intentar instalar con winget
    if (Test-Winget) {
        Write-Host "  Instalando Python 3.12 con winget..." -ForegroundColor $ColorInfo
        try {
            winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
            Write-Host "  [OK] Python 3.12 instalado exitosamente" -ForegroundColor $ColorSuccess
            Write-Host "  [!] IMPORTANTE: Cierra y abre PowerShell nuevamente para usar Python" -ForegroundColor $ColorWarning
            return $true
        } catch {
            Write-Host "  [ERROR] Error instalando Python con winget: $_" -ForegroundColor $ColorError
        }
    }
    
    # Si winget no funciono, dar instrucciones manuales
    Write-Host ""
    Write-Host "  [!] No se pudo instalar Python automaticamente" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "  Opciones de instalacion manual:" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "  Opcion 1: Microsoft Store (recomendado, no requiere admin)" -ForegroundColor $ColorSuccess
    Write-Host "    1. Abre Microsoft Store" -ForegroundColor $ColorInfo
    Write-Host "    2. Busca 'Python 3.12'" -ForegroundColor $ColorInfo
    Write-Host "    3. Click en 'Obtener' o 'Instalar'" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "  Opcion 2: Descarga manual" -ForegroundColor $ColorSuccess
    Write-Host "    1. Ve a: https://www.python.org/downloads/" -ForegroundColor $ColorInfo
    Write-Host "    2. Descarga Python 3.12.x" -ForegroundColor $ColorInfo
    Write-Host "    3. Ejecuta el instalador" -ForegroundColor $ColorInfo
    Write-Host "    4. IMPORTANTE: Marca 'Add Python to PATH'" -ForegroundColor $ColorWarning
    Write-Host ""
    
    $openStore = Read-Host "  Deseas abrir Microsoft Store ahora? (S/N)"
    if ($openStore -eq "S" -or $openStore -eq "s") {
        Start-Process "ms-windows-store://pdp/?ProductId=9NCVDN91XZQP"
        Write-Host "  [OK] Microsoft Store abierto. Instala Python y luego ejecuta este script nuevamente." -ForegroundColor $ColorSuccess
    }
    
    return $false
}

# ============================================================================
# Funcion: Instalar Git
# ============================================================================
function Install-Git {
    Write-Host ""
    Write-Host "[2/2] Verificando Git..." -ForegroundColor $ColorInfo
    
    # Verificar si Git ya esta instalado
    try {
        $gitVersion = git --version 2>&1
        Write-Host "  [OK] $gitVersion ya esta instalado" -ForegroundColor $ColorSuccess
        return $true
    } catch {
        Write-Host "  [!] Git no encontrado" -ForegroundColor $ColorWarning
    }
    
    $installGit = Read-Host "  Deseas instalar Git? (S/N) [Opcional pero recomendado]"
    
    if ($installGit -ne "S" -and $installGit -ne "s") {
        Write-Host "  [!] Git no sera instalado (puedes instalarlo mas tarde)" -ForegroundColor $ColorWarning
        return $true
    }
    
    # Intentar instalar con winget
    if (Test-Winget) {
        Write-Host "  Instalando Git con winget..." -ForegroundColor $ColorInfo
        try {
            winget install Git.Git --silent --accept-package-agreements --accept-source-agreements
            Write-Host "  [OK] Git instalado exitosamente" -ForegroundColor $ColorSuccess
            Write-Host "  [!] IMPORTANTE: Cierra y abre PowerShell nuevamente para usar Git" -ForegroundColor $ColorWarning
            return $true
        } catch {
            Write-Host "  [ERROR] Error instalando Git con winget: $_" -ForegroundColor $ColorError
        }
    }
    
    # Si winget no funciono, dar instrucciones manuales
    Write-Host ""
    Write-Host "  [!] No se pudo instalar Git automaticamente" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "  Instalacion manual:" -ForegroundColor $ColorInfo
    Write-Host "    1. Ve a: https://git-scm.com/download/win" -ForegroundColor $ColorInfo
    Write-Host "    2. Descarga el instalador" -ForegroundColor $ColorInfo
    Write-Host "    3. Ejecuta el instalador con opciones por defecto" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $openBrowser = Read-Host "  Deseas abrir el sitio de descarga ahora? (S/N)"
    if ($openBrowser -eq "S" -or $openBrowser -eq "s") {
        Start-Process "https://git-scm.com/download/win"
        Write-Host "  [OK] Navegador abierto. Descarga e instala Git, luego ejecuta este script nuevamente." -ForegroundColor $ColorSuccess
    }
    
    return $false
}

# ============================================================================
# Funcion: Verificar instalacion
# ============================================================================
function Test-Installation {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor $ColorInfo
    Write-Host "  Verificacion de Instalacion" -ForegroundColor $ColorInfo
    Write-Host "================================================================" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $allGood = $true
    
    # Verificar Python
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "  [OK] Python: $pythonVersion" -ForegroundColor $ColorSuccess
    } catch {
        Write-Host "  [ERROR] Python no encontrado" -ForegroundColor $ColorError
        Write-Host "  [!] Cierra y abre PowerShell nuevamente, o reinicia tu computadora" -ForegroundColor $ColorWarning
        $allGood = $false
    }
    
    # Verificar pip
    try {
        $pipVersion = pip --version 2>&1
        Write-Host "  [OK] pip instalado" -ForegroundColor $ColorSuccess
    } catch {
        Write-Host "  [ERROR] pip no encontrado" -ForegroundColor $ColorError
        $allGood = $false
    }
    
    # Verificar Git (opcional)
    try {
        $gitVersion = git --version 2>&1
        Write-Host "  [OK] Git: $gitVersion" -ForegroundColor $ColorSuccess
    } catch {
        Write-Host "  [!] Git no encontrado (opcional)" -ForegroundColor $ColorWarning
    }
    
    Write-Host ""
    
    if ($allGood) {
        Write-Host "================================================================" -ForegroundColor $ColorInfo
        Write-Host "  [OK] Todos los prerequisitos estan instalados!" -ForegroundColor $ColorSuccess
        Write-Host "================================================================" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  Proximos pasos:" -ForegroundColor $ColorInfo
        Write-Host "  1. Si acabas de instalar Python, cierra y abre PowerShell" -ForegroundColor $ColorWarning
        Write-Host "  2. Ejecuta el instalador de Kiro:" -ForegroundColor $ColorInfo
        Write-Host "     .\install.ps1 -SAPUser 'TU_USUARIO_SAP'" -ForegroundColor $ColorSuccess
        Write-Host ""
    } else {
        Write-Host "================================================================" -ForegroundColor $ColorInfo
        Write-Host "  [!] Algunos prerequisitos faltan" -ForegroundColor $ColorWarning
        Write-Host "================================================================" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  Acciones requeridas:" -ForegroundColor $ColorInfo
        Write-Host "  1. Instala los prerequisitos faltantes (ver arriba)" -ForegroundColor $ColorWarning
        Write-Host "  2. Cierra y abre PowerShell nuevamente" -ForegroundColor $ColorWarning
        Write-Host "  3. Ejecuta este script nuevamente para verificar" -ForegroundColor $ColorWarning
        Write-Host ""
    }
    
    return $allGood
}

# ============================================================================
# MAIN: Ejecutar instalacion
# ============================================================================

Write-Host "Este script instalara los prerequisitos necesarios para Kiro SAP ABAP Power:" -ForegroundColor $ColorInfo
Write-Host "  - Python 3.12 (requerido)" -ForegroundColor $ColorInfo
Write-Host "  - Git (opcional pero recomendado)" -ForegroundColor $ColorInfo
Write-Host ""

# Verificar si tiene winget
if (-not (Test-Winget)) {
    Write-Host "[!] winget no esta disponible" -ForegroundColor $ColorWarning
    Write-Host "    Se proporcionaran instrucciones de instalacion manual" -ForegroundColor $ColorInfo
    Write-Host ""
}

# Instalar Python
$pythonInstalled = Install-Python

# Instalar Git
$gitInstalled = Install-Git

# Verificar instalacion
$allInstalled = Test-Installation

# Exit code
if ($allInstalled) {
    exit 0
} else {
    exit 1
}
