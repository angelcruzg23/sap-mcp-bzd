# Caso de Uso: Transport Checker + Fix de Lectura de Tablas DDIC

**Fecha:** 2026-04-28  
**Equipo:** L2C — Amrize BP  
**Sistema:** SAP ECC BZD 130 (EHP8)  
**Herramienta:** Kiro + MCP Server SAP ADT  

---

## Contexto — El problema real

Durante un pase a producción, la OT **BZDK930579** (CHG0432285 — ATP dropdown lists) falló en la activación en BZP porque faltaba un objeto que no fue incluido en el transporte. Esto generó coordinación de emergencia entre Yonatan Carranza, Vanessa Uribe, Daniel Gómez y Juan Antonio Jaramillo para crear una OT correctiva (BZDK930943) y relanzar la original.

**Impacto:** tiempo perdido del equipo, coordinación con basis fuera de horario, riesgo de inconsistencia en PRD.

**Pregunta al agente:** ¿Es posible crear un programa Z que valide la consistencia de una OT antes de transportar?

---

## Lo que Kiro generó

### 1. Programa ZR_SD_TRANSPORT_CHECKER ($TMP)

Reporte ABAP con selection screen que recibe un número de OT y ejecuta 5 validaciones automáticas:

| Validación | Categoría | Qué detecta |
|------------|-----------|-------------|
| Includes faltantes | INCLUDE | Includes Z/Y referenciados por programas de la OT que no están incluidos |
| Completitud de FUGR | FUGR | Function modules del mismo grupo que no viajan en la OT |
| Objetos inactivos | ACTIVATION | Objetos que no han sido activados en desarrollo |
| Referencias cruzadas | XREF | Objetos Z/Y referenciados que están en otras OTs abiertas |
| Objetos bloqueados | LOCK | Objetos que otro usuario tiene en una OT diferente |

**Output:** ALV con semáforo (🔴 Error / 🟡 Warning / 🟢 OK), header con resumen de la OT, contadores de errores/warnings/ok.

**Prueba real:** Se ejecutó contra la OT BZDK930947 (CHG0436955 — EHP8 hyper-INC08319045) y detectó correctamente que el include `ZSDR_ANOKA_REPORT_BAK_N_F02` estaba también en la OT `BZD_P00001` de otro desarrollador — exactamente el tipo de conflicto que causó el problema original.

### 2. Arquitectura del programa

- Clase local `lcl_transport_checker` con SRP por método
- Tablas consultadas: E070, E07T, E071, TRDIR, TFDIR, DWINACTIV, WBCROSSGT
- FM estándar: `RS_GET_ALL_INCLUDES` para resolución segura de includes
- Output via `CL_SALV_TABLE` con header informativo
- Sintaxis clásica (sin `@`) para compatibilidad con pool/cluster tables

---

## El problema colateral — Lectura de tablas DDIC

Durante el desarrollo, Kiro necesitó consultar la estructura de tablas como E070, E071, DWINACTIV y WBCROSSGT para conocer sus campos. El MCP Server usaba el endpoint `/sap/bc/adt/ddic/tables/{name}` que **no existe en ECC 6.0 EHP8** — devolvía 404 para todas las tablas, incluyendo tablas transparentes como VBAK.

Esto causó que Kiro adivinara los campos incorrectamente:
- Asumió que E070 tenía campo `AS4TEXT` (está en E07T)
- Asumió que D010INC tenía campos `PROG`/`INCLUDE` accesibles via Open SQL
- Asumió que DWINACTIV tenía campo `PGMID` y `OBJ_TYPE`
- Usó sintaxis nueva (`@()`) con pool tables que no la soportan bien

**Resultado:** 4 errores de sintaxis en el primer intento, 2 más en el segundo.

### Fix aplicado al MCP Server

Se descubrió via el ADT Discovery (`/sap/bc/adt/discovery`) que el endpoint correcto es `/sap/bc/adt/ddic/structures/{name}` con Accept header `application/vnd.sap.adt.blues.v1+xml`.

**Cambio en `sap_client.py`:**

```python
# ANTES — solo intentaba un endpoint que no existe en ECC
def get_table_definition(self, table_name):
    url = f"/sap/bc/adt/ddic/tables/{table_name}"  # 404 siempre
    
# DESPUÉS — intenta múltiples endpoints con fallback
def get_table_definition(self, table_name):
    # Intento 1: /ddic/tables/ (S/4HANA)
    # Intento 2: /ddic/structures/ con Accept correcto (ECC EHP8) ← ESTE FUNCIONA
    # Intento 3: /ddic/dataelements/ como último recurso
    # Fallback: mensaje descriptivo apuntando al steering file
```

**Resultado post-fix:** 10/10 tablas accesibles (VBAK, VBAP, MARA, MARD, KNA1, E070, E071, TFDIR, DWINACTIV, WBCROSSGT).

### Steering file 08-sap-system-tables.md

Se creó un archivo de referencia permanente con los campos verificados de las tablas de sistema más usadas (E070, E07T, E071, TRDIR, DWINACTIV, TADIR, WBCROSSGT, TFDIR). Este archivo se carga automáticamente en el contexto de Kiro para evitar que vuelva a adivinar campos.

---

## Lecciones aprendidas

1. **El endpoint ADT `/sap/bc/adt/ddic/tables/` no existe en ECC 6.0 EHP8.** El endpoint correcto para leer metadata de tablas (transparentes, pool y cluster) es `/sap/bc/adt/ddic/structures/` con Accept `application/vnd.sap.adt.blues.v1+xml`.

2. **Siempre consultar ADT Discovery** (`/sap/bc/adt/discovery`) para verificar qué endpoints y Accept headers están disponibles en el sistema antes de asumir.

3. **Pool/cluster tables requieren sintaxis clásica** en Open SQL (sin `@` host variables, sin string templates en WHERE). Usar CONCATENATE previo y variables intermedias.

4. **Preferir FMs estándar sobre SELECTs directos** a tablas de sistema: `RS_GET_ALL_INCLUDES` en lugar de SELECT a D010INC, `TR_READ_REQUEST` en lugar de SELECT directo a E070/E071.

5. **Un problema en producción puede generar herramientas preventivas.** El incidente de la OT fallida motivó la creación de un validador que puede prevenir futuros incidentes similares.

---

## Artefactos generados

| Artefacto | Ubicación | Propósito |
|-----------|-----------|-----------|
| ZR_SD_TRANSPORT_CHECKER | SAP BZD ($TMP) | Programa de validación de OTs |
| sap_client.py (fix) | Workspace local | MCP Server con lectura de tablas corregida |
| 08-sap-system-tables.md | .kiro/steering/ | Referencia de campos de tablas de sistema |
| Este documento | MD/ | Documentación del caso |
