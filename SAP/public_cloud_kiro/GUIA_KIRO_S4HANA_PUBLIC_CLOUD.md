# Guía: Kiro + S/4HANA Cloud Public Edition

## Contexto

Esta guía documenta cómo conectar Kiro (IDE con agente AI) a un sistema **SAP S/4HANA Cloud, Public Edition** usando un MCP Server que se comunica vía ADT REST API. Incluye los prerequisitos, configuración, archivos MCP necesarios y pruebas de validación.

> **Nota importante:** Esta guía asume que tienes un landscape 3-System (Development, Test, Production) con **Developer Extensibility** habilitada. Sin 3SL, no hay tenant de desarrollo y no puedes conectar ADT.

---

## 1. Diferencias clave: On-Premise (BZD) vs Public Cloud

| Aspecto | BZD (On-Premise ECC 6.0) | S/4HANA Cloud Public Edition |
|---|---|---|
| **Autenticación** | Basic Auth (usuario/password) | OAuth2 / JWT vía XSUAA (BTP) |
| **URL del sistema** | `http://servidor:8000` | `https://<tenant>.abap.<region>.hana.ondemand.com` |
| **Modelo de código** | ABAP clásico (Z*, PROG, FUGR) | ABAP Cloud (RAP, CDS, solo Released APIs) |
| **Objetos permitidos** | Cualquier Z* (programas, FMs, clases, includes) | Solo objetos ABAP Cloud: CDS Views, Behavior Definitions, Service Bindings, clases con language version "ABAP for Cloud Development" |
| **Transacciones** | SE09, SE38, SE80, STVARV | No existen — todo vía ADT o Fiori Launchpad |
| **Transporte** | OTs manuales en SE09 con CTS Project | Software Components + gCTS o ABAP Transport Management |
| **Paquetes** | Z* packages ($TMP, ZDEV_SD, etc.) | ZLOCAL (local) o paquetes dentro de Software Components |
| **APIs disponibles** | Acceso completo al stack ABAP | Solo [Released APIs](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENRELEASED_APIS.html) (C1/C0 contracts) |
| **ADT endpoints** | `/sap/bc/adt/*` completo | `/sap/bc/adt/*` disponible pero con restricciones de ABAP Cloud |

### Lo que NO puedes hacer en Public Cloud
- Crear programas clásicos (reports con `WRITE`, `SELECTION-SCREEN`)
- Crear Function Modules clásicos
- Crear includes
- Usar `SELECT` sobre tablas no released (ej: VBAK directamente — debes usar CDS views released)
- Usar BAPIs clásicas (BAPI_SALESORDER_CHANGE, etc.) — debes usar APIs released
- Acceder a SE38, SE80, SE09, SM30, STVARV

### Lo que SÍ puedes hacer
- Crear clases ABAP con language version "ABAP for Cloud Development"
- Crear CDS View Entities, Behavior Definitions, Service Definitions/Bindings
- Crear Business Object extensions (RAP extensibility)
- Usar ABAP Unit tests
- Leer/escribir código vía ADT REST API (con autenticación JWT)
- Activar objetos vía ADT
- Ejecutar syntax check y ATC checks

---

## 2. Prerequisitos

### 2.1 En el lado SAP (administrador del tenant)

1. **Landscape 3-System (3SL)** con Developer Extensibility habilitada
   - Referencia: [SAP S/4HANA Cloud Public Edition, Three-System Landscape](https://pages.community.sap.com/topics/s4hana-cloud/three-system-landscape)

2. **Business Role `SAP_BR_DEVELOPER`** asignada a tu usuario en el tenant de desarrollo (client 080)
   - Esta role habilita el acceso a ADT y al ABAP Environment

3. **Communication Arrangement para ADT** (si aplica)
   - En algunos tenants, los servicios ADT ya están habilitados por defecto
   - Verificar que `/sap/bc/adt/*` esté accesible

4. **Service Key de ABAP Environment** (para autenticación OAuth2/JWT)
   - Se obtiene desde el BTP Cockpit o desde el Fiori Launchpad del tenant de desarrollo

### 2.2 En tu máquina local

1. **Python 3.9+** con pip
2. **Kiro IDE** instalado
3. **Eclipse ADT** (recomendado para validación inicial de la conexión)
   - Descargar desde: [ABAP Development Tools](https://tools.hana.ondemand.com/#abap)
4. **Git** (para clonar el MCP server)

---

## 3. Opciones de MCP Server para Public Cloud

Existen dos MCP servers open-source con soporte para BTP/Public Cloud:

### Opción A: mcp-adt (Python) — RECOMENDADA
- **Repo:** [github.com/YahorNovik/mcp-adt](https://github.com/YahorNovik/mcp-adt)
- **Lenguaje:** Python
- **Auth BTP:** JWT nativo con utilidades para generar `.env` desde service keys
- **Ventaja:** Más cercano a nuestro MCP server actual (Python + ADT), facilita migración

### Opción B: mcp-abap-abap-adt-api (Node.js)
- **Repo:** [github.com/mario-andreschak/mcp-abap-abap-adt-api](https://github.com/mario-andreschak/mcp-abap-abap-adt-api)
- **Lenguaje:** Node.js (TypeScript)
- **Auth BTP:** Basic Auth (requiere adaptación para JWT)
- **Ventaja:** Más tools disponibles (lock, unlock, transport, write)

### Opción C: Adaptar nuestro MCP server actual (server.py + sap_client.py)
- Requiere agregar soporte OAuth2/JWT al `sap_client.py`
- Ver sección 7 de esta guía

---

## 4. Setup con mcp-adt (Opción A — Recomendada)

### 4.1 Clonar e instalar

```bash
git clone https://github.com/YahorNovik/mcp-adt.git
cd mcp-adt
python -m venv .venv

# Windows
.\.venv\Scripts\activate

# Linux/macOS
source .venv/bin/activate

pip install -r requirements.txt
```

### 4.2 Obtener el Service Key del tenant de desarrollo

**Opción 1: Desde BTP Cockpit**
1. Ir a BTP Cockpit → tu subaccount → Service Instances
2. Buscar la instancia de "ABAP Environment" o "abap"
3. Crear un Service Key si no existe
4. Descargar el JSON del service key

**Opción 2: Desde S/4HANA Cloud Fiori Launchpad**
1. Ir al Fiori Launchpad del tenant de desarrollo
2. App "Communication Arrangements" o "Maintain Communication Arrangements"
3. Buscar el arrangement para ADT

El service key tiene esta estructura:

```json
{
  "label": "abap-trial-service-broker",
  "credentials": {
    "url": "https://<tenant-id>.abap.<region>.hana.ondemand.com",
    "username": "DEVELOPER",
    "password": "user_password",
    "uaa": {
      "url": "https://<subdomain>.authentication.<region>.hana.ondemand.com",
      "clientid": "sb-<guid>!b<number>|abap-trial-service-broker!b<number>",
      "clientsecret": "<client_secret_value>"
    }
  }
}
```

### 4.3 Generar el archivo .env desde el service key

```bash
python btp_env_generator.py --service-key service-key.json --username tu-usuario@empresa.com --prompt-password
```

Esto genera un archivo `.env` con:

```env
SAP_AUTH_TYPE=jwt
SAP_URL=https://<tenant-id>.abap.<region>.hana.ondemand.com
SAP_JWT_TOKEN=eyJhbGciOiJSUzI1NiIsImp...
SAP_VERIFY_SSL=true
SAP_TIMEOUT_DEFAULT=45
```

### 4.4 Verificar la conexión

```bash
# Ejecutar test de conexión incluido
python test_btp_features.py
```

O usar los MCP tools directamente:
- `get_btp_connection_status_mcp()` — verifica configuración actual
- `parse_btp_service_key_mcp("service-key.json")` — analiza el service key

### 4.5 Configurar en Kiro (mcp.json)

Crear o editar `.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "sap-public-cloud": {
      "command": "python",
      "args": ["C:/ruta/completa/a/mcp-adt/mcp_server.py"],
      "env": {
        "SAP_AUTH_TYPE": "jwt",
        "SAP_URL": "https://<tenant-id>.abap.<region>.hana.ondemand.com",
        "SAP_JWT_TOKEN": "<tu-jwt-token>",
        "SAP_VERIFY_SSL": "true"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

> **Seguridad:** No commitear el JWT token al repositorio. Usar variables de entorno del sistema o un archivo `.env` local.

---

## 5. Setup con S/4HANA Cloud Public Edition (conexión directa ADT)

En S/4HANA Cloud Public Edition con 3SL, la conexión ADT es ligeramente diferente a BTP ABAP Environment standalone.

### 5.1 URL del tenant de desarrollo

La URL del tenant de desarrollo típicamente sigue este formato:
```
https://<tenant-id>.s4hana.ondemand.com
```

El client de desarrollo suele ser **080**.

### 5.2 Conexión desde Eclipse ADT (validación)

Antes de configurar el MCP server, valida la conexión desde Eclipse:

1. File → New → **ABAP Cloud Project**
2. Seleccionar **SAP S/4HANA Cloud ABAP Environment**
3. Ingresar la URL del tenant de desarrollo
4. Autenticarse con tu usuario de desarrollo
5. Verificar que puedes ver los paquetes y objetos

Si esto funciona, el MCP server también podrá conectarse.

### 5.3 Autenticación para MCP

Para S/4HANA Cloud Public Edition, la autenticación puede ser:

**Opción 1: Basic Auth (si está habilitado)**
```env
SAP_AUTH_TYPE=basic
SAP_URL=https://<tenant-id>.s4hana.ondemand.com
SAP_CLIENT=080
SAP_USER=TU_USUARIO
SAP_PASS=TU_PASSWORD
SAP_VERIFY_SSL=true
```

**Opción 2: JWT via XSUAA (recomendado)**
```env
SAP_AUTH_TYPE=jwt
SAP_URL=https://<tenant-id>.abap.<region>.hana.ondemand.com
SAP_JWT_TOKEN=<token>
SAP_VERIFY_SSL=true
```

---

## 6. Pruebas de validación post-conexión

Una vez configurado el MCP server y conectado a Kiro, ejecutar estas pruebas en orden:

### Test 1: Ping al sistema
```
→ Usar tool: sap_ping (o equivalente)
→ Esperado: respuesta exitosa con info del sistema
```

### Test 2: Buscar objetos en el repositorio
```
→ Usar tool: search_objects con query "ZCL_*" o "I_*"
→ Esperado: lista de objetos (en Public Cloud verás objetos I_* que son CDS views estándar released)
```

### Test 3: Leer código de una clase
```
→ Usar tool: get_class_source con una clase Z* que hayas creado
→ Esperado: código fuente ABAP Cloud de la clase
```

### Test 4: Leer definición de CDS View (si el MCP lo soporta)
```
→ Usar tool: get_cds_source (disponible en mcp-adt)
→ Probar con un CDS view released como I_BusinessPartner
→ Esperado: definición del CDS view
```

### Test 5: Verificar ADT capabilities
```
→ Usar tool: check_adt_capabilities
→ Esperado: lista de servicios ADT disponibles en el tenant
→ Comparar con BZD para identificar diferencias
```

### Test 6: Crear una clase de prueba (si tienes permisos de escritura)
```
→ Crear clase ZCL_TEST_KIRO_CONNECTION en paquete ZLOCAL
→ Con language version "ABAP for Cloud Development"
→ Activar y ejecutar syntax check
```

---

## 7. Adaptar nuestro MCP server actual (Opción C)

Si prefieres extender `server.py` + `sap_client.py` en lugar de usar un MCP server externo, estos son los cambios necesarios:

### 7.1 Agregar soporte OAuth2/JWT a sap_client.py

El flujo de autenticación JWT para BTP es:

1. Obtener token OAuth2 del endpoint XSUAA usando client credentials + usuario/password
2. Usar el JWT token en el header `Authorization: Bearer <token>` para cada request ADT
3. Renovar el token cuando expire

Ejemplo de obtención de token:

```python
import requests

def get_jwt_token(uaa_url, client_id, client_secret, username, password):
    """Obtiene JWT token via OAuth2 password grant desde XSUAA."""
    token_url = f"{uaa_url}/oauth/token"
    response = requests.post(
        token_url,
        data={
            "grant_type": "password",
            "username": username,
            "password": password,
        },
        auth=(client_id, client_secret),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    response.raise_for_status()
    return response.json()["access_token"]
```

### 7.2 Modificar SAPADTClient para dual auth

```python
class SAPADTClient:
    def __init__(self, host, client, username, password, secure=True,
                 auth_type="basic", jwt_token=None):
        self.auth_type = auth_type
        self.jwt_token = jwt_token
        # ... resto del constructor

    def _get_auth_headers(self):
        if self.auth_type == "jwt":
            return {"Authorization": f"Bearer {self.jwt_token}"}
        else:
            # Basic auth como actualmente
            return {}  # requests.auth.HTTPBasicAuth se maneja aparte
```

### 7.3 Agregar tools específicos de ABAP Cloud

Tools nuevos que serían útiles para Public Cloud:

| Tool | Descripción | Endpoint ADT |
|---|---|---|
| `sap_get_cds_source` | Leer CDS View Entity | `/sap/bc/adt/ddic/ddl/sources/<name>` |
| `sap_get_behavior_definition` | Leer Behavior Definition | `/sap/bc/adt/bo/behaviordefinitions/<name>/source/main` |
| `sap_get_service_definition` | Leer Service Definition | `/sap/bc/adt/businessservices/servicedefinitions/<name>/source/main` |
| `sap_get_service_binding` | Leer Service Binding | `/sap/bc/adt/businessservices/servicebindings/<name>` |
| `sap_run_atc_check` | Ejecutar ATC (ABAP Test Cockpit) | `/sap/bc/adt/atc/runs` |

---

## 8. Modelo de desarrollo en Public Cloud (RAP)

En Public Cloud, todo desarrollo sigue el **ABAP RESTful Application Programming Model (RAP)**:

```
CDS View Entity (modelo de datos)
  └─ Behavior Definition (lógica de negocio)
       └─ Behavior Implementation (clase ABAP Cloud)
            └─ Service Definition (qué exponer)
                 └─ Service Binding (cómo exponer: OData V2/V4, InA)
```

### Ejemplo mínimo de un objeto RAP

**CDS View Entity:**
```sql
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Custom Business Object'
define root view entity ZR_CustomObject
  as select from ztab_custom_object
{
  key object_id    as ObjectId,
      description  as Description,
      status       as Status,
      created_by   as CreatedBy,
      created_at   as CreatedAt
}
```

**Behavior Definition:**
```
managed implementation in class ZBP_R_CustomObject unique;
strict ( 2 );

define behavior for ZR_CustomObject alias CustomObject
persistent table ztab_custom_object
lock master
authorization master ( instance )
{
  create;
  update;
  delete;

  field ( readonly ) ObjectId, CreatedBy, CreatedAt;
  field ( mandatory ) Description;

  mapping for ztab_custom_object
  {
    ObjectId    = object_id;
    Description = description;
    Status      = status;
    CreatedBy   = created_by;
    CreatedAt   = created_at;
  }
}
```

---

## 9. Gestión de transportes en Public Cloud

En Public Cloud con 3SL, el transporte funciona diferente:

- **No hay SE09/SE10** — los transportes se gestionan desde el Fiori Launchpad
- App: **"Export Customizing Transports"** y **"Manage Software Components"**
- Los objetos de desarrollo se asignan a **Software Components**
- El transporte entre sistemas (DEV → TEST → PROD) es gestionado por SAP vía **ABAP Transport Management** o **gCTS**

### Flujo de deploy adaptado para Public Cloud

```
1. Desarrollador crea objetos en el tenant de desarrollo (client 080)
2. Kiro lee/escribe código vía ADT REST API con JWT auth
3. Kiro activa objetos y ejecuta syntax check + ATC
4. Desarrollador revisa en Eclipse ADT
5. Desarrollador libera el transporte desde Fiori Launchpad
6. SAP propaga automáticamente al tenant de test y producción
```

---

## 10. Limitaciones conocidas

1. **JWT tokens expiran** — típicamente cada 12 horas. Hay que regenerar el `.env` periódicamente o implementar refresh automático.

2. **No todos los endpoints ADT están disponibles** — algunos endpoints que funcionan en on-premise pueden no estar habilitados en Public Cloud.

3. **Restricción de Released APIs** — solo puedes usar APIs con release contract C1 (para ABAP Cloud). Consultar la [lista oficial de Released APIs](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENRELEASED_APIS.html).

4. **No puedes crear FMs, includes ni reports clásicos** — todo debe ser ABAP Cloud (clases, CDS, RAP).

5. **ATC es obligatorio** — el ABAP Test Cockpit valida que tu código cumple con las reglas de ABAP Cloud. Código que no pase ATC no se puede activar.

6. **Escritura de clases globales vía ADT REST API** — puede requerir endpoints específicos que no todos los MCP servers implementan aún.

---

## 11. Referencias oficiales

### Documentación SAP
- [SAP S/4HANA Cloud Public Edition — Three-System Landscape](https://pages.community.sap.com/topics/s4hana-cloud/three-system-landscape)
- [ABAP Cloud FAQ](https://community.sap.com/topics/abap/abap-cloud-faq)
- [Released APIs — ABAP Cloud](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENRELEASED_APIS.html)
- [ABAP Language Versions and Released APIs](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/abenabap_versions_and_apis.htm)
- [Setting up ABAP Environment in SAP BTP](https://learning.sap.com/learning-journey/setting-up-an-abap-environment-on-sap-btp)
- [Create Your First ABAP Console Application](https://developers.sap.com/tutorials/abap-environment-console-application..html)
- [ABAP Extensibility Guide — Clean Core](https://community.sap.com/t5/technology-blog-posts-by-sap/abap-extensibility-guide-clean-core-for-sap-s-4hana-cloud-august-2025/ba-p/14175399)
- [Developer Extensibility in S/4HANA Cloud Public](https://learning.sap.com/courses/implementing-sap-s-4hana-cloud-public-edition/using-developer-in-app-extensibility-in-sap-s-4hana-cloud-public-edition)
- [Transport Management in S/4HANA Cloud Public Edition 3SL](https://community.sap.com/t5/enterprise-resource-planning-blog-posts-by-sap/transport-management-in-sap-s-4hana-cloud-public-edition-3-system-landscape/ba-p/13625058)
- [Building External APIs in S/4HANA Cloud Public from ADT](https://community.sap.com/t5/enterprise-resource-planning-blog-posts-by-members/building-and-publishing-external-apis-in-sap-s-4hana-cloud-public-from-adt/ba-p/14114911)

### MCP Servers para SAP
- [mcp-adt (Python, con soporte BTP/JWT)](https://github.com/YahorNovik/mcp-adt) — **Recomendado para Public Cloud**
- [mcp-abap-abap-adt-api (Node.js)](https://github.com/mario-andreschak/mcp-abap-abap-adt-api)
- [BTP Integration Guide — mcp-adt](https://github.com/YahorNovik/mcp-adt/blob/main/doc/BTP_INTEGRATION_GUIDE.md)

### Tutoriales SAP
- [Create ABAP Cloud Project in ADT](https://developers.sap.com/tutorials/abap-environment-console-application..html)
- [Install ABAP Development Tools (ADT)](https://developers.sap.com/tutorials/abap-install-adt..html)
- [RAP Developer Extensibility](https://community.sap.com/t5/technology-blog-posts-by-members/rap-on-stack-developer-extensibility/ba-p/14017859)

### gCTS y Transport Management
- [Git-enabled Change and Transport System (gCTS)](https://support.sap.com/en/tools/software-logistics-tools/change-and-transport-system.html)
- [gCTS Configuration and Integration with GitHub](https://community.sap.com/t5/technology-blogs-by-members/gcts-configuration-and-integration-with-github/ba-p/13545617)

---

## 12. Checklist rápido

- [ ] Tengo un landscape 3SL con Developer Extensibility habilitada
- [ ] Mi usuario tiene el Business Role `SAP_BR_DEVELOPER`
- [ ] Puedo conectarme desde Eclipse ADT al tenant de desarrollo
- [ ] Tengo el service key JSON del ABAP Environment
- [ ] Instalé Python 3.9+ y cloné el MCP server (mcp-adt)
- [ ] Generé el `.env` con `btp_env_generator.py`
- [ ] Configuré `mcp.json` en Kiro
- [ ] El ping al sistema responde OK
- [ ] Puedo buscar objetos en el repositorio
- [ ] Puedo leer código fuente de una clase
- [ ] Puedo crear y activar un objeto de prueba
- [ ] El syntax check pasa sin errores

---

*Documento creado: Abril 2026*
*Basado en investigación de MCP servers open-source y documentación oficial SAP.*
*Contexto: Equipo Amrize BP — migración de workflow Kiro on-premise a Public Cloud.*
