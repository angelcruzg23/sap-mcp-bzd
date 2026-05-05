# Guia de Instalacion Desde Cero - Kiro SAP ABAP Power

## Para Usuarios Sin Python ni Git

Esta guia es para usuarios que instalan por primera vez y no tienen Python ni Git instalados.

---

## Paso 1: Descargar el Proyecto

### Opcion A: Sin Git (Recomendado para principiantes)

1. Ve a: https://github.com/angelcruzg23/sap-mcp-bzd
2. Click en el boton verde **"Code"**
3. Click en **"Download ZIP"**
4. Descomprime el archivo ZIP en una carpeta (ej: `C:\Users\TU_USUARIO\sap-mcp-bzd`)

### Opcion B: Con Git (si ya lo tienes instalado)

```powershell
git clone https://github.com/angelcruzg23/sap-mcp-bzd.git
cd sap-mcp-bzd
```

---

## Paso 2: Instalar Python 3.11 o 3.12

### Metodo 1: Instalador Automatico (Recomendado)

Abre **PowerShell** y ejecuta:

```powershell
# Navega a la carpeta del proyecto
cd C:\Users\TU_USUARIO\sap-mcp-bzd

# Ejecuta el instalador de prerequisitos
.\install-prerequisites.ps1
```

Este script instalara automaticamente:
- Python 3.12 (si no esta instalado)
- Git (si no esta instalado)

**Despues de instalar, cierra y abre PowerShell nuevamente antes de continuar.**

### Metodo 2: Instalador Todo-en-Uno (Mas Rapido)

Si quieres instalar prerequisitos Y configurar Kiro en un solo paso:

```powershell
# Navega a la carpeta del proyecto
cd C:\Users\TU_USUARIO\sap-mcp-bzd

# Ejecuta el instalador completo
.\install-complete.ps1 -SAPUser "TU_USUARIO_SAP"
```

Este script hara TODO automaticamente:
1. Instalar Python y Git (si faltan)
2. Instalar dependencias Python
3. Configurar MCP servers
4. Copiar steering files, skills, hooks
5. Verificar conexion a SAP

**Si usas este metodo, puedes saltar al Paso 5 (Reiniciar Kiro).**

### Metodo 3: Instalacion Manual de Python

#### Opcion 2.1: Con winget (Windows 10/11)

```powershell
# Instalar Python 3.12
winget install Python.Python.3.12

# Verificar instalacion
python --version
# Debe mostrar: Python 3.12.x
```

**IMPORTANTE:** Despues de instalar, cierra y abre PowerShell nuevamente.

#### Opcion 2.2: Microsoft Store (sin permisos de administrador)

1. Abre Microsoft Store
2. Busca "Python 3.12"
3. Click en "Obtener" o "Instalar"
4. Espera a que termine la instalacion

#### Opcion 2.3: Descarga Manual

1. Ve a: https://www.python.org/downloads/
2. Descarga Python 3.12.x (ultima version)
3. Ejecuta el instalador
4. **IMPORTANTE:** Marca la casilla "Add Python to PATH"
5. Click en "Install Now"

### Verificar Instalacion de Python

```powershell
# Verificar Python
python --version
# Debe mostrar: Python 3.10.x o superior

# Verificar pip
pip --version
# Debe mostrar: pip 23.x.x
```

**Si no funciona:**
- Cierra y abre PowerShell nuevamente
- Si sigue sin funcionar, reinicia tu computadora

---

## Paso 3: Instalar Git (Opcional pero Recomendado)

### Metodo 1: Con winget

```powershell
winget install Git.Git
```

### Metodo 2: Descarga Manual

1. Ve a: https://git-scm.com/download/win
2. Descarga el instalador
3. Ejecuta el instalador con opciones por defecto

### Verificar Instalacion de Git

```powershell
git --version
# Debe mostrar: git version 2.x.x
```

---

## Paso 4: Ejecutar el Instalador de Kiro

Una vez que tengas Python instalado:

```powershell
# Navega a la carpeta del proyecto
cd C:\Users\TU_USUARIO\sap-mcp-bzd

# Ejecuta el instalador
.\install.ps1 -SAPUser "TU_USUARIO_SAP"

# Ejemplo:
.\install.ps1 -SAPUser "JPEREZ"
```

El instalador te pedira:
1. **Password de SAP** - Se guardara de forma segura
2. Instalara dependencias Python automaticamente
3. Configurara los MCP servers
4. Copiara steering files, skills y hooks
5. Verificara la conexion a SAP

**Tiempo estimado:** 5-10 minutos

---

## Paso 5: Reiniciar Kiro

1. Cierra Kiro completamente (File → Exit o Alt+F4)
2. Abre Kiro nuevamente
3. Verifica que los MCP servers esten conectados (panel lateral)

---

## Paso 6: Probar la Conexion

En el chat de Kiro, escribe:

```
Verifica la conexion con SAP BZD
```

**Respuesta esperada:**
```
✅ Conexion exitosa con SAP BZD
- Host: fbpl08v010.holcimbp.net:8000
- Cliente: 130
- Usuario: TU_USUARIO
```

---

## Solucion de Problemas

### Problema 1: "python no se reconoce como comando"

**Solucion:**
1. Cierra y abre PowerShell nuevamente
2. Si persiste, reinicia tu computadora
3. Si aun no funciona, reinstala Python marcando "Add Python to PATH"

### Problema 2: "No puedo ejecutar scripts de PowerShell"

**Error:**
```
.\install.ps1 : No se puede cargar el archivo porque la ejecucion de scripts esta deshabilitada
```

**Solucion:**
```powershell
# Ejecuta como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Luego ejecuta el instalador nuevamente
.\install.ps1 -SAPUser "TU_USUARIO"
```

### Problema 3: "Error instalando dependencias Python"

**Solucion:**
```powershell
# Instalar manualmente
pip install mcp requests

# Verificar instalacion
pip list | findstr mcp
pip list | findstr requests
```

### Problema 4: "No puedo conectarme a SAP"

**Verificar:**
1. ¿Estas en la red corporativa o VPN conectada?
2. ¿Tu usuario SAP esta activo? (probar en SAP GUI)
3. ¿El password es correcto?

**Probar conexion de red:**
```powershell
Test-NetConnection fbpl08v010.holcimbp.net -Port 8000
```

### Problema 5: "No tengo permisos de administrador"

**Soluciones:**
- Usa Microsoft Store para instalar Python (no requiere admin)
- Pide a IT que instale Python 3.12
- Usa una maquina virtual con permisos

---

## Checklist de Instalacion

Usa este checklist para verificar que todo esta instalado:

- [ ] Python 3.10+ instalado (`python --version`)
- [ ] pip instalado (`pip --version`)
- [ ] Git instalado (opcional) (`git --version`)
- [ ] Proyecto descargado y descomprimido
- [ ] Dependencias Python instaladas (`pip list | findstr mcp`)
- [ ] MCP servers configurados (archivo `~/.kiro/settings/mcp.json` existe)
- [ ] Steering files copiados (carpeta `~/.kiro/steering` existe)
- [ ] Kiro reiniciado
- [ ] MCP servers conectados (panel lateral de Kiro)
- [ ] Conexion a SAP verificada

---

## Instalacion Alternativa: Asistente Interactivo

Si prefieres un asistente con menus interactivos:

```powershell
.\setup-wizard.ps1
```

Este asistente te guiara paso a paso y te permitira configurar multiples sistemas SAP.

---

## Instalacion Alternativa: Instalador Simple

Si quieres algo mas directo sin menus:

```powershell
.\setup-simple.ps1 -SystemKey BZD -Username "TU_USUARIO"
```

---

## Recursos Adicionales

### Documentacion
- `README.md` - Descripcion del proyecto
- `QUICK_START.md` - Guia rapida de inicio

### Skills Disponibles
Activa con `#nombre-del-skill` en el chat:
- `#sap-mcp-capabilities` - Capacidades del MCP server
- `#solid-refactoring` - Patrones SOLID en ABAP
- `#transport-management` - Gestion de ordenes de transporte

### Steering Files
Se aplican automaticamente:
- Contexto de Amrize BP y sistemas SAP
- Convenciones de nomenclatura ABAP
- Estandares de codificacion
- Patrones SOLID validados
- Workflow de deploy

---

## Contacto y Soporte

Si tienes problemas:
1. Revisa la seccion "Solucion de Problemas" arriba
2. Verifica el checklist de instalacion
3. Contacta al equipo SAP de Amrize BP

**Email:** angecruz@amrize.com

---

## Resumen de Comandos

```powershell
# OPCION 1: Instalador Todo-en-Uno (MAS RAPIDO)
# ============================================
# 1. Descargar y descomprimir el proyecto
# 2. Navegar al proyecto
cd C:\Users\TU_USUARIO\sap-mcp-bzd

# 3. Ejecutar instalador completo
.\install-complete.ps1 -SAPUser "TU_USUARIO"

# 4. Reiniciar Kiro

# 5. Probar en Kiro
# "Verifica la conexion con SAP BZD"


# OPCION 2: Paso a Paso (MAS CONTROL)
# ====================================
# 1. Instalar Python (si no lo tienes)
winget install Python.Python.3.12

# 2. Cerrar y abrir PowerShell

# 3. Verificar Python
python --version

# 4. Navegar al proyecto
cd C:\Users\TU_USUARIO\sap-mcp-bzd

# 5. Ejecutar instalador
.\install.ps1 -SAPUser "TU_USUARIO"

# 6. Reiniciar Kiro

# 7. Probar en Kiro
# "Verifica la conexion con SAP BZD"
```

---

**Tiempo total estimado:** 
- **Con instalador todo-en-uno:** 10-15 minutos
- **Paso a paso:** 15-20 minutos (incluyendo instalacion de Python)

**¡Bienvenido al equipo de Kiro SAP ABAP Power!**

---

**Ultima actualizacion:** 2026-05-05  
**Version:** 1.0.0  
**Creado por:** Angel Cruz
