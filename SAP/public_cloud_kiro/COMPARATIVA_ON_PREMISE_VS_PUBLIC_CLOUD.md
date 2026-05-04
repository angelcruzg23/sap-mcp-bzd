# Comparativa: Workflow Kiro On-Premise vs Public Cloud

## Flujo de trabajo actual (BZD On-Premise)

```
Kiro (server.py) ──Basic Auth──► SAP ECC BZD 130
                                  │
                                  ├─ Leer/escribir programas Z*
                                  ├─ Leer/escribir FMs
                                  ├─ Leer/escribir includes
                                  ├─ Activar objetos
                                  ├─ Syntax check
                                  ├─ ABAP Unit (clases globales)
                                  └─ Buscar objetos
```

**Objetos típicos:**
- `ZR_SD_QUICK_ORDERS` (programa report)
- `ZCL_SD_STOCK_QUERY` (clase OO)
- `ZFM_SD_GET_MATERIAL_STOCK` (FM RFC-enabled)
- `ZIF_SD_STOCK_DAO` (interfaz)

---

## Flujo de trabajo Public Cloud

```
Kiro (mcp-adt) ──JWT/OAuth2──► S/4HANA Cloud Dev Tenant (080)
                                │
                                ├─ Leer/escribir clases ABAP Cloud
                                ├─ Leer/escribir CDS View Entities
                                ├─ Leer/escribir Behavior Definitions
                                ├─ Leer/escribir Service Definitions
                                ├─ Activar objetos
                                ├─ Syntax check + ATC
                                ├─ ABAP Unit
                                └─ Buscar objetos
```

**Objetos típicos:**
- `ZR_CustomObject` (CDS View Entity)
- `ZBP_R_CustomObject` (Behavior Implementation class)
- `ZCL_CustomLogic` (clase ABAP Cloud)
- `ZUI_CustomObject_O4` (Service Binding OData V4)

---

## Mapeo de tools MCP

| Tool actual (BZD) | Equivalente Public Cloud | Notas |
|---|---|---|
| `sap_get_program_source` | ❌ No aplica | No hay reports clásicos en Public Cloud |
| `sap_get_class_source` | ✅ `get_class_source_mcp` | Funciona igual, pero solo clases ABAP Cloud |
| `sap_get_function_module_source` | ❌ No aplica | No hay FMs clásicos en Public Cloud |
| `sap_get_include_source` | ❌ No aplica | No hay includes en Public Cloud |
| `sap_search_objects` | ✅ `get_search_objects_mcp` | Funciona igual |
| `sap_get_table_definition` | ✅ `get_table_source_mcp` | Solo tablas released o Z* |
| `sap_activate_object` | ✅ Activación vía ADT | Funciona igual |
| `sap_syntax_check` | ✅ Syntax check vía ADT | Funciona igual + ATC obligatorio |
| `sap_create_program` | ❌ No aplica | Usar creación de clases ABAP Cloud |
| `sap_update_program_source` | ❌ No aplica | Usar update de clases |
| N/A | ✅ `get_cds_source_mcp` | **Nuevo** — leer CDS views |
| N/A | ✅ `get_sql_query_mcp` | **Nuevo** — ejecutar SQL queries |
| N/A | ✅ `get_usage_references_mcp` | **Nuevo** — where-used list |

---

## Patrones SOLID: adaptación a ABAP Cloud

### Patrón actual (On-Premise)
```
ZFM_SD_GET_MATERIAL_STOCK (FM RFC — fachada)
  └─ ZCL_SD_STOCK_QUERY (orquestador)
       ├─ ZIF_SD_STOCK_DAO → ZCL_SD_STOCK_DAO (acceso a datos con SELECT)
       └─ ZIF_SD_EXCLUSION_CHECKER → ZCL_SD_EXCLUSION_CHECKER
```

### Patrón equivalente (Public Cloud)
```
Service Binding ZUI_STOCK_QUERY_O4 (OData V4 — fachada)
  └─ Service Definition ZSD_STOCK_QUERY
       └─ CDS View Entity ZR_StockQuery (modelo de datos)
            └─ Behavior Definition (lógica)
                 └─ ZBP_R_StockQuery (behavior implementation)
                      ├─ ZIF_SD_STOCK_DAO → ZCL_SD_STOCK_DAO (acceso via CDS views released)
                      └─ ZIF_SD_EXCLUSION_CHECKER → ZCL_SD_EXCLUSION_CHECKER
```

**Diferencia clave:** En Public Cloud, la fachada ya no es un FM RFC sino un Service Binding OData. La lógica de negocio en clases OO se mantiene igual, pero el acceso a datos debe usar CDS views released en lugar de SELECTs directos a tablas.

---

## Resumen de decisión

| Si necesitas... | Usa... |
|---|---|
| Desarrollar en BZD (ECC on-premise) | MCP server actual (`server.py`) con Basic Auth |
| Desarrollar en S/4HANA Cloud Public | `mcp-adt` con JWT Auth |
| Ambos sistemas | Dos entradas en `mcp.json`, una por sistema |
