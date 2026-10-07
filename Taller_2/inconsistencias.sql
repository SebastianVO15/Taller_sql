-- =====================================================================
-- Taller 2 - Consultas | Empleo/Desempleo CEDE (1967-1970)
-- Archivo: inconsistencias.sql
-- =====================================================================

SET search_path TO taller_2;

-- ---------------------------------------------------------------------
-- 3. Encuestas de 1967 donde num_personas es menor al numero de
--    integrantes realmente entrevistados
-- ---------------------------------------------------------------------
-- Intuicion: num_personas es lo que el hogar reporta como su tamano, pero
-- en encuesta_integrante hay una fila por cada persona entrevistada.
-- Contamos las filas de encuesta_integrante por encuesta y las comparamos
-- con num_personas; si hay mas entrevistados que los declarados, el campo
-- num_personas es inconsistente (redundancia mal mantenida: el mismo dato
-- esta guardado en dos lugares y no coincide).
-- Nota: aunque el enunciado ubica num_personas en hogar, segun el
-- diagrama esta en la tabla encuesta, que es la que se usa aqui.
SELECT
    e.id         AS id_encuesta,
    e.num_personas,
    COUNT(ei.id) AS num_personas_entrevistadas
FROM encuesta AS e
INNER JOIN encuesta_integrante AS ei ON ei.id_encuesta = e.id
WHERE e.anio = 1967
GROUP BY e.id, e.num_personas
HAVING COUNT(ei.id) > e.num_personas
ORDER BY e.id;

-- INTERPRETACION: (completar. Ej.: se encontraron ___ encuestas en 1967
-- con mas entrevistados que los reportados, es decir ___ % del total del
-- anio. Esto muestra que num_personas no es confiable y deberia
-- calcularse a partir de encuesta_integrante en lugar de almacenarse.)
