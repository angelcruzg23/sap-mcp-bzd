# ============================================================================
# Kiro SAP ABAP Power - Setup Wizard (Asistente de Configuración)
# ============================================================================
# Descripción: Asistente interactivo para configurar múltiples sistemas SAP
# Uso: .\setup-wizard.ps1
# ============================================================================

$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorPrompt = "Magenta"

# ============================================================================
# Banner
# ============================================================================
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $ColorInfo
    Write-Host "║                                                                ║" -ForegroundColor $ColorInfo
    Write-Host "║       Kiro SAP ABAP Power - Asistente de Configuración        ║" -ForegroundColor $ColorInfo
    Write-Host "║                    Amrize BP - 2026                            ║" -ForegroundColor $ColorInfo
    Write-Host "║                                                                ║" -ForegroundColor $ColorInfo
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor $ColorInfo
    Write-Host ""
}

# ============================================================================
# Función: Leer configuración de sistemas disponibles
# ============================================================================
function Get-AvailableSystems {
    if (Test-Path "config-systems.json") {
        try {
            $config = Get-Content "config-systems.json" | ConvertFrom-Json
            return $config.systems
        } catch {
            Write-Host "⚠ Error leyendo config-systems.json: $_" -ForegroundColor $ColorWarning
            return $null
        }
    } else {
        Write-Host "⚠ Archivo config-systems.json no encontrado" -ForegroundColor $ColorWarning
        return $null
    }
}

# ============================================================================
# Función: Mostrar sistemas disponibles
# ============================================================================
function Show-AvailableSystems {
    param($Systems)
    
    Write-Host "📋 Sistemas SAP disponibles:" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $index = 1
    $systemList = @()
    
    foreach ($systemKey in $Systems.PSObject.Properties.Name) {
        $system = $Systems.$systemKey
        Write-Host "  [$index] $systemKey - $($system.name)" -ForegroundColor $ColorSuccess
        Write-Host "      Equipo: $($system.team)" -ForegroundColor $ColorInfo
        Write-Host "      Host: $($system.host):$($system.port)" -ForegroundColor $ColorInfo
        Write-Host "      Cliente: $($system.client)" -ForegroundColor $ColorInfo
        Write-Host ""
        
        $systemList += @{
            Index = $index
            Key = $systemKey
            System = $system
        }
        $index++
    }
    
    return $systemList
}

# ============================================================================
# Función: Solicitar información del usuario
# ============================================================================
function Get-UserInfo {
    Write-Host "👤 Información del usuario" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $name = Read-Host "  Nombre completo (ej: Juan Perez)"
    $email = Read-Host "  Email corporativo (ej: juan.perez@amrize.com)"
    
    Write-Host ""
    Write-Host "  Selecciona tu equipo:" -ForegroundColor $ColorInfo
    Write-Host "    [1] Business Envelope" -ForegroundColor $ColorSuccess
    Write-Host "    [2] Building Materials" -ForegroundColor $ColorSuccess
    Write-Host "    [3] D2I" -ForegroundColor $ColorSuccess
    Write-Host "    [4] Otro" -ForegroundColor $ColorSuccess
    Write-Host ""
    
    $teamChoice = Read-Host "  Opción"
    
    $team = switch ($teamChoice) {
        "1" { "Business Envelope" }
        "2" { "Building Materials" }
        "3" { "D2I" }
        "4" { Read-Host "  Nombre del equipo" }
        default { "Business Envelope" }
    }
    
    return @{
        Name = $name
        Email = $email
        Team = $team
    }
}

# ============================================================================
# Función: Configurar un sistema SAP
# ============================================================================
function Configure-SAPSystem {
    param(
        [string]$SystemKey,
        [object]$SystemInfo,
        [bool]$IsFirst
    )
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host "  Configurando: $SystemKey - $($SystemInfo.name)" -ForegroundColor $ColorPrompt
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
    
    # Preguntar si quiere configurar este sistema
    if (-not $IsFirst) {
        $configure = Read-Host "  ¿Deseas configurar este sistema? (S/N)"
        if ($configure -ne "S" -and $configure -ne "s") {
            return $null
        }
    }
    
    # Solicitar usuario
    $username = Read-Host "  Usuario SAP para $SystemKey"
    
    # Solicitar password
    Write-Host "  Password SAP para $SystemKey (se guardará de forma segura)" -ForegroundColor $ColorWarning
    $securePassword = Read-Host "  Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    # Preguntar si es el sistema por defecto
    $isDefault = $false
    if ($IsFirst) {
        $isDefault = $true
        Write-Host "  ✓ Este será tu sistema por defecto" -ForegroundColor $ColorSuccess
    } else {
        $defaultChoice = Read-Host "  ¿Usar como sistema por defecto? (S/N)"
        $isDefault = ($defaultChoice -eq "S" -or $defaultChoice -eq "s")
    }
    
    return @{
        Username = $username
        Password = $password
        PasswordEnvVar = "SAP_PASSWORD_$SystemKey"
        Enabled = $true
        IsDefault = $isDefault
    }
}

# ============================================================================
# Función: Guardar configuración de usuario
# ============================================================================
function Save-UserConfig {
    param(
        [object]$UserInfo,
        [hashtable]$SystemsConfig,
        [object]$Preferences
    )
    
    $userConfig = @{
        user = @{
            name = $UserInfo.Name
            email = $UserInfo.Email
            team = $UserInfo.Team
        }
        systems = @{}
        preferences = $Preferences
    }
    
    foreach ($key in $SystemsConfig.Keys) {
        $config = $SystemsConfig[$key]
        $userConfig.systems[$key] = @{
            enabled = $config.Enabled
            username = $config.Username
            password_env_var = $config.PasswordEnvVar
            default = $config.IsDefault
        }
    }
    
    try {
        $userConfig | ConvertTo-Json -Depth 10 | Out-File "user-config.json" -Encoding UTF8
        Write-Host "  ✓ Configuración guardada en user-config.json" -ForegroundColor $ColorSuccess
        return $true
    } catch {
        Write-Host "  ✗ Error guardando configuración: $_" -ForegroundColor $ColorError
        return $false
    }
}

# ============================================================================
# Función: Configurar variables de entorno
# ============================================================================
function Set-EnvironmentVariables {
    param([hashtable]$SystemsConfig)
    
    Write-Host ""
    Write-Host "🔐 Configurando variables de entorno..." -ForegroundColor $ColorInfo
    
    foreach ($key in $SystemsConfig.Keys) {
        $config = $SystemsConfig[$key]
        if ($config.Enabled) {
            try {
                # Configurar a nivel de usuario (permanente)
                [System.Environment]::SetEnvironmentVariable($config.PasswordEnvVar, $config.Password, 'User')
                
                # También configurar para la sesión actual
                Set-Item -Path "env:$($config.PasswordEnvVar)" -Value $config.Password
                
                Write-Host "  ✓ $($config.PasswordEnvVar) configurado" -ForegroundColor $ColorSuccess
            } catch {
                Write-Host "  ✗ Error configurando $($config.PasswordEnvVar): $_" -ForegroundColor $ColorError
            }
        }
    }
}

# ============================================================================
# Función: Generar configuración de MCP
# ============================================================================
function Generate-MCPConfig {
    param(
        [object]$AvailableSystems,
        [hashtable]$SystemsConfig
    )
    
    Write-Host ""
    Write-Host "⚙️  Generando configuración de MCP..." -ForegroundColor $ColorInfo
    
    $projectPath = (Get-Location).Path
    $mcpConfig = @{
        mcpServers = @{}
    }
    
    foreach ($key in $SystemsConfig.Keys) {
        $userConfig = $SystemsConfig[$key]
        if ($userConfig.Enabled) {
            $systemInfo = $AvailableSystems.$key
            
            $serverKey = "sap-$($key.ToLower())"
            $mcpConfig.mcpServers[$serverKey] = @{
                command = "python"
                args = @("$projectPath\server.py")
                env = @{
                    SAP_HOST = "$($systemInfo.host):$($systemInfo.port)"
                    SAP_CLIENT = $systemInfo.client
                    SAP_USER = $userConfig.Username
                    SAP_SECURE = "false"
                    SAP_SYSTEM_ID = $key
                }
                disabled = $false
                autoApprove = @()
                timeout = 60000
            }
        }
    }
    
    # Guardar configuración
    $mcpConfigPath = "$HOME\.kiro\settings"
    $mcpConfigFile = "$mcpConfigPath\mcp.json"
    
    if (-not (Test-Path $mcpConfigPath)) {
        New-Item -ItemType Directory -Path $mcpConfigPath -Force | Out-Null
    }
    
    try {
        $mcpConfig | ConvertTo-Json -Depth 10 | Out-File $mcpConfigFile -Encoding UTF8
        Write-Host "  ✓ Configuración MCP guardada en $mcpConfigFile" -ForegroundColor $ColorSuccess
        
        # Mostrar resumen
        Write-Host ""
        Write-Host "  Sistemas configurados:" -ForegroundColor $ColorInfo
        foreach ($key in $mcpConfig.mcpServers.Keys) {
            Write-Host "    - $key" -ForegroundColor $ColorSuccess
        }
        
        return $true
    } catch {
        Write-Host "  ✗ Error guardando configuración MCP: $_" -ForegroundColor $ColorError
        return $false
    }
}

# ============================================================================
# Función: Verificar conexión a sistemas
# ============================================================================
function Test-SystemConnections {
    param(
        [object]$AvailableSystems,
        [hashtable]$SystemsConfig
    )
    
    Write-Host ""
    Write-Host "🔌 Verificando conexiones a sistemas SAP..." -ForegroundColor $ColorInfo
    Write-Host ""
    
    $allSuccess = $true
    
    foreach ($key in $SystemsConfig.Keys) {
        $userConfig = $SystemsConfig[$key]
        if ($userConfig.Enabled) {
            $systemInfo = $AvailableSystems.$key
            
            Write-Host "  Probando $key..." -ForegroundColor $ColorInfo
            
            $testScript = @"
import requests
from requests.auth import HTTPBasicAuth
import sys

host = '$($systemInfo.host)'
port = '$($systemInfo.port)'
client = '$($systemInfo.client)'
user = '$($userConfig.Username)'
password = '$($userConfig.Password)'

try:
    response = requests.get(
        f'http://{host}:{port}/sap/bc/adt/discovery',
        auth=HTTPBasicAuth(user, password),
        headers={'sap-client': client},
        timeout=10
    )
    if response.status_code == 200:
        print('SUCCESS')
        sys.exit(0)
    else:
        print(f'ERROR:{response.status_code}')
        sys.exit(1)
except Exception as e:
    print(f'ERROR:{str(e)}')
    sys.exit(1)
"@
            
            try {
                $result = $testScript | python
                
                if ($result -eq "SUCCESS") {
                    Write-Host "    ✓ Conexión exitosa" -ForegroundColor $ColorSuccess
                } else {
                    Write-Host "    ✗ Error: $result" -ForegroundColor $ColorError
                    $allSuccess = $false
                }
            } catch {
                Write-Host "    ✗ Error: $_" -ForegroundColor $ColorError
                $allSuccess = $false
            }
        }
    }
    
    return $allSuccess
}

# ============================================================================
# Función: Copiar archivos del framework
# ============================================================================
function Copy-FrameworkFiles {
    Write-Host ""
    Write-Host "📦 Copiando archivos del framework..." -ForegroundColor $ColorInfo
    
    $success = $true
    
    # Steering files
    if (Test-Path ".\.kiro\steering") {
        $targetDir = "$HOME\.kiro\steering"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -Path ".\.kiro\steering\*" -Destination $targetDir -Force -Recurse
        Write-Host "  ✓ Steering files copiados" -ForegroundColor $ColorSuccess
    }
    
    # Skills
    if (Test-Path ".\.kiro\skills") {
        $targetDir = "$HOME\.kiro\skills"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -Path ".\.kiro\skills\*" -Destination $targetDir -Force -Recurse
        Write-Host "  ✓ Skills copiados" -ForegroundColor $ColorSuccess
    }
    
    # Hooks
    if (Test-Path ".\.kiro\hooks") {
        $targetDir = "$HOME\.kiro\hooks"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -Path ".\.kiro\hooks\*" -Destination $targetDir -Force -Recurse
        Write-Host "  ✓ Hooks copiados" -ForegroundColor $ColorSuccess
    }
    
    # Templates
    if (Test-Path ".\templates") {
        $targetDir = "$HOME\.kiro\templates\abap"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -Path ".\templates\*" -Destination $targetDir -Force -Recurse
        Write-Host "  ✓ Templates copiados" -ForegroundColor $ColorSuccess
    }
    
    return $success
}

# ============================================================================
# Función: Mostrar resumen final
# ============================================================================
function Show-FinalSummary {
    param(
        [object]$UserInfo,
        [hashtable]$SystemsConfig,
        [bool]$AllTestsPassed
    )
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
    
    if ($AllTestsPassed) {
        Write-Host "✅ ¡Configuración completada exitosamente!" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "⚠️  Configuración completada con advertencias" -ForegroundColor $ColorWarning
    }
    
    Write-Host ""
    Write-Host "📋 Resumen de configuración:" -ForegroundColor $ColorInfo
    Write-Host "  • Usuario: $($UserInfo.Name)" -ForegroundColor $ColorInfo
    Write-Host "  • Email: $($UserInfo.Email)" -ForegroundColor $ColorInfo
    Write-Host "  • Equipo: $($UserInfo.Team)" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "  Sistemas configurados:" -ForegroundColor $ColorInfo
    
    foreach ($key in $SystemsConfig.Keys) {
        $config = $SystemsConfig[$key]
        if ($config.Enabled) {
            $defaultMark = if ($config.IsDefault) { " (por defecto)" } else { "" }
            Write-Host "    - $key ($($config.Username))$defaultMark" -ForegroundColor $ColorSuccess
        }
    }
    
    Write-Host ""
    Write-Host "🎯 Próximos pasos:" -ForegroundColor $ColorInfo
    Write-Host "  1. Reinicia Kiro para aplicar los cambios" -ForegroundColor $ColorWarning
    Write-Host "  2. Verifica que los MCP servers estén conectados (panel lateral)" -ForegroundColor $ColorWarning
    Write-Host "  3. Prueba con: 'Verifica la conexión con SAP [SISTEMA]'" -ForegroundColor $ColorWarning
    Write-Host ""
    Write-Host "📚 Recursos disponibles:" -ForegroundColor $ColorInfo
    Write-Host "  • Skills: #sap-mcp-capabilities, #solid-refactoring, #transport-management" -ForegroundColor $ColorInfo
    Write-Host "  • Documentación: QUICK_START.md, ONBOARDING_NUEVO_DESARROLLADOR.md" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "💡 Para reconfigurar, ejecuta nuevamente: .\setup-wizard.ps1" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor $ColorInfo
    Write-Host ""
}

# ============================================================================
# MAIN: Ejecutar asistente
# ============================================================================

Show-Banner

# Verificar prerequisitos
Write-Host "🔍 Verificando prerequisitos..." -ForegroundColor $ColorInfo
Write-Host ""

try {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✓ Python: $pythonVersion" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "  ✗ Python no encontrado. Instala Python 3.8+ desde python.org" -ForegroundColor $ColorError
    exit 1
}

Write-Host ""
Read-Host "Presiona Enter para continuar"

# Paso 1: Información del usuario
Show-Banner
$userInfo = Get-UserInfo

# Paso 2: Mostrar sistemas disponibles
Show-Banner
$availableSystems = Get-AvailableSystems

if ($null -eq $availableSystems) {
    Write-Host "❌ No se pudo cargar la configuración de sistemas" -ForegroundColor $ColorError
    exit 1
}

$systemList = Show-AvailableSystems -Systems $availableSystems

Write-Host ""
Read-Host "Presiona Enter para continuar"

# Paso 3: Configurar sistemas
Show-Banner
Write-Host "🔧 Configuración de sistemas SAP" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "A continuación, configurarás los sistemas SAP que utilizas." -ForegroundColor $ColorInfo
Write-Host "Puedes configurar uno o varios sistemas." -ForegroundColor $ColorInfo
Write-Host ""
Read-Host "Presiona Enter para continuar"

$systemsConfig = @{}
$isFirst = $true

foreach ($item in $systemList) {
    Show-Banner
    $config = Configure-SAPSystem -SystemKey $item.Key -SystemInfo $item.System -IsFirst $isFirst
    
    if ($null -ne $config) {
        $systemsConfig[$item.Key] = $config
        $isFirst = $false
    }
}

if ($systemsConfig.Count -eq 0) {
    Write-Host ""
    Write-Host "❌ No se configuró ningún sistema. Abortando." -ForegroundColor $ColorError
    exit 1
}

# Paso 4: Preferencias
Show-Banner
Write-Host "⚙️  Preferencias" -ForegroundColor $ColorInfo
Write-Host ""

$autoActivate = Read-Host "  ¿Activar objetos automáticamente después de subirlos? (S/N)"
$syntaxCheck = Read-Host "  ¿Ejecutar syntax check después de subir código? (S/N)"
$autoFormat = Read-Host "  ¿Formatear código automáticamente al guardar? (S/N)"

$preferences = @{
    auto_activate = ($autoActivate -eq "S" -or $autoActivate -eq "s")
    run_syntax_check_after_upload = ($syntaxCheck -eq "S" -or $syntaxCheck -eq "s")
    auto_format_on_save = ($autoFormat -eq "S" -or $autoFormat -eq "s")
}

# Paso 5: Guardar configuración
Show-Banner
Write-Host "💾 Guardando configuración..." -ForegroundColor $ColorInfo

if (-not (Save-UserConfig -UserInfo $userInfo -SystemsConfig $systemsConfig -Preferences $preferences)) {
    Write-Host "❌ Error guardando configuración de usuario" -ForegroundColor $ColorError
    exit 1
}

# Paso 6: Configurar variables de entorno
Set-EnvironmentVariables -SystemsConfig $systemsConfig

# Paso 7: Generar configuración de MCP
if (-not (Generate-MCPConfig -AvailableSystems $availableSystems -SystemsConfig $systemsConfig)) {
    Write-Host "❌ Error generando configuración de MCP" -ForegroundColor $ColorError
    exit 1
}

# Paso 8: Instalar dependencias Python
Write-Host ""
Write-Host "📦 Instalando dependencias Python..." -ForegroundColor $ColorInfo
try {
    pip install -r requirements.txt --quiet
    Write-Host "  ✓ Dependencias instaladas" -ForegroundColor $ColorSuccess
} catch {
    Write-Host "  ⚠ Error instalando dependencias: $_" -ForegroundColor $ColorWarning
}

# Paso 9: Copiar archivos del framework
Copy-FrameworkFiles

# Paso 10: Verificar conexiones
$allTestsPassed = Test-SystemConnections -AvailableSystems $availableSystems -SystemsConfig $systemsConfig

# Mostrar resumen final
Show-FinalSummary -UserInfo $userInfo -SystemsConfig $systemsConfig -AllTestsPassed $allTestsPassed

# Exit code
if ($allTestsPassed) {
    exit 0
} else {
    exit 1
}
