---
inclusion: manual
---
# SAP Integration Patterns — Amrize BP

## Última actualización: 2026-04-27

---

## 1. Patrón: FM RFC como fachada de clases OO (Mulesoft/Salesforce)

### Cuándo usar
Cuando Mulesoft o Salesforce necesitan consumir lógica SAP via RFC.

### Arquitectura
```
Salesforce → Mulesoft (JCo/RFC) → ZFM_* (fachada) → ZCL_* (orquestador OO)
                                       │                    ├─ ZIF_*_DAO → ZCL_*_DAO
                                       │                    └─ ZIF_*_CHECKER → ZCL_*_CHECKER
                                       └─ ET_MESSAGES (BAPIRET2) para errores
```

### Reglas
- El FM solo instancia la clase y delega. Cero lógica de negocio en el FM.
- FM debe ser Remote-Enabled Module.
- En pestaña Tables usar LIKE (no TYPE con tipo tabla) — estándar SAP para RFC.
- Catch cx_root en el FM para que errores inesperados no rompan la conexión RFC.
- Siempre retornar ET_MESSAGES tipo BAPIRET2 para comunicar errores al consumidor.

### Ejemplo real: ZFM_SD_GET_MATERIAL_STOCK
```abap
FUNCTION zfm_sd_get_material_stock.
  DATA lo_query TYPE REF TO zif_sd_stock_query.
  TRY.
      lo_query = NEW zcl_sd_stock_query( ).
      et_plant_stock[] = lo_query->get_stock_by_plant(
        EXPORTING iv_matnr = iv_matnr  iv_bukrs = iv_bukrs
        IMPORTING ev_matnr_desc = ev_matnr_desc
                  et_messages   = et_messages[] ).
    CATCH cx_root INTO DATA(lx_error).
      APPEND VALUE bapiret2( type = 'E' message = lx_error->get_text( ) )
        TO et_messages[].
  ENDTRY.
ENDFUNCTION.
```

---

## 2. Patrón: Quotation Create/Change desde Salesforce

### Flujo Create (ZSD_QUOTATION_SALSFRC_CREATE)
```
Salesforce → Mulesoft → FM RFC
  → ZCL_SD_QUOTATION_VALIDATOR (valida datos de entrada)
  → ZCL_SD_DATA_CONVERTER (convierte formatos SF→SAP)
  → ZCL_SD_SALESFORCE_ID_MANAGER (gestiona IDs SF↔SAP)
  → ZCL_SD_BAPI_WRAPPER (encapsula BAPI_CUSTOMERQUOTATION_CREATEFROMDATA2)
  → ZCL_SD_SF_ID_REPOSITORY_DB (persiste relación SF ID ↔ SAP VBELN)
```

### Reglas de integración Salesforce
- Salesforce IDs son alfanuméricos de 18 caracteres — almacenar en campo CHAR18 o tabla Z.
- Siempre validar datos ANTES de llamar la BAPI — los mensajes de error de BAPIs SAP no son user-friendly para Salesforce.
- Mapeo de campos SF→SAP debe estar en una clase separada (ZCL_SD_DATA_CONVERTER), no hardcodeado en el FM.

---

## 3. Patrón: Middleware CRM ↔ ECC (BTMBDOC)

### Cadena de llamadas real (descubierta en BZN)
```
Middleware
  → Z_FM_SE_CRM_DWNLD_BTMBDOC_VAL   (wrapper Z con flag de procesamiento)
    → CRM_DOWNLOAD_BTMBDOC_VAL       (estándar SAP — validación)
      → ZCRM_DOWNLOAD_BTMBDOC_VAL    (copia Z con lock custom 60 seg)
        → ZCRM_DOWNLOAD_BTMBDOC      (copia Z del estándar con cambios)
```

### Trampas conocidas
- **Flag de procesamiento**: ZGM_PROC_DOC_LOG puede quedar con `processing = true` si hay error antes del cleanup. Bloquea reintentos.
- **Message type mapping**: FM Z custom (`ZCRM_MSG_TYPE_MAPPING_IN2OUT`) puede mapear incorrectamente → process mode incorrecto → CRM_ORDER_MAINTAIN falla.
- **Lock custom**: 12 reintentos × 5 seg = 60 seg. Si sigue lockeado, continúa SIN error → puede causar fallo posterior.
- **Desalineamiento de estructuras**: BAD_BUS_TRANSN_MESSAGE puede tener diferente cantidad de componentes entre ECC y CRM si los SP no están alineados.

### Reglas para análisis de middleware
1. Siempre verificar TODAS las capas Z — no asumir que solo hay 2 niveles.
2. Verificar tabla ZGM_PROC_DOC_LOG para flags de procesamiento stuck.
3. Comparar niveles de SP de componentes CRM_MIDDLEWARE y BBPCRM entre sistemas.
4. Usar MCP con conexión a BZN para leer código CRM directamente.

---

## 4. Patrón: Enhancement en código estándar (TMS/Delivery)

### Cuándo usar
Cuando TMS (Transportation Management System) envía datos a SAP y se necesita mapear campos custom.

### Ejemplo real: CHG0432318 — Conestoga Equipment Type
```
TMS → PI/PO → SAP (Inbound IDoc/RFC)
  → Enhancement ZSDE_TMS2SAP_DELIVERY_DATA en MV50AFZ1
    → Si VSBED = 'ZZ' (Conestoga) → actualizar ZZEQUIPE_TYPE en LIKP
```

### Reglas
- Usar variable global en TOP include como buffer entre pantalla y estructura LIKP.
- En enhancements explícitos (ENHO/XH), verificar nombres exactos de work areas en scope.
- Lógica condicional: solo actuar cuando el valor específico viene de TMS, no modificar para otros tipos.
- Search term obligatorio para rastrear cambios del CR.

---

## 5. Patrón: Workflow → BAPI con protección de lock

### Cuándo usar
Cuando un workflow task ejecuta un FM que llama BAPIs de cambio.

### Ejemplo real: CHG0436393 — ZSD_PPD_REJ_UPDATE
```
Workflow PPD Approval
  → ZSD_PPD_REJ_UPDATE
    → ENQUEUE_EVVBAKE (con reintentos)
    → BAPI_CUSTOMERQUOTATION_CHANGE
    → BAPI_TRANSACTION_COMMIT
    → DEQUEUE_EVVBAKE (en ambos caminos)
```

### Reglas
- Siempre ENQUEUE antes de BAPI de cambio.
- Reintentos: 24 × 5 seg = 2 min es un buen default para workflows.
- DEQUEUE en AMBOS caminos (éxito y error).
- `sy-msgv1` contiene el usuario que tiene el lock en FOREIGN_LOCK.
- Para escenario workflow: usar MESSAGE TYPE 'E' para que el WF engine ponga el work item en estado ERROR (reiniciable desde SWPR).
- Para escenario CPQ: retornar error en TA_BAPIRET.
