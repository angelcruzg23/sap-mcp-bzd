# ============================================================================
# Kiro SAP ABAP Power - Gestión de Credenciales
# ============================================================================
# Descripción: Gestiona credenciales de múltiples sistemas SAP de forma segura
# Uso: .\manage-credentials.ps1 [add|update|remove|list|test]
# ============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("add", "update", "remove", "list", "test", "")]
    [string]$Action = "",
    
    [Parameter(Mandatory=$false)]
    [string]$System = ""
)

$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorPrompt = "Magenta"

# ============================================================================
# Función: Mostrar menú principal
# ============================================================================
function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $ColorInfo
    Write-Host "║                                                                ║" -ForegroundColor $ColorInfo
    Write-Host "║          Gestión de Credenciales SAP - Kiro Power             ║" -ForegroundColor $ColorInfo
    Write-Host "║                                                                ║" -ForegroundColor $ColorInfo
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "  [1] Agregar credenciales para un sistema" -ForegroundColor $ColorSuccess
    Write-Host "  [2] Actualizar credenciales existentes" -ForegroundColor $ColorSuccess
    Write-Host "  [3] Eliminar credenciales" -ForegroundColor $ColorSuccess
    Write-Host "  [4] Listar sistemas configurados" -ForegroundColor $ColorSuccess
    Write-Host "  [5] Probar conexión a un sistema" -ForegroundColor $ColorSuccess
    Write-Host "  [6] Salir" -ForegroundColor $ColorSuccess
    Write-Host ""
    
    $choice = Read-Host "  Selecciona una opción"
    
    switch ($choice) {
        "1" { Add-Credentials }
        "2" { Update-Credentials }
        "3" { Remove-Credentials }
        "4" { List-Systems }
        "5" { Test-Connection }
        "6" { exit 0 }
        default { 
            Write-Host "  Opción inválida" -ForegroundColor $ColorError
            Start-Sleep -Seconds 2
            Show-Menu
        }
    }
}

# ============================================================================
# Función: Leer configuración de usuario
# ============================================================================
function Get-UserConfig {
    if (Test-Path "user-config.json") {
        try {
            return Get-Content "user-config.json" | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

# ============================================================================
# Función: Guardar configuración de usuario
# ============================================================================
function Save-UserConfig {
    param([object]$Config)
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File "user-config.json" -Encoding UTF8
        return $true
    } catch {
        Write-Host "  ✗ Error guardando configuración: $_" -ForegroundColor $ColorError
        return $false
    }
}

# ============================================================================
# Función: Leer sistemas disponibles
# ============================================================================
function Get-AvailableSystems {
    if (Test-Path "config-systems.json") {
        try {
            $config = Get-Content "config-systems.json" | ConvertFrom-Json
            return $config.systems
        } catch {
            return $null
        }
    }
    return $null
}

# ============================================================================
# Función: Agregar credenciales
# ============================================================================
function Add-Credentials {
    Clear-Host
    Write-Host ""
    Write-Host "➕ Agregar credenciales para un sistema SAP" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $availableSystems = Get-AvailableSystems
    if ($null -eq $availableSystems) {
        Write-Host "  ✗ No se pudo cargar la configuración de sistemas" -ForegroundColor $ColorError
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    # Mostrar sistemas disponibles
    Write-Host "  Sistemas disponibles:" -ForegroundColor $ColorInfo
    $index = 1
    $systemList = @()
    foreach ($key in $availableSystems.PSObject.Properties.Name) {
        Write-Host "    [$index] $key - $($availableSystems.$key.name)" -ForegroundColor $ColorSuccess
        $systemList += $key
        $index++
    }
    Write-Host ""
    
    $choice = Read-Host "  Selecciona un sistema (número)"
    $systemKey = $systemList[[int]$choice - 1]
    
    if ($null -eq $systemKey) {
        Write-Host "  ✗ Selección inválida" -ForegroundColor $ColorError
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    # Solicitar credenciales
    Write-Host ""
    $username = Read-Host "  Usuario SAP para $systemKey"
    Write-Host "  Password SAP (se guardará de forma segura)" -ForegroundColor $ColorWarning
    $securePassword = Read-Host "  Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    # Guardar en variables de entorno
    $envVar = "SAP_PASSWORD_$systemKey"
    [System.Environment]::SetEnvironmentVariable($envVar, $password, 'User')
    Set-Item -Path "env:$envVar" -Value $password
    
    # Actualizar user-config.json
    $userConfig = Get-UserConfig
    if ($null -eq $userConfig) {
        $userConfig = @{
            user = @{}
            systems = @{}
            preferences = @{}
        }
    }
    
    if ($null -eq $userConfig.systems) {
        $userConfig.systems = @{}
    }
    
    $userConfig.systems | Add-Member -NotePropertyName $systemKey -NotePropertyValue @{
        enabled = $true
        username = $username
        password_env_var = $envVar
        default = $false
    } -Force
    
    if (Save-UserConfig -Config $userConfig) {
        Write-Host ""
        Write-Host "  ✓ Credenciales guardadas para $systemKey" -ForegroundColor $ColorSuccess
        Write-Host "  ✓ Variable de entorno $envVar configurada" -ForegroundColor $ColorSuccess
    }
    
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
    Show-Menu
}

# ============================================================================
# Función: Actualizar credenciales
# ============================================================================
function Update-Credentials {
    Clear-Host
    Write-Host ""
    Write-Host "🔄 Actualizar credenciales existentes" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $userConfig = Get-UserConfig
    if ($null -eq $userConfig -or $null -eq $userConfig.systems) {
        Write-Host "  ⚠ No hay sistemas configurados" -ForegroundColor $ColorWarning
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    # Mostrar sistemas configurados
    Write-Host "  Sistemas configurados:" -ForegroundColor $ColorInfo
    $index = 1
    $systemList = @()
    foreach ($key in $userConfig.systems.PSObject.Properties.Name) {
        $system = $userConfig.systems.$key
        Write-Host "    [$index] $key ($($system.username))" -ForegroundColor $ColorSuccess
        $systemList += $key
        $index++
    }
    Write-Host ""
    
    $choice = Read-Host "  Selecciona un sistema (número)"
    $systemKey = $systemList[[int]$choice - 1]
    
    if ($null -eq $systemKey) {
        Write-Host "  ✗ Selección inválida" -ForegroundColor $ColorError
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    # Solicitar nuevas credenciales
    Write-Host ""
    Write-Host "  Sistema: $systemKey" -ForegroundColor $ColorInfo
    Write-Host "  Usuario actual: $($userConfig.systems.$systemKey.username)" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $updateUser = Read-Host "  ¿Actualizar usuario? (S/N)"
    if ($updateUser -eq "S" -or $updateUser -eq "s") {
        $username = Read-Host "  Nuevo usuario SAP"
        $userConfig.systems.$systemKey.username = $username
    }
    
    $updatePassword = Read-Host "  ¿Actualizar password? (S/N)"
    if ($updatePassword -eq "S" -or $updatePassword -eq "s") {
        Write-Host "  Nuevo password SAP (se guardará de forma segura)" -ForegroundColor $ColorWarning
        $securePassword = Read-Host "  Password" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        # Actualizar variable de entorno
        $envVar = $userConfig.systems.$systemKey.password_env_var
        [System.Environment]::SetEnvironmentVariable($envVar, $password, 'User')
        Set-Item -Path "env:$envVar" -Value $password
    }
    
    if (Save-UserConfig -Config $userConfig) {
        Write-Host ""
        Write-Host "  ✓ Credenciales actualizadas para $systemKey" -ForegroundColor $ColorSuccess
    }
    
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
    Show-Menu
}

# ============================================================================
# Función: Eliminar credenciales
# ============================================================================
function Remove-Credentials {
    Clear-Host
    Write-Host ""
    Write-Host "🗑️  Eliminar credenciales" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $userConfig = Get-UserConfig
    if ($null -eq $userConfig -or $null -eq $userConfig.systems) {
        Write-Host "  ⚠ No hay sistemas configurados" -ForegroundColor $ColorWarning
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    # Mostrar sistemas configurados
    Write-Host "  Sistemas configurados:" -ForegroundColor $ColorInfo
    $index = 1
    $systemList = @()
    foreach ($key in $userConfig.systems.PSObject.Properties.Name) {
        $system = $userConfig.systems.$key
        Write-Host "    [$index] $key ($($system.username))" -ForegroundColor $ColorSuccess
        $systemList += $key
        $index++
    }
    Write-Host ""
    
    $choice = Read-Host "  Selecciona un sistema (número)"
    $systemKey = $systemList[[int]$choice - 1]
    
    if ($null -eq $systemKey) {
        Write-Host "  ✗ Selección inválida" -ForegroundColor $ColorError
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    # Confirmar eliminación
    Write-Host ""
    Write-Host "  ⚠ Esto eliminará las credenciales de $systemKey" -ForegroundColor $ColorWarning
    $confirm = Read-Host "  ¿Estás seguro? (S/N)"
    
    if ($confirm -eq "S" -or $confirm -eq "s") {
        # Eliminar variable de entorno
        $envVar = $userConfig.systems.$systemKey.password_env_var
        [System.Environment]::SetEnvironmentVariable($envVar, $null, 'User')
        Remove-Item -Path "env:$envVar" -ErrorAction SilentlyContinue
        
        # Eliminar de configuración
        $userConfig.systems.PSObject.Properties.Remove($systemKey)
        
        if (Save-UserConfig -Config $userConfig) {
            Write-Host ""
            Write-Host "  ✓ Credenciales eliminadas para $systemKey" -ForegroundColor $ColorSuccess
        }
    }
    
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
    Show-Menu
}

# ============================================================================
# Función: Listar sistemas
# ============================================================================
function List-Systems {
    Clear-Host
    Write-Host ""
    Write-Host "📋 Sistemas configurados" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $userConfig = Get-UserConfig
    if ($null -eq $userConfig -or $null -eq $userConfig.systems) {
        Write-Host "  ⚠ No hay sistemas configurados" -ForegroundColor $ColorWarning
        Write-Host ""
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    $availableSystems = Get-AvailableSystems
    
    foreach ($key in $userConfig.systems.PSObject.Properties.Name) {
        $system = $userConfig.systems.$key
        $systemInfo = $availableSystems.$key
        
        $statusIcon = if ($system.enabled) { "✓" } else { "✗" }
        $defaultMark = if ($system.default) { " (por defecto)" } else { "" }
        
        Write-Host "  $statusIcon $key$defaultMark" -ForegroundColor $ColorSuccess
        Write-Host "      Usuario: $($system.username)" -ForegroundColor $ColorInfo
        Write-Host "      Host: $($systemInfo.host):$($systemInfo.port)" -ForegroundColor $ColorInfo
        Write-Host "      Cliente: $($systemInfo.client)" -ForegroundColor $ColorInfo
        Write-Host "      Equipo: $($systemInfo.team)" -ForegroundColor $ColorInfo
        Write-Host "      Variable de entorno: $($system.password_env_var)" -ForegroundColor $ColorInfo
        Write-Host ""
    }
    
    Read-Host "Presiona Enter para continuar"
    Show-Menu
}

# ============================================================================
# Función: Probar conexión
# ============================================================================
function Test-Connection {
    Clear-Host
    Write-Host ""
    Write-Host "🔌 Probar conexión a sistema SAP" -ForegroundColor $ColorInfo
    Write-Host ""
    
    $userConfig = Get-UserConfig
    if ($null -eq $userConfig -or $null -eq $userConfig.systems) {
        Write-Host "  ⚠ No hay sistemas configurados" -ForegroundColor $ColorWarning
        Read-Host "Presiona Enter para continuar"
        Show-Menu
        return
    }
    
    # Mostrar sistemas configurados
    Write-Host "  Sistemas configurados:" -ForegroundColor $ColorInfo
    $index = 1
    $systemList = @()
    foreach ($key in $userConfig.systems.PSObject.Properties.Name) {
        Write-Host "    [$index] $key" -ForegroundColor $ColorSuccess
        $systemList += $key
        $index++
    }
    Write-Host "    [0] Probar todos" -ForegroundColor $ColorSuccess
    Write-Host ""
    
    $choice = Read-Host "  Selecciona un sistema (número)"
    
    if ($choice -eq "0") {
        # Probar todos
        Write-Host ""
        foreach ($key in $systemList) {
            Test-SingleSystem -SystemKey $key -UserConfig $userConfig
        }
    } else {
        $systemKey = $systemList[[int]$choice - 1]
        if ($null -ne $systemKey) {
            Write-Host ""
            Test-SingleSystem -SystemKey $systemKey -UserConfig $userConfig
        }
    }
    
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
    Show-Menu
}

# ============================================================================
# Función: Probar un sistema individual
# ============================================================================
function Test-SingleSystem {
    param(
        [string]$SystemKey,
        [object]$UserConfig
    )
    
    $availableSystems = Get-AvailableSystems
    $systemInfo = $availableSystems.$SystemKey
    $userSystem = $UserConfig.systems.$SystemKey
    
    Write-Host "  Probando $SystemKey..." -ForegroundColor $ColorInfo
    
    # Obtener password de variable de entorno
    $password = [System.Environment]::GetEnvironmentVariable($userSystem.password_env_var, 'User')
    if (-not $password) {
        $password = [System.Environment]::GetEnvironmentVariable($userSystem.password_env_var, 'Process')
    }
    
    if (-not $password) {
        Write-Host "    ✗ Password no encontrado en variable de entorno" -ForegroundColor $ColorError
        return
    }
    
    $testScript = @"
import requests
from requests.auth import HTTPBasicAuth
import sys

host = '$($systemInfo.host)'
port = '$($systemInfo.port)'
client = '$($systemInfo.client)'
user = '$($userSystem.username)'
password = '$password'

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
        }
    } catch {
        Write-Host "    ✗ Error: $_" -ForegroundColor $ColorError
    }
}

# ============================================================================
# MAIN
# ============================================================================

if ($Action -eq "") {
    Show-Menu
} else {
    switch ($Action) {
        "add" { Add-Credentials }
        "update" { Update-Credentials }
        "remove" { Remove-Credentials }
        "list" { List-Systems }
        "test" { Test-Connection }
    }
}
