# Amrize BP — Reglas de Deploy a SAP desde Kiro

## Flujo controlado de deploy
```
1. Desarrollador crea OT en SE09 (con proyecto CTS correcto)
2. Desarrollador da el número de OT a Kiro
3. Kiro lee código actual de SAP (baseline para diff)
4. Kiro genera código nuevo localmente
5. Desarrollador revisa el diff
6. Kiro sube código a SAP con la OT proporcionada
7. Kiro activa el objeto
8. Kiro ejecuta syntax check (sap_syntax_check) para validar compilación
9. Kiro lee código de vuelta para verificar
```

## Reglas de Órdenes de Transporte

1. **Siempre proporcionar la OT explícitamente** — nunca dejar que Kiro cree OTs en sistemas con CTS Project Management (como BZD). La API ADT no soporta asignación a proyecto CTS.
2. **Crear la OT ANTES de pedir a Kiro que suba código** — en SE09/SE10 con la descripción correcta del change/ticket.
3. **$TMP solo para POCs** — nunca para código que irá a producción.
4. **Revisar TODAS las tasks dentro de una OT** — cuando se consulta el contenido de una orden de transporte con `sap_get_transport_details`, los objetos están asignados a las tasks (campo `tasks[].objects[]`), NO al request principal. Siempre revisar cada task para ver qué objetos contiene.

## Reglas de código

5. **Siempre pedir diff antes de subir** — leer el código actual de SAP y comparar con la versión local antes de escribir.
6. **Verificar después de subir** — leer el código de vuelta desde SAP para confirmar que quedó correcto.
7. **Un objeto a la vez** — no subir 5 objetos de golpe. Subir uno, verificar, subir el siguiente.
8. **Activar explícitamente** — para objetos productivos, separar el upload de la activación.

## Reglas de responsabilidad

9. **No subir código que no entiendas** — si Kiro propone algo y no entiendes por qué, pregunta antes de subir.
10. **Nunca subir a PRD sin revisión humana** — Kiro genera, el desarrollador decide.
11. **El desarrollador es siempre el responsable** — Kiro es una herramienta. El código en SAP lleva tu nombre.

## Notas técnicas clave para deploy

- El endpoint de FM source NO acepta bloques de comentarios de interfaz local (`*"------`). Enviar el source limpio tal como lo devuelve el GET.
- ABAP Unit vía ADT NO detecta clases de test locales en reports — solo funciona con clases globales (ZCL_*).
- Tipos de objeto para activación: PROG/P (programa), PROG/I (include), FUGR/FF (function module), CLAS/OC (clase), INTF/OI (interfaz).
- Crear/escribir clases globales aún NO está soportado por el MCP — usar Eclipse ADT para esas operaciones.
- La activación ADT puede pasar objetos con errores de sintaxis (especialmente FMs). SIEMPRE ejecutar `sap_syntax_check` después de activar — no confiar en que "activó = compila" (lección CHG0434843).

## Estructura XML del CTS (lección 2026-05-05)
- El endpoint `/sap/bc/adt/cts/transportrequests` retorna **todas las OTs visibles** en un solo XML de ~50KB, no solo la OT solicitada. El número en la URL no filtra.
- Los objetos de una task usan el tag `tm:abap_object` (con guión bajo), NO `tm:abapObject`. Atributos clave: `tm:pgmid`, `tm:type`, `tm:name`, `tm:wbtype`, `tm:obj_info`.
- El tool `sap_get_transport_xml_raw` permite ver el fragmento XML crudo de una OT específica cuando `sap_get_transport_details` no muestra objetos — útil para diagnóstico de parsing.
