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

-- INTERPRETACION: (completar. Ej.: el ingreso promedio paso de ___ en
-- 1967 a ___ en 1970, una variacion de ___ %, consistente con la
-- inflacion/crecimiento de la epoca.)


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

-- INTERPRETACION: (completar. Ej.: ___ tiene la mayor tasa de ocupacion
-- (___ %) y ___ la menor (___ %).)


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

-- INTERPRETACION: (completar. Ej.: el desempleo paso de ___ % a ___ %
-- entre 1967 y 1970; el subempleo es ___ .)


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

-- INTERPRETACION: (completar. Ej.: ___ presenta el mayor desempleo en
-- ___; la TGO ronda ___, es decir, ___ de cada 100 personas en edad de
-- trabajar participa en el mercado laboral.)


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

-- INTERPRETACION: En general NO tiene mucho sentido. La encuesta solo
-- cubre las principales ciudades, casi una por departamento, por lo que
-- agrupar por departamento replica el resultado por ciudad (la excepcion
-- seria un departamento con varias ciudades, p. ej. Santander con
-- Bucaramanga y Barrancabermeja). Ademas, la muestra es urbana y no
-- representa al resto del departamento (zonas rurales y municipios
-- pequenos), asi que la tasa departamental seria enganosa.
