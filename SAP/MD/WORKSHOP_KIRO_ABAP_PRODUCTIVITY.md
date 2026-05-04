# Workshop: Kiro como Co-Piloto ABAP
## Cómo un AI Assistant transforma la productividad del desarrollador SAP

---

## 1. Contexto del Workshop

Este material se basa en una sesión real de trabajo donde se utilizó Kiro (AI Assistant + IDE) conectado al sistema SAP BZD 130 vía MCP (Model Context Protocol) para analizar un requerimiento funcional y generar propuestas de código ABAP listas para implementar.

El caso de uso fue el Change Request **CHG0432318 — New Conestoga Equipment Type for US Bank**.

---

## 2. Lo que hicimos en la sesión (paso a paso)

### Paso 1 — Análisis del Functional Design
- Se le entregó a Kiro un documento `.mht` (Word guardado como web archive) con el Functional Design.
- Kiro parseó el HTML embebido, extrajo el contenido relevante y entregó un resumen estructurado del requerimiento:
  - Qué es un Conestoga (flatbed trailer con lona retráctil)
  - Por qué se necesita (tarifa diferente, US Bank necesita la info en EDI 858)
  - Los 5 pasos técnicos del diseño
  - El análisis de impacto (solo User Exit afectado)
  - Los escenarios de prueba

**Tiempo estimado manual:** 30-45 minutos leyendo el FD y tomando notas.
**Tiempo con Kiro:** ~2 minutos.

### Paso 2 — Búsqueda de objetos en SAP
- Kiro buscó los programas mencionados en el FD directamente en el sistema SAP BZD:
  - `ZSDE_GET_DATA_SHPMNT_HD_TAB` → Function Module en grupo `ZSDE_SHPMNT_DELIVRY_HD_TAB`
  - `ZSDE_SET_DATA_SHPMNT_HD_TAB` → Function Module en el mismo grupo
  - `ZSDE_TMS2SAP_DELIVERY_DATA` → Enhancement (ENHO/XH) en programa `MV50AFZ1`
- Obtuvo el código fuente de los FMs y la estructura del function group.

**Tiempo estimado manual:** 15-20 minutos navegando SE37, SE38, SE80.
**Tiempo con Kiro:** ~1 minuto.

### Paso 3 — Generación de código
- Kiro analizó el patrón del código existente (asignaciones campo por campo, variables globales gv_*, convención de search terms).
- Generó 4 archivos ABAP con los cambios propuestos:
  - **TOP Include** — nueva variable global `gv_zzequipe_type`
  - **FM GET** — nueva línea de lectura del campo
  - **FM SET** — nueva línea de escritura del campo
  - **Enhancement MV50AFZ1** — lógica condicional: solo actualizar cuando TMS envía 'ZZ' (Conestoga)
- Generó una guía de implementación en markdown.

**Tiempo estimado manual:** 45-60 minutos escribiendo, probando sintaxis, revisando patrones.
**Tiempo con Kiro:** ~3 minutos.

### Resultado total
| Actividad | Manual | Con Kiro |
|-----------|--------|----------|
| Análisis del FD | 30-45 min | 2 min |
| Búsqueda de objetos SAP | 15-20 min | 1 min |
| Generación de código | 45-60 min | 3 min |
| **Total** | **~2 horas** | **~6 minutos** |

---

## 3. La nueva manera de trabajar

### Antes (flujo tradicional)
```
FD en Word/PDF → Leer manualmente → Abrir SAP GUI/Eclipse →
Buscar objetos uno por uno → Entender el patrón → Escribir código →
Probar sintaxis → Documentar cambios
```

### Ahora (flujo con Kiro)
```
FD en cualquier formato → Kiro analiza y resume →
Kiro busca objetos en SAP vía MCP → Kiro entiende el patrón →
Kiro genera código siguiendo convenciones → Dev revisa y ajusta →
Subir a SAP
```

### El cambio de rol del ABAP Developer
| Antes | Ahora |
|-------|-------|
| Lector de documentos | Validador de análisis |
| Buscador de objetos | Revisor de propuestas |
| Escritor de código | Arquitecto de soluciones |
| Documentador manual | Curador de documentación generada |

El desarrollador ABAP pasa de ser **ejecutor** a ser **revisor y decisor**. El valor está en el criterio técnico, no en la velocidad de tipeo.

---

## 4. Requisitos para que Kiro trabaje de forma impecable

### 4.1 Lo que necesita Kiro (infraestructura)

| Requisito | Descripción | Estado en Holcim BP |
|-----------|-------------|---------------------|
| Conexión MCP a SAP | Servidor MCP que exponga ADT vía REST | ✅ Configurado (BZD 130) |
| Acceso de lectura a código | Permisos ADT para leer programas, clases, FMs, tablas | ✅ Disponible |
| Acceso de escritura (opcional) | Permisos ADT para crear/modificar objetos | ✅ Disponible |
| Steering files | Reglas de codificación, naming, contexto del sistema | ✅ Configurados (.kiro/steering/) |

### 4.2 Lo que necesita Kiro (documentación del requerimiento)

Este es el punto más crítico. La calidad del output de Kiro depende directamente de la calidad del input.

**Mínimo necesario en el Functional Design:**
- Descripción clara del cambio de negocio (qué y por qué)
- Nombres exactos de los objetos SAP afectados (programas, tablas, FMs, enhancements)
- Nombres de campos nuevos o modificados
- Lógica condicional explícita (cuándo sí, cuándo no)
- Valores específicos (ej: 'ZZ' = Conestoga)

**Lo que mejora dramáticamente el resultado:**
- Diagrama de flujo técnico (aunque sea en texto)
- Ejemplos de datos reales (ej: shipment 1122655, delivery 801333806)
- Referencia a cambios anteriores similares (para que Kiro entienda el patrón)

**Lo que NO necesita Kiro:**
- Formato bonito del documento (puede leer .mht, .md, .txt, .docx)
- Explicaciones de conceptos SAP estándar (ya los conoce)
- Screenshots de SAP GUI (no puede interpretarlos en archivos .mht)

### 4.3 Lo que necesita Kiro (steering / reglas del equipo)

Los steering files en `.kiro/steering/` son las "reglas del juego" que Kiro sigue automáticamente:

| Steering File | Propósito |
|---------------|-----------|
| `01-holcim-context.md` | Sistema SAP, versión ABAP, módulos en uso |
| `02-naming-conventions.md` | Prefijos ZCL_, ZIF_, ZR_, convenciones de variables |
| `03-coding-standards.md` | Obligatorios, prohibidos, recomendados |
| `04-solid-patterns.md` | Patrones SOLID adaptados a ABAP |

Estos archivos son la razón por la que Kiro genera código que se ve como si lo hubiera escrito alguien del equipo.

---

## 5. Lo que debemos hacer nosotros como ABAPs

### 5.1 Antes de pedirle algo a Kiro
- Asegurar que el FD tenga los nombres técnicos correctos de los objetos
- Confirmar que los campos nuevos ya existen en el diccionario (o indicar que se asumen)
- Tener claro el search term y la orden de transporte

### 5.2 Durante la sesión con Kiro
- Dar instrucciones claras y específicas ("busca el programa X dentro del enhancement Y")
- Validar que el código generado sigue el patrón del código existente
- Verificar nombres de variables en scope (especialmente en enhancements)
- No asumir que el código está listo para producción sin revisión

### 5.3 Después de la sesión
- Revisar el código generado línea por línea
- Verificar en el sistema real los nombres de work areas y variables en scope
- Ejecutar pruebas unitarias
- Documentar cualquier ajuste manual que se haya hecho

### 5.4 Responsabilidades que NO se delegan a Kiro

| Responsabilidad | Por qué sigue siendo nuestra |
|-----------------|------------------------------|
| Decisión de diseño | Kiro propone, el ABAP decide |
| Validación de impacto | Solo el dev conoce el contexto completo del landscape |
| Pruebas en sistema | Kiro no puede ejecutar transacciones SAP GUI |
| Activación en PRD | Proceso de transporte sigue siendo manual y controlado |
| Revisión de seguridad | Autorizaciones y accesos son responsabilidad del equipo |

---

## 6. Ejercicio: Debugging de un reporte productivo con Kiro

### Contexto del ejercicio

Un usuario reporta que recibe correctamente los correos de factura, y en SOST aparecen como "Transmitted". Sin embargo, el reporte Z `ZSDR_DAILY_INVOICE_REPORT` (transacción `ZSD_DAILY_INVOICE`) muestra esas mismas facturas con semáforo rojo (Failed).

El objetivo es usar Kiro para diagnosticar el bug sin abrir SAP GUI ni Eclipse ADT.

### Paso 1 — Lectura del programa principal

Se le pide a Kiro que lea el programa `ZSDR_DAILY_INVOICE_REPORT` desde SAP BZD.

Kiro identifica que es un report con estructura clásica de includes:
- `_TOP` → datos globales y constantes
- `_SCR` → pantalla de selección
- `_C01` → clases locales (eventos ALV, manejo de layouts)
- `_F01` → FORMs con la lógica de negocio

**Problema encontrado:** el endpoint ADT de programas (`/sap/bc/adt/programs/programs/`) no puede leer includes individuales — solo el programa padre.

### Paso 2 — Evolución del MCP Server en tiempo real

En lugar de buscar un workaround manual, se decidió mejorar el MCP Server agregando soporte para includes:

- Se agregó el método `get_include_source()` en `sap_client.py` usando el endpoint correcto: `/sap/bc/adt/programs/includes/{nombre}/source/main`
- Se registró la herramienta `sap_get_include_source` en `server.py`
- Se reinició el MCP Server

**Tiempo:** ~3 minutos. A partir de ese momento, Kiro puede leer cualquier include ABAP del sistema.

**Lección clave:** el MCP Server es extensible en tiempo real. Si Kiro no puede hacer algo, se le agrega la capacidad y se sigue trabajando.

### Paso 3 — Lectura de los 4 includes

Con la nueva herramienta, Kiro leyó los 4 includes en paralelo y obtuvo el código fuente completo del reporte.

### Paso 4 — Análisis del bug (simulación de flujo)

Se le pidió a Kiro que simulara el flujo de datos del FORM `f_get_data` para encontrar dónde se pierde la correlación entre SOST (transmitido) y el reporte (failed).

Kiro identificó **dos problemas potenciales**:

**Problema 1 — Rango de fechas de SOOD demasiado estrecho:**
El rango `so_datvr` se calcula dinámicamente y puede no incluir documentos SAPoffice creados en fechas posteriores a la factura.

**Problema 2 — DELETE de documentos transmitidos (causa raíz confirmada):**
```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```
Esta línea elimina de la tabla interna los documentos que ya tienen número SAPcomm asignado. Pero después del EHP8, SAPconnect asigna el `SCOMNO` inmediatamente al transmitir, por lo que esta línea borra exactamente los documentos que SÍ fueron enviados exitosamente.

Al no encontrar match en el LOOP posterior, la factura cae en el ELSE y se marca como Failed:
```abap
READ TABLE ltt_sood_hashed INTO DATA(ls_sood)
     WITH KEY objdes = ls_invoice-tdcovtitle.
IF sy-subrc EQ 0.
  " ... asigna semáforo según SOST
ELSE.
  " ← CAE AQUÍ: documento eliminado por el DELETE
  gs_report-icon  = icon3.    " 🔴 ROJO
  gs_report-vstat = |F|.      " Failed
ENDIF.
```

### Paso 5 — Validación con el usuario

Se le presentó el análisis al desarrollador. Confirmó que el Problema 2 era la causa raíz.

### Paso 6 — Propuesta de solución

Se diseñó un **switch por fecha usando TVARVC** para no romper el comportamiento pre-EHP8:

```abap
SELECT SINGLE low INTO lv_ehp8_cutoff
  FROM tvarvc
  WHERE name = 'ZSD_DAILY_INV_EHP8_DATE'
    AND type = 'P'.

IF sy-subrc <> 0.
  lv_ehp8_cutoff = '99991231'.  " Fallback seguro
ENDIF.

IF so_erdat-low < lv_ehp8_cutoff.
  DELETE ltt_sood WHERE NOT scomno IS INITIAL.  " Solo pre-EHP8
ENDIF.
```

### Paso 7 — Generación de entregables

Kiro generó:
- Informe de análisis en español (`ANALISIS_BUG_SCOMNO.md`)
- Informe de análisis en inglés (`BUG_ANALYSIS_SCOMNO.md`)
- Include F01 modificado con el fix aplicado (`ZSDR_DAILY_INVOICE_REPORT_F01.abap`)

Todo sin subir nada a SAP — archivos locales para revisión del equipo.

### Resumen del ejercicio

| Actividad | Manual | Con Kiro |
|-----------|--------|----------|
| Leer programa + 4 includes | 15-20 min | 1 min |
| Evolucionar MCP Server | N/A | 3 min |
| Simular flujo y encontrar bug | 1-2 horas | 5 min |
| Generar informe bilingüe | 30-45 min | 2 min |
| Generar código con fix | 20-30 min | 2 min |
| **Total** | **~3 horas** | **~13 minutos** |

### Lecciones aprendidas

1. **Kiro puede hacer debugging estático** — no necesita ejecutar el programa. Simulando el flujo de datos con el código fuente, identificó la causa raíz.
2. **El MCP Server es un asset vivo** — cuando faltaba una capacidad (leer includes), se agregó en minutos y se siguió trabajando.
3. **El contexto del EHP8 fue clave** — Kiro no sabía que el EHP8 cambió el comportamiento de SAPconnect. El desarrollador aportó ese contexto y Kiro lo integró en la solución.
4. **La solución con TVARVC es un patrón reutilizable** — switch por fecha para proteger comportamiento legacy mientras se corrige el nuevo.
5. **Generar documentación bilingüe es trivial** — lo que manualmente tomaría 30+ minutos, Kiro lo hace en segundos.

---

## 7. Ejercicio: Modificación de una FM productiva y deploy a SAP desde Kiro

### Contexto del ejercicio

Se recibe el Change Request **CHG0436393** para la FM `ZSD_PPD_REJ_UPDATE` del grupo de funciones `ZSD_PPD`. Esta FM es invocada desde un workflow de aprobación PPD (Product Price Deviation) y su función es remover el motivo de rechazo de las posiciones de una quotation después de que el flujo de aprobación finaliza.

**El problema:** la FM llama directamente a `BAPI_CUSTOMERQUOTATION_CHANGE` sin verificar si la quotation está bloqueada por otro usuario. Si alguien la tiene abierta en VA22/VA23, la BAPI puede fallar o generar inconsistencias.

**El requerimiento:** agregar validación de enqueue lock antes de la BAPI, con reintentos de hasta 2 minutos si la quotation está tomada.

### Paso 1 — Lectura y análisis de la FM desde SAP

Kiro leyó el código fuente de `ZSD_PPD_REJ_UPDATE` directamente desde BZD 130 usando `sap_get_function_module_source`. Analizó el flujo completo:

- Preparación de estructuras BAPI para limpiar `reason_rej`
- Llamada directa a `BAPI_CUSTOMERQUOTATION_CHANGE`
- Dos caminos post-BAPI: éxito (COMMIT + email aprobación) y error (flag + email error)
- Manejo especial para escenario CPQ (`I_CPQ = abap_true`)

Con este análisis, Kiro propuso un plan de implementación con 3 puntos de inserción sin modificar el código existente.

**Tiempo estimado manual:** 20-30 minutos leyendo y entendiendo el flujo.
**Tiempo con Kiro:** ~2 minutos.

### Paso 2 — Generación de código y documentación local

Kiro generó la carpeta `L2C_CHG0436393/` con 3 artefactos:

| Archivo | Contenido |
|---------|-----------|
| `ANALISIS_ZSD_PPD_REJ_UPDATE.md` | Análisis AS-IS vs TO-BE, riesgos, decisiones de diseño |
| `TD_ZSD_PPD_REJ_UPDATE_CHG0436393.md` | Technical Design completo con diagrama de flujo y escenarios de prueba |
| `ZSD_PPD_REJ_UPDATE.abap` | Código fuente modificado con los 3 bloques de inserción marcados con `+CHG0436393` |

La lógica nueva consiste en:
1. **ENQUEUE_EVVBAKE** con loop de reintento (24 × 5 seg = 2 min máximo)
2. Si no se obtiene el lock → `UPDATE_FAILED = 'X'` + email de notificación + RETURN
3. **DEQUEUE_EVVBAKE** en ambos caminos post-BAPI (éxito y error)

**Tiempo estimado manual:** 1-2 horas entre diseño, código y documentación.
**Tiempo con Kiro:** ~5 minutos.

### Paso 3 — El obstáculo: el MCP Server no podía escribir Function Modules

Al intentar subir el código a BZD, descubrimos que el MCP Server solo tenía `sap_update_program_source` que usa el endpoint `/sap/bc/adt/programs/programs/{name}`. Este endpoint no funciona para includes de function groups — SAP ADT retorna `403 ExceptionResourceNoAccess`.

Los includes de FM (`LZSD_PPDU04`) tampoco se pueden actualizar como programas normales. El endpoint correcto para escribir el source de un FM es:

```
PUT /sap/bc/adt/functions/groups/{fg}/fmodules/{fm}/source/main
```

Con lock/unlock en:
```
POST /sap/bc/adt/functions/groups/{fg}/fmodules/{fm}?_action=LOCK
POST /sap/bc/adt/functions/groups/{fg}/fmodules/{fm}?_action=UNLOCK
```

### Paso 4 — Evolución del MCP Server (segunda vez)

Igual que en el ejercicio del debugging (donde se agregó `sap_get_include_source`), Kiro evolucionó el MCP Server en tiempo real:

**En `sap_client.py`** — se agregó el método `update_function_module_source()`:
```python
def update_function_module_source(self, function_group, function_name,
                                  source_code, transport=""):
    object_url = f"/sap/bc/adt/functions/groups/{fg}/fmodules/{fm}"
    source_url = f"{object_url}/source/main"
    # 1. Fetch CSRF token
    # 2. Lock FM object
    # 3. PUT source code (text/plain)
    # 4. Unlock FM object
```

**En `server.py`** — se registró la herramienta `sap_update_function_module_source` con sus parámetros (`function_group`, `function_name`, `source_code`, `transport`).

Se reinició el MCP Server y la nueva capacidad quedó disponible inmediatamente.

**Lección aprendida adicional:** el endpoint de FM source no acepta el bloque de comentarios de interfaz local (`*"------`). El source debe enviarse con la firma `FUNCTION ... IMPORTING ... TABLES ...` en formato limpio, exactamente como lo devuelve el GET del mismo endpoint. Esto se descubrió por un error `400 Parameter comment blocks are not allowed` y se corrigió en el mismo intento.

### Paso 5 — Deploy a SAP BZD 130

Con la nueva herramienta disponible, el deploy fue directo:

```
1. sap_update_function_module_source(ZSD_PPD, ZSD_PPD_REJ_UPDATE, source) → OK
2. sap_activate_object(ZSD_PPD_REJ_UPDATE, FUGR/FF) → Activado exitosamente
3. sap_get_function_module_source(ZSD_PPD, ZSD_PPD_REJ_UPDATE) → Verificación OK
```

El código quedó activo en BZD 130 con los 3 bloques de inserción `+CHG0436393` correctamente posicionados.

### Paso 6 — Lo que Kiro logró que no se había hecho antes

Este ejercicio marcó un hito: **es la primera vez que Kiro escribe y activa código de un Function Module directamente en SAP BZD**. Hasta este punto, solo se habían creado/modificado programas tipo PROG.

| Capacidad | Antes | Después de CHG0436393 |
|-----------|-------|----------------------|
| Leer programas (PROG) | ✅ | ✅ |
| Leer includes | ✅ | ✅ |
| Leer FMs | ✅ | ✅ |
| Leer clases | ✅ | ✅ |
| Escribir programas (PROG) | ✅ | ✅ |
| **Escribir Function Modules** | ❌ | ✅ |
| Activar objetos | ✅ | ✅ |

### Paso 7 — Debugging en vivo: el loop que no terminaba

Después del deploy inicial, el desarrollador ejecutó una prueba real desde el workflow PPD. Al monitorear en el debugger ABAP, detectó que el loop de reintentos no salía correctamente — el contador `LV_RETRY_COUNT` superaba el valor de `LC_MAX_RETRIES` (26 vs 24).

El desarrollador compartió un screenshot del debugger directamente en el chat de Kiro. Kiro analizó la imagen y el código, e identificó el problema:

El `DO lc_max_retries TIMES` combinado con `EXIT` dentro del bloque `IF sy-subrc = 0` era ambiguo. En ABAP, `EXIT` dentro de un `DO...ENDDO` debería salir del loop, pero en el contexto de ejecución del workflow (con múltiples niveles de call stack), el comportamiento no era el esperado.

**El fix:** reemplazar `DO...ENDDO` + `EXIT` por un `WHILE` con condición explícita:

```abap
" ANTES (problemático):
DO lc_max_retries TIMES.
  ...
  IF sy-subrc = 0.
    EXIT.    " ← Ambiguo en contexto de WF
  ENDIF.
  lv_retry_count = lv_retry_count + 1.
ENDDO.

" DESPUÉS (corregido):
WHILE lv_lock_acquired = abap_false AND lv_retry_count < lc_max_retries.
  ...
  IF sy-subrc = 0.
    lv_lock_acquired = abap_true.   " ← Condición del WHILE lo saca limpio
  ELSE.
    lv_retry_count = lv_retry_count + 1.
  ENDIF.
ENDWHILE.
```

Dos mejoras clave:
1. La condición de salida es explícita en la cabecera del `WHILE` — no depende de `EXIT`
2. El incremento del contador solo ocurre en el `ELSE` (cuando el lock falla), no en cada iteración

Kiro subió el fix a BZD y lo activó en la misma OT `BZDK930898`. El objeto ya estaba registrado en la orden de transporte del primer deploy.

**Lección clave:** Kiro puede interpretar screenshots del debugger ABAP. El desarrollador no tuvo que describir el problema en texto — la imagen fue suficiente para que Kiro correlacionara los valores de las variables con el código y propusiera el fix.

### Paso 8 — Integración con el Workflow: que el paso quede en ERROR

Con el loop corregido, surgió un nuevo requerimiento: cuando la quotation sigue bloqueada después de 2 minutos, el paso del workflow `WS95000007` (QuotationPPD) debía quedar en estado **ERROR** para poder reintentarlo desde la transacción SWPR (Workflow Restart After Error).

El desarrollador compartió screenshots del Workflow Builder mostrando el paso "Update Rejection Reason Code after" y la pantalla de SWPR.

**El problema:** con el `RETURN` original, la FM salía limpiamente. El workflow engine interpretaba esto como ejecución exitosa — el paso terminaba "bien" aunque la quotation no se actualizó.

Kiro propuso 3 opciones y recomendó la más directa:

**Opción C — MESSAGE TYPE 'E' dentro de la FM:**

```abap
" ANTES:
      RETURN.    " ← Sale limpio, WF cree que todo OK

" DESPUÉS:
      MESSAGE e000(zsd) WITH 'Quotation' i_salesorder 'locked by' lv_lock_user.
      " ← MESSAGE TYPE E causa que el WF engine ponga el paso en ERROR
```

Un `MESSAGE TYPE 'E'` dentro de una FM llamada desde un workflow task causa que el work item quede en estado ERROR. El workflow engine captura la excepción y el paso se puede reintentar desde SWPR.

El cambio solo aplica al escenario de workflow (no-CPQ). El escenario CPQ sigue usando `RETURN` con `TA_BAPIRET` porque CPQ maneja sus propios errores.

Kiro subió el cambio a BZD, lo activó, y el flujo completo quedó:

```
1. Lock falla después de 2 min → UPDATE_FAILED = 'X'
2. Envía email de notificación al agente (como antes)
3. MESSAGE TYPE 'E' → WF engine captura la excepción
4. Work item del paso "Update Rejection Reason Code" → estado ERROR
5. Desde SWPR → buscar WF, ver error, reintentar cuando quotation esté libre
```

### Paso 9 — Ciclo completo: 3 iteraciones de deploy en una sesión

Este ejercicio demostró algo que no se había logrado antes: **3 ciclos completos de code → deploy → test → fix → redeploy** en una sola sesión de Kiro, sin abrir Eclipse ADT ni SAP GUI para editar código:

| Iteración | Qué se hizo | Resultado |
|-----------|-------------|-----------|
| 1ª | Deploy inicial con ENQUEUE + DO loop | Código en BZD, pero loop no salía bien |
| 2ª | Fix del WHILE (reemplazo DO por WHILE) | Loop funciona correctamente |
| 3ª | MESSAGE TYPE E para integración con WF | Paso del WF queda en ERROR, reiniciable desde SWPR |

Cada iteración fue: editar local → `sap_update_function_module_source` → `sap_activate_object` → verificar. Todo dentro de la OT `BZDK930898`.

### Resumen del ejercicio

| Actividad | Manual | Con Kiro |
|-----------|--------|----------|
| Leer y analizar la FM | 20-30 min | 2 min |
| Diseñar solución + documentación | 1-2 horas | 5 min |
| Evolucionar MCP Server (nueva API) | N/A | 5 min |
| Deploy + activación en BZD | 10-15 min (Eclipse ADT) | 1 min |
| Verificación post-deploy | 5 min | 1 min |
| Debugging en vivo + fix del WHILE | 30-45 min | 3 min |
| Integración con WF (MESSAGE TYPE E) | 20-30 min | 2 min |
| **Total** | **~4 horas** | **~19 minutos** |

### Lecciones aprendidas

1. **El MCP Server sigue creciendo orgánicamente** — cada requerimiento real descubre una capacidad faltante que se agrega en minutos. El patrón lock → write → unlock de ADT es consistente entre programas y FMs, solo cambia el endpoint.
2. **Kiro genera código conservador** — no tocó ni una línea del código existente. Los 3 bloques de inserción están claramente delimitados con search terms, siguiendo la convención del equipo.
3. **El análisis de impacto es instantáneo** — Kiro identificó los dos escenarios (CPQ y workflow) y generó manejo de error para ambos, incluyendo notificación por email reutilizando el patrón existente.
4. **La documentación se genera como subproducto** — el análisis, el TD y el código se crearon en una sola sesión. No fue un paso adicional.
5. **El deploy desde Kiro elimina el context-switch** — no hubo necesidad de abrir Eclipse ADT, buscar el objeto, hacer lock manual, pegar código, activar. Todo ocurrió en el mismo flujo de trabajo.
6. **Kiro interpreta screenshots del debugger** — el desarrollador compartió una imagen del ABAP Debugger y Kiro correlacionó los valores de las variables con el código para identificar el bug del loop.
7. **El ciclo code-deploy-test-fix es iterativo** — 3 deploys en una sesión, cada uno corrigiendo un aspecto diferente (lógica de retry, estructura del loop, integración con WF). Sin Kiro, cada ciclo requeriría abrir Eclipse, buscar el objeto, editar, activar.
8. **Kiro entiende el contexto de SAP Workflow** — propuso la solución correcta (`MESSAGE TYPE 'E'`) sabiendo que el workflow engine captura excepciones de tipo E para poner el paso en error, y que SWPR permite reintentar.

---

## 8. Ejercicio: Deploy del fix EHP8 al Daily Invoice Report — Lecciones de control

### Contexto

Después de analizar y generar el fix del bug SCOMNO (Sección 6), llegó el momento de subir el cambio al sistema BZD 130. Este ejercicio reveló lecciones críticas sobre **cómo controlar a la IA cuando interactúa con sistemas productivos**.

### Paso 1 — Lectura del código actual de BZD para diff

Antes de subir nada, Kiro leyó el include `ZSDR_DAILY_INVOICE_REPORT_F01` directamente de BZD 130 con `sap_get_include_source` y lo comparó con la versión local que tenía el fix. Confirmó que la línea problemática seguía ahí:

```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

Se identificaron los 3 puntos exactos de inserción del fix, sin tocar ninguna otra línea del código existente.

### Paso 2 — Intento de crear la Orden de Transporte desde Kiro

Se intentó crear la OT `L2C:CHG0436752- EHP8 hyper-INC08320193-BZP-036` directamente desde Kiro usando la ADT CTS API. Esto requirió evolucionar el MCP Server (tercera vez) agregando `sap_create_transport`.

El proceso de descubrimiento fue iterativo:

| Intento | Resultado | Aprendizaje |
|---------|-----------|-------------|
| 1 — XML formato `tm:root` | 400 Invalid Data | Formato incorrecto |
| 2 — XML formato `asx:abap` sin REF | 500 Resource could not be created | Necesita URI del objeto |
| 3 — Con REF del include | 500 Must be assigned to a project | BZD tiene CTS Project Management |
| 4 — Con `cts_project` como query param | 500 Must be assigned to a project | Parámetro no reconocido |
| 5 — Con `CTS_PROJECT` en XML body | 500 Must be assigned to a project | Campo no estándar del XML |

La creación de OTs en sistemas con CTS Project Management habilitado (como BZD con proyecto `FSBPRLZT` / `BZD_P00001`) requiere una integración más profunda con el Transport Organizer que la API REST estándar no expone completamente.

**Decisión:** crear la OT manualmente en SE09 y pasar el número a Kiro.

### Paso 3 — Deploy exitoso con OT proporcionada

Con la OT `BZDK930912` creada manualmente, el deploy fue inmediato:

```
1. sap_update_program_source(ZSDR_DAILY_INVOICE_REPORT_F01, source, BZDK930912) → ✅ OK
2. sap_activate_object(ZSDR_DAILY_INVOICE_REPORT_F01, PROG/I) → ✅ Activado
3. sap_get_include_source(ZSDR_DAILY_INVOICE_REPORT_F01) → ✅ Verificado
```

Los 3 bloques del fix quedaron activos en BZD 130.

### Paso 4 — Lo que falta: variable TVARVC

El fix usa una variable `ZSD_DAILY_INV_EHP8_DATE` en TVARVC como switch de fecha. Sin ella, el fallback es `99991231` (comportamiento original, no rompe nada). Para activar el fix:

- Transacción `STVARV`
- Name: `ZSD_DAILY_INV_EHP8_DATE`
- Type: `P` (Parameter)
- Low: `20260401` (fecha de corte del EHP8)

---

## 9. Reglas de oro para controlar la IA en desarrollo ABAP

Esta sección nace de la experiencia real de las sesiones anteriores. Son las reglas que todo ABAP developer debe seguir cuando trabaja con Kiro u otra IA conectada a SAP.

### 9.1 Control de Órdenes de Transporte

**REGLA #1: Siempre proporcionar la OT explícitamente.**

Si no le das una OT a Kiro, pueden pasar dos cosas:
- El sistema rechaza el cambio (como en BZD con CTS Project Management)
- El cambio se graba en una OT que no controlas, o peor, en `$TMP`

```
❌ "Sube el código a SAP"
✅ "Sube el código a SAP usando la OT BZDK930912"
```

**REGLA #2: Crear la OT antes de pedirle a Kiro que suba código.**

El flujo correcto es:
1. Tú creas la OT en SE09/SE10 con la descripción correcta del change
2. Le das el número a Kiro
3. Kiro sube y activa usando esa OT

Esto garantiza que:
- La OT tiene la descripción correcta del ticket/change
- Está asignada al proyecto CTS correcto
- Está bajo tu control para release

### 9.2 Control de lo que se sube

**REGLA #3: Siempre pedir un diff antes de subir.**

Antes de que Kiro escriba en SAP, pídele que lea el código actual y te muestre las diferencias exactas. Así verificas que solo se modifican las líneas que esperas.

```
✅ "Lee el include actual de BZD y muéstrame el diff con nuestra versión local"
```

**REGLA #4: Verificar después de subir.**

Después de cada deploy, pídele a Kiro que lea el código de vuelta desde SAP para confirmar que quedó correcto.

```
✅ "Lee el include de BZD para verificar que el fix quedó bien"
```

**REGLA #5: Un cambio a la vez.**

No le pidas a Kiro que suba 5 objetos de una vez. Sube uno, verifica, sube el siguiente. Si algo sale mal, sabes exactamente qué objeto fue.

### 9.3 Control de la activación

**REGLA #6: Activar explícitamente, no automáticamente.**

Algunos flujos de Kiro (como `sap_create_program`) activan automáticamente después de crear. Para objetos existentes en producción, es mejor controlar la activación por separado:

```
✅ "Sube el código pero NO lo actives todavía"
✅ "Ahora sí, activa el include"
```

### 9.4 Control del alcance

**REGLA #7: Kiro no debe modificar código que no entiendas.**

Si Kiro propone un cambio y no entiendes por qué, no lo subas. Pregúntale que te explique línea por línea. El ABAP developer es el responsable final del código en SAP.

**REGLA #8: Nunca subir a PRD sin revisión humana.**

Kiro sube a DEV (BZD). El proceso de transporte a QAS y PRD sigue siendo 100% controlado por el equipo. Kiro no tiene (ni debe tener) acceso a sistemas productivos.

### 9.5 Control del MCP Server

**REGLA #9: El MCP Server es tu responsabilidad.**

El MCP Server es el puente entre Kiro y SAP. Si le agregas una herramienta de escritura, eres responsable de lo que esa herramienta puede hacer. Revisa el código del MCP Server periódicamente.

**REGLA #10: Principio de mínimo privilegio.**

El usuario SAP que usa el MCP Server debe tener solo los permisos necesarios. Si solo necesitas leer código, no le des permisos de escritura. Si solo trabajas en SD, no le des acceso a FI.

### 9.6 Resumen visual

```
┌─────────────────────────────────────────────────────────┐
│              FLUJO CONTROLADO DE DEPLOY                  │
│                                                          │
│  1. Dev crea OT en SE09 ──────────────────┐              │
│  2. Dev pide a Kiro que lea código actual  │              │
│  3. Dev revisa el diff propuesto           │  CONTROL     │
│  4. Dev da la OT a Kiro ──────────────────┘  HUMANO      │
│  5. Kiro sube código con la OT                           │
│  6. Dev pide verificación post-deploy ────┐              │
│  7. Dev activa (o pide a Kiro activar)    │  VERIFICACIÓN │
│  8. Dev lee código de vuelta desde SAP ───┘              │
│  9. Dev prueba en sistema                                │
│ 10. Dev transporta a QAS/PRD (manual) ──── TRANSPORTE    │
└─────────────────────────────────────────────────────────┘
```

---

## 10. Casos de uso donde Kiro brilla

| Caso de Uso | Nivel de Ayuda |
|-------------|----------------|
| Análisis de FDs y documentos de requerimiento | ⭐⭐⭐⭐⭐ |
| Búsqueda y lectura de código existente en SAP | ⭐⭐⭐⭐⭐ |
| Generación de código siguiendo patrones existentes | ⭐⭐⭐⭐⭐ |
| Refactoring de código legacy a ABAP moderno/OO | ⭐⭐⭐⭐⭐ |
| Creación de clases de test (ABAP Unit) | ⭐⭐⭐⭐⭐ |
| Documentación técnica automática | ⭐⭐⭐⭐ |
| Análisis de incidentes con logs y dumps | ⭐⭐⭐⭐ |
| Configuración SAP (SPRO, tablas de customizing) | ⭐⭐ |
| Debugging interactivo en runtime | ⭐ |

---

## 11. Arquitectura de la solución

```
┌─────────────────────────────────────────────────┐
│                   Kiro IDE                       │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Steering │  │   Chat   │  │  File System  │  │
│  │  Rules   │  │  Agent   │  │  (workspace)  │  │
│  └──────────┘  └────┬─────┘  └───────────────┘  │
│                     │                            │
│              ┌──────┴──────┐                     │
│              │ MCP Client  │                     │
│              └──────┬──────┘                     │
└─────────────────────┼───────────────────────────┘
                      │ HTTP/REST
              ┌───────┴───────┐
              │  MCP Server   │
              │  (Python)     │
              └───────┬───────┘
                      │ ADT REST API
              ┌───────┴───────┐
              │   SAP BZD     │
              │  ECC 6.0 EHP8 │
              │  Cliente 130  │
              └───────────────┘
```

---

## 12. Capacidades actuales del MCP Server

| Capacidad | Herramienta MCP | Estado |
|-----------|----------------|--------|
| Ping / conectividad | `sap_ping` | ✅ |
| Leer programas (PROG) | `sap_get_program_source` | ✅ |
| Leer includes (PROG/I) | `sap_get_include_source` | ✅ |
| Leer clases (CLAS) | `sap_get_class_source` | ✅ |
| Leer Function Modules | `sap_get_function_module_source` | ✅ |
| Buscar objetos | `sap_search_objects` | ✅ |
| Leer tablas DDIC | `sap_get_table_definition` | ✅ |
| Crear programas | `sap_create_program` | ✅ |
| Actualizar programas/includes | `sap_update_program_source` | ✅ |
| Actualizar Function Modules | `sap_update_function_module_source` | ✅ |
| Activar objetos | `sap_activate_object` | ✅ |
| Ejecutar ABAP Unit | `sap_run_abap_unit` | ✅ |
| Crear OT (sin CTS Project) | `sap_create_transport` | ⚠️ Parcial |
| Crear OT (con CTS Project) | — | ❌ Requiere SE09 manual |
| Listar servicios ADT | `sap_check_adt_capabilities` | ✅ |
| Probar endpoints | `sap_test_endpoint` | ✅ |

---

## 13. Próximos pasos

- [ ] Refinar este documento después de la primera revisión
- [ ] Agregar más casos de uso reales (Quick Orders, Quotation Salesforce, Stock Query)
- [ ] Preparar demo en vivo para el workshop
- [ ] Definir checklist de "FD ready for Kiro" para el equipo funcional
- [ ] Evaluar métricas de productividad antes/después en sprints reales

---

*Documento generado a partir de sesión real de trabajo con Kiro — Abril 2026*
*Versión 1.0 — Para revisión y refinamiento*
