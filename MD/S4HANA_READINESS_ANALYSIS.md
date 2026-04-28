# Análisis S/4HANA Readiness — ZSD_QUOTATION_SALSFRC_CREATE

## Información del objeto

| Campo | Valor |
|-------|-------|
| Nombre | ZSD_QUOTATION_SALSFRC_CREATE |
| Tipo | Function Module (RFC-enabled) |
| Grupo de funciones | ZSD_CPQ_INTERFACES |
| Paquete | ZSD_I_211 |
| Descripción | Customer Quotation: Create Customer Quotation |
| Líneas de código | ~280 |
| Sistema | BZD 130 |

## Dependencias detectadas

| Objeto | Tipo | Descripción |
|--------|------|-------------|
| ZCL_SD_ZFDC_CONTROLLER_ID | Clase | Controlador de ID Salesforce (duplicación) |
| ZCL_SD_GET_SHIPPING_POINT | Clase | Determinación de shipping point por planta |
| ZCL_SD_SFDC_PROCESSING_VOC | Clase | Procesamiento de texto VOC Salesforce |
| ZSD_SALESORD_SALSFRC_SIMULATE | FM | Simulación de orden de venta |
| BAPI_QUOTATION_CREATEFROMDATA2 | FM SAP | BAPI estándar de creación de cotización |
| BAPI_TRANSACTION_COMMIT | FM SAP | Commit de transacción |

---

## Hallazgos S/4HANA Readiness

### 🔴 CRÍTICO — Requiere cambio obligatorio

#### H-01: Estructuras BAPE_VBAK / BAPE_VBAP con offset hardcodeado

```abap
ls_extensionin-structure = 'BAPE_VBAK'.
ls_extensionin+30        = ls_bape_vbak.     " ← offset fijo
```

**Problema:** Se usa offset fijo (`+30`) para mover datos a la estructura BAPIPAREX. En S/4HANA, la estructura BAPE_VBAK puede cambiar de longitud si se agregan campos de extensión (ej: Business Partner). Un offset fijo es frágil y puede corromper datos.

**Riesgo:** Alto — corrupción silenciosa de datos en extensiones BAPI.

**Recomendación:** Usar asignación por componente o MOVE-CORRESPONDING a la parte VALUEPART de BAPIPAREX.

```abap
" Alternativa más segura
ls_extensionin-structure  = 'BAPE_VBAK'.
ls_extensionin-valuepart1 = ls_bape_vbak.
```

---

#### H-02: MOVE-CORRESPONDING masivo sin control

Se usa MOVE-CORRESPONDING en múltiples lugares sin validar qué campos se mueven:

```abap
MOVE-CORRESPONDING quotation_header_in TO ls_quot_head_in.    " línea ~95
MOVE-CORRESPONDING wa_return TO wa_e_return.                   " línea ~210
MOVE-CORRESPONDING wa_item TO wa_items.                        " línea ~225
MOVE-CORRESPONDING wa_schedules TO wa_schedule.                " línea ~231
MOVE-CORRESPONDING quotation_partners[] TO order_partners[].  " línea ~233
MOVE-CORRESPONDING ls_quot_head_in TO order_header_in.         " línea ~220
```

**Problema:** En S/4HANA, las estructuras estándar BAPI pueden tener campos nuevos o campos con longitud diferente (ej: MATNR de 18→40 chars). MOVE-CORRESPONDING moverá campos que coincidan por nombre, pero si la estructura destino no tiene el campo extendido, se trunca silenciosamente.

**Riesgo:** Medio-Alto — truncamiento de MATNR u otros campos extendidos.

**Recomendación:** Reemplazar con CORRESPONDING #( ) explícito y documentar qué campos se mapean. Mejor aún, crear un método de conversión explícito.

---

### 🟡 ADVERTENCIA — Revisar antes de migración

#### H-03: BAPI_QUOTATION_CREATEFROMDATA2 — verificar compatibilidad S/4

```abap
CALL FUNCTION 'BAPI_QUOTATION_CREATEFROMDATA2'
```

**Problema:** Esta BAPI sigue existiendo en S/4HANA, pero tiene cambios en el manejo de condiciones de precio. En S/4HANA, las condiciones se persisten en PRCD_ELEMENTS en lugar de KONV. Si el FM custom `ZSD_SALESORD_SALSFRC_SIMULATE` lee KONV internamente, fallará.

**Riesgo:** Medio — la BAPI en sí funciona, pero los FMs custom que la rodean pueden no.

**Recomendación:** Verificar que `ZSD_SALESORD_SALSFRC_SIMULATE` no lea KONV directamente. Analizar ese FM por separado.

---

#### H-04: SET/GET PARAMETER ID — patrón frágil

```abap
SET PARAMETER ID 'ZSD_SHIPPING_TYPE' FIELD ls_quot_head_in-ship_type.
SET PARAMETER ID 'ZSD_ENVIAR_IDOC' FIELD abap_true.
...
SET PARAMETER ID 'ZSD_ENVIAR_IDOC' FIELD abap_false.
...
SET PARAMETER ID 'ZSD_SHIPPING_TYPE' FIELD space.
```

**Problema:** SET/GET PARAMETER ID es un mecanismo de memoria de usuario (SPA/GPA). En S/4HANA con Fiori, los parámetros SPA/GPA no funcionan igual que en SAP GUI. Si este FM se llama desde un contexto Fiori o API, los parámetros no se propagan correctamente.

**Riesgo:** Medio — funciona en SAP GUI pero falla en contextos Fiori/API.

**Recomendación:** Pasar estos valores como parámetros explícitos del FM en lugar de usar memoria de usuario. Esto también mejora la testeabilidad.

---

#### H-05: BAPI_TRANSACTION_COMMIT sin parámetro WAIT

```abap
CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
```

**Problema:** En S/4HANA sobre HANA DB, las operaciones asíncronas son más rápidas. Sin el parámetro `WAIT = 'X'`, el commit puede no haberse completado cuando el código continúa, causando inconsistencias en lecturas posteriores.

**Riesgo:** Medio — posibles inconsistencias de datos en S/4HANA.

**Recomendación:**

```abap
CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
  EXPORTING
    wait = abap_true.
```

---

#### H-06: Tipos LIKE en lugar de TYPE en la firma del FM

```abap
VALUE(SALESDOCUMENTIN) LIKE BAPIVBELN-VBELN OPTIONAL
VALUE(QUOTATION_HEADER_IN) LIKE ZSD_BAPISDHD1
...
TABLES
  QUOTATION_ITEMS_IN LIKE ZST_SD_BAPISDITM OPTIONAL
```

**Problema:** `LIKE` referencia la definición en tiempo de ejecución del objeto del diccionario. En S/4HANA, si la estructura referenciada cambia (ej: MATNR se extiende), el comportamiento puede ser impredecible. `TYPE` es la forma correcta y moderna.

**Riesgo:** Bajo-Medio — funciona pero es obsoleto y puede causar warnings en ATC.

**Recomendación:** Cambiar `LIKE` por `TYPE` en toda la firma. Nota: esto requiere ajustar todos los programas que llaman este FM.

---

### 🟢 BUENAS PRÁCTICAS — Ya cumple o impacto bajo

#### H-07: No hay SELECTs directos a tablas deprecadas

El FM no hace ningún SELECT directo a base de datos. Toda la lógica de persistencia se delega a:
- `BAPI_QUOTATION_CREATEFROMDATA2` (SAP estándar)
- `ZCL_SD_ZFDC_CONTROLLER_ID` (clase custom)
- `ZSD_SALESORD_SALSFRC_SIMULATE` (FM custom)

Esto es positivo porque el impacto de tablas deprecadas está encapsulado en esos objetos, no en este FM.

#### H-08: Uso de clases OO para lógica auxiliar

```abap
DATA(lo_sf_id) = NEW zcl_sd_zfdc_controller_id( ... ).
zcl_sd_get_shipping_point=>get_value( ... ).
zcl_sd_sfdc_processing_voc=>get_sfdc_voc_text( ).
```

Ya usa clases OO para lógica de negocio. Esto facilita la migración porque cada clase se puede analizar y ajustar de forma independiente.

---

## Hallazgos de Sintaxis ABAP 7.5 (optimización EHP8)

Estos no son bloqueantes para S/4HANA pero representan oportunidades de modernización que ya pueden aplicar en EHP8.

### S-01: Declaraciones DATA excesivas al inicio

```abap
" ❌ Actual — 30+ líneas de DATA al inicio
DATA: return TYPE TABLE OF bapiret2.
DATA: lt_extensionin TYPE TABLE OF bapiparex,
      ls_extensionin TYPE bapiparex,
      ls_bape_vbak   TYPE bape_vbak,
      ...
```

**Recomendación:** Usar inline declarations donde se usen por primera vez.

### S-02: LOOP + MOVE-CORRESPONDING + APPEND

```abap
" ❌ Actual
LOOP AT quotation_items_in INTO wa_item.
  MOVE-CORRESPONDING wa_item TO wa_items.
  APPEND wa_items TO order_items_in.
ENDLOOP.
```

**Recomendación ABAP 7.5:**

```abap
" ✅ Moderno
order_items_in = CORRESPONDING #( quotation_items_in[] ).
```

Ya lo hacen en algunas partes (`lt_quotation_items_in = CORRESPONDING #( quotation_items_in[] )`), pero no en todas. Hay inconsistencia.

### S-03: READ TABLE con SY-SUBRC

```abap
" ❌ Actual
READ TABLE quotation_items_in INTO wa_quote WITH KEY itm_number = <fs_schedules>-itm_number.
IF sy-subrc EQ 0.
```

**Recomendación ABAP 7.5:**

```abap
" ✅ Moderno (con manejo de excepción)
TRY.
    DATA(ls_quote) = quotation_items_in[ itm_number = <fs_schedules>-itm_number ].
    <fs_schedules>-zzsalesforce_id = ls_quote-zzsalesforce_id.
  CATCH cx_sy_itab_line_not_found.
ENDTRY.
```

### S-04: READ TABLE ... TRANSPORTING NO FIELDS para verificar existencia

```abap
" ❌ Actual
READ TABLE return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
IF sy-subrc NE 0.
```

**Recomendación ABAP 7.5:**

```abap
" ✅ Moderno
IF NOT line_exists( return[ type = 'E' ] ).
```

---

## Objetos dependientes que requieren análisis separado

Estos objetos son llamados por el FM y necesitan su propio análisis de S/4HANA readiness:

| Objeto | Prioridad | Motivo |
|--------|-----------|--------|
| ZSD_SALESORD_SALSFRC_SIMULATE | 🔴 Alta | Puede leer KONV u otras tablas deprecadas internamente |
| ZCL_SD_ZFDC_CONTROLLER_ID | 🟡 Media | Persiste datos en tabla Z — verificar modelo de datos |
| ZCL_SD_GET_SHIPPING_POINT | 🟡 Media | Puede leer tablas de WM/shipping que cambian en S/4 |
| ZCL_SD_SFDC_PROCESSING_VOC | 🟢 Baja | Solo obtiene texto, bajo riesgo |

---

## Resumen de esfuerzo estimado

| Categoría | Hallazgos | Esfuerzo |
|-----------|-----------|----------|
| 🔴 Crítico (S/4HANA) | 2 (offset hardcodeado, MOVE-CORRESPONDING masivo) | 2-3 días |
| 🟡 Advertencia (S/4HANA) | 4 (BAPI pricing, SET PARAMETER, COMMIT WAIT, LIKE→TYPE) | 3-4 días |
| 🟢 Optimización (EHP8) | 4 (inline declarations, CORRESPONDING, table expressions, line_exists) | 2-3 días |
| Análisis dependencias | 4 objetos adicionales | 3-5 días |
| **Total estimado** | | **10-15 días** |

Nota: el esfuerzo incluye desarrollo, pruebas unitarias y pruebas de integración con Salesforce.
