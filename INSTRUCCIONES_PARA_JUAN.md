# 🚀 Instrucciones para Juan - Configurar Kiro SAP ABAP Power

## Hola Juan,

Ya está todo listo para que configures Kiro y puedas trabajar con SAP desde el IDE. El proceso toma **10 minutos**.

---

## ✅ Prerequisitos (Ya los tienes)

- [x] Kiro instalado y logueado ✅
- [x] Python 3.8+ instalado ✅
- [x] Credenciales de SAP ✅
- [x] Acceso a red corporativa ✅

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

En la misma ventana de PowerShell:

```powershell
.\setup-wizard.ps1
```

El asistente te va a preguntar:

### 2.1 Información Personal
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

**Solución:**
```powershell
# Verificar Python
python --version

# Si no está instalado, descargar de:
# https://www.python.org/downloads/
```

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
