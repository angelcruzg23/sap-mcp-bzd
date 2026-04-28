# SAP BZD MCP Server

MCP Server en Python para conectar **Kiro** con **SAP ECC BZD 130**.
Usa ADT REST API (HTTP) — sin RFC, sin Docker, sin NW RFC SDK.

## Requisitos

- Python 3.8+
- Acceso HTTP a `fbpl08v010.holcimbp.net:8000`

## Instalación

```powershell
cd C:\Users\angecruz\sap-mcp-bzd
pip install -r requirements.txt
```

## Prueba rápida antes de conectar Kiro

```powershell
# 1. Define tu password como variable de entorno (no la escribas en el código)
$env:SAP_PASSWORD = "tu_password_aqui"

# 2. Prueba que el servidor arranca
python server.py
```

Si ves que el proceso queda esperando en stdin → está bien, es el comportamiento correcto de stdio transport.
Presiona Ctrl+C para salir.

## Configuración en Kiro (mcp.json)

Abre o crea el archivo `.kiro/mcp.json` en tu proyecto de Kiro:

```json
{
  "mcpServers": {
    "sap-bzd": {
      "command": "python",
      "args": ["C:\\Users\\angecruz\\sap-mcp-bzd\\server.py"],
      "env": {
        "SAP_HOST": "fbpl08v010.holcimbp.net:8000",
        "SAP_CLIENT": "130",
        "SAP_USER": "ANGECRUZ",
        "SAP_PASSWORD": "tu_password_aqui",
        "SAP_SECURE": "false"
      },
      "timeout": 60000
    }
  }
}
```

## Herramientas disponibles

| Herramienta | Descripción |
|---|---|
| `sap_ping` | Verifica conectividad con BZD |
| `sap_get_program_source` | Código fuente de un REPORT/PROG |
| `sap_get_class_source` | Código fuente de una clase OO |
| `sap_get_function_module_source` | Código fuente de un FM |
| `sap_search_objects` | Busca objetos Z* en el repositorio |
| `sap_get_table_definition` | Definición de tabla del diccionario |

## Estructura de archivos

```
sap-mcp-bzd/
├── server.py          ← Servidor MCP (entry point)
├── sap_client.py      ← Wrapper HTTP para ADT API
├── requirements.txt   ← Dependencias Python
└── README.md
```
