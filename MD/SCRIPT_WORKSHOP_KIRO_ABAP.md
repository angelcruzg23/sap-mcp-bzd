# Script del Workshop: Kiro como Co-Piloto ABAP
## Guía del presentador — Para leer, practicar y seguir en vivo

---

## Antes de empezar — Notas para ti como presentador

- Este script está diseñado para ~75-100 minutos
- Las partes entre `[ACCIÓN]` son cosas que haces en pantalla
- Las partes entre `[PAUSA]` son momentos para preguntar si hay dudas
- El tono es conversacional, como si estuvieras explicándole a un compañero
- No necesitas memorizar nada — léelo natural, con tus palabras
- Si alguien pregunta algo que no sabes, di "buena pregunta, lo investigo y les comparto"

---

## PARTE 1 — Conceptos básicos de IA (15 minutos)
### "Antes de tocar código, nivelemos conceptos"

---

Bueno, antes de meternos de lleno con Kiro y SAP, quiero que hablemos de algunos conceptos de inteligencia artificial que van a aparecer durante todo el workshop. No necesitan ser expertos en IA para usar esto, pero sí ayuda entender qué está pasando por debajo.

Voy a explicar 5 conceptos. Son los únicos que necesitan para entender todo lo que vamos a hacer hoy.

### Concepto 1 — ¿Qué es un LLM?

LLM significa Large Language Model, o Modelo de Lenguaje Grande. Es el "cerebro" detrás de herramientas como ChatGPT, Copilot, o en nuestro caso, Kiro.

Piénsenlo así: es un programa que fue entrenado leyendo una cantidad absurda de texto — documentación, código, libros, foros, Stack Overflow, la documentación de SAP, código ABAP público... todo. Y después de leer todo eso, aprendió patrones. No "entiende" como un humano, pero puede predecir con mucha precisión qué texto debería venir después de otro texto.

Cuando ustedes le dicen a Kiro "dame el código para leer la tabla VBAK", el LLM no busca en una base de datos de respuestas. Lo que hace es: basándose en todo lo que leyó, predice cuál es la secuencia de texto más probable que responda a esa pregunta. Y como leyó miles de programas ABAP, la predicción es bastante buena.

Dato clave: el LLM que usa Kiro se llama Claude. Es de una empresa llamada Anthropic. No es ChatGPT (que es de OpenAI), aunque el concepto es similar.

### Concepto 2 — ¿Qué es un Prompt?

El prompt es simplemente lo que ustedes le escriben al AI. La instrucción, la pregunta, el pedido.

Pero acá viene lo importante: la calidad de lo que el AI te devuelve depende directamente de la calidad de lo que tú le pides. Esto es igual que cuando un funcional te pasa un requerimiento vago vs. uno bien detallado.

Ejemplo malo:
> "Haz un programa ABAP"

Ejemplo bueno:
> "Busca el Function Module ZSDE_GET_DATA_SHPMNT_HD_TAB en SAP BZD y agrega una línea para leer el campo ZZEQUIPE_TYPE de la LIKP, siguiendo el mismo patrón de los campos existentes"

¿Ven la diferencia? Entre más contexto y más específico seas, mejor resultado vas a obtener. Esto lo vamos a ver en la demo en vivo.

### Concepto 3 — ¿Qué es el Contexto?

El contexto es toda la información adicional que el AI tiene disponible cuando procesa tu prompt. No es solo lo que tú escribes en el chat — también incluye:

- Los archivos que tienes abiertos en el IDE
- Las reglas del equipo (lo que nosotros llamamos "steering files")
- El historial de la conversación
- Los resultados de herramientas que el AI ejecutó (como buscar código en SAP)

Piénsenlo como la diferencia entre pedirle algo a un consultor que acaba de llegar vs. uno que ya lleva 6 meses en el proyecto. El que lleva 6 meses tiene contexto — sabe cómo nombran las cosas, qué sistema usan, cuáles son las reglas. Eso es exactamente lo que hacen los steering files: le dan contexto a Kiro sobre nuestro proyecto.

### Concepto 4 — ¿Qué es MCP?

MCP significa Model Context Protocol. Este es el concepto más técnico, pero lo voy a simplificar.

Imaginen que el LLM es un cerebro muy inteligente pero que está encerrado en un cuarto sin ventanas. Puede pensar y razonar, pero no puede ver ni tocar nada del mundo exterior. No puede abrir SAP, no puede leer archivos, no puede buscar en internet.

MCP es la puerta que le abrimos a ese cuarto. Es un protocolo — un estándar — que permite conectar al AI con herramientas externas. En nuestro caso, la herramienta externa es SAP BZD.

Nosotros construimos un pequeño servidor en Python que:
1. Recibe peticiones de Kiro (ej: "busca el programa ZSD_QUOTATION*")
2. Las traduce a llamadas HTTP a la API de SAP (ADT REST API)
3. Le devuelve los resultados a Kiro

Así es como Kiro puede leer código ABAP, buscar objetos, crear programas y hasta activarlos. Todo sin que ustedes abran SAP GUI.

`[ACCIÓN: Mostrar el diagrama de arquitectura del documento WORKSHOP_KIRO_ABAP_PRODUCTIVITY.md — la sección con el diagrama ASCII de Kiro → MCP → SAP]`

### Concepto 5 — ¿Qué son los Steering Files?

Los steering files son archivos markdown que viven en la carpeta `.kiro/steering/` del proyecto. Son reglas que Kiro lee automáticamente cada vez que le pides algo.

Nosotros tenemos 4 principales:
- Uno que le dice qué sistema SAP usamos, qué versión de ABAP, qué módulos
- Uno con las convenciones de nombres (ZCL_, ZIF_, prefijos de variables)
- Uno con los estándares de codificación (qué está prohibido, qué es obligatorio)
- Uno con los patrones SOLID adaptados a ABAP

Esto es lo que hace que cuando Kiro genera código, se vea como si lo hubiera escrito alguien del equipo y no un robot genérico. Sin estos archivos, Kiro genera código ABAP válido pero genérico. Con ellos, genera código que sigue nuestras reglas.

`[PAUSA — Preguntar: ¿Alguna duda sobre estos 5 conceptos? ¿Queda claro qué es un LLM, un prompt, el contexto, MCP y los steering files?]`

---

## PARTE 2 — Qué es Kiro y por qué nos importa (10 minutos)
### "Ahora sí, hablemos de la herramienta"

---

Kiro es un IDE — un entorno de desarrollo — construido por Amazon. Se ve y se siente como VS Code, así que si ya usaron VS Code alguna vez, se van a sentir cómodos.

Pero la diferencia es que Kiro tiene un agente de AI integrado. No es un plugin que instalas encima — es parte del IDE desde el diseño. Esto significa que el AI puede:

- Leer y escribir archivos en tu proyecto
- Ejecutar comandos en la terminal
- Conectarse a herramientas externas vía MCP (como nuestro SAP)
- Seguir reglas del equipo automáticamente
- Trabajar en modo autónomo o supervisado

¿Por qué nos importa como ABAPs? Porque nuestro trabajo tiene mucho de esto:
- Leer documentos funcionales largos
- Buscar objetos en SAP (SE38, SE37, SE24, SE80...)
- Entender código existente antes de modificarlo
- Escribir código que sigue patrones repetitivos
- Documentar lo que hicimos

Todo eso es trabajo que un AI puede hacer más rápido que nosotros. No mejor — más rápido. La decisión de diseño, la validación, las pruebas, eso sigue siendo nuestro.

`[ACCIÓN: Abrir Kiro y mostrar la interfaz — señalar el chat, el explorador de archivos, la terminal]`

---

## PARTE 3 — Demo en vivo (30-40 minutos)
### "Vamos a hacer exactamente lo que hicimos en una sesión real"

---

Lo que van a ver ahora es una recreación de una sesión real de trabajo. El caso es el Change Request CHG0432318 — un nuevo tipo de equipo Conestoga para US Bank. Es un caso real del módulo SD.

### Demo 3.1 — Análisis del Functional Design

`[ACCIÓN: Tener el archivo .mht del FD abierto en la carpeta ConestogaChange]`

Tengo acá un Functional Design en formato .mht — que es básicamente un Word guardado como página web. Es un formato feo para leer, lleno de HTML y markup de Microsoft.

Voy a pedirle a Kiro que lo analice.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Analiza el requerimiento que se encuentra en la carpeta ConestogaChange. 
Dime qué entendiste del documento.
```

`[ESPERAR la respuesta de Kiro — debería dar un resumen estructurado del FD]`

Miren lo que hizo:
- Leyó un documento .mht lleno de HTML basura
- Extrajo la información de negocio: qué es un Conestoga, por qué se necesita el cambio
- Identificó los 5 pasos técnicos del diseño
- Resumió el análisis de impacto
- Listó los escenarios de prueba

Esto me hubiera tomado 30-45 minutos leyendo el documento. Kiro lo hizo en menos de 2 minutos.

`[PAUSA — Preguntar: ¿Alguien tiene preguntas sobre lo que acaba de pasar?]`

### Demo 3.2 — Búsqueda de objetos en SAP

Ahora le voy a pedir que busque los programas que menciona el FD directamente en SAP BZD.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Busca el programa MV50AFZ1 dentro de la ampliación ZSDE_TMS2SAP_DELIVERY_DATA 
y también los programas ZSDE_GET_DATA_SHPMNT_HD_TAB y ZSDE_SET_DATA_SHPMNT_HD_TAB
```

`[ESPERAR — Kiro va a usar las herramientas MCP para buscar en SAP]`

Fíjense en lo que está pasando:
- Kiro primero intentó buscar como programas (PROG) — no los encontró
- Entonces buscó por patrón y descubrió que son Function Modules dentro del grupo ZSDE_SHPMNT_DELIVRY_HD_TAB
- Encontró que el enhancement es tipo ENHO/XH
- Obtuvo el código fuente de los FMs

Esto es exactamente lo que haríamos nosotros: ir a SE37, buscar, no encontrar, ir a SE80, buscar el function group... Kiro hizo ese proceso de descubrimiento solo.

`[ACCIÓN: Mostrar en pantalla el código fuente que Kiro obtuvo de SAP]`

### Demo 3.3 — Generación de código

Ahora viene la parte interesante. Le voy a pedir que genere el código con los cambios.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Genera los archivos ABAP con los cambios necesarios para el nuevo campo 
ZZEQUIPE_TYPE en la LIKP. Modifica los FMs GET y SET, y agrega la lógica 
en el enhancement de MV50AFZ1 para que solo actualice cuando TMS envíe 
el valor 'ZZ' (Conestoga).
```

`[ESPERAR — Kiro va a generar los archivos]`

Veamos qué generó:

`[ACCIÓN: Abrir cada archivo generado y comentar:]`

1. El TOP include — agregó la variable global `gv_zzequipe_type` siguiendo el mismo patrón de las existentes
2. El FM GET — una línea nueva: `es_likp-zzequipe_type = gv_zzequipe_type`
3. El FM SET — una línea nueva: `gv_zzequipe_type = is_likp-zzequipe_type`
4. El enhancement — lógica condicional con constante, solo actualiza cuando VSBED = 'ZZ'

Fíjense en los detalles:
- Usó el mismo estilo de comentarios con search term (AC04082026)
- Respetó la convención de alineación de los comentarios
- No tocó el código existente — solo agregó lo nuevo
- La lógica del enhancement usa una constante en vez de un valor hardcodeado

Eso es porque los steering files le dijeron las reglas del equipo. Sin ellos, el código sería válido pero no seguiría nuestro estilo.

`[PAUSA — Preguntar: ¿Qué opinan? ¿El código se ve como algo que ustedes escribirían?]`

### Demo 3.4 — Lo que Kiro NO hizo (y por qué importa)

Quiero que noten lo que Kiro no hizo:
- No activó el código en SAP automáticamente (aunque puede hacerlo)
- No asumió nombres de variables en el enhancement — dejó una nota diciendo "verificar los nombres en scope"
- No creó la orden de transporte
- No hizo pruebas en el sistema

¿Por qué? Porque esas son decisiones que tomamos nosotros. Kiro es un co-piloto, no el piloto. Nos ahorra el trabajo mecánico para que nos enfoquemos en las decisiones de diseño y la validación.

### Demo 3.5 — Caso real: Debugging de autorización en programa de producción
#### "Esto pasó esta semana — un caso real de soporte"

`[ACCIÓN: Mostrar la imagen del error en SAP GUI — el mensaje "No authorization for W56LE601004 in plant 3096" en la barra de estado]`

Este caso es de esta semana. Un usuario reportó que al ejecutar la transacción ZSD_ORDER_TRACKING1 (programa ZSDR_ANOKA_REPORT_BAK_N), le aparecía un error de autorización en la barra de estado y el reporte salía vacío. El mensaje decía:

> "No authorization for W56LE601004 in plant 3096"

El usuario no sabía de dónde venía. El funcional tampoco. Nos llegó como incidente.

Vamos a ver cómo Kiro nos ayudó a resolverlo.

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Analicemos el programa ZSDR_ANOKA_REPORT_BAK_N para determinar dónde 
existe un punto dentro del código que lance el mensaje de falta de 
autorización. El mensaje es "No authorization for W56LE601004 in plant 3096". 
Este mensaje lo lanza cuando se procesa la búsqueda de la información, 
no cuando se selecciona el material en el ALV.
```

`[ESPERAR — Kiro va a:]`
1. Traer el código fuente del programa principal desde SAP BZD
2. Descubrir que tiene 3 includes (TOP2, E02, F02)
3. Traer los 3 includes en paralelo
4. Analizar todo el código buscando authority checks y llamadas a FMs

`[ACCIÓN: Mostrar cómo Kiro navega el código — señalar que leyó ~2500 líneas de ABAP en segundos]`

Miren lo que encontró:

El programa tiene **3 chequeos de autorización explícitos** que Kiro identificó:

| Form | Objeto Auth | Propósito |
|------|------------|-----------|
| `validate_authorization` | M_MSEG_WWE | Plantas STO — muestra popup |
| `zauthority_check` | M_MATE_VKO | Org. ventas — filtra registros |
| `zf_prs_data` (loop STO) | M_MSEG_WWE | Planta suministro — hace CONTINUE |

Pero **ninguno de esos genera el mensaje que vimos**. Entonces, ¿de dónde viene?

Kiro encontró que el culpable es una llamada a la FM estándar `MD_STOCK_REQUIREMENTS_LIST_API` dentro del `FORM zf_prs_data`. Esta FM hace internamente su propio authority check sobre el objeto `M_MTDI_ORG`, y cuando falla, lanza el mensaje E401(61) que se propaga a la barra de estado.

Y el código que la llama tiene un bloque vacío para el error:

```abap
IF sy-subrc <> 0.
  " ← Vacío: el mensaje de error se filtra a la barra de estado
ELSE.
  ...
ENDIF.
```

Esto empezó a pasar con **EHP8** — la FM tiene chequeos de autorización más estrictos que antes no existían.

`[PAUSA — Preguntar: ¿Cuánto les hubiera tomado encontrar esto manualmente? Buscar en 2500 líneas de código, en 3 includes, rastrear que el error no viene del código custom sino de una FM estándar...]`

Ahora le pedimos la solución:

`[ACCIÓN: En el chat de Kiro, escribir:]`

```
Proponme un cambio para validar el objeto M_MTDI_ORG antes de llamar 
a la FM, de manera que si el usuario no tiene acceso, continue con 
el siguiente registro.
```

Kiro propuso insertar **9 líneas** justo antes del CALL FUNCTION:

```abap
*       >>> BEGIN OF INSERTION - BZDK930947 - Authority pre-check
        AUTHORITY-CHECK OBJECT 'M_MTDI_ORG'
          ID 'MDAKT' FIELD 'A'
          ID 'WERKS' FIELD wa_vbap-werks
          ID 'DISPO' DUMMY.
        IF sy-subrc NE 0.
          CLEAR ls_mdps.
          CONTINUE.
        ENDIF.
*       <<< END OF INSERTION - BZDK930947 - Authority pre-check
```

La lógica es simple: replicar el mismo chequeo que la FM hace internamente, pero antes de llamarla. Si el usuario no tiene autorización para esa planta, se salta el registro silenciosamente y continúa con el siguiente. Sin mensaje de error, sin bloquear el reporte.

Después le pedimos que generara el informe técnico completo en inglés, y lo hizo en un archivo markdown con:
- Root cause analysis
- Code location exacta
- Propuesta de solución con código
- Comportamiento antes vs. después
- Impact assessment

`[ACCIÓN: Abrir el archivo ZSDR_ANOKA_REPORT_BAK_N/ANALYSIS_AUTHORITY_CHECK_MD_STOCK.md y mostrar la estructura]`

Veamos los tiempos de este caso:

| Actividad | Manual | Con Kiro |
|-----------|--------|----------|
| Leer y entender el programa (3 includes, ~2500 líneas) | 60-90 min | 2 min |
| Identificar el punto exacto del error | 30-60 min | 1 min |
| Descartar los 3 authority checks que NO son el problema | 15-20 min | incluido |
| Descubrir que el error viene de una FM estándar | 20-30 min | incluido |
| Proponer la solución con código | 15-20 min | 1 min |
| Generar el informe técnico completo | 30-45 min | 2 min |
| **Total** | **~3-4 horas** | **~6 minutos** |

Y lo más importante: Kiro no solo encontró el problema — explicó **por qué** empezó a pasar (EHP8), **dónde** exactamente está en el código, y **cómo** se comportará el programa después del fix.

`[PAUSA — Preguntar: ¿Ven la diferencia entre el caso anterior (desarrollo nuevo) y este (debugging/soporte)? Kiro sirve para ambos escenarios.]`

---

## PARTE 4 — La nueva forma de trabajar (10 minutos)
### "¿Cómo cambia nuestro día a día?"

---

`[ACCIÓN: Mostrar la tabla comparativa del documento WORKSHOP_KIRO_ABAP_PRODUCTIVITY.md]`

Veamos los números de esta sesión:

**Caso 1 — Desarrollo nuevo (Conestoga CHG0432318):**

| Actividad | Manual | Con Kiro |
|-----------|--------|----------|
| Análisis del FD | 30-45 min | 2 min |
| Búsqueda de objetos SAP | 15-20 min | 1 min |
| Generación de código | 45-60 min | 3 min |
| **Total** | **~2 horas** | **~6 minutos** |

**Caso 2 — Debugging/Soporte (Authority check ZSDR_ANOKA_REPORT_BAK_N):**

| Actividad | Manual | Con Kiro |
|-----------|--------|----------|
| Leer y entender programa (2500+ líneas, 3 includes) | 60-90 min | 2 min |
| Identificar root cause (FM estándar, no código custom) | 30-60 min | 1 min |
| Proponer solución con código | 15-20 min | 1 min |
| Generar informe técnico completo | 30-45 min | 2 min |
| **Total** | **~3-4 horas** | **~6 minutos** |

Dos escenarios completamente diferentes — desarrollo nuevo y soporte/debugging — y en ambos Kiro comprimió horas de trabajo mecánico a minutos.

Ahora, ojo — esto no significa que el trabajo se hace en 6 minutos. Después de esos 6 minutos, yo todavía tengo que:
- Revisar el código línea por línea
- Verificar los nombres de variables en el sistema real
- Subir el código a SAP
- Probar
- Documentar

Pero el punto es: el trabajo mecánico y repetitivo se comprimió dramáticamente. Y eso me libera tiempo para pensar en el diseño, en los edge cases, en las pruebas.

### Nuestro nuevo rol

Antes éramos:
- Lectores de documentos
- Buscadores de objetos
- Escritores de código
- Documentadores

Ahora somos:
- Validadores de análisis
- Revisores de propuestas
- Arquitectos de soluciones
- Curadores de lo que el AI genera

El valor ya no está en qué tan rápido tipeas. Está en tu criterio técnico, en tu conocimiento del negocio, en tu capacidad de decir "esto está bien" o "esto no va a funcionar porque..."

---

## PARTE 5 — Qué necesitamos para que esto funcione (10 minutos)
### "No es magia — hay requisitos"

---

Para que Kiro nos dé resultados buenos, necesitamos darle buen input. Basura entra, basura sale — eso aplica igual con AI.

### Lo que necesita el equipo funcional

Los Functional Designs tienen que incluir:
- Nombres exactos de los objetos SAP (no "el programa de entregas" sino "ZSDE_GET_DATA_SHPMNT_HD_TAB")
- Nombres de campos nuevos o modificados
- Lógica condicional explícita (cuándo sí, cuándo no)
- Valores específicos (ej: 'ZZ' = Conestoga)

Si el FD dice "hay que agregar un campo en la delivery", Kiro no puede hacer mucho. Si dice "agregar el campo ZZEQUIPE_TYPE en LIKP, actualizar los FMs GET y SET del grupo ZSDE_SHPMNT_DELIVRY_HD_TAB, y en el enhancement ZSDE_TMS2SAP_DELIVERY_DATA solo actualizar cuando VSBED = 'ZZ'", Kiro puede generar el código casi listo para producción.

### Lo que necesitamos nosotros como ABAPs

1. Tener Kiro instalado y configurado (les vamos a compartir la guía de instalación)
2. Mantener los steering files actualizados (si cambian las reglas del equipo, actualizar los archivos)
3. Aprender a escribir buenos prompts (ser específicos, dar contexto)
4. Siempre revisar lo que Kiro genera (nunca subir código sin revisarlo)
5. Reportar cuando Kiro se equivoca (para mejorar los steering files)

### Lo que NO se delega al AI

Esto es importante y quiero que quede claro:

- La decisión de diseño es nuestra
- La validación de impacto es nuestra
- Las pruebas en el sistema son nuestras
- La activación en producción sigue el proceso normal de transportes
- La seguridad y autorizaciones son responsabilidad del equipo

Kiro es una herramienta. Una herramienta muy poderosa, pero una herramienta. El responsable del código que sube a producción sigue siendo el desarrollador.

`[PAUSA — Preguntar: ¿Alguna preocupación? ¿Algo que les genere duda?]`

---

## PARTE 6 — Cierre y próximos pasos (5 minutos)

---

Para cerrar, les voy a compartir:

1. La guía de instalación paso a paso — está diseñada para que cualquiera pueda configurar Kiro en su máquina en 15 minutos
2. Los steering files del equipo — para que Kiro genere código con nuestro estilo desde el día 1
3. El documento de productividad — con los casos de uso donde Kiro más ayuda

Mi sugerencia: instálenlo esta semana, prueben con algo simple — buscar un objeto, leer código de un programa que ya conocen. Vayan agarrando confianza. Y si tienen problemas, me escriben.

Esto no reemplaza lo que sabemos. Lo amplifica. Un ABAP con 10 años de experiencia usando Kiro es mucho más productivo que Kiro solo. Porque Kiro puede generar código rápido, pero solo ustedes saben si ese código tiene sentido en el contexto de Holcim.

Gracias por su tiempo. ¿Preguntas finales?

`[ACCIÓN: Abrir espacio para Q&A — tener abiertos los documentos por si necesitas mostrar algo]`

---

## Apéndice — Preguntas frecuentes que podrían surgir

### "¿Kiro puede ver mis datos de producción?"
No. Kiro se conecta a SAP vía ADT, que es la misma API que usa Eclipse. Solo puede hacer lo que tu usuario SAP tiene autorizado. Si tu usuario no puede ver datos de producción, Kiro tampoco.

### "¿El código que genera Kiro es seguro?"
El código es tan seguro como el que escribirías tú. Kiro sigue las reglas de los steering files, pero la revisión final es tuya. Nunca subas código sin revisarlo.

### "¿Esto funciona con S/4HANA?"
Sí. El MCP server usa ADT REST API, que funciona igual en ECC y en S/4HANA. Solo habría que ajustar los steering files para permitir sintaxis de ABAP Cloud si aplica.

### "¿Puedo usar esto para debuggear?"
No directamente — Kiro no puede hacer debugging interactivo (poner breakpoints, inspeccionar variables en runtime). Pero como vimos en el caso de la autorización, sí puede analizar miles de líneas de código, rastrear el flujo de ejecución, identificar qué FM estándar está causando un error, y proponer un fix con código listo. Para investigación de incidentes y root cause analysis, es extremadamente útil.

### "¿Kiro puede leer código de FMs estándar de SAP?"
Sí, a través del MCP server puede leer cualquier objeto al que tu usuario SAP tenga acceso vía ADT. Eso incluye programas Z, FMs estándar, clases, includes, tablas del diccionario, etc.

### "¿Cuánto cuesta la licencia de Kiro?"
Kiro tiene un tier gratuito con límites de uso y un tier de pago. Los detalles están en kiro.dev. Para el workshop estamos usando licencias del equipo.

### "¿Qué pasa si Kiro genera código incorrecto?"
Pasa. No es perfecto. Por eso el flujo siempre incluye revisión humana. Si genera algo incorrecto, corrígelo y si es un patrón que se repite, actualiza los steering files para que no vuelva a pasar.

### "¿Puedo conectar Kiro a otros sistemas además de SAP?"
Sí. MCP es un protocolo abierto. Puedes crear servidores MCP para cualquier sistema que tenga una API: bases de datos, APIs REST, servicios cloud, etc.

---

## Checklist del presentador — Antes del workshop

- [ ] Kiro abierto con el workspace del proyecto
- [ ] MCP server conectado y funcionando (hacer un ping de prueba)
- [ ] VPN conectada (para llegar a SAP BZD)
- [ ] Archivo FD del Conestoga en la carpeta ConestogaChange
- [ ] Imagen del error de autorización (screenshot de SAP GUI con el mensaje en la barra de estado)
- [ ] Informe técnico generado: ZSDR_ANOKA_REPORT_BAK_N/ANALYSIS_AUTHORITY_CHECK_MD_STOCK.md
- [ ] Documentos de referencia abiertos (WORKSHOP_KIRO_ABAP_PRODUCTIVITY.md, GUIA_INSTALACION)
- [ ] Pantalla compartida lista
- [ ] Chat de Kiro limpio (sin historial de sesiones anteriores)
- [ ] Backup: tener los archivos ABAP ya generados por si la demo en vivo falla

---

*Script v1.1 — Abril 2026 (actualizado con caso de debugging/autorización)*
*Duración estimada: 75-100 minutos*
*Audiencia: Desarrolladores ABAP, nivel técnico mixto, sin experiencia previa con AI*
