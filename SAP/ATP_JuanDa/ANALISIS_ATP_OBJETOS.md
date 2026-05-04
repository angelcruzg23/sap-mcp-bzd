# Análisis de Objetos ATP — Holcim BP (BZD 130)

## 1. Resumen Ejecutivo

Este documento analiza los objetos ABAP del componente ATP (Available-To-Promise) del módulo SD en el sistema SAP ECC 6.0 EHP8 de Holcim BP. El análisis se basa en el inventario de objetos proporcionado por JuanDa y la extracción directa del código fuente desde el sistema BZD 130 vía ADT.

### Estado de los Objetos

| Objeto | Tipo | ¿Existe en BZD? | Estado |
|--------|------|:---:|--------|
| ZCL_SD_ATP_HANDLER | Clase | ✅ | Código fuente recuperado |
| ZCL_SD_ATP_RESULT | Clase | ✅ | Código fuente recuperado |
| ZCL_SD_ATP_SIMULATOR | Clase | ✅ | Código fuente recuperado |
| ZCL_SD_ATP_CACHE | Clase | ✅ | Código fuente recuperado |
| ZIF_SD_ATP_CHECK | Interfaz | ❌ | No encontrada en repositorio |
| ZFM_SD_ATP_CHECK | Function Module | ❌ | No encontrado (FM / grupo ZFG_SD_ATP) |
| ZFM_SD_ATP_SIMULATION | Function Module | ❌ | No encontrado |
| ZFM_SD_ATP_BATCH_CHECK | Function Module | ❌ | No encontrado |
| ZSDT_ATP_CONFIG | Tabla | ❌ | No encontrada en DDIC |
| ZSDT_ATP_LOG | Tabla | ❌ | No encontrada en DDIC |
| ZSDT_ATP_RESULTS | Tabla | ❌ | No encontrada en DDIC |
| ZSSD_ATP_REQUEST | Estructura | ❌ | No verificable directamente |
| ZSSD_ATP_RESPONSE | Estructura | ❌ | No verificable directamente |
| ZSSD_ATP_ITEM | Estructura | ❌ | No verificable directamente |
| ZDE_SD_ATP_STATUS | Elemento de datos | ❌ | No verificable directamente |
| ZDE_SD_ATP_QTY | Elemento de datos | ❌ | No verificable directamente |
| ZDO_SD_ATP_STATUS | Dominio | ❌ | No verificable directamente |
| ZFG_SD_ATP | Grupo de funciones | ❌ | No encontrado |
| LZFG_SD_ATPTOP | Include TOP | ❌ | No encontrado |
| LZFG_SD_ATPF01 | Include F01 | ❌ | No encontrado |
| ZSD_ATP | Clase de mensajes | ❌ | No verificable directamente |
| ZEI_SD_ATP_BADI | Enhancement Impl. | ❌ | No verificable directamente |
| ZES_SD_ATP_CHECK | Enhancement Spot | ❌ | No verificable directamente |

> Las 4 clases OO existen y tienen código funcional. Los objetos de diccionario (tablas, estructuras, elementos de datos), function modules, y enhancements no fueron encontrados — probablemente están pendientes de creación o en otro sistema/transporte.

---

## 2. Arquitectura del Componente ATP

```
┌─────────────────────────────────────────────────────────┐
│                    CAPA DE CONSUMO                       │
│  ZFM_SD_ATP_CHECK  │  ZFM_SD_ATP_SIMULATION  │  BATCH   │
│  (Function Module)    (Function Module)        (FM)      │
│  ── pendientes de creación ──                            │
└──────────────┬──────────────────────┬───────────────────┘
               │                      │
┌──────────────▼──────────┐ ┌────────▼────────────────────┐
│  ZCL_SD_ATP_HANDLER     │ │  ZCL_SD_ATP_SIMULATOR       │
│  ─ check_availability   │ │  ─ simulate_order           │
│  ─ check_avail_multi    │ │  ─ simulate_single_item     │
│  ─ get_confirmed_qty    │ │  ─ get_alternative_plants   │
│  implements ZIF_SD_ATP  │ │  usa ZCL_SD_ATP_HANDLER     │
└──────┬──────────┬───────┘ └─────────────────────────────┘
       │          │
┌──────▼───┐ ┌───▼──────────────┐  ┌─────────────────────┐
│ ATP_CACHE│ │ ZCL_SD_ATP_RESULT│  │  ZSDT_ATP_CONFIG     │
│ (memoria)│ │ (Value Object)   │  │  ZSDT_ATP_LOG        │
│ TTL 300s │ │ ─ status checks  │  │  (tablas pendientes) │
└──────────┘ │ ─ shortage calc  │  └─────────────────────┘
             └──────────────────┘
```

---

## 3. Análisis Detallado por Clase

### 3.1 ZCL_SD_ATP_HANDLER — Orquestador Principal

**Responsabilidad:** Clase central que ejecuta la verificación ATP contra SAP usando `BAPI_MATERIAL_AVAILABILITY`.

**Interfaz pública:**

| Método | Parámetros | Retorno | Descripción |
|--------|-----------|---------|-------------|
| `constructor` | IV_VKORG, IV_VTWEG, IV_SPART, IV_WERKS?, IV_LGORT? | — | Inicializa org. ventas y dependencias |
| `check_availability` | IS_REQUEST (ZSSD_ATP_REQUEST) | RS_RESPONSE (ZSSD_ATP_RESPONSE) | Verificación ATP individual |
| `check_availability_multi` | IT_REQUESTS (tabla) | RT_RESPONSES (tabla) | Verificación ATP masiva |
| `get_confirmed_quantity` | IV_MATNR, IV_WERKS, IV_QUANTITY, IV_UNIT, IV_DATE? | RV_CONFIRMED_QTY (MENGE_D) | Atajo para obtener cantidad confirmada |
| `get_messages` | — | RT_MESSAGES (BAPIRET2_T) | Mensajes acumulados |

**Flujo de check_availability:**
1. Consulta caché → si hay resultado válido, retorna inmediatamente
2. Llama `BAPI_MATERIAL_AVAILABILITY` vía método privado `call_atp_bapi`
3. Aplica reglas de negocio (`apply_business_rules`)
4. Actualiza caché
5. Registra log en tabla `ZSDT_ATP_LOG`

**Reglas de negocio implementadas:**
- Cantidad mínima de pedido: si la cantidad confirmada es menor al mínimo configurado, se rechaza (status `R`)
- Bloqueo de crédito: si hay bloqueo crediticio, status cambia a `B` (Blocked)
- Bloqueo de entrega: si hay bloqueo de entrega, status cambia a `B`

**Dependencias internas (acoplamiento directo):**
- `ZCL_SD_MESSENGER` — manejo de mensajes (CREATE OBJECT directo)
- `ZCL_SD_ATP_CACHE` — caché en memoria (CREATE OBJECT directo)
- `ZCL_SD_ATP_CONFIG` — configuración (CREATE OBJECT directo, con TRY/CATCH)

**Implementa:** `ZIF_SD_ATP_CHECK~execute_check` → delega a `check_availability`

---

### 3.2 ZCL_SD_ATP_RESULT — Value Object

**Responsabilidad:** Encapsula la respuesta ATP y provee métodos de consulta semántica.

| Método | Retorno | Lógica |
|--------|---------|--------|
| `get_status` | ZDE_SD_ATP_STATUS | Retorna status directo |
| `get_confirmed_qty` | MENGE_D | Cantidad confirmada |
| `get_requested_qty` | MENGE_D | Cantidad solicitada |
| `is_fully_confirmed` | ABAP_BOOL | confirmed >= requested |
| `is_partially_confirmed` | ABAP_BOOL | 0 < confirmed < requested |
| `is_not_available` | ABAP_BOOL | confirmed = 0 |
| `get_shortage_qty` | MENGE_D | requested - confirmed (mín 0) |
| `get_confirmation_rate` | P (packed) | (confirmed / requested) * 100 |
| `get_response` | ZSSD_ATP_RESPONSE | Estructura completa |

**Evaluación:** Clase bien diseñada, sigue SRP. Es un Value Object puro sin dependencias externas. Útil para lógica de presentación y decisiones de negocio downstream.

---

### 3.3 ZCL_SD_ATP_SIMULATOR — Simulación de Pedidos

**Responsabilidad:** Simula disponibilidad ATP para múltiples ítems y busca plantas alternativas.

| Método | Descripción |
|--------|-------------|
| `simulate_order` | Itera ítems y verifica ATP por cada uno |
| `simulate_single_item` | Verificación ATP de un ítem individual |
| `get_alternative_plants` | Busca plantas donde el material tiene stock |
| `get_messages` | Mensajes propios + mensajes del handler |

**Lógica de plantas alternativas:**
1. SELECT a tabla `MARC` para encontrar plantas donde el material existe (no marcado para borrado)
2. Para cada planta, ejecuta `check_plant_availability`
3. Filtra solo plantas con cantidad confirmada > 0
4. Ordena por cantidad confirmada descendente

**Dependencias:**
- `ZCL_SD_ATP_HANDLER` — instanciado directamente en constructor (acoplamiento fuerte)
- `ZCL_SD_MESSENGER` — instanciado directamente

---

### 3.4 ZCL_SD_ATP_CACHE — Caché en Memoria

**Responsabilidad:** Caché de resultados ATP con TTL configurable (default 300 segundos = 5 minutos).

| Método | Descripción |
|--------|-------------|
| `get_cached_result` | Busca resultado por clave compuesta (material+planta+cantidad+unidad) |
| `set_cached_result` | Almacena resultado con timestamp |
| `clear_cache` | Limpia toda la caché |
| `invalidate` | Invalida por material y/o planta (selectivo) |
| `get_cache_size` | Número de entradas en caché |

**Implementación técnica:**
- Tabla interna HASHED con clave `cache_key` (string concatenado)
- TTL basado en `CL_ABAP_TSTMP=>subtract`
- Método `cleanup_expired` para limpieza de entradas vencidas (no se llama automáticamente)

---

## 4. Análisis de Calidad y Hallazgos

### 4.1 Cumplimiento de Estándares Holcim BP

| Estándar | Estado | Detalle |
|----------|:------:|---------|
| Nomenclatura ZCL_ / ZIF_ | ✅ | Clases usan ZCL_SD_ATP_*, interfaz ZIF_SD_ATP_CHECK |
| Variables mo_, mv_, mt_ | ✅ | Consistente en todas las clases |
| Parámetros iv_, ev_, it_, et_ | ✅ | Consistente |
| Variables locales lv_, lt_, ls_, lo_ | ✅ | Consistente |
| No SELECT * | ✅ | SELECT DISTINCT werks (campos explícitos) |
| No SELECT en LOOP | ⚠️ | `find_alternative_plants` hace SELECT fuera del LOOP, pero `check_plant_availability` dentro del LOOP llama BAPI (aceptable para ATP) |
| Sintaxis moderna ABAP | ✅ | Usa VALUE, COND, xsdbool, inline declarations |
| ABAP Doc en métodos públicos | ❌ | Ningún método tiene documentación "! |
| Clase de test _TEST | ❌ | No existe ZCL_SD_ATP_HANDLER_TEST ni similar |
| Manejo de excepciones | ⚠️ | Solo TRY/CATCH en constructor para config, BAPI no tiene manejo de excepciones explícito |
| COMMIT WORK en lógica de negocio | ⚠️ | `log_atp_check` hace INSERT directo sin COMMIT, pero tampoco hay control superior visible |
| Tablas con TYPE TABLE OF | ✅ | Declaraciones correctas |

### 4.2 Cumplimiento SOLID

| Principio | Estado | Detalle |
|-----------|:------:|---------|
| SRP (Single Responsibility) | ⚠️ | ZCL_SD_ATP_HANDLER tiene múltiples responsabilidades: orquestación, llamada BAPI, mapping, caché, logging, reglas de negocio |
| OCP (Open/Closed) | ⚠️ | Las reglas de negocio están hardcodeadas en `apply_business_rules`. No hay Strategy pattern |
| LSP (Liskov Substitution) | ✅ | ZIF_SD_ATP_CHECK permite sustitución |
| ISP (Interface Segregation) | ✅ | Interfaz con un solo método `execute_check` |
| DIP (Dependency Inversion) | ❌ | Las 3 dependencias (messenger, cache, config) se instancian con CREATE OBJECT directo. No hay inyección de dependencias |

### 4.3 Hallazgos Críticos

#### 🔴 CRÍTICO — Objetos DDIC no existen
Las tablas `ZSDT_ATP_CONFIG`, `ZSDT_ATP_LOG`, `ZSDT_ATP_RESULTS`, las estructuras `ZSSD_ATP_REQUEST`, `ZSSD_ATP_RESPONSE`, `ZSSD_ATP_ITEM`, los elementos de datos y el dominio no fueron encontrados en el sistema BZD. Esto significa:
- Las clases que referencian estos tipos **no pueden compilar** sin ellos
- Es posible que estén en un transporte pendiente o en otro sistema
- Se requiere verificar con JuanDa el estado de estos objetos DDIC

#### 🔴 CRÍTICO — Function Modules y grupo de funciones no existen
`ZFG_SD_ATP`, `ZFM_SD_ATP_CHECK`, `ZFM_SD_ATP_SIMULATION`, `ZFM_SD_ATP_BATCH_CHECK` no existen. La capa de consumo RFC/FM está pendiente.

#### 🟡 IMPORTANTE — Sin tests unitarios
No existe clase de test para ninguno de los 4 objetos. Esto viola el estándar obligatorio de Holcim BP.

#### 🟡 IMPORTANTE — Acoplamiento fuerte (violación DIP)
```abap
" En ZCL_SD_ATP_HANDLER constructor:
CREATE OBJECT mo_messenger.        " ← acoplamiento directo
CREATE OBJECT mo_cache.            " ← acoplamiento directo
CREATE OBJECT mo_config ...        " ← acoplamiento directo

" En ZCL_SD_ATP_SIMULATOR constructor:
CREATE OBJECT mo_handler ...       " ← acoplamiento directo
CREATE OBJECT mo_messenger.        " ← acoplamiento directo
```
Esto impide inyectar test doubles y dificulta las pruebas unitarias.

#### 🟡 IMPORTANTE — Sin ABAP Doc
Ningún método público tiene documentación `"!`. Estándar obligatorio.

#### 🟢 MENOR — Caché sin limpieza automática
`cleanup_expired` existe pero nunca se invoca automáticamente. Las entradas expiradas se filtran en lectura pero permanecen en memoria.

#### 🟢 MENOR — INSERT directo en log_atp_check
```abap
INSERT zsdt_atp_log FROM ls_log.
```
Sin manejo de error si el INSERT falla (duplicado de UUID, tabla llena, etc.).

---

## 5. Mapa de Dependencias entre Objetos

```
ZCL_SD_ATP_SIMULATOR
  └── ZCL_SD_ATP_HANDLER (CREATE OBJECT directo)
        ├── ZCL_SD_MESSENGER (CREATE OBJECT directo)
        ├── ZCL_SD_ATP_CACHE (CREATE OBJECT directo)
        ├── ZCL_SD_ATP_CONFIG (CREATE OBJECT directo, opcional)
        ├── implements ZIF_SD_ATP_CHECK
        ├── usa BAPI_MATERIAL_AVAILABILITY (SAP estándar)
        ├── lee/escribe ZSDT_ATP_LOG (tabla Z — no existe aún)
        └── usa tipos: ZSSD_ATP_REQUEST, ZSSD_ATP_RESPONSE (no existen aún)

ZCL_SD_ATP_RESULT
  └── Sin dependencias externas (Value Object puro)

ZCL_SD_ATP_CACHE
  └── CL_ABAP_TSTMP (clase SAP estándar)
```

---

## 6. Recomendaciones de Mejora

### 6.1 Prioridad Alta — Crear objetos DDIC faltantes
Antes de que el código pueda activarse, se necesitan:
1. Dominio `ZDO_SD_ATP_STATUS` con valores: C (Confirmed), P (Partial), N (Not available), R (Rejected), B (Blocked)
2. Elementos de datos `ZDE_SD_ATP_STATUS`, `ZDE_SD_ATP_QTY`
3. Estructuras `ZSSD_ATP_REQUEST`, `ZSSD_ATP_RESPONSE`, `ZSSD_ATP_ITEM`
4. Tablas `ZSDT_ATP_CONFIG`, `ZSDT_ATP_LOG`, `ZSDT_ATP_RESULTS`
5. Tipos tabla `ZSSD_ATP_REQUEST_T`, `ZSSD_ATP_RESPONSE_T`, `ZSSD_ATP_ITEM_T`, `ZSSD_ATP_PLANT_T`

### 6.2 Prioridad Alta — Aplicar Dependency Inversion
Refactorizar ZCL_SD_ATP_HANDLER para recibir dependencias por constructor:

```abap
METHODS constructor
  IMPORTING
    iv_vkorg     TYPE vkorg
    iv_vtweg     TYPE vtweg
    iv_spart     TYPE spart
    iv_werks     TYPE werks_d     OPTIONAL
    iv_lgort     TYPE lgort_d     OPTIONAL
    io_cache     TYPE REF TO zif_sd_atp_cache     OPTIONAL  " ← interfaz
    io_messenger TYPE REF TO zif_sd_messenger     OPTIONAL  " ← interfaz
    io_config    TYPE REF TO zif_sd_atp_config    OPTIONAL. " ← interfaz
```

Crear interfaces: `ZIF_SD_ATP_CACHE`, `ZIF_SD_MESSENGER`, `ZIF_SD_ATP_CONFIG`.

### 6.3 Prioridad Alta — Crear tests unitarios
Clase `ZCL_SD_ATP_HANDLER_TEST` con al menos:
- Test de check_availability con resultado completo (status C)
- Test de check_availability con resultado parcial (status P)
- Test de check_availability sin disponibilidad (status N)
- Test de apply_business_rules con cantidad mínima
- Test de apply_business_rules con bloqueo de crédito
- Test de caché (hit y miss)

### 6.4 Prioridad Media — Extraer responsabilidades de ZCL_SD_ATP_HANDLER
Siguiendo SRP, considerar extraer:
- `ZCL_SD_ATP_BAPI_MAPPER` — mapping request/response ↔ BAPI
- `ZCL_SD_ATP_RULES_ENGINE` — reglas de negocio (con Strategy pattern para extensibilidad)
- `ZCL_SD_ATP_LOGGER` — logging a tabla Z

### 6.5 Prioridad Media — Agregar ABAP Doc
```abap
"! Verifica disponibilidad ATP para un material en una planta
"! @parameter is_request | Solicitud ATP con material, planta, cantidad y unidad
"! @parameter rs_response | Respuesta con cantidad confirmada y status
METHOD check_availability.
```

### 6.6 Prioridad Baja — Mejoras menores
- Invocar `cleanup_expired` periódicamente en `get_cached_result` o `set_cached_result`
- Agregar manejo de error en `log_atp_check` (TRY/CATCH o verificar SY-SUBRC)
- Considerar hacer `check_availability_multi` con FOR ALL ENTRIES en lugar de LOOP individual (optimización de performance para lotes grandes)

---

## 7. Valores de Status ATP

| Código | Significado | Origen |
|:------:|-------------|--------|
| C | Confirmed — cantidad completa disponible | `call_atp_bapi` |
| P | Partial — disponibilidad parcial | `call_atp_bapi` |
| N | Not available — sin disponibilidad | `call_atp_bapi` |
| R | Rejected — por debajo de cantidad mínima | `apply_business_rules` |
| B | Blocked — bloqueo de crédito o entrega | `apply_business_rules` |

---

## 8. Conclusión

El componente ATP tiene una arquitectura OO razonable con buena separación entre handler, simulador, caché y value object. Sin embargo, tiene gaps importantes que impiden su uso productivo:

1. Los objetos DDIC (tablas, estructuras, elementos de datos) no existen en BZD — sin ellos el código no compila
2. No hay tests unitarios (violación de estándar obligatorio)
3. El acoplamiento directo entre clases impide testabilidad y viola DIP
4. Falta la capa de Function Modules para consumo RFC

La recomendación es priorizar la creación de objetos DDIC, luego aplicar inyección de dependencias, y finalmente crear los tests unitarios antes de mover a productivo.

---

*Documento generado el 19 de marzo de 2026 — Análisis basado en código fuente extraído de SAP BZD 130 vía ADT*
