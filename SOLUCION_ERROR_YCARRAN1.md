# Solución al Error de setup-wizard.ps1 para YCARRAN1

## Problema Identificado

El archivo `setup-wizard.ps1` tenía caracteres especiales (emojis) que causaban errores de codificación en PowerShell. Los emojis UTF-8 no son compatibles con todas las configuraciones de PowerShell en Windows.

## Solución Aplicada

✅ **El archivo ha sido corregido**. Todos los emojis problemáticos han sido reemplazados por etiquetas de texto ASCII:

- `🔍` → `[Check]`
- `✓` → `[OK]`
- `✗` → `[ERROR]`
- `⚠` → `[!]`
- `📋` → `[i]`
- `🔧` → `[Config]`
- `💾` → `[Save]`
- `🔐` → `[Seguridad]`
- `⚙️` → `[Config]`
- `📦` → `[Setup]`
- `🔌` → `[Test]`
- Y otros...

## Instrucciones para YCARRAN1

### Paso 1: Actualizar el archivo
El archivo ya está corregido en el repositorio. Si estás trabajando en tu copia local:

```powershell
# Navega al directorio del proyecto
cd C:\Users\YCARRAN1\sap-mcp-bzd

# Descarga la versión corregida (si usas Git)
git pull origin main
```

### Paso 2: Ejecutar el asistente de configuración

```powershell
# Ejecuta el asistente
.\setup-wizard.ps1
```

### Paso 3: Seguir el asistente interactivo

El asistente te guiará paso a paso:

1. **Verificación de prerequisitos** - Confirma que Python está instalado
2. **Información del usuario** - Ingresa tu nombre, email y equipo
3. **Sistemas disponibles** - Verás la lista de sistemas SAP (BZD, BZN, etc.)
4. **Configuración de sistemas** - Para cada sistema:
   - Usuario SAP (ej: YCARRAN1)
   - Password SAP (se guardará de forma segura)
   - Sistema por defecto (S/N)
5. **Preferencias** - Opciones de auto-activación, syntax check, etc.
6. **Instalación** - El asistente:
   - Guarda tu configuración en `user-config.json`
   - Configura variables de entorno
   - Genera configuración MCP en `~/.kiro/settings/mcp.json`
   - Instala dependencias Python
   - Copia archivos del framework (steering, skills, hooks)
   - Verifica conexiones a SAP

### Paso 4: Reiniciar Kiro

Después de completar el asistente:

1. Cierra Kiro completamente
2. Abre Kiro nuevamente
3. Verifica que los MCP servers estén conectados (panel lateral de Kiro)

### Paso 5: Probar la conexión

En el chat de Kiro, prueba:

```
Verifica la conexión con SAP BZD
```

## Solución de Problemas

### Si el error persiste

1. **Verifica la codificación del archivo:**
   ```powershell
   # El archivo debe estar en UTF-8 sin BOM
   Get-Content setup-wizard.ps1 -Encoding UTF8 | Out-Null
   ```

2. **Ejecuta con codificación explícita:**
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File setup-wizard.ps1
   ```

3. **Verifica que Python esté instalado:**
   ```powershell
   python --version
   # Debe mostrar Python 3.10 o superior (requerido por el paquete mcp)
   ```

### Si Python no está instalado

1. Descarga Python desde: https://www.python.org/downloads/
2. Durante la instalación, marca "Add Python to PATH"
3. Reinicia PowerShell después de instalar

### Si tienes problemas de permisos

```powershell
# Ejecuta PowerShell como Administrador y permite scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Archivos Generados

Después de ejecutar el asistente, se crearán:

- `user-config.json` - Tu configuración personal
- `~/.kiro/settings/mcp.json` - Configuración de MCP servers
- Variables de entorno: `SAP_PASSWORD_BZD`, `SAP_PASSWORD_BZN`, etc.

## Contacto

Si necesitas ayuda adicional:
- Revisa: `QUICK_START.md`
- Revisa: `ONBOARDING_NUEVO_DESARROLLADOR.md`
- Contacta al equipo de Amrize BP

---

**Fecha de corrección:** 2026-05-05  
**Corregido por:** Kiro AI Assistant  
**Versión:** 1.0
