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

-- INTERPRETACION:  Solo 5 de las 9 ciudades de la encuesta tienen hogares
-- con vivienda y ciudad asociadas: Bogota (2757 viviendas, 14980
-- hogares), Medellin (554, 674), Ibague (438, 531), Cali (578, 580) y
-- Barrancabermeja (432, 446). Bogota concentra el 87 % de los 17211
-- hogares, por lo que cualquier resultado agregado refleja sobre todo a
-- la capital. En las otras ciudades hay entre 1,0 y 1,2 hogares por
-- vivienda, mientras que en Bogota la razon es de 5,4. Una diferencia tan
-- grande no parece hacinamiento real: es mas probable que los
-- identificadores de vivienda de Bogota se repitan entre los cuatro
-- anios de la encuesta, de modo que una misma vivienda acumula hogares
-- de distintos levantamientos.


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

-- INTERPRETACION: La edad promedio de la PET es practicamente igual
-- entre sexos (30,70 anios en hombres y 30,36 en mujeres), lo que
-- muestra una poblacion joven. En educacion si hay brecha: los hombres
-- tienen en promedio 6,31 anios de estudio frente a 5,35 de las mujeres,
-- casi un anio menos (0,96). En ambos casos el promedio apenas supera la
-- primaria, coherente con la Colombia urbana de finales de los sesenta.
-- La muestra tiene mas mujeres (32150) que hombres (26637).


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

-- INTERPRETACION: La alfabetizacion es alta en ambos sexos, pero mayor
-- en hombres (96,35 %) que en mujeres (91,38 %), una brecha de 5 puntos
-- porcentuales. El grado universitario es muy escaso: 3,60 % de los
-- hombres y 1,06 % de las mujeres, es decir, los hombres tienen 3,4
-- veces mas probabilidad de tenerlo. La brecha de genero es entonces
-- mas marcada en la educacion superior que en la basica. Como AVG ignora
-- los NULL, las 792 personas sin dato de grado universitario no entran
-- en ese porcentaje. Ademas hay 47 personas con grado universitario que
-- figuran como no alfabetas, lo que es otra inconsistencia de la base.






