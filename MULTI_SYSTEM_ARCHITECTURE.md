# 🏗️ Arquitectura Multi-Sistema - Kiro SAP ABAP Power

## Problema que Resuelve

En Amrize BP, diferentes equipos trabajan con diferentes sistemas SAP:
- **Business Envelope** → BZD
- **Building Materials** → DEV
- **D2I** → BZX
- **Todos** → BZN (Sandbox)

Cada desarrollador puede necesitar acceso a uno o varios sistemas, con credenciales diferentes para cada uno.

---

## Solución: Configuración Multi-Sistema

### 1. **Archivo Central de Sistemas** (`config-systems.json`)

Define todos los sistemas SAP disponibles en la organización:

```json
{
  "systems": {
    "BZD": {
      "name": "BZD - Business Envelope (Development)",
      "host": "fbpl08v010.holcimbp.net",
      "port": "8000",
      "client": "130",
      "team": "Business Envelope",
      "cts_project_management": true
    },
    "DEV": {
      "name": "DEV - Building Materials (Development)",
      "host": "servidor-dev-building.holcimbp.net",
      "port": "8000",
      "client": "100",
      "team": "Building Materials"
    }
  }
}
```

**Características:**
- ✅ Mantenido por el equipo SAP
- ✅ Versionado en Git
- ✅ Un solo lugar para actualizar configuraciones
- ✅ Fácil agregar nuevos sistemas

### 2. **Configuración Personal** (`user-config.json`)

Cada desarrollador tiene su propia configuración:

```json
{
  "user": {
    "name": "Juan Perez",
    "email": "juan.perez@amrize.com",
    "team": "Business Envelope"
  },
  "systems": {
    "BZD": {
      "enabled": true,
      "username": "JPEREZ",
      "password_env_var": "SAP_PASSWORD_BZD",
      "default": true
    },
    "BZN": {
      "enabled": true,
      "username": "JPEREZ",
      "password_env_var": "SAP_PASSWORD_BZN",
      "default": false
    }
  }
}
```

**Características:**
- ✅ No se versiona en Git (`.gitignore`)
- ✅ Específico para cada desarrollador
- ✅ Habilita solo los sistemas que usa
- ✅ Define sistema por defecto

### 3. **Gestión Segura de Passwords**

Los passwords se guardan en **variables de entorno del usuario**:

```powershell
# Variables de entorno (nivel usuario, permanentes)
SAP_PASSWORD_BZD = "password_de_juan_para_bzd"
SAP_PASSWORD_DEV = "password_de_juan_para_dev"
SAP_PASSWORD_BZX = "password_de_juan_para_bzx"
SAP_PASSWORD_BZN = "password_de_juan_para_bzn"
```

**Ventajas:**
- ✅ No se guardan en archivos de texto plano
- ✅ No se suben a Git
- ✅ Persisten entre sesiones
- ✅ Accesibles solo para el usuario
- ✅ Un password diferente por sistema

### 4. **Configuración de MCP Automática**

El asistente genera automáticamente `~/.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "sap-bzd": {
      "command": "python",
      "args": ["C:\\Users\\juan\\kiro-sap-abap-power\\server.py"],
      "env": {
        "SAP_HOST": "fbpl08v010.holcimbp.net:8000",
        "SAP_CLIENT": "130",
        "SAP_USER": "JPEREZ",
        "SAP_SYSTEM_ID": "BZD"
      }
    },
    "sap-bzn": {
      "command": "python",
      "args": ["C:\\Users\\juan\\kiro-sap-abap-power\\server.py"],
      "env": {
        "SAP_HOST": "lfh02a09ld075.holcimbp.net:8040",
        "SAP_CLIENT": "100",
        "SAP_USER": "JPEREZ",
        "SAP_SYSTEM_ID": "BZN"
      }
    }
  }
}
```

**Características:**
- ✅ Un MCP server por sistema habilitado
- ✅ Mismo `server.py` para todos
- ✅ `SAP_SYSTEM_ID` diferencia las instancias
- ✅ Password se lee de variable de entorno

---

## Flujo de Trabajo

### Escenario 1: Juan (Business Envelope)

Juan trabaja principalmente con BZD, pero ocasionalmente usa BZN para pruebas.

**Configuración:**
```powershell
.\setup-wizard.ps1
```

1. Ingresa su información personal
2. Selecciona BZD (sistema principal)
3. Ingresa credenciales para BZD
4. Selecciona BZN (sandbox)
5. Ingresa credenciales para BZN
6. ✅ Listo

**Resultado:**
- MCP servers: `sap-bzd` (por defecto), `sap-bzn`
- Variables de entorno: `SAP_PASSWORD_BZD`, `SAP_PASSWORD_BZN`

**Uso en Kiro:**
```
# Sistema por defecto (BZD)
Lee el código del programa ZR_SD_QUICK_ORDERS

# Sistema específico
Lee el código del programa ZR_TEST_SANDBOX del sistema BZN
```

### Escenario 2: María (Building Materials)

María trabaja solo con DEV.

**Configuración:**
```powershell
.\setup-wizard.ps1
```

1. Ingresa su información personal
2. Selecciona DEV (único sistema)
3. Ingresa credenciales para DEV
4. ✅ Listo

**Resultado:**
- MCP server: `sap-dev` (por defecto)
- Variable de entorno: `SAP_PASSWORD_DEV`

**Uso en Kiro:**
```
# Todo va al sistema por defecto (DEV)
Lee el código del programa ZMM_INVENTORY_REPORT
```

### Escenario 3: Carlos (D2I - Multi-sistema)

Carlos trabaja con BZX, pero también necesita acceso a BZD y BZN.

**Configuración:**
```powershell
.\setup-wizard.ps1
```

1. Ingresa su información personal
2. Selecciona BZX (sistema principal)
3. Ingresa credenciales para BZX
4. Selecciona BZD (acceso secundario)
5. Ingresa credenciales para BZD
6. Selecciona BZN (sandbox)
7. Ingresa credenciales para BZN
8. ✅ Listo

**Resultado:**
- MCP servers: `sap-bzx` (por defecto), `sap-bzd`, `sap-bzn`
- Variables de entorno: `SAP_PASSWORD_BZX`, `SAP_PASSWORD_BZD`, `SAP_PASSWORD_BZN`

**Uso en Kiro:**
```
# Sistema por defecto (BZX)
Lee el código del programa ZD2I_INTEGRATION

# Sistemas específicos
Lee el código del programa ZR_SD_QUICK_ORDERS del sistema BZD
Crea una OT en el sistema BZN con descripción "Test"
```

---

## Gestión de Credenciales

### Agregar un Sistema Nuevo

Juan necesita acceso a DEV:

```powershell
.\manage-credentials.ps1 add
```

1. Selecciona DEV de la lista
2. Ingresa usuario y password
3. ✅ Listo

**Resultado:**
- Nuevo MCP server: `sap-dev`
- Nueva variable de entorno: `SAP_PASSWORD_DEV`
- Reiniciar Kiro para aplicar cambios

### Actualizar Password

El password de Juan para BZD cambió:

```powershell
.\manage-credentials.ps1 update
```

1. Selecciona BZD
2. Ingresa nuevo password
3. ✅ Listo

**Resultado:**
- Variable de entorno `SAP_PASSWORD_BZD` actualizada
- No necesita reiniciar Kiro (se aplica en la próxima conexión)

### Eliminar un Sistema

Juan ya no necesita acceso a BZN:

```powershell
.\manage-credentials.ps1 remove
```

1. Selecciona BZN
2. Confirma eliminación
3. ✅ Listo

**Resultado:**
- MCP server `sap-bzn` eliminado de `mcp.json`
- Variable de entorno `SAP_PASSWORD_BZN` eliminada
- Reiniciar Kiro para aplicar cambios

### Listar Sistemas Configurados

```powershell
.\manage-credentials.ps1 list
```

**Salida:**
```
📋 Sistemas configurados

  ✓ BZD (por defecto)
      Usuario: JPEREZ
      Host: fbpl08v010.holcimbp.net:8000
      Cliente: 130
      Equipo: Business Envelope
      Variable de entorno: SAP_PASSWORD_BZD

  ✓ BZN
      Usuario: JPEREZ
      Host: lfh02a09ld075.holcimbp.net:8040
      Cliente: 100
      Equipo: All
      Variable de entorno: SAP_PASSWORD_BZN
```

### Probar Conexiones

```powershell
.\manage-credentials.ps1 test
```

**Salida:**
```
🔌 Probar conexión a sistema SAP

  Sistemas configurados:
    [1] BZD
    [2] BZN
    [0] Probar todos

  Selecciona un sistema (número): 0

  Probando BZD...
    ✓ Conexión exitosa

  Probando BZN...
    ✓ Conexión exitosa
```

---

## Arquitectura Técnica

### Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                         Kiro IDE                            │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ MCP: sap-bzd │  │ MCP: sap-dev │  │ MCP: sap-bzx │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
    ┌─────────────────────────────────────────────────┐
    │           server.py (Multi-instancia)           │
    │                                                 │
    │  Instancia 1      Instancia 2      Instancia 3 │
    │  SAP_SYSTEM_ID=   SAP_SYSTEM_ID=   SAP_SYSTEM_ID=│
    │  BZD              DEV              BZX          │
    └─────┬───────────────┬───────────────┬───────────┘
          │               │               │
          ▼               ▼               ▼
    ┌─────────┐     ┌─────────┐     ┌─────────┐
    │ SAP BZD │     │ SAP DEV │     │ SAP BZX │
    │ :8000   │     │ :8000   │     │ :8000   │
    └─────────┘     └─────────┘     └─────────┘
```

### Flujo de Datos

1. **Usuario en Kiro:** "Lee el código del programa ZR_TEST del sistema DEV"
2. **Kiro:** Identifica que debe usar el MCP server `sap-dev`
3. **MCP sap-dev:** Ejecuta `server.py` con `SAP_SYSTEM_ID=DEV`
4. **server.py:** 
   - Lee configuración de `config-systems.json` para DEV
   - Lee credenciales de `user-config.json`
   - Obtiene password de variable de entorno `SAP_PASSWORD_DEV`
   - Se conecta a SAP DEV
5. **SAP DEV:** Retorna el código del programa
6. **Kiro:** Muestra el código al usuario

---

## Ventajas de esta Arquitectura

### Para el Desarrollador Individual
1. ✅ **Setup único** — Configura una vez, usa siempre
2. ✅ **Múltiples sistemas** — Acceso a todos los sistemas que necesita
3. ✅ **Credenciales seguras** — No se guardan en archivos de texto
4. ✅ **Fácil gestión** — Scripts para agregar/actualizar/eliminar sistemas
5. ✅ **Sistema por defecto** — No necesita especificar el sistema cada vez

### Para el Equipo
1. ✅ **Configuración centralizada** — `config-systems.json` versionado en Git
2. ✅ **Fácil agregar sistemas** — Solo actualizar `config-systems.json`
3. ✅ **Onboarding rápido** — Asistente guiado para nuevos desarrolladores
4. ✅ **Consistencia** — Todos usan la misma configuración de sistemas
5. ✅ **Auditoría** — Se sabe qué sistemas tiene configurado cada desarrollador

### Para la Organización
1. ✅ **Seguridad** — Passwords no se comparten ni se guardan en Git
2. ✅ **Escalabilidad** — Fácil agregar nuevos sistemas o equipos
3. ✅ **Mantenibilidad** — Cambios en configuración de sistemas se propagan automáticamente
4. ✅ **Flexibilidad** — Cada desarrollador configura solo lo que necesita
5. ✅ **Trazabilidad** — Logs de conexión por sistema

---

## Casos de Uso Avanzados

### Caso 1: Cambio de Servidor

El servidor de DEV cambió de host:

**Antes:**
```json
"DEV": {
  "host": "servidor-dev-building.holcimbp.net"
}
```

**Después:**
```json
"DEV": {
  "host": "nuevo-servidor-dev.holcimbp.net"
}
```

**Impacto:**
- ✅ Actualizar `config-systems.json` en Git
- ✅ Todos los desarrolladores hacen `git pull`
- ✅ Reinician Kiro
- ✅ Automáticamente conectan al nuevo servidor

### Caso 2: Nuevo Sistema para un Equipo

Se crea un nuevo sistema BZY para el equipo de Finance:

**Acción:**
1. Agregar BZY a `config-systems.json`
2. Commit y push a Git
3. Comunicar al equipo de Finance

**Resultado:**
- ✅ Equipo de Finance ejecuta `git pull`
- ✅ Ejecuta `.\manage-credentials.ps1 add`
- ✅ Selecciona BZY y configura credenciales
- ✅ Listo para usar

### Caso 3: Rotación de Passwords

La política de seguridad requiere cambiar passwords cada 90 días:

**Acción:**
```powershell
.\manage-credentials.ps1 update
```

**Resultado:**
- ✅ Desarrollador actualiza password para cada sistema
- ✅ Variables de entorno se actualizan
- ✅ Próxima conexión usa el nuevo password

---

## Mejores Prácticas

### Para Desarrolladores

1. **Usa el asistente** — `.\setup-wizard.ps1` para configuración inicial
2. **Gestiona credenciales** — `.\manage-credentials.ps1` para cambios
3. **Verifica conexiones** — Después de cambios, prueba con `.\manage-credentials.ps1 test`
4. **Mantén actualizado** — `git pull` regularmente para obtener nuevos sistemas
5. **No compartas passwords** — Cada desarrollador tiene sus propias credenciales

### Para el Equipo SAP

1. **Mantén `config-systems.json` actualizado** — Es la fuente de verdad
2. **Documenta cambios** — En commits de Git
3. **Comunica cambios** — Notifica al equipo cuando hay nuevos sistemas
4. **Valida configuración** — Antes de agregar un sistema, verifica que funciona
5. **Versiona correctamente** — Usa semantic versioning para el framework

---

## Troubleshooting

### Problema: MCP server no conecta

**Solución:**
```powershell
# Verificar que la variable de entorno existe
$env:SAP_PASSWORD_BZD

# Si no existe, reconfigurar
.\manage-credentials.ps1 update
```

### Problema: Password incorrecto

**Solución:**
```powershell
# Actualizar password
.\manage-credentials.ps1 update

# Probar conexión
.\manage-credentials.ps1 test
```

### Problema: Sistema no aparece en Kiro

**Solución:**
1. Verificar que está en `user-config.json` con `enabled: true`
2. Verificar que está en `~/.kiro/settings/mcp.json`
3. Reiniciar Kiro

### Problema: Necesito acceso a un sistema nuevo

**Solución:**
```powershell
# Verificar que el sistema existe en config-systems.json
Get-Content config-systems.json

# Si existe, agregar credenciales
.\manage-credentials.ps1 add

# Si no existe, contactar al equipo SAP
```

---

## Conclusión

La arquitectura multi-sistema de Kiro SAP ABAP Power permite:

✅ **Flexibilidad** — Cada desarrollador configura solo lo que necesita  
✅ **Seguridad** — Passwords seguros en variables de entorno  
✅ **Escalabilidad** — Fácil agregar nuevos sistemas y equipos  
✅ **Mantenibilidad** — Configuración centralizada y versionada  
✅ **Usabilidad** — Asistente guiado y scripts de gestión  

**Resultado:** Onboarding de 10 minutos para cualquier desarrollador, sin importar cuántos sistemas necesite.

---

**Autor:** Ángel Cruz  
**Fecha:** 2026-05-04  
**Versión:** 1.0
