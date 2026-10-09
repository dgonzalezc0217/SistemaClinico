-- SISTEMA CLÍNICO: 420 REGISTROS SINTÉTICOS PARA PRUEBAS
-- Fuente: https://github.com/dgonzalezc0217/SistemaClinico/tree/master/database
-- Commit revisado: 289de13c72dd8997fc1255622cec7b48937d55a5
-- SQLite >= 3.37.0. Ejecutar sobre las 40 tablas YA CREADAS, una sola vez.
-- 10 filas nuevas en cada tabla salvo Detalle_Orden: 30. Total: 420.
-- No elimina ni modifica registros anteriores. IDs calculados desde cada MAX(id).
-- Las tablas temporales auxiliares desaparecen al final y no alteran el modelo.
-- Todos los nombres, documentos, registros profesionales y casos son ficticios.
-- Los códigos diagnósticos son INTERNOS, no códigos oficiales CIE-10/CUPS.
-- Correos example.com; teléfonos desconocidos = NULL.
-- Referencias demo:// y firmas son marcadores, no archivos ni firmas verificables.
-- Usuarios ficticios: sujeto_identidad no es una contraseña ni habilita un login.
-- Roles/permisos: asignación mínima de demostración, no política de producción.
-- IA: salidas sintéticas, no inferencias reales. Hash SHA-256 del texto que sigue
-- al prefijo demo:inline: en referencia_entrada, codificado en UTF-8.
-- Fechas de atención: 15 a 24 de septiembre de 2026. Instantes en UTC.
-- 13:00 UTC = 08:00 Bogotá. Los turnos están expresados en hora local.
-- Diez consultas ambulatorias; cinco controles de hipertensión y cinco cuadros
-- respiratorios. Cada paciente tiene una orden con medicamento, laboratorio e imagen.
-- Los 10 cargos y detalles de factura corresponden SOLO a las consultas.
-- Laboratorio/imagen se documentan clínicamente, sin cargar su facturación en este lote.
-- Medicamentos prescritos, no dispensados. No se simula su cobro.
-- Catálogos contienen opciones adicionales sin uso: no todos requieren asociaciones.
-- Detalle_Orden conserva SOLICITADO: los triggers impiden cambiarlo tras emitir.
-- La realización se consulta en Resultado_Lab/Estudio_Imagen, no en ese campo.
-- 90 000 COP = 9 000 000 centavos; 1 consulta = 1000 milésimas.
-- Ocho pagos completos y dos abonos de 45 000 COP.
--
-- USO MANUAL:
-- 1) Abrir la base que realmente utiliza tu conexión Java; cerrar operaciones pendientes.
-- 2) Activar PRAGMA foreign_keys = ON fuera de cualquier transacción.
-- 3) Ejecutar TODO este archivo, deteniendo la ejecución ante el primer error.
-- 4) Si ocurre un error: NO ejecutar COMMIT; ejecutar ROLLBACK; antes de corregir.
-- 5) No quitar BEGIN/COMMIT. Si ya hay una transacción, terminarla antes de empezar.
-- 6) Al final: 40 filas de conteo, 420 filas nuevas en total, foreign_key_check vacío,
--    integrity_check = ok; facturas con saldo 0 en ocho casos y 4500000 en dos.
-- La repetición se rechaza antes de insertar para evitar duplicar escenarios.

PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 5000;
BEGIN IMMEDIATE;

CREATE TEMP TABLE _demo_guard (ok INTEGER);
CREATE TEMP TRIGGER _demo_guard_fail BEFORE INSERT ON _demo_guard
WHEN NEW.ok <> 1
BEGIN
 SELECT RAISE(ROLLBACK, 'Carga cancelada: relaciones desactivadas, lote ya existente o conteos incorrectos.');
END;
INSERT INTO _demo_guard SELECT foreign_keys FROM pragma_foreign_keys;
INSERT INTO _demo_guard SELECT CASE WHEN EXISTS (
 SELECT 1 FROM Servicio WHERE sistema_codigo='INTERNO_DEMO' AND version_catalogo='2026.1'
) THEN 0 ELSE 1 END;

CREATE TEMP TABLE _demo_base (
 tabla TEXT PRIMARY KEY, base INTEGER NOT NULL, antes INTEGER NOT NULL, esperado INTEGER NOT NULL
);

INSERT INTO _demo_base SELECT 'Rol', COALESCE(MAX(id_rol),0), COUNT(*), 10 FROM Rol;
INSERT INTO _demo_base SELECT 'Permiso', COALESCE(MAX(id_permiso),0), COUNT(*), 10 FROM Permiso;
INSERT INTO _demo_base SELECT 'Especialidad', COALESCE(MAX(id_especialidad),0), COUNT(*), 10 FROM Especialidad;
INSERT INTO _demo_base SELECT 'Turno', COALESCE(MAX(id_turno),0), COUNT(*), 10 FROM Turno;
INSERT INTO _demo_base SELECT 'Sede', COALESCE(MAX(id_sede),0), COUNT(*), 10 FROM Sede;
INSERT INTO _demo_base SELECT 'Paciente', COALESCE(MAX(id_paciente),0), COUNT(*), 10 FROM Paciente;
INSERT INTO _demo_base SELECT 'Catalogo_Diagnostico', COALESCE(MAX(id_catalogo_diagnostico),0), COUNT(*), 10 FROM Catalogo_Diagnostico;
INSERT INTO _demo_base SELECT 'Servicio', COALESCE(MAX(id_servicio),0), COUNT(*), 10 FROM Servicio;
INSERT INTO _demo_base SELECT 'Sistema_Externo', COALESCE(MAX(id_sistema_externo),0), COUNT(*), 10 FROM Sistema_Externo;
INSERT INTO _demo_base SELECT 'Usuario', COALESCE(MAX(id_usuario),0), COUNT(*), 10 FROM Usuario;
INSERT INTO _demo_base SELECT 'Rol_Permiso', 0, COUNT(*), 10 FROM Rol_Permiso;
INSERT INTO _demo_base SELECT 'Historia_Clinica', COALESCE(MAX(id_historia_clinica),0), COUNT(*), 10 FROM Historia_Clinica;
INSERT INTO _demo_base SELECT 'Factura', COALESCE(MAX(id_factura),0), COUNT(*), 10 FROM Factura;
INSERT INTO _demo_base SELECT 'Usuario_Rol', 0, COUNT(*), 10 FROM Usuario_Rol;
INSERT INTO _demo_base SELECT 'Usuario_Especialidad', 0, COUNT(*), 10 FROM Usuario_Especialidad;
INSERT INTO _demo_base SELECT 'Alergia_Paciente', COALESCE(MAX(id_alergia_paciente),0), COUNT(*), 10 FROM Alergia_Paciente;
INSERT INTO _demo_base SELECT 'Agenda', COALESCE(MAX(id_agenda),0), COUNT(*), 10 FROM Agenda;
INSERT INTO _demo_base SELECT 'Evento_Auditoria', COALESCE(MAX(id_evento_auditoria),0), COUNT(*), 10 FROM Evento_Auditoria;
INSERT INTO _demo_base SELECT 'Antecedente', COALESCE(MAX(id_antecedente),0), COUNT(*), 10 FROM Antecedente;
INSERT INTO _demo_base SELECT 'Pago', COALESCE(MAX(id_pago),0), COUNT(*), 10 FROM Pago;
INSERT INTO _demo_base SELECT 'Cita', COALESCE(MAX(id_cita),0), COUNT(*), 10 FROM Cita;
INSERT INTO _demo_base SELECT 'Episodio', COALESCE(MAX(id_episodio),0), COUNT(*), 10 FROM Episodio;
INSERT INTO _demo_base SELECT 'Signo_Vital', COALESCE(MAX(id_signo_vital),0), COUNT(*), 10 FROM Signo_Vital;
INSERT INTO _demo_base SELECT 'Nota_Clinica', COALESCE(MAX(id_nota),0), COUNT(*), 10 FROM Nota_Clinica;
INSERT INTO _demo_base SELECT 'Orden_Medica', COALESCE(MAX(id_orden_medica),0), COUNT(*), 10 FROM Orden_Medica;
INSERT INTO _demo_base SELECT 'Diagnostico_Clinico', COALESCE(MAX(id_diagnostico_clinico),0), COUNT(*), 10 FROM Diagnostico_Clinico;
INSERT INTO _demo_base SELECT 'Analisis_IA', COALESCE(MAX(id_analisis_IA),0), COUNT(*), 10 FROM Analisis_IA;
INSERT INTO _demo_base SELECT 'Detalle_Orden', COALESCE(MAX(id_detalle_orden),0), COUNT(*), 30 FROM Detalle_Orden;
INSERT INTO _demo_base SELECT 'Sugerencia_IA', COALESCE(MAX(id_sugerencia_IA),0), COUNT(*), 10 FROM Sugerencia_IA;
INSERT INTO _demo_base SELECT 'Prescripcion', COALESCE(MAX(id_prescripcion),0), COUNT(*), 10 FROM Prescripcion;
INSERT INTO _demo_base SELECT 'Resultado_Lab', COALESCE(MAX(id_resultado_lab),0), COUNT(*), 10 FROM Resultado_Lab;
INSERT INTO _demo_base SELECT 'Estudio_Imagen', COALESCE(MAX(id_estudio_imagen),0), COUNT(*), 10 FROM Estudio_Imagen;
INSERT INTO _demo_base SELECT 'Prestacion', COALESCE(MAX(id_prestacion),0), COUNT(*), 10 FROM Prestacion;
INSERT INTO _demo_base SELECT 'Revision_IA', COALESCE(MAX(id_revision_IA),0), COUNT(*), 10 FROM Revision_IA;
INSERT INTO _demo_base SELECT 'Valor_Resultado', COALESCE(MAX(id_valor_resultado),0), COUNT(*), 10 FROM Valor_Resultado;
INSERT INTO _demo_base SELECT 'Episodio_Resultado_Lab', 0, COUNT(*), 10 FROM Episodio_Resultado_Lab;
INSERT INTO _demo_base SELECT 'Informe_Imagen', COALESCE(MAX(id_informe),0), COUNT(*), 10 FROM Informe_Imagen;
INSERT INTO _demo_base SELECT 'Episodio_Estudio_Imagen', 0, COUNT(*), 10 FROM Episodio_Estudio_Imagen;
INSERT INTO _demo_base SELECT 'Cargo', COALESCE(MAX(id_cargo),0), COUNT(*), 10 FROM Cargo;
INSERT INTO _demo_base SELECT 'Detalle_Factura', COALESCE(MAX(id_detalle_factura),0), COUNT(*), 10 FROM Detalle_Factura;

-- 01. Rol: 10 registros nuevos.
INSERT OR ROLLBACK INTO Rol (id_rol, nombre) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Rol'), 'Médico general (prueba)'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Rol'), 'Médico de familia (prueba)'),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Rol'), 'Internista (prueba)'),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Rol'), 'Médico de atención ambulatoria (prueba)'),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Rol'), 'Médico de seguimiento (prueba)'),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Rol'), 'Médico de consulta prioritaria (prueba)'),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Rol'), 'Radiólogo (prueba)'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Rol'), 'Médico de laboratorio (prueba)'),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Rol'), 'Director médico (prueba)'),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Rol'), 'Auditor médico (prueba)');

-- 02. Permiso: 10 registros nuevos.
INSERT OR ROLLBACK INTO Permiso (id_permiso, codigo, descripcion) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_CONSULTA_REGISTRAR', 'Registrar consulta clínica'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_HISTORIA_LEER', 'Consultar historia clínica'),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_ORDEN_EMITIR', 'Emitir órdenes médicas'),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_NOTA_FIRMAR', 'Firmar notas clínicas'),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_SEGUIMIENTO_REGISTRAR', 'Registrar seguimiento'),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_TRIAGE_CONSULTAR', 'Consultar clasificación de atención'),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_IMAGEN_INFORMAR', 'Informar estudios de imagen'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_LAB_VALIDAR', 'Validar resultados de laboratorio'),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_GESTION_SUPERVISAR', 'Supervisar actividad asistencial'),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Permiso'), 'DEMO_AUDITORIA_LEER', 'Consultar trazabilidad clínica');

-- 03. Especialidad: 10 registros nuevos.
INSERT OR ROLLBACK INTO Especialidad (id_especialidad, nombre, activo) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), 'Medicina general', 1),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Especialidad'), 'Medicina familiar', 1),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Especialidad'), 'Medicina interna', 1),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Especialidad'), 'Radiología', 1),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Especialidad'), 'Patología clínica', 1),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Especialidad'), 'Cardiología', 1),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Especialidad'), 'Nefrología', 1),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Especialidad'), 'Neumología', 1),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Especialidad'), 'Endocrinología', 1),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Especialidad'), 'Geriatría', 1);

-- 04. Turno: 10 registros nuevos.
INSERT OR ROLLBACK INTO Turno (id_turno, nombre, hora_inicio, hora_fin) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Turno'), 'Mañana A', '07:00:00', '13:00:00'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Turno'), 'Mañana B', '08:00:00', '14:00:00'),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Turno'), 'Diurno A', '07:00:00', '16:00:00'),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Turno'), 'Diurno B', '08:00:00', '17:00:00'),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Turno'), 'Tarde A', '13:00:00', '19:00:00'),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Turno'), 'Tarde B', '14:00:00', '20:00:00'),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Turno'), 'Imágenes diurno', '07:00:00', '17:00:00'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Turno'), 'Laboratorio diurno', '06:00:00', '16:00:00'),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Turno'), 'Dirección', '08:00:00', '17:00:00'),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Turno'), 'Auditoría', '08:00:00', '17:00:00');

-- 05. Sede: 10 registros nuevos.
INSERT OR ROLLBACK INTO Sede (id_sede, codigo, nombre) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S01', 'Vida Integral Chapinero (prueba)'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S02', 'Vida Integral Suba (prueba)'),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S03', 'Vida Integral Kennedy (prueba)'),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S04', 'Vida Integral Usaquén (prueba)'),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S05', 'Vida Integral Teusaquillo (prueba)'),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S06', 'Vida Integral Engativá (prueba)'),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S07', 'Vida Integral Fontibón (prueba)'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S08', 'Vida Integral Bosa (prueba)'),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S09', 'Vida Integral Puente Aranda (prueba)'),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Sede'), 'DEMO-S10', 'Vida Integral Barrios Unidos (prueba)');

-- 06. Catalogo_Diagnostico: 10 registros nuevos.
INSERT OR ROLLBACK INTO Catalogo_Diagnostico (id_catalogo_diagnostico, sistema_codigo, version_catalogo, codigo, descripcion) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX001', 'Hipertensión arterial esencial'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX002', 'Infección respiratoria aguda, no especificada'),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX003', 'Diabetes mellitus tipo 2'),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX004', 'Dislipidemia'),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX005', 'Hipotiroidismo'),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX006', 'Asma'),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX007', 'Rinitis alérgica'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX008', 'Gastritis'),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX009', 'Lumbalgia'),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), 'INTERNO_DEMO', '2026.1', 'DX010', 'Osteoartrosis de rodilla');

-- 07. Servicio: 10 registros nuevos.
INSERT OR ROLLBACK INTO Servicio (id_servicio, sistema_codigo, version_catalogo, codigo, nombre, tipo, duracion_minutos, activo) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV001', 'Consulta de medicina general', 'CONSULTA', 30, 1),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV002', 'Losartán 50 mg tableta', 'MEDICAMENTO', NULL, 1),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV003', 'Acetaminofén 500 mg tableta', 'MEDICAMENTO', NULL, 1),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV004', 'Creatinina sérica', 'LABORATORIO', 15, 1),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV005', 'Proteína C reactiva cuantitativa', 'LABORATORIO', 15, 1),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV006', 'Ecografía renal y de vías urinarias', 'IMAGEN', 30, 1),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV007', 'Radiografía de tórax frontal y lateral', 'IMAGEN', 20, 1),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV008', 'Hemograma completo', 'LABORATORIO', 15, 1),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV009', 'Ecografía abdominal total', 'IMAGEN', 30, 1),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Servicio'), 'INTERNO_DEMO', '2026.1', 'SRV010', 'Radiografía de rodilla', 'IMAGEN', 20, 1);

-- 08. Sistema_Externo: 10 registros nuevos.
INSERT OR ROLLBACK INTO Sistema_Externo (id_sistema_externo, codigo, nombre, tipo) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'LIS-DEMO', 'Laboratorio central de pruebas', 'LIS'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'PACS-DEMO', 'Archivo de imágenes de pruebas', 'PACS'),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'RCM-DEMO', 'Facturación de pruebas', 'RCM'),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'HCE-DEMO', 'Historia clínica de referencia', 'HCE'),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'RIS-DEMO', 'Gestión radiológica de pruebas', 'RIS'),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'IDP-DEMO', 'Identidad de pruebas', 'IDENTIDAD'),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'FARM-DEMO', 'Farmacia de pruebas', 'FARMACIA'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'PORTAL-DEMO', 'Portal del paciente de pruebas', 'PORTAL'),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'AGENDA-DEMO', 'Agendamiento de pruebas', 'AGENDA'),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Sistema_Externo'), 'DOC-DEMO', 'Gestión documental de pruebas', 'DOCUMENTAL');

-- 09. Usuario: 10 registros nuevos.
INSERT OR ROLLBACK INTO Usuario (id_usuario, nombres, apellidos, registro_profesional, activo, sujeto_identidad, tipo_documento, numero_documento, telefono, correo, fecha_nacimiento, id_turno) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), 'Valentina', 'Ríos Pardo', 'DEMO-RM-0001', 1, 'demo-clinica-20261009-profesional-01', 'CC', '9900200001', NULL, 'profesional01@example.com', '1976-03-15', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Usuario'), 'Andrés Felipe', 'Castro León', 'DEMO-RM-0002', 1, 'demo-clinica-20261009-profesional-02', 'CC', '9900200002', NULL, 'profesional02@example.com', '1977-03-15', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Usuario'), 'Camila', 'Mendoza Ruiz', 'DEMO-RM-0003', 1, 'demo-clinica-20261009-profesional-03', 'CC', '9900200003', NULL, 'profesional03@example.com', '1978-03-15', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), 'Julián', 'Pérez Salas', 'DEMO-RM-0004', 1, 'demo-clinica-20261009-profesional-04', 'CC', '9900200004', NULL, 'profesional04@example.com', '1979-03-15', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Usuario'), 'Daniela', 'Vargas Nieto', 'DEMO-RM-0005', 1, 'demo-clinica-20261009-profesional-05', 'CC', '9900200005', NULL, 'profesional05@example.com', '1980-03-15', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Usuario'), 'Sebastián', 'Mora Gil', 'DEMO-RM-0006', 1, 'demo-clinica-20261009-profesional-06', 'CC', '9900200006', NULL, 'profesional06@example.com', '1981-03-15', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario'), 'Mariana', 'Torres Peña', 'DEMO-RM-0007', 1, 'demo-clinica-20261009-profesional-07', 'CC', '9900200007', NULL, 'profesional07@example.com', '1982-03-15', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario'), 'Felipe', 'Suárez Rojas', 'DEMO-RM-0008', 1, 'demo-clinica-20261009-profesional-08', 'CC', '9900200008', NULL, 'profesional08@example.com', '1983-03-15', (SELECT base + 8 FROM _demo_base WHERE tabla = 'Turno')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Usuario'), 'Carolina', 'Díaz Ortiz', 'DEMO-RM-0009', 1, 'demo-clinica-20261009-profesional-09', 'CC', '9900200009', NULL, 'profesional09@example.com', '1984-03-15', NULL),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Usuario'), 'Nicolás', 'Herrera Cano', 'DEMO-RM-0010', 1, 'demo-clinica-20261009-profesional-10', 'CC', '9900200010', NULL, 'profesional10@example.com', '1985-03-15', NULL);

-- 10. Rol_Permiso: 10 registros nuevos.
INSERT OR ROLLBACK INTO Rol_Permiso (id_rol, id_permiso) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Permiso')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Rol'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Permiso'));

-- 11. Usuario_Rol: 10 registros nuevos.
INSERT OR ROLLBACK INTO Usuario_Rol (id_usuario, id_rol) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Rol')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Rol'));

-- 12. Usuario_Especialidad: 10 registros nuevos.
INSERT OR ROLLBACK INTO Usuario_Especialidad (id_usuario, id_especialidad) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Especialidad')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Especialidad'));

-- 13. Paciente: 10 registros nuevos.
INSERT OR ROLLBACK INTO Paciente (id_paciente, tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento, grupo_sanguineo, factor_rh, sexo, telefono, estado_identificacion, correo, creado_en) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100001', 'Luz Marina', 'Cárdenas Vega', '1968-02-14', 'O', '+', 'F', NULL, 'IDENTIFICADO', 'paciente01@example.com', '2026-09-15 12:40:00'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100002', 'Jorge Enrique', 'Salazar Pinto', '1961-07-23', 'A', '+', 'M', NULL, 'IDENTIFICADO', 'paciente02@example.com', '2026-09-16 12:40:00'),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100003', 'Gloria Patricia', 'Molina Rueda', '1974-11-09', 'B', '+', 'F', NULL, 'IDENTIFICADO', NULL, '2026-09-17 12:40:00'),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100004', 'Carlos Alberto', 'Reyes Acosta', '1959-04-18', NULL, NULL, 'M', NULL, 'IDENTIFICADO', 'paciente04@example.com', '2026-09-18 12:40:00'),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100005', 'Martha Cecilia', 'Duarte Silva', '1970-09-05', 'O', '-', 'F', NULL, 'IDENTIFICADO', 'paciente05@example.com', '2026-09-19 12:40:00'),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100006', 'Ana Sofía', 'Beltrán Mesa', '1998-05-12', 'A', '+', 'F', NULL, 'IDENTIFICADO', 'paciente06@example.com', '2026-09-20 12:40:00'),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100007', 'Diego Alejandro', 'Ospina Lara', '1987-12-03', 'O', '+', 'M', NULL, 'IDENTIFICADO', 'paciente07@example.com', '2026-09-21 12:40:00'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100008', 'Paula Andrea', 'Quintero Ríos', '1992-08-27', 'AB', '+', 'F', NULL, 'IDENTIFICADO', 'paciente08@example.com', '2026-09-22 12:40:00'),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100009', 'Luis Fernando', 'Pineda Cruz', '1980-06-16', 'B', '-', 'M', NULL, 'IDENTIFICADO', NULL, '2026-09-23 12:40:00'),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Paciente'), 'CC', '9900100010', 'Sandra Milena', 'Romero Arias', '1990-01-30', NULL, NULL, 'F', NULL, 'IDENTIFICADO', 'paciente10@example.com', '2026-09-24 12:40:00');

-- 14. Historia_Clinica: 10 registros nuevos.
INSERT OR ROLLBACK INTO Historia_Clinica (id_historia_clinica, numero_historia, abierta_en, id_paciente) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-001', '2026-09-15 12:45:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-002', '2026-09-16 12:45:00', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-003', '2026-09-17 12:45:00', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-004', '2026-09-18 12:45:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-005', '2026-09-19 12:45:00', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-006', '2026-09-20 12:45:00', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-007', '2026-09-21 12:45:00', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-008', '2026-09-22 12:45:00', (SELECT base + 8 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-009', '2026-09-23 12:45:00', (SELECT base + 9 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'DEMO-2026-HC-010', '2026-09-24 12:45:00', (SELECT base + 10 FROM _demo_base WHERE tabla = 'Paciente'));

-- 15. Alergia_Paciente: 10 registros nuevos.
INSERT OR ROLLBACK INTO Alergia_Paciente (id_alergia_paciente, sustancia, reaccion, estado, registrada_en, id_usuario, id_historia_clinica, observaciones) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Penicilina', 'Urticaria', 'REFERIDA', '2026-09-15 13:02:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'Antecedente referido por el paciente; pendiente soporte externo.'),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Mariscos', 'Urticaria', 'REFERIDA', '2026-09-16 13:02:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Látex', 'Dermatitis de contacto', 'REFERIDA', '2026-09-17 13:02:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Maní', 'Urticaria', 'REFERIDA', '2026-09-18 13:02:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Trimetoprim/sulfametoxazol', 'Exantema', 'REFERIDA', '2026-09-19 13:02:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Amoxicilina', 'Urticaria', 'REFERIDA', '2026-09-20 13:02:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Ibuprofeno', 'Angioedema referido', 'REFERIDA', '2026-09-21 13:02:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Historia_Clinica'), 'Antecedente referido por el paciente; pendiente soporte externo.'),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Látex', 'Dermatitis de contacto', 'REFERIDA', '2026-09-22 13:02:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Camarón', 'Urticaria', 'REFERIDA', '2026-09-23 13:02:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Alergia_Paciente'), 'Diclofenaco', 'Urticaria', 'REFERIDA', '2026-09-24 13:02:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Historia_Clinica'), NULL);

-- 16. Antecedente: 10 registros nuevos.
INSERT OR ROLLBACK INTO Antecedente (id_antecedente, tipo, descripcion, registrado_en, activo, id_usuario, id_historia_clinica) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Antecedente'), 'PATOLOGICO', 'Hipertensión diagnosticada en 2018.', '2026-09-15 13:03:00', 1, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Antecedente'), 'PATOLOGICO', 'Hipertensión diagnosticada en 2012.', '2026-09-16 13:03:00', 1, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Antecedente'), 'PATOLOGICO', 'Hipertensión diagnosticada en 2020.', '2026-09-17 13:03:00', 1, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Antecedente'), 'PATOLOGICO', 'Hipertensión diagnosticada en 2010.', '2026-09-18 13:03:00', 1, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Antecedente'), 'PATOLOGICO', 'Hipertensión diagnosticada en 2017.', '2026-09-19 13:03:00', 1, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Antecedente'), 'QUIRURGICO', 'Apendicectomía en 2015, sin complicaciones.', '2026-09-20 13:03:00', 1, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Antecedente'), 'QUIRURGICO', 'Colecistectomía en 2021, sin complicaciones.', '2026-09-21 13:03:00', 1, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Antecedente'), 'FAMILIAR', 'Madre con hipertensión arterial.', '2026-09-22 13:03:00', 1, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Antecedente'), 'QUIRURGICO', 'Herniorrafia inguinal en 2019.', '2026-09-23 13:03:00', 1, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Historia_Clinica')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Antecedente'), 'FAMILIAR', 'Padre con diabetes mellitus tipo 2.', '2026-09-24 13:03:00', 1, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Historia_Clinica'));

-- 17. Agenda: 10 registros nuevos.
INSERT OR ROLLBACK INTO Agenda (id_agenda, inicio, fin, estado, id_sede, id_usuario) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-15 12:00:00', '2026-09-15 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-16 12:00:00', '2026-09-16 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-17 12:00:00', '2026-09-17 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-18 12:00:00', '2026-09-18 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-19 12:00:00', '2026-09-19 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-20 12:00:00', '2026-09-20 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-21 12:00:00', '2026-09-21 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-22 12:00:00', '2026-09-22 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-23 12:00:00', '2026-09-23 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Agenda'), '2026-09-24 12:00:00', '2026-09-24 18:00:00', 'CERRADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'));

-- 18. Cita: 10 registros nuevos.
INSERT OR ROLLBACK INTO Cita (id_cita, inicio, fin, estado, prioridad, motivo_cancelacion, id_paciente, id_agenda, id_especialidad, id_servicio) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-15 13:00:00', '2026-09-15 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-16 13:00:00', '2026-09-16 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 2 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-17 13:00:00', '2026-09-17 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 3 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-18 13:00:00', '2026-09-18 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-19 13:00:00', '2026-09-19 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 5 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-20 13:00:00', '2026-09-20 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 6 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-21 13:00:00', '2026-09-21 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 7 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-22 13:00:00', '2026-09-22 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 8 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-23 13:00:00', '2026-09-23 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 9 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Cita'), '2026-09-24 13:00:00', '2026-09-24 13:30:00', 'ATENDIDA', 'NORMAL', NULL, (SELECT base + 10 FROM _demo_base WHERE tabla = 'Paciente'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Agenda'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Especialidad'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'));

-- 19. Episodio: 10 registros nuevos.
INSERT OR ROLLBACK INTO Episodio (id_episodio, tipo_atencion, motivo_consulta, estado, nivel_triage, ingreso_en, egreso_en, id_sede, id_historia_clinica, id_cita) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Control de hipertensión; estudio por elevación previa de creatinina.', 'CERRADO', NULL, '2026-09-15 13:00:00', '2026-09-15 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Control de hipertensión; estudio por elevación previa de creatinina.', 'CERRADO', NULL, '2026-09-16 13:00:00', '2026-09-16 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Control de hipertensión; estudio por elevación previa de creatinina.', 'CERRADO', NULL, '2026-09-17 13:00:00', '2026-09-17 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Control de hipertensión; estudio por elevación previa de creatinina.', 'CERRADO', NULL, '2026-09-18 13:00:00', '2026-09-18 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Control de hipertensión; estudio por elevación previa de creatinina.', 'CERRADO', NULL, '2026-09-19 13:00:00', '2026-09-19 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Tos de siete días, fiebre referida y dolor muscular; descartar compromiso pulmonar.', 'CERRADO', NULL, '2026-09-20 13:00:00', '2026-09-20 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Tos de siete días, fiebre referida y dolor muscular; descartar compromiso pulmonar.', 'CERRADO', NULL, '2026-09-21 13:00:00', '2026-09-21 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Tos de siete días, fiebre referida y dolor muscular; descartar compromiso pulmonar.', 'CERRADO', NULL, '2026-09-22 13:00:00', '2026-09-22 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Tos de siete días, fiebre referida y dolor muscular; descartar compromiso pulmonar.', 'CERRADO', NULL, '2026-09-23 13:00:00', '2026-09-23 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Cita')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'), 'AMBULATORIA', 'Tos de siete días, fiebre referida y dolor muscular; descartar compromiso pulmonar.', 'CERRADO', NULL, '2026-09-24 13:00:00', '2026-09-24 17:00:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sede'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Historia_Clinica'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Cita'));

-- 20. Signo_Vital: 10 registros nuevos.
INSERT OR ROLLBACK INTO Signo_Vital (id_signo_vital, codigo_signo, valor, unidad, medido_en, id_usuario, id_episodio) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'PAS', 132, 'mmHg', '2026-09-15 13:05:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'PAS', 138, 'mmHg', '2026-09-16 13:05:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'PAS', 128, 'mmHg', '2026-09-17 13:05:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'PAS', 136, 'mmHg', '2026-09-18 13:05:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'PAS', 130, 'mmHg', '2026-09-19 13:05:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'TEMPERATURA', 37.8, '°C', '2026-09-20 13:05:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'TEMPERATURA', 38.0, '°C', '2026-09-21 13:05:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'TEMPERATURA', 37.6, '°C', '2026-09-22 13:05:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'TEMPERATURA', 37.9, '°C', '2026-09-23 13:05:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Signo_Vital'), 'TEMPERATURA', 37.7, '°C', '2026-09-24 13:05:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'));

-- 21. Nota_Clinica: 10 registros nuevos.
INSERT OR ROLLBACK INTO Nota_Clinica (id_nota, id_nota_previa, tipo, contenido, registrada_en, firmada_en, referencia_firma, motivo_rectificacion, id_episodio, id_usuario) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Control de hipertensión en tratamiento habitual con losartán. Sin síntomas agudos. Se renueva tratamiento previamente tolerado y se solicita creatinina y ecografía renal por alteración previa de función renal. Seguimiento con resultados.', '2026-09-15 13:15:00', '2026-09-15 13:20:00', 'demo://firmas/nota/001', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Control de hipertensión en tratamiento habitual con losartán. Sin síntomas agudos. Se renueva tratamiento previamente tolerado y se solicita creatinina y ecografía renal por alteración previa de función renal. Seguimiento con resultados.', '2026-09-16 13:15:00', '2026-09-16 13:20:00', 'demo://firmas/nota/002', NULL, (SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Control de hipertensión en tratamiento habitual con losartán. Sin síntomas agudos. Se renueva tratamiento previamente tolerado y se solicita creatinina y ecografía renal por alteración previa de función renal. Seguimiento con resultados.', '2026-09-17 13:15:00', '2026-09-17 13:20:00', 'demo://firmas/nota/003', NULL, (SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Control de hipertensión en tratamiento habitual con losartán. Sin síntomas agudos. Se renueva tratamiento previamente tolerado y se solicita creatinina y ecografía renal por alteración previa de función renal. Seguimiento con resultados.', '2026-09-18 13:15:00', '2026-09-18 13:20:00', 'demo://firmas/nota/004', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Control de hipertensión en tratamiento habitual con losartán. Sin síntomas agudos. Se renueva tratamiento previamente tolerado y se solicita creatinina y ecografía renal por alteración previa de función renal. Seguimiento con resultados.', '2026-09-19 13:15:00', '2026-09-19 13:20:00', 'demo://firmas/nota/005', NULL, (SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Cuadro respiratorio de siete días con mialgias y fiebre referida. Se solicita proteína C reactiva y radiografía de tórax por persistencia de síntomas. Manejo sintomático y reevaluación con resultados; instrucciones de reconsulta explicadas.', '2026-09-20 13:15:00', '2026-09-20 13:20:00', 'demo://firmas/nota/006', NULL, (SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Cuadro respiratorio de siete días con mialgias y fiebre referida. Se solicita proteína C reactiva y radiografía de tórax por persistencia de síntomas. Manejo sintomático y reevaluación con resultados; instrucciones de reconsulta explicadas.', '2026-09-21 13:15:00', '2026-09-21 13:20:00', 'demo://firmas/nota/007', NULL, (SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Cuadro respiratorio de siete días con mialgias y fiebre referida. Se solicita proteína C reactiva y radiografía de tórax por persistencia de síntomas. Manejo sintomático y reevaluación con resultados; instrucciones de reconsulta explicadas.', '2026-09-22 13:15:00', '2026-09-22 13:20:00', 'demo://firmas/nota/008', NULL, (SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Cuadro respiratorio de siete días con mialgias y fiebre referida. Se solicita proteína C reactiva y radiografía de tórax por persistencia de síntomas. Manejo sintomático y reevaluación con resultados; instrucciones de reconsulta explicadas.', '2026-09-23 13:15:00', '2026-09-23 13:20:00', 'demo://firmas/nota/009', NULL, (SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Nota_Clinica'), NULL, 'CONSULTA', 'Cuadro respiratorio de siete días con mialgias y fiebre referida. Se solicita proteína C reactiva y radiografía de tórax por persistencia de síntomas. Manejo sintomático y reevaluación con resultados; instrucciones de reconsulta explicadas.', '2026-09-24 13:15:00', '2026-09-24 13:20:00', 'demo://firmas/nota/010', NULL, (SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'));

-- 22. Orden_Medica: 10 registros nuevos.
INSERT OR ROLLBACK INTO Orden_Medica (id_orden_medica, emitida_en, prioridad, estado, referencia_firma, id_usuario, id_episodio) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Orden_Medica'), NULL, 'NORMAL', 'BORRADOR', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'));

-- 23. Detalle_Orden: 30 registros nuevos.
INSERT OR ROLLBACK INTO Detalle_Orden (id_detalle_orden, cantidad, indicaciones, estado, id_servicio, id_orden_medica) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 30, 'Continuación de tratamiento habitual; revisión en control.', 'SOLICITADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 11 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 21 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Evaluación renal y vías urinarias.', 'SOLICITADO', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 30, 'Continuación de tratamiento habitual; revisión en control.', 'SOLICITADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 12 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 22 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Evaluación renal y vías urinarias.', 'SOLICITADO', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 30, 'Continuación de tratamiento habitual; revisión en control.', 'SOLICITADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 13 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 23 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Evaluación renal y vías urinarias.', 'SOLICITADO', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 30, 'Continuación de tratamiento habitual; revisión en control.', 'SOLICITADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 14 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 24 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Evaluación renal y vías urinarias.', 'SOLICITADO', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 30, 'Continuación de tratamiento habitual; revisión en control.', 'SOLICITADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 15 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 25 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Evaluación renal y vías urinarias.', 'SOLICITADO', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 9, 'Uso sintomático durante tres días.', 'SOLICITADO', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 16 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 26 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Proyecciones frontal y lateral; tos persistente.', 'SOLICITADO', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 9, 'Uso sintomático durante tres días.', 'SOLICITADO', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 17 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 27 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Proyecciones frontal y lateral; tos persistente.', 'SOLICITADO', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 9, 'Uso sintomático durante tres días.', 'SOLICITADO', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 18 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 28 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Proyecciones frontal y lateral; tos persistente.', 'SOLICITADO', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 9, 'Uso sintomático durante tres días.', 'SOLICITADO', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 19 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 29 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Proyecciones frontal y lateral; tos persistente.', 'SOLICITADO', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 9, 'Uso sintomático durante tres días.', 'SOLICITADO', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 20 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Muestra de sangre venosa.', 'SOLICITADO', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Orden_Medica')),
    ((SELECT base + 30 FROM _demo_base WHERE tabla = 'Detalle_Orden'), 1, 'Proyecciones frontal y lateral; tos persistente.', 'SOLICITADO', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Servicio'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Orden_Medica'));

-- 24. Prescripcion: 10 registros nuevos.
INSERT OR ROLLBACK INTO Prescripcion (id_prescripcion, dosis, unidad_dosis, via, frecuencia, inicio, fin, id_detalle_orden) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Prescripcion'), 50, 'mg', 'ORAL', 'Cada 24 horas', '2026-09-15 18:00:00', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Prescripcion'), 50, 'mg', 'ORAL', 'Cada 24 horas', '2026-09-16 18:00:00', NULL, (SELECT base + 2 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Prescripcion'), 50, 'mg', 'ORAL', 'Cada 24 horas', '2026-09-17 18:00:00', NULL, (SELECT base + 3 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Prescripcion'), 50, 'mg', 'ORAL', 'Cada 24 horas', '2026-09-18 18:00:00', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Prescripcion'), 50, 'mg', 'ORAL', 'Cada 24 horas', '2026-09-19 18:00:00', NULL, (SELECT base + 5 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Prescripcion'), 500, 'mg', 'ORAL', 'Cada 8 horas si dolor o fiebre', '2026-09-20 18:00:00', '2026-09-23 18:00:00', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Prescripcion'), 500, 'mg', 'ORAL', 'Cada 8 horas si dolor o fiebre', '2026-09-21 18:00:00', '2026-09-24 18:00:00', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Prescripcion'), 500, 'mg', 'ORAL', 'Cada 8 horas si dolor o fiebre', '2026-09-22 18:00:00', '2026-09-25 18:00:00', (SELECT base + 8 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Prescripcion'), 500, 'mg', 'ORAL', 'Cada 8 horas si dolor o fiebre', '2026-09-23 18:00:00', '2026-09-26 18:00:00', (SELECT base + 9 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Prescripcion'), 500, 'mg', 'ORAL', 'Cada 8 horas si dolor o fiebre', '2026-09-24 18:00:00', '2026-09-27 18:00:00', (SELECT base + 10 FROM _demo_base WHERE tabla = 'Detalle_Orden'));

-- Emitir únicamente las diez órdenes nuevas, después de detalles y prescripciones.
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-15 13:25:00', referencia_firma='demo://firmas/orden/001' WHERE id_orden_medica=(SELECT base + 1 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-16 13:25:00', referencia_firma='demo://firmas/orden/002' WHERE id_orden_medica=(SELECT base + 2 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-17 13:25:00', referencia_firma='demo://firmas/orden/003' WHERE id_orden_medica=(SELECT base + 3 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-18 13:25:00', referencia_firma='demo://firmas/orden/004' WHERE id_orden_medica=(SELECT base + 4 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-19 13:25:00', referencia_firma='demo://firmas/orden/005' WHERE id_orden_medica=(SELECT base + 5 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-20 13:25:00', referencia_firma='demo://firmas/orden/006' WHERE id_orden_medica=(SELECT base + 6 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-21 13:25:00', referencia_firma='demo://firmas/orden/007' WHERE id_orden_medica=(SELECT base + 7 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-22 13:25:00', referencia_firma='demo://firmas/orden/008' WHERE id_orden_medica=(SELECT base + 8 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-23 13:25:00', referencia_firma='demo://firmas/orden/009' WHERE id_orden_medica=(SELECT base + 9 FROM _demo_base WHERE tabla = 'Orden_Medica');
UPDATE Orden_Medica SET estado='EMITIDA', emitida_en='2026-09-24 13:25:00', referencia_firma='demo://firmas/orden/010' WHERE id_orden_medica=(SELECT base + 10 FROM _demo_base WHERE tabla = 'Orden_Medica');

-- 25. Resultado_Lab: 10 registros nuevos.
INSERT OR ROLLBACK INTO Resultado_Lab (id_resultado_lab, codigo_resultado_externo, version, observacion, referencia_pdf, muestra_tomada_en, registrado_en, validado_en, estado, id_detalle_orden, id_sistema_externo, id_usuario_validador) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0001', '1', NULL, NULL, '2026-09-15 13:40:00', '2026-09-15 14:20:00', '2026-09-15 14:30:00', 'VALIDADO', (SELECT base + 11 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0002', '1', NULL, NULL, '2026-09-16 13:40:00', '2026-09-16 14:20:00', '2026-09-16 14:30:00', 'VALIDADO', (SELECT base + 12 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0003', '1', NULL, NULL, '2026-09-17 13:40:00', '2026-09-17 14:20:00', '2026-09-17 14:30:00', 'VALIDADO', (SELECT base + 13 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0004', '1', NULL, NULL, '2026-09-18 13:40:00', '2026-09-18 14:20:00', '2026-09-18 14:30:00', 'VALIDADO', (SELECT base + 14 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0005', '1', NULL, NULL, '2026-09-19 13:40:00', '2026-09-19 14:20:00', '2026-09-19 14:30:00', 'VALIDADO', (SELECT base + 15 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0006', '1', NULL, NULL, '2026-09-20 13:40:00', '2026-09-20 14:20:00', '2026-09-20 14:30:00', 'VALIDADO', (SELECT base + 16 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0007', '1', NULL, NULL, '2026-09-21 13:40:00', '2026-09-21 14:20:00', '2026-09-21 14:30:00', 'VALIDADO', (SELECT base + 17 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0008', '1', NULL, NULL, '2026-09-22 13:40:00', '2026-09-22 14:20:00', '2026-09-22 14:30:00', 'VALIDADO', (SELECT base + 18 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0009', '1', NULL, NULL, '2026-09-23 13:40:00', '2026-09-23 14:20:00', '2026-09-23 14:30:00', 'VALIDADO', (SELECT base + 19 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Resultado_Lab'), 'DEMO-LAB-0010', '1', NULL, NULL, '2026-09-24 13:40:00', '2026-09-24 14:20:00', '2026-09-24 14:30:00', 'VALIDADO', (SELECT base + 20 FROM _demo_base WHERE tabla = 'Detalle_Orden'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Usuario'));

-- 26. Valor_Resultado: 10 registros nuevos.
INSERT OR ROLLBACK INTO Valor_Resultado (id_valor_resultado, codigo_analito, nombre_analito, valor_numerico, valor_textual, unidad, referencia_aplicada, interpretacion, id_resultado_lab) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'CREA-INT', 'Creatinina sérica', 1.05, NULL, 'mg/dL', 'Intervalo del laboratorio de demostración: 0.60–1.20 mg/dL', 'DENTRO_DE_REFERENCIA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'CREA-INT', 'Creatinina sérica', 1.12, NULL, 'mg/dL', 'Intervalo del laboratorio de demostración: 0.60–1.20 mg/dL', 'DENTRO_DE_REFERENCIA', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'CREA-INT', 'Creatinina sérica', 0.98, NULL, 'mg/dL', 'Intervalo del laboratorio de demostración: 0.60–1.20 mg/dL', 'DENTRO_DE_REFERENCIA', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'CREA-INT', 'Creatinina sérica', 1.18, NULL, 'mg/dL', 'Intervalo del laboratorio de demostración: 0.60–1.20 mg/dL', 'DENTRO_DE_REFERENCIA', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'CREA-INT', 'Creatinina sérica', 1.02, NULL, 'mg/dL', 'Intervalo del laboratorio de demostración: 0.60–1.20 mg/dL', 'DENTRO_DE_REFERENCIA', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'PCR-INT', 'Proteína C reactiva', 8.0, NULL, 'mg/L', 'Intervalo del laboratorio de demostración: menor de 5 mg/L', 'ELEVADO', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'PCR-INT', 'Proteína C reactiva', 12.0, NULL, 'mg/L', 'Intervalo del laboratorio de demostración: menor de 5 mg/L', 'ELEVADO', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'PCR-INT', 'Proteína C reactiva', 6.0, NULL, 'mg/L', 'Intervalo del laboratorio de demostración: menor de 5 mg/L', 'ELEVADO', (SELECT base + 8 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'PCR-INT', 'Proteína C reactiva', 10.0, NULL, 'mg/L', 'Intervalo del laboratorio de demostración: menor de 5 mg/L', 'ELEVADO', (SELECT base + 9 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Valor_Resultado'), 'PCR-INT', 'Proteína C reactiva', 7.0, NULL, 'mg/L', 'Intervalo del laboratorio de demostración: menor de 5 mg/L', 'ELEVADO', (SELECT base + 10 FROM _demo_base WHERE tabla = 'Resultado_Lab'));

-- 27. Estudio_Imagen: 10 registros nuevos.
INSERT OR ROLLBACK INTO Estudio_Imagen (id_estudio_imagen, study_instance_uid, modalidad, referencia_pacs, realizado_en, estado, id_sistema_externo, id_detalle_orden) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000001', 'US', 'demo://pacs/studies/2.25.100000000000000000000000000000000001', '2026-09-15 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 21 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000002', 'US', 'demo://pacs/studies/2.25.100000000000000000000000000000000002', '2026-09-16 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 22 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000003', 'US', 'demo://pacs/studies/2.25.100000000000000000000000000000000003', '2026-09-17 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 23 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000004', 'US', 'demo://pacs/studies/2.25.100000000000000000000000000000000004', '2026-09-18 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 24 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000005', 'US', 'demo://pacs/studies/2.25.100000000000000000000000000000000005', '2026-09-19 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 25 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000006', 'DX', 'demo://pacs/studies/2.25.100000000000000000000000000000000006', '2026-09-20 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 26 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000007', 'DX', 'demo://pacs/studies/2.25.100000000000000000000000000000000007', '2026-09-21 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 27 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000008', 'DX', 'demo://pacs/studies/2.25.100000000000000000000000000000000008', '2026-09-22 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 28 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000009', 'DX', 'demo://pacs/studies/2.25.100000000000000000000000000000000009', '2026-09-23 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 29 FROM _demo_base WHERE tabla = 'Detalle_Orden')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), '2.25.100000000000000000000000000000000010', 'DX', 'demo://pacs/studies/2.25.100000000000000000000000000000000010', '2026-09-24 15:00:00', 'INFORMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sistema_Externo'), (SELECT base + 30 FROM _demo_base WHERE tabla = 'Detalle_Orden'));

-- 28. Informe_Imagen: 10 registros nuevos.
INSERT OR ROLLBACK INTO Informe_Imagen (id_informe, version, hallazgos, conclusion, referencia_pdf, creado_en, firmado_en, referencia_firma, estado, id_estudio_imagen, id_usuario) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Riñones de contornos conservados. Sin dilatación de sistemas colectores ni litiasis visible.', 'Sin signos ecográficos de obstrucción urinaria.', NULL, '2026-09-15 15:20:00', '2026-09-15 15:30:00', 'demo://firmas/imagen/001', 'FIRMADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Riñones de contornos conservados. Sin dilatación de sistemas colectores ni litiasis visible.', 'Sin signos ecográficos de obstrucción urinaria.', NULL, '2026-09-16 15:20:00', '2026-09-16 15:30:00', 'demo://firmas/imagen/002', 'FIRMADO', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Riñones de contornos conservados. Sin dilatación de sistemas colectores ni litiasis visible.', 'Sin signos ecográficos de obstrucción urinaria.', NULL, '2026-09-17 15:20:00', '2026-09-17 15:30:00', 'demo://firmas/imagen/003', 'FIRMADO', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Riñones de contornos conservados. Sin dilatación de sistemas colectores ni litiasis visible.', 'Sin signos ecográficos de obstrucción urinaria.', NULL, '2026-09-18 15:20:00', '2026-09-18 15:30:00', 'demo://firmas/imagen/004', 'FIRMADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Riñones de contornos conservados. Sin dilatación de sistemas colectores ni litiasis visible.', 'Sin signos ecográficos de obstrucción urinaria.', NULL, '2026-09-19 15:20:00', '2026-09-19 15:30:00', 'demo://firmas/imagen/005', 'FIRMADO', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Sin consolidaciones focales ni derrame pleural. Silueta cardiomediastínica sin aumento aparente.', 'Sin evidencia radiográfica de neumonía.', NULL, '2026-09-20 15:20:00', '2026-09-20 15:30:00', 'demo://firmas/imagen/006', 'FIRMADO', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Sin consolidaciones focales ni derrame pleural. Silueta cardiomediastínica sin aumento aparente.', 'Sin evidencia radiográfica de neumonía.', NULL, '2026-09-21 15:20:00', '2026-09-21 15:30:00', 'demo://firmas/imagen/007', 'FIRMADO', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Sin consolidaciones focales ni derrame pleural. Silueta cardiomediastínica sin aumento aparente.', 'Sin evidencia radiográfica de neumonía.', NULL, '2026-09-22 15:20:00', '2026-09-22 15:30:00', 'demo://firmas/imagen/008', 'FIRMADO', (SELECT base + 8 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Sin consolidaciones focales ni derrame pleural. Silueta cardiomediastínica sin aumento aparente.', 'Sin evidencia radiográfica de neumonía.', NULL, '2026-09-23 15:20:00', '2026-09-23 15:30:00', 'demo://firmas/imagen/009', 'FIRMADO', (SELECT base + 9 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Informe_Imagen'), '1', 'Sin consolidaciones focales ni derrame pleural. Silueta cardiomediastínica sin aumento aparente.', 'Sin evidencia radiográfica de neumonía.', NULL, '2026-09-24 15:20:00', '2026-09-24 15:30:00', 'demo://firmas/imagen/010', 'FIRMADO', (SELECT base + 10 FROM _demo_base WHERE tabla = 'Estudio_Imagen'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Usuario'));

-- 29. Episodio_Resultado_Lab: 10 registros nuevos.
INSERT OR ROLLBACK INTO Episodio_Resultado_Lab (id_episodio, id_resultado_lab) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Resultado_Lab')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Resultado_Lab'));

-- 30. Episodio_Estudio_Imagen: 10 registros nuevos.
INSERT OR ROLLBACK INTO Episodio_Estudio_Imagen (id_episodio, id_estudio_imagen) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Estudio_Imagen')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Estudio_Imagen'));

-- 31. Diagnostico_Clinico: 10 registros nuevos.
INSERT OR ROLLBACK INTO Diagnostico_Clinico (id_diagnostico_clinico, tipo, registrado_en, estado, id_usuario, id_episodio, id_catalogo_diagnostico) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-15 16:00:00', 'CONFIRMADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-16 16:00:00', 'CONFIRMADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-17 16:00:00', 'CONFIRMADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-18 16:00:00', 'CONFIRMADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-19 16:00:00', 'CONFIRMADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-20 16:00:00', 'CONFIRMADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-21 16:00:00', 'CONFIRMADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-22 16:00:00', 'CONFIRMADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-23 16:00:00', 'CONFIRMADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Diagnostico_Clinico'), 'PRINCIPAL', '2026-09-24 16:00:00', 'CONFIRMADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'));

-- 32. Analisis_IA: 10 registros nuevos.
INSERT OR ROLLBACK INTO Analisis_IA (id_analisis_IA, nombre_modelo, version_modelo, referencia_entrada, hash_entrada, solicitado_en, terminado_en, estado, id_usuario, id_episodio) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=1;diagnostico_interno=1;valor_laboratorio=1.05', 'e851c8feae4e56ef68ccd97abd6a51d06d0a62f0ad0c1fce99a7ea956e23de26', '2026-09-15 16:05:00', '2026-09-15 16:06:00', 'COMPLETADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=2;diagnostico_interno=1;valor_laboratorio=1.12', 'e0f71239af0578d1c5e2e309d5078d46299118189c608d3355cc79d234b99c1d', '2026-09-16 16:05:00', '2026-09-16 16:06:00', 'COMPLETADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=3;diagnostico_interno=1;valor_laboratorio=0.98', '2d5a3ab30be270d505a19f93a0f6a2870685ef4b0df40f1902642e0bd4db3fba', '2026-09-17 16:05:00', '2026-09-17 16:06:00', 'COMPLETADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=4;diagnostico_interno=1;valor_laboratorio=1.18', 'ed9b38ed1f57438e32029db553fb3152a90019134d3f70e88a583d2a66575660', '2026-09-18 16:05:00', '2026-09-18 16:06:00', 'COMPLETADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=5;diagnostico_interno=1;valor_laboratorio=1.02', '08eb6d27cfa37584a00560d850115a4b3825c6c1cabe3e763e4449174becc0ee', '2026-09-19 16:05:00', '2026-09-19 16:06:00', 'COMPLETADO', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=6;diagnostico_interno=2;valor_laboratorio=8.0', '71d181bf41cf66b6ee708a2f582693aa8be24d458c329901035508b321ef428d', '2026-09-20 16:05:00', '2026-09-20 16:06:00', 'COMPLETADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=7;diagnostico_interno=2;valor_laboratorio=12.0', 'ba1cabb6ccaa73af654e839e5c86304510ab15981784b7f594eb66d3f97589d8', '2026-09-21 16:05:00', '2026-09-21 16:06:00', 'COMPLETADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=8;diagnostico_interno=2;valor_laboratorio=6.0', 'eafd0bd2c4be25bf6b110da74d3bdc3fcfb2c616959457ee2ada93910a043c7d', '2026-09-22 16:05:00', '2026-09-22 16:06:00', 'COMPLETADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=9;diagnostico_interno=2;valor_laboratorio=10.0', '66ed48a5c65b1888ead930fe50c439851626e31fda8567f68459cf51a84f860b', '2026-09-23 16:05:00', '2026-09-23 16:06:00', 'COMPLETADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Analisis_IA'), 'Clasificador clínico DEMO (sin ejecución real)', '0.1-sintetica', 'demo:inline:episodio_demo=10;diagnostico_interno=2;valor_laboratorio=7.0', 'a398b0fddf0e422f91767d63107bc73935cf1661c4fd12a25515ad2adb6a12e7', '2026-09-24 16:05:00', '2026-09-24 16:06:00', 'COMPLETADO', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'));

-- 33. Sugerencia_IA: 10 registros nuevos.
INSERT OR ROLLBACK INTO Sugerencia_IA (id_sugerencia_IA, probabilidad, explicacion, id_catalogo_diagnostico, id_analisis_IA) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.91, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.89, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.88, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.92, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.9, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.76, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.74, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.79, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.77, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Analisis_IA')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), 0.75, 'Salida sintética para probar el flujo de revisión; compatible con el diagnóstico registrado. No corresponde a una inferencia real.', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Catalogo_Diagnostico'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Analisis_IA'));

-- 34. Revision_IA: 10 registros nuevos.
INSERT OR ROLLBACK INTO Revision_IA (id_revision_IA, decision, justificacion, revisada_en, id_sugerencia_IA, id_usuario) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-15 16:15:00', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-16 16:15:00', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-17 16:15:00', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-18 16:15:00', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-19 16:15:00', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-20 16:15:00', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-21 16:15:00', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-22 16:15:00', (SELECT base + 8 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-23 16:15:00', (SELECT base + 9 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Revision_IA'), 'ACEPTADA', 'Caso de demostración: concordancia con la valoración médica y los resultados; decisión clínica documentada por el profesional.', '2026-09-24 16:15:00', (SELECT base + 10 FROM _demo_base WHERE tabla = 'Sugerencia_IA'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'));

-- 35. Prestacion: 10 registros nuevos.
INSERT OR ROLLBACK INTO Prestacion (id_prestacion, cantidad, realizada_en, estado, id_servicio, id_detalle_orden, id_usuario, id_episodio) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-15 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-16 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-17 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-18 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-19 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-20 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-21 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-22 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-23 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Episodio')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Prestacion'), 1, '2026-09-24 13:30:00', 'REALIZADA', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Servicio'), NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Usuario'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Episodio'));

-- 36. Cargo: 10 registros nuevos.
INSERT OR ROLLBACK INTO Cargo (id_cargo, clave_idempotencia, codigo_cargo_externo, estado_envio, creado_en, confirmado_en, ultimo_error, id_prestacion, id_sistema_externo) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-001', 'DEMO-RCM-0001', 'CONFIRMADO', '2026-09-15 17:05:00', '2026-09-15 17:06:00', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-002', 'DEMO-RCM-0002', 'CONFIRMADO', '2026-09-16 17:05:00', '2026-09-16 17:06:00', NULL, (SELECT base + 2 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-003', 'DEMO-RCM-0003', 'CONFIRMADO', '2026-09-17 17:05:00', '2026-09-17 17:06:00', NULL, (SELECT base + 3 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-004', 'DEMO-RCM-0004', 'CONFIRMADO', '2026-09-18 17:05:00', '2026-09-18 17:06:00', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-005', 'DEMO-RCM-0005', 'CONFIRMADO', '2026-09-19 17:05:00', '2026-09-19 17:06:00', NULL, (SELECT base + 5 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-006', 'DEMO-RCM-0006', 'CONFIRMADO', '2026-09-20 17:05:00', '2026-09-20 17:06:00', NULL, (SELECT base + 6 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-007', 'DEMO-RCM-0007', 'CONFIRMADO', '2026-09-21 17:05:00', '2026-09-21 17:06:00', NULL, (SELECT base + 7 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-008', 'DEMO-RCM-0008', 'CONFIRMADO', '2026-09-22 17:05:00', '2026-09-22 17:06:00', NULL, (SELECT base + 8 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-009', NULL, 'PENDIENTE', '2026-09-23 17:05:00', NULL, NULL, (SELECT base + 9 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Cargo'), 'demo-20261009-consulta-010', NULL, 'PENDIENTE', '2026-09-24 17:05:00', NULL, NULL, (SELECT base + 10 FROM _demo_base WHERE tabla = 'Prestacion'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Sistema_Externo'));

-- 37. Factura: 10 registros nuevos.
INSERT OR ROLLBACK INTO Factura (id_factura, numero, emitida_en, estado, moneda, id_paciente) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 1 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 5 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 8 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 9 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Factura'), NULL, NULL, 'BORRADOR', 'COP', (SELECT base + 10 FROM _demo_base WHERE tabla = 'Paciente'));

-- 38. Detalle_Factura: 10 registros nuevos.
INSERT OR ROLLBACK INTO Detalle_Factura (id_detalle_factura, descripcion, cantidad_milesimas, precio_unitario_centavos, id_factura, id_prestacion) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 1 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 2 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 2 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 3 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 3 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 4 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 5 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 5 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 6 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 6 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 7 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 7 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 8 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 8 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 9 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 9 FROM _demo_base WHERE tabla = 'Prestacion')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Detalle_Factura'), 'Consulta de medicina general', 1000, 9000000, (SELECT base + 10 FROM _demo_base WHERE tabla = 'Factura'), (SELECT base + 10 FROM _demo_base WHERE tabla = 'Prestacion'));

-- Emitir únicamente las diez facturas nuevas, antes de sus pagos.
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-15 17:10:00', numero='DEMO-2026-FV-001' WHERE id_factura=(SELECT base + 1 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-16 17:10:00', numero='DEMO-2026-FV-002' WHERE id_factura=(SELECT base + 2 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-17 17:10:00', numero='DEMO-2026-FV-003' WHERE id_factura=(SELECT base + 3 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-18 17:10:00', numero='DEMO-2026-FV-004' WHERE id_factura=(SELECT base + 4 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-19 17:10:00', numero='DEMO-2026-FV-005' WHERE id_factura=(SELECT base + 5 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-20 17:10:00', numero='DEMO-2026-FV-006' WHERE id_factura=(SELECT base + 6 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-21 17:10:00', numero='DEMO-2026-FV-007' WHERE id_factura=(SELECT base + 7 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-22 17:10:00', numero='DEMO-2026-FV-008' WHERE id_factura=(SELECT base + 8 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-23 17:10:00', numero='DEMO-2026-FV-009' WHERE id_factura=(SELECT base + 9 FROM _demo_base WHERE tabla = 'Factura');
UPDATE Factura SET estado='EMITIDA', emitida_en='2026-09-24 17:10:00', numero='DEMO-2026-FV-010' WHERE id_factura=(SELECT base + 10 FROM _demo_base WHERE tabla = 'Factura');

-- 39. Pago: 10 registros nuevos.
INSERT OR ROLLBACK INTO Pago (id_pago, fecha, valor_centavos, medio_pago, referencia, id_factura) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-15 17:20:00', 9000000, 'EFECTIVO', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-16 17:20:00', 9000000, 'TARJETA_DEBITO', 'DEMO-PAGO-0002', (SELECT base + 2 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-17 17:20:00', 9000000, 'TRANSFERENCIA', 'DEMO-PAGO-0003', (SELECT base + 3 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-18 17:20:00', 9000000, 'TARJETA_CREDITO', 'DEMO-PAGO-0004', (SELECT base + 4 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-19 17:20:00', 9000000, 'EFECTIVO', NULL, (SELECT base + 5 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-20 17:20:00', 9000000, 'TARJETA_DEBITO', 'DEMO-PAGO-0006', (SELECT base + 6 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-21 17:20:00', 9000000, 'TRANSFERENCIA', 'DEMO-PAGO-0007', (SELECT base + 7 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-22 17:20:00', 9000000, 'EFECTIVO', NULL, (SELECT base + 8 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-23 17:20:00', 4500000, 'TARJETA_CREDITO', 'DEMO-PAGO-0009', (SELECT base + 9 FROM _demo_base WHERE tabla = 'Factura')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Pago'), '2026-09-24 17:20:00', 4500000, 'TRANSFERENCIA', 'DEMO-PAGO-0010', (SELECT base + 10 FROM _demo_base WHERE tabla = 'Factura'));

-- 40. Evento_Auditoria: 10 registros nuevos.
INSERT OR ROLLBACK INTO Evento_Auditoria (id_evento_auditoria, actor_sistema, accion, entidad, numero_registro, ocurrido_en, motivo, detalle, resultado, id_usuario, id_paciente) VALUES
    ((SELECT base + 1 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 1 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-15 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 01; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 1 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 2 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 2 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-16 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 02; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 2 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 3 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 3 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-17 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 03; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 3 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 4 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 4 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-18 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 04; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 4 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 5 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 5 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-19 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 05; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 5 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 6 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 6 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-20 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 06; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 6 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 7 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 7 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-21 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 07; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 7 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 8 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 8 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-22 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 08; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 8 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 9 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 9 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-23 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 09; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 9 FROM _demo_base WHERE tabla = 'Paciente')),
    ((SELECT base + 10 FROM _demo_base WHERE tabla = 'Evento_Auditoria'), 'SEMILLA_DEMO_20261009', 'CREAR', 'Paciente', CAST((SELECT base + 10 FROM _demo_base WHERE tabla = 'Paciente') AS TEXT), '2026-09-24 12:40:00', 'Carga de escenario ficticio de pruebas', 'Paciente de demostración 10; sin datos personales reales.', 'EXITO', NULL, (SELECT base + 10 FROM _demo_base WHERE tabla = 'Paciente'));

-- Comprobación automática de los incrementos antes de confirmar.
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Rol) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Rol';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Permiso) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Permiso';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Especialidad) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Especialidad';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Turno) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Turno';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Sede) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Sede';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Paciente) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Paciente';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Catalogo_Diagnostico) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Catalogo_Diagnostico';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Servicio) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Servicio';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Sistema_Externo) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Sistema_Externo';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Usuario) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Usuario';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Rol_Permiso) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Rol_Permiso';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Historia_Clinica) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Historia_Clinica';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Factura) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Factura';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Usuario_Rol) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Usuario_Rol';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Usuario_Especialidad) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Usuario_Especialidad';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Alergia_Paciente) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Alergia_Paciente';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Agenda) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Agenda';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Evento_Auditoria) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Evento_Auditoria';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Antecedente) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Antecedente';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Pago) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Pago';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Cita) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Cita';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Episodio) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Episodio';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Signo_Vital) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Signo_Vital';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Nota_Clinica) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Nota_Clinica';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Orden_Medica) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Orden_Medica';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Diagnostico_Clinico) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Diagnostico_Clinico';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Analisis_IA) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Analisis_IA';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Detalle_Orden) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Detalle_Orden';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Sugerencia_IA) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Sugerencia_IA';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Prescripcion) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Prescripcion';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Resultado_Lab) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Resultado_Lab';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Estudio_Imagen) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Estudio_Imagen';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Prestacion) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Prestacion';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Revision_IA) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Revision_IA';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Valor_Resultado) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Valor_Resultado';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Episodio_Resultado_Lab) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Episodio_Resultado_Lab';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Informe_Imagen) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Informe_Imagen';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Episodio_Estudio_Imagen) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Episodio_Estudio_Imagen';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Cargo) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Cargo';
INSERT INTO _demo_guard SELECT CASE WHEN (SELECT COUNT(*) FROM Detalle_Factura) - antes = esperado THEN 1 ELSE 0 END FROM _demo_base WHERE tabla='Detalle_Factura';
INSERT INTO _demo_guard SELECT CASE WHEN EXISTS (SELECT 1 FROM pragma_foreign_key_check) THEN 0 ELSE 1 END;
COMMIT;

-- Resumen: 40 filas; nuevos = 10 salvo Detalle_Orden = 30.
SELECT 'Rol' AS tabla, (SELECT COUNT(*) FROM Rol) AS total_actual, (SELECT COUNT(*) FROM Rol) - antes AS nuevos FROM _demo_base WHERE tabla='Rol'
UNION ALL
SELECT 'Permiso' AS tabla, (SELECT COUNT(*) FROM Permiso) AS total_actual, (SELECT COUNT(*) FROM Permiso) - antes AS nuevos FROM _demo_base WHERE tabla='Permiso'
UNION ALL
SELECT 'Especialidad' AS tabla, (SELECT COUNT(*) FROM Especialidad) AS total_actual, (SELECT COUNT(*) FROM Especialidad) - antes AS nuevos FROM _demo_base WHERE tabla='Especialidad'
UNION ALL
SELECT 'Turno' AS tabla, (SELECT COUNT(*) FROM Turno) AS total_actual, (SELECT COUNT(*) FROM Turno) - antes AS nuevos FROM _demo_base WHERE tabla='Turno'
UNION ALL
SELECT 'Sede' AS tabla, (SELECT COUNT(*) FROM Sede) AS total_actual, (SELECT COUNT(*) FROM Sede) - antes AS nuevos FROM _demo_base WHERE tabla='Sede'
UNION ALL
SELECT 'Paciente' AS tabla, (SELECT COUNT(*) FROM Paciente) AS total_actual, (SELECT COUNT(*) FROM Paciente) - antes AS nuevos FROM _demo_base WHERE tabla='Paciente'
UNION ALL
SELECT 'Catalogo_Diagnostico' AS tabla, (SELECT COUNT(*) FROM Catalogo_Diagnostico) AS total_actual, (SELECT COUNT(*) FROM Catalogo_Diagnostico) - antes AS nuevos FROM _demo_base WHERE tabla='Catalogo_Diagnostico'
UNION ALL
SELECT 'Servicio' AS tabla, (SELECT COUNT(*) FROM Servicio) AS total_actual, (SELECT COUNT(*) FROM Servicio) - antes AS nuevos FROM _demo_base WHERE tabla='Servicio'
UNION ALL
SELECT 'Sistema_Externo' AS tabla, (SELECT COUNT(*) FROM Sistema_Externo) AS total_actual, (SELECT COUNT(*) FROM Sistema_Externo) - antes AS nuevos FROM _demo_base WHERE tabla='Sistema_Externo'
UNION ALL
SELECT 'Usuario' AS tabla, (SELECT COUNT(*) FROM Usuario) AS total_actual, (SELECT COUNT(*) FROM Usuario) - antes AS nuevos FROM _demo_base WHERE tabla='Usuario'
UNION ALL
SELECT 'Rol_Permiso' AS tabla, (SELECT COUNT(*) FROM Rol_Permiso) AS total_actual, (SELECT COUNT(*) FROM Rol_Permiso) - antes AS nuevos FROM _demo_base WHERE tabla='Rol_Permiso'
UNION ALL
SELECT 'Historia_Clinica' AS tabla, (SELECT COUNT(*) FROM Historia_Clinica) AS total_actual, (SELECT COUNT(*) FROM Historia_Clinica) - antes AS nuevos FROM _demo_base WHERE tabla='Historia_Clinica'
UNION ALL
SELECT 'Factura' AS tabla, (SELECT COUNT(*) FROM Factura) AS total_actual, (SELECT COUNT(*) FROM Factura) - antes AS nuevos FROM _demo_base WHERE tabla='Factura'
UNION ALL
SELECT 'Usuario_Rol' AS tabla, (SELECT COUNT(*) FROM Usuario_Rol) AS total_actual, (SELECT COUNT(*) FROM Usuario_Rol) - antes AS nuevos FROM _demo_base WHERE tabla='Usuario_Rol'
UNION ALL
SELECT 'Usuario_Especialidad' AS tabla, (SELECT COUNT(*) FROM Usuario_Especialidad) AS total_actual, (SELECT COUNT(*) FROM Usuario_Especialidad) - antes AS nuevos FROM _demo_base WHERE tabla='Usuario_Especialidad'
UNION ALL
SELECT 'Alergia_Paciente' AS tabla, (SELECT COUNT(*) FROM Alergia_Paciente) AS total_actual, (SELECT COUNT(*) FROM Alergia_Paciente) - antes AS nuevos FROM _demo_base WHERE tabla='Alergia_Paciente'
UNION ALL
SELECT 'Agenda' AS tabla, (SELECT COUNT(*) FROM Agenda) AS total_actual, (SELECT COUNT(*) FROM Agenda) - antes AS nuevos FROM _demo_base WHERE tabla='Agenda'
UNION ALL
SELECT 'Evento_Auditoria' AS tabla, (SELECT COUNT(*) FROM Evento_Auditoria) AS total_actual, (SELECT COUNT(*) FROM Evento_Auditoria) - antes AS nuevos FROM _demo_base WHERE tabla='Evento_Auditoria'
UNION ALL
SELECT 'Antecedente' AS tabla, (SELECT COUNT(*) FROM Antecedente) AS total_actual, (SELECT COUNT(*) FROM Antecedente) - antes AS nuevos FROM _demo_base WHERE tabla='Antecedente'
UNION ALL
SELECT 'Pago' AS tabla, (SELECT COUNT(*) FROM Pago) AS total_actual, (SELECT COUNT(*) FROM Pago) - antes AS nuevos FROM _demo_base WHERE tabla='Pago'
UNION ALL
SELECT 'Cita' AS tabla, (SELECT COUNT(*) FROM Cita) AS total_actual, (SELECT COUNT(*) FROM Cita) - antes AS nuevos FROM _demo_base WHERE tabla='Cita'
UNION ALL
SELECT 'Episodio' AS tabla, (SELECT COUNT(*) FROM Episodio) AS total_actual, (SELECT COUNT(*) FROM Episodio) - antes AS nuevos FROM _demo_base WHERE tabla='Episodio'
UNION ALL
SELECT 'Signo_Vital' AS tabla, (SELECT COUNT(*) FROM Signo_Vital) AS total_actual, (SELECT COUNT(*) FROM Signo_Vital) - antes AS nuevos FROM _demo_base WHERE tabla='Signo_Vital'
UNION ALL
SELECT 'Nota_Clinica' AS tabla, (SELECT COUNT(*) FROM Nota_Clinica) AS total_actual, (SELECT COUNT(*) FROM Nota_Clinica) - antes AS nuevos FROM _demo_base WHERE tabla='Nota_Clinica'
UNION ALL
SELECT 'Orden_Medica' AS tabla, (SELECT COUNT(*) FROM Orden_Medica) AS total_actual, (SELECT COUNT(*) FROM Orden_Medica) - antes AS nuevos FROM _demo_base WHERE tabla='Orden_Medica'
UNION ALL
SELECT 'Diagnostico_Clinico' AS tabla, (SELECT COUNT(*) FROM Diagnostico_Clinico) AS total_actual, (SELECT COUNT(*) FROM Diagnostico_Clinico) - antes AS nuevos FROM _demo_base WHERE tabla='Diagnostico_Clinico'
UNION ALL
SELECT 'Analisis_IA' AS tabla, (SELECT COUNT(*) FROM Analisis_IA) AS total_actual, (SELECT COUNT(*) FROM Analisis_IA) - antes AS nuevos FROM _demo_base WHERE tabla='Analisis_IA'
UNION ALL
SELECT 'Detalle_Orden' AS tabla, (SELECT COUNT(*) FROM Detalle_Orden) AS total_actual, (SELECT COUNT(*) FROM Detalle_Orden) - antes AS nuevos FROM _demo_base WHERE tabla='Detalle_Orden'
UNION ALL
SELECT 'Sugerencia_IA' AS tabla, (SELECT COUNT(*) FROM Sugerencia_IA) AS total_actual, (SELECT COUNT(*) FROM Sugerencia_IA) - antes AS nuevos FROM _demo_base WHERE tabla='Sugerencia_IA'
UNION ALL
SELECT 'Prescripcion' AS tabla, (SELECT COUNT(*) FROM Prescripcion) AS total_actual, (SELECT COUNT(*) FROM Prescripcion) - antes AS nuevos FROM _demo_base WHERE tabla='Prescripcion'
UNION ALL
SELECT 'Resultado_Lab' AS tabla, (SELECT COUNT(*) FROM Resultado_Lab) AS total_actual, (SELECT COUNT(*) FROM Resultado_Lab) - antes AS nuevos FROM _demo_base WHERE tabla='Resultado_Lab'
UNION ALL
SELECT 'Estudio_Imagen' AS tabla, (SELECT COUNT(*) FROM Estudio_Imagen) AS total_actual, (SELECT COUNT(*) FROM Estudio_Imagen) - antes AS nuevos FROM _demo_base WHERE tabla='Estudio_Imagen'
UNION ALL
SELECT 'Prestacion' AS tabla, (SELECT COUNT(*) FROM Prestacion) AS total_actual, (SELECT COUNT(*) FROM Prestacion) - antes AS nuevos FROM _demo_base WHERE tabla='Prestacion'
UNION ALL
SELECT 'Revision_IA' AS tabla, (SELECT COUNT(*) FROM Revision_IA) AS total_actual, (SELECT COUNT(*) FROM Revision_IA) - antes AS nuevos FROM _demo_base WHERE tabla='Revision_IA'
UNION ALL
SELECT 'Valor_Resultado' AS tabla, (SELECT COUNT(*) FROM Valor_Resultado) AS total_actual, (SELECT COUNT(*) FROM Valor_Resultado) - antes AS nuevos FROM _demo_base WHERE tabla='Valor_Resultado'
UNION ALL
SELECT 'Episodio_Resultado_Lab' AS tabla, (SELECT COUNT(*) FROM Episodio_Resultado_Lab) AS total_actual, (SELECT COUNT(*) FROM Episodio_Resultado_Lab) - antes AS nuevos FROM _demo_base WHERE tabla='Episodio_Resultado_Lab'
UNION ALL
SELECT 'Informe_Imagen' AS tabla, (SELECT COUNT(*) FROM Informe_Imagen) AS total_actual, (SELECT COUNT(*) FROM Informe_Imagen) - antes AS nuevos FROM _demo_base WHERE tabla='Informe_Imagen'
UNION ALL
SELECT 'Episodio_Estudio_Imagen' AS tabla, (SELECT COUNT(*) FROM Episodio_Estudio_Imagen) AS total_actual, (SELECT COUNT(*) FROM Episodio_Estudio_Imagen) - antes AS nuevos FROM _demo_base WHERE tabla='Episodio_Estudio_Imagen'
UNION ALL
SELECT 'Cargo' AS tabla, (SELECT COUNT(*) FROM Cargo) AS total_actual, (SELECT COUNT(*) FROM Cargo) - antes AS nuevos FROM _demo_base WHERE tabla='Cargo'
UNION ALL
SELECT 'Detalle_Factura' AS tabla, (SELECT COUNT(*) FROM Detalle_Factura) AS total_actual, (SELECT COUNT(*) FROM Detalle_Factura) - antes AS nuevos FROM _demo_base WHERE tabla='Detalle_Factura';

SELECT * FROM V_Resumen_Factura WHERE id_factura > (SELECT base FROM _demo_base WHERE tabla='Factura') AND id_factura <= (SELECT base+10 FROM _demo_base WHERE tabla='Factura');
PRAGMA foreign_key_check;
PRAGMA integrity_check;
DROP TRIGGER _demo_guard_fail;
DROP TABLE _demo_guard;
DROP TABLE _demo_base;
