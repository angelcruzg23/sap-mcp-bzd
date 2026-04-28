# Bitácora de Sesiones con Kiro
## Registro de interacciones, problemas resueltos y lecciones aprendidas

---

## Sesión 1 — 21 de Abril 2026
### Tema: Debugging del Daily Invoice Report (ZSDR_DAILY_INVOICE_REPORT)

#### Problema reportado
Un usuario final reportó que recibe correctamente los correos de factura en su bandeja, y en SOST aparecen como "Transmitted". Sin embargo, el reporte Z (transacción ZSD_DAILY_INVOICE) muestra esas facturas con semáforo rojo (Failed).

#### Cómo Kiro ayudó a encontrar el error

1. **Lectura del programa principal:** Kiro leyó el código fuente de `ZSDR_DAILY_INVOICE_REPORT` desde SAP BZD vía MCP y detectó que usa 4 includes.

2. **Obstáculo técnico:** El MCP Server no podía leer includes individuales — solo programas tipo PROG. El endpoint ADT para includes es diferente (`/sap/bc/adt/programs/includes/` vs `/sap/bc/adt/programs/programs/`).

3. **Evolución del MCP Server en vivo:** En lugar de un workaround manual, se le pidió a Kiro que modificara el `sap_client.py` y `server.py` para agregar la herramienta `sap_get_include_source`. Se reinició el MCP y se continuó trabajando. Tiempo: ~3 minutos.

4. **Lectura de los 4 includes en paralelo:** Con la nueva herramienta, Kiro leyó TOP, SCR, C01 y F01 simultáneamente.

5. **Simulación del flujo de datos:** Se le pidió a Kiro que simulara paso a paso el FORM `f_get_data` para encontrar dónde se pierde la correlación entre SOST y el reporte. Kiro identificó dos problemas potenciales y señaló la línea exacta del bug.

#### Cómo le indiqué qué hacer

- Le pedí que leyera el programa desde SAP → encontró el obstáculo de los includes.
- Le pregunté cómo resolver el tema de los includes → propuso 3 opciones, elegí la opción 1 (mejorar el MCP).
- Le pedí que implementara el cambio en el MCP → lo hizo y me pidió reiniciar.
- Le pedí que simulara el flujo para encontrar el bug → identificó 2 problemas.
- Confirmé que el Problema 2 era la causa raíz.
- Le pedí un informe en markdown con el código que falla y una solución basada en switch TVARVC.
- Le pedí la versión en inglés.
- Le pedí que implementara el fix en el include F01 pero solo localmente, sin subir a SAP.
- Le pedí que agregara el ejercicio al workshop.

#### Propuesta de solución

Switch por fecha usando TVARVC (`ZSD_DAILY_INV_EHP8_DATE`):
- Antes de la fecha de corte: comportamiento original (ejecuta el DELETE)
- Después de la fecha de corte: omite el DELETE para no eliminar documentos transmitidos
- Si la variable no existe: fallback seguro, mantiene comportamiento original

#### Entregables generados
| Archivo | Descripción |
|---------|-------------|
| `ZSDR_DAILY_INVOICE_REPORT/ANALISIS_BUG_SCOMNO.md` | Informe de análisis en español |
| `ZSDR_DAILY_INVOICE_REPORT/BUG_ANALYSIS_SCOMNO.md` | Informe de análisis en inglés |
| `ZSDR_DAILY_INVOICE_REPORT/ZSDR_DAILY_INVOICE_REPORT_F01.abap` | Include F01 con el fix aplicado |
| `MD/WORKSHOP_KIRO_ABAP_PRODUCTIVITY.md` | Workshop actualizado con el ejercicio |

#### Lecciones aprendidas

1. **Kiro puede hacer debugging estático efectivo** — simulando el flujo de datos con el código fuente, sin necesidad de ejecutar el programa ni usar el debugger de SAP.

2. **El MCP Server es extensible en tiempo real** — cuando faltó la capacidad de leer includes, se agregó en minutos sin interrumpir la sesión de trabajo. Esto demuestra que el MCP es un asset vivo que crece con las necesidades.

3. **El contexto humano sigue siendo indispensable** — Kiro no sabía que el EHP8 cambió el comportamiento de SAPconnect respecto al `SCOMNO`. El desarrollador aportó ese contexto y Kiro lo integró en la solución. La combinación humano + AI es más poderosa que cualquiera por separado.

4. **El patrón TVARVC como switch es reutilizable** — proteger comportamiento legacy con una fecha de corte configurable es un patrón que aplica a muchos escenarios post-upgrade.

5. **La documentación bilingüe es trivial con Kiro** — generar el mismo informe en español e inglés tomó segundos. Esto es valioso en equipos multinacionales como Holcim.

6. **Pedir "no subas a SAP" es un control válido** — el desarrollador mantiene el control total de qué se sube y cuándo. Kiro genera, el humano decide.

#### Tiempo invertido
| Actividad | Estimado manual | Con Kiro |
|-----------|----------------|----------|
| Leer programa + includes | 15-20 min | 1 min |
| Mejorar MCP Server | N/A | 3 min |
| Encontrar causa raíz | 1-2 horas | 5 min |
| Generar informes (ES + EN) | 45-60 min | 3 min |
| Generar código con fix | 20-30 min | 2 min |
| Actualizar workshop | 20-30 min | 3 min |
| **Total** | **~3.5 horas** | **~17 minutos** |

---

## Sesiones anteriores (resumen)

### POC Job Chaining
- **Problema:** Necesidad de lanzar un Job B automáticamente cuando termina un Job A.
- **Solución:** Programa `ZR_SD_JOB_CHAIN_POC` usando `JOB_OPEN` / `SUBMIT VIA JOB` / `JOB_CLOSE` con `PRED_JOBNAME`.
- **Obstáculo:** Primer intento falló con `invalid_startdate` (SY-SUBRC = 2) porque `JOB_CLOSE` necesita `SDLSTRTDT`/`SDLSTRTTM` como fallback incluso con predecesor.
- **Fix:** Se agregaron los parámetros de fecha/hora y funcionó correctamente.
- **Lección:** SAP requiere fecha de inicio como fallback en job chaining — no está documentado de forma obvia.

### Reporte ALV de Clientes (ZR_REPORTE_CLIENTES)
- **Problema:** Crear un reporte rápido de datos maestros de clientes.
- **Solución:** Programa con SELECT de 10 campos principales de KNA1, ALV con `CL_SALV_TABLE`, filtro por código de cliente.
- **Lección:** Para reportes simples, Kiro genera código funcional y activado en SAP en menos de 2 minutos.

---

*Este documento se actualiza automáticamente con cada sesión de trabajo con Kiro.*
*Última actualización: 21 de Abril 2026*