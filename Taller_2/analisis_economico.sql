-- =====================================================================
-- Taller 2 - Consultas | Empleo/Desempleo CEDE (1967-1970)
-- Archivo: analisis_economico.sql
-- =====================================================================
-- Definiciones (variable actividad: 0 Inactivo, 1 Ocupado, 2 Subempleado,
-- 3 Cesante, 4 Nuevo):
--   PET = edad entre 12 y 98
--   PEA = actividad IN (1, 2, 3, 4)
--   OC  = actividad = 1
--   SE  = actividad = 2
--   DS  = actividad IN (3, 4)   (cesantes + nuevos en el mercado)
-- Asi, OC + SE + DS = PEA y los porcentajes suman 100 %.
-- =====================================================================

SET search_path TO taller_2;

-- ---------------------------------------------------------------------
-- 2.1 Promedio del ingreso familiar por anio
-- ---------------------------------------------------------------------
-- Intuicion: ingreso_familiar esta en encuesta (una fila por encuesta de
-- hogar), asi que se promedia directamente agrupando por anio.
SELECT
    e.anio,
    ROUND(AVG(e.ingreso_familiar), 2) AS promedio_ingreso_familiar
FROM encuesta AS e
GROUP BY e.anio
ORDER BY e.anio;

-- INTERPRETACION: El ingreso familiar promedio fue de 2653,63 en 1967,
-- 3693,56 en 1968, 3666,89 en 1969 y 3353,94 en 1970. Sube 39 % entre
-- 1967 y 1968, se mantiene en 1969 y cae 9 % en 1970; frente a 1967 el
-- ultimo anio queda 26 % por encima. Estos valores deben leerse con
-- cautela por tres razones: (1) el maximo de la variable es 99999 en
-- todos los anios, que parece un codigo de "sin informacion" no
-- documentado en el diccionario y que infla el promedio; (2) hay muchos
-- ingresos en cero, sobre todo en 1967 (605 de 6200 encuestas), que lo
-- reducen; y (3) las ciudades encuestadas cambian cada anio, asi que la
-- serie no compara la misma poblacion.


-- ---------------------------------------------------------------------
-- 2.2 Tasa de ocupacion por ciudad (TOC = OC / PET)
-- ---------------------------------------------------------------------
-- Intuicion: dentro de cada ciudad se cuentan los ocupados sobre toda la
-- PET. FILTER permite contar solo las filas que cumplen la condicion.
SELECT
    c.nombre AS ciudad,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ei.actividad = 1) / COUNT(*), 2)
        AS tasa_ocupacion
FROM encuesta_integrante AS ei
INNER JOIN encuesta AS e ON e.id = ei.id_encuesta
INNER JOIN hogar    AS h ON h.id = e.id_hogar
INNER JOIN vivienda AS v ON v.id = h.id_vivienda
INNER JOIN ciudad   AS c ON c.id = v.id_ciudad
WHERE ei.edad BETWEEN 12 AND 98
GROUP BY c.nombre
ORDER BY tasa_ocupacion DESC;

-- INTERPRETACION: Bogota tiene la mayor tasa de ocupacion (46,43 %),
-- seguida de Ibague (40,37 %), Cali (38,52 %), Barrancabermeja (38,18 %)
-- y Medellin (37,89 %). En todas las ciudades menos de la mitad de la
-- poblacion en edad de trabajar esta ocupada, lo que se explica por la
-- alta inactividad (estudiantes y personas dedicadas al hogar). Bogota
-- se separa del resto por unos 6 a 8 puntos porcentuales, coherente con
-- un mercado laboral mas grande y diversificado en la capital.


-- ---------------------------------------------------------------------
-- 2.3 % de ocupados, subempleados y desempleados sobre la PEA, por anio
-- ---------------------------------------------------------------------
-- Intuicion: el denominador es la PEA (solo actividad 1 a 4), por eso se
-- filtra en el WHERE. Al ser categorias excluyentes suman 100 %.
SELECT
    e.anio,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ei.actividad = 1) / COUNT(*), 2)
        AS porcentaje_ocupados,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ei.actividad = 2) / COUNT(*), 2)
        AS porcentaje_subempleados,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ei.actividad IN (3, 4)) / COUNT(*), 2)
        AS porcentaje_desesmpleados
FROM encuesta_integrante AS ei
INNER JOIN encuesta AS e ON e.id = ei.id_encuesta
WHERE ei.edad BETWEEN 12 AND 98
  AND ei.actividad IN (1, 2, 3, 4)
GROUP BY e.anio
ORDER BY e.anio;

-- INTERPRETACION: Los tres porcentajes suman 100 % en cada anio. Los
-- ocupados pasan de 86,01 % de la PEA en 1967 y 86,37 % en 1968 a
-- 91,34 % en 1969 y 91,08 % en 1970. El desempleo baja de 12,69 % en
-- 1967 a 7,21 % en 1969 y sube levemente a 8,07 % en 1970, una reduccion
-- de 4,6 puntos en el periodo. El subempleo es marginal en todos los
-- anios (entre 0,85 % y 1,76 %). La mejora debe tomarse con cuidado:
-- desde 1969 la muestra es casi solo Bogota, que tiene menor desempleo,
-- asi que parte de la caida se debe al cambio de ciudades encuestadas.


-- ---------------------------------------------------------------------
-- 2.4 TGO, TOC, TSE y TDS por ciudad y anio
-- ---------------------------------------------------------------------
-- Intuicion: TGO y TOC usan como denominador la PET (todas las personas
-- de 12 a 98); TSE y TDS usan la PEA. NULLIF evita division por cero si
-- alguna ciudad-anio no tuviera PEA. Se muestran como proporciones (0-1).
SELECT
    c.nombre AS ciudad,
    e.anio,
    ROUND(COUNT(*) FILTER (WHERE ei.actividad IN (1, 2, 3, 4))::numeric
          / COUNT(*), 4) AS tgo,
    ROUND(COUNT(*) FILTER (WHERE ei.actividad = 1)::numeric
          / COUNT(*), 4) AS toc,
    ROUND(COUNT(*) FILTER (WHERE ei.actividad = 2)::numeric
          / NULLIF(COUNT(*) FILTER (WHERE ei.actividad IN (1, 2, 3, 4)), 0), 4) AS tse,
    ROUND(COUNT(*) FILTER (WHERE ei.actividad IN (3, 4))::numeric
          / NULLIF(COUNT(*) FILTER (WHERE ei.actividad IN (1, 2, 3, 4)), 0), 4) AS tds
FROM encuesta_integrante AS ei
INNER JOIN encuesta AS e ON e.id = ei.id_encuesta
INNER JOIN hogar    AS h ON h.id = e.id_hogar
INNER JOIN vivienda AS v ON v.id = h.id_vivienda
INNER JOIN ciudad   AS c ON c.id = v.id_ciudad
WHERE ei.edad BETWEEN 12 AND 98
GROUP BY c.nombre, e.anio
ORDER BY c.nombre, e.anio;

-- INTERPRETACION: Solo hay 9 combinaciones ciudad-anio con datos, y
-- Bogota es la unica ciudad con los cuatro anios. El mayor desempleo se
-- observa en Cali en 1967 (TDS de 0,1577), seguido de Barrancabermeja en
-- 1967 (0,1477) y Medellin en 1968 (0,1462); el menor es el de Bogota en
-- 1969 (0,0712). La TGO esta entre 0,43 y 0,53: en Bogota unas 52 de
-- cada 100 personas en edad de trabajar participan en el mercado
-- laboral, frente a 43 a 47 en las demas ciudades. Bogota tambien tiene
-- la mayor TOC (0,45 a 0,48). En Bogota el desempleo cae de 0,1233 en
-- 1967 a 0,0807 en 1970, y en Barrancabermeja de 0,1477 a 0,0839 entre
-- 1967 y 1969. La TSE no supera 0,022 en ningun caso.


-- ---------------------------------------------------------------------
-- 2.5 ¿Tiene sentido agrupar por departamento?
-- ---------------------------------------------------------------------
-- Verificacion: cuantas ciudades de la encuesta hay en cada departamento.
SELECT
    d.nombre             AS departamento,
    COUNT(DISTINCT c.id) AS num_ciudades
FROM ciudad AS c
INNER JOIN departamento AS d ON d.id = c.id_departamento
GROUP BY d.nombre
ORDER BY num_ciudades DESC;

-- En la practica Bucaramanga no tiene encuestas en la base, por lo que
-- incluso Santander queda representado por una sola ciudad
-- (Barrancabermeja) y la agrupacion por departamento no aporta nada
-- distinto a la agrupacion por ciudad.
