---
inclusion: fileMatch
fileMatchPattern: "**/*.abap"
---
# ABAP Lessons Learned — Bitácora de Aprendizajes

## Última actualización: 2026-04-27

---

## Sesión 2026-04-27: Consolidación de 2 meses de aprendizajes

### Lección 1: EHP8 cambia el momento de asignación de SCOMNO en SAPconnect
- **Contexto**: Bug en ZSDR_DAILY_INVOICE_REPORT — facturas transmitidas aparecían como "Failed"
- **Causa raíz**: Después de EHP8, SAPconnect asigna SCOMNO inmediatamente al transmitir. El código hacía `DELETE ltt_sood WHERE NOT scomno IS INITIAL`, eliminando los registros exitosos.
- **Solución validada**: Switch por fecha con TVARVC (`ZSD_DAILY_INV_EHP8_DATE`). Antes de la fecha de corte → comportamiento original. Después → omite el DELETE.
- **Patrón reutilizable**: Siempre usar TVARVC como switch de fecha cuando un upgrade cambia comportamiento. Fallback seguro: `'99991231'` (comportamiento original).

### Lección 2: EHP8 agrega authority checks más estrictos en FMs estándar
- **Contexto**: ZSDR_ANOKA_REPORT_BAK_N — error "No authorization for W56LE601004 in plant 3096"
- **Causa raíz**: `MD_STOCK_REQUIREMENTS_LIST_API` en EHP8 valida `M_MTDI_ORG` internamente. El bloque `IF sy-subrc <> 0` estaba vacío, dejando que el mensaje de error se filtrara al status bar.
- **Solución validada**: Authority check preventivo ANTES de llamar al FM estándar. Si falla → `CONTINUE` (skip silencioso, consistente con otros checks del mismo programa).
- **Patrón reutilizable**: Cuando un FM estándar hace authority checks internos, replicar el check ANTES para controlar el flujo. Usar `AUTHORITY-CHECK OBJECT` con los mismos campos que el FM usa internamente.

### Lección 3: ENQUEUE antes de BAPIs de cambio en contexto de workflow
- **Contexto**: CHG0436393 — ZSD_PPD_REJ_UPDATE llamaba BAPI_CUSTOMERQUOTATION_CHANGE sin verificar lock
- **Causa raíz**: Si la quotation estaba abierta en VA22/VA23, la BAPI podía fallar o generar inconsistencias
- **Solución validada**: ENQUEUE_EVVBAKE con reintentos (24 × 5 seg = 2 min máximo). DEQUEUE en ambos caminos (éxito y error).
- **Patrón reutilizable**: Siempre ENQUEUE antes de BAPIs de cambio. Usar WHILE/DO con reintentos y WAIT UP TO. `sy-msgv1` contiene el usuario que tiene el lock en FOREIGN_LOCK.
- **Nota**: No usar DO...ENDDO + EXIT para loops con condición de salida. EXIT es ambiguo en call stacks profundos (workflows). Preferir WHILE con condición explícita o DO N TIMES.

### Lección 4: Flujo CRM↔ECC tiene más capas de las documentadas
- **Contexto**: BDoc encolado en status F0x — análisis del flujo ECC→CRM
- **Descubrimiento**: La cadena real tiene 4 capas (no 2): Z_FM_SE_CRM_DWNLD_BTMBDOC_VAL → CRM_DOWNLOAD_BTMBDOC_VAL → ZCRM_DOWNLOAD_BTMBDOC_VAL → ZCRM_DOWNLOAD_BTMBDOC
- **Hallazgos clave**:
  - Flag de procesamiento en ZGM_PROC_DOC_LOG no se limpia en error → bloquea reintentos
  - FM Z custom para message type mapping puede causar process mode incorrecto
  - Lock custom de 60 seg que continúa sin error puede causar fallo en CRM_ORDER_MAINTAIN
  - Desalineamiento de estructura BAD_BUS_TRANSN_MESSAGE entre ECC y CRM (109 vs 106 componentes)
- **Patrón reutilizable**: En análisis de middleware CRM, siempre verificar TODAS las capas Z. No asumir que solo hay 2 niveles.

### Lección 5: Arithmetic overflow en características de clasificación
- **Contexto**: Error ARITHMETIC_ERRORS en quotation 10195339, característica ZZPLPOD_UMREZ
- **Causa raíz**: Característica configurada con 5 dígitos (máx 99,999) pero el valor era 150,000 (6 dígitos). Overflow al convertir de flotante a packed.
- **Solución**: Ampliar longitud en CT04 (de 5 a 8 dígitos). Es cambio de Customizing, no de código.
- **Patrón reutilizable**: Cuando hay ARITHMETIC_ERRORS en clasificación (LCUBXFOC), verificar la longitud de la característica en CT04 vs el valor que se intenta asignar. El error está en la configuración, no en el código.

### Lección 6: Enhancement en includes estándar — verificar scope de variables
- **Contexto**: CHG0432318 — Conestoga equipment type, enhancement en MV50AFZ1
- **Aprendizaje**: En enhancements explícitos (ENHO/XH), las variables en scope dependen del código existente. Antes de implementar, verificar los nombres exactos de las work areas disponibles dentro del enhancement actual en el sistema.
- **Patrón**: Para campos custom en LIKP/VBAK, usar variable global en TOP include como buffer entre pantalla y estructura.

---

## Sesión 2026-04-06: ZDUMP_CONTEXT_4_CLAUDE testing

### Lección 7: ABAP Unit no detecta tests en reports
- **Síntoma**: `sap_run_abap_unit` contra `/sap/bc/adt/programs/programs/zdump_context_runner` retorna "Does not Contain any Test Classes"
- **Causa raíz**: El endpoint ADT de ABAP Unit para reports tipo executable program NO escanea clases locales FOR TESTING
- **Solución**: Usar clases globales (ZCL_*) para tests. ABAP Unit via ADT funciona correctamente con `/sap/bc/adt/oo/classes/{classname}`

### Lección 8: Parámetro source_code requerido en sap_create_program
- **Síntoma**: `sap_create_program` falla con "Input validation error: 'source_code' is a required property"
- **Solución**: Siempre pasar source_code al crear programas — no se puede crear programa vacío

### Lección 9: Tablas generadas no encontradas via ADT
- **Síntoma**: `sap_get_table_definition` para KOTG504 retorna 404
- **Causa raíz**: KOTG504 es tabla de condiciones generada dinámicamente, el endpoint ADT no la encuentra
- **Workaround**: Usar SELECT directo a DD03L dentro del programa ABAP

---

## Plantilla para nuevas entradas
<!--
### Lección N: [título corto]
- **Contexto**: [qué se estaba haciendo]
- **Causa raíz**: [por qué pasó]
- **Solución**: [qué se hizo]
- **Patrón reutilizable**: [qué aplicar en el futuro]
-->
