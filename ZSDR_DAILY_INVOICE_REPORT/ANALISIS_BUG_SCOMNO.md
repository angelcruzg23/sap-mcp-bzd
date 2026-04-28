# Análisis de Bug — ZSDR_DAILY_INVOICE_REPORT
## Facturas marcadas como "Failed" cuando realmente fueron transmitidas

| Campo | Valor |
|-------|-------|
| Programa | ZSDR_DAILY_INVOICE_REPORT |
| Transacción | ZSD_DAILY_INVOICE |
| WRICEF | SD_E_618 |
| Include afectado | ZSDR_DAILY_INVOICE_REPORT_F01 |
| FORM afectado | F_GET_DATA |
| Reportado por | Usuario final |
| Severidad | Alta — información incorrecta en reporte de control |

---

## 1. Descripción del problema

El usuario reporta que recibe correctamente los correos de factura en su bandeja, y al verificar en la transacción SOST el estado aparece como **"Transmitted"**. Sin embargo, el reporte Z (`ZSD_DAILY_INVOICE`) muestra la factura con semáforo **rojo (F = Failed)**, indicando que el envío falló.

Esto genera confusión operativa y desconfianza en el reporte como herramienta de monitoreo diario.

---

## 2. Causa raíz identificada

En el FORM `f_get_data` del include `ZSDR_DAILY_INVOICE_REPORT_F01`, después de extraer los documentos de SAPoffice desde la tabla `SOOD`, se ejecuta la siguiente línea:

```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

### ¿Qué hace esta línea?

Elimina de la tabla interna `ltt_sood` todos los registros que tienen un número SAPcomm (`SCOMNO`) asignado.

### ¿Por qué es un problema?

Cuando SAPconnect transmite exitosamente un documento, le asigna un `SCOMNO` en la tabla `SOOD`. Es decir, **tener `SCOMNO` es evidencia de que el documento SÍ fue procesado y transmitido**.

Al eliminar estos registros, el LOOP posterior no encuentra match en `ltt_sood_hashed` y cae en la rama ELSE, que asigna semáforo rojo:

```abap
LOOP AT ltt_invoice INTO DATA(ls_invoice).
  ...
  READ TABLE ltt_sood_hashed INTO DATA(ls_sood)
       WITH KEY objdes = ls_invoice-tdcovtitle.
  IF sy-subrc EQ 0.
    " Busca en SOST y asigna semáforo según resultado
    ...
  ELSE.
    " ← CAE AQUÍ porque el registro fue eliminado por el DELETE
    gs_report-icon  = icon3.    " 🔴 Semáforo ROJO
    gs_report-vstat = |F|.      " Status: Failed
    APPEND gs_report TO gt_report.
  ENDIF.
ENDLOOP.
```

### Diagrama del flujo del error

```
SOOD (documento SAPoffice)
  │
  ├─ scomno IS INITIAL     → Se mantiene en ltt_sood → Se cruza con SOST → Semáforo correcto
  │
  └─ scomno IS NOT INITIAL → ❌ ELIMINADO por DELETE → No hay match → Semáforo ROJO (incorrecto)
                               ↑
                               El documento SÍ fue transmitido,
                               pero el reporte lo marca como fallido
```

---

## 3. Contexto del error

Este comportamiento comenzó a manifestarse **después de la aplicación del EHP8**. Es probable que el EHP8 haya cambiado el momento en que SAPconnect asigna el `SCOMNO` en `SOOD`, o que ahora lo asigne de forma más inmediata, causando que al momento de la consulta del reporte el campo ya esté lleno.

**Antes del EHP8:** el `SCOMNO` posiblemente se asignaba después, por lo que el `DELETE` no afectaba los registros recientes.

**Después del EHP8:** el `SCOMNO` se asigna durante la transmisión, por lo que el `DELETE` elimina los documentos exitosos.

---

## 4. Solución propuesta

Implementar un **switch por fecha** usando una variable en `TVARVC` que permita:
- Mantener el comportamiento original (con el `DELETE`) para documentos anteriores al EHP8
- Desactivar el `DELETE` para documentos a partir de la fecha de corte

### 4.1 Configuración en TVARVC

Crear una entrada en TVARVC:

| Campo | Valor |
|-------|-------|
| Name | ZSD_DAILY_INV_EHP8_DATE |
| Type | P (Parameter) |
| Low | 20260401 (fecha de corte — ajustar según fecha real del EHP8) |

### 4.2 Código modificado

**Antes (código actual con el bug):**
```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

**Después (código corregido con switch TVARVC):**
```abap
* ── Switch EHP8: no eliminar documentos transmitidos después de fecha de corte ──
* La fecha de corte se configura en TVARVC variable ZSD_DAILY_INV_EHP8_DATE
* Antes de esa fecha se mantiene el comportamiento original (DELETE con scomno)
* Después de esa fecha se omite el DELETE para evitar marcar como Failed
* documentos que realmente fueron transmitidos exitosamente.
DATA: lv_ehp8_cutoff TYPE sy-datum.

SELECT SINGLE low
  INTO lv_ehp8_cutoff
  FROM tvarvc
  WHERE name = 'ZSD_DAILY_INV_EHP8_DATE'
    AND type = 'P'.

IF sy-subrc <> 0.
  " Si no existe la variable, usar comportamiento original por seguridad
  lv_ehp8_cutoff = '99991231'.
ENDIF.

IF so_erdat-low < lv_ehp8_cutoff.
  " Comportamiento original pre-EHP8
  DELETE ltt_sood WHERE NOT scomno IS INITIAL.
ENDIF.
```

### 4.3 Explicación del switch

| Escenario | Fecha filtro del reporte | Comportamiento |
|-----------|--------------------------|----------------|
| Pre-EHP8 | Anterior a la fecha en TVARVC | Ejecuta el `DELETE` (comportamiento original) |
| Post-EHP8 | Igual o posterior a la fecha en TVARVC | **Omite el `DELETE`**, los documentos transmitidos se mantienen y se cruzan correctamente con SOST |
| TVARVC no existe | Cualquiera | Ejecuta el `DELETE` (fallback seguro, no rompe nada) |

---

## 5. Pasos para implementar

1. Crear la variable `ZSD_DAILY_INV_EHP8_DATE` en TVARVC (transacción STVARV) con la fecha de corte del EHP8
2. Modificar el include `ZSDR_DAILY_INVOICE_REPORT_F01` con el código propuesto
3. Activar y probar con facturas que actualmente aparecen en rojo pero están transmitidas en SOST
4. Verificar que facturas anteriores al EHP8 siguen mostrándose correctamente

---

## 6. Riesgo

| Riesgo | Mitigación |
|--------|------------|
| Romper comportamiento pre-EHP8 | El switch por fecha garantiza que solo aplica para fechas nuevas |
| Variable TVARVC no creada | El fallback usa fecha 99991231, manteniendo comportamiento original |
| Duplicados en SOOD por no hacer DELETE | Bajo riesgo: el `DELETE ADJACENT DUPLICATES` posterior ya maneja duplicados |
