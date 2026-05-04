# Análisis: Activación de SAP Fiori Launchpad en BZD 130

**Sistema:** SAP ECC 6.0 EHP8 — BZD (cliente 130)  
**NetWeaver:** 7.50 SP19  
**Fecha de análisis:** 2026-04-27  
**Objetivo:** Activar el Fiori Launchpad por primera vez en el landscape de desarrollo

---

## 1. Estado Actual del Sistema (verificado vía MCP/ADT)

### Endpoints HTTP probados

| Endpoint | Status | Interpretación |
|----------|--------|----------------|
| `/sap/bc/ui2/flp` | 403 | Nodo ICF existe pero requiere autenticación/autorización |
| `/sap/bc/ui5_ui5/ui2/ushell/shells/abap/FioriLaunchpad.html` | 403 | URL clásica del FLP — nodo existe, no accesible |
| `/sap/opu/odata/UI2/PAGE_BUILDER_PERS` | 403 | Servicio OData del FLP — existe pero sin acceso |
| `/sap/opu/odata/UI2/INTEROP` | 403 | Servicio de interoperabilidad — existe |
| `/sap/public/bc/ui2/logon` | 403 | Pantalla de logon del FLP — existe |
| `/sap/public/bc/ui5_ui5` | 403 | Librería UI5 — existe |
| `/sap/opu/odata/sap/ESH_SEARCH_SRV` | 403 | Enterprise Search — existe |
| `/sap/bc/bsp/sap/ui2` | 404 | BSP application ui2 — **NO existe** |

### Tablas del diccionario

| Tabla | Status | Interpretación |
|-------|--------|----------------|
| `/UI2/CHIP` | 404 (no existe) | Tabla de chips del FLP — **componente UI2 no accesible vía ADT** |
| `/UI2/PAGE_PERS` | 404 (no existe) | Personalización de páginas FLP — **no accesible** |

### Objetos Z de Fiori

| Búsqueda | Resultado |
|----------|-----------|
| `ZFIORI*` | 0 objetos |
| `ZUI5*` | 0 objetos |

### Conclusión del estado actual

Los nodos ICF principales del Fiori Launchpad **existen** en el sistema (responden 403, no 404), lo que indica que los software components de Fiori (SAP_UI, UI_INFRA, SAP_GW) probablemente **ya están instalados** como parte del EHP8. Sin embargo:

- Los servicios no están accesibles (posiblemente desactivados en SICF o sin autorización)
- No hay desarrollo Z custom de Fiori
- Las tablas /UI2/* no son accesibles vía ADT (puede ser limitación del endpoint ADT para namespaces con `/`)
- La BSP application `ui2` no existe como tal (es normal, el FLP usa ICF directo)

---

## 2. Arquitectura de Deployment Recomendada

Para ECC 6.0 EHP8, hay dos opciones de deployment:

| Opción | Descripción | Recomendación |
|--------|-------------|---------------|
| **Embedded** | FLP + Gateway + Backend en el mismo servidor | ✅ Recomendado para BZD |
| **Hub** | FLP + Gateway en servidor separado (SAP Fiori Front-End Server) | Para landscapes grandes con múltiples backends |

**Recomendación: Embedded Deployment** — es más simple, BZD ya tiene los componentes instalados con EHP8, y para un primer proyecto de Fiori es la opción más directa.

---

## 3. Prerequisitos de Software (verificar con Basis en SAP GUI)

### 3.1 Software Components — VERIFICADO ✅ (2026-04-27)

Datos obtenidos de CVERS en BZD 130:

| Componente | Descripción | Versión | SP | Status |
|------------|-------------|---------|-----|--------|
| `SAP_BASIS` | SAP Basis Component | 750 | SP32 | ✅ OK |
| `SAP_ABA` | Cross-Application Component | 750 | SP32 | ✅ OK |
| `SAP_GWFND` | SAP Gateway Foundation | 750 | SP32 | ✅ OK — suficiente para embedded |
| `SAP_UI` | User Interface Technology (SAPUI5) | 754 | SP17 | ✅ OK — versión excelente |
| `SAP_BS_FND` | SAP Business Suite Foundation | 748 | SP24 | ✅ OK |
| `SAP_AP` | SAP Application Platform | 750 | SP22 | ✅ OK |
| `UIBAS001` | UI for Basis Applications | 500 | SP12 | ✅ OK |
| `SAP_GW` | SAP Gateway Server | — | — | ❌ No instalado (no requerido para embedded) |
| `UI_INFRA` | UI Infrastructure | — | — | ℹ️ Integrado en SAP_UI 754 |

**Conclusión:** Todos los componentes necesarios para Fiori embedded deployment están instalados. No se requiere instalación adicional de software.

### 3.2 Business Functions (verificar en SFW5)

| Business Function | Descripción | Requerida |
|-------------------|-------------|-----------|
| `GW_DIRECT_OS_DEPLOYMENT` | Gateway Direct OS Deployment | Sí, para embedded |
| `UI_FRAMEWORK` | UI Framework | Sí |

> **Acción:** Verificar en transacción **SFW5** si estas business functions están activadas.

---

## 4. Plan de Activación — Paso a Paso

### Fase 1: Verificación de Prerequisitos (Basis + Funcional)

| # | Tarea | Transacción | Responsable | Status |
|---|-------|-------------|-------------|--------|
| 1.1 | Verificar software components en CVERS | `CVERS` | Basis | ✅ Completado |
| 1.2 | Verificar business functions en SFW5 | `SFW5` | Basis | ⬜ Pendiente |
| 1.3 | Verificar que ICM (Internet Communication Manager) está activo | `SMICM` | Basis | ⬜ Pendiente |
| 1.4 | Verificar parámetros de perfil HTTP/HTTPS | `RZ10` | Basis | ⬜ Pendiente |
| 1.5 | Verificar SAP Notes aplicadas (ver sección 6) | `SNOTE` | Basis | ⬜ Pendiente |

### Fase 2: Configuración del Gateway (STC01)

Ejecutar el task list combinado para embedded deployment:

| # | Tarea | Transacción | Detalle |
|---|-------|-------------|---------|
| 2.1 | Ejecutar task list `SAP_GW_FIORI_ERP_ONE_CLNT_SETUP` | `STC01` | Task list combinado que incluye: |
| | — `SAP_GATEWAY_BASIC_CONFIG` | | Activación básica del Gateway |
| | — `SAP_FIORI_LAUNCHPAD_INIT_SETUP` | | Setup inicial del FLP |
| | — `SAP_GATEWAY_ACTIVATE_ODATA_SERV` | | Activación de servicios OData |
| | — `SAP_BASIS_ACTIVATE_ICF_NODES` | | Activación de nodos ICF |

> **Nota:** Este task list es específico para embedded deployment (un solo cliente). Es el recomendado para BZD 130.

### Fase 3: Activación de Servicios ICF (SICF)

Verificar/activar manualmente si el task list no los activó todos:

| # | Nodo ICF | Path | Propósito |
|---|----------|------|-----------|
| 3.1 | `flp` | `/sap/bc/ui2/flp` | Fiori Launchpad principal |
| 3.2 | `FioriLaunchpad` | `/sap/bc/ui5_ui5/ui2/ushell/shells/abap/` | URL clásica del FLP |
| 3.3 | `ui5_ui5` | `/sap/bc/ui5_ui5/` | Librería SAPUI5 |
| 3.4 | `nwbc` | `/sap/bc/nwbc/` | NetWeaver Business Client (para SAP GUI for HTML) |

### Fase 4: Activación de Servicios OData Mandatorios

Activar en transacción `/IWFND/MAINT_SERVICE`:

| # | Servicio OData | Propósito |
|---|----------------|-----------|
| 4.1 | `PAGE_BUILDER_PERS` | Personalización del FLP |
| 4.2 | `PAGE_BUILDER_CONF` | Configuración de catálogos (cross-client) |
| 4.3 | `PAGE_BUILDER_CUST` | Customizing del FLP |
| 4.4 | `INTEROP` | Interoperabilidad entre apps |
| 4.5 | `TRANSPORT` | Transporte de configuración FLP |
| 4.6 | `CATALOGSERVICE` | Catálogo de servicios |

### Fase 5: Configuración del Fiori Launchpad Designer

| # | Tarea | Transacción | Detalle |
|---|-------|-------------|---------|
| 5.1 | Crear catálogo de prueba | `/UI2/FLPD_CUST` | FLP Designer (customizing) |
| 5.2 | Crear grupo de tiles | `/UI2/FLPD_CUST` | Agrupar tiles por área funcional |
| 5.3 | Asignar catálogo a rol | `PFCG` | Rol con catálogo Fiori |
| 5.4 | Probar acceso al FLP | Browser | `https://<host>:<port>/sap/bc/ui2/flp` |

### Fase 6: Configuración de Seguridad

| # | Tarea | Detalle |
|---|-------|---------|
| 6.1 | Crear rol `Z_FIORI_ADMIN` | Rol para administradores del FLP Designer |
| 6.2 | Crear rol `Z_FIORI_USER_BASE` | Rol base para usuarios Fiori |
| 6.3 | Configurar SSO (Single Sign-On) | Logon tickets entre componentes |
| 6.4 | Configurar CORS si aplica | Para acceso cross-origin |

---

## 5. Roles y Autorizaciones Clave

### Objetos de autorización para Fiori

| Objeto | Campo | Valor | Propósito |
|--------|-------|-------|-----------|
| `S_SERVICE` | `SRV_NAME` | `*` | Acceso a servicios ICF (restringir después) |
| `S_SERVICE` | `SRV_TYPE` | `HT` | Tipo HTTP |
| `S_START` | `AUTH_GROUP` | `*` | Inicio de transacciones vía FLP |
| `/UI2/PAGE` | | | Personalización de páginas FLP |

### Roles estándar SAP de referencia

| Rol | Propósito |
|-----|-----------|
| `SAP_FLP_USER` | Rol base para usuarios del FLP |
| `SAP_FLP_ADMIN` | Rol para administradores del FLP |
| `/UI2/SAP_ADMIN` | Administración de contenido UI2 |

---

## 6. SAP Notes Relevantes

| Nota | Descripción | Prioridad |
|------|-------------|-----------|
| **1793771** | Central SAP Note for SAP Fiori on SAP NetWeaver | 🔴 Crítica |
| **2aborar** | | |
| **2217498** | Fiori Launchpad: Collective corrections | 🔴 Crítica |
| **2526760** | SAP Fiori for SAP ERP: Central Note | 🟡 Alta |
| **1921163** | SAP Gateway: Central Note | 🟡 Alta |
| **2712785** | Rapid Activation for SAP Fiori (si aplica) | 🟡 Alta |

> **Acción:** Verificar en `SNOTE` cuáles de estas notas ya están aplicadas.

---

## 7. Checklist de Verificación Post-Activación

| # | Verificación | Cómo | Esperado |
|---|-------------|------|----------|
| 7.1 | FLP carga en browser | URL: `https://fbpl08v010.holcimbp.net:8000/sap/bc/ui2/flp` | Pantalla de login → FLP vacío |
| 7.2 | FLP Designer accesible | `/UI2/FLPD_CUST` en SAP GUI | Se abre el designer |
| 7.3 | Servicios OData responden | `/IWFND/GW_CLIENT` → probar `PAGE_BUILDER_PERS` | HTTP 200 con metadata |
| 7.4 | UI5 library carga | `https://<host>:<port>/sap/public/bc/ui5_ui5/resources/sap-ui-core.js` | JavaScript carga |
| 7.5 | Tile de prueba funciona | Crear tile manual en FLP Designer | Tile visible en FLP |

---

## 8. Riesgos y Consideraciones

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Software components faltantes | Bloqueante | Verificar CVERS antes de empezar |
| SAP Notes no aplicadas | Errores en runtime | Aplicar notas antes de configurar |
| Conflicto con servicios ICF existentes | Bajo | Los nodos ya existen (403), solo activar |
| Performance del ICM | Medio | Verificar parámetros de memoria en SMICM |
| Autorizaciones insuficientes | Medio | Crear roles antes de probar |

---

## 9. Próximos Pasos Inmediatos

1. **Reunión con Basis** — compartir este documento y pedir:
   - Output de `CVERS` (software components)
   - Output de `SFW5` (business functions activas)
   - Confirmación de que ICM está activo con HTTP/HTTPS
   
2. **Ejecutar task list** `SAP_GW_FIORI_ERP_ONE_CLNT_SETUP` en `STC01`

3. **Verificar acceso** al FLP después del task list

4. **Primer tile de prueba** — crear un tile que lance una transacción existente (ej: VA01)

---

## 10. Arquitectura Target

```
┌─────────────────────────────────────────────────────┐
│                    BZD 130 (ECC EHP8)               │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ SAP Gateway  │  │  SAPUI5 Lib  │  │  ICM/ICF  │ │
│  │ (SAP_GW)     │  │  (SAP_UI)    │  │  HTTP(S)  │ │
│  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘ │
│         │                 │                │        │
│  ┌──────┴─────────────────┴────────────────┴─────┐  │
│  │           Fiori Launchpad (FLP)                │  │
│  │  /sap/bc/ui2/flp                              │  │
│  │                                               │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐        │  │
│  │  │ Catalog │ │  Group  │ │  Tiles  │        │  │
│  │  │ (PFCG)  │ │         │ │         │        │  │
│  │  └─────────┘ └─────────┘ └─────────┘        │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │         OData Services (/IWFND/)              │  │
│  │  PAGE_BUILDER_PERS | PAGE_BUILDER_CONF        │  │
│  │  INTEROP | CATALOGSERVICE | TRANSPORT         │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │         Backend ECC (SD, MM, FI, PP...)       │  │
│  │         BAPIs, FMs, Clases OO                 │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘

Browser → HTTPS → ICM → ICF → FLP → OData → Backend
```

---

*Documento generado con Kiro + MCP Server — análisis automatizado del sistema BZD 130*
