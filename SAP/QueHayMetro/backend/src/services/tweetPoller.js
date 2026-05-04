const axios = require('axios');
const config = require('../config');
const { getMockTweets } = require('../data/mockTweets');
const { analyzeTweets } = require('./aiAnalyzer');

// Cache en memoria del estado actual
let cachedStatus = null;
let lastUpdated = null;
let lastTweets = [];

// Obtiene tweets reales de la API de X
async function fetchLiveTweets() {
  try {
    // Busca tweets recientes de @metrodemedellin (última hora)
    const response = await axios.get(
      'https://api.twitter.com/2/tweets/search/recent',
      {
        params: {
          query: 'from:metrodemedellin',
          max_results: 10,
          'tweet.fields': 'created_at,text',
        },
        headers: {
          Authorization: `Bearer ${config.xBearerToken}`,
        },
      }
    );
    return response.data.data || [];
  } catch (error) {
    console.error('Error consultando X API:', error.message);
    return [];
  }
}

// Ejecuta un ciclo de polling: obtener tweets → analizar → cachear
async function poll() {
  console.log(`[${new Date().toLocaleTimeString()}] Polling tweets (modo: ${config.mode})...`);

  const tweets = config.mode === 'live' ? await fetchLiveTweets() : getMockTweets();
  lastTweets = tweets;

  const analysis = await analyzeTweets(tweets);
  cachedStatus = analysis;
  lastUpdated = new Date();

  console.log(`[${new Date().toLocaleTimeString()}] Estado: ${analysis.status} — ${analysis.summary}`);
  return analysis;
}

// Inicia el polling periódico
function startPolling() {
  // Primera ejecución inmediata
  poll();
  // Luego cada X minutos
  setInterval(poll, config.pollIntervalMs);
  console.log(`Polling iniciado cada ${config.pollIntervalMs / 60000} minutos`);
}

// Getters para el estado actual
function getCurrentStatus() {
  return {
    ...cachedStatus,
    lastUpdated: lastUpdated?.toISOString(),
    mode: config.mode,
  };
}

function getLastTweets() {
  return lastTweets;
}

module.exports = { startPolling, poll, getCurrentStatus, getLastTweets };
