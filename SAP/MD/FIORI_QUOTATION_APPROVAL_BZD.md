# Fiori para Aprobación de Quotations en BZD (ECC EHP8)

## Diagnóstico del Sistema BZD — Resultados de la Investigación

### ✅ Lo que YA está instalado y funcionando

| Componente | Estado | Evidencia |
|---|---|---|
| **SAPUI5 Runtime** | ✅ Activo | Versión **1.71.75** detectada en `/sap/bc/adt/filestore/ui5-bsp/ui5-rt-version` |
| **SAP Gateway (IWBEP)** | ✅ Instalado | Paquete `IWBEP` con transacciones y componentes V4 detectados |
| **SAP Gateway Foundation (IWFND)** | ✅ Instalado | Paquete `IWFND_CORE` presente |
| **Fiori Launchpad (/UI2/FLP)** | ✅ Instalado | Clases `/UI2/CL_FLP_*`, transacción `/UI2/FLP`, BSP `/UI2/USHELL` presentes |
| **SAPUI5 Filestore (BSP)** | ✅ Activo | Endpoint ADT `filestore/ui5-bsp` disponible |
| **SAP GUI for HTML (WebGUI)** | ✅ Activo | `/sap/bc/gui/sap/its/webgui` responde HTTP 200 |
| **BOPF Framework** | ✅ Activo | Servicios ADT de Business Objects disponibles |
| **CDS Views (DDL Sources)** | ✅ Activo | Servicios ADT DDL disponibles |
| **Web Dynpro ABAP** | ✅ Activo | Servicios ADT WDY completos |
| **FPM (Floor Plan Manager)** | ✅ Activo | Endpoint ADT FPM disponible |
| **Objetos Z de Quotation** | ✅ Existen | FMs: `ZSD_QUOTATION_SALSFRC_CREATE/CHANGE/GET_SFID`, estructuras `ZSD_QUOTE_HEADER_S`, `ZSD_QUOTE_ITEM_S` |

### ⚠️ Lo que requiere verificación/activación (403 = servicio existe pero no autenticado vía ADT)

| Componente | Estado | Endpoint | Nota |
|---|---|---|---|
| **Fiori Launchpad URL** | ⚠️ 403 | `/sap/bc/ui2/flp` | Existe pero requiere activación en SICF o permisos |
| **OData Gateway Hub** | ⚠️ 403 | `/sap/opu/odata` | Existe pero requiere autenticación/activación SICF |
| **CATALOGSERVICE** | ⚠️ 403 | `/sap/opu/odata/IWFND/CATALOGSERVICE` | Service catalog del Gateway — necesita activación |
| **FLP Shell** | ⚠️ 403 | `/sap/bc/ui5_ui5/ui2/ushell/...` | Shell de Fiori Launchpad |
| **FLP Startup** | ⚠️ 403 | `/sap/bc/ui2/start_up` | Servicio de inicio del FLP |

> **Nota importante:** Los HTTP 403 no significan que no estén instalados — significan que el usuario técnico ADT no tiene autorización para esos servicios ICF. Es muy probable que con un usuario con rol `SAP_FLP_USER` estos endpoints respondan correctamente.

### ❌ Lo que NO se encontró

| Componente | Estado | Impacto |
|---|---|---|
| **Workflow para Quotations** | ❌ No existe | No hay objetos `*WORKFLOW*QUOT*` — hay que crear el workflow |
| **App Fiori estándar de Quotation Approval** | ❌ No existe como estándar en ECC | SAP no entrega una app Fiori estándar "Approve Sales Quotations" para ECC EHP8. Solo existe "Manage Sales Quotations" en S/4HANA |

---

## Plan de Habilitación — Qué se debe activar/configurar

### FASE 1: Infraestructura Fiori (Basis/Admin)

#### 1.1 Activar servicios ICF en SICF
Verificar y activar estos nodos en la transacción **SICF**:

```
/sap/bc/ui2/                          → Fiori Launchpad
/sap/bc/ui2/flp                       → FLP principal
/sap/bc/ui2/start_up                  → Startup services
/sap/bc/ui5_ui5/                      → SAPUI5 apps
/sap/bc/ui5_ui5/ui2/ushell/           → Unified Shell
/sap/opu/odata/                       → OData Gateway
/sap/opu/odata/IWFND/                 → Gateway Foundation services
/sap/opu/odata/sap/                   → SAP OData services
/sap/bc/bsp/sap/                      → BSP applications
/sap/public/bc/ui5_ui5/               → SAPUI5 public resources
/sap/public/bc/ui2/                   → UI2 public resources
```

#### 1.2 Configurar SAP Gateway Hub (Transacciones clave)
| Transacción | Propósito |
|---|---|
| `/IWFND/MAINT_SERVICE` | Registrar y activar servicios OData en el Gateway Hub |
| `/IWFND/GW_CLIENT` | Probar servicios OData |
| `/IWBEP/REG_SERVICE` | Registrar servicios OData en el backend |
| `/UI2/FLP` | Configurar Fiori Launchpad |
| `/UI2/FLPD_CUST` | Fiori Launchpad Designer (Customizing) |
| `/UI2/FLPD_CONF` | Fiori Launchpad Designer (Configuration) |
| `/UI2/SEMOBJ` | Definir Semantic Objects |

#### 1.3 Roles de autorización necesarios
| Rol | Propósito |
|---|---|
| `SAP_FLP_USER` | Acceso básico al Fiori Launchpad |
| `SAP_IWFND_RT_GW_USER` | Acceso runtime al Gateway |
| `/IWFND/RT_GW_USER` | Gateway runtime user |
| `SAP_UI2_USER_700` | Personalización del Launchpad |

### FASE 2: Workflow de Aprobación (Funcional/ABAP)

Como **no existe** una app Fiori estándar de "Approve Sales Quotations" para ECC, hay dos caminos:

#### Opción A: Workflow SAP + Inbox Fiori (RECOMENDADA)
Usar **SAP Business Workflow** con la app Fiori estándar **"My Inbox"** (app ID: F0862).

Pasos:
1. **Crear Workflow Template** (transacción `SWDD`)
   - Evento trigger: cambio de status en quotation (VBAK-VBTYP = 'B')
   - Steps: aprobación por manager, con escalamiento
   - Binding a Business Object `BUS2032` (Sales Quotation)

2. **Crear Task de decisión** (transacción `PFTC`)
   - Task type: Decision Task (TS)
   - Outcomes: Aprobar / Rechazar / Devolver
   - Agent determination: por jerarquía organizacional o regla

3. **Activar servicios OData para My Inbox**
   - Registrar en `/IWFND/MAINT_SERVICE`:
     - `TASKPROCESSING` (servicio de workflow items)
     - `WFSERVICE` (workflow service)
   - Activar en SICF: `/sap/opu/odata/IWPGW/TASKPROCESSING`

4. **Configurar tile en Fiori Launchpad**
   - Semantic Object: `WorkflowTask`
   - Action: `displayInbox`
   - Target: app My Inbox

#### Opción B: App Fiori Custom (más esfuerzo, más control)
Desarrollar una app SAPUI5 custom con:
- Servicio OData custom para leer/aprobar quotations
- UI con lista de quotations pendientes
- Detalle con datos de cabecera/posiciones
- Acciones: Aprobar, Rechazar, Comentar

### FASE 3: Servicio OData para Quotations (ABAP)

Independiente de la opción elegida, necesitarás un servicio OData. Crear en `SEGW`:

```
Nombre: ZSD_QUOTATION_APPROVAL_SRV
Entidades:
  - QuotationHeader (VBAK fields + status aprobación)
  - QuotationItem (VBAP fields)
  - ApprovalLog (tabla Z para historial)
  - ApprovalAction (para POST de aprobación/rechazo)
```

Tablas Z necesarias:
```
ZTAB_SD_QUOT_APPR     → Status de aprobación por quotation
ZTAB_SD_QUOT_APPR_LOG → Log de acciones de aprobación
```

---

## Checklist de Verificación con Basis

Solicitar al equipo Basis que verifique en BZD:

- [ ] **SICF**: ¿Están activos los nodos `/sap/bc/ui2/*` y `/sap/opu/odata/*`?
- [ ] **Software Components**: Verificar en `SPAM` que estén instalados:
  - `SAP_GWFND` (Gateway Foundation) — SP level
  - `SAP_UI` (UI Add-on) — debe ser ≥ 7.53 para SAPUI5 1.71
  - `UI_INFRA` (UI Infrastructure)
  - `SAP_BASIS` 753 o superior
- [ ] **Roles**: ¿Existe `SAP_FLP_USER` en el sistema?
- [ ] **FLP accesible**: Probar URL `http://fbpl08v010.holcimbp.net:8000/sap/bc/ui2/flp` con usuario de diálogo
- [ ] **Gateway Hub**: ¿Está configurado el system alias en `/IWFND/MAINT_SERVICE`?
- [ ] **Workflow Engine**: ¿Está activo? Verificar con transacción `SWU3` (Automatic Workflow Customizing)

---

## Resumen Ejecutivo

BZD tiene la **infraestructura base** para Fiori (SAPUI5 1.71, Gateway, FLP instalado). Lo que falta es:

1. **Activación y configuración** de servicios ICF/OData (trabajo de Basis)
2. **Roles de autorización** para usuarios Fiori
3. **Workflow de aprobación** para quotations (no existe estándar — hay que construirlo)
4. **Servicio OData** para exponer datos de quotation
5. **Tile en FLP** para la app de aprobación

La ruta más rápida es **Opción A**: Workflow SAP + My Inbox, porque reutiliza la app estándar de inbox y solo requiere configurar el workflow y el servicio OData backend.
