# Guía de Instalación — Kiro + SAP MCP Server en macOS

## Resumen

El MCP Server SAP ADT es **100% compatible con macOS** sin modificaciones al código.  
Usa Python puro + HTTP (sin RFC SDK, sin DLLs, sin dependencias nativas de Windows).

Solo se necesita:
1. Instalar Python y dependencias
2. Copiar los archivos del servidor
3. Configurar `mcp.json` con rutas macOS
4. Ajustar credenciales SAP del usuario

---

## Requisitos previos

| Componente | Versión mínima | Verificar con |
|------------|---------------|---------------|
| macOS | 12 Monterey+ | `sw_vers` |
| Python | 3.10+ | `python3 --version` |
| pip | 21+ | `pip3 --version` |
| Kiro IDE | Última versión | Descargar de kiro.dev |
| Acceso red | Puerto 8000 al servidor SAP | `curl http://fbpl08v010.holcimbp.net:8000` |

---

## Paso 1 — Instalar Python (si no está)

macOS incluye Python 3 en versiones recientes. Si no lo tienes:

```bash
# Opción A: Homebrew (recomendado)
brew install python@3.12

# Opción B: Descarga directa
# https://www.python.org/downloads/macos/
```

Verificar:
```bash
python3 --version
# Python 3.12.x
```

---

## Paso 2 — Crear directorio del proyecto

```bash
# Crear carpeta para el MCP server
mkdir -p ~/sap-mcp-bzd
cd ~/sap-mcp-bzd
```

---

## Paso 3 — Copiar archivos del servidor

Copia estos 3 archivos desde el repositorio Windows al Mac:

```
~/sap-mcp-bzd/
├── server.py          # Servidor MCP (sin cambios)
├── sap_client.py      # Cliente HTTP SAP ADT (sin cambios)
└── requirements.txt   # Dependencias Python (sin cambios)
```

Puedes copiarlos por:
- Git clone del repositorio
- SCP/SFTP desde la máquina Windows
- Copiar manualmente el contenido

> **Importante:** Los archivos `server.py` y `sap_client.py` NO requieren ninguna modificación para macOS.

---

## Paso 4 — Instalar dependencias Python

```bash
cd ~/sap-mcp-bzd

# Opción A: Instalación directa
pip3 install mcp requests

# Opción B: Usando requirements.txt
pip3 install -r requirements.txt

# Opción C: Con entorno virtual (recomendado para aislar dependencias)
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## Paso 5 — Verificar conectividad con SAP

Antes de configurar Kiro, verifica que tu Mac puede alcanzar el servidor SAP:

```bash
# Test de red básico
curl -s -o /dev/null -w "%{http_code}" http://fbpl08v010.holcimbp.net:8000/sap/bc/adt/discovery

# Si retorna 401 = el servidor responde (falta auth, es normal)
# Si retorna 000 o timeout = problema de red/VPN
```

> **Nota:** Si estás fuera de la red corporativa, necesitarás VPN activa para alcanzar el servidor SAP.

---

## Paso 6 — Configurar Kiro MCP

Abre Kiro en macOS y configura el archivo `.kiro/mcp.json` en tu workspace:

### Si usas instalación directa (sin venv):

```json
{
  "mcpServers": {
    "sap-bzd": {
      "command": "python3",
      "args": ["/Users/TU_USUARIO/sap-mcp-bzd/server.py"],
      "env": {
        "SAP_HOST": "fbpl08v010.holcimbp.net:8000",
        "SAP_CLIENT": "130",
        "SAP_USER": "TU_USUARIO_SAP",
        "SAP_PASSWORD": "TU_PASSWORD_SAP",
        "SAP_SECURE": "false"
      },
      "timeout": 60000
    }
  }
}
```

### Si usas entorno virtual (venv):

```json
{
  "mcpServers": {
    "sap-bzd": {
      "command": "/Users/TU_USUARIO/sap-mcp-bzd/.venv/bin/python",
      "args": ["/Users/TU_USUARIO/sap-mcp-bzd/server.py"],
      "env": {
        "SAP_HOST": "fbpl08v010.holcimbp.net:8000",
        "SAP_CLIENT": "130",
        "SAP_USER": "TU_USUARIO_SAP",
        "SAP_PASSWORD": "TU_PASSWORD_SAP",
        "SAP_SECURE": "false"
      },
      "timeout": 60000
    }
  }
}
```

### Diferencias clave vs. Windows

| Aspecto | Windows | macOS |
|---------|---------|-------|
| Comando Python | `python` | `python3` |
| Ruta al server | `C:\\Users\\...\\server.py` | `/Users/.../server.py` |
| Separador de ruta | `\\` | `/` |
| Activar venv | `.venv\Scripts\activate` | `source .venv/bin/activate` |

---

## Paso 7 — Conectar otros clientes SAP

El servidor soporta **cualquier sistema SAP con ADT habilitado** cambiando las variables de entorno.  
Para conectar otro cliente, simplemente agrega otro server en `mcp.json`:

```json
{
  "mcpServers": {
    "sap-bzd": {
      "command": "python3",
      "args": ["/Users/TU_USUARIO/sap-mcp-bzd/server.py"],
      "env": {
        "SAP_HOST": "fbpl08v010.holcimbp.net:8000",
        "SAP_CLIENT": "130",
        "SAP_USER": "TU_USUARIO_SAP",
        "SAP_PASSWORD": "TU_PASSWORD_SAP",
        "SAP_SECURE": "false"
      },
      "timeout": 60000
    },
    "sap-dev": {
      "command": "python3",
      "args": ["/Users/TU_USUARIO/sap-mcp-bzd/server.py"],
      "env": {
        "SAP_HOST": "servidor-dev.holcimbp.net:8000",
        "SAP_CLIENT": "100",
        "SAP_USER": "TU_USUARIO_DEV",
        "SAP_PASSWORD": "TU_PASSWORD_DEV",
        "SAP_SECURE": "false"
      },
      "timeout": 60000
    },
    "sap-qa": {
      "command": "python3",
      "args": ["/Users/TU_USUARIO/sap-mcp-bzd/server.py"],
      "env": {
        "SAP_HOST": "servidor-qa.holcimbp.net:8000",
        "SAP_CLIENT": "200",
        "SAP_USER": "TU_USUARIO_QA",
        "SAP_PASSWORD": "TU_PASSWORD_QA",
        "SAP_SECURE": "true"
      },
      "timeout": 60000
    }
  }
}
```

Cada entrada en `mcpServers` levanta una instancia independiente del server.py con sus propias credenciales.  
Kiro mostrará las herramientas de cada servidor con el prefijo correspondiente (ej: `mcp_sap_bzd_sap_ping`, `mcp_sap_dev_sap_ping`).

---

## Paso 8 — Verificar en Kiro

Una vez configurado:

1. Abre Kiro
2. Abre el panel de MCP Servers (Command Palette → "MCP")
3. Verifica que el servidor `sap-bzd` aparece con estado **running** (verde)
4. En el chat, pide: *"Haz un ping a SAP"*
5. Kiro debería usar la herramienta `sap_ping` y confirmar la conexión

---

## Troubleshooting

### El servidor no arranca
```bash
# Verificar que Python encuentra las dependencias
python3 -c "import mcp; import requests; print('OK')"

# Si falla, reinstalar
pip3 install mcp requests
```

### Error de conexión a SAP
- Verificar VPN activa
- Verificar que el puerto 8000 no está bloqueado por firewall
- Probar: `curl http://fbpl08v010.holcimbp.net:8000/sap/bc/adt/discovery`

### Error "command not found: python3"
```bash
# Verificar instalación
which python3

# Si usas pyenv
eval "$(pyenv init -)"
```

### Timeout en operaciones
- Aumentar `timeout` en mcp.json (ej: `120000` para 2 minutos)
- Verificar latencia de red: `ping fbpl08v010.holcimbp.net`

### HTTPS (SAP_SECURE=true)
Si el servidor SAP usa HTTPS con certificado auto-firmado, puede fallar la verificación SSL.  
Solución temporal en `sap_client.py`:
```python
self.session.verify = False  # Solo para desarrollo/testing
```

---

## Seguridad — Manejo de contraseñas

Evita dejar contraseñas en texto plano en `mcp.json`. Alternativas:

### Opción 1: macOS Keychain (recomendado)
```bash
# Guardar en Keychain
security add-generic-password -a "SAP_USER" -s "sap-bzd-password" -w "TU_PASSWORD"

# Leer desde script wrapper
security find-generic-password -a "SAP_USER" -s "sap-bzd-password" -w
```

### Opción 2: Archivo .env (no commitear a Git)
```bash
# ~/sap-mcp-bzd/.env
SAP_PASSWORD=tu_password_aqui
```

### Opción 3: Variable de entorno en shell profile
```bash
# En ~/.zshrc o ~/.bash_profile
export SAP_PASSWORD="tu_password_aqui"
```

Luego en `mcp.json` omitir `SAP_PASSWORD` del bloque `env` para que tome la variable del sistema.

---

## Arquitectura — Por qué funciona cross-platform

```
┌─────────────┐     stdio      ┌──────────────┐     HTTP/REST     ┌───────────┐
│   Kiro IDE   │ ◄────────────► │  server.py   │ ◄────────────────► │  SAP ECC  │
│   (macOS)    │   JSON-RPC     │  (Python 3)  │   ADT REST API    │  BZD 130  │
└─────────────┘                 └──────────────┘                    └───────────┘
                                       │
                                 sap_client.py
                                 (requests HTTP)
```

- Sin RFC SDK → sin compilación nativa
- Sin Docker → sin overhead
- Python puro + HTTP = funciona en Windows, macOS, Linux
