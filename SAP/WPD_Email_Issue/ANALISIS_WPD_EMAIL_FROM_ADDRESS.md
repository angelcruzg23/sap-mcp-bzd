# Análisis: WPD Email From-Address Issue (CRM)

## Problema
Después del upgrade a EHP8, los correos de aprobación/rechazo de WPD (Warranty Price Deviation) 
en CRM ya no llegan al external rep porque:

- **Antes**: `From = Mike Huber (dominio amrize)` → `To = external rep` ✅ Funcionaba
- **Ahora**: `From = external rep` → `To = external rep` ❌ No sale (dominio externo no autorizado en SAPconnect)

### Evidencia del screenshot
- Documento: **SRV_CONTRO 800519266** (Service Contract)
- Account: RACKLEY ROOFING COMPANY INC
- Contact: Daniel Diaz
- Employee Responsible: Ben George
- **From**: dawn@ims-reps.com (external rep)
- **To**: dawn@ims-reps.com (external rep)
- Subject: WPD 0600519266 for 40000463 Approval/Rejection

## Búsqueda en BZD (ECC)

### Objetos encontrados en ECC (grupo ZSD_PPD)
Estos FMs manejan emails del workflow PPD **desde el lado ECC**:

| FM | Descripción | Sender Logic |
|----|-------------|--------------|
| `ZSD_PPD_NO_APP_SEND_EMAIL` | Email cuando no hay aprobadores | `sender = cl_sapuser_bcs=>create( sy-uname )` — usa SY-UNAME |
| `ZSD_PPD_EMAIL_2_INITIATOR` | Email al iniciador del WF | `SO_NEW_DOCUMENT_ATT_SEND_API1` — sender implícito (SY-UNAME) |
| `ZSD_PPD_REMAINDER_EMAILS` | Reminder al aprobador actual | `SO_NEW_DOCUMENT_ATT_SEND_API1` — sender implícito (SY-UNAME) |
| `ZSD_PPD_REJ_NOTIF` | Notificación de rechazo | `SO_NEW_DOCUMENT_ATT_SEND_API1` — sender implícito (SY-UNAME) |
| `ZSD_PPD_APPROVALS` | Determinación de agentes/aprobadores | No envía email directamente |

**Nota**: Estos FMs del lado ECC usan `SY-UNAME` como sender o el sender implícito de 
`SO_NEW_DOCUMENT_ATT_SEND_API1`. NO son los que generan el email del screenshot (que es CRM WebUI).

### Objetos CRM-related en ECC
- Paquete `ZSD_CRM` existe con enhancements y function groups
- `ZWARRANTY_CNTRCT_HISTORY_CHNG` — programa de warranty contract history (paquete ZSD_CRM)
- `ZSD_CRM_CO_SLS` — function group CRM
- `ZSD_CRM_TOOLS` — function group CRM tools

## Dónde está el problema (Sistema CRM)

El screenshot es de **SAP CRM WebUI** — un sistema separado de ECC. El email se genera 
en el sistema CRM, no en ECC. **No puedo acceder al sistema CRM con el MCP actual** 
(solo tengo BZD = ECC desarrollo).

### Puntos a investigar EN EL SISTEMA CRM

#### 1. Action Profile del Service Contract (PRIORIDAD ALTA)
- **Transacción**: `CRMC_ACTION_DEF` en CRM
- Buscar el Action Profile asignado al tipo de transacción del Service Contract (SRV_CONTRO)
- Dentro del action de "WPD Approval/Rejection Email":
  - Revisar el **Processing Type** (Smart Form, Method, etc.)
  - La **clase/método** que construye el email determina el FROM address
  - Buscar clases Z* que implementen `IF_ACTION_EXECUTE` o similar

#### 2. Partner Determination (PRIORIDAD ALTA)
- **Transacción**: `CRMC_PARTNER_FCT` en CRM
- El cambio de EHP8 puede haber alterado cómo se resuelve el partner para el sender
- **Hipótesis principal**: Antes se usaba la partner function del "Employee Responsible" 
  (Ben George → Mike Huber como su manager/delegate) como sender. Ahora se usa el "Contact" 
  (Daniel Diaz → dawn@ims-reps.com)

#### 3. BAdIs de Email en CRM
- `BADI_CRM_EMAIL` — procesamiento de emails
- `CRM_EMAIL_COMM_BADI` — comunicación por email
- `CRM_COPY_BADI` — copia de datos en actividades
- Buscar implementaciones Z* de estos BAdIs en el sistema CRM

#### 4. SAPconnect Configuration
- **Transacción**: `SCOT` en CRM
- Verificar el **default sender address** configurado
- Con EHP8, el comportamiento de SAPconnect cambió: ahora asigna SCOMNO inmediatamente

#### 5. Workflow en CRM
- **Transacción**: `SWDD` en CRM
- Si la aprobación WPD usa un workflow CRM, el paso de envío de email puede tener 
  configurado el sender
- Buscar workflows Z* relacionados con WPD o Service Contract approval

#### 6. Smart Forms / Email Templates
- Buscar Smart Forms Z* en CRM relacionados con WPD approval
- El template puede tener lógica que determina el remitente

## Hipótesis de Root Cause

### Más probable: Cambio en Partner Determination o Action Processing
Con EHP8, SAP cambió el comportamiento de cómo se resuelve el "sender" en actividades 
de email CRM:

1. **Antes de EHP8**: El sistema tomaba el **Employee Responsible** (o un usuario SAP 
   configurado como default sender) para el campo FROM del email
2. **Después de EHP8**: El sistema ahora toma el **Contact** o el **Account Contact** 
   como FROM address

Esto es consistente con el screenshot donde `From = dawn@ims-reps.com` = el Contact/External Rep.

### Alternativa: Nota SAP / Cambio estándar en EHP8
Es posible que SAP haya cambiado el comportamiento estándar del email sender en 
actividades CRM con alguna nota incluida en EHP8. Buscar notas SAP relacionadas con:
- "CRM email from address EHP8"
- "CRM action email sender partner function"

## Recomendación de Acción

1. **Conectar Kiro al sistema CRM** (si es posible vía MCP) para buscar objetos Z* directamente
2. **En CRM, revisar** `CRMC_ACTION_DEF` → buscar el action profile del SRV_CONTRO → 
   identificar la clase/método que envía el email de aprobación WPD
3. **Verificar en SCOT** del CRM si hay un default sender configurado
4. **Buscar notas SAP** sobre cambios en email sender behavior con EHP8 en CRM
5. **Como fix temporal**: Si se identifica el método que determina el sender, se puede 
   forzar el FROM address a un usuario interno (como Mike Huber) o a un buzón genérico 
   de Amrize (ej: noreply@amrize.com)
