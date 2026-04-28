---
inclusion: fileMatch
fileMatchPattern: "**/*.abap"
---

# S/4HANA Readiness — Reglas para código ABAP nuevo

## Tablas que NO deben usarse en código nuevo
Estas tablas serán eliminadas o reemplazadas en S/4HANA. Usar alternativas compatibles:

| NO usar | Usar en su lugar | Motivo |
|---------|-----------------|--------|
| VBUK | Campos de status en VBAK | Tabla eliminada en S/4 |
| VBUP | Campos de status en VBAP | Tabla eliminada en S/4 |
| KONV | PRCD_ELEMENTS (o KONV solo como estructura) | Tabla reemplazada |
| BSEG (como tabla real) | ACDOCA | Universal Journal |
| MSEG, MKPF | MATDOC | Nuevo documento de material |
| FAGLFLEXA, FAGLFLEXT | ACDOCA | Eliminadas |

## Campos y tablas — trampas conocidas
- EISBE (stock de seguridad) NO es campo de MARD — es de MARC. No incluir en SELECTs a MARD.
- MATNR será 40 caracteres en S/4 (hoy es 18). No asumir longitud fija.
- KUNNR/LIFNR serán reemplazados por Business Partner (BUPA). Considerar en diseños nuevos.
- En integraciones CRM ↔ ECC, los mapeos de BTMBDOC pueden cambiar con Business Partner.

## Sintaxis ABAP 7.5 obligatoria en código nuevo
- Usar inline declarations: DATA( ), FIELD-SYMBOL( )
- Usar VALUE #( ) para construir tablas y estructuras
- Usar NEW #( ) en lugar de CREATE OBJECT
- Usar llamadas funcionales: obj->method( ) en lugar de CALL METHOD
- Usar Open SQL con @ para host variables: WHERE field IN @s_range
- Usar COND / SWITCH en lugar de IF/CASE para asignaciones simples
- Usar FILTER #( ) en lugar de LOOP + APPEND para filtrar tablas
- Usar REDUCE para agregaciones en lugar de LOOP + suma manual
- Usar xsdbool( ) para expresiones booleanas: rv_exists = xsdbool( sy-subrc = 0 )

## Function Modules estándar con cambios de comportamiento en S/4HANA

| FM Estándar | Cambio en S/4 | Impacto |
|-------------|---------------|---------|
| MD_STOCK_REQUIREMENTS_LIST_API | Authority checks más estrictos (M_MTDI_ORG) desde EHP8 | Agregar pre-check antes de llamar |
| BAPI_CUSTOMERQUOTATION_CHANGE | Sin cambio directo, pero VBUK/VBUP eliminadas afectan status checks previos | Verificar que no se lean VBUK/VBUP antes de la BAPI |
| CRM_DOWNLOAD_BTMBDOC | Estructura BAD_BUS_TRANSN_MESSAGE puede diferir entre sistemas | Alinear SP entre ECC y CRM |
| FMs que leen KONV | KONV reemplazada por PRCD_ELEMENTS | Usar PRCD_ELEMENTS o acceso via CDS |
| FMs que leen BSEG | BSEG será vista de compatibilidad sobre ACDOCA | Performance degradada, migrar a ACDOCA |

## Business Partner — Preparación para migración

En S/4HANA, KUNNR (cliente) y LIFNR (proveedor) son reemplazados por Business Partner (BP):
- Tabla central: BUT000 (Business Partner general)
- Mapeo: BUT000-PARTNER ↔ KNA1-KUNNR (via tabla de mapeo)
- En código nuevo: no asumir que KUNNR = número de cliente final. Diseñar con abstracción.
- En integraciones CRM ↔ ECC: los mapeos de BTMBDOC pueden cambiar con Business Partner.
- En integraciones Salesforce: el Account ID de SF ya es independiente de KUNNR, pero verificar mapeos en tablas Z.

## Patrones a evitar
- No usar Native SQL (EXEC SQL / ENDEXEC)
- No usar FORMs (PERFORM/FORM) — usar métodos de clase
- No usar SELECT sin listar campos explícitamente
- No usar CREATE OBJECT — usar NEW #( )
- No usar CALL METHOD — usar llamada funcional directa
