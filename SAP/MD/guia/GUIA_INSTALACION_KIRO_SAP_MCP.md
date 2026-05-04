# Guía de Instalación: Kiro + MCP + SAP BZD 130
## De cero a tu primera consulta ABAP en ~15 minutos

---

## Qué vas a lograr

Al terminar esta guía vas a tener Kiro (el IDE con AI) conectado directamente a SAP BZD 130. Vas a poder pedirle cosas como:
- "Busca el programa ZSD_QUOTATION* en SAP"
- "Dame el código fuente de la clase ZCL_SD_QUICK_ORDERS"
- "Crea un programa ABAP nuevo en $TMP"

Todo desde el chat de Kiro, sin abrir SAP GUI ni Eclipse.
3
---

## Qué necesitas antes de empezar

| Requisito | Detalle |
|-----------|---------|
| Windows 10/11 | (macOS y Linux también funcionan, los comandos cambian un poco) |
| Python 3.10 o superior | Para correr el servidor MCP |
| Cuenta SAP BZD | Tu usuario y contraseña del sistema BZD cliente 130 |
| Acceso de red a SAP | Debes poder llegar a `fbpl08v010.holcimbp.net:8000` desde tu PC |
| Licencia Kiro | Cuenta activa en kiro.dev |

---

## Paso 1 — Instalar Python

Si ya tienes Python 3.10+, salta al Paso 2.

1. Ve a https://www.python.org/downloads/
2. Descarga la última versión estable (3.12 o superior)
3. Al instalar, marca la casilla **"Add Python to PATH"** (esto es crítico)
4. Verifica que quedó bien:

```
python --version
```

Deberías ver algo como `Python 3.12.x`. Si dice "no se reconoce el comando", reinicia la terminal.

---

## Paso 2 — Instalar Kiro

1. Ve a https://kiro.dev
2. Inicia sesión con tu cuenta (o crea una si no tienes)
3. Descarga el instalador para Windows
4. Ejecuta el instalador, siguiente-siguiente-finalizar
5. Abre Kiro — te va a pedir iniciar sesión la primera vez

Kiro se ve como VS Code. Si ya usas VS Code, te vas a sentir en casa.

---

## Paso 3 — Crear la carpeta del proyecto

Abre una terminal (PowerShell o CMD) y ejecuta:

```powershell
mkdir C:\Users\TU_USUARIO\sap-mcp-bzd
cd C:\Users\TU_USUARIO\sap-mcp-bzd
```

Reemplaza `TU_USUARIO` con tu usuario de Windows.

---

## Paso 4 — Crear el servidor MCP (los archivos Python)

Necesitas crear 3 archivos en la carpeta `sap-mcp-bzd`. Puedes hacerlo desde Kiro o desde cualquier editor.

### 4.1 — Archivo `requirements.txt`

Crea el archivo `C:\Users\TU_USUARIO\sap-mcp-bzd\requirements.txt` con este contenido:

```
mcp
requests
```

### 4.2 — Archivo `sap_client.py`

Crea el archivo `C:\Users\TU_USUARIO\sap-mcp-bzd\sap_client.py`.

Este archivo es el cliente HTTP que habla con SAP usando la API REST de ADT (ABAP Development Tools). No usa RFC ni NW RFC SDK — solo HTTP puro.

El código completo está en el repositorio del equipo. Pídele a Angel Cruz o al lead técnico que te comparta la carpeta `sap-mcp-bzd`. Los archivos que necesitas son:
- `sap_client.py` (~300 líneas)
- `server.py` (~250 líneas)

Si ya tienes acceso al repositorio Git del equipo, clona directamente:

```powershell
git clone [URL_DEL_REPO] C:\Users\TU_USUARIO\sap-mcp-bzd
```

---

## Paso 5 — Instalar las dependencias Python

En la terminal, dentro de la carpeta del proyecto:

```powershell
cd C:\Users\TU_USUARIO\sap-mcp-bzd
pip install -r requirements.txt
```

Esto instala dos paquetes:
- `mcp` — el SDK de Model Context Protocol
- `requests` — para hacer llamadas HTTP a SAP

Si te da error de permisos, intenta con:

```powershell
pip install --user -r requirements.txt
```

---

## Paso 6 — Verificar que Python puede llegar a SAP

Antes de configurar Kiro, verifica que tu PC puede hablar con SAP:

```powershell
python -c "import requests; r = requests.get('http://fbpl08v010.holcimbp.net:8000/sap/bc/adt/discovery', auth=('TU_USUARIO_SAP','TU_PASSWORD_SAP'), headers={'sap-client':'130'}); print(r.status_code)"
```

Si ves `200`, estás conectado. Si ves un error de conexión, revisa:
- ¿Estás conectado a la VPN de Holcim?
- ¿Tu firewall permite tráfico al puerto 8000?
- ¿Tu usuario SAP está activo en BZD 130?

---

## Paso 7 — Abrir el proyecto en Kiro

1. Abre Kiro
2. File → Open Folder
3. Navega a `C:\Users\TU_USUARIO\sap-mcp-bzd` y ábrela
4. Kiro va a cargar la carpeta como workspace

---

## Paso 8 — Configurar el servidor MCP en Kiro

Este es el paso clave. Necesitas crear el archivo de configuración que le dice a Kiro cómo arrancar el servidor MCP.

1. En Kiro, crea la carpeta `.kiro` en la raíz del proyecto (si no existe)
2. Dentro de `.kiro`, crea el archivo `mcp.json`

La ruta completa debe ser: `C:\Users\TU_USUARIO\sap-mcp-bzd\.kiro\mcp.json`

Contenido del archivo:

```json
{
  "mcpServers": {
    "sap-bzd": {
      "command": "python",
      "args": ["C:\\Users\\TU_USUARIO\\sap-mcp-bzd\\server.py"],
      "env": {
        "SAP_HOST": "fbpl08v010.holcimbp.net:8000",
        "SAP_CLIENT": "130",
        "SAP_USER": "TU_USUARIO_SAP",
        "SAP_PASSWORD": "TU_PASSWORD_SAP",
        "SAP_SECURE": "false"
      },
      "timeout": 60000
    }
  }
}
```

**IMPORTANTE — Reemplaza estos valores:**

| Placeholder | Qué poner |
|-------------|-----------|
| `TU_USUARIO` | Tu usuario de Windows (ej: `jperez`) |
| `TU_USUARIO_SAP` | Tu usuario de SAP BZD (ej: `JPEREZ`) |
| `TU_PASSWORD_SAP` | Tu contraseña de SAP BZD |

**Nota sobre la ruta:** Usa doble backslash `\\` en las rutas de Windows dentro del JSON.

---

## Paso 9 — Verificar que el MCP Server arrancó

1. En Kiro, abre la paleta de comandos: `Ctrl+Shift+P`
2. Escribe `MCP` y selecciona "MCP: List Servers" o busca el panel de MCP Servers
3. Deberías ver `sap-bzd` con estado verde (running)

Si aparece en rojo o no aparece:
- Revisa que la ruta al `server.py` en el JSON sea correcta
- Revisa que Python esté en el PATH
- Revisa que instalaste las dependencias (`pip install -r requirements.txt`)

---

## Paso 10 — Tu primera consulta a SAP desde Kiro

Abre el chat de Kiro (ícono de chat en la barra lateral o `Ctrl+L`) y escribe:

```
Haz un ping a SAP BZD para verificar la conexión
```

Kiro debería responder algo como:
> Conexión exitosa a SAP ADT — status 200

Si funciona, prueba algo más interesante:

```
Busca todos los objetos que empiecen con ZCL_SD* en SAP
```

¡Listo! Ya estás conectado.

---

## Paso 11 (Opcional) — Configurar los Steering Files

Los steering files son reglas que Kiro sigue automáticamente cuando genera código. Son lo que hace que el código generado se vea como si lo hubiera escrito alguien del equipo.

Crea la carpeta `.kiro/steering/` y agrega estos archivos:

### `.kiro/steering/01-holcim-context.md`
```markdown
# Holcim BP — Contexto del Sistema SAP

## Sistema
- SAP ECC 6.0 EHP8 (sistema BZD, cliente 130)
- Servidor: fbpl08v010.holcimbp.net:8000
- Versión ABAP: 7.5 SP19
- NO estamos en S/4HANA — evitar sintaxis exclusiva de S/4 o ABAP Cloud

## Módulos principales en uso
- SD (Ventas), MM (Materiales), FI (Finanzas), PP (Producción), WM (Almacén)

## Contexto de negocio
- Holcim BP es fabricante de materiales de construcción
- Procesos críticos: gestión de pedidos de venta, producción de cemento, logística
```

### `.kiro/steering/02-naming-conventions.md`
```markdown
# Convenciones de Nomenclatura — Holcim BP

## Prefijos por tipo de objeto
| Objeto          | Prefijo   | Ejemplo               |
|-----------------|-----------|----------------------|
| Clase           | ZCL_      | ZCL_SD_ORDER_PROC    |
| Interfaz        | ZIF_      | ZIF_ORDER_VALIDATOR  |
| Programa/Report | Z o ZR_   | ZR_SD_OPEN_ORDERS    |
| Function Module | Z o ZFM_  | ZFM_SD_CREATE_ORDER  |
| Test Class      | _TEST     | ZCL_SD_VALIDATOR_TEST|

## Variables locales
- Variables de instancia: mo_, mv_, mt_, ms_
- Variables locales: lv_, lt_, ls_, lo_
- Parámetros: iv_, ev_, it_, et_
```

### `.kiro/steering/03-coding-standards.md`
```markdown
# Estándares de Codificación — Holcim BP

## OBLIGATORIO
- Toda clase de negocio debe tener clase de prueba _TEST con ABAP Unit
- No se permiten SELECTs dentro de LOOPs
- Usar sintaxis moderna ABAP: VALUE, FILTER, REDUCE cuando aplique
- Toda tabla interna con TYPE TABLE OF [TIPO_COMPLETO]

## PROHIBIDO
- No usar SELECT *
- No modificar tablas SAP estándar directamente
- No hard-codear mandante: usar SY-MANDT
- No usar COMMIT WORK en lógica de negocio
```

Pídele al lead técnico los archivos steering completos del repositorio del equipo. Los de arriba son versiones resumidas.

---

## Troubleshooting — Problemas comunes

### "python no se reconoce como comando"
Python no está en el PATH. Reinstala Python y marca "Add to PATH", o agrega manualmente la ruta de Python a las variables de entorno del sistema.

### El MCP server aparece en rojo
1. Abre una terminal y ejecuta manualmente:
```powershell
$env:SAP_PASSWORD="TU_PASSWORD"
python C:\Users\TU_USUARIO\sap-mcp-bzd\server.py
```
2. Si da error de import, falta instalar dependencias: `pip install mcp requests`
3. Si da error de conexión, revisa la VPN

### "CSRF token error" o "401 Unauthorized"
- Tu usuario o contraseña de SAP están mal en el `mcp.json`
- Tu usuario SAP está bloqueado — pide que lo desbloqueen en BZD 130

### "Connection refused" o "timeout"
- No estás conectado a la VPN de Holcim
- El servidor SAP BZD está caído (verificar con Basis)
- Tu firewall bloquea el puerto 8000

### Kiro no muestra las herramientas SAP en el chat
- Verifica que el archivo `.kiro/mcp.json` existe y tiene el JSON correcto
- Reinicia Kiro completamente (cerrar y abrir)
- Busca "MCP" en la paleta de comandos para ver el estado del server

---

## Estructura final de tu carpeta

Cuando termines, tu carpeta debería verse así:

```
C:\Users\TU_USUARIO\sap-mcp-bzd\
├── .kiro\
│   ├── mcp.json                          ← Configuración del MCP server
│   └── steering\                         ← Reglas para Kiro (opcional pero recomendado)
│       ├── 01-holcim-context.md
│       ├── 02-naming-conventions.md
│       └── 03-coding-standards.md
├── sap_client.py                         ← Cliente HTTP para SAP ADT
├── server.py                             ← Servidor MCP (lo que Kiro ejecuta)
└── requirements.txt                      ← Dependencias Python
```

---

## Qué sigue después de instalar

1. Lee el documento `WORKSHOP_KIRO_ABAP_PRODUCTIVITY.md` para entender la nueva forma de trabajo
2. Prueba buscar objetos de tu módulo: `Busca ZSD_* en SAP` o `Busca ZMM_* en SAP`
3. Prueba leer código: `Dame el código fuente del programa ZR_SD_QUICK_ORDERS`
4. Prueba analizar un FD: arrastra un documento Word/PDF al chat y pídele que lo analice

---

## Seguridad — Notas importantes

- Tu contraseña SAP queda en el archivo `.kiro/mcp.json` en texto plano. **No subas este archivo a Git.**
- Agrega `.kiro/mcp.json` a tu `.gitignore`
- Si compartes tu pantalla, ten cuidado de no mostrar el contenido de `mcp.json`
- El servidor MCP solo corre localmente en tu máquina — no expone ningún puerto a la red
- Cada desarrollador usa su propio usuario SAP — no se comparten credenciales

---

*Guía v1.0 — Abril 2026*
*¿Problemas? Contacta a Angel Cruz o al canal de Teams del equipo ABAP.*
