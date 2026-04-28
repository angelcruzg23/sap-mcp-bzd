const stations = require('../data/stations');

// Calcula distancia entre dos puntos GPS (fórmula Haversine)
function getDistanceKm(lat1, lng1, lat2, lng2) {
  const R = 6371; // Radio de la Tierra en km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Tiempo estimado caminando (velocidad promedio: 5 km/h)
function getWalkingMinutes(distanceKm) {
  return Math.round((distanceKm / 5) * 60);
}

// Encuentra la estación más cercana a unas coordenadas
function findNearest(lat, lng) {
  let nearest = null;
  let minDistance = Infinity;

  for (const station of stations) {
    const distance = getDistanceKm(lat, lng, station.lat, station.lng);
    if (distance < minDistance) {
      minDistance = distance;
      nearest = station;
    }
  }

  return {
    station: nearest,
    distanceKm: Math.round(minDistance * 100) / 100,
    walkingMinutes: getWalkingMinutes(minDistance),
  };
}

// Obtiene todas las estaciones de una línea
function getStationsByLine(line) {
  return stations.filter(
    (s) => s.line === line || s.line === 'AB'
  );
}

// Busca una estación por nombre (búsqueda flexible)
function findStationByName(name) {
  const normalized = name.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
  return stations.find((s) => {
    const stationNorm = s.name.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    return stationNorm.includes(normalized) || normalized.includes(stationNorm);
  });
}

function getAllStations() {
  return stations;
}

module.exports = { findNearest, getStationsByLine, findStationByName, getAllStations };
