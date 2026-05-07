---
inclusion: auto
---

# MCP Server Python — Estándares de código y requisitos

## Contexto
El MCP server (server.py + sap_client.py) es la conexión entre Kiro y SAP via ADT REST API.
Es un asset vivo que crece con cada caso de uso nuevo.

## Requisitos de Python

### Versión Mínima: Python 3.10
El paquete `mcp` (Model Context Protocol SDK) requiere Python 3.10 como mínimo.

```bash
python --version   # Debe mostrar: Python 3.10.x o superior
pip show mcp       # Requires: Python >=3.10
```

### Versiones Recomendadas
- **Python 3.12** — última versión estable, recomendada para nuevas instalaciones
- **Python 3.11** — estable, ampliamente soportado
- **Python 3.10** — versión mínima funcional
- ❌ Python 3.8 / 3.9 — no cumplen requisitos del paquete mcp

## Estándares de código Python para el MCP server

### Estructura
- `server.py` — registro de tools MCP y dispatch (list_tools + call_tool)
- `sap_client.py` — cliente HTTP que habla con SAP ADT REST API
- Cada tool MCP corresponde a un método en sap_client.py

### Convenciones
- Nombres de tools: `sap_` + verbo + objeto (ej: `sap_get_program_source`, `sap_update_function_module_source`)
- Parámetros de tools: snake_case, descriptivos, con description en inputSchema
- Siempre incluir `required` en inputSchema aunque esté vacío
- Manejo de errores: capturar excepciones HTTP y retornar mensaje descriptivo al agente
- Logging: usar print() para debug (el MCP server corre como proceso hijo)

### Patrón para agregar un nuevo tool
1. Agregar `types.Tool(...)` en `list_tools()` con nombre, descripción e inputSchema
2. Agregar case en `call_tool()` que extraiga argumentos y llame al método del client
3. Agregar método en `sap_client.py` que haga la llamada HTTP a SAP ADT
4. Probar con una llamada real desde Kiro

### Headers ADT importantes
- `x-csrf-token: fetch` — para obtener token antes de operaciones de escritura
- `Content-Type: text/plain` — para enviar source code ABAP
- `Accept: application/xml` — la mayoría de respuestas ADT son XML

### Endpoints ADT de referencia
| Operación | Método | Endpoint |
|-----------|--------|----------|
| Leer programa | GET | /sap/bc/adt/programs/programs/{name}/source/main |
| Escribir programa | PUT | /sap/bc/adt/programs/programs/{name}/source/main |
| Leer clase | GET | /sap/bc/adt/oo/classes/{name}/source/main |
| Leer FM | GET | /sap/bc/adt/functions/groups/{group}/fmodules/{name}/source/main |
| Escribir FM | PUT | /sap/bc/adt/functions/groups/{group}/fmodules/{name}/source/main |
| Activar | POST | /sap/bc/adt/activation |
| Buscar objetos | GET | /sap/bc/adt/repository/informationsystem/search?operation=quickSearch&query={q} |
| Lock objeto | POST | /sap/bc/adt/programs/programs/{name}?_action=LOCK&accessMode=MODIFY |
| Unlock objeto | POST | /sap/bc/adt/programs/programs/{name}?_action=UNLOCK |
| Syntax check | POST | /sap/bc/adt/checkruns?reporters=abapCheckRun |

## Dependencias

```
# requirements.txt
mcp>=1.0.0        # Model Context Protocol SDK (requiere Python >=3.10)
requests>=2.31.0  # HTTP client para llamadas a SAP ADT REST API
```

## Referencias
- PyPI mcp: https://pypi.org/project/mcp/
- GitHub python-sdk: https://github.com/modelcontextprotocol/python-sdk
- Documentación MCP: https://modelcontextprotocol.io
- SAP ADT REST API: https://help.sap.com/docs/ABAP_PLATFORM_NEW/c238d694b825421f940829321ffa326a/
