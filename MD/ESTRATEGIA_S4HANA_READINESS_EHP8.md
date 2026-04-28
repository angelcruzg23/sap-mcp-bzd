# Estrategia: Preparación para S/4HANA y Optimización con EHP8

## Contexto Amrize / Holcim BP

| Aspecto | Estado actual |
|---------|--------------|
| Sistema | SAP ECC 6.0 EHP8, ABAP 7.5 SP19 |
| Base de datos | No-HANA (DB tradicional) |
| Migración S/4HANA | No planificada a corto plazo |
| Objetivo | Preparar el código custom para cuando llegue el momento, y aprovechar EHP8 ahora |

---

## Parte 1: ¿Qué código habría que ajustar para S/4HANA?

### Las 5 categorías de impacto en código custom

Cuando eventualmente migren a S/4HANA, el código Z se ve afectado en estas áreas:

### 1.1 Tablas eliminadas o reemplazadas

Este es el impacto más grande. S/4HANA simplifica el modelo de datos eliminando tablas de índice, agregación y status.

| Módulo | Tabla ECC (actual) | Cambio en S/4HANA | Tabla nueva / alternativa |
|--------|-------------------|-------------------|--------------------------|
| FI | BSEG, BSIK, BSID, BSAK, BSAD | Eliminadas como tablas reales | ACDOCA (Universal Journal) |
| FI | FAGLFLEXA, FAGLFLEXT | Eliminadas | ACDOCA |
| FI | BKPF | Se mantiene pero con cambios | ACDOCA para line items |
| SD | VBUK (status cabecera) | Eliminada | Campos movidos a VBAK |
| SD | VBUP (status posición) | Eliminada | Campos movidos a VBAP |
| SD | KONV (condiciones precio) | Reemplazada | PRCD_ELEMENTS |
| MM | EKBE (historial pedido) | Cambios en estructura | MATDOC |
| MM | MSEG, MKPF | Reemplazadas | MATDOC |
| WM | Tablas LQUA, LEIN, etc. | WM eliminado completamente | EWM (Extended WM) |
| General | Pool/Cluster tables | Convertidas a transparentes | Mismos nombres, diferente tipo |

**Impacto para Holcim BP:** Todo SELECT que lea VBUK, VBUP, KONV, BSEG, MSEG o tablas de WM necesitará ajuste.

### 1.2 Sentencias SQL obsoletas

| Sentencia ECC | Problema en S/4HANA | Reemplazo |
|---------------|---------------------|-----------|
| SELECT ... INTO CORRESPONDING FIELDS OF TABLE | Funciona pero no óptimo | SELECT ... INTO TABLE @DATA(lt_result) |
| SELECT SINGLE con campos no-key | Performance en HANA | Usar SELECT UP TO 1 ROWS o revisar índices |
| FOR ALL ENTRIES sin CHECK previo | Puede traer toda la tabla | Siempre validar que la tabla driver no esté vacía |
| Native SQL (EXEC SQL) | Incompatible con HANA | Usar ADBC o Open SQL |
| DB hints específicos | No aplican en HANA | Eliminar hints de DB |

### 1.3 APIs y BAPIs deprecadas

Algunas BAPIs y Function Modules cambian o se eliminan. Los más relevantes para SD/MM:
- BAPIs de WM se eliminan completamente
- Algunas BAPIs de billing cambian parámetros
- Function Modules de pricing que referencian KONV

### 1.4 Longitud de campos extendida

| Campo | ECC (actual) | S/4HANA |
|-------|-------------|---------|
| MATNR (material) | CHAR(18) | CHAR(40) |
| BELNR (doc contable) | CHAR(10) | CHAR(10) — sin cambio |
| VBELN (doc ventas) | CHAR(10) | CHAR(10) — sin cambio |
| Business Partner | No obligatorio | Reemplaza KUNNR/LIFNR |

**Impacto:** Todo código que asuma MATNR = 18 caracteres (substrings, concatenaciones, formatos de salida) necesita revisión.

### 1.5 Cambios funcionales

- Customer/Vendor → Business Partner (obligatorio en S/4HANA)
- Credit Management → SAP Credit Management (FIN-FSCM-CR)
- Output Management → BRF+ / Output Management (reemplaza NAST)

---

## Parte 2: Cómo estimar el impacto con las herramientas que ya tenemos

### 2.1 Herramientas SAP disponibles en ECC EHP8

Pueden ejecutar estas herramientas hoy mismo en BZD para obtener un inventario de impacto:

**ABAP Test Cockpit (ATC) con variante S/4HANA Readiness:**

```
Transacción: ATC
Variante de check: S4HANA_READINESS (o S4HANA_READINESS_REMOTE)
SAP Note: 2364916 — Instalación de checks de readiness en ECC
```

Esto analiza todo el código Z y reporta:
- Uso de tablas eliminadas/modificadas
- Sentencias SQL incompatibles
- APIs deprecadas
- Problemas de longitud de campos

**Code Inspector (SCI):**

```
Transacción: SCI
Variante: FUNCTIONAL_DB + PERFORMANCE_DB
```

Detecta patrones de código que serán problemáticos en HANA (SELECT en LOOPs, Native SQL, etc.)

**SAP Readiness Check (servicio online):**

```
URL: https://me.sap.com/readinesscheck
Requiere: SAP Universal ID + conexión del sistema
```

Análisis completo del sistema incluyendo código custom, add-ons y configuración.

### 2.2 Cómo Kiro puede ayudar en la estimación

Aquí es donde Kiro se vuelve muy poderoso. Con la conexión MCP a BZD podemos:

**Paso 1 — Inventariar todos los objetos Z:**

Usar `sap_search_objects` para listar todos los programas, clases y function modules custom:
```
Buscar: Z* (programas)
Buscar: ZCL_* (clases)
Buscar: ZFM_* o Z*FM* (function modules)
```

**Paso 2 — Extraer código fuente de cada objeto:**

Usar `sap_get_program_source`, `sap_get_class_source`, `sap_get_function_module_source` para traer el código a Kiro.

**Paso 3 — Análisis automatizado con Kiro:**

Pedirle a Kiro que analice cada programa buscando:
- Referencias a tablas deprecadas (VBUK, VBUP, KONV, BSEG, MSEG, etc.)
- Sentencias SQL obsoletas (Native SQL, SELECT sin campo explícito)
- Uso de MATNR con longitud hardcodeada
- Uso de KUNNR/LIFNR directo (vs. Business Partner)
- Patrones de performance (SELECT en LOOP, SELECT *)

**Paso 4 — Generar reporte de impacto:**

Kiro puede generar un documento consolidado con:
- Lista de objetos afectados por categoría
- Nivel de esfuerzo estimado (bajo/medio/alto)
- Código sugerido de reemplazo

### 2.3 Ejemplo práctico: análisis de un programa

Podemos pedirle a Kiro algo como:

> "Trae el código fuente de ZSD_QUOTATION_SALSFRC_CREATE desde BZD y analiza qué cambios necesitaría para ser compatible con S/4HANA. Busca referencias a tablas deprecadas, SQL obsoleto y patrones de performance."

Kiro lee el código vía MCP, lo analiza contra las reglas de S/4HANA readiness, y genera un reporte con hallazgos y recomendaciones.

---

## Parte 3: Aprovechando EHP8 / ABAP 7.5 ahora

Acaban de instalar EHP8, lo que les da acceso a ABAP 7.5 con sintaxis moderna. Esto es una oportunidad para ir modernizando el código existente de forma gradual, lo cual además los prepara para S/4HANA.

### 3.1 Sintaxis nueva disponible en ABAP 7.5

**Declaraciones inline (evitar DATA previo):**

```abap
" ❌ Antes (ABAP clásico)
DATA: lv_name TYPE string.
lv_name = 'Holcim'.

DATA: lt_orders TYPE TABLE OF vbak.
SELECT * FROM vbak INTO TABLE lt_orders WHERE auart = 'ZOR'.

" ✅ Ahora (ABAP 7.5)
DATA(lv_name) = 'Holcim'.

SELECT vbeln, erdat, auart FROM vbak
  INTO TABLE @DATA(lt_orders)
  WHERE auart = 'ZOR'.
```

**Constructores VALUE, CORRESPONDING, NEW:**

```abap
" ❌ Antes
DATA: ls_header TYPE ty_header.
ls_header-vbeln = '0000000001'.
ls_header-auart = 'ZOR'.
APPEND ls_header TO lt_headers.

" ✅ Ahora
DATA(lt_headers) = VALUE ty_header_t(
  ( vbeln = '0000000001' auart = 'ZOR' )
  ( vbeln = '0000000002' auart = 'TA' )
).
```

**Expresiones condicionales COND y SWITCH:**

```abap
" ❌ Antes
IF lv_status = 'A'.
  lv_text = 'Activo'.
ELSEIF lv_status = 'I'.
  lv_text = 'Inactivo'.
ELSE.
  lv_text = 'Desconocido'.
ENDIF.

" ✅ Ahora
DATA(lv_text) = SWITCH string( lv_status
  WHEN 'A' THEN 'Activo'
  WHEN 'I' THEN 'Inactivo'
  ELSE 'Desconocido'
).
```

**Operador FILTER para tablas internas:**

```abap
" ❌ Antes
LOOP AT lt_orders INTO ls_order WHERE auart = 'ZOR'.
  APPEND ls_order TO lt_filtered.
ENDLOOP.

" ✅ Ahora (requiere sorted/hashed table con key)
DATA(lt_filtered) = FILTER #( lt_orders WHERE auart = 'ZOR' ).
```

**REDUCE para agregaciones:**

```abap
" ❌ Antes
DATA: lv_total TYPE netwr.
LOOP AT lt_orders INTO ls_order.
  lv_total = lv_total + ls_order-netwr.
ENDLOOP.

" ✅ Ahora
DATA(lv_total) = REDUCE netwr(
  INIT sum = CONV netwr( 0 )
  FOR ls_order IN lt_orders
  NEXT sum = sum + ls_order-netwr
).
```

**Open SQL mejorado (escape con @, expresiones en SELECT):**

```abap
" ❌ Antes
SELECT vbeln erdat netwr FROM vbak
  INTO TABLE lt_orders
  WHERE erdat IN s_erdat.

" ✅ Ahora (ABAP 7.5 — escape host variables con @)
SELECT vbeln, erdat, netwr
  FROM vbak
  WHERE erdat IN @s_erdat
  INTO TABLE @DATA(lt_orders).
```

**Iteraciones con FOR:**

```abap
" Crear tabla derivada en una línea
DATA(lt_numbers) = VALUE ty_vbeln_t(
  FOR ls_order IN lt_orders
  ( ls_order-vbeln )
).
```

### 3.2 Proceso de optimización gradual con Kiro

Proponemos un proceso iterativo donde Kiro ayuda a modernizar programas existentes:

**Flujo de trabajo:**

```
1. Traer código fuente desde BZD (MCP)
        ↓
2. Kiro analiza patrones obsoletos
        ↓
3. Kiro propone versión modernizada con sintaxis 7.5
        ↓
4. Desarrollador revisa y ajusta
        ↓
5. Se sube a BZD vía Eclipse ADT
        ↓
6. Se ejecutan tests (ABAP Unit + ATC)
```

**Qué buscar en cada programa:**

| Patrón obsoleto | Reemplazo ABAP 7.5 | Beneficio |
|-----------------|---------------------|-----------|
| DATA + asignación separada | DATA( ) inline | Menos líneas, más legible |
| LOOP + APPEND para filtrar | FILTER #( ) | Performance + legibilidad |
| LOOP + suma manual | REDUCE | Expresivo, menos errores |
| IF/CASE para asignar valor | COND / SWITCH | Compacto |
| READ TABLE ... INTO ... SY-SUBRC | TRY ... table_line[ ] | Moderno, manejo de excepciones |
| CREATE OBJECT | NEW #( ) | Sintaxis moderna |
| CALL METHOD obj->method | obj->method( ) | Llamada funcional |
| SELECT sin @ | SELECT con @DATA( ) | Preparado para S/4 |
| FORMs (PERFORM) | Métodos de clase | OO, testeable |

### 3.3 Priorización: qué programas modernizar primero

Recomendamos priorizar por impacto de negocio y frecuencia de cambio:

| Prioridad | Criterio | Ejemplo Holcim BP |
|-----------|----------|-------------------|
| Alta | Programas que se modifican frecuentemente | Interfaces Salesforce, reportes de ventas |
| Alta | Programas con problemas de performance | Reportes que tardan mucho, jobs nocturnos |
| Media | Programas con lógica compleja en FORMs | Candidatos a refactorizar a OO |
| Media | Programas que usan tablas que cambiarán en S/4 | Los que leen VBUK, VBUP, KONV |
| Baja | Programas estables que no se tocan | Dejar para la migración formal |

---

## Parte 4: Cómo Kiro automatiza este proceso

### 4.1 Steering file para S/4HANA readiness

Podemos crear un steering file que Kiro aplique automáticamente cada vez que analice o genere código ABAP:

```markdown
# S/4HANA Readiness Rules

## PROHIBIDO en código nuevo
- No usar tablas: VBUK, VBUP, KONV, BSEG (como tabla), MSEG, MKPF
- No usar Native SQL (EXEC SQL)
- No asumir MATNR = 18 caracteres
- No usar KUNNR/LIFNR directo sin considerar Business Partner

## OBLIGATORIO en código nuevo
- Usar sintaxis Open SQL con @ para host variables
- Usar inline declarations DATA( )
- Usar VALUE, FILTER, REDUCE donde aplique
- Usar NEW #( ) en lugar de CREATE OBJECT
- Usar llamadas funcionales method( ) en lugar de CALL METHOD
```

### 4.2 Hook para validación automática

Un hook de Kiro que revise cada archivo ABAP generado:

```json
{
  "name": "S4HANA Readiness Check",
  "version": "1.0.0",
  "when": {
    "type": "fileCreated",
    "patterns": ["*.abap"]
  },
  "then": {
    "type": "askAgent",
    "prompt": "Revisa este código ABAP y verifica que no use tablas deprecadas en S/4HANA (VBUK, VBUP, KONV, BSEG, MSEG, MKPF), que use sintaxis ABAP 7.5 moderna (inline declarations, VALUE, FILTER, NEW), y que no asuma MATNR de 18 caracteres. Reporta cualquier hallazgo."
  }
}
```

### 4.3 Análisis masivo vía MCP

Podemos crear un flujo donde Kiro:

1. Busca todos los objetos Z en BZD con `sap_search_objects`
2. Para cada objeto, extrae el código fuente
3. Analiza contra las reglas de S/4HANA readiness
4. Genera un reporte consolidado en markdown

Esto es algo que podemos hacer iterativamente: empezar con los programas del módulo SD (que es el más crítico para Holcim BP), luego MM, FI, etc.

---

## Parte 5: Roadmap sugerido

### Fase 1 — Inventario y diagnóstico (1-2 semanas)

- Ejecutar ATC con variante S4HANA_READINESS en BZD
- Usar Kiro + MCP para extraer y analizar los programas Z más críticos
- Generar reporte de impacto por módulo

### Fase 2 — Establecer estándares (1 semana)

- Crear steering file de S/4HANA readiness en Kiro
- Crear hook de validación automática
- Workshop al equipo sobre sintaxis ABAP 7.5

### Fase 3 — Modernización gradual (continuo)

- Cada vez que se toque un programa existente, modernizar la sintaxis
- Todo código nuevo debe cumplir estándares ABAP 7.5
- Kiro valida automáticamente con el hook

### Fase 4 — Preparación activa para S/4HANA (cuando se defina timeline)

- Remediar los hallazgos del ATC por prioridad
- Reemplazar referencias a tablas deprecadas
- Evaluar impacto de Business Partner
- Evaluar impacto de eliminación de WM (si aplica)

---

## Referencias

- [SAP S/4HANA Custom Code Adaptation Process](https://blogs.sap.com/2017/02/15/sap-s4hana-system-conversion-custom-code-adaptation-process/) — Proceso oficial de SAP para adaptación de código custom
- [SAP Readiness Check](https://me.sap.com/readinesscheck) — Herramienta online de SAP para análisis de readiness
- [SAP Note 2364916](https://me.sap.com/notes/2364916) — Instalación de checks S/4HANA readiness en ECC
- [SAP Note 3231748](https://me.sap.com/notes/3231748) — Variante de check para S/4HANA 2022
- [Best Practices for ABAP Development on NetWeaver 7.5x](https://blogs.sap.com/2017/10/02/best-practices-for-abap-development-on-sap-netweaver-7.5x/) — Mejores prácticas de SAP para ABAP 7.5
- [Simplification Item: Pricing Data Model (KONV → PRCD_ELEMENTS)](https://community.sap.com/t5/enterprise-resource-planning-blogs-by-sap/simplification-item-simplified-data-model-in-pricing-and-condition/ba-p/13204475) — Cambio de KONV a PRCD_ELEMENTS

Content was rephrased for compliance with licensing restrictions.
