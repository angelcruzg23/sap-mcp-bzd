# Amrize BP — Estándares de Codificación

## OBLIGATORIO
- Toda clase de negocio debe tener una clase de prueba _TEST con ABAP Unit
- Métodos públicos deben tener documentación ABAP Doc ("! descripción)
- No se permiten SELECTs dentro de LOOPs (usar FOR ALL ENTRIES o JOIN)
- Usar sintaxis moderna ABAP 7.5: VALUE, FILTER, REDUCE en lugar de LOOP clásico cuando aplique
- Manejo explícito de excepciones: nunca suprimir con EXCEPTIONS others = 0 si no se maneja
- Toda tabla interna debe declararse con TYPE TABLE OF [TIPO_COMPLETO]
- Usar ENQUEUE/DEQUEUE antes de llamar BAPIs de cambio (BAPI_CUSTOMERQUOTATION_CHANGE, BAPI_SALESORDER_CHANGE, etc.) — validado en CHG0436393
- En FMs RFC-enabled, usar LIKE en pestaña Tables (no TYPE con tipo tabla) — estándar SAP para RFC

## PROHIBIDO
- No usar FIELD-SYMBOLS sin tipo (FIELD-SYMBOL <fs> — siempre tipar)
- No usar SELECT * — siempre listar campos explícitamente
- No modificar tablas SAP estándar directamente (usar Enhancement o BAdI)
- No usar MOVE-CORRESPONDING masivo sin entender qué mueve
- No hard-codear mandante: usar SY-MANDT
- No usar COMMIT WORK en lógica de negocio (solo en el control superior del proceso o usar BAPI_TRANSACTION_COMMIT)
- No usar DO...ENDDO + EXIT para loops con condición de salida — usar WHILE con condición explícita (lección del debugging CHG0436393: EXIT es ambiguo en call stacks profundos como workflows)
- No usar FORMs (PERFORM/FORM) en código nuevo — usar métodos de clase

## PATRONES VALIDADOS EN PRODUCCIÓN

### Switch por fecha con TVARVC
Para proteger comportamiento legacy después de upgrades (ej: EHP8):
```abap
SELECT SINGLE low INTO lv_cutoff
  FROM tvarvc
  WHERE name = 'ZSD_DAILY_INV_EHP8_DATE'
    AND type = 'P'.
IF sy-subrc <> 0.
  lv_cutoff = '99991231'.  " Fallback seguro: comportamiento original
ENDIF.
IF so_erdat-low < lv_cutoff.
  " Lógica pre-EHP8
ENDIF.
```

### Enqueue con reintentos antes de BAPI
```abap
WHILE lv_lock_acquired = abap_false AND lv_retry_count < lc_max_retries.
  CALL FUNCTION 'ENQUEUE_EVVBAKE'
    EXPORTING vbeln = iv_vbeln
    EXCEPTIONS foreign_lock = 1 OTHERS = 2.
  IF sy-subrc = 0.
    lv_lock_acquired = abap_true.
  ELSE.
    lv_retry_count = lv_retry_count + 1.
    WAIT UP TO 5 SECONDS.
  ENDIF.
ENDWHILE.
```

### MESSAGE TYPE 'E' para integración con Workflow
Cuando una FM es llamada desde un workflow task y necesita que el paso quede en ERROR (reiniciable desde SWPR):
```abap
MESSAGE e000(zsd) WITH 'Quotation' iv_vbeln 'locked by' lv_lock_user.
" El WF engine captura la excepción y pone el work item en estado ERROR
```

### Authority check preventivo
Cuando se llama un FM estándar que hace authority checks internos (ej: MD_STOCK_REQUIREMENTS_LIST_API), replicar el check ANTES para evitar errores silenciosos:
```abap
AUTHORITY-CHECK OBJECT 'M_MTDI_ORG'
  ID 'MDAKT' FIELD 'A'
  ID 'WERKS' FIELD wa_vbap-werks
  ID 'DISPO' DUMMY.
IF sy-subrc NE 0.
  CONTINUE.  " Saltar registro sin error visible
ENDIF.
```

## LIMITACIONES CONOCIDAS DE ABAP 7.50 SP32
- `VALUE #()` con `LET` + table expression `OPTIONAL` no es estable — usar LOOP clásico con READ TABLE como fallback
- EISBE (stock de seguridad) NO es campo de MARD — es de MARC. No incluir en SELECTs a MARD.

## LECCIONES APRENDIDAS

### FOR ALL ENTRIES exige tipos idénticos (CHG0434843)
Al usar `FOR ALL ENTRIES IN @lt_tabla WHERE campo = @lt_tabla-campo`, los campos de la estructura auxiliar deben tiparse con `TYPE tabla_db-campo` (referencia directa al campo de la tabla de BD), NO con data elements sueltos (`TYPE fcurr`, `TYPE tcurr`).
Aunque ambos resuelvan al mismo tipo técnico, SAP valida la cadena de referencia completa y rechaza tipos que no sean idénticos.
```abap
" MAL — puede dar error de tipos incompatibles
TYPES: BEGIN OF lty_lookup,
         fcurr TYPE fcurr,    " data element suelto
         tcurr TYPE tcurr,    " data element suelto
       END OF lty_lookup.

" BIEN — tipos idénticos a la tabla de BD
TYPES: BEGIN OF lty_lookup,
         fcurr TYPE tcurr-fcurr,  " referencia directa al campo
         tcurr TYPE tcurr-tcurr,  " referencia directa al campo
         gdatu TYPE tcurr-gdatu,  " referencia directa al campo
       END OF lty_lookup.
```

### La activación ADT no es un syntax check completo (CHG0434843)
La activación vía ADT REST API (`/sap/bc/adt/activation`) puede pasar objetos con errores de sintaxis, especialmente FMs dentro de function groups. No confiar en que "activó = compila". Siempre ejecutar syntax check explícito después de activar, o antes de subir si el MCP lo soporta.

## RECOMENDADO
- Preferir CL_SALV_TABLE sobre el ALV clásico para reportes nuevos
- Preferir BAdIs sobre User Exits para nuevas implementaciones
- Centralizar acceso a datos en clases DAO (Data Access Object) separadas
- FM como fachada de clases OO: el FM instancia la clase y delega (ver ZFM_SD_GET_MATERIAL_STOCK → ZCL_SD_STOCK_QUERY)

## PATRÓN: REFACTORIZACIÓN DE INCLUDES PROCEDURALES A OO TESTEABLE

Los includes de enhancement spots (como `ZI_SD_E_112_PLANT_DETERMINE`) operan sobre variables globales del programa (`vbak`, `vbap`, `xvbpa`, `cvbap`, `*vbap`) y son imposibles de testear directamente.

### Estrategia validada (SD_E_112, 2026-05-05)
1. **El include se convierte en fachada** (~30 líneas): mapea globales → tipos propios → llama al orquestador → escribe resultados de vuelta
2. **Toda la lógica va al orquestador** (`ZCL_SD_*`): recibe tipos propios, sin referencias a globales del programa
3. **Tipos propios desacoplan del contexto**: definir `ty_vbak_relevant`, `ty_vbap_relevant` con solo los campos necesarios — permite construir datos de test sin poblar estructuras SAP completas
4. **El resultado se retorna explícitamente**: `ty_result` con flags (`plant_determined`, `warning_no_mard`) y mensajes — nunca efectos laterales ocultos

```abap
" Include refactorizado — solo fachada
DATA(ls_vbak_rel) = VALUE zcl_sd_plant_determinator=>ty_vbak_relevant(
  auart = vbak-auart  vkorg = vbak-vkorg  vtweg = vbak-vtweg ).
DATA(lo_det) = NEW zcl_sd_plant_determinator( ).
lo_det->determine_and_apply(
  EXPORTING is_vbak = ls_vbak_rel ...
  CHANGING  cs_vbap = ls_vbap_rel ... ).
IF ls_result-plant_determined = abap_true.
  vbap-werks = ls_vbap_rel-werks.  " escribir de vuelta a global
ENDIF.
```

### Orden de deploy para refactorizaciones de este tipo
1. Interfaces (`ZIF_*`) — sin dependencias, primero
2. Implementaciones DAO y checkers (`ZCL_*_DAO`, `ZCL_*_CHECKER`)
3. Orquestador (`ZCL_*_DETERMINATOR` o similar)
4. Clase de tests (`ZCL_*_TEST`) → ejecutar ABAP Unit antes de tocar el include
5. Include refactorizado — último, cuando los tests pasan
