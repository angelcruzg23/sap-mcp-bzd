# Análisis Flujo ECC → CRM — Conclusiones para revisión

**Fecha:** 24 Abril 2026  
**Error:** BDoc encolado en status F0x — CRM_ORDER msg 11 + SMW3 msg 18  
**GUID afectado:** 005056B8EDFB1FD18...

---

## Cadena real de llamadas (descubierta conectándonos a BZN)

```
Middleware
  → Z_FM_SE_CRM_DWNLD_BTMBDOC_VAL   (grupo: Z_SE_MIDDLEWARE)
    → CRM_DOWNLOAD_BTMBDOC_VAL       (estándar SAP)
      → ZCRM_DOWNLOAD_BTMBDOC_VAL    (copia Z con lock custom)
        → ZCRM_DOWNLOAD_BTMBDOC      (copia Z del estándar con cambios)
```

**Son 4 capas, no 2 como se pensaba inicialmente.**

---

## 3 hallazgos para revisar el lunes

### 1. Bug en Z_FM_SE_CRM_DWNLD_BTMBDOC_VAL — Flag de procesamiento no se limpia en error

Cuando el FM estándar falla, el RAISE sale del FM **antes** de limpiar el flag en `ZGM_PROC_DOC_LOG`. El documento queda marcado como `processing = true` y puede bloquear reintentos.

**Acción:** Revisar tabla `ZGM_PROC_DOC_LOG` para el object_id del documento afectado. Si tiene `processing = true`, limpiarlo manualmente.

### 2. ZCRM_DOWNLOAD_BTMBDOC usa FM Z custom para message type mapping

En el paso 80, la copia Z llama `ZCRM_MSG_TYPE_MAPPING_IN2OUT` en vez del estándar `CRM_MSG_TYPE_MAPPING_IN2OUT`. Si este FM no mapea correctamente el message type, el process mode queda mal y `CRM_ORDER_MAINTAIN` puede fallar.

**Acción:** Leer `ZCRM_MSG_TYPE_MAPPING_IN2OUT` y comparar con el estándar.

### 3. ZCRM_DOWNLOAD_BTMBDOC_VAL tiene lock custom de 60 segundos

Para Service Confirmations, intenta 12 veces con 5 segundos de espera verificar si el documento está lockeado. Si después de 60 segundos sigue lockeado, **continúa sin error** — lo que puede causar que `CRM_ORDER_MAINTAIN` falle con el error 11 porque el documento está lockeado por otro proceso.

**Acción:** Verificar si el documento del error es un Service Confirmation y si hay procesos concurrentes que lo lockean.

---

### 4. NUEVO — Desalineamiento de estructura BAD_BUS_TRANSN_MESSAGE entre ECC y CRM

La estructura principal del BDoc `BAD_BUS_TRANSN_MESSAGE` tiene diferente cantidad de componentes:

| Sistema | Componentes |
|---------|-------------|
| ECC (BZA client 130) | **109 / 213** |
| CRM (BZC client 100) | **106 / 211** |

**Campos que existen en ECC pero NO en CRM:**
- `PS_DM_EA_EXT_H` — relacionado con Dispute Management / EA (Extended Analytics)
- `TEXT_GEN` (tipo `BAD_TEXT_GEN_MESS_T`) — textos genéricos del BDoc

Esto indica que ECC está en un nivel de SP/EHP más alto que CRM para el componente de middleware. Cuando ECC empaqueta el BDoc con estos campos extra y CRM intenta deserializarlo, puede causar:
- Error de mapeo si el middleware no puede ignorar los campos desconocidos
- Corrupción del BDoc si los offsets de las estructuras se desplazan
- El error CRM_ORDER 11 si los datos llegan mal mapeados al `CRM_ORDER_MAINTAIN`

**Acción:** Verificar en transacción SPAM/SAINT los niveles de SP de los componentes `CRM_MIDDLEWARE` y `BBPCRM` en ambos sistemas. Alinear los Support Packages o aplicar las notas SAP correspondientes para que `BAD_BUS_TRANSN_MESSAGE` tenga la misma definición en ambos lados.

---

## Descartados

- **BAdI CRM_BTX_EXTENSIONS:** No tiene implementaciones Z en BZN
- **Diferencia de interfaces entre FMs:** Las interfaces están correctamente alineadas entre las 4 capas
- **CRM_ORDER_DELETE (paso 70):** No es la causa — solo aplica si hay objetos a borrar
- **CRM_DOWNLOAD_BTMBDOC_MAPPER:** El mapeo de DOC_FLOW está presente y activo (`PERFORM map_doc_flow_2_api`)

---

## Conexión BZN configurada

Se configuró acceso MCP al sistema CRM BZN (lfh02a09ld075.holcimbp.net:8040, client 100, user AHERNA11) para poder leer código fuente directamente. Está listo para continuar el análisis el lunes.
