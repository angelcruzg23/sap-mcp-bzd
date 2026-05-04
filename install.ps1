# ============================================================================
# Kiro SAP ABAP Power - Instalador Automático
# ============================================================================
# Descripción: Configura automáticamente el ambiente de Kiro para SAP ABAP
# Autor: Equipo SAP ABAP - Amrize BP
# Versión: 1.0.0
# Fecha: 2026-05-04
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$SAPUser,
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultSystem = "BZD",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipPasswordPrompt
)

# Colores para output
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

# Banner
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $ColorInfo
Write-Host "║                                                                ║" -ForegroundColor $ColorInfo
Write-Host "║          Kiro SAP ABAP Power - Instalador v1.0.0              ║" -ForegroundColor $ColorInfo
Write-Host "║                    Amrize BP - 2026                            ║" -ForegroundColor $ColorInfo
Write-Host "║                                                                ║" -ForegroundColor $ColorInfo
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor $ColorInfo
Write-Host ""

# ============================================================================
# Función: Verificar prerequisitos
# ============================================================================
function Test-Prerequisites {
    Write-Host "🔍 Verificando prerequisitos..." -ForegroundColor $ColorInfo
    
    # Verificar Python
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            if ($major -ge 3 -and $minor -ge 8) {
                Write-Host "  ✓ Python $pythonVersion instalado" -ForegroundColor $ColorSuccess
            } else {
                Write-Host "  ✗ Python 3.8+ requerido. Versión actual: $pythonVersion" -ForegroundColor $ColorError
                return $false
            }
        }
    } catch {
        Write-Host "  ✗ Python no encontrado. Instala Python 3.8+ desde python.org" -ForegroundColor $ColorError
        return $false
    }
    
    # Verificar pip
    try {
        $pipVersion = pip --version 2>&1
        Write-Host "  ✓ pip instalado" -ForegroundColor $ColorSuccess
    } catch {
        Write-Host "  ✗ pip no encontrado" -ForegroundColor $ColorError
        return $false
    }
    
    # Verificar Git (opcional pero recomendado)
    try {
        $gitVersion = git --version 2>&1
        Write-Host "  ✓ Git instalado" -ForegroundColor $ColorSuccess
    } catch {
        Write-Host "  ⚠ Git no encontrado (opcional)" -ForegroundColor $ColorWarning
    }
    
    return $true
}

# ============================================================================
# Función: Instalar dependencias Python
# ============================================================================
function Install-PythonDependencies {
    Write-Host ""
    Write-Host "📦 Instalando dependencias Python..." -ForegroundColor $ColorInfo
    
    if (Test-Path "requirements.txt") {
        try {
            pip install -r requirements.txt --quiet
            Write-Host "  ✓ Dependencias instaladas correctamente" -ForegroundColor $ColorSuccess
            return $true
        } catch {
            Write-Host "  ✗ Error instalando dependencias: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  ⚠ requirements.txt no encontrado. Instalando dependencias básicas..." -ForegroundColor $ColorWarning
        try {
            pip install requests python-dotenv --quiet
            Write-Host "  ✓ Dependencias básicas instaladas" -ForegroundColor $ColorSuccess
            return $true
        } catch {
            Write-Host "  ✗ Error instalando dependencias básicas: $_" -ForegroundColor $ColorError
            return $false
        }
    }
}

# ============================================================================
# Función: Configurar password de SAP
# ============================================================================
function Set-SAPPassword {
    Write-Host ""
    Write-Host "🔐 Configurando credenciales SAP..." -ForegroundColor $ColorInfo
    
    if (-not $SkipPasswordPrompt) {
        $securePassword = Read-Host "  Ingresa tu password de SAP" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        # Configurar variable de entorno para el usuario
        [System.Environment]::SetEnvironmentVariable('SAP_PASSWORD', $password, 'User')
        Write-Host "  ✓ Password configurado de forma segura" -ForegroundColor $ColorSuccess
        
        # También configurar para la sesión actual
        $env:SAP_PASSWORD = $password
    } else {
        Write-Host "  ⚠ Saltando configuración de password (deberás configurarlo manualmente)" -ForegroundColor $ColorWarning
    }
}

# ============================================================================
# Función: Configurar MCP servers
# ============================================================================
function Set-MCPServers {
    param(
        [string]$User,
        [string]$DefaultSys
    )
    
    Write-Host ""
    Write-Host "⚙️  Configurando MCP servers..." -ForegroundColor $ColorInfo
    
    $mcpConfigPath = "$HOME\.kiro\settings"
    $mcpConfigFile = "$mcpConfigPath\mcp.json"
    
    # Crear directorio si no existe
    if (-not (Test-Path $mcpConfigPath)) {
        New-Item -ItemType Directory -Path $mcpConfigPath -Force | Out-Null
    }
    
    # Obtener ruta absoluta del proyecto
    $projectPath = (Get-Location).Path
    
    # Configuración de MCP servers
    $mcpConfig = @{
        mcpServers = @{
            "sap-bzd" = @{
                command = "python"
                args = @("$projectPath\server.py")
                env = @{
                    SAP_HOST = "fbpl08v010.holcimbp.net"
                    SAP_PORT = "8000"
                    SAP_CLIENT = "130"
                    SAP_USER = $User
                }
                disabled = $false
                autoApprove = @()
            }
            "sap-bzn" = @{
                command = "python"
                args = @("$projectPath\server.py")
                env = @{
                    SAP_HOST = "lfh02a09ld075.holcimbp.net"
                    SAP_PORT = "8040"
                    SAP_CLIENT = "100"
                    SAP_USER = $User
                }
                disabled = $false
                autoApprove = @()
            }
        }
    }
    
    # Guardar configuración
    try {
        $mcpConfig | ConvertTo-Json -Depth 10 | Out-File $mcpConfigFile -Encoding UTF8
        Write-Host "  ✓ MCP servers configurados:" -ForegroundColor $ColorSuccess
        Write-Host "    - sap-bzd (BZD - Desarrollo)" -ForegroundColor $ColorSuccess
        Write-Host "    - sap-bzn (BZN - Sandbox)" -ForegroundColor $ColorSuccess
    } catch {
        Write-Host "  ✗ Error configurando MCP servers: $_" -ForegroundColor $ColorError
        return $false
    }
    
    return $true
}

# ============================================================================
# Función: Copiar steering files
# ============================================================================
function Copy-SteeringFiles {
    Write-Host ""
    Write-Host "📝 Copiando steering files..." -ForegroundColor $ColorInfo
    
    $sourceDir = ".\.kiro\steering"
    $targetDir = "$HOME\.kiro\steering"
    
    if (Test-Path $sourceDir) {
        # Crear directorio destino si no existe
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Copiar archivos
        try {
            Copy-Item -Path "$sourceDir\*" -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  ✓ $fileCount steering files copiados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  ✗ Error copiando steering files: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  ⚠ Directorio de steering files no encontrado" -ForegroundColor $ColorWarning
    }
    
    return $true
}

# ============================================================================
# Función: Copiar skills
# ============================================================================
function Copy-Skills {
    Write-Host ""
    Write-Host "🎯 Copiando skills..." -ForegroundColor $ColorInfo
    
    $sourceDir = ".\.kiro\skills"
    $targetDir = "$HOME\.kiro\skills"
    
    if (Test-Path $sourceDir) {
        # Crear directorio destino si no existe
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Copiar archivos
        try {
            Copy-Item -Path "$sourceDir\*" -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  ✓ $fileCount skills copiados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  ✗ Error copiando skills: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  ⚠ Directorio de skills no encontrado" -ForegroundColor $ColorWarning
    }
    
    return $true
}

# ============================================================================
# Función: Instalar hooks
# ============================================================================
function Install-Hooks {
    Write-Host ""
    Write-Host "🪝 Instalando hooks..." -ForegroundColor $ColorInfo
    
    $sourceDir = ".\.kiro\hooks"
    $targetDir = "$HOME\.kiro\hooks"
    
    if (Test-Path $sourceDir) {
        # Crear directorio destino si no existe
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Copiar archivos
        try {
            Copy-Item -Path "$sourceDir\*" -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  ✓ $fileCount hooks instalados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  ✗ Error instalando hooks: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  ⚠ Directorio de hooks no encontrado" -ForegroundColor $ColorWarning
    }
    
    return $true
}

# ============================================================================
# Función: Copiar templates
# ============================================================================
function Copy-Templates {
    Write-Host ""
    Write-Host "📄 Copiando templates ABAP..." -ForegroundColor $ColorInfo
    
    $sourceDir = ".\templates"
    $targetDir = "$HOME\.kiro\templates\abap"
    
    if (Test-Path $sourceDir) {
        # Crear directorio destino si no existe
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Copiar archivos
        try {
            Copy-Item -Path "$sourceDir\*" -Destination $targetDir -Force -Recurse
            $fileCount = (Get-ChildItem $targetDir -File).Count
            Write-Host "  ✓ $fileCount templates copiados" -ForegroundColor $ColorSuccess
        } catch {
            Write-Host "  ✗ Error copiando templates: $_" -ForegroundColor $ColorError
            return $false
        }
    } else {
        Write-Host "  ⚠ Directorio de templates no encontrado" -ForegroundColor $ColorWarning
    }
    
    return $true
}

# ============================================================================
# Función: Verificar conexión a SAP
# ============================================================================
function Test-SAPConnection {
    Write-Host ""
    Write-Host "🔌 Verificando conexión a SAP BZD..." -ForegroundColor $ColorInfo
    
    try {
        $testScript = @"
import requests
from requests.auth import HTTPBasicAuth
import os

host = 'fbpl08v010.holcimbp.net'
port = '8000'
client = '130'
user = '$SAPUser'
password = os.environ.get('SAP_PASSWORD', '')

if not password:
    print('ERROR: SAP_PASSWORD no configurado')
    exit(1)

try:
    response = requests.get(
        f'http://{host}:{port}/sap/bc/adt/discovery',
        auth=HTTPBasicAuth(user, password),
        headers={'sap-client': client},
        timeout=10
    )
    if response.status_code == 200:
        print('SUCCESS')
    else:
        print(f'ERROR: Status {response.status_code}')
except Exception as e:
    print(f'ERROR: {str(e)}')
"@
        
        $result = $testScript | python
        
        if ($result -eq "SUCCESS") {
            Write-Host "  ✓ Conexión exitosa con SAP BZD" -ForegroundColor $ColorSuccess
            return $true
        } else {
            Write-Host "  ✗ Error de conexión: $result" -ForegroundColor $ColorError
            Write-Host "  ℹ Verifica:" -ForegroundColor $ColorWarning
            Write-Host "    - Estás en la red corporativa o VPN conectada" -ForegroundColor $ColorWarning
            Write-Host "    - Tu usuario y password son correctos" -ForegroundColor $ColorWarning
            Write-Host "    - El servidor SAP está disponible" -ForegroundColor $ColorWarning
            return $false
        }
    } catch {
        Write-Host "  ✗ Error verificando conexión: $_" -ForegroundColor $ColorError
        return $false
    }
}

# ============================================================================
# Función: Mostrar resumen
# ============================================================================
function Show-Summary {
    param(
        [bool]$Success
    )
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    
    if ($Success) {
        Write-Host ""
        Write-Host "✅ ¡Instalación completada exitosamente!" -ForegroundColor $ColorSuccess
        Write-Host ""
        Write-Host "📋 Resumen de configuración:" -ForegroundColor $ColorInfo
        Write-Host "  • Usuario SAP: $SAPUser" -ForegroundColor $ColorInfo
        Write-Host "  • Sistema por defecto: $DefaultSystem" -ForegroundColor $ColorInfo
        Write-Host "  • MCP servers: sap-bzd, sap-bzn" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "🎯 Próximos pasos:" -ForegroundColor $ColorInfo
        Write-Host "  1. Reinicia Kiro para aplicar los cambios" -ForegroundColor $ColorWarning
        Write-Host "  2. Verifica que los MCP servers estén conectados (panel lateral)" -ForegroundColor $ColorWarning
        Write-Host "  3. Prueba con: 'Verifica la conexión con SAP BZD'" -ForegroundColor $ColorWarning
        Write-Host ""
        Write-Host "📚 Recursos disponibles:" -ForegroundColor $ColorInfo
        Write-Host "  • Skills: #sap-mcp-capabilities, #solid-refactoring, #transport-management" -ForegroundColor $ColorInfo
        Write-Host "  • Steering files: Contexto, convenciones, estándares, patrones" -ForegroundColor $ColorInfo
        Write-Host "  • Hooks: Validaciones automáticas de sintaxis y transportes" -ForegroundColor $ColorInfo
        Write-Host "  • Templates: Clases, DAOs, FMs, Reports" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "💡 Documentación completa: ONBOARDING_NUEVO_DESARROLLADOR.md" -ForegroundColor $ColorInfo
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "❌ La instalación encontró errores" -ForegroundColor $ColorError
        Write-Host ""
        Write-Host "🔍 Revisa los mensajes de error arriba" -ForegroundColor $ColorWarning
        Write-Host "📞 Si necesitas ayuda, contacta al equipo SAP" -ForegroundColor $ColorWarning
        Write-Host ""
    }
    
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
}

# ============================================================================
# MAIN: Ejecutar instalación
# ============================================================================

$installSuccess = $true

# Paso 1: Verificar prerequisitos
if (-not (Test-Prerequisites)) {
    $installSuccess = $false
    Show-Summary -Success $false
    exit 1
}

# Paso 2: Instalar dependencias Python
if (-not (Install-PythonDependencies)) {
    $installSuccess = $false
}

# Paso 3: Configurar password
Set-SAPPassword

# Paso 4: Configurar MCP servers
if (-not (Set-MCPServers -User $SAPUser -DefaultSys $DefaultSystem)) {
    $installSuccess = $false
}

# Paso 5: Copiar steering files
if (-not (Copy-SteeringFiles)) {
    $installSuccess = $false
}

# Paso 6: Copiar skills
if (-not (Copy-Skills)) {
    $installSuccess = $false
}

# Paso 7: Instalar hooks
if (-not (Install-Hooks)) {
    $installSuccess = $false
}

# Paso 8: Copiar templates
if (-not (Copy-Templates)) {
    $installSuccess = $false
}

# Paso 9: Verificar conexión (solo si todo lo anterior fue exitoso)
if ($installSuccess -and -not $SkipPasswordPrompt) {
    if (-not (Test-SAPConnection)) {
        Write-Host ""
        Write-Host "⚠ La instalación se completó pero la conexión a SAP falló" -ForegroundColor $ColorWarning
        Write-Host "  Podrás configurar la conexión más tarde" -ForegroundColor $ColorWarning
    }
}

# Mostrar resumen
Show-Summary -Success $installSuccess

# Exit code
if ($installSuccess) {
    exit 0
} else {
    exit 1
}
