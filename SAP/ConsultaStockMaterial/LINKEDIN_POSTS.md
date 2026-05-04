# LinkedIn Posts — Material Stock API with Kiro

## Tips para maximizar engagement en LinkedIn

1. Publicar entre 7-9 AM (hora de tu audiencia) martes a jueves
2. El hook (primeras 2 líneas) es lo más importante — debe generar curiosidad
3. Usar espaciado generoso (una idea por línea)
4. Incluir una imagen o screenshot del resultado real en SAP
5. Cerrar con una pregunta para generar comentarios
6. Publicar primero en inglés (audiencia global SAP/tech), luego en español (comunidad LATAM)
7. No poner links en el post principal — LinkedIn penaliza links externos. Si quieres compartir algo, ponlo en el primer comentario

---

## English Version

---

"Where is this material available?"

That one question was costing us hours every week.

Our Salesforce team needed to know which plants had stock for a specific material. Every. Single. Time. They had to ask someone to open SAP, run transaction MMBE, take a screenshot, and send it back.

Manual. Slow. Outdated the moment it was sent.

So I decided to fix it.

I sat down with Kiro (AWS's AI-powered IDE) and described the problem in plain language. I pasted screenshots of the SAP screens — the stock overview, the exclusion table.

What happened next surprised me.

In about 72 minutes, Kiro helped me:

→ Design a complete SOLID architecture (3 interfaces, 3 classes, 1 RFC function module)
→ Generate ~860 lines of production-ready ABAP code
→ Create 24 unit tests with test doubles
→ Build the implementation guide for SAP (13 objects, step by step)
→ Write the API spec for our Mulesoft developer
→ Fix 4 compilation issues specific to our SAP version (ECC 6.0, ABAP 7.50 SP32)

The same work would have taken ~45 hours manually. That's roughly 6 working days.

We went from 6 days → 72 minutes.

The result? An RFC-enabled function module that Mulesoft calls in real time. Salesforce now shows material availability by plant — including which plants are excluded — without anyone opening SAP.

No more screenshots. No more waiting. No more guessing.

A few things I learned along the way:

1. AI doesn't replace the developer. It replaces the repetitive parts — boilerplate, documentation, test scaffolding. You still need to know your SAP tables, your business rules, your architecture.

2. Showing the AI your actual errors (Eclipse screenshots) makes iteration incredibly fast. It understood ABAP compilation errors from images.

3. The documentation came for free. Requirements, technical design, API spec, implementation guide — all generated as part of the process, not as an afterthought.

4. Steering files matter. I had coding standards and naming conventions configured in Kiro. Every line of generated code followed our team's patterns automatically.

The question isn't whether AI will change SAP development.

It's whether you'll be the one leading that change in your organization.

What repetitive development task would you automate first?

#SAP #ABAP #AI #Kiro #AWS #Mulesoft #Salesforce #SAPDevelopment #Innovation #DigitalTransformation

---

## Versión en Español

---

"¿En qué planta está disponible este material?"

Esa simple pregunta nos costaba horas cada semana.

El equipo de Salesforce necesitaba saber qué plantas tenían stock de un material. Cada vez, alguien tenía que abrir SAP, ejecutar la transacción MMBE, tomar un screenshot y enviarlo por correo.

Manual. Lento. Desactualizado en el momento que se enviaba.

Decidí resolverlo.

Me senté con Kiro (el IDE con IA de AWS) y le describí el problema en lenguaje natural. Pegué capturas de pantalla de SAP — el resumen de stock, la tabla de exclusiones.

Lo que pasó después me sorprendió.

En aproximadamente 72 minutos, Kiro me ayudó a:

→ Diseñar una arquitectura SOLID completa (3 interfaces, 3 clases, 1 función RFC)
→ Generar ~860 líneas de código ABAP listo para producción
→ Crear 24 tests unitarios con test doubles
→ Construir la guía de implementación para SAP (13 objetos, paso a paso)
→ Escribir la especificación de API para el desarrollador de Mulesoft
→ Corregir 4 errores de compilación específicos de nuestra versión de SAP (ECC 6.0, ABAP 7.50 SP32)

El mismo trabajo hubiera tomado ~45 horas manualmente. Eso son aproximadamente 6 días laborales.

Pasamos de 6 días → 72 minutos.

¿El resultado? Un function module RFC que Mulesoft llama en tiempo real. Salesforce ahora muestra la disponibilidad de material por planta — incluyendo qué plantas están excluidas — sin que nadie abra SAP.

No más screenshots. No más esperas. No más adivinanzas.

Algunas cosas que aprendí en el camino:

1. La IA no reemplaza al desarrollador. Reemplaza las partes repetitivas — boilerplate, documentación, scaffolding de tests. Tú sigues necesitando conocer tus tablas SAP, tus reglas de negocio, tu arquitectura.

2. Mostrarle a la IA tus errores reales (screenshots de Eclipse) hace la iteración increíblemente rápida. Entendió errores de compilación ABAP desde imágenes.

3. La documentación salió gratis. Requerimientos, diseño técnico, spec de API, guía de implementación — todo generado como parte del proceso, no como deuda técnica.

4. Los steering files importan. Tenía los estándares de codificación y convenciones de nomenclatura configurados en Kiro. Cada línea de código generado siguió los patrones de nuestro equipo automáticamente.

La pregunta no es si la IA va a cambiar el desarrollo SAP.

Es si tú vas a ser quien lidere ese cambio en tu organización.

¿Qué tarea repetitiva de desarrollo automatizarías primero?

#SAP #ABAP #IA #Kiro #AWS #Mulesoft #Salesforce #DesarrolloSAP #Innovación #TransformaciónDigital

---

## Imagen sugerida para acompañar el post

Usa el screenshot de SAP SE37 mostrando el resultado de ET_PLANT_STOCK con las 8 plantas y los flags de exclusión. Es visual, real, y demuestra que no es teoría — es algo que ya funciona en producción.

Si puedes, haz un collage con:
- Lado izquierdo: el screenshot de MMBE (el proceso manual)
- Lado derecho: el resultado del FM en SE37 (la solución automatizada)
- En el medio: una flecha con "72 min with Kiro"
