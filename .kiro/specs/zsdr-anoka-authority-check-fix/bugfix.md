# Bugfix Requirements Document

## Introduction

El reporte `ZSDR_ANOKA_REPORT_BAK_N` llama al Function Module estándar `MD_STOCK_REQUIREMENTS_LIST_API` para obtener datos de stock/MRP por planta. Desde el upgrade a EHP8, este FM realiza internamente un authority check sobre el objeto `M_MTDI_ORG` (actividad 'A', campo WERKS y DISPO). Cuando el usuario no tiene autorización para una planta específica, el FM omite silenciosamente esos registros sin retornar ningún error ni mensaje. El reporte muestra resultados incompletos sin advertir al usuario, lo que puede llevar a decisiones incorrectas basadas en datos parciales.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN el usuario ejecuta `ZSDR_ANOKA_REPORT_BAK_N` para múltiples plantas y NO tiene autorización `M_MTDI_ORG` (actividad 'A') para al menos una de ellas THEN el sistema omite los registros de esa planta sin mostrar ningún mensaje de advertencia ni error al usuario

1.2 WHEN el FM `MD_STOCK_REQUIREMENTS_LIST_API` realiza el authority check interno sobre `M_MTDI_ORG` para una planta sin autorización THEN el sistema descarta silenciosamente los datos de esa planta y retorna únicamente los registros de las plantas autorizadas, sin indicar que hubo plantas excluidas

1.3 WHEN el usuario revisa los resultados del reporte THEN el sistema presenta los datos como si fueran completos, sin ninguna indicación de que faltan plantas por restricciones de autorización

### Expected Behavior (Correct)

2.1 WHEN el usuario ejecuta `ZSDR_ANOKA_REPORT_BAK_N` para múltiples plantas y NO tiene autorización `M_MTDI_ORG` (actividad 'A') para al menos una de ellas THEN el sistema SHALL realizar un authority check preventivo antes de llamar al FM y omitir la planta sin autorización usando `CONTINUE`, evitando el error silencioso del FM

2.2 WHEN el authority check preventivo detecta que el usuario no tiene autorización para una planta THEN el sistema SHALL registrar esa planta como "omitida por falta de autorización" para poder informar al usuario al final del proceso

2.3 WHEN el reporte finaliza su ejecución y al menos una planta fue omitida por falta de autorización THEN el sistema SHALL mostrar un mensaje de advertencia (tipo 'W') indicando explícitamente qué plantas fueron excluidas de los resultados por restricciones de autorización

### Unchanged Behavior (Regression Prevention)

3.1 WHEN el usuario tiene autorización `M_MTDI_ORG` (actividad 'A') para todas las plantas seleccionadas THEN el sistema SHALL CONTINUE TO procesar todas las plantas y mostrar los resultados completos sin ningún mensaje adicional

3.2 WHEN el usuario tiene autorización para un subconjunto de plantas y el reporte procesa ese subconjunto THEN el sistema SHALL CONTINUE TO retornar los datos de stock/MRP correctos para las plantas autorizadas, sin alterar el contenido ni el formato de los resultados

3.3 WHEN el reporte procesa una planta con autorización válida THEN el sistema SHALL CONTINUE TO llamar a `MD_STOCK_REQUIREMENTS_LIST_API` con los mismos parámetros de entrada y obtener los mismos datos que antes del fix

---

## Bug Condition (Pseudocódigo)

### Función de condición de bug

```pascal
FUNCTION isBugCondition(X)
  INPUT: X of type PlantAuthorizationInput
         X.werks = planta a procesar
         X.user  = usuario ejecutando el reporte
  OUTPUT: boolean

  // Retorna true cuando el usuario NO tiene autorización para la planta
  RETURN AUTHORITY-CHECK('M_MTDI_ORG', MDAKT='A', WERKS=X.werks, DISPO=DUMMY) <> 0
END FUNCTION
```

### Propiedad: Fix Checking

```pascal
// Property: Fix Checking — plantas sin autorización deben ser omitidas con aviso
FOR ALL X WHERE isBugCondition(X) DO
  result ← processPlant'(X)
  ASSERT result.plant_skipped = true
  ASSERT result.warning_shown = true
  ASSERT result.data_returned IS EMPTY
END FOR
```

### Propiedad: Preservation Checking

```pascal
// Property: Preservation Checking — plantas con autorización no se ven afectadas
FOR ALL X WHERE NOT isBugCondition(X) DO
  ASSERT processPlant(X) = processPlant'(X)
END FOR
```

**Nota:** `processPlant` es el comportamiento original (sin fix); `processPlant'` es el comportamiento corregido.
