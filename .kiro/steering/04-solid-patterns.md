# Amrize BP — Patrones SOLID con Ejemplos Reales

## Single Responsibility Principle (SRP)
Cada clase tiene UNA razón para cambiar. Ejemplo real del proyecto ConsultaStockMaterial:
- `ZCL_SD_STOCK_DAO` — solo accede a datos (MARD, MARC, T001K, T001W, MAKT, MARA)
- `ZCL_SD_EXCLUSION_CHECKER` — solo evalúa exclusiones KOTG504
- `ZCL_SD_STOCK_QUERY` — solo orquesta el flujo (validar → obtener datos → verificar exclusiones)

NO: una clase que consulta BD, evalúa exclusiones Y orquesta el flujo.

## Open/Closed Principle (OCP)
Abierto para extensión, cerrado para modificación.
- Usar implementaciones de interfaz para nuevos comportamientos
- Ejemplo: si mañana se necesita otro tipo de exclusión (no KOTG504), se crea `ZCL_SD_EXCLUSION_CHECKER_V2` que implementa `ZIF_SD_EXCLUSION_CHECKER` — sin tocar el orquestador

## Liskov Substitution Principle (LSP)
Cualquier implementación de una interfaz debe ser intercambiable sin romper el sistema.
- Los test doubles (`LCL_DAO_DOUBLE`, `LCL_EXCLUSION_DOUBLE`) sustituyen a las clases reales en tests sin cambiar el orquestador

## Interface Segregation Principle (ISP)
Interfaces específicas, no interfaces gigantes.
- `ZIF_SD_STOCK_DAO` — 5 métodos de acceso a datos
- `ZIF_SD_EXCLUSION_CHECKER` — 1 método de exclusión
- `ZIF_SD_STOCK_QUERY` — 1 método de orquestación
NO: una sola interfaz con los 7 métodos juntos.

## Dependency Inversion Principle (DIP) — el más importante en ABAP
Las clases de negocio dependen de interfaces ZIF_, no de clases ZCL_ concretas.
Esto hace el código testeable con test doubles.

### Patrón de inyección de dependencias con defaults (validado)
```abap
CLASS zcl_sd_stock_query DEFINITION.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_dao       TYPE REF TO zif_sd_stock_dao       OPTIONAL
        io_exclusion TYPE REF TO zif_sd_exclusion_checker OPTIONAL.
  PRIVATE SECTION.
    DATA mo_dao       TYPE REF TO zif_sd_stock_dao.
    DATA mo_exclusion TYPE REF TO zif_sd_exclusion_checker.
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
ENDCLASS.
```
- En producción: se instancia sin parámetros → usa clases reales
- En tests: se inyectan test doubles → sin acceso a BD

### Patrón de test double local
```abap
CLASS lcl_dao_double DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sd_stock_dao.
    DATA mt_stock_to_return TYPE zty_sd_plant_stock_t.
    DATA mv_material_exists TYPE abap_bool VALUE abap_true.
ENDCLASS.
```
Los atributos públicos permiten configurar el comportamiento del double en cada test.

### Patrón FM como fachada de clases OO
Para exponer lógica OO como RFC-enabled (consumible por Mulesoft/Salesforce):
```abap
FUNCTION zfm_sd_get_material_stock.
  DATA lo_query TYPE REF TO zif_sd_stock_query.
  TRY.
      lo_query = NEW zcl_sd_stock_query( ).
      et_plant_stock[] = lo_query->get_stock_by_plant(
        EXPORTING iv_matnr = iv_matnr  iv_bukrs = iv_bukrs
        IMPORTING ev_matnr_desc = ev_matnr_desc
                  et_messages   = et_messages[] ).
    CATCH cx_root INTO DATA(lx_error).
      APPEND VALUE bapiret2( type = 'E' message = lx_error->get_text( ) )
        TO et_messages[].
  ENDTRY.
ENDFUNCTION.
```
El FM solo instancia y delega. Toda la lógica vive en las clases OO testeables.

## Arquitectura de referencia (ConsultaStockMaterial)
```
ZFM_SD_GET_MATERIAL_STOCK (FM RFC — fachada)
  └─ ZCL_SD_STOCK_QUERY (orquestador)
       ├─ ZIF_SD_STOCK_DAO → ZCL_SD_STOCK_DAO (acceso a datos)
       └─ ZIF_SD_EXCLUSION_CHECKER → ZCL_SD_EXCLUSION_CHECKER (reglas)

Tests:
  ZCL_SD_STOCK_QUERY_TEST
    ├─ LCL_DAO_DOUBLE (simula BD)
    └─ LCL_EXCLUSION_DOUBLE (simula exclusiones)
  ZCL_SD_STOCK_DAO_TEST (tests de integración)
  ZCL_SD_EXCLUSION_CHECKER_TEST (tests de integración)
```
