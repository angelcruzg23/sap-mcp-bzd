# Workshop: Desarrollo ABAP Moderno en Holcim BP

## ¿Por qué cambiar la forma en que desarrollamos?

Históricamente en ABAP escribimos reportes monolíticos: un solo programa con SELECTs, lógica de negocio y presentación ALV todo mezclado en FORMs. Funciona, pero tiene problemas reales que nos afectan día a día:

- Cuando algo falla en producción, cuesta encontrar dónde está el problema porque todo está en un solo bloque de 500+ líneas
- No podemos probar la lógica sin ejecutar el reporte completo contra la base de datos
- Si otro desarrollador necesita reutilizar parte de la lógica, termina copiando y pegando código
- Cada cambio es riesgoso porque no hay forma de validar que no rompimos algo existente

Este workshop usa el reporte `ZR_SD_QUICK_ORDERS` como ejemplo práctico para mostrar cómo debería ser nuestro proceso de desarrollo a partir de ahora.

---

## El ejemplo: antes vs. después

### Antes (enfoque clásico)

Un solo programa que hace todo:

```
ZR_SD_QUICK_ORDERS (programa monolítico)
├── Pantalla de selección
├── SELECT directo sobre VBAK/VBAP
├── Lógica de procesamiento
└── Presentación ALV
```

Problemas concretos:
- Si el SELECT cambia, hay que probar todo el reporte manualmente
- No hay tests automatizados posibles
- Si otro reporte necesita la misma consulta, se copia el código

### Después (enfoque que proponemos)

```
ZR_SD_QUICK_ORDERS              → Solo UI (pantalla + ALV)
  └── ZCL_SD_QUICK_ORDERS       → Solo lógica de negocio
        └── ZIF_SD_QUICK_ORDERS_DAO  → Contrato de acceso a datos
              └── ZCL_SD_QUICK_ORDERS_DAO  → Solo el SELECT real

ZCL_SD_QUICK_ORDERS_TEST        → Tests automatizados con mock
```

Cada pieza tiene una sola responsabilidad y se puede probar, reutilizar o cambiar de forma independiente.

---

## Los 3 principios que aplicamos (y por qué)

### 1. Separar el acceso a datos (Patrón DAO)

**Regla:** Todo SELECT va en una clase DAO separada, nunca directo en el reporte o en la lógica de negocio.

**¿Por qué?**
- Si mañana la tabla cambia (migración a S/4HANA, nueva tabla Z), solo tocamos el DAO
- Podemos mockear el DAO en tests sin tocar la base de datos
- Otros desarrollos pueden reutilizar el mismo DAO

**En la práctica:**

```abap
" ❌ MAL — SELECT directo en el reporte
START-OF-SELECTION.
  SELECT vbeln erdat FROM vbak INTO TABLE lt_data
    WHERE erdat IN s_erdat.

" ✅ BIEN — SELECT encapsulado en un DAO
CLASS zcl_sd_quick_orders_dao IMPLEMENTATION.
  METHOD zif_sd_quick_orders_dao~get_orders.
    SELECT k~vbeln k~erdat ...
      INTO TABLE et_data
      FROM vbak AS k
      INNER JOIN vbap AS p ON p~vbeln = k~vbeln
      WHERE k~erdat IN it_erdat.
  ENDMETHOD.
ENDCLASS.
```

### 2. Depender de interfaces, no de clases concretas (DIP)

**Regla:** La clase de negocio recibe una interfaz `ZIF_` en el constructor, no una clase `ZCL_` directa.

**¿Por qué?**
- En producción se inyecta el DAO real que hace el SELECT
- En tests se inyecta un mock que devuelve datos ficticios
- El código de negocio no sabe ni le importa de dónde vienen los datos

**En la práctica:**

```abap
" La clase de negocio recibe la interfaz, no la implementación
CLASS zcl_sd_quick_orders DEFINITION.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_dao TYPE REF TO zif_sd_quick_orders_dao OPTIONAL.
  PRIVATE SECTION.
    DATA mo_dao TYPE REF TO zif_sd_quick_orders_dao.
ENDCLASS.

CLASS zcl_sd_quick_orders IMPLEMENTATION.
  METHOD constructor.
    " Si no se pasa nada, usa el DAO real (producción)
    " Si se pasa un mock, lo usa (testing)
    IF io_dao IS BOUND.
      mo_dao = io_dao.
    ELSE.
      mo_dao = NEW zcl_sd_quick_orders_dao( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

### 3. Tests automatizados con ABAP Unit

**Regla:** Toda clase de negocio debe tener una clase `_TEST` con tests unitarios.

**¿Por qué?**
- Detectamos errores antes de transportar a QAS/PRD
- Documentan el comportamiento esperado del código
- Nos dan confianza para hacer cambios sin miedo a romper algo

**En la práctica:**

```abap
" Test double local — simula el DAO sin base de datos
CLASS ltd_mock_dao DEFINITION FINAL FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_sd_quick_orders_dao.
    METHODS set_mock_data
      IMPORTING it_data TYPE zif_sd_quick_orders_dao=>ty_output_t.
  PRIVATE SECTION.
    DATA mt_mock_data TYPE zif_sd_quick_orders_dao=>ty_output_t.
ENDCLASS.

" En el test: inyectamos el mock
METHOD setup.
  mo_mock_dao = NEW ltd_mock_dao( ).
  mo_cut = NEW zcl_sd_quick_orders( io_dao = mo_mock_dao ).
ENDMETHOD.

" Validamos comportamiento sin tocar la DB
METHOD get_orders_with_data.
  mo_mock_dao->set_mock_data( lt_datos_ficticios ).
  mo_cut->get_orders( ... ).
  cl_abap_unit_assert=>assert_equals( act = lv_count exp = 2 ).
ENDMETHOD.
```

---

## Proceso de desarrollo paso a paso

A partir de ahora, cuando desarrollemos cualquier funcionalidad nueva, seguimos estos pasos:

### Paso 1 — Definir el contrato de datos (Interfaz)

Antes de escribir cualquier SELECT, definimos QUÉ datos necesitamos en una interfaz `ZIF_`:

```
ZIF_SD_[NOMBRE]_DAO
  ├── TYPES (estructuras y tablas de salida)
  └── METHODS get_xxx (firma del método)
```

Esto nos obliga a pensar en el diseño antes de codificar.

### Paso 2 — Implementar el acceso a datos (DAO)

Creamos la clase `ZCL_SD_[NOMBRE]_DAO` que implementa la interfaz. Aquí van los SELECTs reales.

Reglas del DAO:
- Solo acceso a datos, cero lógica de negocio
- Campos listados explícitamente (nunca SELECT *)
- JOINs en lugar de SELECTs dentro de LOOPs
- Un DAO por dominio funcional (pedidos, materiales, clientes...)

### Paso 3 — Implementar la lógica de negocio (Clase de servicio)

Creamos `ZCL_SD_[NOMBRE]` que recibe el DAO por inyección de dependencias:

- Constructor con parámetro `io_dao TYPE REF TO zif_..._dao OPTIONAL`
- Si no se pasa, crea la instancia real (producción)
- Toda la lógica de procesamiento, validación y transformación va aquí
- Nunca hace SELECTs directos

### Paso 4 — Escribir los tests (ABAP Unit)

Creamos `ZCL_SD_[NOMBRE]_TEST` con:

- Una clase local `LTD_MOCK_DAO` que implementa la interfaz del DAO
- Método `set_mock_data()` para inyectar datos de prueba
- Tests que cubran: caso con datos, caso vacío, conteos, validaciones

Los tests se ejecutan en segundos porque no tocan la base de datos.

### Paso 5 — Crear el reporte o interfaz de usuario

El reporte (`ZR_` o `Z`) solo se encarga de:
- Pantalla de selección
- Instanciar la clase de servicio
- Presentar los datos en ALV con `CL_SALV_TABLE`

El reporte es "tonto" — no tiene lógica, solo conecta la UI con el servicio.

---

## Convenciones que debemos respetar

### Nomenclatura de objetos

| Objeto | Patrón | Ejemplo |
|--------|--------|---------|
| Interfaz DAO | ZIF_SD_[NOMBRE]_DAO | ZIF_SD_QUICK_ORDERS_DAO |
| Clase DAO | ZCL_SD_[NOMBRE]_DAO | ZCL_SD_QUICK_ORDERS_DAO |
| Clase servicio | ZCL_SD_[NOMBRE] | ZCL_SD_QUICK_ORDERS |
| Clase test | ZCL_SD_[NOMBRE]_TEST | ZCL_SD_QUICK_ORDERS_TEST |
| Reporte | ZR_SD_[NOMBRE] | ZR_SD_QUICK_ORDERS |
| Mock local | LTD_MOCK_[NOMBRE] | LTD_MOCK_DAO |

### Variables

| Scope | Prefijo | Ejemplo |
|-------|---------|---------|
| Instancia objeto | mo_ | mo_dao |
| Instancia valor | mv_ | mv_has_data |
| Instancia tabla | mt_ | mt_data |
| Local valor | lv_ | lv_count |
| Local tabla | lt_ | lt_result |
| Local objeto | lo_ | lo_columns |
| Import valor | iv_ | iv_field |
| Import tabla | it_ | it_erdat |
| Export valor | ev_ | ev_count |
| Export tabla | et_ | et_data |

---

## Checklist antes de transportar

Antes de liberar cualquier orden de transporte, verificar:

- [ ] ¿La lógica de negocio está en una clase, no en el reporte?
- [ ] ¿El acceso a datos está en un DAO separado?
- [ ] ¿La clase de negocio depende de una interfaz ZIF_, no de una clase concreta?
- [ ] ¿Existe una clase _TEST con ABAP Unit?
- [ ] ¿Los tests pasan en verde?
- [ ] ¿Se usan campos explícitos en los SELECTs (no SELECT *)?
- [ ] ¿No hay SELECTs dentro de LOOPs?
- [ ] ¿Los métodos públicos tienen documentación ABAP Doc?
- [ ] ¿Se usa CL_SALV_TABLE para la salida ALV?
- [ ] ¿Las variables siguen las convenciones de nomenclatura?

---

## Preguntas frecuentes

**¿Esto no es mucho código para un reporte simple?**
Son 5 objetos en lugar de 1, sí. Pero cada uno es pequeño, claro y testeable. El tiempo extra de creación se recupera la primera vez que necesitás hacer un cambio o investigar un bug.

**¿Tengo que hacer esto para TODOS los desarrollos?**
Para cualquier desarrollo nuevo que tenga lógica de negocio, sí. Para un reporte que es literalmente un SELECT y un ALV sin procesamiento, se puede simplificar, pero el DAO separado sigue siendo buena práctica.

**¿Y los desarrollos existentes?**
No vamos a refactorizar todo lo que ya existe. Pero si tocamos un programa existente para un cambio significativo, aprovechamos para extraer la lógica a clases.

**¿Cómo ejecuto los tests?**
En Eclipse ADT: click derecho sobre la clase _TEST → Run As → ABAP Unit Test. También se pueden ejecutar desde SE80 o con la transacción SAUNIT_CLIENT_SETUP para ejecución masiva.

**¿El mock no es "hacer trampa"?**
No. El mock aísla lo que queremos probar. Si queremos validar que la clase de negocio cuenta bien los registros, no necesitamos una base de datos real. El DAO real se prueba por separado con tests de integración si es necesario.
