# Informe de Análisis Técnico — Error Aritmético en Clasificación

**Fecha:** 22 de abril de 2026
**Sistema:** SAP ECC 6.0 EHP8 — BZD / Cliente 130
**Documento relacionado:** Quotation 10195339
**Severidad:** Media — Error en tiempo de ejecución que impide procesamiento de clasificación
**Elaborado por:** Equipo de desarrollo ABAP / L2C

---

## 1. Descripción del problema

Durante el procesamiento de la quotation **10195339**, se presenta una excepción de tipo **ARITHMETIC_ERRORS** en la rutina estándar SAP `ASSIGN_AND_CHANGE_COMPONENT` del include `LCUBXFOC` (grupo de funciones `CUBX` — módulo de Clasificación).

El error ocurre al intentar asignar un valor numérico a la característica de clasificación **ZZPLPOD_UMREZ** ("Numerator for converting task"), la cual pertenece al grupo de características `FSBP_VC` (FSBP Variant Configuration Rule).

---

## 2. Valores observados en el debugger

Los siguientes valores fueron capturados en el momento de la excepción:

| Variable | Valor | Descripción |
|---|---|---|
| `I_CABN-ATFOR` | `NUM` | Formato del atributo (numérico) |
| `I_CABN-ANZDZ` | `0` | Cantidad de decimales configurados |
| `I_VALUE-ATFLV` | `1.50000000000000E+05` | Valor flotante = **150,000** |
| `<P>` | `150000` | Valor asignado al field symbol (packed) |
| `SY-SUBRC` | `15` | Código de retorno = excepción aritmética capturada |

---

## 3. Configuración actual de la característica (CT04)

| Parámetro | Valor actual |
|---|---|
| Característica | `ZZPLPOD_UMREZ` |
| Descripción | Numerator for converting task |
| Grupo de características | FSBP_VC (FSBP Variant Configuration Rule) |
| Data Type | NUM (Numeric Format) |
| **Number of Chars** | **5** |
| **Decimal Places** | **(vacío = 0)** |
| Exp. display | 0 No exponent |
| Negative Vals Allowed | No |
| Valor máximo admitido | **99,999** |

---

## 4. Causa raíz

La característica `ZZPLPOD_UMREZ` está configurada con una longitud de **5 caracteres numéricos sin decimales**, lo que permite un valor máximo de **99,999**.

El valor que se intenta asignar desde la quotation 10195339 es **150,000** (6 dígitos), el cual **excede la capacidad** de la característica.

Cuando la rutina estándar ejecuta la conversión de tipo flotante (`F`) a tipo empaquetado (`P`) con la longitud definida en la característica, se produce un **overflow aritmético** porque el número 150,000 no cabe en un campo packed de 5 posiciones.

**En resumen:** El valor 150,000 > 99,999 (máximo para 5 dígitos) → ARITHMETIC_ERRORS.

---

## 5. Impacto

- La clasificación de la quotation 10195339 no se completa correctamente.
- Cualquier otro documento que intente asignar un valor mayor a 99,999 en esta característica presentará el mismo error.
- El error ocurre en código estándar SAP (`LCUBXFOC`), por lo que **no se debe modificar** el include directamente.

---

## 6. Soluciones propuestas

### Opción A — Ampliar la longitud de la característica (Recomendada)

**Acción:** Modificar la característica `ZZPLPOD_UMREZ` en la transacción **CT04**.

| Parámetro | Valor actual | Valor propuesto |
|---|---|---|
| Number of Chars | 5 | **8** (o según el rango máximo esperado) |

**Consideraciones:**
- Permite valores hasta 99,999,999 (8 dígitos), cubriendo ampliamente el rango de numeradores de conversión.
- Se debe validar con el equipo funcional cuál es el rango máximo real esperado para este numerador.
- Verificar si existen dependencias en tablas de configuración, variant conditions o reglas de configuración que referencien esta característica y puedan verse afectadas por el cambio de longitud.
- Requiere orden de transporte de Customizing.

### Opción B — Corregir el valor del dato

**Acción:** Revisar y corregir el valor de clasificación asignado a la quotation 10195339.

**Consideraciones:**
- Solo aplica si el valor 150,000 es incorrecto o fue ingresado por error.
- Se debe verificar el origen del dato: ¿fue ingresado manualmente, viene de una interfaz (Salesforce, MuleSoft), o fue calculado por una regla de configuración de variantes?
- Si el valor es legítimo de negocio, esta opción **no es viable** y se debe proceder con la Opción A.

---

## 7. Acciones requeridas del equipo funcional

1. **Confirmar** si el valor 150,000 es un numerador de conversión válido para el escenario de negocio de la quotation 10195339.
2. **Definir** el rango máximo esperado para la característica `ZZPLPOD_UMREZ` (¿cuál es el numerador de conversión más grande que se puede presentar?).
3. **Aprobar** la ampliación de la longitud en CT04 si el valor es legítimo, o indicar el valor correcto si fue un error de datos.
4. **Verificar** si existen otros documentos afectados por la misma limitación (quotations, órdenes de venta, etc. que usen esta característica con valores > 99,999).

---

## 8. Información de referencia

- **Transacción de análisis:** CT04 (Mantenimiento de características)
- **Include estándar afectado:** LCUBXFOC (Grupo de funciones CUBX)
- **Rutina:** FORM ASSIGN_AND_CHANGE_COMPONENT
- **Nota SAP relacionada:** Buscar en SAP Notes por "LCUBXFOC arithmetic_errors" para posibles correcciones estándar.
