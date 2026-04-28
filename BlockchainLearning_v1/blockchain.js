// ============================================================
// blockchain.js — Motor de blockchain didáctico
// Usa la Web Crypto API (SHA-256) para calcular hashes reales.
// ============================================================

class Block {
  constructor(index, timestamp, data, previousHash = '0') {
    this.index = index;
    this.timestamp = timestamp;
    this.data = data;
    this.previousHash = previousHash;
    this.hash = ''; // se calcula de forma asíncrona
  }

  /** Calcula el hash SHA-256 del contenido del bloque */
  async calculateHash() {
    const content = this.index + this.timestamp + this.data + this.previousHash;
    const encoder = new TextEncoder();
    const buffer = await crypto.subtle.digest('SHA-256', encoder.encode(content));
    const hashArray = Array.from(new Uint8Array(buffer));
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }
}

// ---- Estado global de la cadena ----
let chain = [];

/** Crea el bloque génesis (el primero de la cadena) */
async function createGenesisBlock() {
  const genesis = new Block(0, Date.now(), 'Bloque Génesis — Inicio de la cadena', '0');
  genesis.hash = await genesis.calculateHash();
  return genesis;
}

/** Inicializa la cadena con el bloque génesis */
async function initChain() {
  chain = [await createGenesisBlock()];
  await renderChain();
}

/** Agrega un nuevo bloque con los datos del input */
async function addBlock() {
  const input = document.getElementById('blockData');
  const data = input.value.trim();
  if (!data) return;

  const prevBlock = chain[chain.length - 1];
  const newBlock = new Block(chain.length, Date.now(), data, prevBlock.hash);
  newBlock.hash = await newBlock.calculateHash();
  chain.push(newBlock);

  input.value = '';
  await renderChain();
}

/** Reinicia la cadena al estado inicial */
async function resetChain() {
  await initChain();
}

/** Recalcula hashes y valida toda la cadena */
async function validateChain() {
  // El génesis siempre recalcula su propio hash
  chain[0].hash = await chain[0].calculateHash();

  for (let i = 1; i < chain.length; i++) {
    chain[i].hash = await chain[i].calculateHash();
  }
}

/** Verifica si un bloque es válido respecto a su hash y al hash anterior */
async function isBlockValid(block, index) {
  const recalculated = await block.calculateHash();
  if (block.hash !== recalculated) return false;
  if (index > 0 && block.previousHash !== chain[index - 1].hash) return false;
  return true;
}

/** Renderiza toda la cadena en el DOM */
async function renderChain() {
  await validateChain();

  const container = document.getElementById('blockchain');
  container.innerHTML = '';

  for (let i = 0; i < chain.length; i++) {
    const block = chain[i];
    const valid = await isBlockValid(block, i);

    // Flecha entre bloques
    if (i > 0) {
      const arrow = document.createElement('div');
      arrow.className = 'chain-arrow';
      arrow.textContent = '→';
      container.appendChild(arrow);
    }

    const blockEl = document.createElement('div');
    blockEl.className = `block ${valid ? 'valid' : 'invalid'}`;
    blockEl.innerHTML = `
      <div class="block-header">
        <span class="block-index">Bloque #${block.index}</span>
        <span class="block-status ${valid ? 'valid' : 'invalid'}">
          ${valid ? '✅ Válido' : '❌ Inválido'}
        </span>
      </div>

      <div class="block-field">
        <label>Timestamp</label>
        <div class="value">${new Date(block.timestamp).toLocaleString()}</div>
      </div>

      <div class="block-field">
        <label>Datos (editable — ¡prueba cambiar algo!)</label>
        <textarea oninput="onBlockDataChange(${i}, this.value)">${block.data}</textarea>
      </div>

      <div class="block-field">
        <label>Hash anterior</label>
        <div class="value">${block.previousHash}</div>
      </div>

      <div class="block-field">
        <label>Hash de este bloque</label>
        <div class="value" style="color: ${valid ? '#4ade80' : '#f87171'}">${block.hash}</div>
      </div>
    `;

    container.appendChild(blockEl);
  }
}

/** Callback cuando el usuario edita los datos de un bloque */
async function onBlockDataChange(index, newData) {
  chain[index].data = newData;
  // Recalcular hash del bloque editado (esto rompe la cadena hacia adelante)
  chain[index].hash = await chain[index].calculateHash();
  await renderChain();
}

// ---- Arranque ----
initChain();
