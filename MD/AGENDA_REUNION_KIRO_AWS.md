# Agenda de Reunión — Kiro + Amrize/Holcim BP

## Contexto para el equipo de AWS/Kiro

Amrize (Holcim BP) es una empresa de materiales de construcción que opera sobre SAP ECC 6.0 EHP8 (ABAP 7.5 SP19). Tenemos un equipo de desarrolladores ABAP que ya está usando Kiro como IDE principal, conectado a SAP vía MCP (Model Context Protocol). Ya logramos:

- Conectar Kiro a nuestro sistema BZD 130 para leer código fuente ABAP, buscar objetos y consultar el diccionario de datos
- Generar código ABAP con principios SOLID, inyección de dependencias y ABAP Unit
- Crear documentación técnica automatizada (TD, guías de workshop)
- Establecer steering files con estándares de codificación, nomenclatura y patrones de diseño

Queremos escalar esto a todo el equipo de desarrollo y maximizar el valor de Kiro en nuestro contexto SAP.

---

## Preguntas Técnicas

### 1. Modos de trabajo y casos de uso en otros clientes

- ¿Qué modos de trabajo (Autopilot vs. Supervised) recomiendan para equipos que están adoptando Kiro por primera vez?
- ¿Tienen casos documentados de otros clientes usando Kiro con SAP o sistemas legacy (no solo web/cloud-native)?
- ¿Cuál ha sido el patrón de adopción más exitoso? ¿Empezar con un equipo piloto, un módulo específico, o adopción masiva?
- ¿Hay clientes que usen Kiro para generar código en lenguajes "no mainstream" como ABAP, COBOL o RPG?

### 2. Automatización de pruebas y QA con Kiro

- ¿Es posible configurar hooks que ejecuten ABAP Unit automáticamente después de cada generación de código? (Hoy lo hacemos manual en Eclipse ADT)
- ¿Pueden los hooks de Kiro integrarse con pipelines de CI/CD externos (Jenkins, Azure DevOps, gCTS)?
- ¿Hay forma de que Kiro valide automáticamente que el código generado cumple con nuestros steering files antes de que el desarrollador lo suba?
- ¿Qué tan viable es usar el hook `preToolUse` como gate de calidad para bloquear código que no cumpla estándares?
- ¿Tienen roadmap para integración con herramientas de testing SAP como ABAP Test Cockpit (ATC) o Code Inspector?

### 3. MCP con SAP — profundización técnica

- Nuestro MCP server actual permite leer código y buscar objetos. ¿Qué otros endpoints ADT recomiendan exponer para maximizar el contexto que Kiro tiene del sistema SAP?
- ¿Hay limitaciones conocidas del MCP con SAP ECC vs. S/4HANA? (Ya detectamos que tablas estándar como VBAK no se resuelven por `/sap/bc/adt/ddic/tables/`)
- ¿Conocen otros clientes que hayan construido MCP servers para SAP? ¿Hay algún MCP server SAP open-source o en el marketplace?
- ¿Cuál es el límite práctico de contexto que Kiro puede manejar cuando el MCP devuelve programas ABAP de 2000+ líneas?
- ¿Recomiendan un MCP server por sistema SAP (DEV, QAS, PRD) o uno solo apuntando a DEV?

### 4. Escalabilidad y gobernanza para equipos

- ¿Cómo manejan otros clientes los steering files cuando hay 10+ desarrolladores? ¿Se versionan en Git? ¿Hay un mecanismo de distribución centralizada?
- ¿Existe un modelo de "steering files corporativos" que se hereden a todos los workspaces de un equipo?
- ¿Hay métricas o dashboards para medir la adopción y productividad del equipo con Kiro?
- ¿Cómo se maneja el licenciamiento para equipos grandes? ¿Hay planes enterprise con administración centralizada?
- ¿Hay forma de compartir specs entre desarrolladores para que uno defina los requisitos y otro implemente?

---

## Preguntas Estratégicas / No Técnicas

### 5. Roadmap y visión de producto

- ¿Cuál es el roadmap de Kiro para los próximos 6-12 meses?
- ¿Hay planes de soporte nativo para lenguajes como ABAP (syntax highlighting, diagnostics, autocompletado)?
- ¿Están considerando integración directa con SAP ADT (como extensión, sin necesidad de MCP custom)?
- ¿Kiro va a soportar colaboración en tiempo real entre desarrolladores (pair programming asistido por IA)?

### 6. Soporte y documentación para adopción empresarial

- ¿Qué documentación o guías de onboarding tienen para equipos que están adoptando Kiro?
- ¿Ofrecen workshops o sesiones de enablement para equipos enterprise?
- ¿Hay un canal de soporte dedicado para clientes enterprise o early adopters?
- ¿Tienen un programa de "customer champions" o comunidad de práctica entre clientes?

### 7. Seguridad y compliance

- ¿El código que Kiro procesa sale del entorno local? ¿Qué datos se envían a la nube?
- ¿Cómo manejan la propiedad intelectual del código generado?
- ¿Hay certificaciones de seguridad (SOC2, ISO 27001) que podamos presentar a nuestro equipo de InfoSec?
- ¿Se puede configurar Kiro para que NO envíe ciertos archivos o patrones (ej: credenciales, datos de producción)?

---

## 10 Puntos de Conversación Productiva

Estos son los temas concretos que recomiendo cubrir en la reunión, ordenados por prioridad:

### Bloque 1 — Lo que ya tenemos (mostrar valor, 15 min)

**Punto 1: Demo en vivo de lo que ya logramos**
Mostrar la conexión MCP → SAP BZD, la generación de código ABAP con SOLID, los steering files y la documentación automática. Esto posiciona a Amrize como un cliente avanzado y abre la puerta a soporte prioritario.

**Punto 2: Nuestro caso de uso diferenciador**
Somos probablemente uno de los pocos clientes usando Kiro con SAP ABAP. Esto es valioso para AWS como caso de estudio. Preguntar: ¿les interesa documentar nuestro caso? Esto puede traducirse en soporte dedicado.

### Bloque 2 — Lo que necesitamos resolver (técnico, 20 min)

**Punto 3: Limitaciones del MCP con SAP ECC**
Traer la lista concreta de lo que funciona y lo que no (ej: tablas estándar, ejecución de programas, activación de objetos). Pedir orientación sobre qué endpoints ADT priorizar.

**Punto 4: Automatización del ciclo de testing**
Explorar cómo conectar los hooks de Kiro con ABAP Unit / ATC. ¿Es viable un hook que ejecute tests remotamente vía RFC o ADT API?

**Punto 5: Gestión de steering files a escala**
Hoy los tenemos en un workspace. ¿Cómo los distribuimos a 15 desarrolladores sin que cada uno tenga su versión? ¿Git + sync automático?

### Bloque 3 — Escalamiento (estratégico, 15 min)

**Punto 6: Plan de adopción para el equipo completo**
Pedir recomendaciones de rollout: ¿cuántos desarrolladores a la vez? ¿Qué métricas medir? ¿Qué errores comunes evitar?

**Punto 7: Licenciamiento y costos para 15-20 desarrolladores**
Entender el modelo de pricing enterprise, si hay descuentos por volumen, y qué incluye cada tier.

**Punto 8: Capacitación y enablement**
¿Ofrecen material de training? ¿Pueden hacer un workshop para nuestro equipo? ¿Hay certificación?

### Bloque 4 — Futuro y partnership (10 min)

**Punto 9: Programa de early adopters o beta**
Si somos de los primeros en usar Kiro con SAP, ¿podemos entrar en un programa de feedback directo con el equipo de producto? Esto nos da acceso temprano a features y voz en el roadmap.

**Punto 10: Co-creación de un MCP server SAP de referencia**
Proponer a AWS/Kiro co-desarrollar un MCP server SAP robusto que pueda beneficiar a toda la comunidad SAP. Amrize aporta el conocimiento funcional y técnico SAP, Kiro aporta la plataforma. Win-win.

---

## Material de soporte para llevar a la reunión

- [ ] Demo preparada: conexión MCP → BZD → generación de ZR_SD_QUICK_ORDERS
- [ ] Steering files actuales (.kiro/steering/) como ejemplo de gobernanza
- [ ] Documento TD y Workshop como ejemplo de output
- [ ] Lista de endpoints ADT que usamos y los que nos faltan
- [ ] Métricas informales: tiempo de desarrollo con Kiro vs. sin Kiro (si las tienen)
- [ ] Preguntas de InfoSec pre-aprobadas por el equipo de seguridad

---

## Notas post-reunión (completar después)

| Tema | Respuesta / Compromiso | Responsable | Fecha |
|------|----------------------|-------------|-------|
| | | | |
| | | | |
| | | | |
