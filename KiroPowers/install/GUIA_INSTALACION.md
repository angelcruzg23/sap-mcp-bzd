# Guía de Instalación — Kiro Power SAP ABAP Amrize BP

## Requisitos previos

- Python 3.10 o superior (`python --version`)
- Kiro IDE instalado
- Acceso a la red corporativa o VPN conectada
- Usuario SAP activo en BZD (cliente 130)

---

## Instalación rápida (5 minutos)

```powershell
# 1. Navega a la carpeta del proyecto
cd C:\Users\TU_USUARIO\sap-mcp-bzd

# 2. Ejecuta el instalador del Power
.\KiroPowers\install\install.ps1 -SAPUser "TU_USUARIO_SAP"

# Ejemplo:
.\KiroPowers\install\install.ps1 -SAPUser "ANGECRUZ"
```

El instalador te pedirá el password de SAP y configurará todo automáticamente.

**3. Reinicia Kiro** (File → Exit y vuelve a abrir)

**4. Verifica en el chat:**
```
Verifica la conexion con SAP BZD
```

---

## ¿Qué instala este Power?

| Componente | Destino | Descripción |
|-----------|---------|-------------|
| MCP server config | `~/.kiro/settings/mcp.json` | Conexión a BZD y BZN |
| 8 steering files | `~/.kiro/steering/` | Guías de dominio ABAP |
| 5 skills | `~/.kiro/skills/` | Capacidades activables con # |
| 3 hooks | `.kiro/hooks/` | Automatizaciones del workspace |

---

## Instalación con BZN (sandbox)

```powershell
.\KiroPowers\install\install.ps1 -SAPUser "TU_USUARIO" -SAPUserBZN "AHERNA11"
```

El instalador te pedirá el password de BZN también. Si lo dejas vacío, solo configura BZD.

---

## Instalación manual (si el script falla)

### 1. Instalar dependencias Python
```powershell
pip install "mcp>=1.0.0" "requests>=2.31.0"
```

### 2. Copiar mcp.json
Copia `KiroPowers/mcp.json` a `~/.kiro/settings/mcp.json` y reemplaza las variables:
- `${SAP_MCP_SERVER_PATH}` → ruta completa a `server.py` (ej: `C:\Users\angecruz\sap-mcp-bzd\server.py`)
- `${SAP_USER_BZD}` → tu usuario SAP en BZD
- `${SAP_PASSWORD_BZD}` → tu password SAP en BZD

### 3. Copiar steering files
```powershell
Copy-Item KiroPowers\steering\* -Destination "$env:USERPROFILE\.kiro\steering\" -Force
```

### 4. Copiar skills
```powershell
Copy-Item KiroPowers\skills\* -Destination "$env:USERPROFILE\.kiro\skills\" -Force
```

### 5. Copiar hooks
```powershell
# Renombrar .json a .kiro.hook al copiar
Get-ChildItem KiroPowers\hooks\*.json | ForEach-Object {
    Copy-Item $_.FullName ".kiro\hooks\$($_.BaseName).kiro.hook" -Force
}
```

---

## Solución de problemas

### "python no se reconoce como comando"
Cierra y abre PowerShell. Si persiste, reinstala Python marcando "Add Python to PATH".

### "No puedo ejecutar scripts de PowerShell"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "No puedo conectarme a SAP"
1. ¿Estás en la red corporativa o VPN conectada?
2. Prueba: `Test-NetConnection fbpl08v010.holcimbp.net -Port 8000`
3. Verifica que tu usuario SAP esté activo en SAP GUI

### Los MCP servers no aparecen en Kiro
1. Verifica que `~/.kiro/settings/mcp.json` existe y tiene el formato correcto
2. Reinicia Kiro completamente
3. Revisa el panel MCP en el sidebar de Kiro

---

## Skills disponibles después de instalar

Actívalos escribiendo `#nombre` en el chat de Kiro:

| Skill | Uso |
|-------|-----|
| `#sap-mcp-capabilities` | Ver qué puede/no puede hacer el MCP |
| `#sap-incident-workflow` | Analizar bugs de producción |
| `#sap-integration-patterns` | Patrones SD↔Salesforce, CRM↔ECC |
| `#abap-lessons-learned` | Lecciones aprendidas en producción |
| `#version-inventory` | Inventario de objetos y versiones |

---

**Versión:** 1.0.0  
**Autor:** Angel Cruz — angecruz@amrize.com  
**Última actualización:** 2026-05-06
