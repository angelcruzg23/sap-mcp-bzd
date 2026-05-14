# Guia de Onboarding - Kiro SAP para Building Material DEV

## Para: Nuevo desarrollador (primera vez)

Esta guia cubre TODO desde cero: login corporativo, instalacion de herramientas, y configuracion de Kiro con SAP DEV.

---

## Paso 0: Acceso Corporativo (AWS IAM Identity Center)

Antes de instalar nada, necesitas acceso a los recursos de la compania.

### 0.1 Login en el portal corporativo

1. Abre tu navegador y ve a:
   ```
   https://lham.awsapps.com/start#/us-east-1
   ```

2. Ingresa tu **email corporativo** (ej: `marolda@holcim.com` o similar)

3. Ingresa tu **password corporativo**
   - Si es tu primera vez, puede que te pida configurar MFA (autenticacion multifactor)
   - Sigue las instrucciones en pantalla para registrar tu dispositivo MFA

4. Una vez autenticado, veras el portal de AWS con las cuentas y aplicaciones disponibles

### 0.2 Verificar acceso a la red

Para conectarte a SAP DEV necesitas estar en la **red corporativa**:
- Si estas en oficina: ya estas conectado
- Si estas remoto: conecta tu **VPN corporativa** antes de continuar

**Verificar conectividad al servidor SAP:**

Abre PowerShell y ejecuta:
```powershell
Test-NetConnection nascdev.na.holcim.net -Port 8081
```

**Resultado esperado:**
```
TcpTestSucceeded : True
```

Si dice `False`, verifica tu VPN o contacta a IT.

---

## Paso 1: Instalar Kiro

### 1.1 Descargar Kiro

1. Ve a: https://kiro.dev (o el link que te hayan compartido)
2. Descarga el instalador para Windows
3. Ejecuta el instalador y sigue las instrucciones
4. Abre Kiro una vez instalado

### 1.2 Login en Kiro

- Kiro usa tu cuenta de AWS Builder ID o la cuenta corporativa
- Si te pide login, usa las mismas credenciales del portal AWS:
  ```
  https://lham.awsapps.com/start#/us-east-1
  ```

---

## Paso 2: Descargar el Instalador

Solo necesitas **un archivo**: `install-complete.ps1`

### Opcion A: Descarga directa (mas facil)

1. Ve a: https://github.com/angelcruzg23/sap-mcp-bzd
2. Busca el archivo `install-complete.ps1`
3. Click en el archivo, luego click en **"Raw"**
4. Click derecho > **"Guardar como..."** en tu escritorio o carpeta de descargas

### Opcion B: Te lo pasan por Teams/email

Tu companero de equipo te enviara el archivo `install-complete.ps1`. Guardalo en cualquier carpeta.

---

## Paso 3: Ejecutar el Instalador

Abre **PowerShell** y navega a donde guardaste el archivo:

```powershell
# Si lo guardaste en el escritorio:
cd ~\Desktop

# Ejecutar el instalador
.\install-complete.ps1
```

### Si te da error de ejecucion de scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Luego ejecuta el instalador de nuevo.

### El instalador te pedira:

1. **Confirmacion para continuar** → escribe `S`
2. **Business Unit** → escribe `1` para Building Material o `2` para Building Envelope
3. **Usuario SAP** → tu usuario (ej: `MAROLDA`)
4. **Password SAP** → tu password (no se muestra en pantalla)

### El instalador hara automaticamente:
- Verificar/instalar Python y Git
- Clonar el repositorio en `C:\Users\TU_USUARIO\sap-mcp-bzd`
- Configurar el MCP server con tu sistema SAP
- Instalar dependencias Python
- Copiar steering files, skills y hooks
- Verificar la conexion a SAP

---

## Paso 4: Abrir Kiro con el Proyecto

1. Abre Kiro (o reinicialo si ya estaba abierto)
2. File > Open Folder > `C:\Users\TU_USUARIO\sap-mcp-bzd`
3. Verifica que el MCP server aparezca como **conectado** en el panel lateral

---

## Paso 5: Verificar Conexion

En el panel lateral de Kiro, verifica que el MCP server aparezca como **conectado** (icono verde).

Luego en el chat de Kiro, escribe:

```
Verifica la conexion con SAP DEV
```

**Respuesta esperada:** Kiro deberia confirmar conexion exitosa con el sistema.

---

## Datos del Sistema SAP DEV (Building Material)

| Parametro | Valor |
|-----------|-------|
| Host | nascdev.na.holcim.net |
| Puerto | 8081 |
| Cliente | 310 |
| Protocolo | HTTP |
| URL ADT | http://nascdev.na.holcim.net:8081/sap/bc/adt |

---

## Solucion de Problemas

### "No puedo acceder al portal AWS"
- Verifica que tu cuenta corporativa este activa
- Contacta a IT para que te den acceso al portal: `https://lham.awsapps.com/start#/us-east-1`

### "Test-NetConnection dice False"
- Conecta tu VPN corporativa
- Si ya esta conectada, prueba desconectar y reconectar
- Contacta a IT si persiste

### "python no se reconoce como comando"
- Cierra y abre PowerShell
- Si persiste, reinicia la computadora
- Verifica que Python este en el PATH: busca "Variables de entorno" en Windows

### "El MCP server no conecta en Kiro"
- Verifica que la VPN este activa
- Verifica que el password de SAP sea correcto
- Revisa el archivo `~/.kiro/settings/mcp.json` para confirmar la configuracion

### "Error de autenticacion en SAP"
- Verifica tu usuario SAP en SAP GUI primero (transaccion SE80 o similar)
- Si tu password expiro, cambialo en SAP GUI antes de usar Kiro
- El usuario SAP es diferente al usuario de Windows/email

---

## Resumen Rapido (Checklist)

- [ ] Acceso al portal AWS (`https://lham.awsapps.com/start#/us-east-1`)
- [ ] VPN conectada (si trabajas remoto)
- [ ] Kiro instalado
- [ ] `install-complete.ps1` descargado
- [ ] Ejecutar `.\install-complete.ps1` (instala Python, Git, clona repo, configura todo)
- [ ] Kiro abierto con la carpeta `C:\Users\TU_USUARIO\sap-mcp-bzd`
- [ ] MCP server conectado (panel lateral)
- [ ] Conexion a SAP verificada desde el chat

---

**Tiempo total estimado:** 20-30 minutos (primera vez)

**Contacto:** Si tienes problemas, contacta a Angel Cruz (angecruz@amrize.com)

**Ultima actualizacion:** 2026-05-07
