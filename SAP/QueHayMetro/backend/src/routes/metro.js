const express = require('express');
const router = express.Router();
const { getCurrentStatus, getLastTweets, poll } = require('../services/tweetPoller');
const { findNearest, getAllStations, getStationsByLine } = require('../services/stationService');
const { setScenario, getAvailableScenarios } = require('../data/mockTweets');

// GET /api/metro/status — Estado actual del metro
router.get('/status', (req, res) => {
  const status = getCurrentStatus();
  if (!status || !status.status) {
    return res.json({
      status: 'UNKNOWN',
      summary: 'Iniciando... intenta de nuevo en unos segundos.',
      lastUpdated: null,
    });
  }
  res.json(status);
});

// GET /api/metro/nearest?lat=6.21&lng=-75.57 — Estación más cercana
router.get('/nearest', (req, res) => {
  const { lat, lng } = req.query;
  if (!lat || !lng) {
    return res.status(400).json({ error: 'Se requieren parámetros lat y lng' });
  }

  const result = findNearest(parseFloat(lat), parseFloat(lng));
  const status = getCurrentStatus();

  // Verificar si la estación cercana está afectada
  const isAffected = status?.affected_stations?.some(
    (s) => s.toLowerCase() === result.station.name.toLowerCase()
  );

  res.json({
    ...result,
    isAffected,
    metroStatus: status?.status || 'UNKNOWN',
  });
});

// GET /api/metro/recommendation?lat=6.21&lng=-75.57 — Recomendación personalizada
router.get('/recommendation', (req, res) => {
  const { lat, lng } = req.query;
  if (!lat || !lng) {
    return res.status(400).json({ error: 'Se requieren parámetros lat y lng' });
  }

  const nearest = findNearest(parseFloat(lat), parseFloat(lng));
  const status = getCurrentStatus();

  if (!status || !status.status) {
    return res.json({
      action: 'WAIT',
      message: 'Cargando estado del metro, intenta en unos segundos...',
      nearest,
    });
  }

  const isStationAffected = status.affected_stations?.some(
    (s) => s.toLowerCase() === nearest.station.name.toLowerCase()
  );

  let recommendation;

  switch (status.status) {
    case 'NORMAL':
      recommendation = {
        action: 'GO',
        emoji: '🟢',
        message: `Todo bien. La estación ${nearest.station.name} está a ${nearest.walkingMinutes} min caminando. ¡Sal ahora!`,
      };
      break;

    case 'DELAY':
      recommendation = {
        action: 'GO_WITH_CAUTION',
        emoji: '🟡',
        message: `Hay retrasos en el metro. ${status.summary}. La estación ${nearest.station.name} está a ${nearest.walkingMinutes} min. Sal con tiempo extra.`,
      };
      break;

    case 'PARTIAL_CLOSURE':
      if (isStationAffected) {
        // Buscar estación alternativa no afectada
        const allStations = getAllStations();
        const alternatives = allStations
          .filter((s) => !status.affected_stations.some(
            (as) => as.toLowerCase() === s.name.toLowerCase()
          ))
          .map((s) => ({
            ...s,
            distance: findNearest(parseFloat(lat), parseFloat(lng)),
          }));

        const altNearest = findNearest(parseFloat(lat), parseFloat(lng));
        recommendation = {
          action: 'REROUTE',
          emoji: '🟠',
          message: `¡Atención! La estación ${nearest.station.name} está cerrada. ${status.summary}. Busca una estación alternativa.`,
          closedStations: status.affected_stations,
        };
      } else {
        recommendation = {
          action: 'GO_WITH_CAUTION',
          emoji: '🟡',
          message: `Hay estaciones cerradas (${status.affected_stations.join(', ')}), pero ${nearest.station.name} opera normal. Estás a ${nearest.walkingMinutes} min caminando.`,
        };
      }
      break;

    case 'FULL_CLOSURE':
      recommendation = {
        action: 'STOP',
        emoji: '🔴',
        message: `El metro está suspendido. ${status.summary}. No salgas hacia el metro en este momento.`,
      };
      break;

    default:
      recommendation = {
        action: 'INFO',
        emoji: 'ℹ️',
        message: status.summary || 'Sin información suficiente.',
      };
  }

  res.json({
    recommendation,
    nearest,
    metroStatus: status,
  });
});

// GET /api/metro/stations — Todas las estaciones
router.get('/stations', (req, res) => {
  const { line } = req.query;
  const stations = line ? getStationsByLine(line.toUpperCase()) : getAllStations();
  res.json(stations);
});

// GET /api/metro/tweets — Últimos tweets procesados
router.get('/tweets', (req, res) => {
  res.json(getLastTweets());
});

// --- Endpoints de prueba/simulación ---

// POST /api/test/simulate — Cambiar escenario mock
router.post('/test/simulate', (req, res) => {
  const { scenario } = req.body;
  if (!scenario) {
    return res.status(400).json({
      error: 'Se requiere campo "scenario"',
      available: getAvailableScenarios(),
    });
  }

  const success = setScenario(scenario);
  if (!success) {
    return res.status(400).json({
      error: `Escenario "${scenario}" no existe`,
      available: getAvailableScenarios(),
    });
  }

  // Re-analizar con el nuevo escenario
  poll().then((analysis) => {
    res.json({
      message: `Escenario cambiado a "${scenario}"`,
      status: analysis,
    });
  });
});

// GET /api/test/scenarios — Lista escenarios disponibles
router.get('/test/scenarios', (req, res) => {
  res.json(getAvailableScenarios());
});

module.exports = router;
