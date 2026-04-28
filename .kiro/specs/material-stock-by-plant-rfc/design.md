# Documento de Diseño: ZFM_SD_GET_MATERIAL_STOCK — Stock de Material por Planta (RFC)

## Resumen

FM RFC-enabled `ZFM_SD_GET_MATERIAL_STOCK` que permite a Mulesoft/Salesforce consultar el stock de un material por planta para una sociedad determinada, replicando la información de la transacción MMBE. La lógica de negocio se delega a clases OO siguiendo principios SOLID, con inyección de dependencias para facilitar el testing con ABAP Unit.

Sistema: SAP ECC 6.0 EHP8, ABAP 7.5 SP19. Paquete: ZDEV_SD.

---

## Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────┐
│  MULESOFT / SALESFORCE (sistema externo)                            │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ RFC call
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ZFG_SD_STOCK_QUERY  (Function Group)                               │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  ZFM_SD_GET_MATERIAL_STOCK  (RFC-enabled FM)                  │  │
│  │  - Recibe IV_MATNR, IV_BUKRS                                  │  │
│  │  - Instancia ZCL_SD_STOCK_QUERY                               │  │
│  │  - Captura excepciones no controladas                         │  │
│  │  - Retorna ET_PLANT_STOCK, ET_MESSAGES, EV_MATNR_DESC         │  │
│  └───────────────────────┬───────────────────────────────────────┘  │
└──────────────────────────┼──────────────────────────────────────────┘
                           │ llama a ZIF_SD_STOCK_QUERY
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ZCL_SD_STOCK_QUERY  (Orquestador — implementa ZIF_SD_STOCK_QUERY)  │
│  - Valida inputs                                                    │
│  - Coordina DAO y ExclusionChecker                                  │
│  - Sin acceso directo a BD                                          │
│  - Inyección de dependencias en constructor                         │
└──────────┬──────────────────────────────────┬───────────────────────┘
           │ ZIF_SD_STOCK_DAO                 │ ZIF_SD_EXCLUSION_CHECKER
           ▼                                  ▼
┌──────────────────────────┐    ┌─────────────────────────────────────┐
│  ZCL_SD_STOCK_DAO        │    │  ZCL_SD_EXCLUSION_CHECKER           │
│  (implementa ZIF_SD_     │    │  (implementa ZIF_SD_               │
│   STOCK_DAO)             │    │   EXCLUSION_CHECKER)                │
│  - Acceso a MARD, MARC   │    │  - Consulta KOTG504                 │
│  - T001K, T001W, MAKT    │    │  - Evalúa vigencia de exclusiones   │
│  - MARA, T001            │    │  - Asigna IS_EXCLUDED y REASON      │
└──────────┬───────────────┘    └──────────────┬──────────────────────┘
           │                                   │
           ▼                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│  BASE DE DATOS SAP                                                  │
│  MARD · MARC · T001W · T001K · MAKT · MARA · T001 · KOTG504        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Diagrama de Secuencia — Flujo Principal

```
Mulesoft          ZFM_SD_GET_MATERIAL_STOCK    ZCL_SD_STOCK_QUERY    ZCL_SD_STOCK_DAO    ZCL_SD_EXCLUSION_CHECKER
   │                        │                         │                     │                       │
   │── RFC call ───────────>│                         │                     │                       │
   │   IV_MATNR, IV_BUKRS   │                         │                     │                       │
   │                        │── get_stock_by_plant ──>│                     │                       │
   │                        │                         │── validate_material>│                       │
   │                        │                         │<── rv_exists ───────│                       │
   │                        │                         │── validate_company >│                       │
   │                        │                         │<── rv_exists ───────│                       │
   │                        │                         │── get_plants ──────>│                       │
   │                        │                         │<── rt_plants ───────│                       │
   │                        │                         │── get_material_stock>│                      │
   │                        │                         │<── rt_stock ────────│                       │
   │                        │                         │── check_exclusions ─────────────────────────>│
   │                        │                         │<── rt_result (con IS_EXCLUDED) ──────────────│
   │                        │                         │── get_material_desc>│                       │
   │                        │                         │<── rv_desc ─────────│                       │
   │                        │<── rt_result ───────────│                     │                       │
   │<── ET_PLANT_STOCK ─────│                         │                     │                       │
   │    ET_MESSAGES          │                         │                     │                       │
   │    EV_MATNR_DESC        │                         │                     │                       │
```


---

## Objetos DDIC

### ZST_SD_PLANT_STOCK — Estructura de respuesta por planta

| Campo            | Tipo referencia  | Descripción                          |
|------------------|------------------|--------------------------------------|
| WERKS            | WERKS_D          | Planta                               |
| NAME1            | T001W-NAME1      | Nombre de la planta                  |
| LABST            | MARD-LABST       | Stock de libre utilización           |
| EINME            | MARD-EINME       | Stock en control de calidad          |
| SPEME            | MARD-SPEME       | Stock bloqueado                      |
| EISBE            | MARD-EISBE       | Stock de seguridad / en pedido       |
| IS_EXCLUDED      | ABAP_BOOL        | Flag de exclusión KOTG504 ('X'/space)|
| EXCLUSION_REASON | CHAR255          | Motivo de exclusión (texto libre)    |

### ZTY_SD_PLANT_STOCK_T — Tipo tabla

```abap
TYPES zty_sd_plant_stock_t TYPE TABLE OF zst_sd_plant_stock.
```

---

## Interfaces

### ZIF_SD_STOCK_QUERY

Interfaz del orquestador principal. Punto de entrada para la lógica de negocio.

```abap
INTERFACE zif_sd_stock_query PUBLIC.

  "! Consulta el stock de un material por planta para una sociedad.
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

### ZIF_SD_STOCK_DAO

Interfaz del Data Access Object. Abstrae todo acceso a tablas SAP.

```abap
INTERFACE zif_sd_stock_dao PUBLIC.

  "! Retorna el rango de plantas asociadas a una sociedad (T001K + T001W).
  "! @parameter iv_bukrs   | Sociedad
  "! @parameter rt_plants  | Rango de plantas (para uso en WHERE ... IN)
  METHODS get_plants_for_company
    IMPORTING iv_bukrs TYPE bukrs
    RETURNING VALUE(rt_plants) TYPE RANGE OF werks_d.

  "! Retorna stock por planta para un material, solo plantas activas en MARC.
  "! @parameter iv_matnr  | Número de material
  "! @parameter it_plants | Rango de plantas a consultar
  "! @parameter rt_stock  | Stock por planta (LABST, EINME, SPEME, EISBE, NAME1)
  METHODS get_material_stock
    IMPORTING
      iv_matnr  TYPE matnr
      it_plants TYPE RANGE OF werks_d
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

### ZIF_SD_EXCLUSION_CHECKER

Interfaz del verificador de exclusiones KOTG504.

```abap
INTERFACE zif_sd_exclusion_checker PUBLIC.

  "! Evalúa exclusiones KOTG504 para todas las plantas del resultado.
  "! Una sola consulta a BD; sin SELECTs en LOOP.
  "! @parameter iv_matnr       | Número de material
  "! @parameter it_plant_stock | Stock por planta (entrada)
  "! @parameter rt_result      | Stock por planta con IS_EXCLUDED y EXCLUSION_REASON poblados
  METHODS check_exclusions
    IMPORTING
      iv_matnr       TYPE matnr
      it_plant_stock TYPE zty_sd_plant_stock_t
    RETURNING VALUE(rt_result) TYPE zty_sd_plant_stock_t.

ENDINTERFACE.
```


---

## Clases

### ZFM_SD_GET_MATERIAL_STOCK — Function Module RFC-enabled

Punto de entrada RFC. Sin lógica de negocio propia: instancia el orquestador y delega.

```abap
FUNCTION zfm_sd_get_material_stock
  REMOTE-ENABLED MODULE
  IMPORTING
    iv_matnr TYPE matnr
    iv_bukrs TYPE bukrs
  EXPORTING
    ev_matnr_desc TYPE makt-maktx
  TABLES
    et_plant_stock TYPE zty_sd_plant_stock_t
    et_messages    TYPE bapiret2_t.

  DATA lo_query TYPE REF TO zif_sd_stock_query.

  TRY.
      lo_query = NEW zcl_sd_stock_query( ).
      et_plant_stock = lo_query->get_stock_by_plant(
        EXPORTING
          iv_matnr      = iv_matnr
          iv_bukrs      = iv_bukrs
        IMPORTING
          ev_matnr_desc = ev_matnr_desc
          et_messages   = et_messages ).
    CATCH cx_root INTO DATA(lx_error).
      APPEND VALUE #(
        type       = 'E'
        message    = lx_error->get_text( )
      ) TO et_messages.
  ENDTRY.

ENDFUNCTION.
```

---

### ZCL_SD_STOCK_QUERY — Orquestador principal

Implementa `ZIF_SD_STOCK_QUERY`. Coordina validaciones, consulta de stock y verificación de exclusiones. No contiene ningún SELECT.

#### Definición

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

    METHODS add_error_message
      IMPORTING iv_text TYPE string
      CHANGING  ct_messages TYPE bapiret2_t.

    METHODS add_info_message
      IMPORTING iv_text TYPE string
      CHANGING  ct_messages TYPE bapiret2_t.

ENDCLASS.
```

#### Implementación del constructor

```abap
METHOD constructor.
  mo_dao = COND #(
    WHEN io_dao IS BOUND THEN io_dao
    ELSE NEW zcl_sd_stock_dao( ) ).
  mo_exclusion = COND #(
    WHEN io_exclusion IS BOUND THEN io_exclusion
    ELSE NEW zcl_sd_exclusion_checker( ) ).
ENDMETHOD.
```

#### Pseudocódigo: get_stock_by_plant

```pascal
PROCEDURE get_stock_by_plant(iv_matnr, iv_bukrs)
  OUTPUT: rt_result, ev_matnr_desc, et_messages

  SEQUENCE
    " Paso 1: Validar parámetros de entrada
    IF iv_matnr IS INITIAL THEN
      add_error_message('El número de material es obligatorio')
      RETURN vacío
    END IF

    IF iv_bukrs IS INITIAL THEN
      add_error_message('La sociedad es obligatoria')
      RETURN vacío
    END IF

    " Paso 2: Validar existencia en BD
    IF mo_dao->validate_material(iv_matnr) = ABAP_FALSE THEN
      add_error_message('El material no existe en el sistema')
      RETURN vacío
    END IF

    IF mo_dao->validate_company(iv_bukrs) = ABAP_FALSE THEN
      add_error_message('La sociedad no existe en el sistema')
      RETURN vacío
    END IF

    " Paso 3: Obtener plantas de la sociedad
    lt_plants ← mo_dao->get_plants_for_company(iv_bukrs)

    " Paso 4: Obtener stock por planta
    lt_stock ← mo_dao->get_material_stock(iv_matnr, lt_plants)

    " Paso 5: Verificar si hay stock
    IF lt_stock IS INITIAL THEN
      add_info_message('No se encontró stock para el material en la sociedad')
      RETURN vacío
    END IF

    " Paso 6: Evaluar exclusiones KOTG504
    lt_stock ← mo_exclusion->check_exclusions(iv_matnr, lt_stock)

    " Paso 7: Obtener descripción del material
    ev_matnr_desc ← mo_dao->get_material_description(iv_matnr)

    " Paso 8: Retornar resultado
    rt_result ← lt_stock
  END SEQUENCE
END PROCEDURE
```


---

### ZCL_SD_STOCK_DAO — Data Access Object

Implementa `ZIF_SD_STOCK_DAO`. Centraliza todo acceso a tablas SAP. Sin lógica de negocio.

#### Implementación: get_plants_for_company

Obtiene las plantas de una sociedad mediante JOIN entre T001K y T001W.

```abap
METHOD zif_sd_stock_dao~get_plants_for_company.
  SELECT t1w~werks
    FROM t001k AS t1k
    INNER JOIN t001w AS t1w ON t1w~bwkey = t1k~bwkey
    WHERE t1k~bukrs = @iv_bukrs
    INTO TABLE @DATA(lt_werks).

  rt_plants = VALUE #( FOR ls_w IN lt_werks
    ( sign = 'I' option = 'EQ' low = ls_w-werks ) ).
ENDMETHOD.
```

#### Implementación: get_material_stock

Primero filtra plantas donde el material está activo en MARC (sin LVORM), luego obtiene stock de MARD con FOR ALL ENTRIES. Combina el resultado con NAME1 de T001W.

```abap
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
  SELECT matnr, werks, labst, einme, speme, eisbe
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

  " Paso 4: Construir resultado — incluir todas las plantas de MARC,
  "         con stock de MARD si existe, o ceros si no hay registro en MARD
  rt_stock = VALUE #(
    FOR ls_marc IN lt_marc
    LET ls_mard  = VALUE #( lt_mard[]  [ matnr = ls_marc-matnr
                                          werks = ls_marc-werks ] OPTIONAL )
        ls_t001w = VALUE #( lt_t001w[] [ werks = ls_marc-werks ] OPTIONAL )
    IN (
      werks = ls_marc-werks
      name1 = ls_t001w-name1
      labst = ls_mard-labst
      einme = ls_mard-einme
      speme = ls_mard-speme
      eisbe = ls_mard-eisbe
    )
  ).
ENDMETHOD.
```

#### Implementación: validate_material

```abap
METHOD zif_sd_stock_dao~validate_material.
  SELECT SINGLE matnr FROM mara
    WHERE matnr = @iv_matnr
    INTO @DATA(lv_matnr).
  rv_exists = xsdbool( sy-subrc = 0 ).
ENDMETHOD.
```

#### Implementación: validate_company

```abap
METHOD zif_sd_stock_dao~validate_company.
  SELECT SINGLE bukrs FROM t001
    WHERE bukrs = @iv_bukrs
    INTO @DATA(lv_bukrs).
  rv_exists = xsdbool( sy-subrc = 0 ).
ENDMETHOD.
```

#### Implementación: get_material_description

```abap
METHOD zif_sd_stock_dao~get_material_description.
  SELECT SINGLE maktx FROM makt
    WHERE matnr = @iv_matnr
      AND spras = 'EN'
    INTO @rv_desc.
ENDMETHOD.
```

---

### ZCL_SD_EXCLUSION_CHECKER — Verificador de exclusiones KOTG504

Implementa `ZIF_SD_EXCLUSION_CHECKER`. Una sola consulta a KOTG504 para todas las plantas; sin SELECT en LOOP.

#### Pseudocódigo: check_exclusions

```pascal
PROCEDURE check_exclusions(iv_matnr, it_plant_stock)
  OUTPUT: rt_result

  SEQUENCE
    " Paso 1: Una sola consulta a KOTG504 para el material
    " Filtra registros activos: datab <= hoy AND (datbi >= hoy OR datbi = fecha_alta)
    SELECT kappl, kschl, werks, matnr, datab, datbi
      FROM kotg504
      WHERE matnr = iv_matnr
        AND kappl = 'V'
        AND kschl = 'ZB01'
        AND datab <= sy-datum
        AND ( datbi >= sy-datum OR datbi = gc_high_date )
      INTO TABLE lt_exclusions

    " Paso 2: Copiar entrada como base del resultado
    rt_result ← it_plant_stock

    " Paso 3: Para cada planta en el resultado, verificar exclusión
    " (READ TABLE sobre lt_exclusions — sin SELECT en LOOP)
    FOR EACH ls_stock IN rt_result DO
      " Verificar exclusión específica por planta
      READ TABLE lt_exclusions WITH KEY werks = ls_stock-werks
        INTO ls_excl_plant

      " Verificar exclusión a nivel material (WERKS vacío)
      READ TABLE lt_exclusions WITH KEY werks = space
        INTO ls_excl_material

      IF ls_excl_plant FOUND THEN
        ls_stock-is_excluded      = ABAP_TRUE
        ls_stock-exclusion_reason = 'Planta excluida para este material (KOTG504)'
      ELSE IF ls_excl_material FOUND THEN
        ls_stock-is_excluded      = ABAP_TRUE
        ls_stock-exclusion_reason = 'Material excluido para todas las plantas (KOTG504)'
      ELSE
        ls_stock-is_excluded      = ABAP_FALSE
        ls_stock-exclusion_reason = space
      END IF
    END FOR
  END SEQUENCE
END PROCEDURE
```

#### Constante de fecha alta

```abap
CONSTANTS gc_high_date TYPE dats VALUE '99991231'.
```


---

## Tablas SAP involucradas

| Tabla   | Campos usados                                    | Propósito                                      |
|---------|--------------------------------------------------|------------------------------------------------|
| MARA    | MATNR                                            | Validar existencia del material                |
| T001    | BUKRS                                            | Validar existencia de la sociedad              |
| T001K   | BUKRS, BWKEY                                     | Relacionar sociedad con clave de valoración    |
| T001W   | WERKS, NAME1, BWKEY                              | Obtener plantas y nombres por sociedad         |
| MARC    | MATNR, WERKS, LVORM                              | Filtrar plantas activas para el material       |
| MARD    | MATNR, WERKS, LABST, EINME, SPEME, EISBE         | Stock por planta/almacén                       |
| MAKT    | MATNR, SPRAS, MAKTX                              | Descripción del material en idioma EN          |
| KOTG504 | KAPPL, KSCHL, WERKS, MATNR, DATAB, DATBI         | Exclusiones planta/material vigentes           |

---

## Modelo de datos — relaciones clave

```
T001 (BUKRS)
  └─► T001K (BUKRS → BWKEY)
        └─► T001W (BWKEY = WERKS → NAME1)
              └─► MARC (WERKS + MATNR → LVORM)
                    └─► MARD (WERKS + MATNR → LABST, EINME, SPEME, EISBE)

MARA (MATNR) ──► MAKT (MATNR + SPRAS='EN' → MAKTX)

KOTG504 (MATNR + WERKS + KAPPL='V' + KSCHL='ZB01' + fechas vigentes → exclusión)
```

---

## Especificaciones formales de métodos clave

### get_stock_by_plant

**Precondiciones:**
- `iv_matnr` puede ser cualquier valor (incluyendo vacío — se valida internamente)
- `iv_bukrs` puede ser cualquier valor (incluyendo vacío — se valida internamente)

**Postcondiciones:**
- Si `iv_matnr` o `iv_bukrs` están vacíos → `rt_result` vacío, `et_messages` contiene mensaje tipo 'E'
- Si material no existe en MARA → `rt_result` vacío, `et_messages` contiene mensaje tipo 'E'
- Si sociedad no existe en T001 → `rt_result` vacío, `et_messages` contiene mensaje tipo 'E'
- Si inputs válidos pero sin stock → `rt_result` vacío, `et_messages` contiene mensaje tipo 'I'
- Si inputs válidos con stock → `rt_result` contiene una entrada por cada planta activa en MARC, con IS_EXCLUDED correctamente asignado
- `ev_matnr_desc` se popula solo cuando `rt_result` no está vacío

**Invariante:** `ZCL_SD_STOCK_QUERY` no ejecuta ningún SELECT directo.

### check_exclusions

**Precondiciones:**
- `iv_matnr` es un material válido (ya validado por el orquestador)
- `it_plant_stock` puede estar vacío (retorna vacío sin consultar BD)

**Postcondiciones:**
- Para cada entrada en `rt_result`: `IS_EXCLUDED = 'X'` si y solo si existe registro activo en KOTG504 con `MATNR = iv_matnr` y (`WERKS = planta` o `WERKS = space`)
- Registros con `DATBI < SY-DATUM` no afectan `IS_EXCLUDED`
- Exactamente una consulta a KOTG504 por invocación (sin SELECT en LOOP)

### get_material_stock

**Precondiciones:**
- `iv_matnr` es un material válido
- `it_plants` es un rango no vacío de plantas de la sociedad

**Postcondiciones:**
- Solo se incluyen plantas donde `MARC-LVORM = space` (no marcadas para borrado)
- Para plantas en MARC sin registro en MARD: LABST, EINME, SPEME, EISBE = 0
- Los valores de stock coinciden exactamente con MARD para la combinación MATNR+WERKS


---

## Estrategia de Testing

### Estructura general de clases de prueba

Cada clase de negocio tiene su clase de prueba `_TEST` con ABAP Unit. Las clases de prueba del orquestador usan test doubles (implementaciones locales de las interfaces) para aislar la lógica de negocio del acceso a BD.

```
ZCL_SD_STOCK_QUERY_TEST      → usa test doubles de ZIF_SD_STOCK_DAO y ZIF_SD_EXCLUSION_CHECKER
ZCL_SD_STOCK_DAO_TEST        → prueba consultas reales (requiere datos de prueba en BD)
ZCL_SD_EXCLUSION_CHECKER_TEST → prueba lógica de fechas y flags con datos controlados
```

### Patrón de test double en ABAP Unit

```abap
" Clase de prueba con test double local para ZIF_SD_STOCK_DAO
CLASS lcl_dao_double DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sd_stock_dao.
    DATA mt_stock_to_return TYPE zty_sd_plant_stock_t.
    DATA mv_material_exists  TYPE abap_bool VALUE abap_true.
    DATA mv_company_exists   TYPE abap_bool VALUE abap_true.
ENDCLASS.

CLASS lcl_dao_double IMPLEMENTATION.
  METHOD zif_sd_stock_dao~validate_material.
    rv_exists = mv_material_exists.
  ENDMETHOD.
  METHOD zif_sd_stock_dao~validate_company.
    rv_exists = mv_company_exists.
  ENDMETHOD.
  METHOD zif_sd_stock_dao~get_plants_for_company.
    rt_plants = VALUE #( ( sign = 'I' option = 'EQ' low = '1000' ) ).
  ENDMETHOD.
  METHOD zif_sd_stock_dao~get_material_stock.
    rt_stock = mt_stock_to_return.
  ENDMETHOD.
  METHOD zif_sd_stock_dao~get_material_description.
    rv_desc = 'CEMENT TYPE I'.
  ENDMETHOD.
ENDCLASS.
```

---

### ZCL_SD_STOCK_QUERY_TEST — Casos de prueba

| Método de prueba                  | Escenario                                              | Resultado esperado                                      |
|-----------------------------------|--------------------------------------------------------|---------------------------------------------------------|
| `test_valid_material_and_company` | Material y sociedad válidos, stock en 2 plantas        | ET_PLANT_STOCK con 2 entradas, ET_MESSAGES vacío        |
| `test_empty_matnr`                | IV_MATNR = space                                       | ET_PLANT_STOCK vacío, ET_MESSAGES con 1 mensaje tipo 'E'|
| `test_empty_bukrs`                | IV_BUKRS = space                                       | ET_PLANT_STOCK vacío, ET_MESSAGES con 1 mensaje tipo 'E'|
| `test_material_not_found`         | validate_material retorna ABAP_FALSE                   | ET_PLANT_STOCK vacío, ET_MESSAGES con 1 mensaje tipo 'E'|
| `test_company_not_found`          | validate_company retorna ABAP_FALSE                    | ET_PLANT_STOCK vacío, ET_MESSAGES con 1 mensaje tipo 'E'|
| `test_no_stock_found`             | get_material_stock retorna tabla vacía                 | ET_PLANT_STOCK vacío, ET_MESSAGES con 1 mensaje tipo 'I'|
| `test_excluded_plant_flagged`     | check_exclusions retorna IS_EXCLUDED = 'X' para planta | ET_PLANT_STOCK con IS_EXCLUDED = 'X' en esa planta      |
| `test_non_excluded_plant`         | check_exclusions retorna IS_EXCLUDED = space           | ET_PLANT_STOCK con IS_EXCLUDED = space                  |
| `test_matnr_desc_populated`       | Material válido con stock                              | EV_MATNR_DESC = 'CEMENT TYPE I'                         |

### ZCL_SD_EXCLUSION_CHECKER_TEST — Casos de prueba

| Método de prueba                    | Escenario                                                    | Resultado esperado                              |
|-------------------------------------|--------------------------------------------------------------|-------------------------------------------------|
| `test_active_exclusion_by_plant`    | KOTG504 con WERKS='1000', fechas vigentes                    | IS_EXCLUDED='X' solo para planta 1000           |
| `test_expired_exclusion_ignored`    | KOTG504 con DATBI < SY-DATUM                                 | IS_EXCLUDED=space (exclusión vencida ignorada)  |
| `test_material_level_exclusion`     | KOTG504 con WERKS=space, fechas vigentes                     | IS_EXCLUDED='X' para todas las plantas          |
| `test_no_exclusion`                 | Sin registros en KOTG504 para el material                    | IS_EXCLUDED=space en todas las plantas          |
| `test_future_exclusion_ignored`     | KOTG504 con DATAB > SY-DATUM                                 | IS_EXCLUDED=space (exclusión futura ignorada)   |
| `test_exclusion_reason_plant`       | Exclusión específica por planta                              | EXCLUSION_REASON contiene texto de planta       |
| `test_exclusion_reason_material`    | Exclusión a nivel material (WERKS=space)                     | EXCLUSION_REASON contiene texto de material     |

### ZCL_SD_STOCK_DAO_TEST — Casos de prueba

| Método de prueba                    | Escenario                                                    | Resultado esperado                              |
|-------------------------------------|--------------------------------------------------------------|-------------------------------------------------|
| `test_get_plants_for_company`       | Sociedad con 3 plantas en T001K/T001W                        | rt_plants con 3 entradas tipo RANGE             |
| `test_validate_material_exists`     | Material existente en MARA                                   | rv_exists = ABAP_TRUE                           |
| `test_validate_material_not_exists` | Material inexistente en MARA                                 | rv_exists = ABAP_FALSE                          |
| `test_validate_company_exists`      | Sociedad existente en T001                                   | rv_exists = ABAP_TRUE                           |
| `test_get_stock_excludes_deleted`   | Material con MARC-LVORM = 'X' en una planta                  | Planta con LVORM='X' no aparece en rt_stock     |
| `test_get_stock_zero_when_no_mard`  | Material en MARC pero sin registro en MARD                   | Planta incluida con LABST=0, EINME=0, etc.      |


---

## Propiedades de Corrección

Las propiedades son invariantes que deben mantenerse verdaderas en todas las ejecuciones válidas del sistema. Se expresan como aserciones verificables mediante pruebas basadas en propiedades (property-based testing).

### Propiedad 1: Aislamiento por sociedad

Para cualquier combinación válida de `iv_matnr` e `iv_bukrs`, todas las entradas en `ET_PLANT_STOCK` deben pertenecer exclusivamente a plantas asociadas a `iv_bukrs` mediante T001K/T001W.

```pascal
PARA TODO iv_matnr, iv_bukrs válidos:
  PARA TODA entrada ls_stock EN ET_PLANT_STOCK:
    EXISTE t1k EN T001K: t1k-bukrs = iv_bukrs AND t1k-bwkey = t1w-bwkey
    DONDE t1w EN T001W: t1w-werks = ls_stock-werks
```

**Valida:** Requisito 2.1

### Propiedad 2: Consistencia de stock con MARD

Para cualquier entrada en `ET_PLANT_STOCK`, los valores de stock deben coincidir exactamente con MARD.

```pascal
PARA TODA entrada ls_stock EN ET_PLANT_STOCK:
  SI EXISTE mard: mard-matnr = iv_matnr AND mard-werks = ls_stock-werks ENTONCES
    ls_stock-labst = mard-labst AND
    ls_stock-einme = mard-einme AND
    ls_stock-speme = mard-speme AND
    ls_stock-eisbe = mard-eisbe
  SINO
    ls_stock-labst = 0 AND ls_stock-einme = 0 AND
    ls_stock-speme = 0 AND ls_stock-eisbe = 0
```

**Valida:** Requisitos 2.2, 4.4

### Propiedad 3: Corrección del flag IS_EXCLUDED

`IS_EXCLUDED = 'X'` si y solo si existe al menos un registro activo en KOTG504.

```pascal
PARA TODA entrada ls_stock EN ET_PLANT_STOCK:
  ls_stock-is_excluded = 'X'
  ⟺
  EXISTE kotg504: kotg504-matnr = iv_matnr
    AND (kotg504-werks = ls_stock-werks OR kotg504-werks = space)
    AND kotg504-kappl = 'V' AND kotg504-kschl = 'ZB01'
    AND kotg504-datab <= sy-datum
    AND (kotg504-datbi >= sy-datum OR kotg504-datbi = '99991231')
```

**Valida:** Requisitos 3.2, 3.3

### Propiedad 4: Exclusiones vencidas no afectan el resultado

Ningún registro de KOTG504 con `DATBI < SY-DATUM` puede causar `IS_EXCLUDED = 'X'`.

```pascal
PARA TODO registro kotg504: kotg504-datbi < sy-datum:
  NO EXISTE ls_stock EN ET_PLANT_STOCK:
    ls_stock-werks = kotg504-werks AND
    ls_stock-is_excluded = 'X'
    CAUSADO POR ese registro
```

**Valida:** Requisito 3.4

### Propiedad 5: Exclusión a nivel material aplica a todas las plantas

Si existe un registro activo en KOTG504 con `WERKS = space` para el material, todas las plantas deben tener `IS_EXCLUDED = 'X'`.

```pascal
SI EXISTE kotg504: kotg504-matnr = iv_matnr AND kotg504-werks = space
  AND kotg504-datab <= sy-datum AND (kotg504-datbi >= sy-datum OR kotg504-datbi = '99991231')
ENTONCES
  PARA TODA entrada ls_stock EN ET_PLANT_STOCK:
    ls_stock-is_excluded = 'X'
```

**Valida:** Requisito 3.2

### Propiedad 6: ET_PLANT_STOCK vacío con mensaje cuando no hay stock

Si el material no existe en ninguna planta de la sociedad, el resultado debe estar vacío y los mensajes no deben estar vacíos.

```pascal
SI ET_PLANT_STOCK IS INITIAL ENTONCES
  ET_MESSAGES IS NOT INITIAL AND
  EXISTE msg EN ET_MESSAGES: msg-type IN ('E', 'I')
```

**Valida:** Requisitos 2.6, 5.3, 5.4

### Propiedad 7: Descripción del material en idioma EN

`EV_MATNR_DESC` debe coincidir con MAKT para `SPRAS = 'EN'`.

```pascal
SI ET_PLANT_STOCK IS NOT INITIAL ENTONCES
  EV_MATNR_DESC = makt-maktx
  DONDE makt-matnr = iv_matnr AND makt-spras = 'EN'
```

**Valida:** Requisito 2.4

### Propiedad 8: Completitud de campos en ET_PLANT_STOCK

Campos obligatorios siempre poblados; campos de stock siempre >= 0.

```pascal
PARA TODA entrada ls_stock EN ET_PLANT_STOCK:
  ls_stock-werks IS NOT INITIAL AND
  ls_stock-name1 IS NOT INITIAL AND
  ls_stock-is_excluded IN (abap_true, abap_false) AND
  ls_stock-labst >= 0 AND ls_stock-einme >= 0 AND
  ls_stock-speme >= 0 AND ls_stock-eisbe >= 0
```

**Valida:** Requisitos 4.1, 4.3

---

## Consideraciones de Rendimiento

- `get_plants_for_company`: JOIN entre T001K y T001W — resultado acotado (máximo ~50 plantas por sociedad en Holcim BP). Sin riesgo de performance.
- `get_material_stock`: SELECT sobre MARC con filtro por MATNR + rango de plantas, seguido de FOR ALL ENTRIES sobre MARD. El FOR ALL ENTRIES se ejecuta solo si MARC retorna resultados. Ambas tablas tienen índices primarios eficientes sobre MATNR+WERKS.
- `check_exclusions`: Una sola consulta a KOTG504 filtrada por MATNR + fechas. KOTG504 es una tabla de condiciones con volumen moderado; el filtro por MATNR acota el resultado significativamente.
- No se usan cursores ni OPEN CURSOR — todas las consultas son SELECT INTO TABLE con resultado acotado.

---

## Consideraciones de Seguridad

- El FM es RFC-enabled: Mulesoft debe autenticarse con un usuario RFC dedicado con perfil mínimo necesario (solo lectura sobre las tablas involucradas).
- No se realizan modificaciones a datos (solo lectura): sin riesgo de corrupción de datos por llamadas RFC.
- No se usa `SY-MANDT` hardcodeado — el mandante se toma del contexto de sesión SAP automáticamente.
- Los parámetros de entrada `IV_MATNR` e `IV_BUKRS` se validan antes de cualquier acceso a BD, previniendo consultas con parámetros vacíos que podrían retornar datos masivos.

---

## Dependencias

| Objeto          | Tipo              | Descripción                                              |
|-----------------|-------------------|----------------------------------------------------------|
| MARA            | Tabla SAP estándar| Validación de existencia de material                     |
| T001            | Tabla SAP estándar| Validación de existencia de sociedad                     |
| T001K           | Tabla SAP estándar| Relación sociedad → clave de valoración                  |
| T001W           | Tabla SAP estándar| Plantas y nombres                                        |
| MARC            | Tabla SAP estándar| Datos de material por planta (incluye flag LVORM)        |
| MARD            | Tabla SAP estándar| Stock por planta/almacén                                 |
| MAKT            | Tabla SAP estándar| Descripciones de material                                |
| KOTG504         | Tabla SAP estándar| Condiciones de exclusión planta/material                 |
| BAPIRET2_T      | Tipo SAP estándar | Tabla de mensajes de retorno (tipo de ET_MESSAGES)       |
| ABAP_BOOL       | Tipo SAP estándar | Flag booleano ('X' / space)                              |
| MATNR, BUKRS    | Tipos de dominio  | Tipos de los parámetros de entrada del FM                |
| WERKS_D         | Tipo de dominio   | Tipo del campo WERKS en ZST_SD_PLANT_STOCK               |
