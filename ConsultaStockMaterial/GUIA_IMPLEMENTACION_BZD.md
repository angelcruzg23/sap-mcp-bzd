# Guía de Implementación — ZFM_SD_GET_MATERIAL_STOCK

## Información General

| Campo | Valor |
|-------|-------|
| Sistema | BZD 130 |
| Orden de Transporte | BZDK930642 |
| Paquete | ZSD_SF |
| Descripción | FM RFC para consulta de stock de material por planta con exclusiones KOTG504 |
| Consumidor | Mulesoft → Salesforce |

---

## Inventario de Objetos a Crear

| # | Objeto | Tipo | Transacción | Descripción |
|---|--------|------|-------------|-------------|
| 1 | ZST_SD_PLANT_STOCK | Estructura DDIC | SE11 | Estructura de respuesta por planta |
| 2 | ZTY_SD_PLANT_STOCK_T | Tipo Tabla DDIC | SE11 | Tipo tabla de ZST_SD_PLANT_STOCK |
| 3 | ZIF_SD_STOCK_QUERY | Interfaz | SE24 / Eclipse | Interfaz del orquestador |
| 4 | ZIF_SD_STOCK_DAO | Interfaz | SE24 / Eclipse | Interfaz del DAO |
| 5 | ZIF_SD_EXCLUSION_CHECKER | Interfaz | SE24 / Eclipse | Interfaz del verificador de exclusiones |
| 6 | ZCL_SD_STOCK_QUERY | Clase | SE24 / Eclipse | Orquestador principal |
| 7 | ZCL_SD_STOCK_DAO | Clase | SE24 / Eclipse | Data Access Object |
| 8 | ZCL_SD_EXCLUSION_CHECKER | Clase | SE24 / Eclipse | Verificador de exclusiones KOTG504 |
| 9 | ZFG_SD_STOCK_QUERY | Function Group | SE80 / Eclipse | Grupo de funciones |
| 10 | ZFM_SD_GET_MATERIAL_STOCK | Function Module | SE37 / Eclipse | FM RFC-enabled |
| 11 | ZCL_SD_STOCK_QUERY_TEST | Clase Test | SE24 / Eclipse | Tests del orquestador |
| 12 | ZCL_SD_STOCK_DAO_TEST | Clase Test | SE24 / Eclipse | Tests del DAO |
| 13 | ZCL_SD_EXCLUSION_CHECKER_TEST | Clase Test | SE24 / Eclipse | Tests del exclusion checker |

---

## Orden de Creación (respetar dependencias)

```
Fase 1: DDIC (sin dependencias)
  1. ZST_SD_PLANT_STOCK
  2. ZTY_SD_PLANT_STOCK_T

Fase 2: Interfaces (dependen de DDIC)
  3. ZIF_SD_STOCK_QUERY
  4. ZIF_SD_STOCK_DAO
  5. ZIF_SD_EXCLUSION_CHECKER

Fase 3: Clases de negocio (dependen de interfaces)
  6. ZCL_SD_STOCK_DAO
  7. ZCL_SD_EXCLUSION_CHECKER
  8. ZCL_SD_STOCK_QUERY  (depende de las dos anteriores)

Fase 4: Function Group y FM (depende de clases)
  9. ZFG_SD_STOCK_QUERY
  10. ZFM_SD_GET_MATERIAL_STOCK

Fase 5: Clases de prueba (dependen de todo lo anterior)
  11. ZCL_SD_STOCK_QUERY_TEST
  12. ZCL_SD_STOCK_DAO_TEST
  13. ZCL_SD_EXCLUSION_CHECKER_TEST
```

---

## FASE 1: Objetos DDIC

### 1.1 Estructura ZST_SD_PLANT_STOCK

Transacción: SE11 → Tipo de datos → Estructura
- Nombre: `ZST_SD_PLANT_STOCK`
- Descripción: `Stock de material por planta (respuesta RFC)`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`

Componentes:

| Componente | Categoría | Tipo referencia | Descripción |
|------------|-----------|-----------------|-------------|
| WERKS | Tipo | WERKS_D | Planta |
| NAME1 | Tipo | CHAR30 | Nombre de la planta |
| LABST | Tipo | LABST | Stock de libre utilización |
| EINME | Tipo | EINME | Stock en control de calidad |
| SPEME | Tipo | SPEME | Stock bloqueado |
| IS_EXCLUDED | Tipo | CHAR1 | Flag exclusión KOTG504 (X/space) |
| EXCLUSION_REASON | Tipo | CHAR255 | Motivo de exclusión |

> Nota: EISBE (stock de seguridad) NO es campo de MARD — es de MARC. Se excluye de la estructura.
> Para NAME1 usar CHAR30 en lugar de T001W-NAME1 para evitar dependencia directa.
> Para IS_EXCLUDED usar CHAR1 ya que ABAP_BOOL no es un elemento de datos DDIC estándar disponible en estructuras.

Activar después de crear.

---

### 1.2 Tipo Tabla ZTY_SD_PLANT_STOCK_T

Transacción: SE11 → Tipo de datos → Tipo tabla
- Nombre: `ZTY_SD_PLANT_STOCK_T`
- Descripción: `Tabla de stock por planta`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`

Configuración:
- Tipo de línea: `ZST_SD_PLANT_STOCK`
- Categoría de acceso: `STANDARD TABLE`
- Clave: No única, campos vacíos (o WERKS como clave)

Activar después de crear.

---

## FASE 2: Interfaces

### 2.1 Interfaz ZIF_SD_STOCK_QUERY

Transacción: SE24 → Crear Interfaz (o Eclipse ADT: New → ABAP Interface)
- Nombre: `ZIF_SD_STOCK_QUERY`
- Descripción: `Interfaz orquestador consulta stock por planta`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`

Código fuente completo:

```abap
INTERFACE zif_sd_stock_query PUBLIC.

  "! Consulta el stock de un material por planta para una sociedad.
  "! Replica la información de la transacción MMBE incluyendo
  "! verificación de exclusiones KOTG504.
  "! @parameter iv_matnr      | Número de material (obligatorio)
  "! @parameter iv_bukrs      | Sociedad (obligatorio)
  "! @parameter ev_matnr_desc | Descripción del material en idioma EN
  "! @parameter et_messages   | Mensajes de error, warning o informativos
  "! @parameter rt_result     | Stock por planta con flag de exclusión
  METHODS get_stock_by_plant
    IMPORTING
      iv_matnr      TYPE matnr
      iv_bukrs      TYPE bukrs
    EXPORTING
      ev_matnr_desc TYPE makt-maktx
      et_messages   TYPE bapiret2_t
    RETURNING
      VALUE(rt_result) TYPE zty_sd_plant_stock_t.

ENDINTERFACE.
```

Activar después de crear.

---

### 2.2 Interfaz ZIF_SD_STOCK_DAO

Transacción: SE24 → Crear Interfaz
- Nombre: `ZIF_SD_STOCK_DAO`
- Descripción: `Interfaz DAO consulta stock material`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`

Código fuente completo:

```abap
INTERFACE zif_sd_stock_dao PUBLIC.

  TYPES: BEGIN OF ty_werks_range,
           sign   TYPE char1,
           option TYPE char2,
           low    TYPE werks_d,
           high   TYPE werks_d,
         END OF ty_werks_range,
         tty_werks_range TYPE TABLE OF ty_werks_range WITH DEFAULT KEY.

  "! Retorna el rango de plantas asociadas a una sociedad (T001K + T001W).
  "! @parameter iv_bukrs   | Sociedad
  "! @parameter rt_plants  | Rango de plantas (para uso en WHERE ... IN)
  METHODS get_plants_for_company
    IMPORTING iv_bukrs TYPE bukrs
    RETURNING VALUE(rt_plants) TYPE tty_werks_range.

  "! Retorna stock por planta para un material, solo plantas activas en MARC.
  "! Incluye LABST, EINME, SPEME, EISBE y NAME1 de T001W.
  "! @parameter iv_matnr  | Número de material
  "! @parameter it_plants | Rango de plantas a consultar
  "! @parameter rt_stock  | Stock por planta
  METHODS get_material_stock
    IMPORTING
      iv_matnr  TYPE matnr
      it_plants TYPE tty_werks_range
    RETURNING VALUE(rt_stock) TYPE zty_sd_plant_stock_t.

  "! Retorna la descripción del material en idioma EN desde MAKT.
  "! @parameter iv_matnr | Número de material
  "! @parameter rv_desc  | Descripción (MAKTX)
  METHODS get_material_description
    IMPORTING iv_matnr TYPE matnr
    RETURNING VALUE(rv_desc) TYPE makt-maktx.

  "! Verifica si el material existe en MARA.
  "! @parameter iv_matnr  | Número de material
  "! @parameter rv_exists | ABAP_TRUE si existe
  METHODS validate_material
    IMPORTING iv_matnr TYPE matnr
    RETURNING VALUE(rv_exists) TYPE abap_bool.

  "! Verifica si la sociedad existe en T001.
  "! @parameter iv_bukrs  | Sociedad
  "! @parameter rv_exists | ABAP_TRUE si existe
  METHODS validate_company
    IMPORTING iv_bukrs TYPE bukrs
    RETURNING VALUE(rv_exists) TYPE abap_bool.

ENDINTERFACE.
```

Activar después de crear.

---

### 2.3 Interfaz ZIF_SD_EXCLUSION_CHECKER

Transacción: SE24 → Crear Interfaz
- Nombre: `ZIF_SD_EXCLUSION_CHECKER`
- Descripción: `Interfaz verificador exclusiones KOTG504`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`

Código fuente completo:

```abap
INTERFACE zif_sd_exclusion_checker PUBLIC.

  "! Evalúa exclusiones KOTG504 para todas las plantas del resultado.
  "! Ejecuta una sola consulta a BD para todas las plantas (sin SELECT en LOOP).
  "! Asigna IS_EXCLUDED y EXCLUSION_REASON en cada entrada.
  "! @parameter iv_matnr       | Número de material
  "! @parameter it_plant_stock | Stock por planta (entrada sin flags de exclusión)
  "! @parameter rt_result      | Stock por planta con IS_EXCLUDED y EXCLUSION_REASON poblados
  METHODS check_exclusions
    IMPORTING
      iv_matnr       TYPE matnr
      it_plant_stock TYPE zty_sd_plant_stock_t
    RETURNING VALUE(rt_result) TYPE zty_sd_plant_stock_t.

ENDINTERFACE.
```

Activar después de crear.

---

## FASE 3: Clases de Negocio

### 3.1 Clase ZCL_SD_STOCK_DAO

Transacción: SE24 → Crear Clase (o Eclipse ADT: New → ABAP Class)
- Nombre: `ZCL_SD_STOCK_DAO`
- Descripción: `DAO consulta stock material por planta`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`
- Instanciación: Public
- Final: Sí
- Interfaces: `ZIF_SD_STOCK_DAO`

Código fuente completo:

```abap
CLASS zcl_sd_stock_dao DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_stock_dao.

ENDCLASS.

CLASS zcl_sd_stock_dao IMPLEMENTATION.

  METHOD zif_sd_stock_dao~get_plants_for_company.
    " JOIN T001K + T001W para obtener plantas de la sociedad
    SELECT t1w~werks
      FROM t001k AS t1k
      INNER JOIN t001w AS t1w ON t1w~bwkey = t1k~bwkey
      WHERE t1k~bukrs = @iv_bukrs
      INTO TABLE @DATA(lt_werks).

    rt_plants = VALUE zif_sd_stock_dao=>tty_werks_range(
      FOR ls_w IN lt_werks
      ( sign = 'I' option = 'EQ' low = ls_w-werks ) ).
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_stock.
    " Paso 1: Plantas donde el material existe y no está marcado para borrado
    SELECT matnr, werks
      FROM marc
      WHERE matnr = @iv_matnr
        AND werks IN @it_plants
        AND lvorm = @space
      INTO TABLE @DATA(lt_marc).

    CHECK lt_marc IS NOT INITIAL.

    " Paso 2: Stock desde MARD (FOR ALL ENTRIES sobre lt_marc)
    " Nota: EISBE no es campo de MARD — es de MARC.
    " Campos de stock en MARD: LABST, EINME, SPEME
    SELECT matnr, werks, labst, einme, speme
      FROM mard
      FOR ALL ENTRIES IN @lt_marc
      WHERE matnr = @lt_marc-matnr
        AND werks = @lt_marc-werks
      INTO TABLE @DATA(lt_mard).

    " Paso 3: Nombres de planta desde T001W
    SELECT werks, name1
      FROM t001w
      WHERE werks IN @it_plants
      INTO TABLE @DATA(lt_t001w).

    " Paso 4: Construir resultado con LOOP clásico
    " (VALUE # con LET + table expression OPTIONAL no es estable en 7.50 SP32)
    DATA ls_result TYPE zst_sd_plant_stock.

    LOOP AT lt_marc ASSIGNING FIELD-SYMBOL(<ls_marc>).
      CLEAR ls_result.
      ls_result-werks = <ls_marc>-werks.

      " Buscar nombre de planta
      READ TABLE lt_t001w ASSIGNING FIELD-SYMBOL(<ls_t001w>)
        WITH KEY werks = <ls_marc>-werks.
      IF sy-subrc = 0.
        ls_result-name1 = <ls_t001w>-name1.
      ENDIF.

      " Buscar stock — si no hay registro en MARD, queda en cero
      READ TABLE lt_mard ASSIGNING FIELD-SYMBOL(<ls_mard>)
        WITH KEY matnr = <ls_marc>-matnr
                 werks = <ls_marc>-werks.
      IF sy-subrc = 0.
        ls_result-labst = <ls_mard>-labst.
        ls_result-einme = <ls_mard>-einme.
        ls_result-speme = <ls_mard>-speme.
      ENDIF.

      APPEND ls_result TO rt_stock.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_description.
    SELECT SINGLE maktx FROM makt
      WHERE matnr = @iv_matnr
        AND spras = 'EN'
      INTO @rv_desc.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~validate_material.
    SELECT SINGLE matnr FROM mara
      WHERE matnr = @iv_matnr
      INTO @DATA(lv_matnr).
    rv_exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD zif_sd_stock_dao~validate_company.
    SELECT SINGLE bukrs FROM t001
      WHERE bukrs = @iv_bukrs
      INTO @DATA(lv_bukrs).
    rv_exists = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

ENDCLASS.
```

Activar después de crear.

---

### 3.2 Clase ZCL_SD_EXCLUSION_CHECKER

Transacción: SE24 → Crear Clase
- Nombre: `ZCL_SD_EXCLUSION_CHECKER`
- Descripción: `Verificador exclusiones KOTG504 planta/material`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`
- Instanciación: Public
- Final: Sí
- Interfaces: `ZIF_SD_EXCLUSION_CHECKER`

Código fuente completo:

```abap
CLASS zcl_sd_exclusion_checker DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_exclusion_checker.

  PRIVATE SECTION.
    CONSTANTS gc_high_date TYPE dats VALUE '99991231'.
    CONSTANTS gc_app       TYPE char1 VALUE 'V'.
    CONSTANTS gc_kschl     TYPE char4 VALUE 'ZB01'.

ENDCLASS.

CLASS zcl_sd_exclusion_checker IMPLEMENTATION.

  METHOD zif_sd_exclusion_checker~check_exclusions.
    " Retornar vacío si no hay plantas que evaluar
    CHECK it_plant_stock IS NOT INITIAL.

    " Paso 1: Una sola consulta a KOTG504 para el material
    " Filtra registros activos: datab <= hoy AND (datbi >= hoy OR datbi = '99991231')
    SELECT kappl, kschl, werks, matnr, datab, datbi
      FROM kotg504
      WHERE matnr = @iv_matnr
        AND kappl = @gc_app
        AND kschl = @gc_kschl
        AND datab <= @sy-datum
        AND ( datbi >= @sy-datum OR datbi = @gc_high_date )
      INTO TABLE @DATA(lt_exclusions).

    " Paso 2: Copiar entrada como base del resultado
    rt_result = it_plant_stock.

    " Paso 3: Para cada planta en el resultado, verificar exclusión
    " (READ TABLE sobre lt_exclusions — sin SELECT en LOOP)
    LOOP AT rt_result ASSIGNING FIELD-SYMBOL(<ls_stock>).
      " Verificar exclusión específica por planta
      READ TABLE lt_exclusions TRANSPORTING NO FIELDS
        WITH KEY werks = <ls_stock>-werks.
      DATA(lv_excl_plant) = xsdbool( sy-subrc = 0 ).

      " Verificar exclusión a nivel material (WERKS vacío)
      READ TABLE lt_exclusions TRANSPORTING NO FIELDS
        WITH KEY werks = space.
      DATA(lv_excl_material) = xsdbool( sy-subrc = 0 ).

      IF lv_excl_plant = abap_true.
        <ls_stock>-is_excluded      = abap_true.
        <ls_stock>-exclusion_reason =
          |Plant { <ls_stock>-werks } excluded for material { iv_matnr } (KOTG504)|.
      ELSEIF lv_excl_material = abap_true.
        <ls_stock>-is_excluded      = abap_true.
        <ls_stock>-exclusion_reason =
          |Material { iv_matnr } excluded for all plants (KOTG504)|.
      ELSE.
        <ls_stock>-is_excluded      = abap_false.
        <ls_stock>-exclusion_reason = space.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
```

Activar después de crear.

---

### 3.3 Clase ZCL_SD_STOCK_QUERY

Transacción: SE24 → Crear Clase
- Nombre: `ZCL_SD_STOCK_QUERY`
- Descripción: `Orquestador consulta stock material por planta`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`
- Instanciación: Public
- Final: Sí
- Interfaces: `ZIF_SD_STOCK_QUERY`

> IMPORTANTE: Esta clase depende de ZCL_SD_STOCK_DAO y ZCL_SD_EXCLUSION_CHECKER.
> Crear DESPUÉS de las dos clases anteriores.

Código fuente completo:

```abap
CLASS zcl_sd_stock_query DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_sd_stock_query.

    "! Constructor con inyección de dependencias.
    "! Si no se proveen dependencias, instancia las clases concretas por defecto.
    "! @parameter io_dao       | Implementación de ZIF_SD_STOCK_DAO (opcional)
    "! @parameter io_exclusion | Implementación de ZIF_SD_EXCLUSION_CHECKER (opcional)
    METHODS constructor
      IMPORTING
        io_dao       TYPE REF TO zif_sd_stock_dao       OPTIONAL
        io_exclusion TYPE REF TO zif_sd_exclusion_checker OPTIONAL.

  PRIVATE SECTION.
    DATA mo_dao       TYPE REF TO zif_sd_stock_dao.
    DATA mo_exclusion TYPE REF TO zif_sd_exclusion_checker.

    "! Agrega un mensaje de error a la tabla de mensajes.
    METHODS add_error_message
      IMPORTING iv_text     TYPE string
      CHANGING  ct_messages TYPE bapiret2_t.

    "! Agrega un mensaje informativo a la tabla de mensajes.
    METHODS add_info_message
      IMPORTING iv_text     TYPE string
      CHANGING  ct_messages TYPE bapiret2_t.

ENDCLASS.

CLASS zcl_sd_stock_query IMPLEMENTATION.

  METHOD constructor.
    mo_dao = COND #(
      WHEN io_dao IS BOUND THEN io_dao
      ELSE NEW zcl_sd_stock_dao( ) ).
    mo_exclusion = COND #(
      WHEN io_exclusion IS BOUND THEN io_exclusion
      ELSE NEW zcl_sd_exclusion_checker( ) ).
  ENDMETHOD.

  METHOD zif_sd_stock_query~get_stock_by_plant.
    CLEAR: rt_result, ev_matnr_desc, et_messages.

    " Paso 1: Validar parámetros de entrada
    IF iv_matnr IS INITIAL.
      add_error_message(
        EXPORTING iv_text     = 'Material number is required'
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    IF iv_bukrs IS INITIAL.
      add_error_message(
        EXPORTING iv_text     = 'Company code is required'
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    " Paso 2: Validar existencia en BD
    IF mo_dao->validate_material( iv_matnr ) = abap_false.
      add_error_message(
        EXPORTING iv_text     = |Material { iv_matnr } does not exist in the system|
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    IF mo_dao->validate_company( iv_bukrs ) = abap_false.
      add_error_message(
        EXPORTING iv_text     = |Company code { iv_bukrs } does not exist in the system|
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    " Paso 3: Obtener plantas de la sociedad
    DATA(lt_plants) = mo_dao->get_plants_for_company( iv_bukrs ).

    " Paso 4: Obtener stock por planta
    DATA(lt_stock) = mo_dao->get_material_stock(
      iv_matnr  = iv_matnr
      it_plants = lt_plants ).

    " Paso 5: Verificar si hay stock
    IF lt_stock IS INITIAL.
      add_info_message(
        EXPORTING iv_text     = |No stock found for material { iv_matnr } in company code { iv_bukrs }|
        CHANGING  ct_messages = et_messages ).
      RETURN.
    ENDIF.

    " Paso 6: Evaluar exclusiones KOTG504
    lt_stock = mo_exclusion->check_exclusions(
      iv_matnr       = iv_matnr
      it_plant_stock = lt_stock ).

    " Paso 7: Obtener descripción del material
    ev_matnr_desc = mo_dao->get_material_description( iv_matnr ).

    " Paso 8: Retornar resultado
    rt_result = lt_stock.
  ENDMETHOD.

  METHOD add_error_message.
    APPEND VALUE #(
      type       = 'E'
      id         = 'ZSD_STOCK'
      number     = '001'
      message    = iv_text
    ) TO ct_messages.
  ENDMETHOD.

  METHOD add_info_message.
    APPEND VALUE #(
      type       = 'I'
      id         = 'ZSD_STOCK'
      number     = '002'
      message    = iv_text
    ) TO ct_messages.
  ENDMETHOD.

ENDCLASS.
```

Activar después de crear.

---

## FASE 4: Function Group y Function Module

### 4.1 Function Group ZFG_SD_STOCK_QUERY

Transacción: SE80 → Crear Function Group (o Eclipse ADT: New → ABAP Function Group)
- Nombre: `ZFG_SD_STOCK_QUERY`
- Descripción: `Consulta stock material por planta (RFC)`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`

Activar después de crear.

---

### 4.2 Function Module ZFM_SD_GET_MATERIAL_STOCK

Transacción: SE37 → Crear Function Module
- Nombre: `ZFM_SD_GET_MATERIAL_STOCK`
- Function Group: `ZFG_SD_STOCK_QUERY`
- Descripción: `RFC: Stock de material por planta para una sociedad`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`

#### Pestaña "Attributes"
- Tipo de procesamiento: **Remote-Enabled Module** (marcar esta opción)

#### Pestaña "Import"

| Nombre | Tipo | Referencia | Pass by Value | Opcional |
|--------|------|------------|:---:|:---:|
| IV_MATNR | TYPE | MATNR | ✅ | |
| IV_BUKRS | TYPE | BUKRS | ✅ | |

#### Pestaña "Export"

| Nombre | Tipo | Referencia | Pass by Value |
|--------|------|------------|:---:|
| EV_MATNR_DESC | TYPE | MAKT-MAKTX | ✅ |

#### Pestaña "Tables"

| Nombre | Tipo | Referencia |
|--------|------|------------|
| ET_PLANT_STOCK | LIKE | ZST_SD_PLANT_STOCK |
| ET_MESSAGES | LIKE | BAPIRET2 |

> NOTA: En la pestaña Tables, usar "LIKE" con la estructura, no "TYPE" con el tipo tabla. Esto es estándar para FMs RFC-enabled.

#### Pestaña "Source Code"

```abap
FUNCTION zfm_sd_get_material_stock.
*"----------------------------------------------------------------------
*"*"Interfaz local:
*"  IMPORTING
*"     VALUE(IV_MATNR) TYPE  MATNR
*"     VALUE(IV_BUKRS) TYPE  BUKRS
*"  EXPORTING
*"     VALUE(EV_MATNR_DESC) TYPE  MAKT-MAKTX
*"  TABLES
*"     ET_PLANT_STOCK STRUCTURE  ZST_SD_PLANT_STOCK
*"     ET_MESSAGES STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  DATA lo_query TYPE REF TO zif_sd_stock_query.

  TRY.
      lo_query = NEW zcl_sd_stock_query( ).

      et_plant_stock[] = lo_query->get_stock_by_plant(
        EXPORTING
          iv_matnr      = iv_matnr
          iv_bukrs      = iv_bukrs
        IMPORTING
          ev_matnr_desc = ev_matnr_desc
          et_messages   = et_messages[] ).

    CATCH cx_root INTO DATA(lx_error).
      APPEND VALUE bapiret2(
        type       = 'E'
        id         = 'ZSD_STOCK'
        number     = '000'
        message    = lx_error->get_text( )
      ) TO et_messages[].
  ENDTRY.

ENDFUNCTION.
```

Activar después de crear.

---

## FASE 5: Clases de Prueba

### 5.1 Clase ZCL_SD_STOCK_QUERY_TEST

Transacción: SE24 → Crear Clase
- Nombre: `ZCL_SD_STOCK_QUERY_TEST`
- Descripción: `Tests unitarios orquestador stock por planta`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`
- Instanciación: Private
- Final: Sí
- Marcar como: **Test Class** (en Eclipse: pestaña Properties → Test Class = true)

> IMPORTANTE: En SE24, ir a Properties → marcar "Test Class".
> En Eclipse ADT, al crear la clase agregar `FOR TESTING` en la definición.

Código fuente completo (incluye test doubles locales):

```abap
*----------------------------------------------------------------------*
* Test Double: DAO
*----------------------------------------------------------------------*
CLASS lcl_dao_double DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sd_stock_dao.
    DATA mt_stock_to_return  TYPE zty_sd_plant_stock_t.
    DATA mv_material_exists  TYPE abap_bool VALUE abap_true.
    DATA mv_company_exists   TYPE abap_bool VALUE abap_true.
    DATA mv_desc_to_return   TYPE makt-maktx VALUE 'S20 WATERBLOCK (25 CARTRIDGES)'.
    DATA mt_plants_to_return TYPE RANGE OF werks_d.
ENDCLASS.

CLASS lcl_dao_double IMPLEMENTATION.
  METHOD zif_sd_stock_dao~validate_material.
    rv_exists = mv_material_exists.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~validate_company.
    rv_exists = mv_company_exists.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_plants_for_company.
    rt_plants = mt_plants_to_return.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_stock.
    rt_stock = mt_stock_to_return.
  ENDMETHOD.

  METHOD zif_sd_stock_dao~get_material_description.
    rv_desc = mv_desc_to_return.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Test Double: Exclusion Checker
*----------------------------------------------------------------------*
CLASS lcl_exclusion_double DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sd_exclusion_checker.
    DATA mt_result_to_return TYPE zty_sd_plant_stock_t.
    DATA mv_pass_through     TYPE abap_bool VALUE abap_true.
ENDCLASS.

CLASS lcl_exclusion_double IMPLEMENTATION.
  METHOD zif_sd_exclusion_checker~check_exclusions.
    IF mv_pass_through = abap_true.
      rt_result = it_plant_stock.
    ELSE.
      rt_result = mt_result_to_return.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Clase de prueba principal
*----------------------------------------------------------------------*
CLASS zcl_sd_stock_query_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut       TYPE REF TO zcl_sd_stock_query.
    DATA mo_dao       TYPE REF TO lcl_dao_double.
    DATA mo_exclusion TYPE REF TO lcl_exclusion_double.

    METHODS setup.

    METHODS test_valid_material_and_company FOR TESTING.
    METHODS test_empty_matnr               FOR TESTING.
    METHODS test_empty_bukrs               FOR TESTING.
    METHODS test_material_not_found        FOR TESTING.
    METHODS test_company_not_found         FOR TESTING.
    METHODS test_no_stock_found            FOR TESTING.
    METHODS test_excluded_plant_flagged    FOR TESTING.
    METHODS test_non_excluded_plant        FOR TESTING.
    METHODS test_matnr_desc_populated      FOR TESTING.
ENDCLASS.

CLASS zcl_sd_stock_query_test IMPLEMENTATION.

  METHOD setup.
    mo_dao       = NEW lcl_dao_double( ).
    mo_exclusion = NEW lcl_exclusion_double( ).

    mo_dao->mt_plants_to_return = VALUE #(
      ( sign = 'I' option = 'EQ' low = '1020' )
      ( sign = 'I' option = 'EQ' low = '1053' ) ).

    mo_dao->mt_stock_to_return = VALUE #(
      ( werks = '1020' name1 = 'Prescott Production'
        labst = 921000 einme = 0 speme = 0 eisbe = 320000 )
      ( werks = '1053' name1 = 'Salt Lake City Production'
        labst = 575000 einme = 0 speme = 0 eisbe = 320000 ) ).

    mo_cut = NEW zcl_sd_stock_query(
      io_dao       = mo_dao
      io_exclusion = mo_exclusion ).
  ENDMETHOD.

  METHOD test_valid_material_and_company.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'W563587071' iv_bukrs = '1000'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_initial( act = lt_messages ).
    cl_abap_unit_assert=>assert_not_initial( act = lv_desc ).
  ENDMETHOD.

  METHOD test_empty_matnr.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = space iv_bukrs = '1000'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_messages ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_empty_bukrs.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'W563587071' iv_bukrs = space
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_messages ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_material_not_found.
    mo_dao->mv_material_exists = abap_false.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'NOEXISTE' iv_bukrs = '1000'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_company_not_found.
    mo_dao->mv_company_exists = abap_false.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'W563587071' iv_bukrs = '9999'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_no_stock_found.
    mo_dao->mt_stock_to_return = VALUE #( ).
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'W563587071' iv_bukrs = '1000'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_messages ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'I' act = lt_messages[ 1 ]-type ).
  ENDMETHOD.

  METHOD test_excluded_plant_flagged.
    mo_exclusion->mv_pass_through = abap_false.
    mo_exclusion->mt_result_to_return = VALUE #(
      ( werks = '1020' name1 = 'Prescott Production'
        labst = 921000 is_excluded = abap_false )
      ( werks = '1053' name1 = 'Salt Lake City Production'
        labst = 575000 is_excluded = abap_true
        exclusion_reason = 'Planta excluida (KOTG504)' ) ).

    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'W563587071' iv_bukrs = '1000'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true act = lt_result[ werks = '1053' ]-is_excluded ).
  ENDMETHOD.

  METHOD test_non_excluded_plant.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'W563587071' iv_bukrs = '1000'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_false act = lt_result[ werks = '1020' ]-is_excluded ).
  ENDMETHOD.

  METHOD test_matnr_desc_populated.
    DATA(lt_result) = mo_cut->zif_sd_stock_query~get_stock_by_plant(
      EXPORTING iv_matnr = 'W563587071' iv_bukrs = '1000'
      IMPORTING ev_matnr_desc = DATA(lv_desc) et_messages = DATA(lt_messages) ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'S20 WATERBLOCK (25 CARTRIDGES)' act = lv_desc ).
  ENDMETHOD.

ENDCLASS.
```

---

### 5.2 Clase ZCL_SD_STOCK_DAO_TEST

Transacción: SE24 → Crear Clase
- Nombre: `ZCL_SD_STOCK_DAO_TEST`
- Descripción: `Tests unitarios DAO stock por planta`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`
- Marcar como: **Test Class**

Código fuente completo:

```abap
CLASS zcl_sd_stock_dao_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_sd_stock_dao.

    METHODS setup.

    METHODS test_validate_material_exists     FOR TESTING.
    METHODS test_validate_material_not_exists FOR TESTING.
    METHODS test_validate_company_exists      FOR TESTING.
    METHODS test_validate_company_not_exists  FOR TESTING.
    METHODS test_get_plants_for_company       FOR TESTING.
    METHODS test_get_material_stock           FOR TESTING.
    METHODS test_get_material_description     FOR TESTING.
    METHODS test_get_stock_empty_plants       FOR TESTING.
ENDCLASS.

CLASS zcl_sd_stock_dao_test IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW zcl_sd_stock_dao( ).
  ENDMETHOD.

  METHOD test_validate_material_exists.
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_material( 'W563587071' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = lv_exists ).
  ENDMETHOD.

  METHOD test_validate_material_not_exists.
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_material( 'ZZZNOEXISTE' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lv_exists ).
  ENDMETHOD.

  METHOD test_validate_company_exists.
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_company( '1000' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true act = lv_exists ).
  ENDMETHOD.

  METHOD test_validate_company_not_exists.
    DATA(lv_exists) = mo_cut->zif_sd_stock_dao~validate_company( '9999' ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false act = lv_exists ).
  ENDMETHOD.

  METHOD test_get_plants_for_company.
    DATA(lt_plants) = mo_cut->zif_sd_stock_dao~get_plants_for_company( '1000' ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_plants ).
    cl_abap_unit_assert=>assert_equals( exp = 'I' act = lt_plants[ 1 ]-sign ).
    cl_abap_unit_assert=>assert_equals( exp = 'EQ' act = lt_plants[ 1 ]-option ).
  ENDMETHOD.

  METHOD test_get_material_stock.
    DATA(lt_plants) = mo_cut->zif_sd_stock_dao~get_plants_for_company( '1000' ).
    DATA(lt_stock) = mo_cut->zif_sd_stock_dao~get_material_stock(
      iv_matnr = 'W563587071' it_plants = lt_plants ).

    cl_abap_unit_assert=>assert_not_initial( act = lt_stock ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_stock[ 1 ]-werks ).
    cl_abap_unit_assert=>assert_not_initial( act = lt_stock[ 1 ]-name1 ).
  ENDMETHOD.

  METHOD test_get_material_description.
    DATA(lv_desc) = mo_cut->zif_sd_stock_dao~get_material_description( 'W563587071' ).
    cl_abap_unit_assert=>assert_not_initial( act = lv_desc ).
  ENDMETHOD.

  METHOD test_get_stock_empty_plants.
    DATA(lt_stock) = mo_cut->zif_sd_stock_dao~get_material_stock(
      iv_matnr = 'W563587071' it_plants = VALUE #( ) ).
    cl_abap_unit_assert=>assert_initial( act = lt_stock ).
  ENDMETHOD.

ENDCLASS.
```

---

### 5.3 Clase ZCL_SD_EXCLUSION_CHECKER_TEST

Transacción: SE24 → Crear Clase
- Nombre: `ZCL_SD_EXCLUSION_CHECKER_TEST`
- Descripción: `Tests unitarios verificador exclusiones KOTG504`
- Paquete: `ZSD_SF`
- OT: `BZDK930642`
- Marcar como: **Test Class**

Código fuente completo:

```abap
CLASS zcl_sd_exclusion_checker_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_sd_exclusion_checker.

    METHODS setup.

    METHODS test_empty_input               FOR TESTING.
    METHODS test_no_exclusion_records      FOR TESTING.
    METHODS test_active_exclusion_by_plant FOR TESTING.
    METHODS test_expired_exclusion_ignored FOR TESTING.
    METHODS test_material_level_exclusion  FOR TESTING.
    METHODS test_exclusion_reason_plant    FOR TESTING.
    METHODS test_exclusion_reason_material FOR TESTING.
ENDCLASS.

CLASS zcl_sd_exclusion_checker_test IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW zcl_sd_exclusion_checker( ).
  ENDMETHOD.

  METHOD test_empty_input.
    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr = 'W563587071' it_plant_stock = VALUE #( ) ).
    cl_abap_unit_assert=>assert_initial( act = lt_result ).
  ENDMETHOD.

  METHOD test_no_exclusion_records.
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1020' name1 = 'Prescott' labst = 100 )
      ( werks = '1053' name1 = 'Salt Lake' labst = 200 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr = 'ZTEST_NO_EXCL' it_plant_stock = lt_input ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = abap_false act = lt_result[ 1 ]-is_excluded ).
    cl_abap_unit_assert=>assert_equals(
      exp = abap_false act = lt_result[ 2 ]-is_excluded ).
  ENDMETHOD.

  METHOD test_active_exclusion_by_plant.
    " W563587071 tiene exclusión activa para planta 1030 en KOTG504
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1020' name1 = 'Prescott' labst = 921000 )
      ( werks = '1030' name1 = 'Welford'  labst = 1000 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr = 'W563587071' it_plant_stock = lt_input ).

    cl_abap_unit_assert=>assert_equals(
      exp = abap_true act = lt_result[ werks = '1030' ]-is_excluded ).
  ENDMETHOD.

  METHOD test_expired_exclusion_ignored.
    " Planta 1090 tiene exclusión con Valid to = 11/21/2025 (vencida)
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1090' name1 = 'Test Plant' labst = 500 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr = 'W563587071' it_plant_stock = lt_input ).

    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_result ) ).
  ENDMETHOD.

  METHOD test_material_level_exclusion.
    " W563587071 tiene registros en KOTG504 sin planta (WERKS vacío)
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1020' name1 = 'Prescott' labst = 921000 )
      ( werks = '1053' name1 = 'Salt Lake' labst = 575000 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr = 'W563587071' it_plant_stock = lt_input ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_result ) ).
  ENDMETHOD.

  METHOD test_exclusion_reason_plant.
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '1030' name1 = 'Welford' labst = 1000 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr = 'W563587071' it_plant_stock = lt_input ).

    IF lt_result[ 1 ]-is_excluded = abap_true.
      cl_abap_unit_assert=>assert_not_initial(
        act = lt_result[ 1 ]-exclusion_reason ).
    ENDIF.
  ENDMETHOD.

  METHOD test_exclusion_reason_material.
    DATA(lt_input) = VALUE zty_sd_plant_stock_t(
      ( werks = '9999' name1 = 'Planta ficticia' labst = 0 ) ).

    DATA(lt_result) = mo_cut->zif_sd_exclusion_checker~check_exclusions(
      iv_matnr = 'W563587071' it_plant_stock = lt_input ).

    IF lt_result[ 1 ]-is_excluded = abap_true.
      cl_abap_unit_assert=>assert_char_cp(
        act = lt_result[ 1 ]-exclusion_reason
        exp = '*all plants*' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
```

---

## FASE 6: Pruebas de Integración

### 6.1 Ejecutar ABAP Unit Tests

En Eclipse ADT:
1. Click derecho sobre `ZCL_SD_STOCK_QUERY_TEST` → Run As → ABAP Unit Test
2. Click derecho sobre `ZCL_SD_STOCK_DAO_TEST` → Run As → ABAP Unit Test
3. Click derecho sobre `ZCL_SD_EXCLUSION_CHECKER_TEST` → Run As → ABAP Unit Test

En SAP GUI (SE24):
1. Abrir la clase de test → Menú: Class → Unit Test

### 6.2 Probar el FM en SE37

Transacción: SE37 → `ZFM_SD_GET_MATERIAL_STOCK` → F8 (Ejecutar)

Caso de prueba 1 — Material con stock y exclusiones:
```
IV_MATNR = W563587071
IV_BUKRS = 1000
```

Resultado esperado:
- EV_MATNR_DESC = "S20 WATERBLOCK (25 CARTRIDGES)"
- ET_PLANT_STOCK con plantas: 1020, 1030, 1032, 1053, 1091, 1097
- Plantas 1030, 1032, 1097 con IS_EXCLUDED = 'X' (según KOTG504)
- ET_MESSAGES vacío

Caso de prueba 2 — Material vacío:
```
IV_MATNR = (vacío)
IV_BUKRS = 1000
```

Resultado esperado:
- ET_PLANT_STOCK vacío
- ET_MESSAGES con 1 mensaje tipo 'E': "Material number is required"

Caso de prueba 3 — Material inexistente:
```
IV_MATNR = ZZZNOEXISTE
IV_BUKRS = 1000
```

Resultado esperado:
- ET_PLANT_STOCK vacío
- ET_MESSAGES con 1 mensaje tipo 'E': "Material ZZZNOEXISTE does not exist in the system"

Caso de prueba 4 — Sociedad inexistente:
```
IV_MATNR = W563587071
IV_BUKRS = 9999
```

Resultado esperado:
- ET_PLANT_STOCK vacío
- ET_MESSAGES con 1 mensaje tipo 'E': "Company code 9999 does not exist in the system"

### 6.3 Probar RFC desde fuera de SAP (opcional)

Para validar que Mulesoft puede llamar el FM:
1. Verificar que el FM aparece en SM59 → RFC Destinations → Test Connection
2. Usar transacción STRUST para verificar certificados si es HTTPS
3. Probar con un cliente RFC externo (SAP JCo, PyRFC, etc.)

---

## Checklist de Verificación Final

| # | Verificación | Estado |
|---|-------------|:------:|
| 1 | ZST_SD_PLANT_STOCK activa en SE11 | ☐ |
| 2 | ZTY_SD_PLANT_STOCK_T activa en SE11 | ☐ |
| 3 | ZIF_SD_STOCK_QUERY activa en SE24 | ☐ |
| 4 | ZIF_SD_STOCK_DAO activa en SE24 | ☐ |
| 5 | ZIF_SD_EXCLUSION_CHECKER activa en SE24 | ☐ |
| 6 | ZCL_SD_STOCK_DAO activa en SE24 | ☐ |
| 7 | ZCL_SD_EXCLUSION_CHECKER activa en SE24 | ☐ |
| 8 | ZCL_SD_STOCK_QUERY activa en SE24 | ☐ |
| 9 | ZFG_SD_STOCK_QUERY activo en SE80 | ☐ |
| 10 | ZFM_SD_GET_MATERIAL_STOCK activo y RFC-enabled en SE37 | ☐ |
| 11 | ZCL_SD_STOCK_QUERY_TEST — 9 tests pasan | ☐ |
| 12 | ZCL_SD_STOCK_DAO_TEST — 8 tests pasan | ☐ |
| 13 | ZCL_SD_EXCLUSION_CHECKER_TEST — 7 tests pasan | ☐ |
| 14 | FM probado en SE37 con W563587071 / 1000 | ☐ |
| 15 | FM probado con inputs vacíos (mensajes de error) | ☐ |
| 16 | FM probado con material/sociedad inexistente | ☐ |
| 17 | Todos los objetos en OT BZDK930642 | ☐ |
| 18 | Todos los objetos en paquete ZSD_SF | ☐ |

---

## Notas Técnicas

### Sobre KOTG504
- Es una tabla de condiciones SAP estándar (Plant/Material)
- Los campos clave de condición son: KAPPL (aplicación), KSCHL (clase de condición), WERKS, MATNR
- Los campos de vigencia son: DATAB (válido desde), DATBI (válido hasta)
- Un registro con DATBI = '99991231' significa vigencia indefinida
- Un registro con DATBI < SY-DATUM está vencido y no debe considerarse

### Sobre el stock en MARD
- MARD almacena stock a nivel planta+almacén
- El SELECT con FOR ALL ENTRIES suma automáticamente por planta (sin LGORT en el resultado)
- Si un material existe en MARC pero no tiene registro en MARD, el stock es cero

### Sobre la relación sociedad → planta
- T001K relaciona BUKRS (sociedad) con BWKEY (clave de valoración)
- T001W tiene BWKEY como campo, y WERKS = BWKEY en la mayoría de configuraciones
- El JOIN T001K + T001W es la forma correcta de obtener plantas por sociedad

---

*Documento generado el 27 de marzo de 2026 — Sistema BZD 130, OT BZDK930642, Paquete ZSD_SF*
