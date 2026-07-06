/* =====================================================
    SISTEMA HOSPITAL - ARCHIVO COMPLETO EXAMEN
===================================================== */

-- ============================================
-- CREACIÓN DE TABLAS
-- ============================================

CREATE TABLE pacientes(
    id_paciente SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    edad INT,
    genero VARCHAR(20)
);

CREATE TABLE doctores(
    id_doctor SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    especialidad VARCHAR(100)
);

CREATE TABLE citas(
    id_cita SERIAL PRIMARY KEY,
    id_paciente INT,
    id_doctor INT,
    fecha DATE,
    motivo VARCHAR(200),
    FOREIGN KEY (id_paciente) REFERENCES pacientes(id_paciente),
    FOREIGN KEY (id_doctor) REFERENCES doctores(id_doctor)
);

CREATE TABLE tratamientos(
    id_tratamiento SERIAL PRIMARY KEY,
    id_cita INT,
    descripcion VARCHAR(200),
    costo DECIMAL,
    FOREIGN KEY (id_cita) REFERENCES citas(id_cita)
);


-- ============================================
-- INSERTS
-- ============================================

INSERT INTO pacientes(nombre, edad, genero) VALUES
('Ana Torres', 25, 'Femenino'),
('Luis Perez', 40, 'Masculino'),
('Carlos Ramirez', 35, 'Masculino'),
('Andrea Gomez', 29, 'Femenino'),
('Alejandro Ruiz', 50, 'Masculino');

INSERT INTO doctores(nombre, especialidad) VALUES
('Dr. Martinez', 'Cardiologia'),
('Dr. Lopez', 'Dermatologia'),
('Dr. Sanchez', 'Pediatria'),
('Dr. Rojas', 'Neurologia');

INSERT INTO citas(id_paciente, id_doctor, fecha, motivo) VALUES
(1, 1, '2024-06-01', 'Chequeo general'),
(2, 2, '2024-06-02', 'Problema piel'),
(3, 1, '2024-06-03', 'Dolor pecho'),
(1, 3, '2024-06-04', 'Consulta'),
(4, 4, '2024-06-05', 'Dolor cabeza'),
(5, 1, '2024-06-06', 'Control');

INSERT INTO tratamientos(id_cita, descripcion, costo) VALUES
(1, 'Examen general', 100),
(2, 'Tratamiento piel', 150),
(3, 'Electrocardiograma', 300),
(4, 'Revision', 80),
(5, 'Resonancia', 500),
(6, 'Control', 200);


-- ============================================
-- CONSULTAS
-- ============================================

-- 1. Pacientes mayores de 30
SELECT nombre, edad
FROM pacientes
WHERE edad > 30;

-- 2. Citas con paciente y doctor
SELECT p.nombre AS paciente, d.nombre AS doctor, c.fecha
FROM pacientes p
JOIN citas c ON p.id_paciente = c.id_paciente
JOIN doctores d ON c.id_doctor = d.id_doctor;

-- 3. Doctores por especialidad
SELECT *
FROM doctores
WHERE especialidad = 'Cardiologia';

-- 4. Citas por doctor
SELECT d.nombre, COUNT(*) AS total_citas
FROM citas c
JOIN doctores d ON c.id_doctor = d.id_doctor
GROUP BY d.nombre;

-- 5. Tratamientos caros
SELECT *
FROM tratamientos
WHERE costo > 100;


-- ============================================
-- TOTAL GASTADO POR PACIENTE
-- ============================================

SELECT p.nombre, SUM(t.costo) AS total_gastado
FROM pacientes p
JOIN citas c ON p.id_paciente = c.id_paciente
JOIN tratamientos t ON c.id_cita = t.id_cita
GROUP BY p.nombre;


-- ============================================
-- VISTA
-- ============================================

CREATE VIEW historial_medico AS
SELECT 
    p.nombre AS paciente,
    d.nombre AS doctor,
    c.fecha,
    t.descripcion,
    t.costo
FROM pacientes p
JOIN citas c ON p.id_paciente = c.id_paciente
JOIN doctores d ON c.id_doctor = d.id_doctor
JOIN tratamientos t ON c.id_cita = t.id_cita;

-- usar vista
SELECT * FROM historial_medico;


-- ============================================
-- PROCEDIMIENTO ALMACENADO
-- ============================================

DELIMITER //

CREATE PROCEDURE insertar_cita_tratamiento(
    IN p_id_paciente INT,
    IN p_id_doctor INT,
    IN p_fecha DATE,
    IN p_motivo VARCHAR(200),
    IN p_descripcion VARCHAR(200),
    IN p_costo DECIMAL
)
BEGIN
    DECLARE v_id_cita INT;

    -- Validar paciente
    IF NOT EXISTS (
        SELECT 1 FROM pacientes WHERE id_paciente = p_id_paciente
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Paciente no existe';
    END IF;

    -- Validar costo
    IF p_costo <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Costo inválido';
    END IF;

    -- Insertar cita
    INSERT INTO citas(id_paciente, id_doctor, fecha, motivo)
    VALUES (p_id_paciente, p_id_doctor, p_fecha, p_motivo);

    -- Obtener ID
    SET v_id_cita = LAST_INSERT_ID();

    -- Insertar tratamiento
    INSERT INTO tratamientos(id_cita, descripcion, costo)
    VALUES (v_id_cita, p_descripcion, p_costo);

END //

DELIMITER ;

-- Ejecutar procedimiento
CALL insertar_cita_tratamiento(
    1,
    2,
    '2024-07-10',
    'Dolor',
    'Medicamento',
    150
);

-- ============================================
-- CREAR USUARIO
-- ============================================

-- Crear usuario con contraseña
CREATE USER usuario_prueba WITH PASSWORD '123456';

-- ============================================
-- PERMISOS A NIVEL DE BASE DE DATOS
-- ============================================

-- Permitir conexión a la base de datos
GRANT CONNECT ON DATABASE postgres TO usuario_prueba;

-- ============================================
-- PERMISOS SOBRE ESQUEMA
-- ============================================

-- Permitir usar el esquema public
GRANT USAGE ON SCHEMA public TO usuario_prueba;

-- ============================================
-- PERMISOS SOBRE TABLAS
-- ============================================

-- Permisos básicos (CRUD)
GRANT SELECT, INSERT, UPDATE, DELETE 
ON ALL TABLES IN SCHEMA public 
TO usuario_prueba;

-- Para futuras tablas (esto da puntos extra )
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE 
ON TABLES TO usuario_prueba;

-- ============================================
-- PERMISOS SOBRE SECUENCIAS (IMPORTANTE EN SERIAL)
-- ============================================

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public 
TO usuario_prueba;

-- ============================================
-- PERMISOS SOBRE PROCEDIMIENTOS
-- ============================================

-- Permitir ejecutar procedimientos
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public 
TO usuario_prueba;

-- ============================================
-- REVOCAR PERMISOS (por si te lo preguntan)
-- ============================================

-- Quitar permisos de insertar
REVOKE INSERT ON ALL TABLES IN SCHEMA public 
FROM usuario_prueba;

-- Quitar todos los permisos
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public 
FROM usuario_prueba;

-- ============================================
-- EJEMPLO MÁS ESPECÍFICO
-- ============================================

-- Dar permiso SOLO de lectura a una tabla
GRANT SELECT ON clientes TO usuario_prueba;

-- Dar permiso SOLO de insertar en ordenes
GRANT INSERT ON ordenes TO usuario_prueba;
