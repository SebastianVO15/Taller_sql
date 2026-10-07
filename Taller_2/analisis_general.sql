-- =====================================================================
-- Taller 2 - Consultas | Empleo/Desempleo CEDE (1967-1970)
-- Archivo: analisis_general.sql
-- =====================================================================
-- Supuestos generales:
--   * PET (poblacion en edad de trabajar): edad entre 12 y 98.
--     Se excluyen edad = -1 (menores de un anio) y edad = 99 (sin informacion).
--   * sexo: 1 = Hombre, 2 = Mujer. Se excluyen registros sin sexo.
--   * testudio: -1 = no estudio (se cuenta como 0 anios); 99 = sin informacion (se excluye).
-- =====================================================================

SET search_path TO taller_2;

-- ---------------------------------------------------------------------
-- 1.1 Numero de viviendas y hogares por ciudad
-- ---------------------------------------------------------------------
-- Intuicion: partimos de hogar y usamos INNER JOIN con vivienda y ciudad,
-- de modo que solo se cuentan hogares que tengan vivienda y ciudad
-- asociadas. COUNT(DISTINCT ...) evita contar dos veces una vivienda que
-- tenga varios hogares.
SELECT
    c.nombre             AS ciudad,
    COUNT(DISTINCT v.id) AS viviendas,
    COUNT(DISTINCT h.id) AS hogares
FROM hogar AS h
INNER JOIN vivienda AS v ON v.id = h.id_vivienda
INNER JOIN ciudad   AS c ON c.id = v.id_ciudad
GROUP BY c.nombre
ORDER BY c.nombre;

-- INTERPRETACION: (completar con los resultados. Ej.: la ciudad con mas
-- hogares es ___, lo que es coherente con su tamano poblacional; el
-- cociente hogares/viviendas muestra si hay hacinamiento de hogares.)


-- ---------------------------------------------------------------------
-- 1.2 Promedio de edad y anios de estudio por sexo (solo PET)
-- ---------------------------------------------------------------------
-- Intuicion: filtramos PET y sexo valido; los -1 de testudio se
-- reemplazan por 0 (no estudio) y los 99 (sin informacion) se excluyen
-- para no sesgar el promedio.
SELECT
    CASE
        WHEN ei.sexo = 1 THEN 'Hombre'
        WHEN ei.sexo = 2 THEN 'Mujer'
    END AS sexo,

    ROUND(AVG(ei.edad), 2) AS promedio_edad,

    ROUND(
        AVG(
            CASE
                WHEN ei.testudio = -1 THEN 0
                WHEN ei.testudio = 99 THEN NULL
                ELSE ei.testudio
            END
        ),
        2
    ) AS promedio_tiempo_estudio

FROM encuesta_integrante AS ei
WHERE ei.sexo IN (1, 2)
  AND ei.edad BETWEEN 12 AND 98
GROUP BY ei.sexo;

-- INTERPRETACION: (completar. Ej.: los hombres/mujeres tienen en
-- promedio ___ anios de estudio frente a ___, lo que indica una brecha
-- educativa de ___ anios.)


-- ---------------------------------------------------------------------
-- 1.3 Porcentaje de alfabetas y universitarios por sexo (solo PET)
-- ---------------------------------------------------------------------
-- Intuicion: lee_escribe y grado_universitario son variables 0/1, por lo
-- que su promedio es directamente la proporcion de 1s. Se multiplica por
-- 100 para expresarlo en porcentaje.
SELECT
    CASE ei.sexo WHEN 1 THEN 'Hombre' WHEN 2 THEN 'Mujer' END AS sexo,
    ROUND(100.0 * AVG(ei.lee_escribe), 2)         AS porcentaje_alfabeta,
    ROUND(100.0 * AVG(ei.grado_universitario), 2) AS porcentaje_universitario
FROM encuesta_integrante AS ei
WHERE ei.sexo IN (1, 2)
  AND ei.edad BETWEEN 12 AND 98
GROUP BY ei.sexo;

-- INTERPRETACION: (completar. Ej.: la alfabetizacion es de ___% en
-- hombres y ___% en mujeres; el porcentaje universitario es bajo en
-- ambos sexos, lo cual es esperable para la Colombia de 1967-1970.)









