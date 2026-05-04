*&---------------------------------------------------------------------*
*& Report ZR_SD_JOB_CHAIN_POC
*&---------------------------------------------------------------------*
*& POC: Job Chaining en SAP ECC
*& Permite agendar un Job B que se ejecuta automáticamente cuando
*& finaliza un Job A (predecesor).
*& Usa JOB_OPEN / SUBMIT VIA JOB / JOB_CLOSE con PRED_JOBNAME.
*&---------------------------------------------------------------------*
REPORT zr_sd_job_chain_poc.

*----------------------------------------------------------------------*
* Pantalla de selección
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  PARAMETERS: p_pjob  TYPE btcjob   OBLIGATORY DEFAULT 'JOB_A_TEST',    "Nombre Job predecesor
              p_pjcnt TYPE btcjobcnt OBLIGATORY.                         "Número Job predecesor (de SM37)
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.
  PARAMETERS: p_sjob  TYPE btcjob OBLIGATORY DEFAULT 'JOB_B_SUCESOR',   "Nombre del Job sucesor
              p_rprog TYPE sy-repid OBLIGATORY DEFAULT 'ZR_SD_JOB_CHAIN_DUMMY'. "Report a ejecutar en Job B
SELECTION-SCREEN END OF BLOCK b02.

*----------------------------------------------------------------------*
* Variables
*----------------------------------------------------------------------*
DATA: lv_jobcount  TYPE btcjobcnt,
      lv_released  TYPE btch0000-char1.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  " 1. Abrir el Job sucesor
  CALL FUNCTION 'JOB_OPEN'
    EXPORTING
      jobname          = p_sjob
    IMPORTING
      jobcount         = lv_jobcount
    EXCEPTIONS
      cant_create_job  = 1
      invalid_job_data = 2
      jobname_missing  = 3
      OTHERS           = 4.

  IF sy-subrc <> 0.
    WRITE: / 'Error al abrir Job sucesor. SY-SUBRC:', sy-subrc.
    RETURN.
  ENDIF.

  WRITE: / 'Job sucesor abierto:', p_sjob, '| Número:', lv_jobcount.

  " 2. Agregar paso: ejecutar el report indicado
  SUBMIT (p_rprog)
    VIA JOB p_sjob NUMBER lv_jobcount
    AND RETURN.

  IF sy-subrc <> 0.
    WRITE: / 'Error al agregar paso al Job. SY-SUBRC:', sy-subrc.
    RETURN.
  ENDIF.

  WRITE: / 'Paso agregado: programa', p_rprog.

  " 3. Cerrar el Job con dependencia del predecesor
  CALL FUNCTION 'JOB_CLOSE'
    EXPORTING
      jobcount             = lv_jobcount
      jobname              = p_sjob
      pred_jobcount        = p_pjcnt
      pred_jobname         = p_pjob
      strtimmed            = abap_false
    IMPORTING
      job_was_released     = lv_released
    EXCEPTIONS
      cant_start_immediate = 1
      invalid_startdate    = 2
      jobname_missing      = 3
      job_close_failed     = 4
      job_nosteps          = 5
      job_notex            = 6
      lock_failed          = 7
      invalid_target       = 8
      invalid_time_zone    = 9
      OTHERS               = 10.

  IF sy-subrc <> 0.
    WRITE: / 'Error al cerrar/encadenar Job. SY-SUBRC:', sy-subrc.
    WRITE: / 'Mensaje:', sy-msgv1, sy-msgv2, sy-msgv3, sy-msgv4.
    RETURN.
  ENDIF.

  WRITE: / ''.
  WRITE: / '=== Job encadenado exitosamente ==='.
  WRITE: / 'Job sucesor:', p_sjob, '| Número:', lv_jobcount.
  WRITE: / 'Esperando a que termine:', p_pjob, '| Número:', p_pjcnt.
  WRITE: / 'Released:', lv_released.
  WRITE: / ''.
  WRITE: / 'Verificar en SM37 que el Job B queda en estado "Scheduled"'.
  WRITE: / 'y se lanza automáticamente al finalizar Job A.'.
