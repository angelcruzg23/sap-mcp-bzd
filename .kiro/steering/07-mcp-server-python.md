---
inclusion: auto
---

# MCP Server Python — Estandares de codigo y requisitos

## Contexto
El MCP server (server.py + sap_client.py) es la conexion entre Kiro y SAP via ADT REST API.
Es un asset vivo que crece con cada caso de uso nuevo.

## Requisitos de Python

### Version Minima: Python 3.10

**Razon:** El paquete `mcp` (Model Context Protocol SDK) requiere Python 3.10 como minimo.

```bash
# Verificar version
python --version
# Debe mostrar: Python 3.10.x o superior

# Verificar paquete mcp
pip show mcp
# Requires: Python >=3.10
```

### Versiones Recomendadas

- **Python 3.11** - Estable, ampliamente soportado
- **Python 3.12** - Ultima version estable, recomendada para nuevas instalaciones
- **Python 3.10** - Version minima funcional

### Versiones NO Soportadas

- ❌ Python 3.8 - No cumple requisitos del paquete mcp
- ❌ Python 3.9 - No cumple requisitos del paquete mcp
- ❌ Python 2.x - Obsoleto

## Estandares de codigo Python para el MCP server

### Estructura
- `server.py` — registro de tools MCP y dispatch (list_tools + call_tool)
- `sap_client.py` — cliente HTTP que habla con SAP ADT REST API
- Cada tool MCP corresponde a un metodo en sap_client.py

### Convenciones
- Nombres de tools: `sap_` + verbo + objeto (ej: `sap_get_program_source`, `sap_update_function_module_source`)
- Parametros de tools: snake_case, descriptivos, con description en inputSchema
- Siempre incluir `required` en inputSchema aunque este vacio
- Manejo de errores: capturar excepciones HTTP y retornar mensaje descriptivo al agente
- Logging: usar print() para debug (el MCP server corre como proceso hijo)

### Patron para agregar un nuevo tool

1. Agregar `types.Tool(...)` en `list_tools()` con nombre, descripcion e inputSchema
2. Agregar case en `call_tool()` que extraiga argumentos y llame al metodo del client
3. Agregar metodo en `sap_client.py` que haga la llamada HTTP a SAP ADT
4. Probar con una llamada real desde Kiro

### Headers ADT importantes
- `x-csrf-token: fetch` — para obtener token antes de operaciones de escritura
- `Content-Type: text/plain` — para enviar source code ABAP
- `Accept: application/xml` — la mayoria de respuestas ADT son XML

### Endpoints ADT de referencia
| Operacion | Metodo | Endpoint |
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

### requirements.txt

```
# Model Context Protocol SDK (requiere Python >=3.10)
mcp>=1.0.0

# HTTP client para llamadas a SAP ADT REST API
requests>=2.31.0
```

### Instalacion

```bash
# Instalar dependencias
pip install -r requirements.txt

# Verificar instalacion
pip list | grep mcp
pip list | grep requests
```

## Referencias

- **PyPI mcp:** https://pypi.org/project/mcp/
- **GitHub python-sdk:** https://github.com/modelcontextprotocol/python-sdk
- **Documentacion MCP:** https://modelcontextprotocol.io
- **SAP ADT REST API:** https://help.sap.com/docs/ABAP_PLATFORM_NEW/c238d694b825421f940829321ffa326a/

## Notas Importantes

1. **No usar Python 3.8 o 3.9** - El paquete mcp no funcionara
2. **Recomendar Python 3.11 o 3.12** - Versiones estables y ampliamente soportadas
3. **Verificar version antes de instalar** - Evitar problemas de compatibilidad
4. **Actualizar documentacion** - Mantener consistencia en todos los archivos
