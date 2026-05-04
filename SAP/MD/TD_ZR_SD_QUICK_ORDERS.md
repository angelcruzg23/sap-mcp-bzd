# Technical Design — ZR_SD_QUICK_ORDERS

## 1. Información General

| Campo | Valor |
|-------|-------|
| Nombre | ZR_SD_QUICK_ORDERS |
| Descripción | Consulta rápida de pedidos de venta (VBAK + VBAP) |
| Módulo | SD (Ventas) |
| Paquete | ZDEV_SD |
| Sistema | BZD 130 — SAP ECC 6.0 EHP8, ABAP 7.5 SP19 |
| Autor | Equipo Holcim BP |
| Fecha | Marzo 2026 |

## 2. Objetivo

Proveer un reporte de consulta rápida que muestre los pedidos de venta con sus posiciones, filtrando por fecha de creación y tipo de pedido. La salida presenta los 10 campos principales de cabecera (VBAK) y los 10 campos principales de posición (VBAP) en un ALV interactivo.

## 3. Arquitectura

El diseño sigue los principios SOLID y los estándares de codificación Holcim BP:

```
┌─────────────────────────────┐
│   ZR_SD_QUICK_ORDERS        │  Reporte (UI + pantalla de selección)
│   (Report / Programa)       │
└──────────┬──────────────────┘
           │ usa
           ▼
┌─────────────────────────────┐
│   ZCL_SD_QUICK_ORDERS       │  Lógica de negocio
│   (Clase de servicio)       │
└──────────┬──────────────────┘
           │ depende de (DIP)
           ▼
┌─────────────────────────────┐
│   ZIF_SD_QUICK_ORDERS_DAO   │  Interfaz de acceso a datos
│   (Interface)               │
└──────────┬──────────────────┘
           │ implementada por
     ┌─────┴──────┐
     ▼            ▼
┌──────────┐  ┌──────────────────────┐
│ ZCL_SD_  │  │ LTD_MOCK_DAO         │
│ QUICK_   │  │ (Test Double local)  │
│ ORDERS_  │  │ en ZCL_SD_QUICK_     │
│ DAO      │  │ ORDERS_TEST          │
│ (Real)   │  └──────────────────────┘
└──────────┘
```

## 4. Objetos del Desarrollo

| Objeto | Tipo | Descripción |
|--------|------|-------------|
| ZR_SD_QUICK_ORDERS | PROG | Reporte principal con pantalla de selección y ALV |
| ZIF_SD_QUICK_ORDERS_DAO | INTF | Interfaz del DAO — define tipos y método `get_orders` |
| ZCL_SD_QUICK_ORDERS_DAO | CLAS | Implementación real del DAO (SELECT VBAK + VBAP) |
| ZCL_SD_QUICK_ORDERS | CLAS | Clase de servicio / lógica de negocio |
| ZCL_SD_QUICK_ORDERS_TEST | CLAS | Clase de test ABAP Unit (6 tests) |

## 5. Pantalla de Selección

| Parámetro | Campo | Tipo | Obligatorio | Descripción |
|-----------|-------|------|:-----------:|-------------|
| S_ERDAT | SY-DATUM | SELECT-OPTIONS | Sí | Fecha de creación del pedido |
| S_AUART | VBAK-AUART | SELECT-OPTIONS | No | Tipo de pedido de venta |

## 6. Campos de Salida

### 6.1 Cabecera (VBAK)

| # | Campo | Elemento de datos | Descripción |
|---|-------|-------------------|-------------|
| 1 | VBELN | VBELN_VA | Nº documento de ventas |
| 2 | ERDAT | ERDAT | Fecha de creación |
| 3 | ERZET | ERZET | Hora de creación |
| 4 | ERNAM | ERNAM | Creado por |
| 5 | AUART | AUART | Tipo de pedido |
| 6 | VKORG | VKORG | Organización de ventas |
| 7 | VTWEG | VTWEG | Canal de distribución |
| 8 | SPART | SPART | Sector |
| 9 | KUNNR | KUNAG | Solicitante |
| 10 | NETWR | NETWR | Valor neto del documento |

### 6.2 Posición (VBAP)

| # | Campo | Elemento de datos | Descripción |
|---|-------|-------------------|-------------|
| 1 | POSNR | POSNR_VA | Posición del documento |
| 2 | MATNR | MATNR | Número de material |
| 3 | ARKTX | ARKTX | Descripción del material |
| 4 | KWMENG | KWMENG | Cantidad pedida |
| 5 | VRKME | VRKME | Unidad de medida de venta |
| 6 | NETWR | NETWR | Valor neto de la posición |
| 7 | WERKS | WERKS_D | Centro |
| 8 | LGORT | LGORT_D | Almacén |
| 9 | PSTYV | PSTYV | Tipo de posición |
| 10 | ABGRU | ABGRU | Motivo de rechazo |

## 7. Lógica de Acceso a Datos

```sql
SELECT k~vbeln k~erdat k~erzet k~ernam k~auart
       k~vkorg k~vtweg k~spart k~kunnr k~netwr
       p~posnr p~matnr p~arktx p~kwmeng p~vrkme
       p~netwr AS netwr_p p~werks p~lgort p~pstyv p~abgru
  FROM vbak AS k
  INNER JOIN vbap AS p ON p~vbeln = k~vbeln
  WHERE k~erdat IN s_erdat
    AND k~auart IN s_auart
  ORDER BY k~vbeln k~erdat p~posnr.
```

- JOIN directo entre VBAK y VBAP (sin SELECT dentro de LOOP)
- Campos listados explícitamente (sin SELECT *)
- Ordenado por pedido, fecha y posición

## 8. Salida ALV

- Clase: `CL_SALV_TABLE` (estándar recomendado Holcim BP)
- Funciones habilitadas: filtrar, ordenar, exportar a Excel
- Patrón zebra activado para legibilidad
- Ancho de columnas optimizado automáticamente
- Textos de columna personalizados en español

## 9. Principios de Diseño Aplicados

| Principio | Aplicación |
|-----------|------------|
| SRP | El DAO solo accede a datos. La clase de servicio solo orquesta. El reporte solo presenta. |
| DIP | `ZCL_SD_QUICK_ORDERS` depende de `ZIF_SD_QUICK_ORDERS_DAO`, no de la clase concreta |
| OCP | Nuevos DAOs pueden implementar la interfaz sin modificar la clase de servicio |
| Inyección de dependencias | Constructor con parámetro OPTIONAL para el DAO |
| DAO Pattern | Acceso a datos centralizado y aislado en `ZCL_SD_QUICK_ORDERS_DAO` |

## 10. Tests Unitarios (ABAP Unit)

Clase: `ZCL_SD_QUICK_ORDERS_TEST` — Risk Level: HARMLESS, Duration: SHORT

| # | Test | Qué valida |
|---|------|------------|
| 1 | get_orders_with_data | Devuelve registros cuando el DAO tiene datos |
| 2 | get_orders_empty_result | Devuelve tabla vacía y count = 0 sin datos |
| 3 | has_data_true_after_result | `has_data()` retorna TRUE tras consulta con resultados |
| 4 | has_data_false_when_empty | `has_data()` retorna FALSE tras consulta vacía |
| 5 | get_orders_count_matches | `ev_count` coincide con `lines( et_data )` |
| 6 | get_orders_filters_ignored | Confirma que la clase delega el filtrado al DAO |

Estrategia de mock: clase local `LTD_MOCK_DAO` que implementa `ZIF_SD_QUICK_ORDERS_DAO` y permite inyectar datos de prueba con `set_mock_data()`. No se accede a base de datos en ningún test.

## 11. Instrucciones de Instalación

1. Crear los objetos en el paquete `ZDEV_SD` en el orden:
   - `ZIF_SD_QUICK_ORDERS_DAO` (interfaz)
   - `ZCL_SD_QUICK_ORDERS_DAO` (clase DAO)
   - `ZCL_SD_QUICK_ORDERS` (clase de servicio)
   - `ZR_SD_QUICK_ORDERS` (reporte)
   - `ZCL_SD_QUICK_ORDERS_TEST` (clase de test)
2. Activar todos los objetos
3. Mantener textos de selección en SE38 → Ir a → Elementos de texto:
   - TEXT-B01: `Filtros de selección`
4. Ejecutar tests: Eclipse ADT → click derecho en `ZCL_SD_QUICK_ORDERS_TEST` → Run As → ABAP Unit Test
5. Ejecutar reporte: SE38 → `ZR_SD_QUICK_ORDERS` → F8
