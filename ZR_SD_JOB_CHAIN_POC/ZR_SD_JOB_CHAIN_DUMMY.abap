*&---------------------------------------------------------------------*
*& Report ZR_SD_JOB_CHAIN_DUMMY
*&---------------------------------------------------------------------*
*& Programa dummy para ser ejecutado como paso del Job sucesor.
*& Solo escribe un log para confirmar que el encadenamiento funcionó.
*&---------------------------------------------------------------------*
REPORT zr_sd_job_chain_dummy.

START-OF-SELECTION.

  WRITE: / '================================================'.
  WRITE: / '  JOB SUCESOR EJECUTADO EXITOSAMENTE'.
  WRITE: / '================================================'.
  WRITE: / 'Fecha:', sy-datum.
  WRITE: / 'Hora:', sy-uzeit.
  WRITE: / 'Usuario:', sy-uname.
  WRITE: / 'Sistema:', sy-sysid, '| Mandante:', sy-mandt.
  WRITE: / ''.
  WRITE: / 'Este programa fue lanzado automáticamente'.
  WRITE: / 'por el mecanismo de Job Chaining (PRED_JOBNAME).'.
  WRITE: / '================================================'.
