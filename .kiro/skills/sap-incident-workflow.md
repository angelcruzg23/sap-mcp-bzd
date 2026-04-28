---
inclusion: manual
---
# SAP Incident & Bug Analysis Workflow

## Última actualización: 2026-04-27

---

## Flujo estándar de análisis de incidentes

### Fase 1: Entender el problema
1. Leer el ticket/incidente (descripción del usuario, screenshots, datos de ejemplo)
2. Identificar el programa/transacción afectada
3. Identificar el síntoma vs la causa (el usuario reporta el síntoma, no la causa)

### Fase 2: Localizar el código
1. `sap_search_objects` para encontrar objetos relacionados (Z*, Y*)
2. `sap_get_program_source` / `sap_get_include_source` para leer el código
3. Identificar el FORM/METHOD/FM donde ocurre el problema
4. Si hay includes, leer todos (_TOP, _F01, _F02, _SCR, _C01)

### Fase 3: Análisis de causa raíz
1. Trazar el flujo de datos desde la entrada hasta el punto de fallo
2. Verificar si el problema es de código, configuración, o datos
3. Si es post-EHP8: verificar si el comportamiento cambió con el upgrade
4. Documentar la causa raíz con diagrama de flujo del error

### Fase 4: Proponer solución
1. Diseñar la solución mínima que resuelve el problema
2. Evaluar impacto en otros flujos que usan el mismo código
3. Documentar en formato ANALISIS_*.md o TD_*.md
4. Incluir: código actual (AS-IS), código propuesto (TO-BE), escenarios de prueba

### Fase 5: Implementar (si aplica)
1. Seguir el flujo de deploy: leer baseline → generar diff → confirmar → subir → activar → verificar
2. Un objeto a la vez
3. Search term del CR en todo código modificado

---

## Patrones de causa raíz recurrentes en Amrize BP

### Patrón A: Cambio de comportamiento post-EHP8
- **Señal**: "Esto funcionaba antes" / "Empezó después del upgrade"
- **Investigar**: Qué FMs estándar se llaman y si su comportamiento cambió
- **Solución típica**: Switch por fecha con TVARVC, o authority check preventivo
- **Ejemplos**: SCOMNO en ZSDR_DAILY_INVOICE_REPORT, M_MTDI_ORG en ZSDR_ANOKA_REPORT_BAK_N

### Patrón B: Lock contention en workflows
- **Señal**: Error intermitente en BAPI de cambio, "document locked by user X"
- **Investigar**: ¿Se hace ENQUEUE antes de la BAPI? ¿Hay procesos concurrentes?
- **Solución típica**: ENQUEUE con reintentos antes de la BAPI, DEQUEUE en ambos caminos
- **Ejemplo**: CHG0436393 — ZSD_PPD_REJ_UPDATE

### Patrón C: Overflow/tipo de datos en configuración
- **Señal**: ARITHMETIC_ERRORS, TYPE_CONVERSION_ERROR en código estándar
- **Investigar**: Longitud/tipo del campo en DDIC o CT04 vs el valor real
- **Solución típica**: Ampliar longitud en configuración (no modificar código estándar)
- **Ejemplo**: ZZPLPOD_UMREZ en clasificación (5 dígitos vs valor 150,000)

### Patrón D: Middleware CRM con capas Z ocultas
- **Señal**: BDoc en status F0x, errores en CRM_ORDER_MAINTAIN
- **Investigar**: Cadena completa de FMs (puede haber 4+ capas Z)
- **Solución típica**: Depende del hallazgo — puede ser flag stuck, mapping incorrecto, o desalineamiento de SP
- **Ejemplo**: Flujo ECC→CRM BTMBDOC

### Patrón E: Bloque IF sy-subrc vacío
- **Señal**: Mensaje de error aparece en status bar sin contexto
- **Investigar**: Buscar `IF sy-subrc <> 0` con bloque vacío después de CALL FUNCTION
- **Solución típica**: Manejar el error explícitamente (CONTINUE, mensaje, o log)
- **Ejemplo**: MD_STOCK_REQUIREMENTS_LIST_API en ZSDR_ANOKA_REPORT_BAK_N

---

## Checklist de documentación de incidentes

```markdown
# Análisis de Bug — [PROGRAMA]
## [Título descriptivo del problema]

| Campo | Valor |
|-------|-------|
| Programa | |
| Transacción | |
| Include/FM afectado | |
| Severidad | Alta/Media/Baja |

## 1. Descripción del problema
[Qué reporta el usuario]

## 2. Causa raíz identificada
[Análisis técnico con código relevante]

## 3. Contexto (si aplica EHP8)
[Qué cambió con el upgrade]

## 4. Solución propuesta
[Código AS-IS vs TO-BE]

## 5. Escenarios de prueba
[Tabla con escenarios y resultados esperados]

## 6. Riesgo y mitigación
[Tabla de riesgos]
```
