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
    email VARCHAR(255) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- TABLA DE ALUMNOS
-- =====================================================
CREATE TABLE IF NOT EXISTS alumnos (
    id BIGSERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    grado INTEGER NOT NULL CHECK (grado >= 1 AND grado <= 6),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
CREATE INDEX IF NOT EXISTS idx_docentes_email ON docentes(email);
CREATE INDEX IF NOT EXISTS idx_cursos_docente ON cursos(docente_id);
CREATE INDEX IF NOT EXISTS idx_cursos_grado ON cursos(grado);
CREATE INDEX IF NOT EXISTS idx_cursos_activo ON cursos(activo);
CREATE INDEX IF NOT EXISTS idx_matriculas_alumno ON matriculas(alumno_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_curso ON matriculas(curso_id);
CREATE INDEX IF NOT EXISTS idx_matriculas_estado ON matriculas(estado);

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

