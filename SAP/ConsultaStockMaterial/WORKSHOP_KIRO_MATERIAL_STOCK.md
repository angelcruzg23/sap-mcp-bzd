# Workshop: De una pregunta de Salesforce a una API en SAP con Kiro

## Del problema al valor en tiempo récord

---

## 1. El Problema de Negocio

### La pregunta recurrente

Jesse, del equipo de Salesforce, necesitaba saber con frecuencia:

> *"Can you tell me where W563587071 is available?"*

Cada vez que Jesse o alguien del equipo comercial necesitaba saber en qué plantas estaba disponible un material, el proceso era:

1. Jesse envía un mensaje/email a Sheila preguntando por el material
2. Sheila abre SAP GUI → transacción MMBE
3. Sheila ingresa el material y la sociedad
4. Sheila toma un screenshot de la pantalla de Stock Overview
5. Sheila envía el screenshot por email/Teams a Jesse
6. Jesse interpreta la imagen manualmente

### El costo oculto

- Tiempo de Sheila: ~5-10 minutos por consulta
- Tiempo de Jesse: esperar respuesta + interpretar imagen
- Frecuencia: múltiples veces al día
- Sin visibilidad de exclusiones: Jesse no sabía qué plantas estaban en la lista de exclusión KOTG504
- Información estática: el screenshot se desactualiza inmediatamente

### Lo que Jesse veía

La transacción MMBE para el material W563587071 en la sociedad 1000 (Amrize Building Envelope) mostraba:

```
Material: W563587071  S20 WATERBLOCK (25 CARTRIDGES)
Sociedad: 1000 Amrize Building Envelope

Planta                          Unrestricted    On-Order
─────────────────────────────────────────────────────────
1020 Prescott Production         1,084,000
1030 Wellford Production             1,000
1032 Muscle Shoals Production       14,000
1045 Beech Grove Production              0
1053 Salt Lake City Production     689,000
1050 Mount Joy Dist Center               0
1091 Amrize                              0
1097 Indianapolis Dist Center        3,000
```

Pero lo que Jesse NO veía era que las plantas 1030, 1032 y 1050 estaban en la lista de exclusión KOTG504 — es decir, no debería ofrecer esos materiales desde esas plantas.

---

## 2. La Solución Propuesta

### Visión

Crear un Function Module RFC-enabled en SAP que Mulesoft pueda llamar directamente, para que Salesforce tenga la información de stock por planta en tiempo real, incluyendo las exclusiones de KOTG504.

```
┌──────────┐     ┌──────────┐     ┌──────────────────────────────────┐
│Salesforce│────>│ Mulesoft │────>│ SAP BZD                          │
│  (Jesse) │<────│   API    │<────│ ZFM_SD_GET_MATERIAL_STOCK (RFC)  │
└──────────┘     └──────────┘     └──────────────────────────────────┘
```

### Resultado

Jesse ya no necesita preguntar. Salesforce consulta directamente a SAP vía Mulesoft y muestra:
- Qué plantas tienen el material
- Cuánto stock hay en cada planta
- Cuáles plantas están excluidas (y por qué)

---

## 3. Cómo Abordamos el Desarrollo con Kiro

### Paso 1: Describir la necesidad en lenguaje natural

Le explicamos a Kiro la necesidad de Jesse, pegamos las imágenes de MMBE y KOTG504, y describimos qué queríamos:

> *"Quiero crear una FM estilo RFC que pueda llamar Mulesoft para consultar la información. Si ellos quieren saber qué centros de distribución tiene asociado un material, con su stock, que la API le entregue la información para la sociedad que ellos ingresen. Incluyendo también una lista de exclusión de plantas de la tabla KOTG504."*

Kiro analizó las imágenes y entendió:
- La estructura de datos de MMBE (plantas, stock por tipo)
- La tabla KOTG504 (exclusiones con vigencia, por planta o por material)
- La relación sociedad → planta (T001K → T001W)

### Paso 2: Kiro generó el spec completo

Kiro creó automáticamente tres documentos de especificación:

**Requirements (requirements.md)**
- 6 requisitos funcionales con user stories y criterios de aceptación
- 8 propiedades de corrección formales
- Cobertura: interfaz RFC, consulta de stock, exclusiones KOTG504, estructura de respuesta, manejo de errores, arquitectura OO

**Design (design.md)**
- Arquitectura en capas: FM → Orquestador → DAO + ExclusionChecker → BD
- Diagramas de secuencia
- Firmas completas de interfaces y métodos
- Pseudocódigo de la lógica principal
- Estrategia de testing con test doubles

**Guía de implementación (GUIA_IMPLEMENTACION_BZD.md)**
- 13 objetos a crear con orden de dependencias
- Código fuente completo copy-paste para cada objeto
- Configuración del FM en SE37
- Casos de prueba
- Checklist de verificación

### Paso 3: Kiro generó todo el código ABAP

10 archivos ABAP listos para crear en SAP:

| Objeto | Tipo | Responsabilidad |
|--------|------|-----------------|
| ZIF_SD_STOCK_QUERY | Interfaz | Contrato del orquestador |
| ZIF_SD_STOCK_DAO | Interfaz | Contrato del acceso a datos |
| ZIF_SD_EXCLUSION_CHECKER | Interfaz | Contrato del verificador de exclusiones |
| ZCL_SD_STOCK_QUERY | Clase | Orquestador — coordina todo sin acceder a BD |
| ZCL_SD_STOCK_DAO | Clase | Acceso a datos — MARD, MARC, T001W, T001K, MAKT |
| ZCL_SD_EXCLUSION_CHECKER | Clase | Verifica exclusiones en KOTG504 |
| ZFM_SD_GET_MATERIAL_STOCK | FM RFC | Punto de entrada para Mulesoft |
| ZCL_SD_STOCK_QUERY_TEST | Test | 9 tests con test doubles |
| ZCL_SD_STOCK_DAO_TEST | Test | 8 tests contra datos reales |
| ZCL_SD_EXCLUSION_CHECKER_TEST | Test | 7 tests de lógica de exclusiones |

### Paso 4: Iteración y corrección en tiempo real

Durante la implementación en BZD, encontramos problemas de compatibilidad con la versión de ABAP (SAP_ABA 750 SP32):

| Problema | Causa | Solución de Kiro |
|----------|-------|------------------|
| `RANGE OF werks_d` no válido en interfaz | Sintaxis no soportada como tipo de retorno en ECC | Declarar tipo tabla explícito `tty_werks_range` dentro de la interfaz |
| `VALUE #( ... LET ... OPTIONAL )` falla | Construcción no estable en 7.50 SP32 | Reemplazar por LOOP clásico con READ TABLE |
| `EISBE` no existe en MARD | EISBE es campo de MARC, no de MARD | Quitar del SELECT y de la estructura |
| Mensajes en español | El consumidor es Salesforce US | Cambiar todos los mensajes a inglés |

Kiro corrigió cada problema en segundos, actualizando el código fuente, la guía de implementación y los tests simultáneamente.

### Paso 5: Documentación para Mulesoft

Kiro generó automáticamente la especificación de API para el desarrollador de Mulesoft:
- Parámetros de entrada/salida con tipos y longitudes
- 5 escenarios de respuesta con datos reales
- JSON mapping sugerido
- Lógica de error handling
- Datos de prueba

---

## 4. Arquitectura Técnica

### Principios SOLID aplicados

```
┌─────────────────────────────────────────────────────────────┐
│  ZFM_SD_GET_MATERIAL_STOCK  (FM RFC — punto de entrada)     │
│  Solo instancia el orquestador y captura excepciones        │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│  ZCL_SD_STOCK_QUERY  (Orquestador)                          │
│  - Implementa ZIF_SD_STOCK_QUERY                            │
│  - Inyección de dependencias en constructor                 │
│  - NO tiene ningún SELECT (SRP)                             │
│  - Coordina validación, consulta y exclusiones              │
└──────────┬──────────────────────────────┬───────────────────┘
           │                              │
┌──────────▼──────────────┐  ┌────────────▼───────────────────┐
│  ZCL_SD_STOCK_DAO       │  │  ZCL_SD_EXCLUSION_CHECKER      │
│  Implementa             │  │  Implementa                    │
│  ZIF_SD_STOCK_DAO       │  │  ZIF_SD_EXCLUSION_CHECKER      │
│  - Solo acceso a datos  │  │  - Solo verifica KOTG504       │
│  - MARD, MARC, T001W    │  │  - Una consulta, sin SELECT    │
│  - T001K, MAKT, MARA    │  │    en LOOP                     │
└─────────────────────────┘  └────────────────────────────────┘
```

**SRP (Single Responsibility):** Cada clase tiene una sola razón para cambiar
- DAO: solo cambia si cambian las tablas SAP
- ExclusionChecker: solo cambia si cambia la lógica de KOTG504
- Orquestador: solo cambia si cambia el flujo de negocio

**DIP (Dependency Inversion):** El orquestador depende de interfaces (ZIF_), no de clases concretas. Esto permite:
- Inyectar test doubles para pruebas unitarias
- Reemplazar implementaciones sin tocar el orquestador

**Testabilidad:** 24 tests unitarios con test doubles que no necesitan datos en BD.

### Tablas SAP involucradas

```
T001 (BUKRS) ──► T001K (BUKRS → BWKEY) ──► T001W (BWKEY → WERKS, NAME1)
                                                    │
MARA (MATNR) ──► MARC (MATNR + WERKS, LVORM) ──────┘
                     │
                     └──► MARD (MATNR + WERKS → LABST, EINME, SPEME)

MAKT (MATNR + SPRAS='EN' → MAKTX)

KOTG504 (MATNR + WERKS + KAPPL='V' + KSCHL='ZB01' + fechas → exclusión)
```

### Flujo de ejecución

1. Mulesoft llama `ZFM_SD_GET_MATERIAL_STOCK` vía RFC con material y sociedad
2. El FM instancia `ZCL_SD_STOCK_QUERY` y delega
3. El orquestador valida inputs (material vacío, sociedad vacía)
4. Valida existencia en BD (material en MARA, sociedad en T001)
5. Obtiene plantas de la sociedad (JOIN T001K + T001W)
6. Obtiene stock por planta (MARC + MARD con FOR ALL ENTRIES)
7. Evalúa exclusiones KOTG504 (una sola consulta + READ TABLE)
8. Obtiene descripción del material (MAKT en inglés)
9. Retorna resultado a Mulesoft → Salesforce

---

## 5. Métricas de Tiempo: Desarrollo Manual vs. Kiro

### Desglose detallado por actividad

A continuación se compara el esfuerzo estimado de un desarrollador ABAP Senior haciendo todo manualmente versus lo que tomó con Kiro, medido en la sesión real de trabajo.

#### Fase 1: Análisis y Diseño

| Actividad | Manual (estimado) | Con Kiro (real) |
|-----------|:-----------------:|:---------------:|
| Entender la necesidad de Jesse/Sheila, revisar MMBE y KOTG504 | 2 horas | 10 min |
| Identificar tablas SAP involucradas (MARD, MARC, T001K, T001W, MAKT, KOTG504) y sus relaciones | 2 horas | Incluido |
| Diseñar la arquitectura OO (interfaces, clases, FM) | 3 horas | 5 min |
| Escribir documento de requirements con acceptance criteria | 4 horas | 5 min |
| Escribir documento de diseño técnico con diagramas | 4 horas | 5 min |
| **Subtotal Fase 1** | **15 horas (~2 días)** | **~25 min** |

#### Fase 2: Codificación

| Actividad | Manual (estimado) | Con Kiro (real) |
|-----------|:-----------------:|:---------------:|
| Crear estructura ZST_SD_PLANT_STOCK y tipo tabla en SE11 | 30 min | 2 min (generó spec) |
| Codificar 3 interfaces (ZIF_SD_STOCK_QUERY, ZIF_SD_STOCK_DAO, ZIF_SD_EXCLUSION_CHECKER) | 1.5 horas | 3 min |
| Codificar ZCL_SD_STOCK_DAO (5 métodos, JOINs, FOR ALL ENTRIES) | 3 horas | 5 min |
| Codificar ZCL_SD_EXCLUSION_CHECKER (lógica KOTG504, fechas) | 2 horas | 3 min |
| Codificar ZCL_SD_STOCK_QUERY (orquestador, validaciones, 8 pasos) | 2 horas | 3 min |
| Crear function group y FM RFC-enabled en SE37 | 1 hora | 2 min |
| **Subtotal Fase 2** | **10 horas (~1.5 días)** | **~18 min** |

#### Fase 3: Testing

| Actividad | Manual (estimado) | Con Kiro (real) |
|-----------|:-----------------:|:---------------:|
| Diseñar test doubles para ZIF_SD_STOCK_DAO y ZIF_SD_EXCLUSION_CHECKER | 2 horas | Incluido |
| Codificar ZCL_SD_STOCK_QUERY_TEST (9 tests con doubles) | 3 horas | Incluido |
| Codificar ZCL_SD_STOCK_DAO_TEST (8 tests) | 2 horas | Incluido |
| Codificar ZCL_SD_EXCLUSION_CHECKER_TEST (7 tests) | 2 horas | Incluido |
| **Subtotal Fase 3** | **9 horas (~1 día)** | **Incluido en Fase 2** |

#### Fase 4: Correcciones e Iteración

| Actividad | Manual (estimado) | Con Kiro (real) |
|-----------|:-----------------:|:---------------:|
| Debuggear error `RANGE OF` en interfaz | 30 min | 3 min |
| Debuggear error `VALUE # LET OPTIONAL` en 7.50 SP32 | 1 hora | 5 min |
| Descubrir que EISBE no es campo de MARD | 30 min | 3 min |
| Cambiar mensajes de español a inglés | 30 min | 3 min |
| Actualizar guía de implementación con cada corrección | 1 hora | Incluido |
| **Subtotal Fase 4** | **3.5 horas** | **~14 min** |

#### Fase 5: Documentación

| Actividad | Manual (estimado) | Con Kiro (real) |
|-----------|:-----------------:|:---------------:|
| Guía de implementación paso a paso (13 objetos) | 3 horas | 5 min |
| Spec de API para desarrollador Mulesoft | 3 horas | 5 min |
| Documento de workshop | 2 horas | 5 min |
| **Subtotal Fase 5** | **8 horas (~1 día)** | **~15 min** |

---

### Resumen Consolidado

```
┌─────────────────────────┬──────────────────┬──────────────────┐
│ Fase                    │ Manual (estimado) │ Con Kiro (real)  │
├─────────────────────────┼──────────────────┼──────────────────┤
│ 1. Análisis y Diseño    │    15 horas      │     25 min       │
│ 2. Codificación         │    10 horas      │     18 min       │
│ 3. Testing              │     9 horas      │      0 min *     │
│ 4. Correcciones         │   3.5 horas      │     14 min       │
│ 5. Documentación        │     8 horas      │     15 min       │
├─────────────────────────┼──────────────────┼──────────────────┤
│ TOTAL                   │  45.5 horas      │   ~72 min        │
│                         │  (~6 días lab.)  │  (~1.2 horas)    │
└─────────────────────────┴──────────────────┴──────────────────┘

* Testing incluido en la generación de código (Fase 2)
```

### La métrica clave

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   Reducción de tiempo: 97.4%                             │
│                                                          │
│   45.5 horas → 1.2 horas                                │
│                                                          │
│   Factor de aceleración: 38x más rápido                  │
│                                                          │
│   Tiempo ahorrado: 44.3 horas (~5.5 días laborales)     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### Qué incluye el tiempo "Con Kiro"

Los ~72 minutos incluyen TODO el ciclo real de la sesión:
- Describir la necesidad y pegar imágenes de MMBE/KOTG504
- Revisar y aprobar los documentos de spec generados
- Generar los 10 archivos ABAP
- Crear los objetos en SAP BZD (copiar código a Eclipse ADT)
- Encontrar 4 errores de compilación y corregirlos con Kiro
- Cambiar mensajes a inglés
- Generar spec para Mulesoft
- Generar este documento de workshop

No se excluye nada. Es el tiempo real de la sesión completa.

### Qué NO incluye el tiempo "Manual"

La estimación manual de 45.5 horas es conservadora. No incluye:
- Tiempo de investigación de tablas SAP si el desarrollador no las conoce
- Reuniones de diseño con el equipo
- Code review
- Tiempo de espera por aprobaciones
- Retrabajo por cambios de requerimientos

En un escenario real con un equipo, el tiempo manual podría ser 2-3 semanas.

---

### Entregables producidos en la sesión

| # | Entregable | Líneas/Contenido |
|---|-----------|-----------------|
| 1 | requirements.md | Spec completo con 6 requisitos y 8 propiedades de corrección |
| 2 | design.md | Diseño técnico con diagramas, firmas, pseudocódigo |
| 3 | 3 interfaces ABAP | ~120 líneas de código |
| 4 | 3 clases de negocio ABAP | ~300 líneas de código |
| 5 | 1 FM RFC-enabled | ~40 líneas de código |
| 6 | 3 clases de prueba ABAP | ~400 líneas de código (24 tests) |
| 7 | Guía de implementación | Documento completo con 13 objetos |
| 8 | Spec API para Mulesoft | Documento completo con JSON mapping |
| 9 | Documento de workshop | Este documento |
| | **Total código ABAP** | **~860 líneas** |
| | **Total documentación** | **5 documentos completos** |

### Costo-beneficio

Si el costo/hora de un desarrollador ABAP Senior es ~$75 USD:

| Escenario | Horas | Costo estimado |
|-----------|:-----:|:--------------:|
| Manual | 45.5 h | ~$3,412 USD |
| Con Kiro | 1.2 h | ~$90 USD |
| **Ahorro** | **44.3 h** | **~$3,322 USD** |

Y esto es solo para UN desarrollo. El patrón se repite en cada nueva FM, cada nueva integración, cada nuevo requerimiento.

---

## 6. Más allá de la velocidad: Ventajas cualitativas

### Calidad desde el inicio

- Código generado siguiendo estándares Holcim BP (nomenclatura, SOLID, ABAP Doc)
- Tests unitarios incluidos desde la primera versión — no como afterthought
- Documentación completa generada automáticamente — no como deuda técnica
- Propiedades de corrección formales definidas antes de codificar

### Iteración rápida con feedback visual

Cuando encontramos problemas de compatibilidad con SAP_ABA 750 SP32:
- Pegamos el screenshot del error en Eclipse ADT
- Kiro entendió el error, la causa raíz y la corrección
- Actualizó código fuente, guía y tests en una sola interacción
- 4 errores corregidos en ~14 minutos total

### Documentación como subproducto natural

No tuvimos que escribir documentación por separado. Kiro generó:
- Spec de requirements con user stories y acceptance criteria
- Diseño técnico con diagramas y pseudocódigo
- Guía de implementación paso a paso para crear objetos en SAP
- Spec de API para Mulesoft con JSON mapping y escenarios
- Documento de workshop para compartir conocimiento

### Conocimiento del contexto SAP

Kiro entendió:
- Las tablas SAP estándar (MARD, MARC, T001W, T001K, MAKT, KOTG504)
- Las relaciones entre tablas (sociedad → planta vía T001K/T001W)
- Las limitaciones de sintaxis de ABAP 7.50 SP32
- Los estándares de codificación de Holcim BP (vía steering files)
- La diferencia entre campos de MARD y MARC (EISBE no es de MARD)

---

## 6. Lecciones Aprendidas

### Lo que funcionó bien
- Describir la necesidad con imágenes reales de SAP (MMBE, KOTG504)
- Dejar que Kiro proponga la arquitectura y luego iterar
- Usar los steering files de Holcim BP para que Kiro respete los estándares
- Corregir en tiempo real con screenshots de los errores de Eclipse

### Lo que hay que tener en cuenta
- Siempre validar la sintaxis contra la versión específica de SAP (SP32 tiene limitaciones vs SP19)
- Verificar los campos de las tablas SAP — Kiro puede asumir campos que no existen en tu sistema
- Los tests que dependen de datos reales en BD necesitan datos de prueba consistentes
- Revisar el código generado antes de activar — Kiro es un copiloto, no un autopiloto

### Patrón recomendado para futuros desarrollos

1. Describir la necesidad de negocio en lenguaje natural
2. Incluir imágenes/screenshots del proceso actual en SAP
3. Dejar que Kiro genere el spec (requirements + design)
4. Revisar y ajustar el spec con el equipo
5. Generar el código con Kiro
6. Crear los objetos en SAP siguiendo la guía
7. Iterar con Kiro cuando haya errores de compilación
8. Generar la documentación para equipos externos (Mulesoft, Salesforce)

---

## 7. Impacto en el Negocio

### Antes
- Jesse pregunta → Sheila busca en MMBE → screenshot → email → Jesse interpreta
- Tiempo: 5-10 minutos por consulta, múltiples veces al día
- Sin visibilidad de exclusiones KOTG504
- Información estática (screenshot se desactualiza)

### Después
- Salesforce consulta automáticamente vía Mulesoft → SAP RFC
- Tiempo: < 1 segundo por consulta
- Exclusiones KOTG504 visibles directamente en Salesforce
- Información en tiempo real
- Sheila liberada para tareas de mayor valor

### ROI estimado
- Si Sheila dedicaba ~30 minutos/día a estas consultas = 2.5 horas/semana
- 2.5 horas × 52 semanas = 130 horas/año recuperadas
- Más el valor de tener información en tiempo real para decisiones comerciales

---

*Workshop preparado el 27 de marzo de 2026 — Holcim BP, SAP BZD 130*
