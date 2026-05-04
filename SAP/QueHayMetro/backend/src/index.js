const express = require('express');
const cors = require('cors');
const config = require('./config');
const metroRoutes = require('./routes/metro');
const { startPolling } = require('./services/tweetPoller');

const app = express();

app.use(cors());
app.use(express.json());

// Rutas
app.use('/api/metro', metroRoutes);

// Rutas de test (reutiliza el mismo router que tiene /test/*)
app.post('/api/test/simulate', (req, res) => {
  const { scenario } = req.body;
  if (!scenario) {
    return res.status(400).json({
      error: 'Se requiere campo "scenario"',
      available: require('./data/mockTweets').getAvailableScenarios(),
    });
  }
  const success = require('./data/mockTweets').setScenario(scenario);
  if (!success) {
    return res.status(400).json({
      error: `Escenario "${scenario}" no existe`,
      available: require('./data/mockTweets').getAvailableScenarios(),
    });
  }
  require('./services/tweetPoller').poll().then((analysis) => {
    res.json({ message: `Escenario cambiado a "${scenario}"`, status: analysis });
  });
});

app.get('/api/test/scenarios', (req, res) => {
  res.json(require('./data/mockTweets').getAvailableScenarios());
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', mode: config.mode, timestamp: new Date().toISOString() });
});

// Ruta raíz
app.get('/', (req, res) => {
  res.json({
    app: 'QueHayMetro API',
    version: '1.0.0',
    endpoints: {
      status: 'GET /api/metro/status',
      nearest: 'GET /api/metro/nearest?lat=6.21&lng=-75.57',
      recommendation: 'GET /api/metro/recommendation?lat=6.21&lng=-75.57',
      stations: 'GET /api/metro/stations',
      tweets: 'GET /api/metro/tweets',
      simulate: 'POST /api/test/simulate { "scenario": "delay" }',
      scenarios: 'GET /api/test/scenarios',
    },
  });
});

// Iniciar servidor y polling
app.listen(config.port, '0.0.0.0', () => {
  console.log(`\n🚇 QueHayMetro API corriendo en http://localhost:${config.port}`);
  console.log(`📡 Modo: ${config.mode}`);
  console.log(`\nEndpoints disponibles:`);
  console.log(`  GET  /api/metro/status`);
  console.log(`  GET  /api/metro/nearest?lat=6.21&lng=-75.57`);
  console.log(`  GET  /api/metro/recommendation?lat=6.21&lng=-75.57`);
  console.log(`  GET  /api/metro/stations`);
  console.log(`  GET  /api/metro/tweets`);
  console.log(`  POST /api/test/simulate  { "scenario": "delay" }`);
  console.log(`  GET  /api/test/scenarios\n`);

  startPolling();
});
