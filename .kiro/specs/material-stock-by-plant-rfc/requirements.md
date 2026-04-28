# Documento de Requisitos

## Introducción

Este documento describe los requisitos funcionales y técnicos para la creación del Function Module RFC-enabled `ZFM_SD_GET_MATERIAL_STOCK`, que permite a sistemas externos (Mulesoft/Salesforce) consultar el stock de un material por planta para una sociedad determinada. La funcionalidad replica programáticamente la información que actualmente se obtiene de la transacción MMBE (Stock Overview), incluyendo la verificación de exclusiones de planta definidas en la tabla de condiciones KOTG504.

El FM delega la lógica de negocio a clases OO siguiendo los principios SOLID y los estándares de codificación Holcim BP.

---

## Glosario

- **ZFM_SD_GET_MATERIAL_STOCK**: Function Module RFC-enabled, punto de entrada para la consulta de stock por planta.
- **ZFG_SD_STOCK_QUERY**: Function Group que contiene el FM.
- **ZCL_SD_STOCK_QUERY**: Clase orquestadora principal; implementa `ZIF_SD_STOCK_QUERY`.
- **ZIF_SD_STOCK_QUERY**: Interfaz del orquestador de consulta de stock.
- **ZCL_SD_STOCK_DAO**: Clase de acceso a datos (DAO) para tablas MARD, MARC, T001W, T001K, MAKT; implementa `ZIF_SD_STOCK_DAO`.
- **ZIF_SD_STOCK_DAO**: Interfaz del DAO de stock.
- **ZCL_SD_EXCLUSION_CHECKER**: Clase que verifica exclusiones en KOTG504; implementa `ZIF_SD_EXCLUSION_CHECKER`.
- **ZIF_SD_EXCLUSION_CHECKER**: Interfaz del verificador de exclusiones.
- **ZST_SD_PLANT_STOCK**: Estructura de respuesta por planta (WERKS, NAME1, LABST, EINME, SPEME, EISBE, IS_EXCLUDED, EXCLUSION_REASON).
- **ZTY_SD_PLANT_STOCK_T**: Tipo tabla de `ZST_SD_PLANT_STOCK`.
- **MARD**: Tabla SAP de stock por planta/almacén (campos: MATNR, WERKS, LGORT, LABST, EINME, SPEME, EISBE).
- **MARC**: Tabla SAP de datos de material por planta.
- **T001W**: Tabla SAP de plantas (campos: WERKS, NAME1, BWKEY).
- **T001K**: Tabla SAP de valoración — relaciona sociedad (BUKRS) con clave de valoración (BWKEY), que a su vez se corresponde con WERKS en T001W.
- **MAKT**: Tabla SAP de descripciones de material (campos: MATNR, SPRAS, MAKTX).
- **KOTG504**: Tabla de condiciones de exclusión planta/material (campos: App, List/excl., WERKS, MATNR, Valid From, Valid to).
- **IS_EXCLUDED**: Flag ABAP_BOOL ('X' = excluida, space = no excluida).
- **Registro activo en KOTG504**: Registro donde Valid From <= SY-DATUM y (Valid to >= SY-DATUM o Valid to está vacío).
- **LABST**: Stock de libre utilización (unrestricted use).
- **EINME**: Stock en control de calidad (quality inspection).
- **SPEME**: Stock bloqueado (blocked stock).
- **EISBE**: Stock de seguridad / en pedido (on-order stock).
- **IV_MATNR**: Parámetro de entrada — número de material (tipo MATNR).
- **IV_BUKRS**: Parámetro de entrada — sociedad (tipo BUKRS).
- **ET_PLANT_STOCK**: Parámetro de salida tabla — stock por planta (tipo ZTY_SD_PLANT_STOCK_T).
- **ET_MESSAGES**: Parámetro de salida tabla — mensajes de error/warning (tipo BAPIRET2_T).
- **EV_MATNR_DESC**: Parámetro de salida valor — descripción del material en idioma EN.

---

## Requisitos

### Requisito 1: Interfaz RFC del Function Module

**User Story:** Como desarrollador de integración en Mulesoft, quiero invocar un FM RFC-enabled con un material y una sociedad, para obtener el stock por planta de forma programática sin depender de capturas de pantalla de MMBE.

#### Criterios de Aceptación

1. THE ZFM_SD_GET_MATERIAL_STOCK SHALL estar definido como `REMOTE-ENABLED MODULE` dentro del Function Group ZFG_SD_STOCK_QUERY en el paquete ZDEV_SD.
2. THE ZFM_SD_GET_MATERIAL_STOCK SHALL aceptar los parámetros de importación IV_MATNR (tipo MATNR) e IV_BUKRS (tipo BUKRS).
3. THE ZFM_SD_GET_MATERIAL_STOCK SHALL retornar el parámetro de exportación EV_MATNR_DESC (tipo MAKT-MAKTX).
4. THE ZFM_SD_GET_MATERIAL_STOCK SHALL retornar la tabla ET_PLANT_STOCK (tipo ZTY_SD_PLANT_STOCK_T).
5. THE ZFM_SD_GET_MATERIAL_STOCK SHALL retornar la tabla ET_MESSAGES (tipo BAPIRET2_T) con mensajes de error, warning o informativos.
6. THE ZFM_SD_GET_MATERIAL_STOCK SHALL delegar toda la lógica de negocio a una instancia de ZIF_SD_STOCK_QUERY, sin contener lógica de negocio propia.

---

### Requisito 2: Consulta de Stock por Planta y Sociedad

**User Story:** Como usuario de Salesforce, quiero consultar el stock de un material en todas las plantas de una sociedad, para saber en qué centros de distribución está disponible el material.

#### Criterios de Aceptación

1. WHEN ZFM_SD_GET_MATERIAL_STOCK es invocado con IV_MATNR e IV_BUKRS válidos, THE ZCL_SD_STOCK_QUERY SHALL retornar en ET_PLANT_STOCK únicamente las plantas asociadas a IV_BUKRS mediante la relación T001K (BUKRS → BWKEY) y T001W (BWKEY = WERKS).
2. WHEN ZFM_SD_GET_MATERIAL_STOCK es invocado con IV_MATNR e IV_BUKRS válidos, THE ZCL_SD_STOCK_DAO SHALL consultar MARD para obtener los campos LABST, EINME, SPEME e EISBE para cada combinación MATNR+WERKS encontrada.
3. WHEN ZFM_SD_GET_MATERIAL_STOCK es invocado con IV_MATNR e IV_BUKRS válidos, THE ZCL_SD_STOCK_DAO SHALL consultar T001W para obtener NAME1 de cada planta retornada.
4. WHEN ZFM_SD_GET_MATERIAL_STOCK es invocado con IV_MATNR e IV_BUKRS válidos, THE ZCL_SD_STOCK_DAO SHALL consultar MAKT con SPRAS = 'EN' para obtener EV_MATNR_DESC.
5. THE ZCL_SD_STOCK_DAO SHALL ejecutar todas las consultas a base de datos sin realizar SELECTs dentro de LOOPs, usando FOR ALL ENTRIES o JOINs según corresponda.
6. WHEN el material IV_MATNR no existe en ninguna planta de la sociedad IV_BUKRS, THEN THE ZCL_SD_STOCK_QUERY SHALL retornar ET_PLANT_STOCK vacío y SHALL agregar un mensaje de tipo 'I' (informativo) en ET_MESSAGES indicando que no se encontró stock para el material en la sociedad.

---

### Requisito 3: Verificación de Exclusiones KOTG504

**User Story:** Como usuario de Salesforce, quiero saber si una planta está en la lista de exclusión para un material, para tomar decisiones de abastecimiento correctas sin necesidad de consultar KOTG504 manualmente.

#### Criterios de Aceptación

1. WHEN ZCL_SD_EXCLUSION_CHECKER evalúa una planta para un material, THE ZCL_SD_EXCLUSION_CHECKER SHALL consultar KOTG504 filtrando por MATNR = IV_MATNR y (WERKS = planta evaluada O WERKS vacío), con App = 'V' y List/excl. = 'ZB01'.
2. WHEN existe al menos un registro activo en KOTG504 para la combinación MATNR+WERKS (o MATNR con WERKS vacío), THEN THE ZCL_SD_EXCLUSION_CHECKER SHALL asignar IS_EXCLUDED = 'X' en la entrada correspondiente de ET_PLANT_STOCK.
3. WHEN no existe ningún registro activo en KOTG504 para la combinación MATNR+WERKS ni para MATNR con WERKS vacío, THEN THE ZCL_SD_EXCLUSION_CHECKER SHALL asignar IS_EXCLUDED = space en la entrada correspondiente de ET_PLANT_STOCK.
4. WHEN un registro de KOTG504 tiene Valid to < SY-DATUM, THE ZCL_SD_EXCLUSION_CHECKER SHALL ignorar ese registro y no considerarlo como exclusión activa.
5. WHEN IS_EXCLUDED = 'X', THE ZCL_SD_EXCLUSION_CHECKER SHALL asignar un texto descriptivo en EXCLUSION_REASON indicando el motivo de exclusión (planta específica o nivel material).
6. THE ZCL_SD_EXCLUSION_CHECKER SHALL evaluar las exclusiones para todas las plantas de ET_PLANT_STOCK en una única consulta a KOTG504, sin realizar SELECTs dentro de LOOPs.

---

### Requisito 4: Estructura de Respuesta por Planta

**User Story:** Como desarrollador de integración en Mulesoft, quiero recibir una estructura de datos completa y consistente por planta, para mapear la respuesta al modelo de datos de Salesforce sin transformaciones adicionales.

#### Criterios de Aceptación

1. THE ZST_SD_PLANT_STOCK SHALL contener los campos: WERKS (tipo WERKS_D), NAME1 (tipo T001W-NAME1), LABST (tipo MARD-LABST), EINME (tipo MARD-EINME), SPEME (tipo MARD-SPEME), EISBE (tipo MARD-EISBE), IS_EXCLUDED (tipo ABAP_BOOL), EXCLUSION_REASON (tipo CHAR255).
2. THE ZTY_SD_PLANT_STOCK_T SHALL definirse como TYPE TABLE OF ZST_SD_PLANT_STOCK.
3. WHEN una planta no tiene stock en MARD (no existe registro), THE ZCL_SD_STOCK_QUERY SHALL incluir la planta en ET_PLANT_STOCK con LABST, EINME, SPEME e EISBE en cero, si la planta está activa para el material en MARC.
4. WHEN ET_PLANT_STOCK contiene una entrada para una planta, THE LABST de esa entrada SHALL coincidir con el valor de MARD-LABST para la combinación MATNR+WERKS correspondiente.

---

### Requisito 5: Manejo de Errores e Inputs Inválidos

**User Story:** Como desarrollador de integración en Mulesoft, quiero recibir mensajes de error claros cuando los parámetros de entrada son inválidos, para poder informar al usuario de Salesforce de forma precisa.

#### Criterios de Aceptación

1. WHEN IV_MATNR está vacío al invocar ZFM_SD_GET_MATERIAL_STOCK, THEN THE ZFM_SD_GET_MATERIAL_STOCK SHALL retornar ET_PLANT_STOCK vacío y SHALL agregar un mensaje de tipo 'E' (error) en ET_MESSAGES indicando que el número de material es obligatorio.
2. WHEN IV_BUKRS está vacío al invocar ZFM_SD_GET_MATERIAL_STOCK, THEN THE ZFM_SD_GET_MATERIAL_STOCK SHALL retornar ET_PLANT_STOCK vacío y SHALL agregar un mensaje de tipo 'E' (error) en ET_MESSAGES indicando que la sociedad es obligatoria.
3. WHEN IV_MATNR no existe en la tabla MARA, THEN THE ZCL_SD_STOCK_QUERY SHALL retornar ET_PLANT_STOCK vacío y SHALL agregar un mensaje de tipo 'E' en ET_MESSAGES indicando que el material no existe en el sistema.
4. WHEN IV_BUKRS no existe en la tabla T001, THEN THE ZCL_SD_STOCK_QUERY SHALL retornar ET_PLANT_STOCK vacío y SHALL agregar un mensaje de tipo 'E' en ET_MESSAGES indicando que la sociedad no existe en el sistema.
5. IF ocurre una excepción no controlada durante la ejecución de ZCL_SD_STOCK_QUERY, THEN THE ZFM_SD_GET_MATERIAL_STOCK SHALL capturar la excepción y SHALL agregar un mensaje de tipo 'E' en ET_MESSAGES con la descripción del error, sin propagar la excepción al sistema llamante.

---

### Requisito 6: Arquitectura OO y Estándares Holcim BP

**User Story:** Como desarrollador ABAP en Holcim BP, quiero que el FM siga los estándares de arquitectura OO y los principios SOLID, para que el código sea mantenible, testeable y extensible.

#### Criterios de Aceptación

1. THE ZCL_SD_STOCK_QUERY SHALL depender de ZIF_SD_STOCK_DAO y ZIF_SD_EXCLUSION_CHECKER mediante inyección de dependencias en el constructor, no de las clases concretas ZCL_SD_STOCK_DAO y ZCL_SD_EXCLUSION_CHECKER directamente.
2. THE ZCL_SD_STOCK_QUERY SHALL implementar la interfaz ZIF_SD_STOCK_QUERY.
3. THE ZCL_SD_STOCK_DAO SHALL implementar la interfaz ZIF_SD_STOCK_DAO.
4. THE ZCL_SD_EXCLUSION_CHECKER SHALL implementar la interfaz ZIF_SD_EXCLUSION_CHECKER.
5. THE ZCL_SD_STOCK_QUERY SHALL tener una clase de prueba ZCL_SD_STOCK_QUERY_TEST con ABAP Unit que use test doubles para ZIF_SD_STOCK_DAO y ZIF_SD_EXCLUSION_CHECKER.
6. THE ZCL_SD_STOCK_DAO SHALL tener una clase de prueba ZCL_SD_STOCK_DAO_TEST con ABAP Unit.
7. THE ZCL_SD_EXCLUSION_CHECKER SHALL tener una clase de prueba ZCL_SD_EXCLUSION_CHECKER_TEST con ABAP Unit.
8. THE ZCL_SD_STOCK_DAO SHALL usar sintaxis moderna ABAP (VALUE, FILTER, REDUCE) donde aplique, y no usar SELECT * en ninguna consulta.
9. WHILE ZCL_SD_STOCK_QUERY orquesta la consulta, THE ZCL_SD_STOCK_QUERY SHALL no contener ningún acceso directo a tablas de base de datos (sin sentencias SELECT propias).

---

## Propiedades de Corrección (Correctness Properties)

*Una propiedad es una característica o comportamiento que debe mantenerse verdadero en todas las ejecuciones válidas del sistema — esencialmente, una declaración formal sobre lo que el sistema debe hacer. Las propiedades sirven como puente entre las especificaciones legibles por humanos y las garantías de corrección verificables por máquina.*

### Propiedad 1: Aislamiento por sociedad

*Para cualquier* combinación de material e IV_BUKRS válidos, todas las entradas en ET_PLANT_STOCK deben corresponder exclusivamente a plantas asociadas a IV_BUKRS mediante T001K/T001W, y ninguna entrada debe pertenecer a una sociedad distinta.

**Valida: Requisitos 2.1**

---

### Propiedad 2: Consistencia de stock con MARD

*Para cualquier* entrada en ET_PLANT_STOCK, los valores de LABST, EINME, SPEME e EISBE deben coincidir exactamente con los valores almacenados en MARD para la combinación MATNR+WERKS correspondiente.

**Valida: Requisitos 2.2, 4.4**

---

### Propiedad 3: Corrección del flag IS_EXCLUDED

*Para cualquier* planta retornada en ET_PLANT_STOCK, IS_EXCLUDED debe ser 'X' si y solo si existe al menos un registro activo en KOTG504 para esa combinación MATNR+WERKS (o MATNR con WERKS vacío). IS_EXCLUDED debe ser space en caso contrario.

**Valida: Requisitos 3.2, 3.3**

---

### Propiedad 4: Exclusiones con fecha vencida no cuentan

*Para cualquier* registro en KOTG504 cuyo campo Valid to sea menor a SY-DATUM, ese registro no debe influir en el valor de IS_EXCLUDED de ninguna planta en ET_PLANT_STOCK.

**Valida: Requisito 3.4**

---

### Propiedad 5: Exclusión a nivel material aplica a todas las plantas

*Para cualquier* material con un registro activo en KOTG504 donde WERKS está vacío, todas las plantas retornadas en ET_PLANT_STOCK para ese material deben tener IS_EXCLUDED = 'X'.

**Valida: Requisito 3.2**

---

### Propiedad 6: ET_PLANT_STOCK vacío con mensaje cuando no hay stock

*Para cualquier* combinación material+sociedad donde el material no existe en ninguna planta de la sociedad, ET_PLANT_STOCK debe estar vacío y ET_MESSAGES debe contener al menos un mensaje de tipo 'I' o 'E'.

**Valida: Requisitos 2.6, 5.3, 5.4**

---

### Propiedad 7: Descripción del material en idioma EN

*Para cualquier* material válido, EV_MATNR_DESC debe coincidir con el valor de MAKT-MAKTX para MATNR = IV_MATNR y SPRAS = 'EN'.

**Valida: Requisito 2.4**

---

### Propiedad 8: Completitud de campos en ET_PLANT_STOCK

*Para cualquier* entrada en ET_PLANT_STOCK, los campos WERKS, NAME1, IS_EXCLUDED deben estar siempre poblados (no vacíos), y los campos de stock (LABST, EINME, SPEME, EISBE) deben tener valor numérico >= 0.

**Valida: Requisitos 4.1, 4.3**
