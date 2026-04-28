# Tareas: Object ID Extractor

## Tarea 1: Crear la clase de excepción ZCX_SD_OBJECT_ID_ERROR

- [ ] 1.1 Crear la clase `ZCX_SD_OBJECT_ID_ERROR` que hereda de `CX_STATIC_CHECK` e implementa `IF_T100_MESSAGE`
- [ ] 1.2 Definir constantes `gc_empty_string` (msgno 001) y `gc_no_match` (msgno 002) con clase de mensajes `ZSD_OBJID`
- [ ] 1.3 Definir atributo `mv_length TYPE i READ-ONLY` y constructor con parámetros `textid`, `previous`, `iv_length`
- [ ] 1.4 Crear archivo `ZCX_SD_OBJECT_ID_ERROR.abap` en carpeta del proyecto

> Req: 2.1, 2.2, 3.4

## Tarea 2: Crear la interfaz ZIF_SD_OBJECT_ID_EXTRACTOR

- [ ] 2.1 Crear la interfaz `ZIF_SD_OBJECT_ID_EXTRACTOR` con constantes `gc_object_id_length = 10` y `gc_regex_pattern = '(.{10})$'`
- [ ] 2.2 Definir método `extract_object_id` con `IMPORTING iv_source_string TYPE string`, `RETURNING VALUE(rv_object_id) TYPE char10`, `RAISING zcx_sd_object_id_error`
- [ ] 2.3 Agregar documentación ABAP Doc al método y a la interfaz
- [ ] 2.4 Crear archivo `ZIF_SD_OBJECT_ID_EXTRACTOR.abap` en carpeta del proyecto

> Req: 3.1, 5.3, 5.4

## Tarea 3: Crear la clase ZCL_SD_OBJECT_ID_EXTRACTOR

- [ ] 3.1 Crear la clase `ZCL_SD_OBJECT_ID_EXTRACTOR` como `PUBLIC FINAL CREATE PUBLIC` que implementa `ZIF_SD_OBJECT_ID_EXTRACTOR`
- [ ] 3.2 Implementar `extract_object_id`: validar string vacío (lanzar gc_empty_string), aplicar REGEX `(.{10})$` con `CL_ABAP_REGEX`/`CL_ABAP_MATCHER`, lanzar gc_no_match si no hay match, extraer submatch 1
- [ ] 3.3 Usar sintaxis moderna ABAP 7.5: `NEW #()`, `DATA()`, inline declarations
- [ ] 3.4 Agregar documentación ABAP Doc a la clase y métodos públicos
- [ ] 3.5 Crear archivo `ZCL_SD_OBJECT_ID_EXTRACTOR.abap` en carpeta del proyecto

> Req: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 3.2, 5.1, 5.2, 5.3

## Tarea 4: Crear la clase de prueba ZCL_SD_OBJECT_ID_EXTRACTOR_TEST

- [ ] 4.1 Crear clase de prueba `ZCL_SD_OBJECT_ID_EXTRACTOR_TEST` con `DURATION SHORT` y `RISK LEVEL HARMLESS`
- [ ] 4.2 Implementar método `setup` que instancia `ZCL_SD_OBJECT_ID_EXTRACTOR`
- [ ] 4.3 Implementar test: extracción exitosa con prefijo largo (`"R3AD_SALESDO0069002341"` → `"0069002341"`)
- [ ] 4.4 Implementar test: extracción con prefijo corto (`"X0069002341"` → `"0069002341"`)
- [ ] 4.5 Implementar test: string exacto de 10 caracteres retorna el mismo string
- [ ] 4.6 Implementar test: string vacío lanza excepción con textid gc_empty_string
- [ ] 4.7 Implementar test: string corto (< 10 chars) lanza excepción con textid gc_no_match y mv_length correcto
- [ ] 4.8 Implementar test: string largo (> 30 chars) extrae correctamente los últimos 10
- [ ] 4.9 Crear archivo `ZCL_SD_OBJECT_ID_EXTRACTOR_TEST.abap` en carpeta del proyecto

> Req: 4.1, 4.2, 4.3, 1.1, 1.2, 1.3, 2.1, 2.2
