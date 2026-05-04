# QueHayMetro — Plan de Producto MVP

## 1. Análisis de Competencia

### Apps existentes en el ecosistema Metro de Medellín

| App | Qué hace | Qué NO hace (tu oportunidad) |
|-----|----------|-------------------------------|
| **App Cívica (oficial Metro)** | Planificación de viajes, pago con billetera digital, reporte de ocupación de vagones | No interpreta tweets, no da alertas inteligentes de servicio, no sugiere hora de salida |
| **Moovit** | Horarios en tiempo real, planificador de rutas multimodal, alertas de servicio genéricas | No analiza redes sociales, alertas genéricas sin contexto personalizado por ubicación |
| **Muuf** | Ubicación de buses en tiempo real, rutas de transporte público en Medellín y Rionegro | Enfocado en buses, no en metro. No tiene análisis de tweets ni IA |
| **Medellin Subway Map** | Mapa del metro, info turística, puntos de interés cercanos | Solo mapa estático/informativo, sin estado del servicio en tiempo real |
| **Medellin Transit Map** | Mapa del sistema SITVA completo | Solo mapas, sin alertas ni inteligencia |
| **Google Maps** | Rutas peatonales + transporte público, horarios estimados | No sabe si el metro está caído, no analiza @metrodemedellin |

### Tu diferenciador clave (lo que NADIE hace hoy)
**Ninguna app existente interpreta los tweets de @metrodemedellin con IA para darte un diagnóstico personalizado del servicio según tu ubicación y proponerte una decisión: "sal ahora" o "espera" o "toma alternativa".**

Esto es un nicho real y desatendido. La gente hoy abre X/Twitter manualmente, lee los tweets, interpreta por su cuenta, y decide. Tu app automatiza ese proceso cognitivo.

---

## 2. Realidad de la API de X (Twitter) — Abril 2026

Desde febrero 2026, X migró a un modelo **pay-as-you-go** (pago por uso):

| Concepto | Costo aproximado |
|----------|-----------------|
| Lectura de un tweet | ~$0.005 USD |
| Búsqueda de tweets | ~$0.01 USD por request |
| Free tier | Solo escritura (1,500 posts/mes), lectura muy limitada (~100 reads/mes app-level) |
| Pay-as-you-go | Compras créditos, se descuentan por request. Sin compromiso mensual fijo |

**Para el PoC:** El free tier con ~100 reads/mes es muy limitado. Pero el pay-as-you-go es viable: si consultas @metrodemedellin cada 5 minutos (288 veces/día), serían ~8,640 reads/mes ≈ **$43 USD/mes**. Si consultas cada 10 minutos, baja a ~$22 USD/mes. Totalmente manejable.

**Alternativa para PoC ultra-barato:** Web scraping del perfil público de @metrodemedellin (frágil pero gratis). Nitter mirrors si aún existen.

---

## 3. Arquitectura MVP Propuesta

```
┌─────────────────────────────────────────────────────┐
│                    MOBILE APP                        │
│              (React Native / Expo)                   │
│                                                      │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ Mapa +   │  │  Estado del  │  │  Recomendación│  │
│  │ Estación │  │  Servicio    │  │  "Sal ahora"  │  │
│  │ cercana  │  │  (semáforo)  │  │  / "Espera"   │  │
│  └──────────┘  └──────────────┘  └───────────────┘  │
└──────────────────┬──────────────────────────────────┘
                   │ REST API
┌──────────────────▼──────────────────────────────────┐
│                   BACKEND                            │
│              (Node.js + Express)                     │
│                                                      │
│  ┌──────────────┐  ┌─────────────┐  ┌────────────┐  │
│  │ Tweet Poller │  │ AI Analyzer │  │ Station    │  │
│  │ (cada 5 min) │  │ (Claude/    │  │ Service    │  │
│  │              │  │  OpenAI)    │  │ (geo+rutas)│  │
│  └──────┬───────┘  └──────┬──────┘  └────────────┘  │
│         │                 │                          │
│  ┌──────▼─────────────────▼──────┐                   │
│  │        Cache / DB             │                   │
│  │   (Redis + SQLite/Postgres)   │                   │
│  └───────────────────────────────┘                   │
└──────────────────────────────────────────────────────┘
         │                    │
    ┌────▼────┐         ┌────▼─────┐
    │ X API   │         │ LLM API  │
    │ (tweets)│         │ (Claude) │
    └─────────┘         └──────────┘
```

### Flujo principal
1. **Tweet Poller** consulta @metrodemedellin cada 5-10 minutos
2. **AI Analyzer** clasifica cada tweet nuevo en categorías:
   - `NORMAL` — servicio operando con normalidad
   - `DELAY` — retrasos en alguna línea/tramo
   - `PARTIAL_CLOSURE` — estaciones cerradas (extrae cuáles)
   - `FULL_CLOSURE` — servicio suspendido
   - `INFO` — tweet informativo sin impacto en servicio
3. El resultado se cachea en Redis (TTL 10 min)
4. La app consulta el backend con la ubicación del usuario
5. El backend calcula estación más cercana y cruza con estado del servicio
6. Responde con recomendación personalizada

---

## 4. Stack Tecnológico MVP

| Componente | Tecnología | Justificación |
|------------|-----------|---------------|
| Mobile App | **React Native + Expo** | Una base de código para iOS y Android. Expo simplifica builds y despliegue |
| Backend | **Node.js + Express** | Ligero, rápido de desarrollar, buen ecosistema para APIs |
| Base de datos | **SQLite** (MVP) → PostgreSQL (producción) | Cero config para MVP, migración fácil |
| Cache | **In-memory** (MVP) → Redis (producción) | Para MVP no necesitas Redis, un Map en memoria basta |
| API de X | **X API v2 pay-as-you-go** | ~$22-43 USD/mes según frecuencia de polling |
| IA / LLM | **Claude API (Haiku)** | Barato (~$0.25/MTok input), rápido, excelente para clasificación de texto en español |
| Geolocalización | **Expo Location** (nativo) | Gratis, viene con Expo |
| Mapas | **React Native Maps** (Google Maps) | Free tier de 28,500 cargas de mapa/mes |
| Hosting backend | **Railway / Render** | Free tier o ~$5-7 USD/mes |
| Ads | **Google AdMob** | Integración nativa con React Native |

---

## 5. Modelo de Datos — Estaciones Metro Línea A y B

### Línea A (Niquía → La Estrella)
```
Niquía → Bello → Madera → Acevedo → Tricentenario → Caribe → 
Universidad → Hospital → Prado → Parque Berrío → San Antonio → 
Exposiciones → Industriales → Poblado → Aguacatala → Ayurá → 
Envigado → Itagüí → Sabaneta → La Estrella
```

### Línea B (San Antonio → San Javier)
```
San Antonio → San José → Miraflores → El Bucaré → 
Santa Lucía → Floresta → San Javier
```

Cada estación tendrá coordenadas GPS precargadas para calcular la más cercana al usuario.

---

## 6. Solución Offline

Para cuando el usuario no tiene señal (común dentro del metro):

1. **Cache local agresivo:** La app guarda el último estado conocido del servicio con timestamp. Al abrir sin conexión, muestra: "Estado del metro hace 12 minutos: Normal ✅"
2. **Datos estáticos precargados:** Mapa de estaciones, coordenadas, tiempos promedio entre estaciones. Esto nunca necesita internet.
3. **Cola de consultas:** Si el usuario pide actualización sin conexión, se encola y se ejecuta cuando recupere señal.
4. **Indicador visual claro:** Banner "Sin conexión — mostrando último estado conocido" para que el usuario sepa que los datos pueden estar desactualizados.

---

## 7. Prompt de IA para Clasificación de Tweets

```
Eres un analista del sistema Metro de Medellín. Clasifica el siguiente tweet 
de @metrodemedellin en una de estas categorías:

- NORMAL: El servicio opera con normalidad
- DELAY: Hay retrasos en alguna línea o tramo
- PARTIAL_CLOSURE: Una o más estaciones están cerradas o fuera de servicio
- FULL_CLOSURE: El servicio está completamente suspendido
- INFO: Tweet informativo (eventos, campañas, horarios) sin impacto en servicio

Responde SOLO en formato JSON:
{
  "status": "NORMAL|DELAY|PARTIAL_CLOSURE|FULL_CLOSURE|INFO",
  "affected_stations": ["lista de estaciones afectadas si aplica"],
  "affected_lines": ["A", "B" o ambas si aplica],
  "summary": "resumen en una frase para el usuario",
  "estimated_resolution": "tiempo estimado si se menciona, null si no"
}
```

---

## 8. Pantallas del MVP (mínimas)

1. **Home / Dashboard**
   - Semáforo grande: 🟢 Normal | 🟡 Retrasos | 🔴 Cerrado
   - Estación más cercana a ti
   - Último tweet relevante interpretado
   - Botón "¿Puedo salir ahora?"

2. **Detalle de Estado**
   - Lista de tweets recientes con su clasificación
   - Mapa de líneas A y B con estaciones coloreadas por estado
   - Estaciones afectadas resaltadas

3. **Mi Ruta**
   - Seleccionar estación destino
   - Ver si la ruta está disponible
   - Tiempo estimado caminando hasta la estación más cercana

4. **Configuración**
   - Estación favorita / habitual
   - Notificaciones push (cuando cambie el estado)
   - Horario laboral (para alertas proactivas)

---

## 9. Costos Estimados Mensuales (MVP en producción)

| Concepto | Costo USD/mes |
|----------|--------------|
| X API (pay-as-you-go, polling cada 10 min) | ~$22 |
| Claude Haiku API (~8,640 clasificaciones/mes) | ~$5 |
| Hosting backend (Railway/Render) | ~$7 |
| Google Maps (free tier) | $0 |
| Apple Developer Account | $8.25 (=$99/año) |
| Google Play Developer | $2.08 (=$25 único, prorrateado) |
| **Total estimado** | **~$45 USD/mes** |

Esto es antes de ingresos por ads. Con AdMob, incluso con pocos usuarios, puedes cubrir estos costos.

---

## 10. Roadmap

### Fase 1 — MVP (4-6 semanas)
- [ ] Backend: Tweet poller + clasificación con IA
- [ ] Backend: API REST para estado del servicio
- [ ] App: Pantalla Home con semáforo y estación cercana
- [ ] App: Geolocalización y cálculo de estación más cercana
- [ ] App: Cache offline del último estado
- [ ] Datos: Coordenadas de todas las estaciones Línea A y B

### Fase 2 — Mejoras (semanas 7-10)
- [ ] Notificaciones push cuando cambie el estado
- [ ] Pantalla de detalle con mapa de líneas
- [ ] Pantalla "Mi Ruta" con destino
- [ ] Integración Google AdMob
- [ ] Alertas proactivas según horario laboral del usuario

### Fase 3 — Expansión (semanas 11-16)
- [ ] Navegación peatonal hasta la estación (Google Maps Directions)
- [ ] Soporte para Tranvía y Metrocable
- [ ] Modo turista (inglés, puntos de interés)
- [ ] Historial de incidentes del metro (analytics)
- [ ] Widget para pantalla de inicio (iOS/Android)

---

## 11. Nombre de la App

**QueHayMetro** — directo, coloquial, memorable. "¿Qué hay con el metro?" es exactamente la pregunta que responde.

Alternativas: MetroPulso, MetroYa, SalgoONo
