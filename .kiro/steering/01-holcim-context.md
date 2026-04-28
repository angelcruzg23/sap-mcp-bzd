# Amrize BP — Contexto del Sistema SAP

## Empresa
- **Amrize BP** (anteriormente Holcim BP) — fabricante de materiales de construcción
- Procesos críticos: gestión de pedidos de venta, producción de cemento, logística
- Equipo multinacional (documentación bilingüe ES/EN es frecuente)

## Sistemas SAP

### BZD (Desarrollo principal)
- SAP ECC 6.0 EHP8 (cliente 130)
- Servidor: fbpl08v010.holcimbp.net:8000
- Versión ABAP: 7.5 SP19
- NO estamos en S/4HANA — evitar sintaxis exclusiva de S/4 o ABAP Cloud
- CTS Project Management ACTIVO — las OTs deben crearse manualmente en SE09 y asignarse al proyecto CTS correspondiente. La API REST de ADT no soporta creación de OTs con proyecto CTS.

### BZN (Sandbox/Pruebas)
- SAP ECC 6.0 EHP8 (cliente 100)
- Servidor: lfh02a09ld075.holcimbp.net:8040
- Disponible vía MCP con usuario AHERNA11

## Contexto EHP8
- El upgrade a EHP8 ha sido causa raíz de varios bugs en producción:
  - SAPconnect ahora asigna SCOMNO inmediatamente al transmitir (antes era posterior)
  - Authority checks más estrictos en FMs estándar como MD_STOCK_REQUIREMENTS_LIST_API
  - Cambios en comportamiento de VBUK/VBUP (preparación para S/4HANA)
- Patrón validado: usar TVARVC como switch de fecha para proteger comportamiento legacy

## Módulos principales en uso
- SD (Ventas), MM (Materiales), FI (Finanzas), PP (Producción), WM (Almacén)
- Integración CRM ↔ ECC (módulo CRM_DOWNLOAD, BTMBDOC)
- Integración Salesforce ↔ SAP vía Mulesoft (FMs RFC-enabled)

## Herramientas de desarrollo
- **Kiro + MCP Server** — IDE principal con conexión directa a SAP vía ADT REST API
  - MCP Server en Python (server.py + sap_client.py) — asset vivo que crece con cada caso
  - Capacidades: leer/escribir programas, includes, FMs, clases; activar objetos; buscar en repositorio; ejecutar ABAP Unit; crear OTs
- **Eclipse ADT** — para operaciones que el MCP aún no soporta
- **SAP GUI** — para transacciones de configuración (STVARV, SE09, SWPR, etc.)

## Paquetes de desarrollo en uso
- `ZSD_SF` — desarrollos SD para integración Salesforce/Mulesoft
- `ZDEV_SD` — desarrollos generales del módulo SD
- `$TMP` — solo para POCs y pruebas locales (nunca para código productivo)
