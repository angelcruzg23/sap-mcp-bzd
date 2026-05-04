# Script: Workshop Kiro + SAP — Edición AMRIZE
## Guía del presentador — Para leer, practicar y seguir en vivo

---

## Antes de empezar

- Duración: ~60 minutos (45 min presentación + 15 min preguntas)
- `[ACCIÓN]` = algo que haces en pantalla
- `[PAUSA]` = momento para preguntar si hay dudas
- `[SLIDE]` = referencia a la sección del documento WORKSHOP_KIRO_SAP_AMRIZE.md
- Tono: conversacional, como explicándole a un compañero
- Tener SAP GUI abierto como respaldo por si la demo en vivo falla
- Tener el documento AMRIZE abierto para las tablas de referencia

---

## PARTE 1 — El problema que todos conocemos (5 min)

---

Déjenme arrancar con una pregunta. ¿Cuántas horas a la semana se les van en esto?

- Leyendo documentos funcionales tratando de encontrar los requerimientos técnicos reales
- Navegando SE37, SE38, SE80 buscando objetos
- Leyendo código de otro tratando de entender qué hace
- Escribiendo código que sigue el mismo patrón de las 50 líneas de arriba
- Documentando lo que hicieron después de haberlo hecho

Si son honestos, probablemente es el 60-70% de la semana. El pensamiento real — las decisiones de diseño, los casos borde, el "¿esto rompe algo?" — eso es quizás el 30%.

¿Qué tal si pudiéramos invertir esa proporción?

Eso es lo que hemos estado haciendo las últimas semanas con Kiro. Y hoy les voy a mostrar exactamente cómo, con casos reales de nuestro sistema.

---

## PARTE 2 — Qué es Kiro, en 3 minutos (3 min)

---

`[SLIDE: Diagrama de arquitectura del documento AMRIZE]`

Cinco cosas que necesitan saber:

1. **Kiro es un IDE** — se ve como VS Code, lo hizo Amazon, tiene un agente de IA integrado
2. **La IA es Claude** — de Anthropic. No es ChatGPT, pero el concepto es el mismo: predice código basándose en patrones de millones de programas
3. **MCP es el puente** — un servidor pequeño en Python que construimos y que traduce las peticiones de Kiro a llamadas de la API ADT de SAP. Así es como Kiro lee y escribe ABAP en BZD
4. **Los steering files son las reglas** — 4 archivos markdown que le dicen a Kiro nuestras convenciones de nombres, estándares de código y patrones SOLID. Por eso el código se ve como el nuestro, no genérico
5. **El desarrollador siempre tiene el control** — Kiro propone, ustedes deciden. Nada llega a SAP sin su revisión

`[PAUSA — ¿Alguna pregunta sobre la configuración antes de verlo en acción?]`

---

## PARTE 3 — Los 4 casos (35 min)

---

Les voy a mostrar 4 casos reales. No son demos armadas para una presentación — pasaron este mes, en tickets reales, en BZD 130.

`[SLIDE: Tabla de tiempos del documento AMRIZE]`

Les doy el resumen de una vez:

| Caso | Manual | Con Kiro |
|------|--------|----------|
| Desarrollo nuevo | ~2 horas | ~6 min |
| Debugging de reporte productivo | ~3 horas | ~13 min |
| Deploy de FM con 3 iteraciones | ~4 horas | ~19 min |
| Investigación de autorización | ~3-4 horas | ~6 min |
| **Total** | **~12-13 horas** | **~44 min** |

Ahora les muestro cómo.

---

### Caso 1 — Desarrollo nuevo desde un Functional Design (8 min)
#### CHG0432318: Tipo de equipo Conestoga

`[ACCIÓN: Abrir el archivo .mht en la carpeta ConestogaChange — mostrar lo feo que se ve]`

Este es un Functional Design en formato .mht. Es básicamente un Word guardado como archivo web — lleno de basura HTML. Leer esto manualmente toma 30-45 minutos.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Analiza el requerimiento en la carpeta ConestogaChange. Dime qué entendiste.
```

`[ESPERAR — Kiro lee el documento y devuelve un resumen estructurado]`

Miren lo que hizo:
- Extrajo el requerimiento de negocio del ruido HTML
- Identificó los 5 pasos técnicos
- Listó los objetos SAP involucrados
- Resumió los escenarios de prueba

Dos minutos. Ahora busquemos el código.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Busca los Function Modules ZSDE_GET_DATA_SHPMNT_HD_TAB y 
ZSDE_SET_DATA_SHPMNT_HD_TAB en SAP BZD
```

`[ESPERAR — Kiro busca en SAP, descubre que son FMs en un function group, trae el fuente]`

Fíjense: Kiro primero intentó buscarlos como programas — falló. Entonces buscó por patrón, descubrió el function group y obtuvo el código fuente. Es el mismo proceso de descubrimiento que hacemos en SE80, pero en segundos.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Genera los cambios ABAP para el nuevo campo ZZEQUIPE_TYPE en LIKP. 
Modifica los FMs GET y SET, y agrega la lógica en el enhancement 
para que solo actualice cuando TMS envíe 'ZZ' (Conestoga).
```

`[ESPERAR — Kiro genera 4 archivos]`

`[ACCIÓN: Abrir cada archivo generado y señalar:]`
- Mismo estilo de comentarios con search terms
- Mismo patrón de nombres de variables (gv_*)
- Misma alineación que el código existente
- La lógica condicional usa una constante, no un valor hardcodeado

Eso son los steering files trabajando. Sin ellos, código válido pero genérico. Con ellos, código que parece escrito por alguien del equipo.

`[PAUSA — ¿Preguntas sobre este caso?]`

---

### Caso 2 — Debugging sin abrir SAP (8 min)
#### ZSDR_DAILY_INVOICE_REPORT — Bug del SCOMNO

`[ACCIÓN: Describir brevemente el escenario]`

Un usuario recibe los correos con las facturas — SOST las muestra como "Transmitted". Pero el reporte diario de facturas las muestra con semáforo rojo: Failed. El equipo funcional no encuentra por qué.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Lee el programa ZSDR_DAILY_INVOICE_REPORT de SAP BZD y analiza 
dónde la lógica del semáforo podría estar marcando facturas 
transmitidas como fallidas.
```

`[ESPERAR — Kiro lee el programa, descubre 4 includes, los lee todos en paralelo]`

Esto es lo que Kiro encontró. En lo profundo del form de procesamiento de datos, hay esta línea:

```abap
DELETE ltt_sood WHERE NOT scomno IS INITIAL.
```

Antes del EHP8, SAPconnect no asignaba el `SCOMNO` hasta después. Después del EHP8, lo asigna inmediatamente al transmitir. Entonces esta línea ahora borra exactamente los documentos que SÍ fueron enviados exitosamente.

El código posterior no encuentra match, cae en el ELSE, y marca la factura como Failed.

`[ACCIÓN: Mostrar el fix — switch por fecha con TVARVC]`

Kiro propuso un switch basado en fecha usando TVARVC — para no romper el comportamiento pre-EHP8. Limpio, seguro, reversible.

Lo clave acá: **Kiro hizo debugging estático**. Nunca ejecutó el programa. Simuló el flujo de datos a través del código fuente y encontró la causa raíz. Eso es algo que nos tomaría 1-2 horas de rastreo manual.

`[PAUSA — ¿Preguntas?]`

---

### Caso 3 — Deploy en vivo a SAP, 3 iteraciones (10 min)
#### CHG0436393: Enqueue lock para ZSD_PPD_REJ_UPDATE

`[ACCIÓN: Describir el escenario brevemente]`

Un Function Module llama a `BAPI_CUSTOMERQUOTATION_CHANGE` sin verificar si la quotation está bloqueada. Si alguien la tiene abierta en VA22, la BAPI puede fallar silenciosamente.

`[ACCIÓN: Mostrar el análisis que Kiro produjo — el AS-IS vs TO-BE]`

Kiro leyó la FM, identificó los dos caminos de ejecución (CPQ y Workflow), y generó la lógica de enqueue/dequeue con un loop de reintentos.

Pero acá se pone interesante. Cuando intentamos subir el código a SAP, el servidor MCP no podía escribir Function Modules — solo soportaba programas.

`[ACCIÓN: Explicar qué pasó después]`

Entonces le agregamos esa capacidad. En 5 minutos. Un método nuevo en el servidor Python, un registro de herramienta nuevo, reinicio, listo. El servidor MCP es un activo vivo — crece con cada caso real.

Después hicimos deploy. Y probamos. Y el loop de reintentos tenía un bug — el `DO...ENDDO` con `EXIT` no se comportaba correctamente en el call stack del workflow.

`[ACCIÓN: Mostrar el screenshot del debugger si está disponible]`

El desarrollador compartió un screenshot del debugger ABAP. Kiro miró la imagen, correlacionó los valores de las variables con el código, y propuso el fix: reemplazar `DO...ENDDO` por `WHILE` con una condición de salida explícita.

Segundo deploy. Después un tercero — agregando `MESSAGE TYPE 'E'` para que el paso del workflow quede en estado ERROR y se pueda reiniciar desde SWPR.

Tres ciclos completos de código → deploy → prueba → fix → redeploy. En una sola sesión. Sin abrir Eclipse.

`[PAUSA — ¿Preguntas sobre el proceso de deploy?]`

---

### Caso 4 — Investigación de autorización (9 min)
#### ZSDR_ANOKA_REPORT_BAK_N — "No authorization for W56LE601004 in plant 3096"

`[ACCIÓN: Mostrar el screenshot del error en SAP GUI en la barra de estado]`

Esto pasó esta semana. Un usuario ejecuta ZSD_ORDER_TRACKING1, le sale este error en la barra de estado, y el reporte no muestra nada. Nadie sabe de dónde viene.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Analiza el programa ZSDR_ANOKA_REPORT_BAK_N para encontrar dónde se 
dispara el error de autorización "No authorization for W56LE601004 
in plant 3096". El mensaje aparece durante el procesamiento de datos, 
no al hacer clic en el ALV.
```

`[ESPERAR — Kiro lee el programa principal, descubre 3 includes, los lee todos]`

2,500 líneas de ABAP en 3 includes. Kiro leyó todo en segundos y encontró:

- 3 chequeos de autorización explícitos en el código — **ninguno genera este mensaje**
- El verdadero culpable: `MD_STOCK_REQUIREMENTS_LIST_API` — una FM estándar de SAP que hace su propio authority check interno sobre el objeto `M_MTDI_ORG`
- El programa llama esta FM dentro de un loop y tiene un manejador de error vacío:

```abap
IF sy-subrc <> 0.
  " ← Nada acá. El error se filtra a la barra de estado.
ENDIF.
```

Esto empezó a pasar con el EHP8 — la FM tiene chequeos de autorización más estrictos ahora.

`[ACCIÓN: Mostrar el fix propuesto — 9 líneas]`

El fix es elegante: replicar el mismo chequeo de autorización que la FM hace internamente, pero ANTES de llamarla. Si el usuario no tiene autorización para esa planta, se salta el registro silenciosamente.

```abap
AUTHORITY-CHECK OBJECT 'M_MTDI_ORG'
  ID 'MDAKT' FIELD 'A'
  ID 'WERKS' FIELD wa_vbap-werks
  ID 'DISPO' DUMMY.
IF sy-subrc NE 0.
  CLEAR ls_mdps.
  CONTINUE.
ENDIF.
```

9 líneas. Ningún otro cambio. El reporte funciona, las plantas sin autorización se excluyen silenciosamente, sin mensajes de error.

Después Kiro generó el informe técnico completo en inglés — causa raíz, ubicación en el código, comportamiento antes vs. después, análisis de impacto. Listo para adjuntar al ticket.

`[PAUSA — ¿Preguntas sobre este caso?]`

---

## PARTE 4 — Qué cambia para nosotros (7 min)

---

`[SLIDE: Tabla "Kiro does vs. You do" del documento AMRIZE]`

Quiero ser claro sobre qué es esto y qué no es.

**Kiro comprime el trabajo mecánico.** La lectura, la búsqueda, el reconocimiento de patrones, el tipeo, la documentación — eso pasa de horas a minutos.

**Kiro NO reemplaza su criterio.** Las decisiones de diseño, el "¿esto rompe algo?", las pruebas, el transporte a producción — eso sigue siendo 100% de ustedes.

El rol cambia:

| Antes | Ahora |
|-------|-------|
| Lector de documentos | Validador de análisis |
| Buscador de objetos | Revisor de propuestas |
| Escritor de código | Arquitecto de soluciones |
| Documentador manual | Curador de documentación |

El valor ya no está en qué tan rápido tipean. Está en su criterio técnico, en su conocimiento del negocio, en su capacidad de decir "esto está bien" o "esto no va a funcionar porque..."

### Las reglas

`[SLIDE: "Rules for working with AI in SAP" del documento AMRIZE]`

Diez reglas. Las tres más importantes:

1. **Siempre crear la orden de transporte manualmente** — darle el número a Kiro. Nunca dejar que Kiro cree OTs en sistemas con CTS Project Management.
2. **Siempre revisar el diff antes de subir** — leer el código actual de SAP, comparar con lo que Kiro propone, y después subir.
3. **El desarrollador siempre es el responsable** — Kiro es una herramienta. Ustedes firman el código que va a SAP.

`[SLIDE: Diagrama de flujo controlado de deploy del documento AMRIZE]`

---

## PARTE 5 — Qué necesitan para arrancar (5 min)

---

Para usar esto en su día a día necesitan:

1. **Kiro instalado** — hay un tier gratuito en kiro.dev, se ve como VS Code
2. **Servidor MCP configurado** — servidor Python que se conecta a SAP vía ADT. Hay guía de instalación (15 min de setup)
3. **Acceso VPN a SAP** — el mismo que usan para Eclipse ADT
4. **Steering files** — les vamos a compartir los 4 archivos que codifican nuestros estándares

Mi sugerencia: instálenlo esta semana. Empiecen simple — buscar un objeto, leer un programa que ya conozcan. Agarren confianza. Después pruébenlo en un ticket real.

---

## PARTE 6 — Preguntas (15 min)

---

`[ACCIÓN: Abrir espacio para preguntas. Tener estas listas:]`

**"¿Kiro puede ver datos de producción?"**
No. Usa ADT — la misma API que Eclipse. Solo puede hacer lo que su usuario SAP tenga autorizado.

**"¿El código generado es seguro?"**
Tan seguro como el que escribirían ustedes. Los steering files imponen estándares, pero la revisión final es de ustedes.

**"¿Esto funciona con S/4HANA?"**
Sí. La API REST de ADT funciona igual. Solo hay que actualizar los steering files para permitir sintaxis de ABAP Cloud si aplica.

**"¿Qué pasa si Kiro genera código incorrecto?"**
Pasa. Por eso el flujo siempre incluye revisión humana. Si es un patrón que se repite, se actualizan los steering files.

**"¿Puedo conectar Kiro a otros sistemas?"**
Sí. MCP es un protocolo abierto. Se pueden construir servidores para cualquier sistema que tenga una API.

**"¿Cuánto cuesta?"**
Kiro tiene un tier gratuito con límites de uso y un tier de pago. Detalles en kiro.dev.

**"¿Kiro puede interpretar screenshots del debugger?"**
Sí — lo demostramos en el Caso 3. Se comparte la imagen en el chat y Kiro correlaciona los valores de las variables con el código.

---

## Checklist del presentador

- [ ] Kiro abierto con el workspace del proyecto
- [ ] Servidor MCP conectado (hacer un ping de prueba)
- [ ] VPN conectada a SAP BZD
- [ ] Carpeta ConestogaChange con el archivo .mht
- [ ] Screenshot del error de autorización (Caso 4)
- [ ] WORKSHOP_KIRO_SAP_AMRIZE.md abierto para tablas de referencia
- [ ] ZSDR_ANOKA_REPORT_BAK_N/ANALYSIS_AUTHORITY_CHECK_MD_STOCK.md listo para mostrar
- [ ] Pantalla compartida lista
- [ ] Chat de Kiro limpio (sin historial de sesiones anteriores)
- [ ] Respaldo: archivos ABAP pre-generados por si la demo en vivo falla

---

*Script v1.0 — Abril 2026*
*Duración: ~60 minutos (45 presentación + 15 preguntas)*
*Audiencia: Desarrolladores ABAP, nivel técnico mixto, público colombiano*
*Referencia: WORKSHOP_KIRO_SAP_AMRIZE.md*
