# Requerimientos: Object ID Extractor

## Requerimiento Funcional 1: Extracción de Object ID mediante REGEX

La función utilitaria debe extraer el Object ID (últimos 10 caracteres) de un string de longitud variable usando el patrón REGEX `(.{10})$`.

### Criterios de Aceptación

- 1.1 Dado un string con longitud >= 10 caracteres, cuando se invoca `extract_object_id`, entonces retorna los últimos 10 caracteres extraídos por el grupo de captura REGEX `(.{10})$`.
  - Example: Input `"R3AD_SALESDO0069002341"` → Output `"0069002341"`
  - Example: Input `"PREFIX_ABC1234567890"` → Output `"1234567890"`
  - Example: Input `"X0069002341"` → Output `"0069002341"` (prefijo de 1 carácter)

- 1.2 Dado un string con longitud >= 10 caracteres, cuando se invoca `extract_object_id`, entonces el resultado siempre tiene exactamente 10 caracteres de longitud.

- 1.3 Dado un string de exactamente 10 caracteres, cuando se invoca `extract_object_id`, entonces retorna el mismo string sin modificación (idempotencia parcial).
  - Example: Input `"0069002341"` → Output `"0069002341"`

- 1.4 Dado cualquier prefijo concatenado con un Object ID de 10 caracteres, cuando se invoca `extract_object_id`, entonces siempre retorna el Object ID original.
  - Example: `"ABC" && "0069002341"` → `"0069002341"`
  - Example: `"VERY_LONG_PREFIX_" && "0069002341"` → `"0069002341"`

## Requerimiento Funcional 2: Manejo de errores con excepciones tipadas

La función debe lanzar excepciones específicas de tipo `ZCX_SD_OBJECT_ID_ERROR` (hereda de `CX_STATIC_CHECK`) para inputs inválidos.

### Criterios de Aceptación

- 2.1 Dado un string vacío, cuando se invoca `extract_object_id`, entonces lanza `ZCX_SD_OBJECT_ID_ERROR` con textid `gc_empty_string` (mensaje 001).
  - Example: Input `""` → Excepción con msgno `001`

- 2.2 Dado un string con longitud entre 1 y 9 caracteres, cuando se invoca `extract_object_id`, entonces lanza `ZCX_SD_OBJECT_ID_ERROR` con textid `gc_no_match` (mensaje 002) e incluye la longitud del string en el atributo `mv_length`.
  - Example: Input `"SHORT"` (5 chars) → Excepción con msgno `002`, mv_length = 5
  - Example: Input `"A"` (1 char) → Excepción con msgno `002`, mv_length = 1
  - Example: Input `"123456789"` (9 chars) → Excepción con msgno `002`, mv_length = 9

## Requerimiento No Funcional 3: Diseño SOLID con interfaz e inyección de dependencias

La implementación debe seguir principios SOLID, especialmente DIP, para ser testeable y extensible.

### Criterios de Aceptación

- 3.1 La interfaz `ZIF_SD_OBJECT_ID_EXTRACTOR` define el contrato público con el método `extract_object_id`, la constante `gc_object_id_length = 10` y la constante `gc_regex_pattern = '(.{10})$'`.

- 3.2 La clase `ZCL_SD_OBJECT_ID_EXTRACTOR` implementa `ZIF_SD_OBJECT_ID_EXTRACTOR` y es `PUBLIC FINAL CREATE PUBLIC`.

- 3.3 Los consumidores de la función deben depender de la interfaz `ZIF_SD_OBJECT_ID_EXTRACTOR` (no de la clase concreta), permitiendo inyección de dependencias y test doubles.
  - Example: Constructor de consumidor acepta `io_extractor TYPE REF TO zif_sd_object_id_extractor OPTIONAL`

- 3.4 La clase de excepción `ZCX_SD_OBJECT_ID_ERROR` hereda de `CX_STATIC_CHECK`, implementa `IF_T100_MESSAGE`, y define constantes `gc_empty_string` y `gc_no_match` con clase de mensajes `ZSD_OBJID`.

## Requerimiento No Funcional 4: Tests unitarios con ABAP Unit

La implementación debe incluir una clase de prueba completa con test doubles.

### Criterios de Aceptación

- 4.1 Existe una clase de prueba `ZCL_SD_OBJECT_ID_EXTRACTOR_TEST` con `DURATION SHORT` y `RISK LEVEL HARMLESS`.

- 4.2 Los tests cubren: extracción exitosa con prefijos variados, string exacto de 10 caracteres, string vacío (excepción gc_empty_string), string corto (excepción gc_no_match), y strings largos.

- 4.3 Los tests usan `CL_ABAP_UNIT_ASSERT` para validaciones (assert_equals, assert_bound, etc.).

## Requerimiento No Funcional 5: Compatibilidad y estándares

### Criterios de Aceptación

- 5.1 El código usa sintaxis moderna ABAP 7.5: inline declarations `DATA( )`, `NEW #( )`, `COND #( )`.

- 5.2 El código es compatible con SAP ECC 6.0 EHP8 (no usa sintaxis exclusiva de S/4HANA o ABAP Cloud).

- 5.3 Todos los métodos públicos tienen documentación ABAP Doc (`"! descripción`).

- 5.4 Los objetos siguen las convenciones de nomenclatura Holcim BP: `ZCL_` para clases, `ZIF_` para interfaces, `ZCX_` para excepciones.

- 5.5 El paquete de desarrollo es `ZDEV_COMMON` (componente reutilizable entre módulos).
