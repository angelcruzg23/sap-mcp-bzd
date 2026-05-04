# 🔧 Guía de Mantenimiento - Kiro SAP ABAP Power

## Para Ángel Cruz y Futuros Mantenedores

Esta guía explica cómo mantener, actualizar y dar soporte al framework Kiro SAP ABAP Power.

---

## 📚 Índice

1. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
2. [Componentes Clave](#componentes-clave)
3. [Flujo de Instalación](#flujo-de-instalación)
4. [Tareas de Mantenimiento](#tareas-de-mantenimiento)
5. [Agregar Nuevos Sistemas](#agregar-nuevos-sistemas)
6. [Actualizar Steering Files](#actualizar-steering-files)
7. [Crear Nuevos Skills](#crear-nuevos-skills)
8. [Agregar Hooks](#agregar-hooks)
9. [Troubleshooting Común](#troubleshooting-común)
10. [Versionado y Releases](#versionado-y-releases)

---

## 📁 Arquitectura del Proyecto

```
kiro-sap-abap-power/
├── 📄 Instalación y Configuración
│   ├── setup-wizard.ps1              # Asistente interactivo (PRINCIPAL)
│   ├── install.ps1                   # Instalador simple (legacy)
│   ├── verify-installation.ps1       # Verificación post-instalación
│   ├── manage-credentials.ps1        # Gestión de credenciales
│   ├── config-systems.json           # Catálogo de sistemas SAP
│   └── user-config.example.json      # Ejemplo de configuración personal
│
├── 🔌 MCP Server (Conexión a SAP)
│   ├── server.py                     # Servidor MCP multi-instancia
│   ├── sap_client.py                 # Cliente HTTP para SAP ADT API
│   └── requirements.txt              # Dependencias Python
│
├── 📖 Documentación
│   ├── README.md                     # Puerta de entrada
│   ├── QUICK_START.md                # Guía rápida (5-10 min)
│   ├── ONBOARDING_NUEVO_DESARROLLADOR.md  # Guía completa
│   ├── MULTI_SYSTEM_ARCHITECTURE.md  # Arquitectura multi-sistema
│   ├── MAINTAINER_GUIDE.md           # Esta guía
│   └── General/
│       ├── ANALISIS_FRAMEWORK_KIRO_SAP_ABAP.md
│       └── APLICACION_KIROPOWERS_A_SAP_ABAP.md
│
├── ⚙️ Framework Kiro
│   ├── .kiro/
│   │   ├── steering/                 # Reglas automáticas
│   │   │   ├── 01-holcim-context.md
│   │   │   ├── 02-naming-conventions.md
│   │   │   ├── 03-coding-standards.md
│   │   │   ├── 04-solid-patterns.md
│   │   │   └── 06-sap-deploy-workflow.md
│   │   ├── skills/                   # Capacidades reutilizables
│   │   │   ├── sap-mcp-capabilities.md
│   │   │   ├── solid-refactoring.md
│   │   │   ├── transport-management.md
│   │   │   └── abap-unit-testing.md
│   │   └── hooks/                    # Automatizaciones
│   │       ├── syntax-check-pre-upload.json
│   │       ├── transport-validation.json
│   │       └── abap-unit-after-upload.json
│   └── templates/                    # Templates ABAP
│       ├── class_with_test.abap
│       ├── dao_pattern.abap
│       └── rfc_facade.abap
│
└── 📂 Proyectos SAP (Ejemplos y Casos de Uso)
    └── SAP/
        ├── ConsultaStockMaterial/
        ├── L2C_CHG0436393/
        └── MD/
```

---

## 🔑 Componentes Clave

### 1. **setup-wizard.ps1** (Componente Principal)

**Propósito:** Asistente interactivo para configurar el framework.

**Funciones principales:**
- `Show-Banner()` — Muestra el banner del asistente
- `Get-AvailableSystems()` — Lee `config-systems.json`
- `Get-UserInfo()` — Solicita información del usuario
- `Configure-SAPSystem()` — Configura credenciales por sistema
- `Save-UserConfig()` — Guarda `user-config.json`
- `Set-EnvironmentVariables()` — Configura passwords en variables de entorno
- `Generate-MCPConfig()` — Genera `~/.kiro/settings/mcp.json`
- `Test-SystemConnections()` — Verifica conexiones a SAP
- `Copy-FrameworkFiles()` — Copia steering files, skills, hooks, templates

**Cuándo modificar:**
- Agregar nuevos pasos al asistente
- Cambiar flujo de configuración
- Agregar validaciones adicionales

**Cómo probar:**
```powershell
# Ejecutar en modo de prueba
.\setup-wizard.ps1

# Verificar archivos generados
Get-Content user-config.json
Get-Content $HOME\.kiro\settings\mcp.json
```

### 2. **config-systems.json** (Catálogo de Sistemas)

**Propósito:** Define todos los sistemas SAP disponibles en la organización.

**Estructura:**
```json
{
  "systems": {
    "SYSTEM_ID": {
      "name": "Nombre descriptivo",
      "host": "servidor.holcimbp.net",
      "port": "8000",
      "client": "130",
      "description": "Descripción del sistema",
      "team": "Equipo propietario",
      "default_package": "ZDEV_XX",
      "cts_project_management": true/false,
      "allow_tmp": true/false
    }
  }
}
```

**Cuándo modificar:**
- Agregar un nuevo sistema SAP
- Cambiar configuración de un sistema existente
- Actualizar host/puerto/cliente

**Cómo agregar un sistema:**
```json
"BZY": {
  "name": "BZY - Finance Team (Development)",
  "host": "servidor-bzy-finance.holcimbp.net",
  "port": "8000",
  "client": "300",
  "description": "Sistema de desarrollo para equipo Finance",
  "team": "Finance",
  "default_package": "ZDEV_FI",
  "cts_project_management": true,
  "allow_tmp": false
}
```

**Validar cambios:**
```powershell
# Verificar que el JSON es válido
Get-Content config-systems.json | ConvertFrom-Json

# Probar conexión al nuevo sistema
.\manage-credentials.ps1 test
```

### 3. **server.py** (MCP Server)

**Propósito:** Servidor MCP que expone herramientas SAP a Kiro.

**Características:**
- Multi-instancia (un proceso por sistema SAP)
- Diferenciación por `SAP_SYSTEM_ID`
- 19 herramientas por sistema

**Cuándo modificar:**
- Agregar nuevas herramientas MCP
- Cambiar lógica de conexión a SAP
- Agregar validaciones

**Estructura de una herramienta:**
```python
@server.call_tool()
async def sap_nueva_herramienta(
    arguments: dict
) -> list[types.TextContent | types.ImageContent | types.EmbeddedResource]:
    """
    Descripción de la herramienta.
    
    Args:
        param1: Descripción del parámetro
    """
    try:
        # Lógica de la herramienta
        result = sap_client.nueva_operacion(arguments)
        
        return [types.TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]
```

**Probar cambios:**
```powershell
# Ejecutar server manualmente
$env:SAP_PASSWORD = "tu_password"
$env:SAP_SYSTEM_ID = "BZD"
python server.py

# Verificar que Kiro puede conectarse
# (Reiniciar Kiro y verificar panel de MCP)
```

### 4. **Steering Files** (.kiro/steering/)

**Propósito:** Reglas y contexto que se incluyen automáticamente en todas las conversaciones.

**Archivos actuales:**
- `01-holcim-context.md` — Contexto de Amrize BP y sistemas SAP
- `02-naming-conventions.md` — Convenciones de nomenclatura ABAP
- `03-coding-standards.md` — Estándares de codificación
- `04-solid-patterns.md` — Patrones SOLID con ejemplos
- `06-sap-deploy-workflow.md` — Workflow de deploy

**Cuándo modificar:**
- Actualizar información de sistemas
- Agregar nuevos estándares de código
- Documentar lecciones aprendidas

**Estructura de un steering file:**
```markdown
---
# Front matter (opcional)
inclusion: auto  # auto | manual | fileMatch
---

# Título del Steering File

## Sección 1
Contenido...

## Sección 2
Contenido...
```

**Probar cambios:**
```powershell
# Copiar a ubicación de Kiro
Copy-Item -Path .\.kiro\steering\* -Destination $HOME\.kiro\steering\ -Force

# Reiniciar Kiro
# Verificar que el contexto se aplica en las respuestas
```

### 5. **Skills** (.kiro/skills/)

**Propósito:** Capacidades reutilizables que se activan con `#nombre-skill`.

**Archivos actuales:**
- `sap-mcp-capabilities.md` — Documentación de herramientas MCP
- `solid-refactoring.md` — Guía de refactoring
- `transport-management.md` — Gestión de transportes
- `abap-unit-testing.md` — Testing unitario

**Cuándo crear un nuevo skill:**
- Tarea repetitiva que requiere contexto específico
- Guía paso a paso para un proceso
- Documentación técnica que se consulta frecuentemente

**Estructura de un skill:**
```markdown
---
inclusion: manual
---

# Skill: Nombre del Skill

## Cuándo usar este skill
- Situación 1
- Situación 2

## Comandos disponibles

### Comando 1
```
Ejemplo de uso en Kiro
```

### Comando 2
```
Ejemplo de uso en Kiro
```

## Reglas importantes
1. Regla 1
2. Regla 2

## Workflow recomendado
1. Paso 1
2. Paso 2
```

**Probar cambios:**
```powershell
# Copiar a ubicación de Kiro
Copy-Item -Path .\.kiro\skills\* -Destination $HOME\.kiro\skills\ -Force

# En Kiro, activar el skill
#nombre-del-skill
```

### 6. **Hooks** (.kiro/hooks/)

**Propósito:** Automatizaciones que se ejecutan en eventos específicos.

**Archivos actuales:**
- `syntax-check-pre-upload.json` — Valida sintaxis antes de subir
- `transport-validation.json` — Verifica OT antes de subir
- `abap-unit-after-upload.json` — Ejecuta tests después de activar

**Cuándo crear un nuevo hook:**
- Validación que debe ejecutarse siempre
- Automatización de tarea repetitiva
- Recordatorio en momento específico

**Estructura de un hook:**
```json
{
  "name": "Nombre del Hook",
  "version": "1.0.0",
  "description": "Descripción de qué hace",
  "when": {
    "type": "preToolUse | postToolUse | fileEdited | etc.",
    "toolTypes": "regex pattern o categoría",
    "patterns": ["*.abap"]
  },
  "then": {
    "type": "askAgent | runCommand",
    "prompt": "Prompt para askAgent",
    "command": "comando para runCommand"
  }
}
```

**Eventos disponibles:**
- `fileEdited` — Cuando se guarda un archivo
- `fileCreated` — Cuando se crea un archivo
- `fileDeleted` — Cuando se elimina un archivo
- `userTriggered` — Cuando el usuario lo activa manualmente
- `promptSubmit` — Cuando se envía un mensaje
- `agentStop` — Cuando termina una ejecución
- `preToolUse` — Antes de ejecutar una herramienta
- `postToolUse` — Después de ejecutar una herramienta
- `preTaskExecution` — Antes de ejecutar una tarea de spec
- `postTaskExecution` — Después de ejecutar una tarea de spec

**Probar cambios:**
```powershell
# Copiar a ubicación de Kiro
Copy-Item -Path .\.kiro\hooks\* -Destination $HOME\.kiro\hooks\ -Force

# Reiniciar Kiro
# Ejecutar acción que dispara el hook
```

---

## 🔄 Tareas de Mantenimiento

### Tarea 1: Agregar un Nuevo Sistema SAP

**Escenario:** Se crea un nuevo sistema BZY para el equipo de Finance.

**Pasos:**

1. **Actualizar `config-systems.json`:**
```json
"BZY": {
  "name": "BZY - Finance Team (Development)",
  "host": "servidor-bzy-finance.holcimbp.net",
  "port": "8000",
  "client": "300",
  "description": "Sistema de desarrollo para equipo Finance",
  "team": "Finance",
  "default_package": "ZDEV_FI",
  "cts_project_management": true,
  "allow_tmp": false
}
```

2. **Validar el JSON:**
```powershell
Get-Content config-systems.json | ConvertFrom-Json
```

3. **Probar conexión:**
```powershell
# Crear un script de prueba
python -c "
import requests
from requests.auth import HTTPBasicAuth

response = requests.get(
    'http://servidor-bzy-finance.holcimbp.net:8000/sap/bc/adt/discovery',
    auth=HTTPBasicAuth('TU_USUARIO', 'TU_PASSWORD'),
    headers={'sap-client': '300'},
    timeout=10
)
print(f'Status: {response.status_code}')
"
```

4. **Commit y push:**
```powershell
git add config-systems.json
git commit -m "feat: Agregar sistema BZY para equipo Finance"
git push origin main
```

5. **Comunicar al equipo:**
```
📢 Nuevo sistema disponible: BZY (Finance)

Para configurarlo:
1. git pull
2. .\manage-credentials.ps1 add
3. Seleccionar BZY
4. Ingresar credenciales
```

### Tarea 2: Actualizar Steering Files

**Escenario:** Se aprendió una nueva lección en producción que debe documentarse.

**Pasos:**

1. **Editar el steering file correspondiente:**
```powershell
# Ejemplo: Agregar lección aprendida a coding-standards.md
code .\.kiro\steering\03-coding-standards.md
```

2. **Agregar la lección:**
```markdown
## LECCIONES APRENDIDAS

### Título de la lección (CHG0XXXXXX)
Descripción del problema y la solución...

```abap
" Código de ejemplo
```
```

3. **Probar localmente:**
```powershell
Copy-Item -Path .\.kiro\steering\03-coding-standards.md -Destination $HOME\.kiro\steering\ -Force
# Reiniciar Kiro y verificar
```

4. **Commit y push:**
```powershell
git add .\.kiro\steering\03-coding-standards.md
git commit -m "docs: Agregar lección aprendida CHG0XXXXXX"
git push origin main
```

### Tarea 3: Crear un Nuevo Skill

**Escenario:** El equipo necesita una guía para debugging en SAP.

**Pasos:**

1. **Crear el archivo:**
```powershell
New-Item -Path .\.kiro\skills\sap-debugging.md -ItemType File
```

2. **Escribir el contenido:**
```markdown
---
inclusion: manual
---

# Skill: Debugging en SAP

## Cuándo usar este skill
- Necesitas debuggear código ABAP
- Quieres entender el flujo de ejecución
- Buscas el origen de un error

## Técnicas de debugging

### 1. Breakpoints externos
```
Activa un breakpoint externo para el usuario AHERNA11
```

### 2. Watchpoints
```
Crea un watchpoint para la variable LV_VBELN
```

## Comandos útiles
- `/h` — Activar debugger
- `/hs` — Activar debugger en siguiente statement
- `/hx` — Desactivar breakpoints

## Workflow recomendado
1. Identificar el punto de entrada
2. Activar breakpoint externo
3. Ejecutar transacción
4. Analizar variables
5. Step through del código
```

3. **Probar:**
```powershell
Copy-Item -Path .\.kiro\skills\sap-debugging.md -Destination $HOME\.kiro\skills\ -Force
# En Kiro: #sap-debugging
```

4. **Commit y push:**
```powershell
git add .\.kiro\skills\sap-debugging.md
git commit -m "feat: Agregar skill de debugging SAP"
git push origin main
```

### Tarea 4: Agregar un Nuevo Hook

**Escenario:** Queremos recordar al desarrollador que documente cambios en el código.

**Pasos:**

1. **Crear el archivo:**
```powershell
New-Item -Path .\.kiro\hooks\documentation-reminder.json -ItemType File
```

2. **Escribir el contenido:**
```json
{
  "name": "Documentation Reminder",
  "version": "1.0.0",
  "description": "Recuerda documentar cambios en el código",
  "when": {
    "type": "postToolUse",
    "toolTypes": ".*update.*source.*"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Recuerda al desarrollador que debe: 1) Agregar comentarios ABAP Doc, 2) Actualizar documentación técnica si aplica, 3) Agregar el tag del CR (+CHG0XXXXXX)"
  }
}
```

3. **Probar:**
```powershell
Copy-Item -Path .\.kiro\hooks\documentation-reminder.json -Destination $HOME\.kiro\hooks\ -Force
# Reiniciar Kiro y probar subiendo código
```

4. **Commit y push:**
```powershell
git add .\.kiro\hooks\documentation-reminder.json
git commit -m "feat: Agregar hook de recordatorio de documentación"
git push origin main
```

### Tarea 5: Actualizar Dependencias Python

**Escenario:** Hay una nueva versión de `requests` con mejoras de seguridad.

**Pasos:**

1. **Actualizar `requirements.txt`:**
```
requests>=2.32.0
python-dotenv>=1.0.1
```

2. **Probar localmente:**
```powershell
pip install -r requirements.txt --upgrade
python server.py
# Verificar que funciona
```

3. **Commit y push:**
```powershell
git add requirements.txt
git commit -m "chore: Actualizar dependencias Python"
git push origin main
```

4. **Comunicar al equipo:**
```
📢 Actualización de dependencias

Ejecutar:
git pull
pip install -r requirements.txt --upgrade
```

---

## 🐛 Troubleshooting Común

### Problema 1: Usuario reporta "MCP server no conecta"

**Diagnóstico:**
```powershell
# 1. Verificar que Python funciona
python --version

# 2. Verificar dependencias
pip list | Select-String requests

# 3. Verificar variables de entorno
$env:SAP_PASSWORD_BZD

# 4. Verificar mcp.json
Get-Content $HOME\.kiro\settings\mcp.json

# 5. Probar server manualmente
$env:SAP_PASSWORD = "password"
$env:SAP_SYSTEM_ID = "BZD"
python server.py
```

**Soluciones:**
- Si falta Python: Instalar Python 3.8+
- Si faltan dependencias: `pip install -r requirements.txt`
- Si falta password: `.\manage-credentials.ps1 update`
- Si falta mcp.json: `.\setup-wizard.ps1`

### Problema 2: Usuario reporta "Password incorrecto"

**Diagnóstico:**
```powershell
# Verificar que el password es correcto en SAP GUI
# Probar conexión manual
python -c "
import requests
from requests.auth import HTTPBasicAuth
import os

response = requests.get(
    'http://fbpl08v010.holcimbp.net:8000/sap/bc/adt/discovery',
    auth=HTTPBasicAuth('USUARIO', os.environ.get('SAP_PASSWORD_BZD')),
    headers={'sap-client': '130'}
)
print(f'Status: {response.status_code}')
"
```

**Soluciones:**
- Actualizar password: `.\manage-credentials.ps1 update`
- Verificar que el usuario está desbloqueado en SAP
- Verificar que el usuario tiene permisos ADT

### Problema 3: Steering files no se aplican

**Diagnóstico:**
```powershell
# Verificar que los archivos existen
Get-ChildItem $HOME\.kiro\steering\

# Verificar contenido
Get-Content $HOME\.kiro\steering\01-holcim-context.md
```

**Soluciones:**
- Copiar archivos: `.\setup-wizard.ps1`
- Verificar front matter del archivo
- Reiniciar Kiro

### Problema 4: Hook no se ejecuta

**Diagnóstico:**
```powershell
# Verificar que el hook existe
Get-ChildItem $HOME\.kiro\hooks\

# Verificar sintaxis JSON
Get-Content $HOME\.kiro\hooks\syntax-check-pre-upload.json | ConvertFrom-Json
```

**Soluciones:**
- Verificar sintaxis JSON
- Verificar que el evento es correcto
- Verificar que el pattern coincide
- Reiniciar Kiro

---

## 📦 Versionado y Releases

### Semantic Versioning

Usamos [Semantic Versioning](https://semver.org/):
- **MAJOR** (1.0.0): Cambios incompatibles
- **MINOR** (0.1.0): Nueva funcionalidad compatible
- **PATCH** (0.0.1): Bug fixes

**Ejemplos:**
- `1.0.0` → `1.1.0`: Agregar nuevo sistema SAP
- `1.1.0` → `1.1.1`: Fix en setup-wizard.ps1
- `1.1.1` → `2.0.0`: Cambio en estructura de config-systems.json

### Crear un Release

**Pasos:**

1. **Actualizar versión:**
```powershell
# Actualizar en README.md
# Actualizar en setup-wizard.ps1 (banner)
```

2. **Crear CHANGELOG:**
```markdown
# Changelog

## [1.1.0] - 2026-05-04

### Added
- Nuevo sistema BZY para equipo Finance
- Skill de debugging SAP
- Hook de recordatorio de documentación

### Changed
- Mejorado asistente de configuración

### Fixed
- Bug en validación de passwords
```

3. **Commit y tag:**
```powershell
git add .
git commit -m "chore: Release v1.1.0"
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin main --tags
```

4. **Crear release en GitLab:**
- Ir a Repository → Tags
- Seleccionar el tag v1.1.0
- Click en "Create release"
- Agregar release notes del CHANGELOG

5. **Comunicar al equipo:**
```
📢 Nueva versión disponible: v1.1.0

Novedades:
- Nuevo sistema BZY
- Skill de debugging
- Hook de documentación

Para actualizar:
git pull
git checkout v1.1.0
.\setup-wizard.ps1
```

---

## 📊 Métricas de Salud del Proyecto

### Métricas a Monitorear

1. **Adopción:**
   - Número de desarrolladores usando el framework
   - Número de sistemas configurados por desarrollador
   - Frecuencia de uso (prompts por día)

2. **Calidad:**
   - Número de issues reportados
   - Tiempo promedio de resolución
   - Satisfacción del usuario (NPS)

3. **Mantenimiento:**
   - Frecuencia de actualizaciones
   - Número de sistemas SAP configurados
   - Número de steering files/skills/hooks

### Cómo Recopilar Métricas

**Encuesta trimestral:**
```
1. ¿Usas Kiro SAP ABAP Power? (Sí/No)
2. ¿Cuántos sistemas tienes configurados? (1-5)
3. ¿Con qué frecuencia lo usas? (Diario/Semanal/Mensual)
4. ¿Qué tan satisfecho estás? (1-10)
5. ¿Qué mejorarías?
```

**Logs de uso:**
```powershell
# Agregar logging básico en server.py
import logging
logging.info(f"Tool used: {tool_name} by {user}")
```

---

## 🎓 Recursos para Mantenedores

### Documentación Oficial

- **Kiro:** https://docs.kiro.ai
- **MCP Protocol:** https://modelcontextprotocol.io
- **SAP ADT API:** Documentación interna de SAP

### Comunidad

- **Canal de Teams:** #kiro-sap-abap
- **GitLab Issues:** Para reportar bugs
- **GitLab Wiki:** Para documentación adicional

### Contactos Clave

- **Creador:** Ángel Cruz (angecruz@amrize.com)
- **Equipo SAP:** Canal de Teams
- **Inspiración:** Luis Jose FONTALVO (kiroPowers original)

---

## ✅ Checklist de Mantenedor

### Semanal
- [ ] Revisar issues en GitLab
- [ ] Responder preguntas en Teams
- [ ] Verificar que los sistemas SAP están accesibles

### Mensual
- [ ] Actualizar dependencias Python
- [ ] Revisar y actualizar steering files
- [ ] Agregar lecciones aprendidas del mes

### Trimestral
- [ ] Encuesta de satisfacción al equipo
- [ ] Revisar métricas de adopción
- [ ] Planear nuevas funcionalidades
- [ ] Crear release si hay cambios significativos

### Anual
- [ ] Revisión completa de documentación
- [ ] Actualización de arquitectura si es necesario
- [ ] Presentación de resultados a management

---

## 🚀 Próximos Pasos

### Roadmap Sugerido

**v1.1.0 (Q2 2026)**
- [ ] Integración con ServiceNow
- [ ] Skill de performance optimization
- [ ] Dashboard de métricas de uso

**v1.2.0 (Q3 2026)**
- [ ] Soporte para S/4HANA
- [ ] Templates adicionales (WebDynpro, CDS Views)
- [ ] Integración con GitLab CI/CD

**v2.0.0 (Q4 2026)**
- [ ] Kiro Power empaquetado
- [ ] Marketplace interno
- [ ] Auto-actualización automática

---

## 📞 Soporte

Si tienes dudas sobre el mantenimiento del proyecto:

1. **Revisa esta guía** — La mayoría de tareas están documentadas
2. **Consulta la documentación** — README, QUICK_START, etc.
3. **Pregunta en Teams** — Canal #kiro-sap-abap
4. **Contacta a Ángel** — angecruz@amrize.com

---

**Última actualización:** 2026-05-04  
**Versión de la guía:** 1.0  
**Mantenedor actual:** Ángel Cruz
