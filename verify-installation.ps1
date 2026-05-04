# ============================================================================
# Kiro SAP ABAP Power - Script de Verificación
# ============================================================================
# Descripción: Verifica que la instalación se completó correctamente
# Uso: .\verify-installation.ps1
# ============================================================================

$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

Write-Host ""
Write-Host "🔍 Verificando instalación de Kiro SAP ABAP Power..." -ForegroundColor $ColorInfo
Write-Host ""

$allChecks = $true

# ============================================================================
# Check 1: Python y dependencias
# ============================================================================
Write-Host "1️⃣  Verificando Python y dependencias..." -ForegroundColor $ColorInfo

try {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✓ Python: $pythonVersion" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "  ✗ Python no encontrado" -ForegroundColor $ColorError
    $allChecks = $false
}

try {
    $result = python -c "import requests; print('OK')" 2>&1
    if ($result -eq "OK") {
        Write-Host "  ✓ Librería requests instalada" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "  ✗ Librería requests no encontrada" -ForegroundColor $ColorError
        $allChecks = $false
    }
} catch {
    Write-Host "  ✗ Error verificando dependencias" -ForegroundColor $ColorError
    $allChecks = $false
}

# ============================================================================
# Check 2: Archivos del proyecto
# ============================================================================
Write-Host ""
Write-Host "2️⃣  Verificando archivos del proyecto..." -ForegroundColor $ColorInfo

$requiredFiles = @(
    "server.py",
    "sap_client.py",
    "requirements.txt"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file encontrado" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "  ✗ $file no encontrado" -ForegroundColor $ColorError
        $allChecks = $false
    }
}

# ============================================================================
# Check 3: Configuración de MCP
# ============================================================================
Write-Host ""
Write-Host "3️⃣  Verificando configuración de MCP..." -ForegroundColor $ColorInfo

$mcpConfigFile = "$HOME\.kiro\settings\mcp.json"

if (Test-Path $mcpConfigFile) {
    Write-Host "  ✓ Archivo mcp.json encontrado" -ForegroundColor $ColorSuccess
    
    try {
        $mcpConfig = Get-Content $mcpConfigFile | ConvertFrom-Json
        
        if ($mcpConfig.mcpServers."sap-bzd") {
            Write-Host "  ✓ MCP server 'sap-bzd' configurado" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "  ✗ MCP server 'sap-bzd' no encontrado" -ForegroundColor $ColorError
            $allChecks = $false
        }
        
        if ($mcpConfig.mcpServers."sap-bzn") {
            Write-Host "  ✓ MCP server 'sap-bzn' configurado" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "  ⚠ MCP server 'sap-bzn' no encontrado (opcional)" -ForegroundColor $ColorWarning
        }
    } catch {
        Write-Host "  ✗ Error leyendo mcp.json: $_" -ForegroundColor $ColorError
        $allChecks = $false
    }
} else {
    Write-Host "  ✗ Archivo mcp.json no encontrado" -ForegroundColor $ColorError
    Write-Host "    Ubicación esperada: $mcpConfigFile" -ForegroundColor $ColorWarning
    $allChecks = $false
}

# ============================================================================
# Check 4: Steering files
# ============================================================================
Write-Host ""
Write-Host "4️⃣  Verificando steering files..." -ForegroundColor $ColorInfo

$steeringDir = "$HOME\.kiro\steering"

if (Test-Path $steeringDir) {
    $steeringFiles = Get-ChildItem $steeringDir -File
    if ($steeringFiles.Count -gt 0) {
        Write-Host "  ✓ $($steeringFiles.Count) steering files encontrados" -ForegroundColor $ColorSuccess
        foreach ($file in $steeringFiles) {
            Write-Host "    - $($file.Name)" -ForegroundColor $ColorInfo
        }
    } else {
        Write-Host "  ⚠ Directorio de steering files vacío" -ForegroundColor $ColorWarning
    }
} else {
    Write-Host "  ⚠ Directorio de steering files no encontrado" -ForegroundColor $ColorWarning
}

# ============================================================================
# Check 5: Skills
# ============================================================================
Write-Host ""
Write-Host "5️⃣  Verificando skills..." -ForegroundColor $ColorInfo

$skillsDir = "$HOME\.kiro\skills"

if (Test-Path $skillsDir) {
    $skillFiles = Get-ChildItem $skillsDir -File
    if ($skillFiles.Count -gt 0) {
        Write-Host "  ✓ $($skillFiles.Count) skills encontrados" -ForegroundColor $ColorSuccess
        foreach ($file in $skillFiles) {
            Write-Host "    - $($file.Name)" -ForegroundColor $ColorInfo
        }
    } else {
        Write-Host "  ⚠ Directorio de skills vacío" -ForegroundColor $ColorWarning
    }
} else {
    Write-Host "  ⚠ Directorio de skills no encontrado" -ForegroundColor $ColorWarning
}

# ============================================================================
# Check 6: Hooks
# ============================================================================
Write-Host ""
Write-Host "6️⃣  Verificando hooks..." -ForegroundColor $ColorInfo

$hooksDir = "$HOME\.kiro\hooks"

if (Test-Path $hooksDir) {
    $hookFiles = Get-ChildItem $hooksDir -File
    if ($hookFiles.Count -gt 0) {
        Write-Host "  ✓ $($hookFiles.Count) hooks encontrados" -ForegroundColor $ColorSuccess
        foreach ($file in $hookFiles) {
            Write-Host "    - $($file.Name)" -ForegroundColor $ColorInfo
        }
    } else {
        Write-Host "  ⚠ Directorio de hooks vacío" -ForegroundColor $ColorWarning
    }
} else {
    Write-Host "  ⚠ Directorio de hooks no encontrado" -ForegroundColor $ColorWarning
}

# ============================================================================
# Check 7: Variables de entorno
# ============================================================================
Write-Host ""
Write-Host "7️⃣  Verificando variables de entorno..." -ForegroundColor $ColorInfo

if ($env:SAP_PASSWORD) {
    Write-Host "  ✓ SAP_PASSWORD configurado" -ForegroundColor $ColorSuccess
} else {
    Write-Host "  ⚠ SAP_PASSWORD no configurado en la sesión actual" -ForegroundColor $ColorWarning
    Write-Host "    Verifica que esté configurado a nivel de usuario" -ForegroundColor $ColorWarning
}

# ============================================================================
# Check 8: Conectividad de red
# ============================================================================
Write-Host ""
Write-Host "8️⃣  Verificando conectividad de red..." -ForegroundColor $ColorInfo

try {
    $testConnection = Test-NetConnection -ComputerName "fbpl08v010.holcimbp.net" -Port 8000 -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "  ✓ Conexión a SAP BZD exitosa" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "  ✗ No se puede conectar a SAP BZD" -ForegroundColor $ColorError
        Write-Host "    Verifica que estés en la red corporativa o VPN conectada" -ForegroundColor $ColorWarning
        $allChecks = $false
    }
} catch {
    Write-Host "  ⚠ No se pudo verificar conectividad: $_" -ForegroundColor $ColorWarning
}

# ============================================================================
# Check 9: Conexión a SAP (si hay password configurado)
# ============================================================================
if ($env:SAP_PASSWORD) {
    Write-Host ""
    Write-Host "9️⃣  Verificando autenticación con SAP..." -ForegroundColor $ColorInfo
    
    try {
        # Leer usuario del mcp.json
        $mcpConfig = Get-Content "$HOME\.kiro\settings\mcp.json" | ConvertFrom-Json
        $sapUser = $mcpConfig.mcpServers."sap-bzd".env.SAP_USER
        
        $testScript = @"
import requests
from requests.auth import HTTPBasicAuth
import os

host = 'fbpl08v010.holcimbp.net'
port = '8000'
client = '130'
user = '$sapUser'
password = os.environ.get('SAP_PASSWORD', '')

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
        print(f'ERROR:{response.status_code}')
except Exception as e:
    print(f'ERROR:{str(e)}')
"@
        
        $result = $testScript | python
        
        if ($result -eq "SUCCESS") {
            Write-Host "  ✓ Autenticación exitosa con SAP BZD" -ForegroundColor $ColorSuccess
        } else {
            Write-Host "  ✗ Error de autenticación: $result" -ForegroundColor $ColorError
            Write-Host "    Verifica tu usuario y password" -ForegroundColor $ColorWarning
            $allChecks = $false
        }
    } catch {
        Write-Host "  ✗ Error verificando autenticación: $_" -ForegroundColor $ColorError
        $allChecks = $false
    }
}

# ============================================================================
# Resumen final
# ============================================================================
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo

if ($allChecks) {
    Write-Host ""
    Write-Host "✅ ¡Todas las verificaciones pasaron exitosamente!" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "🎉 Tu instalación está lista para usar" -ForegroundColor $ColorSuccess
    Write-Host ""
    Write-Host "📋 Próximos pasos:" -ForegroundColor $ColorInfo
    Write-Host "  1. Abre Kiro (o reinícialo si ya está abierto)" -ForegroundColor $ColorInfo
    Write-Host "  2. Verifica que los MCP servers estén conectados (panel lateral)" -ForegroundColor $ColorInfo
    Write-Host "  3. Prueba con: 'Verifica la conexión con SAP BZD'" -ForegroundColor $ColorInfo
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "⚠️  Algunas verificaciones fallaron" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "🔧 Acciones recomendadas:" -ForegroundColor $ColorInfo
    Write-Host "  1. Revisa los errores marcados con ✗ arriba" -ForegroundColor $ColorInfo
    Write-Host "  2. Ejecuta nuevamente: .\install.ps1 -SAPUser TU_USUARIO" -ForegroundColor $ColorInfo
    Write-Host "  3. Si persisten los errores, consulta ONBOARDING_NUEVO_DESARROLLADOR.md" -ForegroundColor $ColorInfo
    Write-Host ""
}

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
Write-Host ""

# Exit code
if ($allChecks) {
    exit 0
} else {
    exit 1
}
