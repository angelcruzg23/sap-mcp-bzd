"""
SAP BZD MCP Server
MCP Server en Python para conectar Kiro con SAP ECC BZD 130
Usa ADT REST API (HTTP) — sin RFC, sin Docker, sin NW RFC SDK.
Transport: stdio (requerido por Kiro)
"""

import os
import sys
import json
import asyncio
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

from sap_client import SAPADTClient

# ──────────────────────────────────────────────
# Configuración de conexión SAP BZD
# Puedes sobreescribir con variables de entorno
# ──────────────────────────────────────────────
SAP_HOST     = os.environ.get("SAP_HOST",     "fbpl08v010.holcimbp.net:8000")
SAP_CLIENT   = os.environ.get("SAP_CLIENT",   "130")
SAP_USER     = os.environ.get("SAP_USER",     "ANGECRUZ")
SAP_PASSWORD = os.environ.get("SAP_PASSWORD", "")  # Se pasa por variable de entorno
SAP_SECURE   = os.environ.get("SAP_SECURE",   "false").lower() == "true"

# Instancia global del cliente ADT
sap = SAPADTClient(
    host=SAP_HOST,
    client=SAP_CLIENT,
    username=SAP_USER,
    password=SAP_PASSWORD,
    secure=SAP_SECURE,
)

# ──────────────────────────────────────────────
# Crear el servidor MCP
# ──────────────────────────────────────────────
server = Server("sap-bzd-mcp")


# ──────────────────────────────────────────────
# Lista de herramientas disponibles
# ──────────────────────────────────────────────
@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="sap_ping",
            description="Verifica la conectividad con el sistema SAP BZD 130. Úsalo para confirmar que el servidor MCP puede hablar con SAP.",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        ),
        types.Tool(
            name="sap_get_program_source",
            description="Obtiene el código fuente ABAP de un programa o report (objetos tipo PROG). Ejemplo: ZREPORTE_VENTAS.",
            inputSchema={
                "type": "object",
                "properties": {
                    "program_name": {
                        "type": "string",
                        "description": "Nombre del programa ABAP en mayúsculas. Ej: ZREPORTE_VENTAS"
                    }
                },
                "required": ["program_name"]
            }
        ),
        types.Tool(
            name="sap_get_class_source",
            description="Obtiene el código fuente de una clase ABAP OO (ZCL_*, LCL_*, etc.).",
            inputSchema={
                "type": "object",
                "properties": {
                    "class_name": {
                        "type": "string",
                        "description": "Nombre de la clase ABAP. Ej: ZCL_SD_HELPER"
                    }
                },
                "required": ["class_name"]
            }
        ),
        types.Tool(
            name="sap_get_function_module_source",
            description="Obtiene el código fuente de un Function Module ABAP. Necesitas el nombre del grupo de funciones y el nombre del FM.",
            inputSchema={
                "type": "object",
                "properties": {
                    "function_group": {
                        "type": "string",
                        "description": "Nombre del grupo de funciones. Ej: ZSD_QUOTATION"
                    },
                    "function_name": {
                        "type": "string",
                        "description": "Nombre del Function Module. Ej: ZSD_QUOTATION_SALSFRC_CHANGE"
                    }
                },
                "required": ["function_group", "function_name"]
            }
        ),
        types.Tool(
            name="sap_get_include_source",
            description="Obtiene el código fuente de un INCLUDE ABAP (los includes son subprogramas referenciados con INCLUDE en un programa principal). Ejemplo: ZSDR_DAILY_INVOICE_REPORT_TOP, ZSDR_DAILY_INVOICE_REPORT_F01.",
            inputSchema={
                "type": "object",
                "properties": {
                    "include_name": {
                        "type": "string",
                        "description": "Nombre del include ABAP en mayúsculas. Ej: ZSDR_DAILY_INVOICE_REPORT_TOP"
                    }
                },
                "required": ["include_name"]
            }
        ),
        types.Tool(
            name="sap_search_objects",
            description="Busca objetos ABAP en el repositorio de SAP BZD por nombre o patrón. Útil para encontrar Z* o Y* objetos.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Término de búsqueda. Ej: ZSD_QUOT* o ZCL_SD*"
                    },
                    "max_results": {
                        "type": "integer",
                        "description": "Número máximo de resultados (default 20)",
                        "default": 20
                    }
                },
                "required": ["query"]
            }
        ),
        types.Tool(
            name="sap_get_table_definition",
            description="Obtiene la definición de una tabla del diccionario ABAP (campos, tipos, longitudes).",
            inputSchema={
                "type": "object",
                "properties": {
                    "table_name": {
                        "type": "string",
                        "description": "Nombre de la tabla ABAP. Ej: ZZSD_QUOTATION o VBAK"
                    }
                },
                "required": ["table_name"]
            }
        ),
        types.Tool(
            name="sap_check_adt_capabilities",
            description="Lista todos los servicios ADT disponibles en SAP BZD. Útil para verificar qué operaciones soporta el sistema (lectura, escritura, activación, etc.).",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        ),
        types.Tool(
            name="sap_test_endpoint",
            description="Prueba un endpoint ADT específico para verificar si está disponible y responde. Útil para diagnóstico.",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path del endpoint ADT. Ej: /sap/bc/adt/programs/programs"
                    },
                    "method": {
                        "type": "string",
                        "description": "Método HTTP: GET, HEAD, OPTIONS. Default: GET",
                        "default": "GET"
                    }
                },
                "required": ["path"]
            }
        ),
        types.Tool(
            name="sap_create_program",
            description="Crea un programa ABAP nuevo en SAP BZD, escribe el código fuente y lo activa. Requiere nombre, descripción, paquete, orden de transporte y código fuente.",
            inputSchema={
                "type": "object",
                "properties": {
                    "program_name": {
                        "type": "string",
                        "description": "Nombre del programa en mayúsculas. Ej: ZR_SD_QUICK_ORDERS"
                    },
                    "description": {
                        "type": "string",
                        "description": "Descripción corta del programa"
                    },
                    "package": {
                        "type": "string",
                        "description": "Paquete de desarrollo. Ej: ZDEV_SD, $TMP"
                    },
                    "transport": {
                        "type": "string",
                        "description": "Orden de transporte. Ej: BZDK900123. Dejar vacío para $TMP"
                    },
                    "source_code": {
                        "type": "string",
                        "description": "Código fuente ABAP completo del programa"
                    }
                },
                "required": ["program_name", "description", "package", "source_code"]
            }
        ),
        types.Tool(
            name="sap_update_program_source",
            description="Actualiza el código fuente de un programa ABAP existente en SAP BZD. Hace lock, escribe y unlock.",
            inputSchema={
                "type": "object",
                "properties": {
                    "program_name": {
                        "type": "string",
                        "description": "Nombre del programa existente. Ej: ZR_SD_QUICK_ORDERS"
                    },
                    "source_code": {
                        "type": "string",
                        "description": "Código fuente ABAP completo (reemplaza todo el código)"
                    },
                    "transport": {
                        "type": "string",
                        "description": "Orden de transporte (opcional)"
                    }
                },
                "required": ["program_name", "source_code"]
            }
        ),
        types.Tool(
            name="sap_update_function_module_source",
            description="Actualiza el código fuente de un Function Module ABAP existente en SAP BZD. Hace lock, escribe y unlock.",
            inputSchema={
                "type": "object",
                "properties": {
                    "function_group": {
                        "type": "string",
                        "description": "Nombre del grupo de funciones. Ej: ZSD_PPD"
                    },
                    "function_name": {
                        "type": "string",
                        "description": "Nombre del Function Module. Ej: ZSD_PPD_REJ_UPDATE"
                    },
                    "source_code": {
                        "type": "string",
                        "description": "Código fuente ABAP completo del FM (reemplaza todo el código)"
                    },
                    "transport": {
                        "type": "string",
                        "description": "Orden de transporte (opcional)"
                    }
                },
                "required": ["function_group", "function_name", "source_code"]
            }
        ),
        types.Tool(
            name="sap_create_transport",
            description="Crea una orden de transporte (Workbench o Customizing Request) en SAP BZD. Retorna el número de OT y task creados.",
            inputSchema={
                "type": "object",
                "properties": {
                    "description": {
                        "type": "string",
                        "description": "Descripción de la orden de transporte. Ej: L2C:CHG0436752- EHP8 fix"
                    },
                    "request_type": {
                        "type": "string",
                        "description": "Tipo de request: K = Workbench (default), W = Customizing",
                        "default": "K"
                    },
                    "target": {
                        "type": "string",
                        "description": "Sistema destino del transporte (opcional, se usa el default del sistema si se omite)",
                        "default": ""
                    }
                },
                "required": ["description"]
            }
        ),
        types.Tool(
            name="sap_activate_object",
            description="Activa un objeto ABAP en SAP BZD (programa, clase, interfaz, etc.).",
            inputSchema={
                "type": "object",
                "properties": {
                    "object_name": {
                        "type": "string",
                        "description": "Nombre del objeto. Ej: ZR_SD_QUICK_ORDERS"
                    },
                    "object_type": {
                        "type": "string",
                        "description": "Tipo del objeto ADT. Ej: PROG/P, CLAS/OC, INTF/OI, FUGR/F",
                        "default": "PROG/P"
                    }
                },
                "required": ["object_name"]
            }
        ),
        types.Tool(
            name="sap_run_abap_unit",
            description="Ejecuta ABAP Unit tests para un objeto ABAP en SAP BZD. Retorna los resultados de los tests.",
            inputSchema={
                "type": "object",
                "properties": {
                    "object_url": {
                        "type": "string",
                        "description": "URI ADT del objeto. Ej: /sap/bc/adt/oo/classes/zcl_sd_quick_orders_test"
                    }
                },
                "required": ["object_url"]
            }
        ),
        types.Tool(
            name="sap_syntax_check",
            description="Ejecuta syntax check de un objeto ABAP en SAP BZD. Retorna errores y warnings de compilación. Usar DESPUÉS de subir código y ANTES de considerar el deploy como exitoso.",
            inputSchema={
                "type": "object",
                "properties": {
                    "object_url": {
                        "type": "string",
                        "description": "URI ADT del objeto. Ej: /sap/bc/adt/programs/programs/zr_sd_quick_orders, /sap/bc/adt/functions/groups/zsd_pros_int/fmodules/zsd_pros_currency_rate_get, /sap/bc/adt/oo/classes/zcl_sd_stock_query"
                    }
                },
                "required": ["object_url"]
            }
        ),
    ]


# ──────────────────────────────────────────────
# Ejecutar herramientas
# ──────────────────────────────────────────────
@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[types.TextContent]:

    def respond(data: dict) -> list[types.TextContent]:
        return [types.TextContent(type="text", text=json.dumps(data, ensure_ascii=False, indent=2))]

    if name == "sap_ping":
        result = sap.ping()
        return respond(result)

    elif name == "sap_get_program_source":
        program = arguments.get("program_name", "").upper()
        if not program:
            return respond({"ok": False, "message": "program_name es requerido"})
        result = sap.get_program_source(program)
        return respond(result)

    elif name == "sap_get_class_source":
        cls = arguments.get("class_name", "").upper()
        if not cls:
            return respond({"ok": False, "message": "class_name es requerido"})
        result = sap.get_class_source(cls)
        return respond(result)

    elif name == "sap_get_function_module_source":
        fg = arguments.get("function_group", "").upper()
        fm = arguments.get("function_name", "").upper()
        if not fg or not fm:
            return respond({"ok": False, "message": "function_group y function_name son requeridos"})
        result = sap.get_function_module_source(fg, fm)
        return respond(result)

    elif name == "sap_get_include_source":
        include = arguments.get("include_name", "").upper()
        if not include:
            return respond({"ok": False, "message": "include_name es requerido"})
        result = sap.get_include_source(include)
        return respond(result)

    elif name == "sap_search_objects":
        query = arguments.get("query", "")
        max_r = arguments.get("max_results", 20)
        if not query:
            return respond({"ok": False, "message": "query es requerido"})
        result = sap.search_objects(query, max_r)
        return respond(result)

    elif name == "sap_get_table_definition":
        table = arguments.get("table_name", "").upper()
        if not table:
            return respond({"ok": False, "message": "table_name es requerido"})
        result = sap.get_table_definition(table)
        return respond(result)

    elif name == "sap_check_adt_capabilities":
        result = sap.check_adt_capabilities()
        return respond(result)

    elif name == "sap_test_endpoint":
        path = arguments.get("path", "")
        method = arguments.get("method", "GET")
        if not path:
            return respond({"ok": False, "message": "path es requerido"})
        result = sap.test_endpoint(path, method)
        return respond(result)

    elif name == "sap_create_program":
        prog = arguments.get("program_name", "").upper()
        desc = arguments.get("description", "")
        pkg = arguments.get("package", "$TMP").upper()
        tr = arguments.get("transport", "")
        src = arguments.get("source_code", "")
        if not prog or not src:
            return respond({"ok": False, "message": "program_name y source_code son requeridos"})
        result = sap.create_program(prog, desc, pkg, tr, src)
        return respond(result)

    elif name == "sap_update_program_source":
        prog = arguments.get("program_name", "").upper()
        src = arguments.get("source_code", "")
        tr = arguments.get("transport", "")
        if not prog or not src:
            return respond({"ok": False, "message": "program_name y source_code son requeridos"})
        result = sap.update_program_source(prog, src, tr)
        return respond(result)

    elif name == "sap_update_function_module_source":
        fg = arguments.get("function_group", "").upper()
        fm = arguments.get("function_name", "").upper()
        src = arguments.get("source_code", "")
        tr = arguments.get("transport", "")
        if not fg or not fm or not src:
            return respond({"ok": False, "message": "function_group, function_name y source_code son requeridos"})
        result = sap.update_function_module_source(fg, fm, src, tr)
        return respond(result)

    elif name == "sap_create_transport":
        desc = arguments.get("description", "")
        req_type = arguments.get("request_type", "K").upper()
        target = arguments.get("target", "")
        if not desc:
            return respond({"ok": False, "message": "description es requerido"})
        result = sap.create_transport_request(desc, req_type, target)
        return respond(result)

    elif name == "sap_activate_object":
        obj = arguments.get("object_name", "").upper()
        obj_type = arguments.get("object_type", "PROG/P")
        if not obj:
            return respond({"ok": False, "message": "object_name es requerido"})
        result = sap.activate_object(obj, obj_type)
        return respond(result)

    elif name == "sap_run_abap_unit":
        obj_url = arguments.get("object_url", "")
        if not obj_url:
            return respond({"ok": False, "message": "object_url es requerido"})
        result = sap.run_abap_unit(obj_url)
        return respond(result)

    elif name == "sap_syntax_check":
        obj_url = arguments.get("object_url", "")
        if not obj_url:
            return respond({"ok": False, "message": "object_url es requerido"})
        result = sap.syntax_check(obj_url)
        return respond(result)

    else:
        return respond({"ok": False, "message": f"Herramienta desconocida: {name}"})


# ──────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────
async def main():
    if not SAP_PASSWORD:
        print(
            "ERROR: Variable de entorno SAP_PASSWORD no está definida.\n"
            "Ejecuta: $env:SAP_PASSWORD='tu_password' antes de iniciar el servidor.",
            file=sys.stderr
        )
        sys.exit(1)

    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
