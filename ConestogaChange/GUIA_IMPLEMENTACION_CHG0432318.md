# Guía de Implementación — CHG0432318
## New Conestoga Equipment Type for US Bank

### Resumen de Cambios

| # | Objeto | Tipo | Acción | Archivo Local |
|---|--------|------|--------|---------------|
| 1 | LZSDE_SHPMNT_DELIVRY_HD_TABTOP | FUGR Include (TOP) | Agregar variable global `gv_zzequipe_type` | `LZSDE_SHPMNT_DELIVRY_HD_TABTOP.abap` |
| 2 | ZSDE_GET_DATA_SHPMNT_HD_TAB | Function Module | Agregar línea `es_likp-zzequipe_type = gv_zzequipe_type` | `ZSDE_GET_DATA_SHPMNT_HD_TAB.abap` |
| 3 | ZSDE_SET_DATA_SHPMNT_HD_TAB | Function Module | Agregar línea `gv_zzequipe_type = is_likp-zzequipe_type` | `ZSDE_SET_DATA_SHPMNT_HD_TAB.abap` |
| 4 | ZSDE_TMS2SAP_DELIVERY_DATA | Enhancement (ENHO/XH) en MV50AFZ1 | Agregar lógica condicional para Conestoga | `ZSDE_TMS2SAP_DELIVERY_DATA.abap` |

### Prerrequisito
- El campo `ZZEQUIPE_TYPE` ya debe existir en la tabla LIKP (append structure).

### Detalle por Objeto

#### 1. TOP Include — Variable Global
Se agrega una nueva variable global `gv_zzequipe_type` que actúa como buffer entre la pantalla (TMS Info tab) y la estructura LIKP, siguiendo el mismo patrón de los campos existentes.

#### 2. FM GET — Lectura de datos
Transfiere el valor de la variable global `gv_zzequipe_type` al campo `es_likp-zzequipe_type` cuando se leen los datos de la pantalla custom del delivery header.

#### 3. FM SET — Escritura de datos
Transfiere el valor de `is_likp-zzequipe_type` a la variable global `gv_zzequipe_type` cuando se cargan datos en la pantalla custom.

#### 4. Enhancement MV50AFZ1 — Lógica TMS
Dentro del enhancement existente `ZSDE_TMS2SAP_DELIVERY_DATA`, se agrega lógica condicional:
- Solo cuando TMS envía el valor `'ZZ'` (Conestoga) en el campo VSBED, se actualiza `ZZEQUIPE_TYPE` en la delivery.
- Para cualquier otro tipo de equipo, el campo no se modifica.
- Esto evita la necesidad de un nuevo mapeo en PI/PO.

### Search Term
`AC04082026` — usar para rastrear todos los cambios de este CHG en el código.

### Nota sobre el Enhancement
El archivo `ZSDE_TMS2SAP_DELIVERY_DATA.abap` muestra la lógica a agregar. Como es un enhancement explícito (ENHO/XH), las variables en scope dependen del código existente. Antes de implementar, verificar los nombres exactos de las work areas disponibles (`ls_tms_data`, `ls_likp`, etc.) dentro del enhancement actual en el sistema.
