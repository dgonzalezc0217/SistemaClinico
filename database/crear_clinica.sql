-- SISTEMA CLINICO | SQLite | versión 1 | 2026-10-06
-- Ejecutar TODO en una base NUEVA y VACIA. Requiere SQLite 3.37.0 o superior.
-- Este archivo crea 40 tablas. No borra tablas ni incluye pacientes de ejemplo.
-- No es una migración para una base que ya tenga datos.
-- Si ocurre un error, DETENER la ejecución, ejecutar ROLLBACK y revisar el mensaje.
-- En la consola sqlite3 puede usarse: sqlite3 -bail clinica.db ".read crear_clinica.sql"
-- En un editor gráfico: abrir una base nueva, pegar TODO y ejecutar el script completo.
--
-- REGLAS SENCILLAS
-- INTEGER PRIMARY KEY: número identificador automático; omítalo al insertar.
-- INTEGER 0/1: falso/verdadero. TEXT: palabras o fechas. REAL: medidas aproximadas.
-- NULL: dato desconocido o que todavía no existe. No escribir 'NULL' ni '' en su lugar.
-- Fechas: '2026-10-06'. Instantes: '2026-10-06 13:00:00', siempre en UTC.
-- Turnos: '07:00:00' a '15:00:00', horas locales de la clínica; admiten cruce de medianoche.
-- Dinero con dos decimales: 25000.50 pesos se guarda como 2500050 centavos.
-- Cantidad de DETALLE_FACTURA: 1 unidad = 1000 milesimas; 2.5 unidades = 2500.
-- Precio unitario: máximo 10000000000 centavos. Cantidad: máximo 100000000 milesimas.
-- Esos límites evitan desbordar la multiplicación entera al calcular un renglón.
-- Total: redondeo de cada renglón al centavo más cercano, mitades hacia arriba.
-- Las demás cantidades y dosis son REAL; no prometen precisión decimal exacta.
--
-- CORRECCIONES APLICADAS AL ARCHIVO DE DRAW.DB
-- Cinco asociaciones con PK compuesta; turno opcional en Usuario; prescripción única
-- por detalle; nota previa única; cargo y detalle de factura únicos por prestación.
-- Se agregan Paciente.creado_en, Alergia_Paciente.observaciones y la FK solicitante IA.
-- Se quita Estudio_Imagen.id_episodio: su origen se obtiene por la orden.
-- Se corrigen id_orden_medica, id_antecedente, codigo_analito y nombre_analito.
-- Resultado_Lab.id_usuario pasa a id_usuario_validador.
-- Cambios monetarios: precio_unitario -> precio_unitario_centavos;
-- Pago.valor -> valor_centavos; Detalle_Factura.cantidad -> cantidad_milesimas.
-- El programa Java deberá usar estos nombres y convertir unidades al mostrar datos.
--
-- IMPORTANTE: activar foreign_keys en CADA conexión, también desde Java, antes de BEGIN.
PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 5000;

BEGIN IMMEDIATE;

-- 01. Rol: Tabla del modelo clínico.
CREATE TABLE Rol (
    id_rol INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    CHECK (nombre IS NULL OR length(trim(nombre)) > 0)
) STRICT;

-- 02. Permiso: Tabla del modelo clínico.
CREATE TABLE Permiso (
    id_permiso INTEGER PRIMARY KEY,
    codigo TEXT NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    CHECK (codigo IS NULL OR length(trim(codigo)) > 0),
    CHECK (descripcion IS NULL OR length(trim(descripcion)) > 0)
) STRICT;

-- 03. Especialidad: Tabla del modelo clínico.
CREATE TABLE Especialidad (
    id_especialidad INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    activo INTEGER NOT NULL DEFAULT 1,
    CHECK (activo IN (0, 1)),
    CHECK (nombre IS NULL OR length(trim(nombre)) > 0)
) STRICT;

-- 04. Turno: Tabla del modelo clínico.
CREATE TABLE Turno (
    id_turno INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    hora_inicio TEXT NOT NULL,
    hora_fin TEXT NOT NULL,
    CHECK (nombre IS NULL OR length(trim(nombre)) > 0),
    CHECK (length(hora_inicio) = 8 AND time(hora_inicio) IS hora_inicio AND hora_inicio < '24:00:00'),
    CHECK (hora_inicio IS NULL OR length(trim(hora_inicio)) > 0),
    CHECK (length(hora_fin) = 8 AND time(hora_fin) IS hora_fin AND hora_fin < '24:00:00'),
    CHECK (hora_fin IS NULL OR length(trim(hora_fin)) > 0)
) STRICT;

-- 05. Sede: Tabla del modelo clínico.
CREATE TABLE Sede (
    id_sede INTEGER PRIMARY KEY,
    codigo TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    CHECK (codigo IS NULL OR length(trim(codigo)) > 0),
    CHECK (nombre IS NULL OR length(trim(nombre)) > 0)
) STRICT;

-- 06. Paciente: Personas atendidas; pueden registrarse sin documento conocido.
CREATE TABLE Paciente (
    id_paciente INTEGER PRIMARY KEY,
    tipo_documento TEXT,
    numero_documento TEXT,
    nombres TEXT NOT NULL,
    apellidos TEXT NOT NULL,
    fecha_nacimiento TEXT,
    grupo_sanguineo TEXT,
    factor_rh TEXT,
    sexo TEXT,
    telefono TEXT,
    estado_identificacion TEXT NOT NULL,
    correo TEXT,
    creado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tipo_documento, numero_documento),
    CHECK ((tipo_documento IS NULL) = (numero_documento IS NULL)),
    CHECK (grupo_sanguineo IS NULL OR grupo_sanguineo IN ('A','B','AB','O')),
    CHECK (factor_rh IS NULL OR factor_rh IN ('+','-')),
    CHECK (tipo_documento IS NULL OR length(trim(tipo_documento)) > 0),
    CHECK (numero_documento IS NULL OR length(trim(numero_documento)) > 0),
    CHECK (nombres IS NULL OR length(trim(nombres)) > 0),
    CHECK (apellidos IS NULL OR length(trim(apellidos)) > 0),
    CHECK (fecha_nacimiento IS NULL OR (length(fecha_nacimiento) = 10 AND date(julianday(fecha_nacimiento)) IS fecha_nacimiento)),
    CHECK (fecha_nacimiento IS NULL OR length(trim(fecha_nacimiento)) > 0),
    CHECK (grupo_sanguineo IS NULL OR length(trim(grupo_sanguineo)) > 0),
    CHECK (factor_rh IS NULL OR length(trim(factor_rh)) > 0),
    CHECK (sexo IS NULL OR length(trim(sexo)) > 0),
    CHECK (telefono IS NULL OR length(trim(telefono)) > 0),
    CHECK (estado_identificacion IS NULL OR length(trim(estado_identificacion)) > 0),
    CHECK (correo IS NULL OR length(trim(correo)) > 0),
    CHECK (creado_en IS NULL OR (length(creado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(creado_en)) IS creado_en)),
    CHECK (creado_en IS NULL OR length(trim(creado_en)) > 0),
    CHECK (nombres IS NULL OR length(nombres) <= 100),
    CHECK (apellidos IS NULL OR length(apellidos) <= 100),
    CHECK (telefono IS NULL OR length(telefono) <= 30),
    CHECK (correo IS NULL OR length(correo) <= 254),
    CHECK (tipo_documento IS NULL OR length(tipo_documento) <= 10),
    CHECK (numero_documento IS NULL OR length(numero_documento) <= 30)
) STRICT;

-- 07. Catalogo_Diagnostico: Tabla del modelo clínico.
CREATE TABLE Catalogo_Diagnostico (
    id_catalogo_diagnostico INTEGER PRIMARY KEY,
    sistema_codigo TEXT NOT NULL,
    version_catalogo TEXT NOT NULL,
    codigo TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    UNIQUE (sistema_codigo, version_catalogo, codigo),
    CHECK (sistema_codigo IS NULL OR length(trim(sistema_codigo)) > 0),
    CHECK (version_catalogo IS NULL OR length(trim(version_catalogo)) > 0),
    CHECK (codigo IS NULL OR length(trim(codigo)) > 0),
    CHECK (descripcion IS NULL OR length(trim(descripcion)) > 0)
) STRICT;

-- 08. Servicio: Tabla del modelo clínico.
CREATE TABLE Servicio (
    id_servicio INTEGER PRIMARY KEY,
    sistema_codigo TEXT NOT NULL,
    version_catalogo TEXT NOT NULL,
    codigo TEXT NOT NULL,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL,
    duracion_minutos INTEGER,
    activo INTEGER NOT NULL DEFAULT 1,
    UNIQUE (sistema_codigo, version_catalogo, codigo),
    CHECK (activo IN (0, 1)),
    CHECK (duracion_minutos IS NULL OR duracion_minutos > 0),
    CHECK (sistema_codigo IS NULL OR length(trim(sistema_codigo)) > 0),
    CHECK (version_catalogo IS NULL OR length(trim(version_catalogo)) > 0),
    CHECK (codigo IS NULL OR length(trim(codigo)) > 0),
    CHECK (nombre IS NULL OR length(trim(nombre)) > 0),
    CHECK (tipo IS NULL OR length(trim(tipo)) > 0)
) STRICT;

-- 09. Sistema_Externo: Tabla del modelo clínico.
CREATE TABLE Sistema_Externo (
    id_sistema_externo INTEGER PRIMARY KEY,
    codigo TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL,
    CHECK (codigo IS NULL OR length(trim(codigo)) > 0),
    CHECK (nombre IS NULL OR length(trim(nombre)) > 0),
    CHECK (tipo IS NULL OR length(trim(tipo)) > 0)
) STRICT;

-- 10. Usuario: Personas con acceso; sujeto_identidad pertenece al proveedor de autenticación.
CREATE TABLE Usuario (
    id_usuario INTEGER PRIMARY KEY,
    nombres TEXT NOT NULL,
    apellidos TEXT NOT NULL,
    registro_profesional TEXT,
    activo INTEGER NOT NULL DEFAULT 1,
    sujeto_identidad TEXT NOT NULL UNIQUE,
    tipo_documento TEXT NOT NULL,
    numero_documento TEXT NOT NULL,
    telefono TEXT,
    correo TEXT,
    fecha_nacimiento TEXT,
    id_turno INTEGER,
    UNIQUE (tipo_documento, numero_documento),
    FOREIGN KEY (id_turno) REFERENCES Turno (id_turno) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (activo IN (0, 1)),
    CHECK (nombres IS NULL OR length(trim(nombres)) > 0),
    CHECK (apellidos IS NULL OR length(trim(apellidos)) > 0),
    CHECK (registro_profesional IS NULL OR length(trim(registro_profesional)) > 0),
    CHECK (sujeto_identidad IS NULL OR length(trim(sujeto_identidad)) > 0),
    CHECK (tipo_documento IS NULL OR length(trim(tipo_documento)) > 0),
    CHECK (numero_documento IS NULL OR length(trim(numero_documento)) > 0),
    CHECK (telefono IS NULL OR length(trim(telefono)) > 0),
    CHECK (correo IS NULL OR length(trim(correo)) > 0),
    CHECK (fecha_nacimiento IS NULL OR (length(fecha_nacimiento) = 10 AND date(julianday(fecha_nacimiento)) IS fecha_nacimiento)),
    CHECK (fecha_nacimiento IS NULL OR length(trim(fecha_nacimiento)) > 0),
    CHECK (nombres IS NULL OR length(nombres) <= 100),
    CHECK (apellidos IS NULL OR length(apellidos) <= 100),
    CHECK (telefono IS NULL OR length(telefono) <= 30),
    CHECK (correo IS NULL OR length(correo) <= 254),
    CHECK (tipo_documento IS NULL OR length(tipo_documento) <= 10),
    CHECK (numero_documento IS NULL OR length(numero_documento) <= 30)
) STRICT;

-- 11. Rol_Permiso: Tabla del modelo clínico.
CREATE TABLE Rol_Permiso (
    id_rol INTEGER NOT NULL,
    id_permiso INTEGER NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    FOREIGN KEY (id_permiso) REFERENCES Permiso (id_permiso) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_rol) REFERENCES Rol (id_rol) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

-- 12. Historia_Clinica: Tabla del modelo clínico.
CREATE TABLE Historia_Clinica (
    id_historia_clinica INTEGER PRIMARY KEY,
    numero_historia TEXT NOT NULL UNIQUE,
    abierta_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_paciente INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (id_paciente) REFERENCES Paciente (id_paciente) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (numero_historia IS NULL OR length(trim(numero_historia)) > 0),
    CHECK (abierta_en IS NULL OR (length(abierta_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(abierta_en)) IS abierta_en)),
    CHECK (abierta_en IS NULL OR length(trim(abierta_en)) > 0)
) STRICT;

-- 13. Factura: Crear BORRADOR, agregar detalles y luego cambiar a EMITIDA.
CREATE TABLE Factura (
    id_factura INTEGER PRIMARY KEY,
    numero TEXT UNIQUE,
    emitida_en TEXT,
    estado TEXT NOT NULL DEFAULT 'BORRADOR',
    moneda TEXT NOT NULL,
    id_paciente INTEGER NOT NULL,
    FOREIGN KEY (id_paciente) REFERENCES Paciente (id_paciente) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (length(moneda) = 3 AND moneda GLOB '[A-Z][A-Z][A-Z]'),
    CHECK (estado IN ('BORRADOR','EMITIDA','ANULADA')),
    CHECK (estado = 'BORRADOR' OR emitida_en IS NOT NULL),
    CHECK (estado = 'BORRADOR' OR numero IS NOT NULL),
    CHECK (numero IS NULL OR length(trim(numero)) > 0),
    CHECK (emitida_en IS NULL OR (length(emitida_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(emitida_en)) IS emitida_en)),
    CHECK (emitida_en IS NULL OR length(trim(emitida_en)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0),
    CHECK (moneda IS NULL OR length(trim(moneda)) > 0)
) STRICT;

-- 14. Usuario_Rol: Tabla del modelo clínico.
CREATE TABLE Usuario_Rol (
    id_usuario INTEGER NOT NULL,
    id_rol INTEGER NOT NULL,
    PRIMARY KEY (id_usuario, id_rol),
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_rol) REFERENCES Rol (id_rol) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

-- 15. Usuario_Especialidad: Tabla del modelo clínico.
CREATE TABLE Usuario_Especialidad (
    id_usuario INTEGER NOT NULL,
    id_especialidad INTEGER NOT NULL,
    PRIMARY KEY (id_usuario, id_especialidad),
    FOREIGN KEY (id_especialidad) REFERENCES Especialidad (id_especialidad) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

-- 16. Alergia_Paciente: Tabla del modelo clínico.
CREATE TABLE Alergia_Paciente (
    id_alergia_paciente INTEGER PRIMARY KEY,
    sustancia TEXT NOT NULL,
    reaccion TEXT NOT NULL,
    estado TEXT NOT NULL,
    registrada_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_usuario INTEGER NOT NULL,
    id_historia_clinica INTEGER NOT NULL,
    observaciones TEXT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_historia_clinica) REFERENCES Historia_Clinica (id_historia_clinica) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (sustancia IS NULL OR length(trim(sustancia)) > 0),
    CHECK (reaccion IS NULL OR length(trim(reaccion)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0),
    CHECK (registrada_en IS NULL OR (length(registrada_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(registrada_en)) IS registrada_en)),
    CHECK (registrada_en IS NULL OR length(trim(registrada_en)) > 0),
    CHECK (observaciones IS NULL OR length(trim(observaciones)) > 0)
) STRICT;

-- 17. Agenda: Tabla del modelo clínico.
CREATE TABLE Agenda (
    id_agenda INTEGER PRIMARY KEY,
    inicio TEXT NOT NULL,
    fin TEXT NOT NULL,
    estado TEXT NOT NULL,
    id_sede INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    FOREIGN KEY (id_sede) REFERENCES Sede (id_sede) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (fin > inicio),
    CHECK (inicio IS NULL OR (length(inicio) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(inicio)) IS inicio)),
    CHECK (inicio IS NULL OR length(trim(inicio)) > 0),
    CHECK (fin IS NULL OR (length(fin) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(fin)) IS fin)),
    CHECK (fin IS NULL OR length(trim(fin)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 18. Evento_Auditoria: Tabla del modelo clínico.
CREATE TABLE Evento_Auditoria (
    id_evento_auditoria INTEGER PRIMARY KEY,
    actor_sistema TEXT,
    accion TEXT NOT NULL,
    entidad TEXT NOT NULL,
    numero_registro TEXT NOT NULL,
    ocurrido_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo TEXT,
    detalle TEXT,
    resultado TEXT NOT NULL,
    id_usuario INTEGER,
    id_paciente INTEGER,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_paciente) REFERENCES Paciente (id_paciente) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (id_usuario IS NOT NULL OR actor_sistema IS NOT NULL),
    CHECK (actor_sistema IS NULL OR length(trim(actor_sistema)) > 0),
    CHECK (accion IS NULL OR length(trim(accion)) > 0),
    CHECK (entidad IS NULL OR length(trim(entidad)) > 0),
    CHECK (numero_registro IS NULL OR length(trim(numero_registro)) > 0),
    CHECK (ocurrido_en IS NULL OR (length(ocurrido_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(ocurrido_en)) IS ocurrido_en)),
    CHECK (ocurrido_en IS NULL OR length(trim(ocurrido_en)) > 0),
    CHECK (motivo IS NULL OR length(trim(motivo)) > 0),
    CHECK (detalle IS NULL OR length(trim(detalle)) > 0),
    CHECK (resultado IS NULL OR length(trim(resultado)) > 0)
) STRICT;

-- 19. Antecedente: Tabla del modelo clínico.
CREATE TABLE Antecedente (
    id_antecedente INTEGER PRIMARY KEY,
    tipo TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    registrado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo INTEGER NOT NULL DEFAULT 1,
    id_usuario INTEGER NOT NULL,
    id_historia_clinica INTEGER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_historia_clinica) REFERENCES Historia_Clinica (id_historia_clinica) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (activo IN (0, 1)),
    CHECK (tipo IS NULL OR length(trim(tipo)) > 0),
    CHECK (descripcion IS NULL OR length(trim(descripcion)) > 0),
    CHECK (registrado_en IS NULL OR (length(registrado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(registrado_en)) IS registrado_en)),
    CHECK (registrado_en IS NULL OR length(trim(registrado_en)) > 0)
) STRICT;

-- 20. Pago: Cada pago pertenece a una factura y usa su moneda. Solo pagos efectivos; no devoluciones.
CREATE TABLE Pago (
    id_pago INTEGER PRIMARY KEY,
    fecha TEXT NOT NULL,
    valor_centavos INTEGER NOT NULL,
    medio_pago TEXT NOT NULL,
    referencia TEXT,
    id_factura INTEGER NOT NULL,
    FOREIGN KEY (id_factura) REFERENCES Factura (id_factura) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (valor_centavos BETWEEN 1 AND 1000000000000000),
    CHECK (fecha IS NULL OR (length(fecha) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(fecha)) IS fecha)),
    CHECK (fecha IS NULL OR length(trim(fecha)) > 0),
    CHECK (medio_pago IS NULL OR length(trim(medio_pago)) > 0),
    CHECK (referencia IS NULL OR length(trim(referencia)) > 0)
) STRICT;

-- 21. Cita: Tabla del modelo clínico.
CREATE TABLE Cita (
    id_cita INTEGER PRIMARY KEY,
    inicio TEXT NOT NULL,
    fin TEXT NOT NULL,
    estado TEXT NOT NULL,
    prioridad TEXT NOT NULL,
    motivo_cancelacion TEXT,
    id_paciente INTEGER NOT NULL,
    id_agenda INTEGER NOT NULL,
    id_especialidad INTEGER NOT NULL,
    id_servicio INTEGER NOT NULL,
    FOREIGN KEY (id_paciente) REFERENCES Paciente (id_paciente) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_agenda) REFERENCES Agenda (id_agenda) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_especialidad) REFERENCES Especialidad (id_especialidad) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (fin > inicio),
    CHECK (inicio IS NULL OR (length(inicio) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(inicio)) IS inicio)),
    CHECK (inicio IS NULL OR length(trim(inicio)) > 0),
    CHECK (fin IS NULL OR (length(fin) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(fin)) IS fin)),
    CHECK (fin IS NULL OR length(trim(fin)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0),
    CHECK (prioridad IS NULL OR length(trim(prioridad)) > 0),
    CHECK (motivo_cancelacion IS NULL OR length(trim(motivo_cancelacion)) > 0)
) STRICT;

-- 22. Episodio: Tabla del modelo clínico.
CREATE TABLE Episodio (
    id_episodio INTEGER PRIMARY KEY,
    tipo_atencion TEXT NOT NULL,
    motivo_consulta TEXT NOT NULL,
    estado TEXT NOT NULL,
    nivel_triage INTEGER,
    ingreso_en TEXT NOT NULL,
    egreso_en TEXT,
    id_sede INTEGER NOT NULL,
    id_historia_clinica INTEGER NOT NULL,
    id_cita INTEGER UNIQUE,
    FOREIGN KEY (id_sede) REFERENCES Sede (id_sede) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_historia_clinica) REFERENCES Historia_Clinica (id_historia_clinica) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_cita) REFERENCES Cita (id_cita) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (nivel_triage IS NULL OR nivel_triage BETWEEN 1 AND 5),
    CHECK (egreso_en IS NULL OR egreso_en >= ingreso_en),
    CHECK (tipo_atencion IS NULL OR length(trim(tipo_atencion)) > 0),
    CHECK (motivo_consulta IS NULL OR length(trim(motivo_consulta)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0),
    CHECK (ingreso_en IS NULL OR (length(ingreso_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(ingreso_en)) IS ingreso_en)),
    CHECK (ingreso_en IS NULL OR length(trim(ingreso_en)) > 0),
    CHECK (egreso_en IS NULL OR (length(egreso_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(egreso_en)) IS egreso_en)),
    CHECK (egreso_en IS NULL OR length(trim(egreso_en)) > 0)
) STRICT;

-- 23. Signo_Vital: Tabla del modelo clínico.
CREATE TABLE Signo_Vital (
    id_signo_vital INTEGER PRIMARY KEY,
    codigo_signo TEXT NOT NULL,
    valor REAL NOT NULL,
    unidad TEXT NOT NULL,
    medido_en TEXT NOT NULL,
    id_usuario INTEGER NOT NULL,
    id_episodio INTEGER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (valor > -1.0e12 AND valor < 1.0e12),
    CHECK (codigo_signo IS NULL OR length(trim(codigo_signo)) > 0),
    CHECK (unidad IS NULL OR length(trim(unidad)) > 0),
    CHECK (medido_en IS NULL OR (length(medido_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(medido_en)) IS medido_en)),
    CHECK (medido_en IS NULL OR length(trim(medido_en)) > 0)
) STRICT;

-- 24. Nota_Clinica: Cada corrección crea otra nota y conserva la anterior.
CREATE TABLE Nota_Clinica (
    id_nota INTEGER PRIMARY KEY,
    id_nota_previa INTEGER UNIQUE,
    tipo TEXT NOT NULL,
    contenido TEXT NOT NULL,
    registrada_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    firmada_en TEXT,
    referencia_firma TEXT,
    motivo_rectificacion TEXT,
    id_episodio INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    FOREIGN KEY (id_nota_previa) REFERENCES Nota_Clinica (id_nota) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (id_nota_previa IS NULL OR id_nota_previa <> id_nota),
    CHECK ((firmada_en IS NULL) = (referencia_firma IS NULL)),
    CHECK (firmada_en IS NULL OR firmada_en >= registrada_en),
    CHECK (tipo IS NULL OR length(trim(tipo)) > 0),
    CHECK (contenido IS NULL OR length(trim(contenido)) > 0),
    CHECK (registrada_en IS NULL OR (length(registrada_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(registrada_en)) IS registrada_en)),
    CHECK (registrada_en IS NULL OR length(trim(registrada_en)) > 0),
    CHECK (firmada_en IS NULL OR (length(firmada_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(firmada_en)) IS firmada_en)),
    CHECK (firmada_en IS NULL OR length(trim(firmada_en)) > 0),
    CHECK (referencia_firma IS NULL OR length(trim(referencia_firma)) > 0),
    CHECK (motivo_rectificacion IS NULL OR length(trim(motivo_rectificacion)) > 0)
) STRICT;

-- 25. Orden_Medica: Crear BORRADOR, agregar detalles/prescripciones y luego cambiar a EMITIDA.
CREATE TABLE Orden_Medica (
    id_orden_medica INTEGER PRIMARY KEY,
    emitida_en TEXT,
    prioridad TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'BORRADOR',
    referencia_firma TEXT,
    id_usuario INTEGER NOT NULL,
    id_episodio INTEGER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (estado IN ('BORRADOR','EMITIDA','ANULADA')),
    CHECK (estado = 'BORRADOR' OR emitida_en IS NOT NULL),
    CHECK (estado = 'BORRADOR' OR referencia_firma IS NOT NULL),
    CHECK (emitida_en IS NULL OR (length(emitida_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(emitida_en)) IS emitida_en)),
    CHECK (emitida_en IS NULL OR length(trim(emitida_en)) > 0),
    CHECK (prioridad IS NULL OR length(trim(prioridad)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0),
    CHECK (referencia_firma IS NULL OR length(trim(referencia_firma)) > 0)
) STRICT;

-- 26. Diagnostico_Clinico: Tabla del modelo clínico.
CREATE TABLE Diagnostico_Clinico (
    id_diagnostico_clinico INTEGER PRIMARY KEY,
    tipo TEXT NOT NULL,
    registrado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado TEXT NOT NULL,
    id_usuario INTEGER NOT NULL,
    id_episodio INTEGER NOT NULL,
    id_catalogo_diagnostico INTEGER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_catalogo_diagnostico) REFERENCES Catalogo_Diagnostico (id_catalogo_diagnostico) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (tipo IS NULL OR length(trim(tipo)) > 0),
    CHECK (registrado_en IS NULL OR (length(registrado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(registrado_en)) IS registrado_en)),
    CHECK (registrado_en IS NULL OR length(trim(registrado_en)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 27. Analisis_IA: Tabla del modelo clínico.
CREATE TABLE Analisis_IA (
    id_analisis_IA INTEGER PRIMARY KEY,
    nombre_modelo TEXT NOT NULL,
    version_modelo TEXT NOT NULL,
    referencia_entrada TEXT NOT NULL,
    hash_entrada TEXT NOT NULL,
    solicitado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    terminado_en TEXT,
    estado TEXT NOT NULL,
    id_usuario INTEGER NOT NULL,
    id_episodio INTEGER NOT NULL,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (terminado_en IS NULL OR terminado_en >= solicitado_en),
    CHECK (nombre_modelo IS NULL OR length(trim(nombre_modelo)) > 0),
    CHECK (version_modelo IS NULL OR length(trim(version_modelo)) > 0),
    CHECK (referencia_entrada IS NULL OR length(trim(referencia_entrada)) > 0),
    CHECK (hash_entrada IS NULL OR length(trim(hash_entrada)) > 0),
    CHECK (solicitado_en IS NULL OR (length(solicitado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(solicitado_en)) IS solicitado_en)),
    CHECK (solicitado_en IS NULL OR length(trim(solicitado_en)) > 0),
    CHECK (terminado_en IS NULL OR (length(terminado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(terminado_en)) IS terminado_en)),
    CHECK (terminado_en IS NULL OR length(trim(terminado_en)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 28. Detalle_Orden: Tabla del modelo clínico.
CREATE TABLE Detalle_Orden (
    id_detalle_orden INTEGER PRIMARY KEY,
    cantidad REAL NOT NULL,
    indicaciones TEXT,
    estado TEXT NOT NULL,
    id_servicio INTEGER NOT NULL,
    id_orden_medica INTEGER NOT NULL,
    FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_orden_medica) REFERENCES Orden_Medica (id_orden_medica) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (cantidad > 0 AND cantidad < 1.0e12),
    CHECK (indicaciones IS NULL OR length(trim(indicaciones)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 29. Sugerencia_IA: Tabla del modelo clínico.
CREATE TABLE Sugerencia_IA (
    id_sugerencia_IA INTEGER PRIMARY KEY,
    probabilidad REAL NOT NULL,
    explicacion TEXT NOT NULL,
    id_catalogo_diagnostico INTEGER NOT NULL,
    id_analisis_IA INTEGER NOT NULL,
    FOREIGN KEY (id_catalogo_diagnostico) REFERENCES Catalogo_Diagnostico (id_catalogo_diagnostico) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_analisis_IA) REFERENCES Analisis_IA (id_analisis_IA) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (probabilidad BETWEEN 0 AND 1),
    CHECK (explicacion IS NULL OR length(trim(explicacion)) > 0)
) STRICT;

-- 30. Prescripcion: Tabla del modelo clínico.
CREATE TABLE Prescripcion (
    id_prescripcion INTEGER PRIMARY KEY,
    dosis REAL NOT NULL,
    unidad_dosis TEXT NOT NULL,
    via TEXT NOT NULL,
    frecuencia TEXT NOT NULL,
    inicio TEXT NOT NULL,
    fin TEXT,
    id_detalle_orden INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (id_detalle_orden) REFERENCES Detalle_Orden (id_detalle_orden) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (dosis > 0 AND dosis < 1.0e12),
    CHECK (fin IS NULL OR fin >= inicio),
    CHECK (unidad_dosis IS NULL OR length(trim(unidad_dosis)) > 0),
    CHECK (via IS NULL OR length(trim(via)) > 0),
    CHECK (frecuencia IS NULL OR length(trim(frecuencia)) > 0),
    CHECK (inicio IS NULL OR (length(inicio) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(inicio)) IS inicio)),
    CHECK (inicio IS NULL OR length(trim(inicio)) > 0),
    CHECK (fin IS NULL OR (length(fin) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(fin)) IS fin)),
    CHECK (fin IS NULL OR length(trim(fin)) > 0)
) STRICT;

-- 31. Resultado_Lab: Tabla del modelo clínico.
CREATE TABLE Resultado_Lab (
    id_resultado_lab INTEGER PRIMARY KEY,
    codigo_resultado_externo TEXT,
    version TEXT NOT NULL,
    observacion TEXT,
    referencia_pdf TEXT,
    muestra_tomada_en TEXT,
    registrado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validado_en TEXT,
    estado TEXT NOT NULL,
    id_detalle_orden INTEGER NOT NULL,
    id_sistema_externo INTEGER,
    id_usuario_validador INTEGER,
    UNIQUE (id_sistema_externo, codigo_resultado_externo, version),
    FOREIGN KEY (id_detalle_orden) REFERENCES Detalle_Orden (id_detalle_orden) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_sistema_externo) REFERENCES Sistema_Externo (id_sistema_externo) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario_validador) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK ((validado_en IS NULL) = (id_usuario_validador IS NULL)),
    CHECK (codigo_resultado_externo IS NULL OR id_sistema_externo IS NOT NULL),
    CHECK (validado_en IS NULL OR validado_en >= registrado_en),
    CHECK (codigo_resultado_externo IS NULL OR length(trim(codigo_resultado_externo)) > 0),
    CHECK (version IS NULL OR length(trim(version)) > 0),
    CHECK (observacion IS NULL OR length(trim(observacion)) > 0),
    CHECK (referencia_pdf IS NULL OR length(trim(referencia_pdf)) > 0),
    CHECK (muestra_tomada_en IS NULL OR (length(muestra_tomada_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(muestra_tomada_en)) IS muestra_tomada_en)),
    CHECK (muestra_tomada_en IS NULL OR length(trim(muestra_tomada_en)) > 0),
    CHECK (registrado_en IS NULL OR (length(registrado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(registrado_en)) IS registrado_en)),
    CHECK (registrado_en IS NULL OR length(trim(registrado_en)) > 0),
    CHECK (validado_en IS NULL OR (length(validado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(validado_en)) IS validado_en)),
    CHECK (validado_en IS NULL OR length(trim(validado_en)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 32. Estudio_Imagen: Tabla del modelo clínico.
CREATE TABLE Estudio_Imagen (
    id_estudio_imagen INTEGER PRIMARY KEY,
    study_instance_uid TEXT NOT NULL UNIQUE,
    modalidad TEXT NOT NULL,
    referencia_pacs TEXT NOT NULL,
    realizado_en TEXT NOT NULL,
    estado TEXT NOT NULL,
    id_sistema_externo INTEGER NOT NULL,
    id_detalle_orden INTEGER NOT NULL,
    FOREIGN KEY (id_sistema_externo) REFERENCES Sistema_Externo (id_sistema_externo) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_detalle_orden) REFERENCES Detalle_Orden (id_detalle_orden) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (study_instance_uid IS NULL OR length(trim(study_instance_uid)) > 0),
    CHECK (modalidad IS NULL OR length(trim(modalidad)) > 0),
    CHECK (referencia_pacs IS NULL OR length(trim(referencia_pacs)) > 0),
    CHECK (realizado_en IS NULL OR (length(realizado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(realizado_en)) IS realizado_en)),
    CHECK (realizado_en IS NULL OR length(trim(realizado_en)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 33. Prestacion: Tabla del modelo clínico.
CREATE TABLE Prestacion (
    id_prestacion INTEGER PRIMARY KEY,
    cantidad REAL NOT NULL,
    realizada_en TEXT NOT NULL,
    estado TEXT NOT NULL,
    id_servicio INTEGER NOT NULL,
    id_detalle_orden INTEGER,
    id_usuario INTEGER NOT NULL,
    id_episodio INTEGER NOT NULL,
    FOREIGN KEY (id_servicio) REFERENCES Servicio (id_servicio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_detalle_orden) REFERENCES Detalle_Orden (id_detalle_orden) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (cantidad > 0 AND cantidad < 1.0e12),
    CHECK (realizada_en IS NULL OR (length(realizada_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(realizada_en)) IS realizada_en)),
    CHECK (realizada_en IS NULL OR length(trim(realizada_en)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 34. Revision_IA: Tabla del modelo clínico.
CREATE TABLE Revision_IA (
    id_revision_IA INTEGER PRIMARY KEY,
    decision TEXT NOT NULL,
    justificacion TEXT NOT NULL,
    revisada_en TEXT NOT NULL,
    id_sugerencia_IA INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    FOREIGN KEY (id_sugerencia_IA) REFERENCES Sugerencia_IA (id_sugerencia_IA) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (decision IS NULL OR length(trim(decision)) > 0),
    CHECK (justificacion IS NULL OR length(trim(justificacion)) > 0),
    CHECK (revisada_en IS NULL OR (length(revisada_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(revisada_en)) IS revisada_en)),
    CHECK (revisada_en IS NULL OR length(trim(revisada_en)) > 0)
) STRICT;

-- 35. Valor_Resultado: Una fila contiene valor numérico O textual. Sin resultado aún, no crear la fila.
CREATE TABLE Valor_Resultado (
    id_valor_resultado INTEGER PRIMARY KEY,
    codigo_analito TEXT NOT NULL,
    nombre_analito TEXT NOT NULL,
    valor_numerico REAL,
    valor_textual TEXT,
    unidad TEXT,
    referencia_aplicada TEXT,
    interpretacion TEXT,
    id_resultado_lab INTEGER NOT NULL,
    FOREIGN KEY (id_resultado_lab) REFERENCES Resultado_Lab (id_resultado_lab) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (valor_numerico IS NULL OR (valor_numerico > -1.0e100 AND valor_numerico < 1.0e100)),
    CHECK ((valor_numerico IS NOT NULL) <> (valor_textual IS NOT NULL)),
    CHECK (codigo_analito IS NULL OR length(trim(codigo_analito)) > 0),
    CHECK (nombre_analito IS NULL OR length(trim(nombre_analito)) > 0),
    CHECK (valor_textual IS NULL OR length(trim(valor_textual)) > 0),
    CHECK (unidad IS NULL OR length(trim(unidad)) > 0),
    CHECK (referencia_aplicada IS NULL OR length(trim(referencia_aplicada)) > 0),
    CHECK (interpretacion IS NULL OR length(trim(interpretacion)) > 0)
) STRICT;

-- 36. Episodio_Resultado_Lab: Tabla del modelo clínico.
CREATE TABLE Episodio_Resultado_Lab (
    id_episodio INTEGER NOT NULL,
    id_resultado_lab INTEGER NOT NULL,
    PRIMARY KEY (id_episodio, id_resultado_lab),
    FOREIGN KEY (id_resultado_lab) REFERENCES Resultado_Lab (id_resultado_lab) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

-- 37. Informe_Imagen: Tabla del modelo clínico.
CREATE TABLE Informe_Imagen (
    id_informe INTEGER PRIMARY KEY,
    version TEXT NOT NULL,
    hallazgos TEXT,
    conclusion TEXT,
    referencia_pdf TEXT,
    creado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    firmado_en TEXT,
    referencia_firma TEXT,
    estado TEXT NOT NULL,
    id_estudio_imagen INTEGER NOT NULL,
    id_usuario INTEGER NOT NULL,
    UNIQUE (id_estudio_imagen, version),
    FOREIGN KEY (id_estudio_imagen) REFERENCES Estudio_Imagen (id_estudio_imagen) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK ((firmado_en IS NULL) = (referencia_firma IS NULL)),
    CHECK (firmado_en IS NULL OR firmado_en >= creado_en),
    CHECK (version IS NULL OR length(trim(version)) > 0),
    CHECK (hallazgos IS NULL OR length(trim(hallazgos)) > 0),
    CHECK (conclusion IS NULL OR length(trim(conclusion)) > 0),
    CHECK (referencia_pdf IS NULL OR length(trim(referencia_pdf)) > 0),
    CHECK (creado_en IS NULL OR (length(creado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(creado_en)) IS creado_en)),
    CHECK (creado_en IS NULL OR length(trim(creado_en)) > 0),
    CHECK (firmado_en IS NULL OR (length(firmado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(firmado_en)) IS firmado_en)),
    CHECK (firmado_en IS NULL OR length(trim(firmado_en)) > 0),
    CHECK (referencia_firma IS NULL OR length(trim(referencia_firma)) > 0),
    CHECK (estado IS NULL OR length(trim(estado)) > 0)
) STRICT;

-- 38. Episodio_Estudio_Imagen: Tabla del modelo clínico.
CREATE TABLE Episodio_Estudio_Imagen (
    id_episodio INTEGER NOT NULL,
    id_estudio_imagen INTEGER NOT NULL,
    PRIMARY KEY (id_episodio, id_estudio_imagen),
    FOREIGN KEY (id_estudio_imagen) REFERENCES Estudio_Imagen (id_estudio_imagen) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_episodio) REFERENCES Episodio (id_episodio) ON DELETE RESTRICT ON UPDATE RESTRICT
) STRICT;

-- 39. Cargo: Tabla del modelo clínico.
CREATE TABLE Cargo (
    id_cargo INTEGER PRIMARY KEY,
    clave_idempotencia TEXT NOT NULL UNIQUE,
    codigo_cargo_externo TEXT,
    estado_envio TEXT NOT NULL,
    creado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmado_en TEXT,
    ultimo_error TEXT,
    id_prestacion INTEGER NOT NULL UNIQUE,
    id_sistema_externo INTEGER NOT NULL,
    FOREIGN KEY (id_prestacion) REFERENCES Prestacion (id_prestacion) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_sistema_externo) REFERENCES Sistema_Externo (id_sistema_externo) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (confirmado_en IS NULL OR confirmado_en >= creado_en),
    CHECK (clave_idempotencia IS NULL OR length(trim(clave_idempotencia)) > 0),
    CHECK (codigo_cargo_externo IS NULL OR length(trim(codigo_cargo_externo)) > 0),
    CHECK (estado_envio IS NULL OR length(trim(estado_envio)) > 0),
    CHECK (creado_en IS NULL OR (length(creado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(creado_en)) IS creado_en)),
    CHECK (creado_en IS NULL OR length(trim(creado_en)) > 0),
    CHECK (confirmado_en IS NULL OR (length(confirmado_en) = 19 AND strftime('%Y-%m-%d %H:%M:%S', julianday(confirmado_en)) IS confirmado_en)),
    CHECK (confirmado_en IS NULL OR length(trim(confirmado_en)) > 0),
    CHECK (ultimo_error IS NULL OR length(trim(ultimo_error)) > 0)
) STRICT;

-- 40. Detalle_Factura: Cantidad en milésimas y precio unitario en centavos; no ingresar dinero con coma.
CREATE TABLE Detalle_Factura (
    id_detalle_factura INTEGER PRIMARY KEY,
    descripcion TEXT NOT NULL,
    cantidad_milesimas INTEGER NOT NULL,
    precio_unitario_centavos INTEGER NOT NULL,
    id_factura INTEGER NOT NULL,
    id_prestacion INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (id_factura) REFERENCES Factura (id_factura) ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (id_prestacion) REFERENCES Prestacion (id_prestacion) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CHECK (cantidad_milesimas BETWEEN 1 AND 100000000),
    CHECK (precio_unitario_centavos BETWEEN 0 AND 10000000000),
    CHECK (descripcion IS NULL OR length(trim(descripcion)) > 0)
) STRICT;

-- INDICES: ayudan a buscar registros y comprobar relaciones.
CREATE INDEX idx_Usuario_id_turno ON Usuario (id_turno);
CREATE INDEX idx_Rol_Permiso_id_permiso ON Rol_Permiso (id_permiso);
CREATE INDEX idx_Factura_id_paciente_emitida_en ON Factura (id_paciente, emitida_en);
CREATE INDEX idx_Usuario_Rol_id_rol ON Usuario_Rol (id_rol);
CREATE INDEX idx_Usuario_Especialidad_id_especialidad ON Usuario_Especialidad (id_especialidad);
CREATE INDEX idx_Alergia_Paciente_id_usuario ON Alergia_Paciente (id_usuario);
CREATE INDEX idx_Alergia_Paciente_id_historia_clinica ON Alergia_Paciente (id_historia_clinica);
CREATE INDEX idx_Agenda_id_sede ON Agenda (id_sede);
CREATE INDEX idx_Agenda_id_usuario ON Agenda (id_usuario);
CREATE INDEX idx_Evento_Auditoria_id_paciente_ocurrido_en ON Evento_Auditoria (id_paciente, ocurrido_en);
CREATE INDEX idx_Evento_Auditoria_id_usuario_ocurrido_en ON Evento_Auditoria (id_usuario, ocurrido_en);
CREATE INDEX idx_Antecedente_id_usuario ON Antecedente (id_usuario);
CREATE INDEX idx_Antecedente_id_historia_clinica ON Antecedente (id_historia_clinica);
CREATE INDEX idx_Pago_id_factura_fecha ON Pago (id_factura, fecha);
CREATE INDEX idx_Cita_id_agenda_inicio ON Cita (id_agenda, inicio);
CREATE INDEX idx_Cita_id_paciente_inicio ON Cita (id_paciente, inicio);
CREATE INDEX idx_Cita_id_especialidad ON Cita (id_especialidad);
CREATE INDEX idx_Cita_id_servicio ON Cita (id_servicio);
CREATE INDEX idx_Episodio_id_historia_clinica_ingreso_en ON Episodio (id_historia_clinica, ingreso_en);
CREATE INDEX idx_Episodio_id_sede ON Episodio (id_sede);
CREATE INDEX idx_Signo_Vital_id_usuario ON Signo_Vital (id_usuario);
CREATE INDEX idx_Signo_Vital_id_episodio ON Signo_Vital (id_episodio);
CREATE INDEX idx_Nota_Clinica_id_episodio_registrada_en ON Nota_Clinica (id_episodio, registrada_en);
CREATE INDEX idx_Nota_Clinica_id_usuario ON Nota_Clinica (id_usuario);
CREATE INDEX idx_Orden_Medica_id_usuario ON Orden_Medica (id_usuario);
CREATE INDEX idx_Orden_Medica_id_episodio ON Orden_Medica (id_episodio);
CREATE INDEX idx_Diagnostico_Clinico_id_usuario ON Diagnostico_Clinico (id_usuario);
CREATE INDEX idx_Diagnostico_Clinico_id_episodio ON Diagnostico_Clinico (id_episodio);
CREATE INDEX idx_Diagnostico_Clinico_id_catalogo_diagnostico ON Diagnostico_Clinico (id_catalogo_diagnostico);
CREATE INDEX idx_Analisis_IA_id_episodio ON Analisis_IA (id_episodio);
CREATE INDEX idx_Analisis_IA_id_usuario ON Analisis_IA (id_usuario);
CREATE INDEX idx_Detalle_Orden_id_servicio ON Detalle_Orden (id_servicio);
CREATE INDEX idx_Detalle_Orden_id_orden_medica ON Detalle_Orden (id_orden_medica);
CREATE INDEX idx_Sugerencia_IA_id_catalogo_diagnostico ON Sugerencia_IA (id_catalogo_diagnostico);
CREATE INDEX idx_Sugerencia_IA_id_analisis_IA ON Sugerencia_IA (id_analisis_IA);
CREATE INDEX idx_Resultado_Lab_id_detalle_orden_registrado_en ON Resultado_Lab (id_detalle_orden, registrado_en);
CREATE INDEX idx_Resultado_Lab_id_usuario_validador ON Resultado_Lab (id_usuario_validador);
CREATE INDEX idx_Estudio_Imagen_id_sistema_externo ON Estudio_Imagen (id_sistema_externo);
CREATE INDEX idx_Estudio_Imagen_id_detalle_orden ON Estudio_Imagen (id_detalle_orden);
CREATE INDEX idx_Prestacion_id_servicio ON Prestacion (id_servicio);
CREATE INDEX idx_Prestacion_id_detalle_orden ON Prestacion (id_detalle_orden);
CREATE INDEX idx_Prestacion_id_usuario ON Prestacion (id_usuario);
CREATE INDEX idx_Prestacion_id_episodio ON Prestacion (id_episodio);
CREATE INDEX idx_Revision_IA_id_sugerencia_IA ON Revision_IA (id_sugerencia_IA);
CREATE INDEX idx_Revision_IA_id_usuario ON Revision_IA (id_usuario);
CREATE INDEX idx_Valor_Resultado_id_resultado_lab ON Valor_Resultado (id_resultado_lab);
CREATE INDEX idx_Episodio_Resultado_Lab_id_resultado_lab ON Episodio_Resultado_Lab (id_resultado_lab);
CREATE INDEX idx_Informe_Imagen_id_usuario ON Informe_Imagen (id_usuario);
CREATE INDEX idx_Episodio_Estudio_Imagen_id_estudio_imagen ON Episodio_Estudio_Imagen (id_estudio_imagen);
CREATE INDEX idx_Cargo_id_sistema_externo ON Cargo (id_sistema_externo);
CREATE INDEX idx_Detalle_Factura_id_factura ON Detalle_Factura (id_factura);

-- REGLAS AUTOMATICAS: SQLite rechaza la operación y muestra el motivo.
CREATE TRIGGER nota_previa_valida
BEFORE INSERT ON Nota_Clinica
WHEN NEW.id_nota_previa IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'La nota previa debe existir y pertenecer al mismo episodio.') WHERE NOT EXISTS (SELECT 1 FROM Nota_Clinica n WHERE n.id_nota = NEW.id_nota_previa AND n.id_episodio = NEW.id_episodio);
    SELECT RAISE(ABORT, 'Escriba el motivo de la rectificacion.') WHERE NEW.motivo_rectificacion IS NULL;
END;

CREATE TRIGGER nota_estructura_inmutable
BEFORE UPDATE ON Nota_Clinica
BEGIN
    SELECT RAISE(ABORT, 'No cambie la identidad, episodio ni enlace de una nota; cree otra nota.') WHERE NEW.id_nota IS NOT OLD.id_nota OR NEW.id_nota_previa IS NOT OLD.id_nota_previa OR NEW.id_episodio IS NOT OLD.id_episodio;
END;

CREATE TRIGGER nota_firmada_no_update
BEFORE UPDATE ON Nota_Clinica
WHEN OLD.firmada_en IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Una nota firmada se conserva; cree una rectificacion.');
END;

CREATE TRIGGER informe_firmado_no_update
BEFORE UPDATE ON Informe_Imagen
WHEN OLD.firmado_en IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Un informe firmado se conserva; cree una nueva version.');
END;

CREATE TRIGGER auditoria_no_update
BEFORE UPDATE ON Evento_Auditoria
BEGIN
    SELECT RAISE(ABORT, 'Los eventos de auditoria no se modifican ni se eliminan.');
END;

CREATE TRIGGER nota_firmada_no_delete
BEFORE DELETE ON Nota_Clinica
WHEN OLD.firmada_en IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Una nota firmada se conserva; cree una rectificacion.');
END;

CREATE TRIGGER informe_firmado_no_delete
BEFORE DELETE ON Informe_Imagen
WHEN OLD.firmado_en IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Un informe firmado se conserva; cree una nueva version.');
END;

CREATE TRIGGER auditoria_no_delete
BEFORE DELETE ON Evento_Auditoria
BEGIN
    SELECT RAISE(ABORT, 'Los eventos de auditoria no se modifican ni se eliminan.');
END;

CREATE TRIGGER Orden_Medica_crear_borrador
BEFORE INSERT ON Orden_Medica
WHEN NEW.estado <> 'BORRADOR'
BEGIN
    SELECT RAISE(ABORT, 'Cree primero un BORRADOR, agregue detalles y luego emita.');
END;

CREATE TRIGGER Orden_Medica_emitir_con_detalles
BEFORE UPDATE ON Orden_Medica
WHEN OLD.estado = 'BORRADOR' AND NEW.estado = 'EMITIDA'
BEGIN
    SELECT RAISE(ABORT, 'No se puede emitir sin detalles.') WHERE NOT EXISTS (SELECT 1 FROM Detalle_Orden WHERE id_orden_medica = NEW.id_orden_medica);
END;

CREATE TRIGGER Orden_Medica_transicion
BEFORE UPDATE ON Orden_Medica
BEGIN
    SELECT RAISE(ABORT, 'Transicion de estado no permitida.') WHERE NOT (NEW.estado = OLD.estado OR (OLD.estado = 'BORRADOR' AND NEW.estado = 'EMITIDA') OR (OLD.estado = 'EMITIDA' AND NEW.estado = 'ANULADA'));
END;

CREATE TRIGGER Orden_Medica_no_borrar_emitida
BEFORE DELETE ON Orden_Medica
WHEN OLD.estado <> 'BORRADOR'
BEGIN
    SELECT RAISE(ABORT, 'Solo se puede borrar un borrador.');
END;

CREATE TRIGGER Orden_Medica_conservar_emitida
BEFORE UPDATE ON Orden_Medica
WHEN OLD.estado <> 'BORRADOR'
BEGIN
    SELECT RAISE(ABORT, 'No modifique los datos de un documento emitido.') WHERE NEW.id_orden_medica IS NOT OLD.id_orden_medica OR NEW.emitida_en IS NOT OLD.emitida_en OR NEW.prioridad IS NOT OLD.prioridad OR NEW.referencia_firma IS NOT OLD.referencia_firma OR NEW.id_usuario IS NOT OLD.id_usuario OR NEW.id_episodio IS NOT OLD.id_episodio;
END;

CREATE TRIGGER Detalle_Orden_solo_borrador_insert
BEFORE INSERT ON Detalle_Orden
BEGIN
    SELECT RAISE(ABORT, 'Los detalles de un documento emitido no se modifican.') WHERE EXISTS (SELECT 1 FROM Orden_Medica WHERE id_orden_medica = NEW.id_orden_medica AND estado <> 'BORRADOR');
END;

CREATE TRIGGER Detalle_Orden_solo_borrador_update
BEFORE UPDATE ON Detalle_Orden
BEGIN
    SELECT RAISE(ABORT, 'Los detalles de un documento emitido no se modifican.') WHERE EXISTS (SELECT 1 FROM Orden_Medica WHERE id_orden_medica = NEW.id_orden_medica AND estado <> 'BORRADOR') OR EXISTS (SELECT 1 FROM Orden_Medica WHERE id_orden_medica = OLD.id_orden_medica AND estado <> 'BORRADOR');
END;

CREATE TRIGGER Detalle_Orden_solo_borrador_delete
BEFORE DELETE ON Detalle_Orden
BEGIN
    SELECT RAISE(ABORT, 'Los detalles de un documento emitido no se modifican.') WHERE EXISTS (SELECT 1 FROM Orden_Medica WHERE id_orden_medica = OLD.id_orden_medica AND estado <> 'BORRADOR');
END;

CREATE TRIGGER Factura_crear_borrador
BEFORE INSERT ON Factura
WHEN NEW.estado <> 'BORRADOR'
BEGIN
    SELECT RAISE(ABORT, 'Cree primero un BORRADOR, agregue detalles y luego emita.');
END;

CREATE TRIGGER Factura_emitir_con_detalles
BEFORE UPDATE ON Factura
WHEN OLD.estado = 'BORRADOR' AND NEW.estado = 'EMITIDA'
BEGIN
    SELECT RAISE(ABORT, 'No se puede emitir sin detalles.') WHERE NOT EXISTS (SELECT 1 FROM Detalle_Factura WHERE id_factura = NEW.id_factura);
END;

CREATE TRIGGER Factura_transicion
BEFORE UPDATE ON Factura
BEGIN
    SELECT RAISE(ABORT, 'Transicion de estado no permitida.') WHERE NOT (NEW.estado = OLD.estado OR (OLD.estado = 'BORRADOR' AND NEW.estado = 'EMITIDA') OR (OLD.estado = 'EMITIDA' AND NEW.estado = 'ANULADA'));
END;

CREATE TRIGGER Factura_no_borrar_emitida
BEFORE DELETE ON Factura
WHEN OLD.estado <> 'BORRADOR'
BEGIN
    SELECT RAISE(ABORT, 'Solo se puede borrar un borrador.');
END;

CREATE TRIGGER Factura_conservar_emitida
BEFORE UPDATE ON Factura
WHEN OLD.estado <> 'BORRADOR'
BEGIN
    SELECT RAISE(ABORT, 'No modifique los datos de un documento emitido.') WHERE NEW.id_factura IS NOT OLD.id_factura OR NEW.numero IS NOT OLD.numero OR NEW.emitida_en IS NOT OLD.emitida_en OR NEW.moneda IS NOT OLD.moneda OR NEW.id_paciente IS NOT OLD.id_paciente;
END;

CREATE TRIGGER Detalle_Factura_solo_borrador_insert
BEFORE INSERT ON Detalle_Factura
BEGIN
    SELECT RAISE(ABORT, 'Los detalles de un documento emitido no se modifican.') WHERE EXISTS (SELECT 1 FROM Factura WHERE id_factura = NEW.id_factura AND estado <> 'BORRADOR');
END;

CREATE TRIGGER Detalle_Factura_solo_borrador_update
BEFORE UPDATE ON Detalle_Factura
BEGIN
    SELECT RAISE(ABORT, 'Los detalles de un documento emitido no se modifican.') WHERE EXISTS (SELECT 1 FROM Factura WHERE id_factura = NEW.id_factura AND estado <> 'BORRADOR') OR EXISTS (SELECT 1 FROM Factura WHERE id_factura = OLD.id_factura AND estado <> 'BORRADOR');
END;

CREATE TRIGGER Detalle_Factura_solo_borrador_delete
BEFORE DELETE ON Detalle_Factura
BEGIN
    SELECT RAISE(ABORT, 'Los detalles de un documento emitido no se modifican.') WHERE EXISTS (SELECT 1 FROM Factura WHERE id_factura = OLD.id_factura AND estado <> 'BORRADOR');
END;

CREATE TRIGGER prescripcion_insert
BEFORE INSERT ON Prescripcion
BEGIN
    SELECT RAISE(ABORT, 'No modifique prescripciones de una orden emitida.') WHERE EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica WHERE d.id_detalle_orden=NEW.id_detalle_orden AND o.estado <> 'BORRADOR');
    SELECT RAISE(ABORT, 'La prescripcion requiere un servicio de tipo MEDICAMENTO.') WHERE NOT EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Servicio s ON s.id_servicio=d.id_servicio WHERE d.id_detalle_orden=NEW.id_detalle_orden AND s.tipo='MEDICAMENTO');
END;

CREATE TRIGGER prescripcion_update
BEFORE UPDATE ON Prescripcion
BEGIN
    SELECT RAISE(ABORT, 'No modifique prescripciones de una orden emitida.') WHERE EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica WHERE d.id_detalle_orden=NEW.id_detalle_orden AND o.estado <> 'BORRADOR');
    SELECT RAISE(ABORT, 'No modifique prescripciones de una orden emitida.') WHERE EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica WHERE d.id_detalle_orden=OLD.id_detalle_orden AND o.estado <> 'BORRADOR');
    SELECT RAISE(ABORT, 'La prescripcion requiere un servicio de tipo MEDICAMENTO.') WHERE NOT EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Servicio s ON s.id_servicio=d.id_servicio WHERE d.id_detalle_orden=NEW.id_detalle_orden AND s.tipo='MEDICAMENTO');
END;

CREATE TRIGGER prescripcion_delete
BEFORE DELETE ON Prescripcion
BEGIN
    SELECT RAISE(ABORT, 'No modifique prescripciones de una orden emitida.') WHERE EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica WHERE d.id_detalle_orden=OLD.id_detalle_orden AND o.estado <> 'BORRADOR');
END;

CREATE TRIGGER orden_prescripciones_completas
BEFORE UPDATE ON Orden_Medica
WHEN NEW.estado='EMITIDA' AND OLD.estado='BORRADOR'
BEGIN
    SELECT RAISE(ABORT, 'Revise las prescripciones de los detalles antes de emitir.') WHERE EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Servicio s ON s.id_servicio=d.id_servicio LEFT JOIN Prescripcion p ON p.id_detalle_orden=d.id_detalle_orden WHERE d.id_orden_medica=NEW.id_orden_medica AND ((s.tipo='MEDICAMENTO' AND p.id_prescripcion IS NULL) OR (s.tipo<>'MEDICAMENTO' AND p.id_prescripcion IS NOT NULL)));
END;

CREATE TRIGGER pago_factura_emitida
BEFORE INSERT ON Pago
BEGIN
    SELECT RAISE(ABORT, 'El pago requiere una factura emitida.') WHERE NOT EXISTS (SELECT 1 FROM Factura WHERE id_factura=NEW.id_factura AND estado='EMITIDA');
END;

CREATE TRIGGER pago_no_update
BEFORE UPDATE ON Pago
BEGIN
    SELECT RAISE(ABORT, 'Los pagos efectivos se conservan; las devoluciones requieren otro flujo.');
END;

CREATE TRIGGER pago_no_delete
BEFORE DELETE ON Pago
BEGIN
    SELECT RAISE(ABORT, 'Los pagos efectivos se conservan; las devoluciones requieren otro flujo.');
END;

CREATE TRIGGER factura_sin_pagos_para_anular
BEFORE UPDATE ON Factura
WHEN NEW.estado='ANULADA'
BEGIN
    SELECT RAISE(ABORT, 'No anule una factura con pagos; hace falta gestionar su devolucion.') WHERE EXISTS (SELECT 1 FROM Pago WHERE id_factura=OLD.id_factura);
END;

CREATE TRIGGER episodio_paciente_cita_insert
BEFORE INSERT ON Episodio
WHEN NEW.id_cita IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'La cita y la historia deben pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Cita c JOIN Historia_Clinica h ON h.id_paciente=c.id_paciente WHERE c.id_cita=NEW.id_cita AND h.id_historia_clinica=NEW.id_historia_clinica);
END;

CREATE TRIGGER prestacion_orden_coherente_insert
BEFORE INSERT ON Prestacion
WHEN NEW.id_detalle_orden IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'La prestacion debe coincidir con el servicio y episodio de su orden.') WHERE NOT EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica WHERE d.id_detalle_orden=NEW.id_detalle_orden AND d.id_servicio=NEW.id_servicio AND o.id_episodio=NEW.id_episodio);
END;

CREATE TRIGGER factura_paciente_prestacion_insert
BEFORE INSERT ON Detalle_Factura
BEGIN
    SELECT RAISE(ABORT, 'La prestacion y la factura deben pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Prestacion p JOIN Episodio e ON e.id_episodio=p.id_episodio JOIN Historia_Clinica h ON h.id_historia_clinica=e.id_historia_clinica JOIN Factura f ON f.id_paciente=h.id_paciente WHERE p.id_prestacion=NEW.id_prestacion AND f.id_factura=NEW.id_factura);
END;

CREATE TRIGGER Episodio_Resultado_Lab_paciente_insert
BEFORE INSERT ON Episodio_Resultado_Lab
BEGIN
    SELECT RAISE(ABORT, 'El examen consultado debe pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Resultado_Lab x JOIN Detalle_Orden d ON d.id_detalle_orden=x.id_detalle_orden JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica JOIN Episodio origen ON origen.id_episodio=o.id_episodio JOIN Episodio destino ON destino.id_episodio=NEW.id_episodio WHERE x.id_resultado_lab=NEW.id_resultado_lab AND origen.id_historia_clinica=destino.id_historia_clinica);
END;

CREATE TRIGGER Episodio_Estudio_Imagen_paciente_insert
BEFORE INSERT ON Episodio_Estudio_Imagen
BEGIN
    SELECT RAISE(ABORT, 'El examen consultado debe pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Estudio_Imagen x JOIN Detalle_Orden d ON d.id_detalle_orden=x.id_detalle_orden JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica JOIN Episodio origen ON origen.id_episodio=o.id_episodio JOIN Episodio destino ON destino.id_episodio=NEW.id_episodio WHERE x.id_estudio_imagen=NEW.id_estudio_imagen AND origen.id_historia_clinica=destino.id_historia_clinica);
END;

CREATE TRIGGER episodio_paciente_cita_update
BEFORE UPDATE ON Episodio
WHEN NEW.id_cita IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'La cita y la historia deben pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Cita c JOIN Historia_Clinica h ON h.id_paciente=c.id_paciente WHERE c.id_cita=NEW.id_cita AND h.id_historia_clinica=NEW.id_historia_clinica);
END;

CREATE TRIGGER prestacion_orden_coherente_update
BEFORE UPDATE ON Prestacion
WHEN NEW.id_detalle_orden IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'La prestacion debe coincidir con el servicio y episodio de su orden.') WHERE NOT EXISTS (SELECT 1 FROM Detalle_Orden d JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica WHERE d.id_detalle_orden=NEW.id_detalle_orden AND d.id_servicio=NEW.id_servicio AND o.id_episodio=NEW.id_episodio);
END;

CREATE TRIGGER factura_paciente_prestacion_update
BEFORE UPDATE ON Detalle_Factura
BEGIN
    SELECT RAISE(ABORT, 'La prestacion y la factura deben pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Prestacion p JOIN Episodio e ON e.id_episodio=p.id_episodio JOIN Historia_Clinica h ON h.id_historia_clinica=e.id_historia_clinica JOIN Factura f ON f.id_paciente=h.id_paciente WHERE p.id_prestacion=NEW.id_prestacion AND f.id_factura=NEW.id_factura);
END;

CREATE TRIGGER Episodio_Resultado_Lab_paciente_update
BEFORE UPDATE ON Episodio_Resultado_Lab
BEGIN
    SELECT RAISE(ABORT, 'El examen consultado debe pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Resultado_Lab x JOIN Detalle_Orden d ON d.id_detalle_orden=x.id_detalle_orden JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica JOIN Episodio origen ON origen.id_episodio=o.id_episodio JOIN Episodio destino ON destino.id_episodio=NEW.id_episodio WHERE x.id_resultado_lab=NEW.id_resultado_lab AND origen.id_historia_clinica=destino.id_historia_clinica);
END;

CREATE TRIGGER Episodio_Estudio_Imagen_paciente_update
BEFORE UPDATE ON Episodio_Estudio_Imagen
BEGIN
    SELECT RAISE(ABORT, 'El examen consultado debe pertenecer al mismo paciente.') WHERE NOT EXISTS (SELECT 1 FROM Estudio_Imagen x JOIN Detalle_Orden d ON d.id_detalle_orden=x.id_detalle_orden JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica JOIN Episodio origen ON origen.id_episodio=o.id_episodio JOIN Episodio destino ON destino.id_episodio=NEW.id_episodio WHERE x.id_estudio_imagen=NEW.id_estudio_imagen AND origen.id_historia_clinica=destino.id_historia_clinica);
END;

CREATE TRIGGER Historia_Clinica_origen_inmutable
BEFORE UPDATE ON Historia_Clinica
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_paciente IS NOT OLD.id_paciente;
END;

CREATE TRIGGER Episodio_origen_inmutable
BEFORE UPDATE ON Episodio
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_historia_clinica IS NOT OLD.id_historia_clinica OR NEW.id_cita IS NOT OLD.id_cita;
END;

CREATE TRIGGER Cita_origen_inmutable
BEFORE UPDATE ON Cita
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_paciente IS NOT OLD.id_paciente;
END;

CREATE TRIGGER Orden_Medica_origen_inmutable
BEFORE UPDATE ON Orden_Medica
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_episodio IS NOT OLD.id_episodio;
END;

CREATE TRIGGER Detalle_Orden_origen_inmutable
BEFORE UPDATE ON Detalle_Orden
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_orden_medica IS NOT OLD.id_orden_medica OR NEW.id_servicio IS NOT OLD.id_servicio;
END;

CREATE TRIGGER Prestacion_origen_inmutable
BEFORE UPDATE ON Prestacion
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_episodio IS NOT OLD.id_episodio OR NEW.id_servicio IS NOT OLD.id_servicio OR NEW.id_detalle_orden IS NOT OLD.id_detalle_orden;
END;

CREATE TRIGGER Resultado_Lab_origen_inmutable
BEFORE UPDATE ON Resultado_Lab
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_detalle_orden IS NOT OLD.id_detalle_orden;
END;

CREATE TRIGGER Estudio_Imagen_origen_inmutable
BEFORE UPDATE ON Estudio_Imagen
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_detalle_orden IS NOT OLD.id_detalle_orden;
END;

CREATE TRIGGER Factura_origen_inmutable
BEFORE UPDATE ON Factura
BEGIN
    SELECT RAISE(ABORT, 'No reasigne el origen de un registro existente; corrija mediante un nuevo registro.') WHERE NEW.id_paciente IS NOT OLD.id_paciente;
END;

-- CONSULTAS GUARDADAS: totales sin duplicar pagos al unir varias filas.
CREATE VIEW V_Detalle_Factura AS
SELECT d.*,
       (cantidad_milesimas * precio_unitario_centavos + 500) / 1000 AS subtotal_centavos
FROM Detalle_Factura d;

CREATE VIEW V_Resumen_Factura AS
SELECT f.id_factura, f.numero, f.id_paciente, f.estado, f.moneda,
       COALESCE(d.total_centavos, 0) AS total_centavos,
       COALESCE(p.pagado_centavos, 0) AS pagado_centavos,
       COALESCE(d.total_centavos, 0) - COALESCE(p.pagado_centavos, 0) AS saldo_centavos
FROM Factura f
LEFT JOIN (SELECT id_factura, SUM(subtotal_centavos) AS total_centavos
           FROM V_Detalle_Factura GROUP BY id_factura) d USING (id_factura)
LEFT JOIN (SELECT id_factura, SUM(valor_centavos) AS pagado_centavos
           FROM Pago GROUP BY id_factura) p USING (id_factura);

-- Rechazar pagos superiores al saldo de la factura.
CREATE TRIGGER pago_no_excede_saldo
BEFORE INSERT ON Pago
BEGIN
    SELECT RAISE(ABORT, 'El pago supera el saldo pendiente.')
    WHERE NEW.valor_centavos > (SELECT saldo_centavos FROM V_Resumen_Factura
                               WHERE id_factura=NEW.id_factura);
END;

PRAGMA user_version = 1;
COMMIT;

-- VERIFICACION: 40 tablas, foreign_keys = 1, sin filas en foreign_key_check,
-- y una fila con 'ok' en integrity_check.
SELECT COUNT(*) AS tablas_creadas FROM sqlite_schema
WHERE type = 'table' AND name NOT LIKE 'sqlite_%';
PRAGMA foreign_keys;
PRAGMA foreign_key_check;
PRAGMA integrity_check;

-- ORDEN PARA CARGAR DATOS
-- 1. Turno, Rol, Permiso, Especialidad, Sede, Servicio, Catalogo_Diagnostico,
--    Sistema_Externo y Usuario; luego sus asignaciones de roles y especialidades.
-- 2. Paciente e Historia_Clinica; Agenda y Cita si la atención fue programada.
-- 3. Episodio y registros clínicos; Orden_Medica en BORRADOR, detalles y prescripciones.
-- 4. Emitir la orden; registrar resultados, estudios y prestaciones realizadas.
-- 5. Factura en BORRADOR; detalles; emitir factura; registrar pagos efectivos.
-- Los módulos de IA y auditoría usan los identificadores de sus registros previos.
-- Para insertar, omita la PK simple y obtenga el número con SELECT last_insert_rowid().
-- Las tablas de asociación usan los dos números YA EXISTENTES; no generan números.
--
-- ALCANCE Y REGLAS A COMPLETAR EN JAVA
-- El SQL crea y protege la estructura; no implementa autenticación, firma digital,
-- llamadas a IA, generación de PDF ni comunicación con laboratorio/PACS/facturación.
-- La aplicación debe generar Evento_Auditoria: la tabla no registra todo por sí sola.
-- Debe validar permisos, especialidad del profesional, disponibilidad y ausencia de
-- solapamientos de citas, tipos clínicos, publicación de resultados, y diagnóstico
-- principal al cerrar un episodio. Los estados no enumerados deben acordarse.
-- Las fechas deben convertirse a UTC antes de insertar; el formato no convierte
-- automáticamente una hora local a UTC. Turnos usan la zona local configurada.
-- Dosis y medidas REAL son aproximadas. Si se necesita representación decimal exacta
-- clínica, acordar unidades y escalas por dato antes de sustituir esos tipos.
-- Se propone una moneda con dos decimales por factura, un solo turno actual por usuario,
-- una prestación por renglón y una facturación por prestación. No cubre impuestos,
-- descuentos, fraccionamiento, refacturación, devoluciones ni historial de turnos.
-- Las anulaciones conservan los documentos y no liberan la prestación para refacturar.
-- Las órdenes/facturas emitidas y los pagos se conservan; existen bloqueos de edición.
-- La firma exige también verificar su evidencia desde la aplicación, no solo la fecha.
-- No almacene contraseñas en sujeto_identidad: es el identificador del proveedor externo.
--
-- FUENTES TECNICAS
-- https://www.sqlite.org/stricttables.html
-- https://www.sqlite.org/foreignkeys.html
-- https://www.sqlite.org/datatype3.html
-- https://www.sqlite.org/floatingpoint.html
