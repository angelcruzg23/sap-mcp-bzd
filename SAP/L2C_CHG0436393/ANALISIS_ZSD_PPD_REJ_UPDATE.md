# Análisis — ZSD_PPD_REJ_UPDATE (CHG0436393)

## Contexto del Cambio
La FM `ZSD_PPD_REJ_UPDATE` del grupo de funciones `ZSD_PPD` es invocada desde un workflow de aprobación PPD (Product Price Deviation). Su propósito es remover el motivo de rechazo de las posiciones de una quotation después de que el flujo de aprobación finaliza exitosamente.

## Problema Identificado
La FM llama directamente a `BAPI_CUSTOMERQUOTATION_CHANGE` sin verificar si la quotation está bloqueada (enqueued) por otro usuario. Si alguien tiene la quotation abierta en VA22/VA23 u otra transacción, la BAPI puede fallar o generar inconsistencias.

## Flujo Actual (AS-IS)

```
1. Recibe T_VBAP con posiciones de la quotation
2. Prepara estructuras BAPI (reason_rej = ' ' para limpiar rechazo)
3. Obtiene VBELN de la primera línea
4. Exporta flag gv_flag_ppd a memoria (ID: ZPPD_WF)
5. Llama BAPI_CUSTOMERQUOTATION_CHANGE directamente
6. Si éxito → BAPI_TRANSACTION_COMMIT + email de aprobación al creador
7. Si error → UPDATE_FAILED = 'X' + email de error al último agente
```

## Flujo Propuesto (TO-BE)

```
1-4. Sin cambios
5. NUEVO: Verificar bloqueo con ENQUEUE_EVVBAKE
   - Si bloqueada → esperar 5 segundos y reintentar
   - Máximo 24 reintentos (2 minutos total)
   - Si se agotan reintentos → UPDATE_FAILED + email de error + RETURN
6. Llama BAPI_CUSTOMERQUOTATION_CHANGE (sin cambios)
7. NUEVO: Liberar bloqueo con DEQUEUE_EVVBAKE
8. Resto del flujo sin cambios (COMMIT, emails, etc.)
```

## Objetos Impactados

| Objeto | Tipo | Acción |
|--------|------|--------|
| ZSD_PPD_REJ_UPDATE | FUGR/FF | Modificación |
| ZSD_PPD (grupo de funciones) | FUGR | Contenedor |

## Análisis de Riesgo

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| WAIT UP TO bloquea work process | Media | Máximo 2 min, aceptable en contexto de workflow |
| Lock no se libera por error inesperado | Baja | DEQUEUE en ambos caminos (éxito y error) |
| Quotation permanece bloqueada > 2 min | Baja | Se trata como error, se notifica por email |

## Decisiones de Diseño

1. **ENQUEUE_EVVBAKE** en lugar de verificar tabla SM12: el enqueue estándar de SAP para documentos de venta es la forma correcta y segura de verificar/adquirir bloqueos.
2. **5 segundos entre reintentos**: balance entre responsividad y carga al sistema.
3. **24 reintentos = 120 segundos (2 min)**: tiempo máximo solicitado por el equipo.
4. **DEQUEUE_EVVBAKE** al final: libera el lock que nosotros adquirimos, independientemente del resultado de la BAPI.
5. **No se modifica la firma** de la FM: los parámetros de entrada/salida permanecen iguales para no impactar a los llamadores existentes.
