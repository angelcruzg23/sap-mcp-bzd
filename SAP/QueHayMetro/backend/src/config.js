require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  mode: process.env.MODE || 'mock', // 'mock' o 'live'
  xBearerToken: process.env.X_BEARER_TOKEN,
  anthropicApiKey: process.env.ANTHROPIC_API_KEY,
  // Polling cada 5 minutos
  pollIntervalMs: 5 * 60 * 1000,
  // Cache TTL: 10 minutos
  cacheTtlMs: 10 * 60 * 1000,
};
