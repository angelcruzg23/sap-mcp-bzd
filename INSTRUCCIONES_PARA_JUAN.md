# 🚀 Instrucciones para Juan - Configurar Kiro SAP ABAP Power

## Hola Juan,

Ya está todo listo para que configures Kiro y puedas trabajar con SAP desde el IDE. El proceso toma **10 minutos**.

---

## ✅ Prerequisitos

- [x] Kiro instalado y logueado ✅
- [ ] Python 3.8+ instalado (ver guía abajo si no lo tienes)
- [x] Credenciales de SAP ✅
- [x] Acceso a red corporativa ✅

---

## 🐍 Paso 0: Instalar Python (Si no lo tienes)

### Verificar si Python está instalado

Abre **PowerShell** y ejecuta:

```powershell
python --version
```

**Si ves algo como:** `Python 3.12.0` o `Python 3.11.x` → **¡Ya lo tienes! Salta al Paso 1**

**Si ves un error** → Sigue esta guía para instalarlo

---

### Opción 1: Instalación con winget (Recomendado - Windows 10/11)

**winget** es el gestor de paquetes oficial de Windows. Es la forma más rápida y limpia.

```powershell
# Instalar Python 3.12 (última versión estable)
winget install Python.Python.3.12

# Verificar instalación
python --version
```

**Resultado esperado:**
```
Python 3.12.x
```

**Si winget no está disponible:**
- Windows 10: Actualiza a la última versión
- Windows 11: Ya viene instalado

---

### Opción 2: Instalación con Chocolatey

Si tu empresa usa **Chocolatey** como gestor de paquetes:

```powershell
# Instalar Python
choco install python -y

# Verificar instalación
python --version
```

---

### Opción 3: Instalación Manual desde Microsoft Store

```powershell
# Abrir Microsoft Store directamente en Python
start ms-windows-store://pdp/?ProductId=9NCVDN91XZQP

# O buscar "Python 3.12" en Microsoft Store
```

**Ventajas:**
- ✅ Instalación automática
- ✅ Actualizaciones automáticas
- ✅ No requiere permisos de administrador

---

### Opción 4: Instalación Manual desde python.org

Si las opciones anteriores no funcionan:

```powershell
# Descargar el instalador
$url = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
$output = "$env:TEMP\python-installer.exe"
Invoke-WebRequest -Uri $url -OutFile $output

# Ejecutar instalador (modo silencioso)
Start-Process -FilePath $output -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1" -Wait

# Verificar instalación
python --version
```

**Importante:** Si instalas manualmente, asegúrate de marcar:
- ✅ "Add Python to PATH"
- ✅ "Install for all users" (si tienes permisos)

---

### Verificar que pip está instalado

```powershell
pip --version
```

**Resultado esperado:**
```
pip 23.x.x from C:\...\Python312\lib\site-packages\pip (python 3.12)
```

**Si pip no está disponible:**
```powershell
python -m ensurepip --upgrade
```

---

### Solución de Problemas Comunes

#### Problema: "python no se reconoce como comando"

**Solución:** Agregar Python al PATH manualmente

```powershell
# Encontrar dónde está instalado Python
Get-Command python | Select-Object -ExpandProperty Source

# Si no encuentra nada, buscar en ubicaciones comunes
Test-Path "C:\Python312\python.exe"
Test-Path "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python312\python.exe"
Test-Path "C:\Program Files\Python312\python.exe"

# Una vez encontrado, agregar al PATH (ejemplo)
$pythonPath = "C:\Python312"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$pythonPath;$pythonPath\Scripts", "User")

# Cerrar y abrir PowerShell nuevamente
```

#### Problema: "Necesito permisos de administrador"

**Solución:** Usar Microsoft Store (no requiere admin) o pedir a IT que instale Python

```powershell
# Opción Microsoft Store (sin admin)
start ms-windows-store://pdp/?ProductId=9NCVDN91XZQP
```

#### Problema: "Tengo Python 2.7 instalado"

**Solución:** Instalar Python 3.12 en paralelo

```powershell
# Python 2 y Python 3 pueden coexistir
# Usa 'python3' en lugar de 'python'
python3 --version

# O instala Python 3.12 con winget
winget install Python.Python.3.12
```

---

### Verificación Final

Una vez instalado Python, verifica que todo funciona:

```powershell
# Verificar Python
python --version

# Verificar pip
pip --version

# Instalar una librería de prueba
pip install requests

# Probar Python
python -c "import requests; print('Python funciona correctamente!')"
```

**Resultado esperado:**
```
Python 3.12.x
pip 23.x.x from ...
Collecting requests...
Successfully installed requests-2.31.0
Python funciona correctamente!
```

---

## ✅ Ahora sí, continúa con el Paso 1

Una vez que Python esté instalado y funcionando, continúa con la instalación del framework.

---

## 📦 Paso 1: Clonar el Repositorio

Abre **PowerShell** y ejecuta:

```powershell
# Navegar a tu carpeta de trabajo
cd C:\Users\$env:USERNAME

# Clonar el repositorio
git clone https://github.com/angelcruzg23/sap-mcp-bzd.git

# Entrar a la carpeta
cd sap-mcp-bzd
```

**Resultado esperado:**
```
Cloning into 'sap-mcp-bzd'...
remote: Enumerating objects: ...
remote: Counting objects: 100% ...
Receiving objects: 100% ...
Resolving deltas: 100% ...
```

---

## ⚙️ Paso 2: Ejecutar el Asistente de Configuración

Tienes **dos opciones** para configurar el framework:

### 🎯 Opción A: Asistente Interactivo (Recomendado)

El asistente te guía paso a paso con menús interactivos:

```powershell
.\setup-wizard.ps1
```

**Ventajas:**
- ✅ Interfaz guiada con menús
- ✅ Configurar múltiples sistemas a la vez
- ✅ Verificación automática de conexiones
- ✅ Configuración de preferencias

**Continúa con la sección 2.1 abajo** ⬇️

---

### ⚡ Opción B: Instalador Simple (Alternativa Rápida)

Si prefieres algo más directo o el wizard tiene problemas:

```powershell
.\install.ps1 -SAPUser "TU_USUARIO_SAP"
```

**Ventajas:**
- ✅ Más rápido (5 minutos)
- ✅ Sin menús interactivos
- ✅ Configura BZD automáticamente

**Desventajas:**
- ⚠️ Solo configura un sistema (BZD)
- ⚠️ No configura preferencias

**Si usas esta opción, salta al Paso 3** ⬇️

---

### 2.1 Información Personal (Solo Opción A)
```
Nombre completo: Juan Perez
Email corporativo: juan.perez@amrize.com
Equipo: [1] Business Envelope
```

### 2.2 Sistemas SAP

El asistente te mostrará los sistemas disponibles:
```
[1] BZD - Business Envelope (Development)
[2] DEV - Building Materials (Development)
[3] BZX - D2I Team (Development)
[4] BZN - Sandbox (All Teams)
```

**Para ti (Business Envelope):**
- Configura **BZD** (tu sistema principal)
- Opcionalmente configura **BZN** (sandbox para pruebas)

### 2.3 Credenciales

Para cada sistema que configures:
```
Usuario SAP para BZD: TU_USUARIO_SAP
Password SAP para BZD: ****
¿Usar como sistema por defecto? S
```

### 2.4 Preferencias
```
¿Activar objetos automáticamente? S
¿Ejecutar syntax check después de subir? S
¿Formatear código automáticamente? S
```

### 2.5 Verificación

El asistente verificará automáticamente la conexión a SAP:
```
Probando BZD...
  ✓ Conexión exitosa
```

**Tiempo total:** ~10 minutos

---

## 🔄 Paso 3: Reiniciar Kiro

1. **Cerrar Kiro completamente** (File → Exit o Alt+F4)
2. **Abrir Kiro nuevamente**
3. **Verificar panel lateral** — Deberías ver los MCP servers conectados (verde)

---

## ✅ Paso 4: Verificar que Funciona

En el chat de Kiro, escribe:

```
Verifica la conexión con SAP BZD
```

**Respuesta esperada:**
```
✅ Conexión exitosa con SAP BZD
- Host: fbpl08v010.holcimbp.net:8000
- Cliente: 130
- Usuario: TU_USUARIO
- Versión: ECC 6.0 EHP8
- ABAP: 7.5 SP19
```

---

## 🎯 Primeros Comandos para Probar

### 1. Leer código de un programa
```
Lee el código del programa ZR_SD_QUICK_ORDERS
```

### 2. Buscar objetos
```
Busca todos los programas que empiecen con ZR_SD_
```

### 3. Listar tus transportes
```
Lista mis órdenes de transporte abiertas
```

### 4. Ver capacidades disponibles
```
#sap-mcp-capabilities
```

### 5. Obtener ayuda con patrones SOLID
```
#solid-refactoring
```

---

## 🔧 Si Algo Sale Mal

### Problema 1: "MCP server no conecta"

**Solución:**
```powershell
# Verificar instalación
.\verify-installation.ps1

# Si hay errores, reconfigurar
.\setup-wizard.ps1
```

### Problema 2: "Password incorrecto"

**Solución:**
```powershell
# Actualizar credenciales
.\manage-credentials.ps1 update
```

### Problema 3: "No puedo conectarme a SAP"

**Verificar:**
1. ¿Estás en la red corporativa o VPN conectada?
2. ¿Tu usuario SAP está activo? (probar en SAP GUI)
3. ¿El servidor está disponible?

**Probar conexión manual:**
```powershell
Test-NetConnection fbpl08v010.holcimbp.net -Port 8000
```

### Problema 4: "Python no encontrado"

**Diagnóstico:**
```powershell
# Verificar Python
python --version

# Verificar pip
pip --version
```

**Solución Rápida:**
```powershell
# Opción 1: Instalar con winget (Recomendado)
winget install Python.Python.3.12

# Opción 2: Microsoft Store (sin permisos admin)
start ms-windows-store://pdp/?ProductId=9NCVDN91XZQP

# Opción 3: Chocolatey
choco install python -y
```

**Después de instalar:**
```powershell
# Cerrar y abrir PowerShell nuevamente
# Verificar instalación
python --version
pip --version
```

**Si sigue sin funcionar:**
Ver la guía completa de instalación de Python en el **Paso 0** arriba.

---

### Problema 5: "Error al instalar dependencias"

**Diagnóstico:**
```powershell
# Intentar instalar dependencias manualmente
pip install requests python-dotenv
```

**Soluciones:**

**Error: "pip no se reconoce"**
```powershell
# Usar python -m pip en lugar de pip
python -m pip install requests python-dotenv
```

**Error: "Permission denied"**
```powershell
# Instalar solo para el usuario actual
pip install --user requests python-dotenv
```

**Error: "SSL Certificate"**
```powershell
# Instalar sin verificar SSL (solo si estás detrás de proxy corporativo)
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org requests python-dotenv
```

---

### Problema 6: "El wizard tiene errores de sintaxis"

**Síntoma:**
```
Unexpected token '}' in expression or statement...
```

**Causa:** Problemas con emojis en PowerShell

**Solución:** Usar el instalador simple en lugar del wizard
```powershell
# En lugar de .\setup-wizard.ps1, usar:
.\install.ps1 -SAPUser "TU_USUARIO_SAP"
```

El instalador simple hace lo mismo pero sin interfaz interactiva.

---

## 📚 Documentación Disponible

Una vez configurado, tienes acceso a:

### Guías Rápidas
- `QUICK_START.md` — Esta guía
- `ONBOARDING_NUEVO_DESARROLLADOR.md` — Guía completa con troubleshooting

### Documentación Técnica
- `MULTI_SYSTEM_ARCHITECTURE.md` — Cómo funciona el sistema multi-sistema
- `MAINTAINER_GUIDE.md` — Para cuando quieras entender más a fondo

### Skills Disponibles (Activar con #)
- `#sap-mcp-capabilities` — Todas las herramientas SAP disponibles
- `#solid-refactoring` — Guía de refactoring a patrones SOLID
- `#transport-management` — Gestión de órdenes de transporte
- `#abap-unit-testing` — Crear tests unitarios

---

## 🎓 Recursos Adicionales

### Steering Files (Automáticos)
Estos se aplican automáticamente en todas tus conversaciones:
- Contexto de Amrize BP y sistemas SAP
- Convenciones de nomenclatura ABAP
- Estándares de codificación
- Patrones SOLID validados
- Workflow de deploy

### Hooks (Automáticos)
Validaciones que se ejecutan automáticamente:
- Syntax check antes de subir código
- Validación de orden de transporte
- Tests unitarios después de activar

### Templates ABAP
Código reutilizable en `templates/`:
- Clase OO con test unitario
- Patrón DAO
- FM RFC como fachada
- Report con ALV

---

## 💡 Consejos

1. **Usa el sistema por defecto** — No necesitas especificar BZD cada vez
2. **Activa skills cuando los necesites** — `#nombre-del-skill`
3. **Gestiona credenciales fácilmente** — `.\manage-credentials.ps1`
4. **Verifica instalación si hay problemas** — `.\verify-installation.ps1`

---

## 📞 Soporte

Si tienes problemas:

1. **Revisa la documentación** — `ONBOARDING_NUEVO_DESARROLLADOR.md`
2. **Ejecuta verificación** — `.\verify-installation.ps1`
3. **Pregunta en Teams** — Canal #kiro-sap-abap
4. **Contacta a Ángel** — angecruz@amrize.com

---

## 🎉 ¡Listo!

Una vez completados los pasos, tendrás:

✅ Conexión directa a SAP BZD desde Kiro  
✅ Capacidad de leer/escribir código ABAP  
✅ Gestión de órdenes de transporte  
✅ Validaciones automáticas de calidad  
✅ Acceso a mejores prácticas del equipo  
✅ Templates de código reutilizables  
✅ Skills contextuales disponibles  

**Tiempo total:** 10 minutos ⏱️  
**Tiempo ahorrado en el futuro:** 2+ horas por día 🚀

---

**¡Bienvenido al equipo de Kiro SAP ABAP Power!**

Si tienes feedback o sugerencias, compártelas con Ángel.

---

**Última actualización:** 2026-05-04  
**Versión:** 1.0.0  
**Creado por:** Ángel Cruz
