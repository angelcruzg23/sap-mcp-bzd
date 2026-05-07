---
inclusion: manual
---
# ABAP Lessons Learned — Bitácora de Aprendizajes

## Última actualización: 2026-05-06

---

## Lección 1: EHP8 cambia el momento de asignación de SCOMNO en SAPconnect
- **Contexto**: Bug en ZSDR_DAILY_INVOICE_REPORT — facturas transmitidas aparecían como "Failed"
- **Causa raíz**: Después de EHP8, SAPconnect asigna SCOMNO inmediatamente al transmitir. El código hacía `DELETE ltt_sood WHERE NOT scomno IS INITIAL`, eliminando los registros exitosos.
- **Solución validada**: Switch por fecha con TVARVC (`ZSD_DAILY_INV_EHP8_DATE`). Antes de la fecha de corte → comportamiento original. Después → omite el DELETE.
- **Patrón reutilizable**: Siempre usar TVARVC como switch de fecha cuando un upgrade cambia comportamiento. Fallback seguro: `'99991231'` (comportamiento original).

## Lección 2: EHP8 agrega authority checks más estrictos en FMs estándar
- **Contexto**: ZSDR_ANOKA_REPORT_BAK_N — error "No authorization for W56LE601004 in plant 3096"
- **Causa raíz**: `MD_STOCK_REQUIREMENTS_LIST_API` en EHP8 valida `M_MTDI_ORG` internamente. El bloque `IF sy-subrc <> 0` estaba vacío.
- **Solución validada**: Authority check preventivo ANTES de llamar al FM estándar. Si falla → `CONTINUE` (skip silencioso).
- **Patrón reutilizable**: Cuando un FM estándar hace authority checks internos, replicar el check ANTES para controlar el flujo.

## Lección 3: ENQUEUE antes de BAPIs de cambio en contexto de workflow
- **Contexto**: CHG0436393 — ZSD_PPD_REJ_UPDATE llamaba BAPI_CUSTOMERQUOTATION_CHANGE sin verificar lock
- **Solución validada**: ENQUEUE_EVVBAKE con reintentos (24 × 5 seg = 2 min máximo). DEQUEUE en ambos caminos.
- **Patrón reutilizable**: Siempre ENQUEUE antes de BAPIs de cambio. `sy-msgv1` contiene el usuario que tiene el lock en FOREIGN_LOCK.
- **Nota**: No usar DO...ENDDO + EXIT para loops con condición de salida. Preferir WHILE con condición explícita.

## Lección 4: Flujo CRM↔ECC tiene más capas de las documentadas
- **Contexto**: BDoc encolado en status F0x — análisis del flujo ECC→CRM
- **Descubrimiento**: La cadena real tiene 4 capas (no 2): Z_FM_SE_CRM_DWNLD_BTMBDOC_VAL → CRM_DOWNLOAD_BTMBDOC_VAL → ZCRM_DOWNLOAD_BTMBDOC_VAL → ZCRM_DOWNLOAD_BTMBDOC
- **Patrón reutilizable**: En análisis de middleware CRM, siempre verificar TODAS las capas Z. No asumir que solo hay 2 niveles.

## Lección 5: Arithmetic overflow en características de clasificación
- **Contexto**: Error ARITHMETIC_ERRORS en quotation 10195339, característica ZZPLPOD_UMREZ
- **Causa raíz**: Característica configurada con 5 dígitos (máx 99,999) pero el valor era 150,000 (6 dígitos).
- **Solución**: Ampliar longitud en CT04 (de 5 a 8 dígitos). Es cambio de Customizing, no de código.
- **Patrón reutilizable**: Cuando hay ARITHMETIC_ERRORS en clasificación (LCUBXFOC), verificar la longitud de la característica en CT04 vs el valor que se intenta asignar.

## Lección 6: Enhancement en includes estándar — verificar scope de variables
- **Contexto**: CHG0432318 — Conestoga equipment type, enhancement en MV50AFZ1
- **Aprendizaje**: En enhancements explícitos (ENHO/XH), las variables en scope dependen del código existente. Verificar los nombres exactos de las work areas disponibles dentro del enhancement.
- **Patrón**: Para campos custom en LIKP/VBAK, usar variable global en TOP include como buffer entre pantalla y estructura.

## Lección 7: ABAP Unit no detecta tests en reports
- **Síntoma**: `sap_run_abap_unit` retorna "Does not Contain any Test Classes"
- **Causa raíz**: El endpoint ADT de ABAP Unit para reports tipo executable program NO escanea clases locales FOR TESTING
- **Solución**: Usar clases globales (ZCL_*) para tests. ABAP Unit via ADT funciona correctamente con `/sap/bc/adt/oo/classes/{classname}`

## Lección 8: FOR ALL ENTRIES exige tipos idénticos (CHG0434843)
- **Causa raíz**: SAP valida la cadena de referencia completa. Tipos que resuelven al mismo tipo técnico pero con data elements diferentes son rechazados.
- **Solución**: Usar `TYPE tabla_db-campo` (referencia directa al campo de la tabla de BD), NO data elements sueltos.

## Lección 9: La activación ADT no es un syntax check completo (CHG0434843)
- **Causa raíz**: La activación vía ADT REST API puede pasar objetos con errores de sintaxis, especialmente FMs dentro de function groups.
- **Solución**: SIEMPRE ejecutar `sap_syntax_check` después de activar. No confiar en que "activó = compila".

## Lección 10: Estructura XML del CTS — tag correcto es tm:abap_object (2026-05-05)
- **Causa raíz**: Los objetos de una task usan el tag `tm:abap_object` (con guión bajo), NO `tm:abapObject`.
- **Solución**: Usar `sap_get_transport_xml_raw` para ver el XML crudo cuando `sap_get_transport_details` no muestra objetos.

---

## Plantilla para nuevas entradas
```
## Lección N: [título corto]
- **Contexto**: [qué se estaba haciendo]
- **Causa raíz**: [por qué pasó]
- **Solución**: [qué se hizo]
- **Patrón reutilizable**: [qué aplicar en el futuro]
```
