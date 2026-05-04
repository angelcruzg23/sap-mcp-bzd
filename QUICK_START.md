# 🚀 Quick Start - Kiro SAP ABAP en 10 Minutos

## Para Juan (o cualquier nuevo desarrollador)

### ✅ Prerequisitos
- [x] Kiro instalado y logueado
- [x] Python 3.8+ instalado
- [x] Acceso a red corporativa (VPN si es remoto)
- [x] Usuario(s) SAP activo(s)

---

## 📦 Instalación en 3 Pasos

### 1️⃣ Clonar el repositorio

```powershell
cd C:\Users\$env:USERNAME
git clone https://gitlab.amrize.com/sap/kiro-sap-abap-power.git
cd kiro-sap-abap-power
```

### 2️⃣ Ejecutar el asistente de configuración

```powershell
.\setup-wizard.ps1
```

El asistente te guiará paso a paso:
1. ✅ Información personal (nombre, email, equipo)
2. ✅ Selección de sistemas SAP a configurar
3. ✅ Credenciales para cada sistema
4. ✅ Preferencias de trabajo
5. ✅ Verificación de conexiones

**Sistemas disponibles:**
- **BZD** — Business Envelope (Development)
- **DEV** — Building Materials (Development)
- **BZX** — D2I Team (Development)
- **BZN** — Sandbox (All Teams)

### 3️⃣ Reiniciar Kiro

1. Cerrar Kiro completamente
2. Abrir Kiro nuevamente
3. ✅ ¡Listo!

---

## 🧪 Verificar que Funciona

En el chat de Kiro, escribe:

```
Verifica la conexión con SAP BZD
```

**Respuesta esperada:**
```
✅ Conexión exitosa con SAP BZD
- Host: fbpl08v010.holcimbp.net:8000
- Cliente: 130
- Usuario: JPEREZ
- Versión: ECC 6.0 EHP8
```

Si configuraste múltiples sistemas, puedes verificar cada uno:
```
Verifica la conexión con SAP DEV
Verifica la conexión con SAP BZX
```

---

## 🔧 Gestión de Credenciales

### Agregar un sistema adicional
```powershell
.\manage-credentials.ps1 add
```

### Actualizar credenciales
```powershell
.\manage-credentials.ps1 update
```

### Listar sistemas configurados
```powershell
.\manage-credentials.ps1 list
```

### Probar conexiones
```powershell
.\manage-credentials.ps1 test
```

---

## 🎯 Primeros Comandos

### Leer código de un programa
```
Lee el código del programa ZR_SD_QUICK_ORDERS
```

### Buscar objetos
```
Busca todos los programas que empiecen con ZR_SD_
```

### Listar tus transportes
```
Lista mis órdenes de transporte abiertas
```

### Ver capacidades disponibles
```
#sap-mcp-capabilities
```

---

## 🆘 Si Algo Sale Mal

### Verificar instalación
```powershell
.\verify-installation.ps1
```

### Reinstalar
```powershell
.\install.ps1 -SAPUser "TU_USUARIO_SAP"
```

### Documentación completa
Ver: `ONBOARDING_NUEVO_DESARROLLADOR.md`

---

## 📚 Recursos Disponibles

### Skills (Activar con #)
- `#sap-mcp-capabilities` — Todas las herramientas SAP disponibles
- `#solid-refactoring` — Guía de refactoring
- `#transport-management` — Gestión de transportes
- `#abap-unit-testing` — Crear tests unitarios

### Steering Files (Automáticos)
- Contexto de Amrize BP
- Convenciones de nomenclatura
- Estándares de codificación
- Patrones SOLID

### Hooks (Automáticos)
- Validación de sintaxis
- Validación de transportes
- Formateo de código

---

## ⏱️ Tiempo Total

- **Instalación con asistente:** 10 minutos
- **Verificación:** 2 minutos
- **Primera prueba:** 1 minuto

**Total:** ~13 minutos para estar 100% operativo con múltiples sistemas

---

## 🎉 ¡Listo para Trabajar!

Juan ahora tiene:
- ✅ Conexión directa a SAP BZD
- ✅ Capacidad de leer/escribir código ABAP
- ✅ Gestión de órdenes de transporte
- ✅ Validaciones automáticas
- ✅ Acceso a mejores prácticas del equipo

**¿Preguntas?** Consulta `ONBOARDING_NUEVO_DESARROLLADOR.md` o pregunta al equipo.
