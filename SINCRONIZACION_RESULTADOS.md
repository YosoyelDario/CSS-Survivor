# Sincronización de resultados

- Los intentos se guardan primero en `user://pending_uploads.json`.
- Si Google tarda o no hay conexión, el intento permanece en la cola.
- Al volver a abrir CSS Survivor, la cola se reintenta automáticamente.
- El timeout de las peticiones se amplió de 8 s a 20 s para tolerar Apps Script.
- El ranking sigue calculando la suma del mejor puntaje de cada nivel.

Este cambio no modifica niveles, preguntas, combate, puntajes, audio ni temporizadores.
