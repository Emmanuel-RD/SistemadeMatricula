-- =====================================================
-- SISTEMA DE GESTIÓN DE MATRÍCULAS
-- Schema Completo de Base de Datos
-- =====================================================

-- =====================================================
-- EXTENSIONES
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- TABLA DE ROLES
-- =====================================================
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    permisos JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar roles por defecto
INSERT INTO roles (nombre, descripcion, permisos) VALUES
('admin', 'Administrador del sistema', '{"all": true}'::jsonb),
('docente', 'Docente del colegio', '{"ver_cursos": true, "ver_estudiantes": true, "editar_cursos": true}'::jsonb),
('alumno', 'Alumno del colegio', '{"ver_cursos": true, "matricularse": true}'::jsonb)
ON CONFLICT (nombre) DO NOTHING;

-- =====================================================
-- TABLA DE USUARIOS
-- =====================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    rol_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) UNIQUE,
    telefono VARCHAR(20),
    activo BOOLEAN DEFAULT true,
    email_confirmado BOOLEAN DEFAULT false,
    token_confirmacion VARCHAR(255),
    ultimo_acceso TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA DE DOCENTES
-- =====================================================
CREATE TABLE IF NOT EXISTS docentes (
    id BIGSERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT docentes_dni_formato CHECK (dni ~ '^[0-9]{8}$')
);

-- =====================================================
-- TABLA DE ALUMNOS
-- =====================================================
CREATE TABLE IF NOT EXISTS alumnos (
    id BIGSERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    grado INTEGER NOT NULL CHECK (grado >= 1 AND grado <= 6),
    foto_carnet TEXT,
    constancia_estudios TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT alumnos_dni_formato CHECK (dni ~ '^[0-9]{8}$')
);

-- =====================================================
-- TABLA DE CURSOS
-- =====================================================
CREATE TABLE IF NOT EXISTS cursos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    grado INTEGER NOT NULL CHECK (grado >= 1 AND grado <= 6),
    docente_id BIGINT REFERENCES docentes(id) ON DELETE SET NULL,
    dia_semana VARCHAR(20) NOT NULL CHECK (dia_semana IN ('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes')),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    capacidad INTEGER NOT NULL DEFAULT 30 CHECK (capacidad > 0),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA DE PERÍODOS
-- =====================================================
CREATE TABLE IF NOT EXISTS periodos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    anio INTEGER NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'borrador' CHECK (estado IN ('borrador', 'abierto', 'cerrado')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA DE MATRÍCULAS POR PERÍODO (una matrícula con múltiples cursos)
-- =====================================================
CREATE TABLE IF NOT EXISTS matriculas_periodo (
    id BIGSERIAL PRIMARY KEY,
    alumno_id BIGINT NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
    periodo_id BIGINT NOT NULL REFERENCES periodos(id) ON DELETE RESTRICT,
    grado INTEGER NOT NULL CHECK (grado >= 1 AND grado <= 6),
    fecha_matricula TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estado VARCHAR(20) NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa', 'cancelada', 'finalizada')),
    observaciones TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(alumno_id, periodo_id)
);

-- =====================================================
-- TABLA PUENTE MATRÍCULA-CURSOS (con snapshots)
-- =====================================================
CREATE TABLE IF NOT EXISTS matricula_cursos (
    id BIGSERIAL PRIMARY KEY,
    matricula_id BIGINT NOT NULL REFERENCES matriculas_periodo(id) ON DELETE CASCADE,
    curso_id BIGINT NOT NULL REFERENCES cursos(id) ON DELETE RESTRICT,
    curso_nombre_snapshot VARCHAR(200) NOT NULL,
    docente_id_snapshot BIGINT,
    docente_nombre_snapshot VARCHAR(200),
    grado_snapshot INTEGER NOT NULL,
    dia_semana_snapshot VARCHAR(20),
    hora_inicio_snapshot TIME,
    hora_fin_snapshot TIME,
    capacidad_snapshot INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(matricula_id, curso_id)
);

-- =====================================================
-- TABLA DE NOTAS POR BIMESTRE (referencia a matricula_cursos)
-- =====================================================
CREATE TABLE IF NOT EXISTS notas (
    id BIGSERIAL PRIMARY KEY,
    matricula_curso_id BIGINT NOT NULL REFERENCES matricula_cursos(id) ON DELETE CASCADE,
    bimestre SMALLINT NOT NULL CHECK (bimestre >= 1 AND bimestre <= 4),
    nota NUMERIC(5,2) NOT NULL CHECK (nota >= 0 AND nota <= 20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(matricula_curso_id, bimestre)
);

-- =====================================================
-- TABLA DE ASISTENCIAS (referencia a matricula_cursos)
-- =====================================================
CREATE TABLE IF NOT EXISTS asistencias (
    id BIGSERIAL PRIMARY KEY,
    matricula_curso_id BIGINT NOT NULL REFERENCES matricula_cursos(id) ON DELETE CASCADE,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    presente BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(matricula_curso_id, fecha)
);

-- =====================================================
-- TABLA DE MATRÍCULAS
-- =====================================================
CREATE TABLE IF NOT EXISTS matriculas (
    id BIGSERIAL PRIMARY KEY,
    alumno_id BIGINT NOT NULL REFERENCES alumnos(id) ON DELETE CASCADE,
    curso_id BIGINT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    fecha_matricula TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estado VARCHAR(20) DEFAULT 'activa' CHECK (estado IN ('activa', 'cancelada', 'finalizada')),
    UNIQUE(alumno_id, curso_id)
);

-- =====================================================
-- AJUSTES DE DNI PARA TABLAS EXISTENTES
-- =====================================================

-- Asegurar columna y restricciones en DOCENTES
ALTER TABLE IF EXISTS docentes ADD COLUMN IF NOT EXISTS dni VARCHAR(20);

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'docentes' AND constraint_name = 'docentes_dni_key'
    ) THEN
        ALTER TABLE docentes ADD CONSTRAINT docentes_dni_key UNIQUE (dni);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'docentes' AND constraint_name = 'docentes_dni_formato'
    ) THEN
        ALTER TABLE docentes ADD CONSTRAINT docentes_dni_formato CHECK (dni ~ '^[0-9]{8}$');
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM docentes WHERE dni IS NULL OR dni = '') THEN
        RAISE EXCEPTION 'Complete los DNI de docentes antes de aplicar NOT NULL';
    END IF;
    ALTER TABLE docentes ALTER COLUMN dni SET NOT NULL;
END $$;

-- Asegurar restricciones en ALUMNOS
ALTER TABLE IF EXISTS alumnos ALTER COLUMN dni TYPE VARCHAR(20);

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'alumnos' AND constraint_name = 'alumnos_dni_formato'
    ) THEN
        ALTER TABLE alumnos ADD CONSTRAINT alumnos_dni_formato CHECK (dni ~ '^[0-9]{8}$');
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM alumnos WHERE dni IS NULL OR dni = '') THEN
        RAISE EXCEPTION 'Complete los DNI de alumnos antes de aplicar NOT NULL';
    END IF;
    ALTER TABLE alumnos ALTER COLUMN dni SET NOT NULL;
END $$;

-- =====================================================
-- ÍNDICES PARA MEJORAR RENDIMIENTO
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_activo ON usuarios(activo);
CREATE INDEX IF NOT EXISTS idx_alumnos_usuario ON alumnos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_alumnos_email ON alumnos(email);
CREATE INDEX IF NOT EXISTS idx_alumnos_grado ON alumnos(grado);
CREATE INDEX IF NOT EXISTS idx_alumnos_dni ON alumnos(dni);
CREATE INDEX IF NOT EXISTS idx_docentes_usuario ON docentes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_docentes_dni ON docentes(dni);
CREATE INDEX IF NOT EXISTS idx_docentes_email ON docentes(email);
CREATE INDEX IF NOT EXISTS idx_cursos_docente ON cursos(docente_id);
CREATE INDEX IF NOT EXISTS idx_cursos_grado ON cursos(grado);
CREATE INDEX IF NOT EXISTS idx_cursos_activo ON cursos(activo);
CREATE INDEX IF NOT EXISTS idx_matriculas_alumno ON matriculas(alumno_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_curso ON matriculas(curso_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_estado ON matriculas(estado);
CREATE INDEX IF NOT EXISTS idx_periodos_estado ON periodos(estado);
CREATE INDEX IF NOT EXISTS idx_periodos_anio ON periodos(anio);
CREATE INDEX IF NOT EXISTS idx_matriculas_periodo_alumno ON matriculas_periodo(alumno_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_periodo_periodo ON matriculas_periodo(periodo_id);
CREATE INDEX IF NOT EXISTS idx_matricula_cursos_curso ON matricula_cursos(curso_id);
CREATE INDEX IF NOT EXISTS idx_notas_matricula_curso ON notas(matricula_curso_id);
CREATE INDEX IF NOT EXISTS idx_notas_bimestre ON notas(bimestre);
CREATE INDEX IF NOT EXISTS idx_asistencias_matricula_curso ON asistencias(matricula_curso_id);
CREATE INDEX IF NOT EXISTS idx_asistencias_fecha ON asistencias(fecha);

-- =====================================================
-- FUNCIONES Y TRIGGERS
-- =====================================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_docentes_updated_at BEFORE UPDATE ON docentes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alumnos_updated_at BEFORE UPDATE ON alumnos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cursos_updated_at BEFORE UPDATE ON cursos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notas_updated_at BEFORE UPDATE ON notas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_asistencias_updated_at BEFORE UPDATE ON asistencias
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matriculas_periodo_updated_at BEFORE UPDATE ON matriculas_periodo
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matricula_cursos_updated_at BEFORE UPDATE ON matricula_cursos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para evitar cursos duplicados/solapados por grado en el mismo horario
CREATE OR REPLACE FUNCTION validar_conflicto_curso_grado()
RETURNS TRIGGER AS $$
BEGIN
    -- Validar que la hora de inicio sea menor que la hora fin
    IF NEW.hora_inicio >= NEW.hora_fin THEN
        RAISE EXCEPTION 'La hora de inicio debe ser menor que la hora de fin' USING ERRCODE = 'check_violation';
    END IF;

    -- Verificar traslape de horarios dentro del mismo grado y día
    IF EXISTS (
        SELECT 1 FROM cursos c
        WHERE c.grado = NEW.grado
          AND c.dia_semana = NEW.dia_semana
          AND (TG_OP = 'INSERT' OR c.id <> NEW.id)
          AND NOT (NEW.hora_fin <= c.hora_inicio OR NEW.hora_inicio >= c.hora_fin)
    ) THEN
        RAISE EXCEPTION 'Ya existe un curso para % grado que se cruza con el horario % - % el %',
            NEW.grado, NEW.hora_inicio, NEW.hora_fin, NEW.dia_semana
            USING ERRCODE = 'unique_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Validacion para evitar cursos duplicados por grado en el mismo horario
DROP TRIGGER IF EXISTS validar_conflicto_curso_grado_trigger ON cursos;
CREATE TRIGGER validar_conflicto_curso_grado_trigger
    BEFORE INSERT OR UPDATE ON cursos
    FOR EACH ROW
    EXECUTE FUNCTION validar_conflicto_curso_grado();

-- Función para validar horario de matrícula
CREATE OR REPLACE FUNCTION validar_horario_matricula()
RETURNS TRIGGER AS $$
DECLARE
    curso_nuevo RECORD;
    curso_existente RECORD;
BEGIN
    SELECT dia_semana, hora_inicio, hora_fin, grado INTO curso_nuevo
    FROM cursos WHERE id = NEW.curso_id;

    FOR curso_existente IN
        SELECT c.dia_semana, c.hora_inicio, c.hora_fin
        FROM matriculas m
        JOIN cursos c ON m.curso_id = c.id
        WHERE m.alumno_id = NEW.alumno_id
        AND m.estado = 'activa'
        AND c.dia_semana = curso_nuevo.dia_semana
        AND c.hora_inicio = curso_nuevo.hora_inicio
        AND c.hora_fin = curso_nuevo.hora_fin
    LOOP
        RAISE EXCEPTION 'El alumno ya tiene un curso en el mismo horario: % de % a %',
            curso_nuevo.dia_semana, curso_nuevo.hora_inicio, curso_nuevo.hora_fin;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validar_horario_matricula_trigger
    BEFORE INSERT ON matriculas
    FOR EACH ROW
    EXECUTE FUNCTION validar_horario_matricula();

-- Función para validar grado de matrícula
CREATE OR REPLACE FUNCTION validar_grado_matricula()
RETURNS TRIGGER AS $$
DECLARE
    grado_alumno INTEGER;
    grado_curso INTEGER;
BEGIN
    SELECT grado INTO grado_alumno FROM alumnos WHERE id = NEW.alumno_id;
    SELECT grado INTO grado_curso FROM cursos WHERE id = NEW.curso_id;
    
    IF grado_alumno != grado_curso THEN
        RAISE EXCEPTION 'El alumno está en %° grado y el curso es para %° grado',
            grado_alumno, grado_curso;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validar_grado_matricula_trigger
    BEFORE INSERT ON matriculas
    FOR EACH ROW
    EXECUTE FUNCTION validar_grado_matricula();

-- Validación para capacidad y duplicidad de curso por alumno (cualquier periodo)
CREATE OR REPLACE FUNCTION validar_matricula_curso()
RETURNS TRIGGER AS $$
DECLARE
    v_periodo_id BIGINT;
    v_alumno_id BIGINT;
    v_capacidad INTEGER;
    v_inscritos INTEGER;
BEGIN
    SELECT periodo_id, alumno_id INTO v_periodo_id, v_alumno_id
    FROM matriculas_periodo
    WHERE id = NEW.matricula_id;

    IF v_alumno_id IS NULL THEN
        RAISE EXCEPTION 'Matrícula de período inválida' USING ERRCODE = 'foreign_key_violation';
    END IF;

    -- No permitir que un alumno se inscriba más de una vez al mismo curso (en cualquier período)
    IF EXISTS (
        SELECT 1
        FROM matricula_cursos mc
        JOIN matriculas_periodo mp ON mp.id = mc.matricula_id
        WHERE mc.curso_id = NEW.curso_id
          AND mp.alumno_id = v_alumno_id
          AND (TG_OP = 'INSERT' OR mc.id <> NEW.id)
    ) THEN
        RAISE EXCEPTION 'El alumno ya está inscrito en este curso' USING ERRCODE = 'unique_violation';
    END IF;

    -- Validar capacidad por período
    SELECT capacidad INTO v_capacidad FROM cursos WHERE id = NEW.curso_id;
    IF v_capacidad IS NOT NULL THEN
        SELECT COUNT(*) INTO v_inscritos
        FROM matricula_cursos mc
        JOIN matriculas_periodo mp ON mp.id = mc.matricula_id
        WHERE mc.curso_id = NEW.curso_id
          AND mp.periodo_id = v_periodo_id
          AND mp.estado = 'activa';

        IF v_inscritos >= v_capacidad THEN
            RAISE EXCEPTION 'El curso ha alcanzado su capacidad para este período' USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS validar_matricula_curso_trigger ON matricula_cursos;
CREATE TRIGGER validar_matricula_curso_trigger
    BEFORE INSERT OR UPDATE ON matricula_cursos
    FOR EACH ROW
    EXECUTE FUNCTION validar_matricula_curso();

-- Función para crear hash de contraseña
CREATE OR REPLACE FUNCTION crear_usuario_con_password(
    p_email VARCHAR,
    p_password TEXT,
    p_rol_id INTEGER,
    p_nombre VARCHAR,
    p_apellido VARCHAR,
    p_dni VARCHAR DEFAULT NULL,
    p_telefono VARCHAR DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_usuario_id UUID;
    v_password_hash TEXT;
BEGIN
    -- Generar hash de contraseña usando crypt
    v_password_hash := crypt(p_password, gen_salt('bf'));
    
    -- Crear usuario
    INSERT INTO usuarios (email, password_hash, rol_id, nombre, apellido, dni, telefono)
    VALUES (p_email, v_password_hash, p_rol_id, p_nombre, p_apellido, p_dni, p_telefono)
    RETURNING id INTO v_usuario_id;
    
    RETURN v_usuario_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar contraseña
CREATE OR REPLACE FUNCTION verificar_password(
    p_email VARCHAR,
    p_password TEXT
)
RETURNS TABLE (
    usuario_id UUID,
    email VARCHAR,
    rol_id INTEGER,
    rol_nombre VARCHAR,
    nombre VARCHAR,
    apellido VARCHAR,
    activo BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email,
        u.rol_id,
        r.nombre as rol_nombre,
        u.nombre,
        u.apellido,
        u.activo
    FROM usuarios u
    JOIN roles r ON u.rol_id = r.id
    WHERE u.email = p_email
    AND u.password_hash = crypt(p_password, u.password_hash)
    AND u.activo = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE docentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE alumnos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cursos ENABLE ROW LEVEL SECURITY;
ALTER TABLE matriculas ENABLE ROW LEVEL SECURITY;
ALTER TABLE notas ENABLE ROW LEVEL SECURITY;
ALTER TABLE asistencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE periodos ENABLE ROW LEVEL SECURITY;
ALTER TABLE matriculas_periodo ENABLE ROW LEVEL SECURITY;
ALTER TABLE matricula_cursos ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS RLS
-- =====================================================

-- Políticas para ROLES (todos pueden leer)
DROP POLICY IF EXISTS "roles_select_all" ON roles;
CREATE POLICY "roles_select_all" ON roles
    FOR SELECT USING (true);

-- Políticas para USUARIOS
-- Nota: Las políticas RLS se manejan a nivel de aplicación
-- ya que no usamos Supabase Auth. Se deshabilitan temporalmente.
DROP POLICY IF EXISTS "usuarios_select_all" ON usuarios;
CREATE POLICY "usuarios_select_all" ON usuarios
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "usuarios_insert_all" ON usuarios;
CREATE POLICY "usuarios_insert_all" ON usuarios
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "usuarios_update_all" ON usuarios;
CREATE POLICY "usuarios_update_all" ON usuarios
    FOR UPDATE USING (true);

-- Políticas para DOCENTES
DROP POLICY IF EXISTS "docentes_select_all" ON docentes;
CREATE POLICY "docentes_select_all" ON docentes
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "docentes_modify_all" ON docentes;
CREATE POLICY "docentes_modify_all" ON docentes
    FOR ALL USING (true);

-- Políticas para ALUMNOS
DROP POLICY IF EXISTS "alumnos_select_all" ON alumnos;
CREATE POLICY "alumnos_select_all" ON alumnos
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "alumnos_modify_all" ON alumnos;
CREATE POLICY "alumnos_modify_all" ON alumnos
    FOR ALL USING (true);

-- Políticas para CURSOS
DROP POLICY IF EXISTS "cursos_select_all" ON cursos;
CREATE POLICY "cursos_select_all" ON cursos
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "cursos_modify_all" ON cursos;
CREATE POLICY "cursos_modify_all" ON cursos
    FOR ALL USING (true);

-- Políticas para MATRÍCULAS
-- Nota: Los permisos se manejan a nivel de aplicación
DROP POLICY IF EXISTS "matriculas_select_all" ON matriculas;
CREATE POLICY "matriculas_select_all" ON matriculas
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "matriculas_insert_all" ON matriculas;
CREATE POLICY "matriculas_insert_all" ON matriculas
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "matriculas_update_all" ON matriculas;
CREATE POLICY "matriculas_update_all" ON matriculas
    FOR UPDATE USING (true);

-- Políticas para NOTAS
DROP POLICY IF EXISTS "notas_select_all" ON notas;
CREATE POLICY "notas_select_all" ON notas
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "notas_modify_all" ON notas;
CREATE POLICY "notas_modify_all" ON notas
    FOR ALL USING (true);

-- Políticas para ASISTENCIAS
DROP POLICY IF EXISTS "asistencias_select_all" ON asistencias;
CREATE POLICY "asistencias_select_all" ON asistencias
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "asistencias_modify_all" ON asistencias;
CREATE POLICY "asistencias_modify_all" ON asistencias
    FOR ALL USING (true);

-- Políticas para PERIODOS
DROP POLICY IF EXISTS "periodos_select_all" ON periodos;
CREATE POLICY "periodos_select_all" ON periodos
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "periodos_modify_all" ON periodos;
CREATE POLICY "periodos_modify_all" ON periodos
    FOR ALL USING (true);

-- Políticas para MATRICULAS_PERIODO
DROP POLICY IF EXISTS "matriculas_periodo_select_all" ON matriculas_periodo;
CREATE POLICY "matriculas_periodo_select_all" ON matriculas_periodo
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "matriculas_periodo_modify_all" ON matriculas_periodo;
CREATE POLICY "matriculas_periodo_modify_all" ON matriculas_periodo
    FOR ALL USING (true);

-- Políticas para MATRICULA_CURSOS
DROP POLICY IF EXISTS "matricula_cursos_select_all" ON matricula_cursos;
CREATE POLICY "matricula_cursos_select_all" ON matricula_cursos
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "matricula_cursos_modify_all" ON matricula_cursos;
CREATE POLICY "matricula_cursos_modify_all" ON matricula_cursos
    FOR ALL USING (true);

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de usuarios con información de rol
CREATE OR REPLACE VIEW v_usuarios_completos AS
SELECT 
    u.id,
    u.email,
    u.nombre,
    u.apellido,
    u.dni,
    u.telefono,
    u.activo,
    u.email_confirmado,
    u.ultimo_acceso,
    u.created_at,
    r.id as rol_id,
    r.nombre as rol_nombre,
    r.descripcion as rol_descripcion
FROM usuarios u
JOIN roles r ON u.rol_id = r.id;

-- Vista de alumnos con información de usuario
CREATE OR REPLACE VIEW v_alumnos_completos AS
SELECT 
    a.id,
    a.usuario_id,
    a.nombre,
    a.apellido,
    a.dni,
    a.email,
    a.grado,
    a.created_at,
    u.activo,
    u.email_confirmado,
    r.nombre as rol_nombre
FROM alumnos a
LEFT JOIN usuarios u ON a.usuario_id = u.id
LEFT JOIN roles r ON u.rol_id = r.id;

-- Vista de docentes con información de usuario
CREATE OR REPLACE VIEW v_docentes_completos AS
SELECT 
    d.id,
    d.usuario_id,
    d.nombre,
    d.apellido,
    d.email,
    d.telefono,
    d.created_at,
    u.activo,
    u.email_confirmado,
    r.nombre as rol_nombre
FROM docentes d
LEFT JOIN usuarios u ON d.usuario_id = u.id
LEFT JOIN roles r ON u.rol_id = r.id;

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Crear usuario administrador por defecto
-- Email: admin@colegio.com
-- Password: Admin123! (cambiar después del primer login)
INSERT INTO usuarios (email, password_hash, rol_id, nombre, apellido, activo, email_confirmado)
SELECT 
    'admin@colegio.com',
    crypt('Admin123!', gen_salt('bf')),
    (SELECT id FROM roles WHERE nombre = 'admin'),
    'Administrador',
    'Sistema',
    true,
    true
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE email = 'admin@colegio.com');

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

COMMENT ON TABLE roles IS 'Roles del sistema (admin, docente, alumno)';
COMMENT ON TABLE usuarios IS 'Usuarios del sistema con autenticación propia';
COMMENT ON TABLE docentes IS 'Información de docentes vinculada a usuarios';
COMMENT ON TABLE alumnos IS 'Información de alumnos vinculada a usuarios';
COMMENT ON TABLE cursos IS 'Cursos disponibles en el sistema';
COMMENT ON TABLE matriculas IS 'Matrículas de alumnos en cursos';
COMMENT ON TABLE notas IS 'Notas por bimestre de cada alumno en un curso';
COMMENT ON TABLE asistencias IS 'Asistencias por alumno en cada curso y fecha';
