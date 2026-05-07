---
inclusion: manual
---
# Inventario de Versiones — Amrize BP

## Última actualización: 2026-05-06

---

## Sistema SAP

| Componente | Versión | Detalle |
|-----------|---------|---------|
| SAP ECC | 6.0 EHP8 | Sistema productivo |
| Sistema ID | BZD | Desarrollo principal |
| Mandante | 130 | Cliente de desarrollo |
| Servidor | fbpl08v010.holcimbp.net:8000 | Application server |
| ABAP | 7.50 SP19 | NO es S/4HANA, NO es ABAP Cloud |

### Sistema Sandbox (BZN)
| Componente | Valor |
|-----------|-------|
| Sistema ID | BZN |
| Mandante | 100 |
| Servidor | lfh02a09ld075.holcimbp.net:8040 |
| Usuario MCP | AHERNA11 |

## Módulos SAP en uso

| Módulo | Área | Uso principal |
|--------|------|--------------|
| SD | Ventas | Pedidos, cotizaciones, ATP, pricing |
| MM | Materiales | Inventario, compras, stock |
| FI | Finanzas | Contabilidad general |
| PP | Producción | Planificación, MRP |
| WM | Almacén | Gestión de warehouse |
| CRM | Middleware | Integración CRM ↔ ECC (BTMBDOC) |

## Restricciones de sintaxis ABAP

- ✅ Sintaxis ABAP 7.50: VALUE, FILTER, REDUCE, string templates, inline declarations
- ✅ NEW, CONV, CORRESPONDING, COND, SWITCH, xsdbool()
- ✅ FOR ... IN, LOOP AT ... GROUP BY
- ⚠️ VALUE #() con LET + table expression OPTIONAL no es estable en 7.50 SP32 — usar LOOP clásico
- ❌ NO usar ABAP Cloud syntax (AMDP restrictions, etc.)
- ❌ NO usar CDS con AMDP
- ❌ NO usar RAP (RESTful ABAP Programming) — es S/4 only

---

## Objetos custom en SAP (por proyecto)

### ConsultaStockMaterial (ZSD_SF — BZDK930642)
| Objeto | Tipo | Descripción |
|--------|------|-------------|
| ZST_SD_PLANT_STOCK | Estructura DDIC | Estructura de respuesta por planta |
| ZTY_SD_PLANT_STOCK_T | Tipo Tabla DDIC | Tipo tabla de ZST_SD_PLANT_STOCK |
| ZIF_SD_STOCK_QUERY | Interfaz | Interfaz del orquestador |
| ZIF_SD_STOCK_DAO | Interfaz | Interfaz del DAO |
| ZIF_SD_EXCLUSION_CHECKER | Interfaz | Interfaz del verificador de exclusiones |
| ZCL_SD_STOCK_QUERY | Clase | Orquestador principal |
| ZCL_SD_STOCK_DAO | Clase | Data Access Object |
| ZCL_SD_EXCLUSION_CHECKER | Clase | Verificador exclusiones KOTG504 |
| ZFG_SD_STOCK_QUERY | Function Group | Grupo de funciones RFC |
| ZFM_SD_GET_MATERIAL_STOCK | Function Module | FM RFC-enabled (consumido por Mulesoft) |
| ZCL_SD_STOCK_QUERY_TEST | Clase Test | Tests unitarios del orquestador |
| ZCL_SD_STOCK_DAO_TEST | Clase Test | Tests del DAO |
| ZCL_SD_EXCLUSION_CHECKER_TEST | Clase Test | Tests del exclusion checker |

### ZR_SD_QUICK_ORDERS (ZDEV_SD)
| Objeto | Tipo | Descripción |
|--------|------|-------------|
| ZCL_SD_QUICK_ORDERS | Clase | Lógica de negocio pedidos rápidos |
| ZCL_SD_QUICK_ORDERS_DAO | Clase | DAO de pedidos |
| ZIF_SD_QUICK_ORDERS_DAO | Interfaz | Interfaz del DAO |
| ZCL_SD_QUICK_ORDERS_TEST | Clase Test | Tests unitarios |
| ZR_SD_QUICK_ORDERS | Programa | Report principal |

### L2C_CHG0436393 (ZSD_ORDER)
| Objeto | Tipo | Descripción |
|--------|------|-------------|
| ZSD_PPD_REJ_UPDATE | Function Module | FM de workflow PPD — enqueue fix |

### ConestogaChange CHG0432318
| Objeto | Tipo | Descripción |
|--------|------|-------------|
| LZSDE_SHPMNT_DELIVRY_HD_TABTOP | Include TOP | Variable global gv_zzequipe_type |
| ZSDE_GET_DATA_SHPMNT_HD_TAB | Function Module | Lectura datos pantalla delivery |
| ZSDE_SET_DATA_SHPMNT_HD_TAB | Function Module | Escritura datos pantalla delivery |
| ZSDE_TMS2SAP_DELIVERY_DATA | Enhancement | Lógica TMS para Conestoga |
