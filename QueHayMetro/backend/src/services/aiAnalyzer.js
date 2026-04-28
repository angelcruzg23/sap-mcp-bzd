const axios = require('axios');
const config = require('../config');

const SYSTEM_PROMPT = `Eres un analista del sistema Metro de Medellín. Tu trabajo es clasificar tweets de la cuenta oficial @metrodemedellin para determinar el estado del servicio.

Clasifica cada tweet en UNA de estas categorías:
- NORMAL: El servicio opera con normalidad
- DELAY: Hay retrasos en alguna línea o tramo
- PARTIAL_CLOSURE: Una o más estaciones están cerradas o fuera de servicio
- FULL_CLOSURE: El servicio está completamente suspendido
- INFO: Tweet informativo (eventos, campañas, horarios) sin impacto en el servicio actual

Responde SOLO en formato JSON válido, sin markdown ni texto adicional:
{
  "status": "NORMAL|DELAY|PARTIAL_CLOSURE|FULL_CLOSURE|INFO",
  "affected_stations": ["lista de estaciones afectadas, vacía si no aplica"],
  "affected_lines": ["A", "B", o ambas si aplica, vacía si no aplica"],
  "summary": "resumen en una frase corta y clara para el usuario",
  "estimated_resolution": "tiempo estimado si se menciona en el tweet, null si no"
}`;

// Analiza tweets con Claude API
async function analyzeTweets(tweets) {
  if (!tweets || tweets.length === 0) {
    return getDefaultStatus();
  }

  // Si estamos en modo mock y no hay API key, usar análisis local simple
  if (config.mode === 'mock' && !config.anthropicApiKey) {
    return analyzeLocal(tweets);
  }

  try {
    const tweetsText = tweets.map((t) => `- "${t.text}"`).join('\n');

    const response = await axios.post(
      'https://api.anthropic.com/v1/messages',
      {
        model: 'claude-3-haiku-20240307',
        max_tokens: 500,
        system: SYSTEM_PROMPT,
        messages: [
          {
            role: 'user',
            content: `Analiza estos tweets recientes de @metrodemedellin y dame el estado ACTUAL del servicio:\n\n${tweetsText}`,
          },
        ],
      },
      {
        headers: {
          'x-api-key': config.anthropicApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      }
    );

    const content = response.data.content[0].text;
    return JSON.parse(content);
  } catch (error) {
    console.error('Error llamando a Claude API:', error.message);
    // Fallback a análisis local si falla la API
    return analyzeLocal(tweets);
  }
}

// Análisis local simple basado en palabras clave (fallback sin IA)
function analyzeLocal(tweets) {
  const latestTweet = tweets[0]?.text?.toLowerCase() || '';

  if (latestTweet.includes('suspendido') || latestTweet.includes('emergencia')) {
    return {
      status: 'FULL_CLOSURE',
      affected_stations: [],
      affected_lines: ['A', 'B'],
      summary: 'Servicio suspendido en todas las líneas',
      estimated_resolution: null,
    };
  }

  if (latestTweet.includes('cerrad') || latestTweet.includes('fuera de servicio')) {
    const stationNames = extractStationNames(latestTweet);
    return {
      status: 'PARTIAL_CLOSURE',
      affected_stations: stationNames,
      affected_lines: detectAffectedLines(latestTweet),
      summary: `Estaciones cerradas: ${stationNames.join(', ') || 'ver detalle'}`,
      estimated_resolution: null,
    };
  }

  if (latestTweet.includes('retras') || latestTweet.includes('demora') || latestTweet.includes('revisión técnica')) {
    return {
      status: 'DELAY',
      affected_stations: extractStationNames(latestTweet),
      affected_lines: detectAffectedLines(latestTweet),
      summary: 'Se presentan retrasos en el servicio',
      estimated_resolution: extractTime(latestTweet),
    };
  }

  if (latestTweet.includes('normal') || latestTweet.includes('normalidad') || latestTweet.includes('buen viaje')) {
    return {
      status: 'NORMAL',
      affected_stations: [],
      affected_lines: [],
      summary: 'Servicio operando con normalidad',
      estimated_resolution: null,
    };
  }

  return {
    status: 'INFO',
    affected_stations: [],
    affected_lines: [],
    summary: 'Información general del Metro',
    estimated_resolution: null,
  };
}

// Extrae nombres de estaciones mencionadas en un tweet
function extractStationNames(text) {
  const stationKeywords = [
    'niquía', 'bello', 'madera', 'acevedo', 'tricentenario', 'caribe',
    'universidad', 'hospital', 'prado', 'parque berrío', 'san antonio',
    'exposiciones', 'industriales', 'poblado', 'aguacatala', 'ayurá',
    'envigado', 'itagüí', 'sabaneta', 'la estrella',
    'san josé', 'miraflores', 'el bucaré', 'santa lucía', 'floresta', 'san javier',
  ];
  return stationKeywords.filter((s) => text.includes(s));
}

function detectAffectedLines(text) {
  const lines = [];
  if (text.includes('línea a') || text.includes('linea a')) lines.push('A');
  if (text.includes('línea b') || text.includes('linea b')) lines.push('B');
  if (lines.length === 0 && (text.includes('todas') || text.includes('sistema'))) {
    return ['A', 'B'];
  }
  return lines;
}

function extractTime(text) {
  const match = text.match(/(\d+)\s*minutos/);
  return match ? `${match[1]} minutos` : null;
}

function getDefaultStatus() {
  return {
    status: 'NORMAL',
    affected_stations: [],
    affected_lines: [],
    summary: 'Sin información reciente. Se asume servicio normal.',
    estimated_resolution: null,
  };
}

module.exports = { analyzeTweets };
