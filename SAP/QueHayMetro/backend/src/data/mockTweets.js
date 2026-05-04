// Tweets de ejemplo para probar sin API de X
// Copiados/inspirados del estilo real de @metrodemedellin

const mockScenarios = {
  normal: [
    {
      id: '1',
      text: 'Servicio normal en todas nuestras líneas. ¡Buen viaje! 🚇',
      created_at: new Date().toISOString(),
    },
    {
      id: '2',
      text: 'Líneas A y B operando con normalidad. Frecuencia habitual de trenes.',
      created_at: new Date(Date.now() - 30 * 60000).toISOString(),
    },
  ],

  delay: [
    {
      id: '3',
      text: 'Por situación presentada en estación Acevedo, el servicio presenta retrasos en la Línea A sentido norte. Trabajamos para normalizar.',
      created_at: new Date().toISOString(),
    },
    {
      id: '4',
      text: 'Informamos retrasos de aproximadamente 10 minutos en Línea A por revisión técnica en tramo Industriales - Poblado.',
      created_at: new Date(Date.now() - 15 * 60000).toISOString(),
    },
  ],

  partial_closure: [
    {
      id: '5',
      text: 'Informamos que las estaciones Acevedo y Tricentenario se encuentran cerradas temporalmente por orden público. El servicio opera entre Caribe y La Estrella.',
      created_at: new Date().toISOString(),
    },
    {
      id: '6',
      text: 'Estación San Javier cerrada por mantenimiento programado. Línea B opera hasta Floresta. Disponemos buses de apoyo.',
      created_at: new Date(Date.now() - 20 * 60000).toISOString(),
    },
  ],

  full_closure: [
    {
      id: '7',
      text: 'ATENCIÓN: Por situación de emergencia, el servicio del Metro se encuentra suspendido en todas las líneas. Informaremos cuando se restablezca.',
      created_at: new Date().toISOString(),
    },
  ],

  info: [
    {
      id: '8',
      text: '¡Te invitamos a la Feria del Libro en estación Parque Berrío! Del 10 al 20 de abril. Entrada libre. 📚',
      created_at: new Date().toISOString(),
    },
    {
      id: '9',
      text: 'Recuerda que los domingos y festivos nuestro horario es de 5:00 a.m. a 10:00 p.m.',
      created_at: new Date(Date.now() - 60 * 60000).toISOString(),
    },
  ],
};

// Escenario activo por defecto
let activeScenario = 'normal';

function setScenario(scenario) {
  if (mockScenarios[scenario]) {
    activeScenario = scenario;
    return true;
  }
  return false;
}

function getMockTweets() {
  return mockScenarios[activeScenario] || mockScenarios.normal;
}

function getAvailableScenarios() {
  return Object.keys(mockScenarios);
}

module.exports = { getMockTweets, setScenario, getAvailableScenarios };
