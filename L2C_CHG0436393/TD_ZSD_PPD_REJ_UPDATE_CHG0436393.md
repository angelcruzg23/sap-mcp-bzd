# Technical Design — CHG0436393
## Enqueue Lock Validation for ZSD_PPD_REJ_UPDATE

| Campo | Valor |
|-------|-------|
| Change Request | CHG0436393 |
| Objeto | ZSD_PPD_REJ_UPDATE (FM) |
| Grupo de Funciones | ZSD_PPD |
| Paquete | ZSD_ORDER |
| Search Term | CHG0436393 |
| Autor | Kiro AI Assistant |
| Fecha | 2026-04-21 |

---

## 1. Objetivo

Agregar validación de bloqueo (enqueue) antes de llamar a `BAPI_CUSTOMERQUOTATION_CHANGE` dentro de la FM `ZSD_PPD_REJ_UPDATE`. Si la quotation está bloqueada por otro usuario, el sistema esperará hasta 2 minutos con reintentos cada 5 segundos antes de abortar.

## 2. Objetos Modificados

| Objeto | Tipo | Acción | Transporte |
|--------|------|--------|------------|
| ZSD_PPD_REJ_UPDATE | FUGR/FF | Modificar | Pendiente |

## 3. Firma de la FM (sin cambios)

```abap
FUNCTION ZSD_PPD_REJ_UPDATE
  IMPORTING
    I_CPQ TYPE CHAR01 OPTIONAL
  EXPORTING
    UPDATE_FAILED TYPE C
    EMAIL TYPE AD_SMTPADR
  TABLES
    T_VBAP LIKE VBAP OPTIONAL
    TA_AGENTS LIKE ZFI_AGENT_STRUCT OPTIONAL
    TA_BAPIRET TYPE BAPIRET2_T OPTIONAL.
```

La firma no se modifica. Los parámetros existentes `UPDATE_FAILED`, `EMAIL` y `TA_BAPIRET` se reutilizan para comunicar el error de lock.

## 4. Variables Nuevas

```abap
CONSTANTS: lc_max_retries TYPE i VALUE 24,    "24 retries x 5 sec = 120 sec (2 min)
           lc_wait_secs   TYPE i VALUE 5.     "Seconds between retries
DATA: lv_retry_count   TYPE i,
      lv_lock_acquired TYPE abap_bool,
      lv_lock_user     TYPE sy-uname.
```

## 5. Lógica de Enqueue (código nuevo)

### 5.1 Adquisición del Lock (antes de la BAPI)

Se inserta **después** del `EXPORT gv_flag_ppd TO MEMORY ID 'ZPPD_WF'` y **antes** de `CALL FUNCTION 'BAPI_CUSTOMERQUOTATION_CHANGE'`:

```abap
lv_retry_count   = 0.
lv_lock_acquired = abap_false.

DO lc_max_retries TIMES.
  CALL FUNCTION 'ENQUEUE_EVVBAKE'
    EXPORTING
      mode_vbak  = 'E'
      mandt      = sy-mandt
      vbeln      = i_salesorder
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  IF sy-subrc = 0.
    lv_lock_acquired = abap_true.
    EXIT.
  ENDIF.

  lv_retry_count = lv_retry_count + 1.
  lv_lock_user = sy-msgv1.

  IF lv_retry_count < lc_max_retries.
    WAIT UP TO lc_wait_secs SECONDS.
  ENDIF.
ENDDO.
```

### 5.2 Manejo de Lock No Adquirido

Si después de 24 reintentos no se obtiene el lock:

- **Escenario CPQ** (`I_CPQ = abap_true`): Se agrega mensaje de error a `TA_BAPIRET` y se hace `RETURN`.
- **Escenario Workflow** (no CPQ): Se envía email de notificación al último agente aprobador (reutilizando el patrón existente de la FM), se marca `UPDATE_FAILED = 'X'`, se popula `EMAIL` y se hace `RETURN`.

### 5.3 Liberación del Lock (después de la BAPI)

Se agrega `DEQUEUE_EVVBAKE` en **ambos** caminos:

- **BAPI exitosa**: después de `BAPI_TRANSACTION_COMMIT`, antes de la lógica de email de aprobación.
- **BAPI con error**: al inicio del bloque ELSE (antes de la lógica de email de error existente).

```abap
CALL FUNCTION 'DEQUEUE_EVVBAKE'
  EXPORTING
    mode_vbak = 'E'
    mandt     = sy-mandt
    vbeln     = i_salesorder.
```

## 6. Diagrama de Flujo

```
┌─────────────────────────────┐
│ Preparar estructuras BAPI   │
│ (código existente)          │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ EXPORT gv_flag_ppd          │
│ (código existente)          │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ ★ NUEVO: ENQUEUE_EVVBAKE   │
│   DO 24 TIMES              │
│     Si lock OK → EXIT       │
│     Si FOREIGN_LOCK →       │
│       WAIT 5 sec, retry     │
│   ENDDO                     │
└──────────┬──────────────────┘
           │
     ┌─────┴─────┐
     │            │
  Lock OK    Lock FAILED
     │            │
     ▼            ▼
┌──────────┐  ┌──────────────────┐
│ BAPI     │  │ UPDATE_FAILED='X'│
│ CHANGE   │  │ Email / BAPIRET  │
└────┬─────┘  │ RETURN           │
     │        └──────────────────┘
  ┌──┴──┐
  │     │
 OK   Error
  │     │
  ▼     ▼
┌────┐ ┌────┐
│CMIT│ │    │
└──┬─┘ └──┬─┘
   │      │
   ▼      ▼
┌─────────────────────────────┐
│ ★ NUEVO: DEQUEUE_EVVBAKE   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Lógica existente            │
│ (emails, flags, etc.)       │
└─────────────────────────────┘
```

## 7. Escenarios de Prueba

| # | Escenario | Resultado Esperado |
|---|-----------|-------------------|
| 1 | Quotation libre, sin lock | Lock adquirido al primer intento, BAPI ejecuta normal |
| 2 | Quotation bloqueada, se libera antes de 2 min | Lock adquirido después de N reintentos, BAPI ejecuta normal |
| 3 | Quotation bloqueada > 2 min, escenario WF | UPDATE_FAILED='X', email enviado al agente, RETURN |
| 4 | Quotation bloqueada > 2 min, escenario CPQ | Mensaje error en TA_BAPIRET, RETURN |
| 5 | BAPI falla después de lock adquirido | DEQUEUE ejecutado, flujo de error existente continúa |
| 6 | BAPI exitosa | DEQUEUE ejecutado, COMMIT + email de aprobación |

## 8. Notas de Implementación

- El `WAIT UP TO 5 SECONDS` bloquea el work process. Con máximo 2 minutos es aceptable en contexto de workflow batch.
- `ENQUEUE_EVVBAKE` es el objeto de bloqueo estándar SAP para documentos de venta (VBAK/VBAP).
- `sy-msgv1` contiene el nombre del usuario que tiene el lock cuando ocurre `FOREIGN_LOCK`.
- No se modifica la firma de la FM, por lo que no hay impacto en los llamadores existentes.
- El `DEQUEUE_EVVBAKE` se ejecuta en ambos caminos (éxito/error) para garantizar que el lock se libere siempre.
