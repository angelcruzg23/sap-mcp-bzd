# Discovery — Tokenización de Activos Inmobiliarios en Colombia

> Fecha: 15 de abril de 2026
> Estado: Fase de investigación
> Objetivo: Evaluar la viabilidad de un modelo de tokenización inmobiliaria en Colombia y definir el alcance de un PoC

---

## 1. ¿Qué es la tokenización inmobiliaria?

La tokenización consiste en dividir un activo físico (edificio, local, lote) en fracciones digitales llamadas "tokens", registrados en una blockchain. Cada token representa una porción del valor del activo y otorga derechos económicos: participación en rentas y plusvalía, sin necesidad de adquirir la propiedad completa.

Es como comprar una parte de un inmueble sin comprar todo el edificio.

### Beneficios estratégicos

- **Democratización del acceso**: inversionistas pequeños y medianos participan en proyectos que antes eran exclusivos de fondos institucionales
- **Liquidez**: los tokens se intercambian en mercados secundarios, eliminando la espera de años o procesos notariales
- **Transparencia**: blockchain asegura trazabilidad total, reduce intermediación y simplifica la gestión de dividendos

### Casos de referencia en LATAM

| País | Caso | Detalle |
|------|------|---------|
| México | Mt Pelerin + desarrolladores locales | Fracciones de propiedades en Tulum y Cancún para inversionistas internacionales |
| Brasil | Housi + Mercado Bitcoin | Tokens respaldados por inmuebles residenciales, inversiones desde US$25 |
| Colombia | Fondos inmobiliarios explorando | Modelos para activos logísticos y comerciales en etapa temprana |

Fuente: [MTS Consultoría — Tokenización de activos inmobiliarios](https://mts.com.co/tokenizacion-de-activos-inmobiliarios/)

---

## 2. Marco legal en Colombia (abril 2026)

### Estado regulatorio actual

| Aspecto | Situación |
|---------|-----------|
| Legalidad de criptoactivos | Legales, pero no completamente regulados. No son moneda de curso legal |
| Clasificación tributaria | Activos intangibles para efectos fiscales (DIAN) |
| Sandbox SFC | Finalizó en 2023. La SFC revisa su enfoque para un marco formal |
| Reporte tributario | Resolución 000240 (dic 2025) — obligatorio desde año gravable 2026, primer reporte mayo 2027 |
| Proyecto de ley | PL 510/2025 busca regulación integral de criptoactivos |
| Tokens como valores | Si representan securities, requieren autorización previa de la SFC |

### Entidades reguladoras relevantes

| Entidad | Rol |
|---------|-----|
| Superfinanciera (SFC) | Supervisa entidades financieras. Prohíbe a entidades vigiladas intermediar con cripto. Evalúa si tokens son valores |
| DIAN | Tributación. Resolución 000240 exige reporte de transacciones cripto |
| UIAF | Antilavado (AML/CFT). Los PSCAs deben reportar operaciones sospechosas |
| Banco de la República | Ha declarado que cripto no es moneda ni divisa |
| Superintendencia de Sociedades | Exige sistemas AML para empresas que manejen activos virtuales |

### Riesgos legales identificados

1. **Incertidumbre jurídica**: no hay marco legal específico para tokenización de activos reales
2. **Riesgo de clasificación como valor**: si la SFC determina que el token es un valor, se requiere autorización y cumplimiento del mercado de valores
3. **Evolución regulatoria**: el PL 510/2025 puede cambiar las reglas del juego
4. **Reporte obligatorio DIAN**: transacciones superiores a $50,000 USD deben reportarse con datos detallados del usuario

### Estrategia legal recomendada para el PoC

- Estructurar como **participación económica en una SAS (SPV)**, no como emisión de valores
- El SPV (Sociedad por Acciones Simplificada) es dueña del inmueble y emite tokens que representan derechos económicos
- Cumplir proactivamente con reporte UIAF y DIAN
- Contratar asesoría legal especializada en fintech/blockchain colombiana
- Monitorear activamente el PL 510/2025

Fuentes: [metlabs.io](https://metlabs.io/en/blockchain-regulation-colombia/), [lightspark.com](https://lightspark.com/knowledge/is-crypto-legal-in-colombia), [ainvest.com](https://www.ainvest.com/news/investment-implications-colombia-crypto-tax-regime-2601/)

---

## 3. Modelo de negocio propuesto

```
INVERSIONISTA ──► Compra tokens (fracciones) ──► Recibe derechos económicos
                                                    │
ACTIVO INMOBILIARIO ◄── SPV (SAS colombiana) ──────┘
(Ej: local comercial       que posee el activo
 en Bogotá, $500M COP)     y emite los tokens
```

### Flujo del inversionista

1. Se registra en la plataforma
2. Completa verificación KYC/AML
3. Deposita COP vía PSE o transferencia
4. Compra tokens del activo que elija
5. Recibe rentas proporcionales mensualmente
6. Puede vender tokens en mercado secundario

---

## 4. Requerimientos técnicos del PoC

### 4.1 Blockchain y Smart Contracts

| Componente | Decisión | Justificación |
|-----------|---------|---------------|
| Red | Polygon PoS (testnet Amoy para PoC) | Gas fees ~$0.01/tx, compatible EVM, amplia adopción |
| Token standard | ERC-3643 (T-REX) simplificado | Security token con compliance on-chain (KYC integrado) |
| Framework | Hardhat | Compilación, testing, deploy. Ecosistema maduro |
| Librerías | OpenZeppelin Contracts v5 | ERC20, AccessControl, ReentrancyGuard |
| Nodo RPC | Alchemy (free tier) | 300M compute units/mes gratis |

**¿Por qué ERC-3643 sobre ERC-1400?** ERC-3643 tiene compliance automático on-chain: solo wallets verificadas pueden recibir tokens. Esto es clave para cumplir con SFC y UIAF.

Contratos mínimos:

| Contrato | Responsabilidad |
|----------|----------------|
| PropertyToken.sol | Token ERC-20 con restricciones KYC |
| IdentityRegistry.sol | Registro de inversionistas verificados |
| ComplianceModule.sol | Reglas de transferencia (límites, restricciones) |
| RentDistributor.sol | Distribución proporcional de rentas |
| PropertyFactory.sol | Factory para tokenizar múltiples propiedades |

### 4.2 Backend API

| Componente | Tecnología |
|-----------|-----------|
| Runtime | Node.js 20 LTS |
| Framework | NestJS (TypeScript) |
| Base de datos | PostgreSQL + Prisma ORM |
| Blockchain | ethers.js v6 |
| Auth | JWT + refresh tokens |
| Cola de tareas | BullMQ + Redis |
| Storage | AWS S3 o MinIO |

Módulos: auth, users, properties, tokens, rent, payments, blockchain, kyc, notifications

### 4.3 Frontend (Marketplace)

| Componente | Tecnología |
|-----------|-----------|
| Framework | Next.js 14+ (App Router) |
| UI | Tailwind CSS + shadcn/ui |
| Wallet | wagmi + viem + WalletConnect |
| Charts | Recharts |
| Forms | React Hook Form + Zod |

Pantallas mínimas: landing, registro + KYC, login, catálogo de propiedades, detalle + compra, dashboard inversiones, panel admin

### 4.4 Integraciones externas

| Servicio | Proveedor | Costo PoC |
|---------|----------|----------|
| KYC/AML | Metamap (colombiano) | Free tier ~100 verificaciones |
| Pagos PSE | Wompi (Bancolombia) | Comisión por tx, sin costo fijo |
| RPC Blockchain | Alchemy | Free tier |
| Email | Resend o SendGrid | Free tier |
| Storage | Cloudinary o S3 | Free tier |

### 4.5 Infraestructura

| Componente | PoC (bajo costo) |
|-----------|-----------------|
| Backend | Railway o Render (free tier) |
| Frontend | Vercel (free tier) |
| Base de datos | Supabase PostgreSQL (free) |
| Redis | Upstash (free tier) |
| CI/CD | GitHub Actions |
| Monitoreo | Sentry (free tier) |
| Dominio | .com.co (~$15 USD/año) |

---

## 5. Alcance del PoC

### Incluido (MVP)

- Tokenización de 1 activo inmobiliario ficticio
- Registro de usuarios con KYC mock (simulado)
- Compra de tokens con pago simulado
- Dashboard de inversiones con rentas acumuladas
- Distribución de rentas proporcional on-chain
- Deploy en testnet Polygon Amoy
- Panel admin para crear propiedades y distribuir rentas

### Excluido del PoC (futuro)

- Mercado secundario (compra/venta entre usuarios)
- KYC real con proveedor
- Pagos reales PSE/Wompi
- Deploy en mainnet
- Múltiples activos simultáneos
- App móvil
- Integración con registros notariales

### Criterios de éxito del PoC

1. Un usuario puede registrarse, pasar KYC mock y comprar tokens de una propiedad
2. El smart contract refleja correctamente la propiedad fraccionada
3. Las rentas se distribuyen proporcionalmente a los holders
4. El dashboard muestra inversiones y rendimientos en tiempo real
5. Todo funciona end-to-end en testnet

---

## 6. Roadmap estimado

| Fase | Duración | Entregable |
|------|----------|-----------|
| 1. Diseño legal + estructura SPV | 2-3 semanas | Opinión legal, estructura societaria |
| 2. Smart Contracts | 2 semanas | Contratos en testnet, unit tests |
| 3. Backend + KYC | 3 semanas | API REST, integración KYC mock, lógica de compra |
| 4. Frontend marketplace | 2 semanas | UI completa para inversionistas |
| 5. Integración + demo | 1 semana | Demo end-to-end con activo ficticio |

**Total estimado: 10-11 semanas**

---

## 7. Equipo mínimo

| Rol | Dedicación | Perfil |
|-----|-----------|--------|
| Blockchain dev | 50% | Solidity, Hardhat, testing de contratos |
| Fullstack dev | 100% | NestJS + Next.js, integración APIs |
| Abogado fintech | Consultoría puntual | Estructura SPV, opinión regulatoria |
| Product / PM | 30% | Alcance, demo, pitch a inversionistas |

---

## 8. Estimación de costos

| Rubro | Costo estimado |
|-------|---------------|
| Infraestructura cloud (3 meses) | $0 - $150 USD (free tiers) |
| Dominio + SSL | ~$15 USD |
| Gas fees testnet | $0 |
| Gas fees mainnet (deploy futuro) | ~$5-10 USD (Polygon) |
| Asesoría legal | $2,000 - $5,000 USD |
| Desarrollo (equipo propio) | Tiempo del equipo |

---

## 9. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|-----------|
| Cambio regulatorio (PL 510/2025) | Alto | Monitoreo activo, estructura flexible |
| SFC clasifica token como valor | Alto | Estructurar como participación económica en SAS, no como security |
| Baja adopción / desconfianza | Medio | Empezar con inversionistas sofisticados, educación |
| Vulnerabilidad en smart contracts | Alto | Auditoría de contratos, uso de OpenZeppelin, tests exhaustivos |
| Complejidad de integración KYC + pagos | Medio | Usar proveedores colombianos (Metamap, Wompi) con APIs probadas |

---

## 10. Próximos pasos

- [ ] Validar estructura legal SPV con abogado fintech colombiano
- [ ] Definir el activo inmobiliario ficticio para el PoC (tipo, ubicación, valor)
- [ ] Configurar repositorio del proyecto con monorepo (contracts + backend + frontend)
- [ ] Desarrollar y testear smart contracts en testnet
- [ ] Diseñar wireframes del marketplace
- [ ] Preparar pitch deck para potenciales inversionistas o socios

---

> Documento generado como parte de la fase de Discovery.
> Fuentes principales: MTS Consultoría, metlabs.io, lightspark.com, ainvest.com, tokeny.com
