// Estaciones del Metro de Medellín - Líneas A y B
// Coordenadas GPS reales de cada estación

const stations = [
  // Línea A (Norte-Sur): Niquía → La Estrella
  { id: 'niquia', name: 'Niquía', line: 'A', lat: 6.3378, lng: -75.5440, order: 1 },
  { id: 'bello', name: 'Bello', line: 'A', lat: 6.3340, lng: -75.5560, order: 2 },
  { id: 'madera', name: 'Madera', line: 'A', lat: 6.3190, lng: -75.5590, order: 3 },
  { id: 'acevedo', name: 'Acevedo', line: 'A', lat: 6.3040, lng: -75.5570, order: 4 },
  { id: 'tricentenario', name: 'Tricentenario', line: 'A', lat: 6.2930, lng: -75.5580, order: 5 },
  { id: 'caribe', name: 'Caribe', line: 'A', lat: 6.2810, lng: -75.5640, order: 6 },
  { id: 'universidad', name: 'Universidad', line: 'A', lat: 6.2700, lng: -75.5660, order: 7 },
  { id: 'hospital', name: 'Hospital', line: 'A', lat: 6.2620, lng: -75.5680, order: 8 },
  { id: 'prado', name: 'Prado', line: 'A', lat: 6.2540, lng: -75.5690, order: 9 },
  { id: 'parque_berrio', name: 'Parque Berrío', line: 'A', lat: 6.2480, lng: -75.5690, order: 10 },
  { id: 'san_antonio', name: 'San Antonio', line: 'AB', lat: 6.2470, lng: -75.5700, order: 11 },
  { id: 'exposiciones', name: 'Exposiciones', line: 'A', lat: 6.2390, lng: -75.5720, order: 12 },
  { id: 'industriales', name: 'Industriales', line: 'A', lat: 6.2310, lng: -75.5740, order: 13 },
  { id: 'poblado', name: 'Poblado', line: 'A', lat: 6.2100, lng: -75.5760, order: 14 },
  { id: 'aguacatala', name: 'Aguacatala', line: 'A', lat: 6.1970, lng: -75.5780, order: 15 },
  { id: 'ayura', name: 'Ayurá', line: 'A', lat: 6.1880, lng: -75.5810, order: 16 },
  { id: 'envigado', name: 'Envigado', line: 'A', lat: 6.1750, lng: -75.5830, order: 17 },
  { id: 'itagui', name: 'Itagüí', line: 'A', lat: 6.1650, lng: -75.5990, order: 18 },
  { id: 'sabaneta', name: 'Sabaneta', line: 'A', lat: 6.1510, lng: -75.6100, order: 19 },
  { id: 'la_estrella', name: 'La Estrella', line: 'A', lat: 6.1390, lng: -75.6270, order: 20 },

  // Línea B (Este-Oeste): San Antonio → San Javier
  { id: 'san_jose', name: 'San José', line: 'B', lat: 6.2490, lng: -75.5750, order: 1 },
  { id: 'miraflores', name: 'Miraflores', line: 'B', lat: 6.2510, lng: -75.5810, order: 2 },
  { id: 'el_bucare', name: 'El Bucaré', line: 'B', lat: 6.2520, lng: -75.5870, order: 3 },
  { id: 'santa_lucia', name: 'Santa Lucía', line: 'B', lat: 6.2540, lng: -75.5940, order: 4 },
  { id: 'floresta', name: 'Floresta', line: 'B', lat: 6.2560, lng: -75.6010, order: 5 },
  { id: 'san_javier', name: 'San Javier', line: 'B', lat: 6.2570, lng: -75.6120, order: 6 },
];

module.exports = stations;
