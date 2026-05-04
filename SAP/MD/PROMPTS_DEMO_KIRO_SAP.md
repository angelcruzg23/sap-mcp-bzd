# Prompts para Demo en Vivo — Kiro + SAP MCP

## Prueba 1: Code Review instantáneo

Copiar y pegar en el chat de Kiro:

```
Lee el FM ZSD_PPD_REJ_UPDATE del grupo de funciones ZSD_PPD en SAP y hazme un code review. 
Dime qué hace, qué patrones usa y si ves problemas o mejoras.
```

**Qué esperar:** Kiro se conecta a SAP BZD, lee el código fuente del Function Module, y te entrega un análisis completo: qué hace el FM, qué patrones ABAP usa, y qué problemas o mejoras detecta.

---

## Prueba 2: De prompt a programa activo en SAP

Copiar y pegar en el chat de Kiro:

```
Crea un programa ZR_SD_DEMO_KIRO en paquete $TMP que lea las últimas 20 cotizaciones 
(VBAK donde AUART = 'ZQT2') creadas hoy, con campos VBELN, ERNAM, ERDAT, NETWR, WAERK 
y las muestre con CL_SALV_TABLE. Súbelo a SAP, actívalo y ejecuta syntax check.
```

**Qué esperar:** Kiro genera el código ABAP, lo sube a SAP BZD vía MCP, lo activa y ejecuta syntax check. Después puedes abrir SE38 y el programa está ahí listo para ejecutar.

---

## Notas

- Los prompts se escriben en lenguaje natural, como si le hablaras a un compañero
- No necesitas abrir Eclipse, SE37 ni SE38 — todo pasa desde Kiro
- Si algo no te gusta del resultado, simplemente dile qué cambiar en el mismo chat
