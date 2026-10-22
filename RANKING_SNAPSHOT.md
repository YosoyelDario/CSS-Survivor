# Ranking global por snapshot

El ranking global se sincroniza con los mejores puntajes locales por nivel:

- nivel_1 = mejor puntaje local N1
- nivel_2 = mejor puntaje local N2
- nivel_3 = mejor puntaje local N3
- puntaje_total = N1 + N2 + N3

Al terminar un intento, el paquete incluye este snapshot. Además, al pulsar GLOBAL > CONECTAR se vuelve a enviar el snapshot antes de descargar el Top 10.

Esto hace que el ranking pueda reconstruirse aunque un intento individual no haya llegado a Google. Los datos académicos de Intentos/Respuestas siguen independientes.
