# SAP MCP Server (Multi-System)

MCP Server en Python para conectar **Kiro** con sistemas **SAP ECC** vía ADT REST API.
Sin RFC, sin Docker, sin NW RFC SDK — solo HTTP.

Soporta múltiples instancias simultáneas usando `SAP_SYSTEM_ID` como diferenciador.

## Sistemas conectados

| Sistema | Descripción | Host | Cliente | Usuario |
|---------|-------------|------|---------|---------|
| **BZD** | Desarrollo principal | `fbpl08v010.holcimbp.net:8000` | 130 | ANGECRUZ |
| **BZN** | Sandbox / Pruebas | `lfh02a09ld075.holcimbp.net:8040` | 100 | AHERNA11 |

Ambos sistemas corren SAP ECC 6.0 EHP8 con ABAP 7.5.

## Requisitos

- Python 3.8+
- Acceso HTTP a los servidores SAP listados arriba
- Kiro IDE con soporte MCP

## Instalación

```powershell
cd C:\Users\angecruz\sap-mcp-bzd
pip install -r requirements.txt
```

## Prueba rápida

```powershell
# Define variables de entorno y arranca el servidor
$env:SAP_PASSWORD = "tu_password"
$env:SAP_SYSTEM_ID = "BZD"
python server.py
```

Si el proceso queda esperando en stdin, está correcto (stdio transport). Ctrl+C para salir.

## Configuración en Kiro (mcp.json)

El archivo `~/.kiro/settings/mcp.json` (nivel usuario) o `.kiro/mcp.json` (nivel workspace) define los servidores MCP.
Cada sistema SAP se configura como una instancia independiente del mismo `server.py`:

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
        "SAP_PASSWORD": "tu_password",
        "SAP_SECURE": "false",
        "SAP_SYSTEM_ID": "BZD"
      },
      "timeout": 60000
    },
    "sap-bzn": {
      "command": "python",
      "args": ["C:\\Users\\angecruz\\sap-mcp-bzd\\server.py"],
      "env": {
        "SAP_HOST": "lfh02a09ld075.holcimbp.net:8040",
        "SAP_CLIENT": "100",
        "SAP_USER": "AHERNA11",
        "SAP_PASSWORD": "tu_password",
        "SAP_SECURE": "false",
        "SAP_SYSTEM_ID": "BZN"
      },
      "timeout": 60000
    }
  }
}
```

> **Nota**: `SAP_SYSTEM_ID` es la clave que diferencia las instancias. El servidor usa este valor para nombrar dinámicamente el MCP server (`sap-bzd-mcp`, `sap-bzn-mcp`).

## Herramientas disponibles (19 por sistema)

### Lectura

| Herramienta | Descripción |
|---|---|
| `sap_ping` | Verifica conectividad con el sistema SAP |
| `sap_get_program_source` | Código fuente de un programa/report |
| `sap_get_class_source` | Código fuente de una clase ABAP OO |
| `sap_get_function_module_source` | Código fuente de un Function Module |
| `sap_get_include_source` | Código fuente de un INCLUDE |
| `sap_search_objects` | Busca objetos Z*/Y* en el repositorio |
| `sap_get_table_definition` | Definición de tabla del diccionario ABAP |
| `sap_check_adt_capabilities` | Lista servicios ADT disponibles |
| `sap_test_endpoint` | Prueba un endpoint ADT específico |

### Escritura

| Herramienta | Descripción |
|---|---|
| `sap_create_program` | Crea un programa ABAP nuevo y lo activa |
| `sap_update_program_source` | Actualiza código de un programa existente |
| `sap_update_program_from_file` | Actualiza programa desde archivo local |
| `sap_update_function_module_source` | Actualiza código de un FM existente |

### Activación y validación

| Herramienta | Descripción |
|---|---|
| `sap_activate_object` | Activa un objeto ABAP (PROG, CLAS, FUGR, etc.) |
| `sap_syntax_check` | Ejecuta syntax check de un objeto |
| `sap_run_abap_unit` | Ejecuta ABAP Unit tests |

### Transportes

| Herramienta | Descripción |
|---|---|
| `sap_create_transport` | Crea una orden de transporte (Workbench/Customizing) |
| `sap_list_transports` | Lista órdenes de transporte abiertas |
| `sap_get_transport_details` | Detalle y objetos de una OT específica |

## Estructura del repositorio

```
sap-mcp-bzd/
├── server.py              ← Servidor MCP (entry point, multi-sistema)
├── sap_client.py          ← Cliente HTTP para SAP ADT REST API
├── requirements.txt       ← Dependencias Python
├── README.md
├── .kiro/
│   ├── mcp.json           ← Config MCP nivel workspace
│   └── steering/          ← Reglas y estándares del equipo
└── SAP/                   ← Proyectos ABAP y documentación
    ├── ConsultaStockMaterial/
    ├── L2C_CHG0436393/
    ├── ZR_SD_QUICK_ORDERS/
    ├── ZSD_QUOTATION_SALSFRC_CREATE/
    ├── MD/                ← Documentación técnica y workshops
    └── ...
```

## Agregar un nuevo sistema SAP

1. Agregar una nueva entrada en `mcp.json` con un `SAP_SYSTEM_ID` único
2. Apuntar al mismo `server.py` — el servidor se nombra dinámicamente
3. Reconectar desde Kiro (Command Palette → MCP)
4. El nuevo sistema aparecerá como servidor independiente con sus 19 tools
