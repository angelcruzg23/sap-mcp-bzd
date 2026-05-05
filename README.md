# 🚀 Kiro SAP ABAP Power

**Framework completo de Kiro para desarrollo SAP ABAP en Amrize BP**

Conecta Kiro directamente con SAP para leer/escribir código, gestionar transportes, y aplicar mejores prácticas automáticamente.

---

## 🎯 ¿Qué es esto?

Un **instalador único** que configura todo lo necesario para trabajar con SAP ABAP desde Kiro:

- ✅ **MCP Servers** — Conexión directa a SAP BZD y BZN
- ✅ **Steering Files** — Contexto, convenciones y estándares del equipo
- ✅ **Skills** — Tareas del día a día (transportes, tests, refactoring)
- ✅ **Hooks** — Validaciones automáticas (sintaxis, transportes)
- ✅ **Templates** — Código ABAP reutilizable (clases, DAOs, FMs)

---

## ⚡ Quick Start

### ¿Primera vez? ¿No tienes Python ni Git?

**Opcion 1: Instalador Todo-en-Uno (Mas Rapido)**

```powershell
# Descarga el proyecto (ZIP desde GitHub o Git)
cd C:\Users\TU_USUARIO\sap-mcp-bzd

# Ejecuta el instalador completo
.\install-complete.ps1 -SAPUser "TU_USUARIO_SAP"
```

Este instalador hara TODO automaticamente:
- ✅ Instalar Python 3.12 (si falta)
- ✅ Instalar Git (si falta)
- ✅ Configurar MCP servers
- ✅ Copiar steering files, skills, hooks
- ✅ Verificar conexion a SAP

**Opcion 2: Instalador de Prerequisitos Solamente**

```powershell
.\install-prerequisites.ps1
```

**Opcion 3: Guia Paso a Paso**

👉 Lee: [GUIA_INSTALACION_DESDE_CERO.md](GUIA_INSTALACION_DESDE_CERO.md)

---

### Ya tienes Python 3.10+ y Git? (5 minutos)

### 1. Clonar el repositorio

```powershell
cd C:\Users\$env:USERNAME
git clone https://gitlab.amrize.com/sap/kiro-sap-abap-power.git
cd kiro-sap-abap-power
```

### 2. Ejecutar el instalador

```powershell
.\install.ps1 -SAPUser "TU_USUARIO_SAP"
```

**Ejemplo:**
```powershell
.\install.ps1 -SAPUser "AHERNA11"
```

### 3. Reiniciar Kiro

Cerrar y abrir Kiro nuevamente.

### 4. Verificar

En Kiro, escribe:
```
Verifica la conexión con SAP BZD
```

**¡Listo!** Ya puedes trabajar con SAP desde Kiro.

---

## 📚 Documentación

- **[GUIA_INSTALACION_DESDE_CERO.md](GUIA_INSTALACION_DESDE_CERO.md)** — Para usuarios sin Python ni Git
- **[QUICK_START.md](QUICK_START.md)** — Instalación en 5 minutos
- **[ONBOARDING_NUEVO_DESARROLLADOR.md](ONBOARDING_NUEVO_DESARROLLADOR.md)** — Guía completa paso a paso
- **[General/APLICACION_KIROPOWERS_A_SAP_ABAP.md](General/APLICACION_KIROPOWERS_A_SAP_ABAP.md)** — Análisis del framework

---

## 🛠️ Capacidades

### Leer/Escribir Código ABAP
```
Lee el código del programa ZR_SD_QUICK_ORDERS
```

### Gestionar Transportes
```
Lista mis órdenes de transporte abiertas
Crea una OT de tipo Workbench con descripción "L2C:CHG0436752 - Fix"
```

### Buscar en Repositorio
```
Busca todas las clases que empiecen con ZCL_SD_
Muestra la definición de la tabla VBAK
```

### Validar Código
```
Ejecuta syntax check del programa ZR_SD_QUICK_ORDERS
Activa el programa ZR_SD_QUICK_ORDERS
```

### Aplicar Mejores Prácticas
```
#solid-refactoring
Refactoriza esta clase para seguir el patrón DAO
```

---

## 🎓 Skills Disponibles

Activa con `#nombre-del-skill` en el chat:

- `#sap-mcp-capabilities` — Documentación completa de herramientas SAP
- `#solid-refactoring` — Guía de refactoring a patrones SOLID
- `#transport-management` — Gestión de órdenes de transporte
- `#abap-unit-testing` — Crear tests unitarios

---

## 🪝 Hooks Automáticos

Se ejecutan automáticamente:

- **Syntax Check Pre-Upload** — Valida sintaxis antes de subir código
- **Transport Validation** — Verifica que hay OT válida
- **ABAP Unit After Upload** — Ejecuta tests después de activar
- **Code Review Checklist** — Recuerda checklist de revisión

---

## 🖥️ Sistemas SAP Conectados

| Sistema | Descripción | Host | Cliente |
|---------|-------------|------|---------|
| **BZD** | Desarrollo principal | `fbpl08v010.holcimbp.net:8000` | 130 |
| **BZN** | Sandbox / Pruebas | `lfh02a09ld075.holcimbp.net:8040` | 100 |

Ambos sistemas: SAP ECC 6.0 EHP8 con ABAP 7.5

---

## 🔧 Herramientas Disponibles (19 por sistema)

### Lectura
- `sap_ping` — Verifica conectividad
- `sap_get_program_source` — Código de programa/report
- `sap_get_class_source` — Código de clase ABAP OO
- `sap_get_function_module_source` — Código de Function Module
- `sap_get_include_source` — Código de INCLUDE
- `sap_search_objects` — Busca objetos Z*/Y*
- `sap_get_table_definition` — Definición de tabla
- `sap_check_adt_capabilities` — Servicios ADT disponibles
- `sap_test_endpoint` — Prueba endpoint ADT

### Escritura
- `sap_create_program` — Crea programa nuevo
- `sap_update_program_source` — Actualiza programa
- `sap_update_program_from_file` — Actualiza desde archivo
- `sap_update_function_module_source` — Actualiza FM

### Activación y Validación
- `sap_activate_object` — Activa objeto ABAP
- `sap_syntax_check` — Syntax check
- `sap_run_abap_unit` — ABAP Unit tests

### Transportes
- `sap_create_transport` — Crea orden de transporte
- `sap_list_transports` — Lista OTs abiertas
- `sap_get_transport_details` — Detalle de OT

---

## 📊 Resultados Esperados

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Tiempo de onboarding | 10 días | 2 días | 80% |
| Setup de ambiente | 4 horas | 15 min | 94% |
| Errores de sintaxis | 30% | 5% | 83% |
| Tiempo de deploy | 30 min | 5 min | 83% |
| Cobertura de tests | 20% | 60% | 200% |

---

## 🔍 Troubleshooting

### Verificar instalación
```powershell
.\verify-installation.ps1
```

### MCP Server en rojo
```powershell
# Verificar que Python puede ejecutar el server
python server.py
```

### Reinstalar
```powershell
.\install.ps1 -SAPUser "TU_USUARIO_SAP"
```

### Documentación completa
Ver: [ONBOARDING_NUEVO_DESARROLLADOR.md](ONBOARDING_NUEVO_DESARROLLADOR.md)

---

## 📁 Estructura del Proyecto

```
kiro-sap-abap-power/
├── install.ps1                    ← Instalador automático
├── verify-installation.ps1        ← Script de verificación
├── server.py                      ← MCP Server (multi-sistema)
├── sap_client.py                  ← Cliente HTTP para SAP ADT
├── requirements.txt               ← Dependencias Python
├── QUICK_START.md                 ← Guía rápida
├── ONBOARDING_NUEVO_DESARROLLADOR.md  ← Guía completa
├── .kiro/
│   ├── steering/                  ← Reglas y estándares
│   ├── skills/                    ← Tareas reutilizables
│   ├── hooks/                     ← Automatizaciones
│   └── settings/                  ← Configuración MCP
├── templates/                     ← Templates ABAP
└── SAP/                           ← Proyectos y documentación
```

---

## 🤝 Contribuir

Este framework está en constante evolución. Para contribuir:

1. Crea una rama con tu mejora
2. Documenta los cambios
3. Crea un Merge Request
4. El equipo revisará y aprobará

---

## 📞 Soporte

- **Documentación:** Ver archivos `.md` en el repositorio
- **Equipo SAP:** Canal de Teams/Slack
- **Creador:** Ángel Cruz

---

## 📝 Versión

**v1.0.0** — 2026-05-04

Basado en el framework **kiroPowers** del equipo de Infraestructura (Luis Jose FONTALVO).

---

## 🎉 Créditos

- **Concepto kiroPowers:** Luis Jose FONTALVO (Infraestructura Americas)
- **Adaptación SAP ABAP:** Ángel Cruz (Equipo SAP)
- **Equipo SAP ABAP:** Amrize BP

---

**¿Nuevo en el equipo?** Empieza con [QUICK_START.md](QUICK_START.md)
