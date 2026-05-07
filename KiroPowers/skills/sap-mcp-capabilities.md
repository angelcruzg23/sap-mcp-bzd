---
inclusion: manual
---
# SAP MCP Server — Capacidades y Limitaciones

## Última actualización: 2026-05-06

## Lo que SÍ puede hacer el agente via MCP (server.py)

| Acción | Herramienta MCP | Estado | Notas |
|--------|----------------|--------|-------|
| Ping al sistema SAP | sap_ping | ✅ | Verifica conectividad BZD 130 |
| Leer código de programas/reports | sap_get_program_source | ✅ | Objetos tipo PROG |
| Leer código de includes | sap_get_include_source | ✅ | Includes tipo _TOP, _F01, _SCR, etc. |
| Leer código de clases globales | sap_get_class_source | ✅ | ZCL_*, CL_* |
| Leer código de Function Modules | sap_get_function_module_source | ✅ | Requiere function_group + function_name |
| Buscar objetos en repositorio | sap_search_objects | ✅ | Soporta wildcards: ZSD_QUOT*, ZCL_SD* |
| Leer definición de tablas DDIC | sap_get_table_definition | ✅ | No encuentra tablas generadas (ej: KOTG504) |
| Crear programas ABAP | sap_create_program | ✅ | Requiere source_code obligatorio |
| Actualizar código de programas | sap_update_program_source | ✅ | Lock → write → unlock automático |
| Actualizar código de FMs | sap_update_function_module_source | ✅ | Lock → write → unlock automático |
| Crear clases ABAP OO | sap_create_class | ✅ | Crea + escribe + activa |
| Actualizar código de clases | sap_update_class_source | ✅ | Lock → write → unlock automático |
| Crear interfaces ABAP OO | sap_create_interface | ✅ | Crea + escribe + activa |
| Actualizar código de interfaces | sap_update_interface_source | ✅ | Lock → write → unlock automático |
| Crear órdenes de transporte | sap_create_transport | ⚠️ | No funciona con CTS Project Management (BZD) |
| Listar OTs abiertas | sap_list_transports | ✅ | Filtra por usuario opcional |
| Ver detalles de una OT | sap_get_transport_details | ✅ | Objetos en tasks[].objects[] |
| Ver XML crudo de una OT | sap_get_transport_xml_raw | ✅ | Diagnóstico cuando details no muestra objetos |
| Activar objetos ABAP | sap_activate_object | ✅ | Tipos: PROG/P, PROG/I, FUGR/FF, CLAS/OC, INTF/OI |
| Syntax check | sap_syntax_check | ✅ | SIEMPRE ejecutar después de activar |
| Ejecutar ABAP Unit tests | sap_run_abap_unit | ✅ | Solo clases globales ZCL_* |
| Verificar capabilities ADT | sap_check_adt_capabilities | ✅ | Lista servicios ADT disponibles |
| Probar endpoints ADT | sap_test_endpoint | ✅ | Diagnóstico de endpoints específicos |

## Lo que NO puede hacer (pendiente de implementar)

| Acción | Endpoint ADT disponible | Prioridad |
|--------|------------------------|-----------|
| Crear Function Modules | POST en function groups | 🟡 MEDIA |
| Crear tablas/estructuras DDIC | POST /sap/bc/adt/ddic/structures | 🟢 BAJA |
| Ejecutar reports (SUBMIT) | No disponible via ADT REST | ❌ No viable |

## Limitaciones conocidas

### ABAP Unit
- NO detecta clases de test locales en reports (executable programs)
- SOLO funciona con clases globales ZCL_* (verificado con ZCL_SD_QUICK_ORDERS_TEST, ZCL_SD_STOCK_QUERY_TEST)
- URI formato: `/sap/bc/adt/oo/classes/{classname_lowercase}`

### Tablas DDIC
- El endpoint `/sap/bc/adt/ddic/tables/` no encuentra tablas generadas dinámicamente (ej: KOTG504)
- Workaround: usar SELECT directo a DD03L dentro del programa ABAP

### Function Modules
- El endpoint de FM source NO acepta bloques de comentarios de interfaz local (`*"------`). Enviar source limpio tal como lo devuelve el GET.
- Requiere function_group + function_name como parámetros separados

### Órdenes de Transporte
- `sap_create_transport` NO soporta asignación a proyecto CTS (BZD tiene CTS Project Management activo)
- Las OTs deben crearse manualmente en SE09/SE10 y proporcionarse a Kiro

## Tipos de objeto para activación

| Tipo ADT | Descripción |
|----------|-------------|
| PROG/P | Programa/Report |
| PROG/I | Include |
| FUGR/FF | Function Module |
| CLAS/OC | Clase |
| INTF/OI | Interfaz |
| FUGR/F | Function Group |
