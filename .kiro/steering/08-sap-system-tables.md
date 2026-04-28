---
inclusion: auto
---

# Tablas de Sistema SAP — Campos Verificados

Estas tablas NO son accesibles via el endpoint ADT `/sap/bc/adt/ddic/tables/` porque son pool tables, cluster tables o tablas internas del workbench. Los campos listados aquí fueron verificados contra el sistema BZD 130 real.

**REGLA: Cuando necesites usar estas tablas en código ABAP, consulta esta referencia en lugar de adivinar los campos.**

## Tablas de Transporte (CTS)

### E070 — Cabecera de Órdenes de Transporte
```
TRKORR    TYPE TRKORR      — Número de la OT (clave)
TRFUNCTION TYPE TRFUNCTION  — Tipo de request (K=Workbench, W=Customizing)
TRSTATUS  TYPE TRSTATUS     — Status (D=Modifiable, L=Modifiable protected, R=Released, N=Released with import)
TARSYSTEM TYPE TARSYSTEM    — Sistema destino
AS4USER   TYPE AS4USER      — Owner/último modificador
AS4DATE   TYPE AS4DATE      — Fecha última modificación
AS4TIME   TYPE AS4TIME      — Hora última modificación
STRKORR   TYPE STRKORR      — Request padre (para tasks: apunta al request)
KORRDEV   TYPE KORRDEV      — Categoría (SYST=sistema, CUST=customizing)
```
**NOTA: E070 NO tiene campo AS4TEXT.** El texto/descripción está en E07T.

### E07T — Textos de Órdenes de Transporte
```
TRKORR    TYPE TRKORR      — Número de la OT (clave)
LANGU     TYPE LANGU        — Idioma (clave)
AS4TEXT   TYPE AS4TEXT       — Texto descriptivo de la OT
```

### E071 — Objetos en Órdenes de Transporte
```
TRKORR    TYPE TRKORR      — Número de la OT (clave)
AS4POS    TYPE TRPOS        — Posición (clave)
PGMID     TYPE PGMID        — Program ID (R3TR, LIMU, etc.)
OBJECT    TYPE TROBJTYPE    — Tipo de objeto (PROG, REPS, FUNC, CLAS, FUGR, TABL, etc.)
OBJ_NAME  TYPE TROBJ_NAME   — Nombre del objeto
OBJFUNC   TYPE OBJFUNC      — Función (K=Key, D=Dictionary, etc.)
LOCKFLAG  TYPE LOCKFLAG     — Flag de bloqueo
```

### E071K — Claves de Objetos en OTs (Customizing)
```
TRKORR    TYPE TRKORR      — Número de la OT
PGMID     TYPE PGMID
OBJECT    TYPE TROBJTYPE
OBJ_NAME  TYPE TROBJ_NAME
TABKEY    TYPE TABKEY        — Clave de la entrada de tabla
MASTERTYPE TYPE TROBJTYPE
MASTERNAME TYPE TROBJ_NAME
```

## Tablas del Workbench

### TRDIR — Directorio de Programas
```
NAME      TYPE PROGNAME     — Nombre del programa (clave)
SUBC      TYPE SUBC          — Tipo (1=Report, I=Include, F=Function group, etc.)
RSTAT     TYPE RSTAT         — Status
CDAT      TYPE DATS          — Fecha creación
UDAT      TYPE DATS          — Fecha última modificación
UNAM      TYPE UNAME         — Último usuario que modificó
RLOAD     TYPE RLOAD         — Load version
```

### DWINACTIV — Objetos Inactivos del Workbench
```
OBJECT    TYPE TROBJTYPE    — Tipo de objeto (clave)
OBJ_NAME  TYPE TROBJ_NAME   — Nombre del objeto (clave)
UNAME     TYPE SYUNAME       — Usuario que tiene la versión inactiva
UDATE     TYPE SYDATUM       — Fecha
```
**NOTA: DWINACTIV NO tiene campo PGMID ni OBJ_TYPE.** Solo OBJECT y OBJ_NAME como campos de filtro.

### TADIR — Catálogo de Objetos del Repositorio
```
PGMID     TYPE PGMID        — Program ID (clave)
OBJECT    TYPE TROBJTYPE    — Tipo de objeto (clave)
OBJ_NAME  TYPE SOBJ_NAME    — Nombre del objeto (clave)
DEVCLASS  TYPE DEVCLASS      — Paquete de desarrollo
AUTHOR    TYPE RESPONSIBL    — Autor/responsable
SRCSYSTEM TYPE SRCSYSTEM     — Sistema origen
```

## Tablas de Cross-Reference

### WBCROSSGT — Cross-References Globales (Where-Used)
```
OTYPE     TYPE TROBJTYPE    — Tipo del objeto referenciado
NAME      TYPE TROBJ_NAME   — Nombre del objeto referenciado
INCLUDE   TYPE PROGNAME     — Programa/include que hace la referencia
DIRECT    TYPE XFELD         — Referencia directa (X) o indirecta
```
**NOTA: Para buscar "qué usa este programa", filtrar por INCLUDE = nombre_programa.**

## Tablas de Function Modules

### TFDIR — Directorio de Function Modules
```
FUNCNAME  TYPE RS38L_FNAM   — Nombre del FM (clave)
PNAME     TYPE PNAME         — Nombre del programa (SAPL + nombre_grupo)
INCLUDE   TYPE PROGNAME     — Include donde está el código
STEXT     TYPE RS38L_FTXT   — Texto corto del FM
```

## Tablas de Includes/Dependencias

### D010INC — Includes Referenciados por Programas
**NOTA: Esta tabla NO tiene campos PROG/INCLUDE como campos directos accesibles via Open SQL en todos los sistemas.** Usar el FM estándar `RS_GET_ALL_INCLUDES` en su lugar:
```abap
CALL FUNCTION 'RS_GET_ALL_INCLUDES'
  EXPORTING program = lv_progname
  TABLES includetab = lt_includes
  EXCEPTIONS OTHERS = 1.
```

### D010SINF — Información de Source de Programas
**NOTA: Similar a D010INC, los campos pueden no ser accesibles directamente.** Usar FMs estándar como alternativa.

## Reglas para Open SQL con estas tablas

1. **Usar sintaxis clásica (sin @)** para pool/cluster tables — la sintaxis nueva con `@host_variable` puede fallar con estas tablas en ABAP 7.50
2. **No usar string templates en WHERE** — `WHERE pname = @( |SAPL{ lv_name }| )` puede fallar. Usar CONCATENATE previo.
3. **Preferir FMs estándar** sobre SELECTs directos cuando existan (RS_GET_ALL_INCLUDES, TR_READ_REQUEST, etc.)
4. **No asumir campos** — si no está en esta lista, verificar en SE11 antes de codificar
