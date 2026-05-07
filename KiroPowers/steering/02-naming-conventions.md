# Amrize BP — Convenciones de Nomenclatura

## Prefijos por tipo de objeto
| Objeto              | Prefijo      | Ejemplo                        |
|---------------------|--------------|--------------------------------|
| Clase               | ZCL_         | ZCL_SD_STOCK_QUERY             |
| Interfaz            | ZIF_         | ZIF_SD_STOCK_DAO               |
| Programa/Report     | Z o ZR_      | ZR_SD_QUICK_ORDERS             |
| Function Group      | ZFG_         | ZFG_SD_STOCK_QUERY             |
| Function Module     | Z o ZFM_     | ZFM_SD_GET_MATERIAL_STOCK      |
| Tabla Z             | ZTAB_        | ZTAB_SD_PRICING_EXT            |
| Estructura DDIC     | ZST_         | ZST_SD_PLANT_STOCK             |
| Tipo Tabla DDIC     | ZTY_         | ZTY_SD_PLANT_STOCK_T           |
| BADi Impl.          | ZI_          | ZI_BADI_SD_PRICING             |
| Clase Test          | _TEST        | ZCL_SD_STOCK_QUERY_TEST        |
| Test Double local   | LCL_*_DOUBLE | LCL_DAO_DOUBLE, LCL_EXCLUSION_DOUBLE |
| Include TOP         | _TOP         | ZSDR_DAILY_INVOICE_REPORT_TOP  |
| Include Pantalla    | _SCR         | ZSDR_DAILY_INVOICE_REPORT_SCR  |
| Include Clases      | _C01         | ZSDR_DAILY_INVOICE_REPORT_C01  |
| Include Forms       | _F01         | ZSDR_DAILY_INVOICE_REPORT_F01  |

## Convenciones de variables locales
- Variables de instancia: `mo_` (ref object), `mv_` (value), `mt_` (table), `ms_` (structure)
- Variables locales en métodos: `lv_` (value), `lt_` (table), `ls_` (structure), `lo_` (ref object)
- Parámetros de método: `iv_` (import value), `ev_` (export value), `it_` (import table), `et_` (export table)
- Constantes de clase: `gc_` (ej: gc_high_date, gc_app, gc_kschl)
- Variables globales en reports clásicos: `gv_` (value), `gt_` (table), `gs_` (structure)

## Search terms en código modificado
Todo bloque de código insertado o modificado debe marcarse con el número del Change Request:
```abap
" +CHG0436393 — BEGIN
  ... código nuevo ...
" +CHG0436393 — END
```
Esto permite buscar todos los cambios de un CR con Ctrl+F en Eclipse o con grep.

## Convenciones de archivos locales en el workspace
- Cada proyecto/CR tiene su propia carpeta: `L2C_CHG0436393/`, `ConsultaStockMaterial/`
- Código ABAP local: `NOMBRE_OBJETO.abap`
- Análisis técnico: `ANALISIS_*.md` o `TD_*.md` (Technical Design)
- Guías de implementación: `GUIA_IMPLEMENTACION_*.md`

## Paquetes de desarrollo
- `ZSD_SF` — integraciones SD con Salesforce/Mulesoft
- `ZDEV_SD` — desarrollos generales SD
- `$TMP` — solo POCs y pruebas (nunca productivo)
