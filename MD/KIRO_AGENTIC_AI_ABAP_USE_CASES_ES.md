# Kiro: Agentic AI — Casos de Uso ABAP en Amrize
## Casos reales desde SAP ECC BZD 130 — Abril 2026

---

## Resumen Ejecutivo

Durante el último mes, el equipo de desarrollo SD ha utilizado Kiro (IDE con IA de Amazon) conectado a SAP BZD 130 mediante un servidor MCP personalizado. Este documento cataloga cada caso de uso real ejecutado, con tiempos medidos y lecciones aprendidas.

Resultado combinado de todos los casos: **~15 horas de trabajo manual comprimidas a ~50 minutos (~94% de reducción)**.

---

## Arquitectura

```
┌─────────────────────────────────────┐
│            Kiro IDE                  │
│  ┌──────────┐  ┌──────┐  ┌───────┐  │
│  │ Steering │  │ Chat │  │ Files │  │
│  │  Rules   │  │Agent │  │       │  │
│  └──────────┘  └──┬───┘  └───────┘  │
│                   │                  │
│            ┌──────┴──────┐           │
│            │ MCP Client  │           │
│            └──────┬──────┘           │
└───────────────────┼─────────────────┘
                    │ HTTP/REST
             ┌──────┴──────┐
             │ MCP Server  │
             │  (Python)   │
             └──────┬──────┘
                    │ ADT REST API
             ┌──────┴──────┐
             │  SAP BZD    │
             │ ECC 6.0 EHP8│
             └─────────────┘
```

Componentes clave:
- **Kiro IDE** — Agente de IA (Claude de Anthropic) con herramientas integradas
- **MCP Server** — Proceso Python que traduce peticiones de la IA a llamadas SAP ADT REST API
- **Steering files** — 7 archivos markdown que codifican los estándares del equipo (nomenclatura, codificación, patrones SOLID, flujo de deploy)
- **SAP BZD 130** — Sistema de desarrollo, ECC 6.0 EHP8, ABAP 7.50

---

## Catálogo de Casos de Uso


### CU-1: Desarrollo Nuevo desde Functional Design
**CHG0432318 — Tipo de Equipo Conestoga para US Bank**

| Atributo | Detalle |
|----------|---------|
| Categoría | Desarrollo nuevo |
| Objetos | FMs ZSDE_GET/SET_DATA_SHPMNT_HD_TAB, Enhancement ZSDE_TMS2SAP_DELIVERY_DATA |
| Qué hizo Kiro | Parseó FD en .mht, encontró objetos en SAP, generó 4 archivos ABAP siguiendo patrones existentes |
| Capacidad clave | Análisis de documentos + descubrimiento de objetos SAP + generación de código con convenciones del equipo |
| Estimado manual | ~2 horas |
| Con Kiro | ~6 minutos |

---

### CU-2: Debugging Estático de Reporte Productivo (Bug EHP8)
**ZSDR_DAILY_INVOICE_REPORT — Bug del SCOMNO**

| Atributo | Detalle |
|----------|---------|
| Categoría | Investigación de bug / Análisis de causa raíz |
| Objetos | Programa ZSDR_DAILY_INVOICE_REPORT + 4 includes (~1,500 líneas) |
| Qué hizo Kiro | Leyó todos los includes, simuló flujo de datos, encontró que `DELETE ltt_sood WHERE NOT scomno IS INITIAL` borra documentos transmitidos después del EHP8 |
| Capacidad clave | Debugging estático — simuló flujo de ejecución sin ejecutar el programa |
| Causa raíz | EHP8 cambió el comportamiento de SAPconnect: SCOMNO ahora se asigna inmediatamente al transmitir |
| Patrón del fix | Switch por fecha con TVARVC para proteger comportamiento pre-EHP8 |
| Estimado manual | ~3 horas |
| Con Kiro | ~13 minutos |
| Evolución MCP | Se agregó herramienta `sap_get_include_source` durante esta sesión (3 min) |

---

### CU-3: Modificación de FM con Deploy en Vivo (3 Iteraciones)
**CHG0436393 — Enqueue lock para ZSD_PPD_REJ_UPDATE**

| Atributo | Detalle |
|----------|---------|
| Categoría | Modificación de código + deploy + debugging iterativo |
| Objetos | FM ZSD_PPD_REJ_UPDATE (function group ZSD_PPD) |
| Qué hizo Kiro | Analizó FM, generó lógica enqueue/dequeue, desplegó 3 veces con correcciones |
| Iteración 1 | Deploy inicial con ENQUEUE + loop DO → el loop no salía correctamente |
| Iteración 2 | Kiro analizó screenshot del debugger, corrigió conversión DO→WHILE |
| Iteración 3 | Agregó MESSAGE TYPE 'E' para integración con Workflow (reinicio desde SWPR) |
| Capacidad clave | Interpretación de screenshots del debugger + deploy iterativo sin Eclipse |
| Estimado manual | ~4 horas |
| Con Kiro | ~19 minutos |
| Evolución MCP | Se agregó herramienta `sap_update_function_module_source` durante esta sesión (5 min) |

---

### CU-4: Investigación de Authority Check
**ZSDR_ANOKA_REPORT_BAK_N — "No authorization for W56LE601004 in plant 3096"**

| Atributo | Detalle |
|----------|---------|
| Categoría | Investigación de incidente / Análisis de causa raíz |
| Objetos | Programa ZSDR_ANOKA_REPORT_BAK_N + 3 includes (~2,500 líneas) |
| Qué hizo Kiro | Leyó todo el código, encontró 3 authority checks explícitos (descartó los 3), identificó al verdadero culpable: FM estándar `MD_STOCK_REQUIREMENTS_LIST_API` con auth check interno sobre `M_MTDI_ORG` |
| Capacidad clave | Análisis de referencias cruzadas — rastreó error desde barra de estado hasta FM estándar |
| Fix | 9 líneas de pre-check replicando el AUTHORITY-CHECK interno de la FM antes de llamarla |
| Estimado manual | ~3-4 horas |
| Con Kiro | ~6 minutos |

---

### CU-5: Arquitectura ABAP Moderna (Refactoring SOLID)
**ZR_SD_QUICK_ORDERS — De monolito a arquitectura testeable**

| Atributo | Detalle |
|----------|---------|
| Categoría | Arquitectura / Refactoring / Mejores prácticas |
| Objetos | ZR_SD_QUICK_ORDERS, ZCL_SD_QUICK_ORDERS, ZCL_SD_QUICK_ORDERS_DAO, ZIF_SD_QUICK_ORDERS_DAO, ZCL_SD_QUICK_ORDERS_TEST |
| Qué hizo Kiro | Refactorizó reporte monolítico en patrón DAO con inyección de dependencias y tests ABAP Unit |
| Capacidad clave | Aplicó principios SOLID desde los steering files para generar arquitectura testeable |
| Patrones aplicados | SRP (DAO separado), DIP (interfaces ZIF_), ABAP Unit con test doubles |

---

### CU-6: Arquitectura SOLID para Integración RFC
**ConsultaStockMaterial — ZFM_SD_GET_MATERIAL_STOCK**

| Atributo | Detalle |
|----------|---------|
| Categoría | Desarrollo nuevo / Integración RFC / Arquitectura SOLID completa |
| Objetos | ZFM_SD_GET_MATERIAL_STOCK, ZCL_SD_STOCK_QUERY, ZCL_SD_STOCK_DAO, ZCL_SD_EXCLUSION_CHECKER + 3 interfaces + 3 clases de test |
| Qué hizo Kiro | Diseñó y generó arquitectura completa: FM fachada → orquestador → DAO + checker de exclusiones, todo con interfaces y tests ABAP Unit |
| Capacidad clave | Generación de arquitectura end-to-end siguiendo patrones del equipo |
| Patrones aplicados | FM como fachada OO, patrón DAO, ISP (3 interfaces enfocadas), DIP con defaults, test doubles |

---

### CU-7: Code Review + Refactoring + Deploy con Syntax Check
**CHG0434843 — PROS Currency Rate GET (ZSD_PROS_CURRENCY_RATE_GET)**

| Atributo | Detalle |
|----------|---------|
| Categoría | Revisión de código + refactoring + deploy + evolución de herramientas |
| Objetos | FM ZSD_PROS_CURRENCY_RATE_GET (function group ZSD_PROS_INT) |
| Qué hizo Kiro | Listó órdenes de transporte abiertas, identificó objetos en la OT, revisó calidad del código, refactorizó SELECT-en-LOOP a FOR ALL ENTRIES, desplegó con OT, ejecutó syntax check |
| Problemas encontrados en código original | SELECT * dentro de LOOP, sin validación de SY-SUBRC, código comentado muerto, sin documentación |
| Iteraciones de deploy | 3 — primera con `INTO TABLE` incorrecto (necesitaba `INTO CORRESPONDING FIELDS OF TABLE`), segunda con tipos incompatibles en FOR ALL ENTRIES (necesitaba `TYPE tcurr-campo` en vez de data elements) |
| Capacidad clave | Listado de órdenes de transporte + revisión de código + syntax check vía ADT |
| Lecciones aprendidas | FOR ALL ENTRIES requiere `TYPE tabla-campo` (no data elements); activación ADT ≠ syntax check |
| Estimado manual | ~2 horas |
| Con Kiro | ~8 minutos |
| Evolución MCP | Se agregó herramienta `sap_syntax_check` durante esta sesión |

---

### CU-8: Análisis de Impacto EHP8 (Deploy del Daily Invoice Report)
**CHG0436752 — Deploy del fix SCOMNO a BZD**

| Atributo | Detalle |
|----------|---------|
| Categoría | Control de deploy / Validación de proceso |
| Objetos | Include ZSDR_DAILY_INVOICE_REPORT_F01 |
| Qué hizo Kiro | Leyó código actual de SAP, comparó con fix local, desplegó con OT proporcionada, activó, verificó |
| Lección clave | CTS Project Management bloquea creación de OTs vía API ADT — las OTs deben crearse manualmente en SE09 |
| Proceso validado | Flujo controlado completo: leer baseline → diff → subir → activar → verificar |

---

## Línea de Tiempo de Evolución del MCP Server

El servidor MCP es un activo vivo que crece con cada caso real:

| Capacidad | Herramienta | Cuándo se agregó | Disparado por |
|-----------|-------------|-------------------|---------------|
| Ping a SAP | `sap_ping` | Build inicial | — |
| Leer programas | `sap_get_program_source` | Build inicial | — |
| Leer clases | `sap_get_class_source` | Build inicial | — |
| Leer FMs | `sap_get_function_module_source` | Build inicial | — |
| Buscar objetos | `sap_search_objects` | Build inicial | — |
| Leer tablas DDIC | `sap_get_table_definition` | Build inicial | — |
| Crear programas | `sap_create_program` | Build inicial | — |
| Actualizar programas | `sap_update_program_source` | Build inicial | — |
| Activar objetos | `sap_activate_object` | Build inicial | — |
| Ejecutar ABAP Unit | `sap_run_abap_unit` | Build inicial | — |
| Capacidades ADT | `sap_check_adt_capabilities` | Build inicial | — |
| Probar endpoints | `sap_test_endpoint` | Build inicial | — |
| **Leer includes** | `sap_get_include_source` | CU-2 (3 min) | No podía leer includes de reportes |
| **Actualizar FMs** | `sap_update_function_module_source` | CU-3 (5 min) | No podía escribir source de FMs |
| **Crear transportes** | `sap_create_transport` | CU-8 | Necesidad de crear OTs |
| **Syntax check** | `sap_syntax_check` | CU-7 | Activación pasó pero el código tenía errores de sintaxis |

**Total actual: 16 herramientas** — cada una agregada en respuesta a una necesidad real, probada inmediatamente en contexto productivo.

---

## Steering Files (Base de Conocimiento del Equipo)

7 steering files codifican los estándares del equipo que Kiro sigue automáticamente:

| Archivo | Propósito |
|---------|-----------|
| `01-holcim-context.md` | Info del sistema, contexto EHP8, landscape de módulos |
| `02-naming-conventions.md` | Prefijos de objetos, convenciones de variables, search terms |
| `03-coding-standards.md` | Patrones obligatorios/prohibidos, patrones validados en producción, lecciones aprendidas |
| `04-solid-patterns.md` | DIP con ZIF_, patrón DAO, FM como fachada OO, test doubles |
| `06-sap-deploy-workflow.md` | Flujo controlado de deploy en 9 pasos, reglas de OT, limitaciones del MCP |
| `07-mcp-server-python.md` | Estándares de código del MCP server, referencia de endpoints ADT |

Estos archivos son la razón por la que Kiro genera código que parece escrito por alguien del equipo.

---

## Resumen de Ahorro de Tiempo

| # | Caso de Uso | Categoría | Manual | Con Kiro | Ahorro |
|---|-------------|-----------|--------|----------|--------|
| 1 | Tipo Equipo Conestoga | Desarrollo nuevo | ~2h | ~6 min | 95% |
| 2 | Bug SCOMNO (Daily Invoice) | Investigación de bug | ~3h | ~13 min | 93% |
| 3 | Enqueue Lock PPD (3 deploys) | Modificar + deploy + debug | ~4h | ~19 min | 92% |
| 4 | Investigación Authority Check | Investigación de incidente | ~3.5h | ~6 min | 97% |
| 7 | Refactor PROS Currency Rate | Code review + deploy | ~2h | ~8 min | 93% |
| | **Total medido** | | **~14.5h** | **~52 min** | **~94%** |

---

## Qué Hace Kiro vs. Qué Queda con el Desarrollador

| Kiro hace | El desarrollador hace |
|-----------|-----------------------|
| Leer miles de líneas de código en segundos | Decidir si el análisis es correcto |
| Encontrar objetos a través de módulos SAP | Validar impacto de negocio |
| Generar código siguiendo patrones del equipo | Revisar cada línea antes de subir |
| Producir documentación técnica | Probar en el sistema real |
| Desplegar y activar en DEV | Transportar a QAS/PRD (manual, controlado) |
| Analizar screenshots del debugger | Tomar decisiones de diseño |
| Ejecutar syntax checks después del deploy | Interpretar warnings y decidir acción |
| Listar órdenes de transporte | Crear OTs con el proyecto CTS correcto |

---

## Conclusiones Clave

1. **Kiro comprime trabajo mecánico, no pensamiento** — lectura, búsqueda, escritura y documentación pasan de horas a minutos. Las decisiones de diseño, pruebas y responsabilidad siguen siendo del desarrollador.

2. **El servidor MCP es un activo vivo** — 16 herramientas construidas orgánicamente, cada una disparada por una necesidad real. Agregar una nueva capacidad toma 3-5 minutos.

3. **Los steering files son el multiplicador** — sin ellos, Kiro genera ABAP válido pero genérico. Con ellos, genera código que sigue las convenciones del equipo desde el día uno. También acumulan lecciones aprendidas (como la regla de tipado en FOR ALL ENTRIES).

4. **El debugging estático es un game changer** — Kiro simula flujo de datos a través del código fuente sin ejecutar el programa. Identificó causas raíz en programas de 2,500+ líneas que tomarían horas de rastreo manual.

5. **Los ciclos iterativos de deploy son la nueva normalidad** — código → deploy → prueba → fix → redeploy, todo desde la misma sesión de chat, sin cambiar de herramienta.

6. **El rol del desarrollador cambia de ejecutor a arquitecto** — el valor está en el criterio técnico, el conocimiento del negocio, y la capacidad de decir "esto no va a funcionar porque..."

7. **Cada error se convierte en una lección permanente** — errores de sintaxis, incompatibilidades de tipos y problemas de deploy se documentan en los steering files para que no vuelvan a ocurrir.

---

*Compilado de sesiones reales de trabajo — Amrize BP, Abril 2026*
*Sistema: SAP ECC 6.0 EHP8 (BZD, Cliente 130)*
*IA: Kiro IDE con Claude (Anthropic) vía MCP Server*
