# Guía: Ejecución del Task List para Fiori Launchpad en BZD 130

**Sistema:** BZD 130 (ECC 6.0 EHP8, NW 7.50 SP32)  
**Fecha:** 2026-04-27  
**Prerequisito:** Software components verificados ✅

---

## Componentes de Software — Verificación Completada

| Componente | Versión | SP | Status |
|---|---|---|---|
| SAP_BASIS | 750 | SP32 | ✅ |
| SAP_ABA | 750 | SP32 | ✅ |
| SAP_GWFND | 750 | SP32 | ✅ Gateway Foundation (suficiente para embedded) |
| SAP_UI | 754 | SP17 | ✅ SAPUI5 library incluida |
| SAP_BS_FND | 748 | SP24 | ✅ |

> `SAP_GW` (Gateway Server) no está instalado, pero NO es necesario para embedded deployment. `SAP_GWFND` cubre esa funcionalidad.

---

## Paso a Paso: Ejecución del Task List en STC01

### Paso 1 — Abrir STC01

1. Abrir SAP GUI → conectar a **BZD 130**
2. En el campo de transacción escribir: **`STC01`** → Enter
3. Se abre la pantalla "Task List Run" (Ejecución de Lista de Tareas)

### Paso 2 — Buscar el Task List

1. En el campo **"Task List"** escribir: **`SAP_GW_FIORI_ERP_ONE_CLNT_SETUP`**
2. Presionar **Enter** o el botón de búsqueda (F4)
3. Si el task list existe, se mostrará su descripción

> ⚠️ **Si el task list NO aparece:** puede que no esté disponible en esta versión. En ese caso, hay que ejecutar los 4 task lists individuales por separado (ver sección "Plan B" más abajo).

### Paso 3 — Generar una nueva ejecución

1. Click en botón **"Generate Task List Run"** (o icono de crear nuevo)
2. Se genera una instancia de ejecución con un ID único
3. El sistema muestra la lista de todas las tareas incluidas

### Paso 4 — Revisar las tareas antes de ejecutar

El task list combinado incluye estas sub-tareas (en orden):

```
┌─────────────────────────────────────────────────────────────┐
│  SAP_GW_FIORI_ERP_ONE_CLNT_SETUP                           │
│                                                             │
│  1. SAP_GATEWAY_BASIC_CONFIG                                │
│     ├─ Activar SAP Gateway                                  │
│     ├─ Configurar parámetros del Gateway                    │
│     └─ Verificar ICM activo                                 │
│                                                             │
│  2. SAP_FIORI_LAUNCHPAD_INIT_SETUP                          │
│     ├─ Activar servicios OData del FLP                      │
│     ├─ Activar nodos ICF del FLP                            │
│     └─ Configurar pantallas de logon/logoff                 │
│                                                             │
│  3. SAP_GATEWAY_ACTIVATE_ODATA_SERV                         │
│     ├─ Registrar servicios OData en /IWFND/MAINT_SERVICE    │
│     └─ Activar servicios: PAGE_BUILDER_*, INTEROP, etc.     │
│                                                             │
│  4. SAP_BASIS_ACTIVATE_ICF_NODES                            │
│     ├─ Activar nodos en SICF                                │
│     └─ /sap/bc/ui2/*, /sap/bc/ui5_ui5/*, /sap/opu/*       │
└─────────────────────────────────────────────────────────────┘
```

Para cada tarea verás un semáforo:
- 🟢 Verde = ya configurado / no requiere acción
- 🟡 Amarillo = requiere revisión manual
- 🔴 Rojo = requiere ejecución

### Paso 5 — Ejecutar las tareas

1. Seleccionar **todas las tareas** con status 🔴 o 🟡
2. Click en **"Execute"** (F8)
3. Algunas tareas pedirán input:

#### Inputs esperados durante la ejecución:

| Tarea | Input requerido | Qué poner |
|-------|----------------|-----------|
| Gateway Activation | System Alias | `LOCAL` (para embedded) |
| OData Service Registration | System Alias | `LOCAL` |
| ICF Node Activation | Confirmación | Confirmar activación |
| Customizing Request | Orden de transporte | Crear una nueva o usar existente |

> **Sobre la OT:** Para la configuración del task list, se puede usar una OT de customizing (tipo W). Crearla en SE09 antes de empezar, con descripción tipo: `"Fiori Launchpad initial setup BZD 130"`.

### Paso 6 — Verificar resultados

Después de ejecutar, cada tarea debe mostrar semáforo 🟢.

Si alguna queda en 🔴:
- Click en la tarea para ver el log de errores
- Los errores más comunes son:
  - **Autorización insuficiente** → necesitas perfil SAP_ALL o roles específicos de Basis
  - **Servicio ya activo** → no es error, es informativo
  - **RFC destination no existe** → para embedded no aplica (no hay RFC a otro sistema)

---

## Plan B: Ejecución Individual (si el task list combinado no existe)

Si `SAP_GW_FIORI_ERP_ONE_CLNT_SETUP` no está disponible, ejecutar en este orden:

### B.1 — Gateway Basic Config

```
Transacción: STC01
Task List:   SAP_GATEWAY_BASIC_CONFIG
```

Esto activa el SAP Gateway. Tareas principales:
- Activar el servicio Gateway
- Configurar el ICF handler para OData
- Verificar parámetros del sistema

### B.2 — Fiori Launchpad Init Setup

```
Transacción: STC01
Task List:   SAP_FIORI_LAUNCHPAD_INIT_SETUP
```

Esto configura el FLP. Tareas principales:
- Activar servicios OData del Launchpad (PAGE_BUILDER_PERS, PAGE_BUILDER_CONF, etc.)
- Activar nodos ICF del FLP (/sap/bc/ui2/flp, etc.)
- Configurar pantalla de logon del FLP

### B.3 — Activate OData Services

```
Transacción: STC01
Task List:   SAP_GATEWAY_ACTIVATE_ODATA_SERV
```

Registra los servicios OData necesarios en el Gateway.

### B.4 — Activate ICF Nodes

```
Transacción: STC01
Task List:   SAP_BASIS_ACTIVATE_ICF_NODES
```

Activa los nodos HTTP en SICF para UI5 y Fiori.

---

## Verificación Manual Post-Ejecución

### V.1 — Verificar Gateway activo

```
Transacción: /IWFND/GW_CLIENT
```
- Probar URL: `/sap/opu/odata/UI2/PAGE_BUILDER_PERS/$metadata`
- Debe devolver XML con la definición del servicio OData

### V.2 — Verificar nodos ICF activos

```
Transacción: SICF
```
Navegar y verificar que estos nodos estén activos (icono verde):

| Path | Nodo |
|------|------|
| `/sap/bc/ui2/` | `flp` |
| `/sap/bc/ui5_ui5/` | (todo el subárbol) |
| `/sap/opu/odata/` | `UI2` |
| `/sap/public/bc/` | `ui5_ui5` |

### V.3 — Verificar servicios OData registrados

```
Transacción: /IWFND/MAINT_SERVICE
```
Buscar y confirmar que existen estos servicios:

| Servicio Técnico | Alias | Propósito |
|-----------------|-------|-----------|
| `/UI2/PAGE_BUILDER_PERS` | `LOCAL` | Personalización FLP |
| `/UI2/PAGE_BUILDER_CONF` | `LOCAL` | Configuración catálogos |
| `/UI2/PAGE_BUILDER_CUST` | `LOCAL` | Customizing FLP |
| `/UI2/INTEROP` | `LOCAL` | Interoperabilidad |
| `/UI2/TRANSPORT` | `LOCAL` | Transporte config FLP |

### V.4 — Probar el FLP en browser

```
URL: https://fbpl08v010.holcimbp.net:8000/sap/bc/ui2/flp
```

Resultado esperado:
1. Pantalla de login SAP (usuario/password)
2. Después del login → Fiori Launchpad vacío (sin tiles)
3. Barra superior con búsqueda y menú de usuario

> Si da error 403 → problema de autorización del usuario
> Si da error 404 → nodo ICF no activado
> Si da error 500 → servicio OData con problema

---

## Autorizaciones Necesarias para Ejecutar STC01

El usuario que ejecute el task list necesita:

| Objeto de autorización | Descripción |
|----------------------|-------------|
| `S_ADMI_FCD` con valor `PADM` | Administración de task lists |
| `S_ICF_ADM` | Administración de nodos ICF |
| `S_SERVICE` | Administración de servicios |
| `S_DEVELOP` | Desarrollo (para registrar servicios) |

> En la práctica, el usuario de Basis con perfil **SAP_ALL** puede ejecutar todo sin problemas. Para DEV (BZD) esto es aceptable.

---

## Troubleshooting Común

| Problema | Causa probable | Solución |
|----------|---------------|----------|
| Task list no encontrado | Versión de SAP_GWFND muy antigua | Verificar SP de SAP_GWFND (tienen SP32, debería estar) |
| "Service already registered" | Servicio OData ya existe | No es error — ignorar |
| "ICF node already active" | Nodo ya activado | No es error — ignorar |
| FLP muestra pantalla en blanco | Cache del browser | Ctrl+Shift+Delete → limpiar cache → reintentar |
| FLP da error "CSRF token" | Problema de seguridad | Verificar parámetro `login/create_sso2_ticket = 2` en RZ10 |
| "No authorization" al abrir FLP | Falta rol Fiori al usuario | Asignar rol con S_SERVICE y /UI2/PAGE |

---

## Siguiente Paso Después del Task List

Una vez que el FLP carga correctamente en el browser:

1. **Crear un catálogo de prueba** → transacción `/UI2/FLPD_CUST`
2. **Crear un tile de prueba** → que lance VA01 (crear pedido de venta)
3. **Asignar catálogo a un rol** → en PFCG
4. **Documentar** → actualizar el análisis con los resultados

---

*Guía generada con Kiro — para ejecución por equipo Basis en BZD 130*
