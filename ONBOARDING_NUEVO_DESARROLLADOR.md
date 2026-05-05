# 🚀 Onboarding: Configurar Kiro para SAP ABAP en 15 minutos

## Escenario
Juan acaba de instalar Kiro, se logueó con sus credenciales de Amrize, y ahora necesita configurar su ambiente para trabajar con SAP BZD.

---

## ✅ Prerequisitos (Verificar primero)

Antes de empezar, Juan debe tener:
- [x] Kiro instalado y logueado
- [x] Python 3.10+ instalado (requerido por el paquete mcp)
- [x] Acceso a la red corporativa (VPN si es remoto)
- [x] Usuario SAP activo (ej: AHERNA11)
- [x] Password de SAP
- [x] Acceso al repositorio GitLab del equipo

---

## 🎯 Opción 1: Instalación Automática (Recomendada)

### Paso 1: Clonar el repositorio del equipo

Abrir PowerShell y ejecutar:

```powershell
# Navegar a una carpeta de trabajo
cd C:\Users\$env:USERNAME

# Clonar el repositorio del equipo
git clone https://gitlab.amrize.com/sap/kiro-sap-abap-power.git
cd kiro-sap-abap-power
```

### Paso 2: Ejecutar el instalador

```powershell
# Ejecutar el instalador con tu usuario SAP
.\install.ps1 -SAPUser "AHERNA11"
```

El instalador te pedirá:
1. ✅ Tu password de SAP (se guardará de forma segura)
2. ✅ Sistema por defecto (presiona Enter para BZD)

**Salida esperada:**
```
🚀 Instalando Kiro SAP ABAP Power...
✓ Verificando Python...
✓ Instalando dependencias Python...
✓ Configurando MCP servers...
✓ Copiando steering files...
✓ Copiando skills...
✓ Instalando hooks...
✓ Copiando templates ABAP...
✅ Instalación completada!
🎉 Reinicia Kiro para aplicar los cambios
```

### Paso 3: Reiniciar Kiro

1. Cerrar Kiro completamente
2. Abrir Kiro nuevamente
3. Verificar que los MCP servers estén conectados (panel lateral)

### Paso 4: Verificar instalación

En el chat de Kiro, escribir:

```
Verifica la conexión con SAP BZD
```

**Respuesta esperada:**
```
✅ Conexión exitosa con SAP BZD
- Host: fbpl08v010.holcimbp.net:8000
- Cliente: 130
- Usuario: AHERNA11
- Versión: ECC 6.0 EHP8
- ABAP: 7.5 SP19
```

---

## 🔧 Opción 2: Instalación Manual (Si no existe el repositorio aún)

### Paso 1: Crear estructura de carpetas

```powershell
# Crear carpeta del proyecto
mkdir C:\Users\$env:USERNAME\sap-mcp-bzd
cd C:\Users\$env:USERNAME\sap-mcp-bzd

# Crear estructura de carpetas
mkdir .kiro\steering
mkdir .kiro\skills
mkdir .kiro\hooks
mkdir .kiro\settings
```

### Paso 2: Instalar dependencias Python

Crear archivo `requirements.txt`:

```powershell
@"
requests>=2.31.0
python-dotenv>=1.0.0
"@ | Out-File -FilePath requirements.txt -Encoding UTF8
```

Instalar:

```powershell
pip install -r requirements.txt
```

### Paso 3: Descargar archivos del MCP Server

Copiar los archivos del repositorio actual:

```powershell
# Si tienes acceso al repositorio de Ángel
git clone https://github.com/angecruz/sap-mcp-bzd.git temp
Copy-Item -Path temp\server.py -Destination .
Copy-Item -Path temp\sap_client.py -Destination .
Copy-Item -Path temp\.kiro\steering\* -Destination .kiro\steering\ -Recurse
Remove-Item -Path temp -Recurse -Force
```

### Paso 4: Configurar variables de entorno

Crear archivo `.env`:

```powershell
@"
SAP_HOST=fbpl08v010.holcimbp.net
SAP_PORT=8000
SAP_CLIENT=130
SAP_USER=AHERNA11
SAP_PASSWORD=TU_PASSWORD_AQUI
"@ | Out-File -FilePath .env -Encoding UTF8
```

⚠️ **IMPORTANTE:** Nunca subir el archivo `.env` a Git. Agregar a `.gitignore`:

```powershell
@"
.env
*.pyc
__pycache__/
"@ | Out-File -FilePath .gitignore -Encoding UTF8
```

### Paso 5: Configurar MCP en Kiro

Crear/editar archivo `C:\Users\$env:USERNAME\.kiro\settings\mcp.json`:

```powershell
$mcpConfig = @{
    mcpServers = @{
        "sap-bzd" = @{
            command = "python"
            args = @("C:\Users\$env:USERNAME\sap-mcp-bzd\server.py")
            env = @{
                SAP_HOST = "fbpl08v010.holcimbp.net"
                SAP_PORT = "8000"
                SAP_CLIENT = "130"
                SAP_USER = "AHERNA11"
            }
            disabled = $false
            autoApprove = @()
        }
    }
}

$mcpConfigPath = "$HOME\.kiro\settings"
if (-not (Test-Path $mcpConfigPath)) {
    New-Item -ItemType Directory -Path $mcpConfigPath -Force
}

$mcpConfig | ConvertTo-Json -Depth 10 | Out-File "$mcpConfigPath\mcp.json" -Encoding UTF8
```

### Paso 6: Configurar password de forma segura

En PowerShell, configurar la variable de entorno:

```powershell
# Opción 1: Solo para la sesión actual
$env:SAP_PASSWORD = "tu_password_aqui"

# Opción 2: Permanente para el usuario (MÁS SEGURO)
[System.Environment]::SetEnvironmentVariable('SAP_PASSWORD', 'tu_password_aqui', 'User')
```

### Paso 7: Reiniciar Kiro

1. Cerrar Kiro completamente
2. Abrir Kiro nuevamente
3. Verificar conexión (ver Paso 4 de Opción 1)

---

## 🧪 Pruebas Rápidas

Una vez configurado, Juan puede probar con estos comandos:

### 1. Leer código de un programa
```
Lee el código del programa ZR_SD_QUICK_ORDERS del sistema BZD
```

### 2. Buscar objetos
```
Busca todos los programas que empiecen con ZR_SD_
```

### 3. Listar órdenes de transporte
```
Lista mis órdenes de transporte abiertas en BZD
```

### 4. Obtener definición de tabla
```
Muestra la definición de la tabla VBAK
```

### 5. Verificar capacidades
```
#sap-mcp-capabilities
```

---

## 📚 Recursos Disponibles

Una vez instalado, Juan tiene acceso a:

### Skills (Activar con #)
- `#sap-mcp-capabilities` — Documentación completa de herramientas SAP
- `#solid-refactoring` — Guía de refactoring a patrones SOLID
- `#transport-management` — Gestión de órdenes de transporte
- `#abap-unit-testing` — Crear tests unitarios

### Steering Files (Automáticos)
- Contexto de Amrize BP y sistemas SAP
- Convenciones de nomenclatura
- Estándares de codificación
- Patrones SOLID validados
- Workflow de deploy

### Hooks (Automáticos)
- Validación de sintaxis antes de subir código
- Validación de orden de transporte
- Formateo de código ABAP

### Templates ABAP
- Clase OO con test unitario
- Patrón DAO
- FM RFC como fachada
- Report con ALV

---

## 🔍 Troubleshooting

### Problema 1: MCP Server aparece en rojo

**Solución:**
```powershell
# Verificar que Python puede ejecutar el server
cd C:\Users\$env:USERNAME\sap-mcp-bzd
python server.py
```

Si hay error, verificar:
- ✅ Python instalado: `python --version`
- ✅ Dependencias instaladas: `pip list | Select-String requests`
- ✅ Variables de entorno configuradas: `$env:SAP_PASSWORD`

### Problema 2: Error de autenticación

**Solución:**
```powershell
# Verificar conexión manual
python -c "
import requests
from requests.auth import HTTPBasicAuth

response = requests.get(
    'http://fbpl08v010.holcimbp.net:8000/sap/bc/adt/discovery',
    auth=HTTPBasicAuth('AHERNA11', 'TU_PASSWORD'),
    headers={'sap-client': '130'}
)
print(f'Status: {response.status_code}')
print(f'Response: {response.text[:200]}')
"
```

**Status esperado:** 200

### Problema 3: No puede conectarse a SAP

**Verificar:**
1. ✅ Estás en la red corporativa o VPN conectada
2. ✅ El servidor SAP está disponible: `Test-NetConnection fbpl08v010.holcimbp.net -Port 8000`
3. ✅ Tu usuario SAP está activo (probar en SAP GUI)

### Problema 4: Steering files no se aplican

**Solución:**
```powershell
# Verificar que los archivos están en la ubicación correcta
Get-ChildItem "$HOME\.kiro\steering\"

# Deben aparecer:
# 01-holcim-context.md
# 02-naming-conventions.md
# 03-coding-standards.md
# 04-solid-patterns.md
# 06-sap-deploy-workflow.md
```

Si no están, copiarlos manualmente:
```powershell
Copy-Item -Path C:\Users\$env:USERNAME\sap-mcp-bzd\.kiro\steering\* -Destination $HOME\.kiro\steering\ -Force
```

---

## 📊 Checklist de Verificación

Antes de empezar a trabajar, Juan debe verificar:

- [ ] Kiro instalado y logueado
- [ ] Python 3.10+ instalado (requerido por el paquete mcp)
- [ ] Repositorio clonado o archivos descargados
- [ ] Dependencias Python instaladas (`pip list`)
- [ ] Variables de entorno configuradas (`$env:SAP_PASSWORD`)
- [ ] MCP server configurado en `~/.kiro/settings/mcp.json`
- [ ] MCP server conectado (verde en panel lateral de Kiro)
- [ ] Steering files copiados a `~/.kiro/steering/`
- [ ] Conexión a SAP BZD verificada
- [ ] Prueba rápida exitosa (leer un programa)

---

## 🎓 Próximos Pasos

Una vez configurado, Juan puede:

1. **Explorar el repositorio de código:**
   ```
   Busca todos los objetos Z del paquete ZDEV_SD
   ```

2. **Leer código existente:**
   ```
   Lee el código de la clase ZCL_SD_STOCK_QUERY y explícame qué hace
   ```

3. **Crear código nuevo:**
   ```
   Crea una clase ZCL_SD_HELPER con un método que valide un número de material
   ```

4. **Gestionar transportes:**
   ```
   Lista mis órdenes de transporte abiertas
   ```

5. **Aprender patrones:**
   ```
   #solid-refactoring
   Muéstrame cómo refactorizar esta clase para seguir el patrón DAO
   ```

---

## 📞 Soporte

Si Juan tiene problemas:

1. **Revisar esta guía** — La mayoría de problemas están documentados
2. **Consultar logs del MCP server** — Panel de Kiro → MCP Logs
3. **Preguntar al equipo** — Canal de Teams/Slack del equipo SAP
4. **Contactar a Ángel Cruz** — Creador del framework

---

## 🎉 ¡Listo para Trabajar!

Una vez completados todos los pasos, Juan tiene:

✅ Conexión directa a SAP BZD desde Kiro  
✅ Capacidad de leer/escribir código ABAP  
✅ Gestión de órdenes de transporte  
✅ Validaciones automáticas de calidad  
✅ Acceso a patrones y mejores prácticas del equipo  
✅ Templates de código reutilizables  
✅ Documentación contextual automática  

**Tiempo total de setup:** 15 minutos ⏱️  
**Tiempo ahorrado en el futuro:** 2+ horas por día 🚀

---

**Última actualización:** 2026-05-04  
**Versión:** 1.0  
**Mantenido por:** Equipo SAP ABAP - Amrize BP
