---
name: sap-abap-amrize
displayName: SAP ABAP Development — Amrize BP
description: Kiro Power para desarrollo ABAP en SAP ECC 6.0 EHP8 (Amrize BP). Incluye conexión directa a SAP vía MCP, estándares de codificación, patrones SOLID validados en producción, y flujo de deploy controlado.
version: 1.0.0
author: Angel Cruz <angecruz@amrize.com>
keywords:
  - SAP
  - ABAP
  - ECC
  - EHP8
  - MCP
  - Amrize
  - SD
  - Salesforce
  - Mulesoft
  - transport
  - deploy
  - SOLID
  - OO
---

# SAP ABAP Development Power — Amrize BP

## ¿Qué incluye este Power?

Este Power configura Kiro para desarrollo ABAP profesional en el entorno SAP de Amrize BP (anteriormente Holcim BP). Bundlea tres componentes:

1. **MCP Server** — conexión directa a SAP BZD (desarrollo) y BZN (sandbox) vía ADT REST API
2. **Steering files** — guías de dominio cargadas según el contexto de la conversación
3. **Hooks** — automatizaciones para sincronización y validación

---

## Cuándo cargar cada steering file

El agente debe cargar el steering file relevante según el contexto de la tarea. No cargar todos a la vez — solo el que aplica.

| Situación | Steering file a cargar |
|-----------|----------------------|
| Primera interacción / contexto general del sistema | `01-amrize-context.md` |
| Crear o nombrar objetos ABAP (clases, FMs, programas, variables) | `02-naming-conventions.md` |
| Escribir código ABAP nuevo o revisar código existente | `03-coding-standards.md` |
| Diseñar arquitectura OO, clases, interfaces, tests | `04-solid-patterns.md` |
| Código que toca VBUK, VBUP, KONV, BSEG, o preparación S/4 | `05-s4hana-readiness.md` |
| Subir código a SAP, activar objetos, gestionar OTs | `06-sap-deploy-workflow.md` |
| Modificar o extender el MCP server (server.py, sap_client.py) | `07-mcp-server-python.md` |
| Escribir SELECTs a tablas de sistema (E070, TRDIR, TADIR, TFDIR) | `08-sap-system-tables.md` |

---

## Skills disponibles (activar con # en el chat)

| Skill | Cuándo usar |
|-------|-------------|
| `#sap-mcp-capabilities` | Verificar qué puede/no puede hacer el MCP antes de planificar |
| `#sap-incident-workflow` | Analizar un bug o incidente de producción paso a paso |
| `#sap-integration-patterns` | Diseñar integraciones SD↔Salesforce, CRM↔ECC, TMS↔SAP |
| `#abap-lessons-learned` | Consultar lecciones aprendidas en producción (EHP8, locks, etc.) |
| `#version-inventory` | Ver inventario de objetos custom y versiones del sistema |

---

## Hooks disponibles

| Hook | Tipo | Descripción |
|------|------|-------------|
| `sync-after-sap-write` | Automático (post-tool) | Guarda el código localmente después de cada escritura en SAP |
| `validate-before-deploy` | Automático (pre-tool) | Recuerda leer el baseline antes de escribir en SAP |
| `actualizar-github` | Manual (userTriggered) | Push de todos los cambios del workspace a GitHub |

---

## Sistemas SAP configurados

| Sistema | ID | Mandante | Uso |
|---------|----|----------|-----|
| BZD | Desarrollo | 130 | Sistema principal — código productivo |
| BZN | Sandbox | 100 | Pruebas y POCs |

**IMPORTANTE:** BZD tiene CTS Project Management activo. Las OTs deben crearse manualmente en SE09 antes de pedir a Kiro que suba código.

---

## Arquitectura de referencia del equipo

```
Salesforce → Mulesoft (RFC) → ZFM_* (fachada)
                                └─ ZCL_* (orquestador)
                                     ├─ ZIF_*_DAO → ZCL_*_DAO
                                     └─ ZIF_*_CHECKER → ZCL_*_CHECKER

Tests: ZCL_*_TEST con LCL_*_DOUBLE (test doubles locales)
```

Proyecto de referencia completo: `PowerSkillSapAmrize/SAP/ConsultaStockMaterial/`

---

## Flujo de deploy en 9 pasos

```
1. Crear OT en SE09 (con proyecto CTS correcto)
2. Dar el número de OT a Kiro
3. Kiro lee código actual de SAP (baseline)
4. Kiro genera código nuevo localmente
5. Revisar el diff
6. Kiro sube código a SAP con la OT
7. Kiro activa el objeto
8. Kiro ejecuta syntax check
9. Kiro lee código de vuelta para verificar
```

---

## Instalación

Ver `install/GUIA_INSTALACION.md` para instrucciones completas.

```powershell
# Instalación rápida
cd C:\Users\TU_USUARIO\sap-mcp-bzd
.\KiroPowers\install\install.ps1 -SAPUser "TU_USUARIO_SAP"
```
