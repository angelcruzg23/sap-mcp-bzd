# 🔗 Blockchain — Guía de Entendimiento para el Equipo

## ¿Qué es una Blockchain?

Una blockchain es una **lista enlazada de bloques** donde cada bloque contiene:
- **Datos** (transacciones, información, lo que sea)
- **Un hash** (huella digital única calculada a partir del contenido)
- **El hash del bloque anterior** (esto crea la "cadena")

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Bloque 0 │────▶│ Bloque 1 │────▶│ Bloque 2 │
│ (Génesis)│     │          │     │          │
│ Hash: a3f│     │ Prev: a3f│     │ Prev: 7b2│
│          │     │ Hash: 7b2│     │ Hash: e91│
└──────────┘     └──────────┘     └──────────┘
```

## Conceptos Clave

### 1. Hashing (SHA-256)
Un hash es una función que toma cualquier entrada y produce una salida de tamaño fijo (64 caracteres hex en SHA-256).

Propiedades importantes:
- **Determinista**: la misma entrada siempre produce el mismo hash
- **Efecto avalancha**: un cambio mínimo en la entrada cambia completamente el hash
- **Unidireccional**: no se puede obtener la entrada original a partir del hash

Ejemplo:
```
"Hola"     → 3c5e2a8f7d... (64 chars)
"Hola."    → 9a1b4c7e2d... (completamente diferente)
```

### 2. Encadenamiento
Cada bloque almacena el hash del bloque anterior. Esto significa que si alguien modifica el Bloque 1, su hash cambia, y el Bloque 2 todavía apunta al hash viejo del Bloque 1. La cadena se "rompe".

### 3. Inmutabilidad
Para alterar un bloque sin ser detectado, tendrías que recalcular los hashes de TODOS los bloques siguientes. En una blockchain real con miles de nodos verificando, esto es computacionalmente inviable.

## ¿Cómo usar la Demo?

1. Abrir `index.html` en cualquier navegador moderno
2. Agregar bloques con el botón "Agregar Bloque"
3. **Editar los datos** de cualquier bloque existente (el textarea es editable)
4. Observar cómo los bloques siguientes se marcan como **inválidos** (rojo)

### ¿Qué demuestra?
- Al editar un bloque, su hash se recalcula
- Los bloques siguientes aún apuntan al hash viejo → cadena rota
- Esto es exactamente lo que hace blockchain resistente a manipulaciones

## Arquitectura de la Demo

```
index.html        → Estructura de la página
styles.css        → Estilos visuales (dark theme)
blockchain.js     → Lógica completa de la blockchain
```

### Clase `Block`
```javascript
class Block {
  index          // Posición en la cadena (0, 1, 2...)
  timestamp      // Momento de creación
  data           // Contenido del bloque (texto libre)
  previousHash   // Hash del bloque anterior
  hash           // Hash propio (SHA-256)
}
```

### Flujo de la aplicación
```
Usuario escribe datos → Clic "Agregar Bloque"
  → Se crea Block con previousHash = hash del último bloque
  → Se calcula hash SHA-256 del nuevo bloque
  → Se renderiza la cadena completa

Usuario edita datos de un bloque existente
  → Se recalcula el hash de ese bloque
  → Los bloques siguientes detectan que previousHash ≠ hash real del anterior
  → Se marcan como inválidos (rojo)
```

## Blockchain en el Mundo Real — ¿Qué más tiene?

Esta demo cubre los fundamentos. Una blockchain de producción agrega:

| Concepto | Qué es | ¿Lo tiene la demo? |
|----------|--------|:-------------------:|
| Hashing | Huella digital de cada bloque | ✅ |
| Encadenamiento | Cada bloque referencia al anterior | ✅ |
| Inmutabilidad | Detectar alteraciones | ✅ |
| Proof of Work | Minado: encontrar un hash que cumpla condiciones | ❌ |
| Red P2P | Múltiples nodos con copias de la cadena | ❌ |
| Consenso | Acuerdo entre nodos sobre cuál cadena es válida | ❌ |
| Transacciones firmadas | Criptografía de llave pública/privada | ❌ |
| Smart Contracts | Código que se ejecuta automáticamente | ❌ |

## Posibles Aplicaciones Empresariales

Áreas donde blockchain puede aportar valor:

1. **Trazabilidad de materiales**: Rastrear el origen y recorrido de materias primas desde el proveedor hasta la planta
2. **Certificados de calidad**: Registro inmutable de resultados de pruebas de laboratorio
3. **Cadena de suministro**: Visibilidad compartida entre proveedores, logística y planta
4. **Auditoría de procesos**: Log inmutable de aprobaciones y cambios en documentos críticos
5. **Contratos con proveedores**: Smart contracts para automatizar pagos al cumplir condiciones

## Glosario Rápido

| Término | Definición |
|---------|-----------|
| **Hash** | Función que convierte datos en una cadena fija de caracteres. Cualquier cambio en los datos produce un hash completamente diferente |
| **Bloque Génesis** | El primer bloque de la cadena. No tiene bloque anterior (previousHash = "0") |
| **Nonce** | Número que los mineros varían para encontrar un hash válido (no incluido en esta demo) |
| **Proof of Work** | Mecanismo que requiere trabajo computacional para agregar bloques, evitando spam |
| **Nodo** | Una computadora que mantiene una copia de la blockchain y valida transacciones |
| **Consenso** | Protocolo por el cual los nodos acuerdan cuál es la versión correcta de la cadena |
| **Smart Contract** | Programa almacenado en la blockchain que se ejecuta automáticamente al cumplirse condiciones |
| **SHA-256** | Algoritmo de hashing usado en Bitcoin. Produce hashes de 256 bits (64 caracteres hexadecimales) |

## Próximos Pasos Sugeridos

Si el equipo quiere profundizar:

1. **Agregar Proof of Work a esta demo** — Hacer que el hash deba empezar con "00" para ser válido, y agregar un campo "nonce" que se incremente hasta lograrlo
2. **Simular transacciones** — En vez de texto libre, usar un formato estructurado (emisor, receptor, monto)
3. **Evaluar plataformas enterprise** — Hyperledger Fabric o Ethereum privado para casos de uso internos
4. **Definir un caso de uso piloto** — Elegir un proceso real y evaluar si blockchain agrega valor vs. una base de datos tradicional

---

*Documento creado como material de aprendizaje interno. Demo funcional en `index.html`.*
