package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.format.ResolverStyle;
import java.util.ArrayList;

public class cAgendamiento {

    // Convención para las agendas que aceptan nuevas citas.
    private static final String ESTADO_AGENDA_DISPONIBLE = "ABIERTA";

    // Cada opción conserva su identificador y su texto por separado.
    public static class Opcion {

        private final long id;
        private final String descripcion;

        public Opcion(long id, String descripcion) {
            this.id = id;
            this.descripcion = descripcion;
        }

        public long getId() {
            return id;
        }

        public String getDescripcion() {
            return descripcion;
        }

        @Override
        public String toString() {
            return descripcion;
        }
    }

    // 1. Buscar pacientes por documento o por parte de su nombre.
    public ArrayList<Opcion> buscarPacientes(String texto)
            throws SQLException {

        ArrayList<Opcion> pacientes = new ArrayList<>();

        if (texto == null || texto.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Escribe un documento o un nombre para buscar."
            );
        }

        String busqueda = texto.trim();

        String sql = "SELECT id_paciente, nombres, apellidos, "
                + "tipo_documento, numero_documento "
                + "FROM Paciente "
                + "WHERE numero_documento = ? "
                + "OR instr(lower(nombres || ' ' || apellidos), "
                + "lower(?)) > 0 "
                + "ORDER BY apellidos, nombres, id_paciente";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql)) {
            consulta.setString(1, busqueda);
            consulta.setString(2, busqueda);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    String tipo = resultado.getString("tipo_documento");
                    String numero = resultado.getString("numero_documento");

                    String documento = numero == null
                            ? "Sin documento"
                            : tipo + " " + numero;

                    String descripcion
                            = resultado.getString("nombres") + " "
                            + resultado.getString("apellidos")
                            + " — " + documento
                            + " [ID: " + resultado.getLong("id_paciente") + "]";

                    pacientes.add(new Opcion(
                            resultado.getLong("id_paciente"),
                            descripcion
                    ));
                }
            }
        }

        return pacientes;
    }

    // 2. Listar las especialidades activas.
    public ArrayList<Opcion> listarEspecialidades()
            throws SQLException {

        ArrayList<Opcion> especialidades = new ArrayList<>();

        String sql = "SELECT id_especialidad, nombre "
                + "FROM Especialidad "
                + "WHERE activo = 1 "
                + "ORDER BY nombre, id_especialidad";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql); ResultSet resultado = consulta.executeQuery()) {
            while (resultado.next()) {
                especialidades.add(new Opcion(
                        resultado.getLong("id_especialidad"),
                        resultado.getString("nombre")
                ));
            }
        }

        return especialidades;
    }

    // 3. Listar profesionales activos de una especialidad.
    public ArrayList<Opcion> listarProfesionalesPorEspecialidad(
            long idEspecialidad) throws SQLException {

        ArrayList<Opcion> profesionales = new ArrayList<>();

        String sql = "SELECT u.id_usuario, u.nombres, u.apellidos "
                + "FROM Usuario u "
                + "JOIN Usuario_Especialidad ue "
                + "ON ue.id_usuario = u.id_usuario "
                + "JOIN Especialidad e "
                + "ON e.id_especialidad = ue.id_especialidad "
                + "WHERE ue.id_especialidad = ? "
                + "AND u.activo = 1 "
                + "AND e.activo = 1 "
                + "ORDER BY u.apellidos, u.nombres, u.id_usuario";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql)) {
            consulta.setLong(1, idEspecialidad);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    String descripcion
                            = resultado.getString("nombres") + " "
                            + resultado.getString("apellidos")
                            + " [ID: " + resultado.getLong("id_usuario") + "]";

                    profesionales.add(new Opcion(
                            resultado.getLong("id_usuario"),
                            descripcion
                    ));
                }
            }
        }

        return profesionales;
    }

    // 4. Buscar agendas que puedan recibir el intervalo solicitado.
    // Las fechas recibidas deben estar expresadas en UTC.
    public ArrayList<Opcion> listarAgendasDisponibles(
            long idUsuario, String inicio, String fin)
            throws SQLException {

        ArrayList<Opcion> agendas = new ArrayList<>();

        if (inicio == null || fin == null) {
            throw new IllegalArgumentException(
                    "Debes indicar el inicio y el fin de la cita."
            );
        }

        DateTimeFormatter formato
                = DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss")
                        .withResolverStyle(ResolverStyle.STRICT);

        LocalDateTime inicioCita;
        LocalDateTime finCita;

        try {
            inicioCita = LocalDateTime.parse(inicio, formato);
            finCita = LocalDateTime.parse(fin, formato);
        } catch (java.time.format.DateTimeParseException error) {
            throw new IllegalArgumentException(
                    "Usa fechas válidas con formato AAAA-MM-DD HH:mm:ss."
            );
        }

        if (!finCita.isAfter(inicioCita)) {
            throw new IllegalArgumentException(
                    "El fin de la cita debe ser posterior al inicio."
            );
        }

        if (!inicioCita.isAfter(LocalDateTime.now(ZoneOffset.UTC))) {
            throw new IllegalArgumentException(
                    "El inicio de la cita debe estar en el futuro."
            );
        }

        String sql = "SELECT a.id_agenda, a.inicio, a.fin, "
                + "s.nombre AS nombre_sede "
                + "FROM Agenda a "
                + "JOIN Usuario u ON u.id_usuario = a.id_usuario "
                + "JOIN Sede s ON s.id_sede = a.id_sede "
                + "WHERE a.id_usuario = ? "
                + "AND u.activo = 1 "
                + "AND a.estado = ? "
                + "AND a.inicio <= ? "
                + "AND a.fin >= ? "
                + "AND NOT EXISTS ("
                + "    SELECT 1 FROM Cita c "
                + "    JOIN Agenda otra ON otra.id_agenda = c.id_agenda "
                + "    WHERE otra.id_usuario = a.id_usuario "
                + "    AND c.estado <> 'CANCELADA' "
                + "    AND c.inicio < ? "
                + "    AND c.fin > ?"
                + ") "
                + "ORDER BY a.inicio, a.id_agenda";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql)) {
            consulta.setLong(1, idUsuario);
            consulta.setString(2, ESTADO_AGENDA_DISPONIBLE);
            consulta.setString(3, inicio);
            consulta.setString(4, fin);
            consulta.setString(5, fin);
            consulta.setString(6, inicio);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    String descripcion
                            = resultado.getString("nombre_sede")
                            + " — " + resultado.getString("inicio")
                            + " a " + resultado.getString("fin")
                            + " [ID: " + resultado.getLong("id_agenda") + "]";

                    agendas.add(new Opcion(
                            resultado.getLong("id_agenda"),
                            descripcion
                    ));
                }
            }
        }

        return agendas;
    }

    // 5. Listar todos los servicios activos.
    public ArrayList<Opcion> listarServicios()
            throws SQLException {

        ArrayList<Opcion> servicios = new ArrayList<>();

        String sql = "SELECT id_servicio, codigo, nombre, tipo "
                + "FROM Servicio "
                + "WHERE activo = 1 "
                + "ORDER BY tipo, nombre, id_servicio";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql); ResultSet resultado = consulta.executeQuery()) {
            while (resultado.next()) {
                String descripcion
                        = resultado.getString("codigo") + " — "
                        + resultado.getString("nombre")
                        + " (" + resultado.getString("tipo") + ")"
                        + " [ID: " + resultado.getLong("id_servicio") + "]";

                servicios.add(new Opcion(
                        resultado.getLong("id_servicio"),
                        descripcion
                ));
            }
        }

        return servicios;
    }
    // Comprueba las fechas antes de guardar.
// Recibe las fechas ya convertidas a UTC.

    private void validarHorario(String inicio, String fin) {

        if (inicio == null || fin == null) {
            throw new IllegalArgumentException(
                    "Debes indicar la fecha y las horas de la cita."
            );
        }

        DateTimeFormatter formato = DateTimeFormatter
                .ofPattern("uuuu-MM-dd HH:mm:ss")
                .withResolverStyle(ResolverStyle.STRICT);

        LocalDateTime fechaInicio;
        LocalDateTime fechaFin;

        try {
            fechaInicio = LocalDateTime.parse(inicio, formato);
            fechaFin = LocalDateTime.parse(fin, formato);

        } catch (java.time.format.DateTimeParseException error) {
            throw new IllegalArgumentException(
                    "La fecha o las horas de la cita no son válidas."
            );
        }

        if (!fechaFin.isAfter(fechaInicio)) {
            throw new IllegalArgumentException(
                    "La hora final debe ser posterior a la hora inicial."
            );
        }

        if (!fechaInicio.isAfter(LocalDateTime.now(ZoneOffset.UTC))) {
            throw new IllegalArgumentException(
                    "La cita debe comenzar en una fecha y hora futuras."
            );
        }
    }

// Ejecuta una consulta y responde si encontró algún registro.
// Los valores se colocan en los signos ? de la consulta.
    private boolean existe(
            Connection conexion,
            String sql,
            Object... valores) throws SQLException {

        try (PreparedStatement consulta = conexion.prepareStatement(sql)) {

            for (int i = 0; i < valores.length; i++) {
                consulta.setObject(i + 1, valores[i]);
            }

            try (ResultSet resultado = consulta.executeQuery()) {
                return resultado.next();
            }
        }
    }

// Valida y guarda una nueva cita.
// Devuelve el identificador que SQLite asignó a la cita.
    public long guardarCita(
            long idPaciente,
            long idEspecialidad,
            long idProfesional,
            long idServicio,
            long idAgenda,
            String inicioUTC,
            String finUTC) throws SQLException {

        return guardarOReprogramar(null, idPaciente, idEspecialidad,
                idProfesional, idServicio, idAgenda, inicioUTC, finUTC);
    }

    public long reprogramarCita(DatosCita original, long idEspecialidad,
            long idProfesional, long idServicio, long idAgenda,
            String inicioUTC, String finUTC) throws SQLException {
        if (original == null) throw new IllegalArgumentException("Selecciona la cita.");
        return guardarOReprogramar(original, original.idPaciente, idEspecialidad,
                idProfesional, idServicio, idAgenda, inicioUTC, finUTC);
    }

    private long guardarOReprogramar(DatosCita original, long idPaciente,
            long idEspecialidad, long idProfesional, long idServicio,
            long idAgenda, String inicioUTC, String finUTC) throws SQLException {
        long excluir = original == null ? 0 : original.idCita;
        validarHorario(inicioUTC, finUTC);

        if (idPaciente <= 0 || idEspecialidad <= 0
                || idProfesional <= 0 || idServicio <= 0
                || idAgenda <= 0) {

            throw new IllegalArgumentException(
                    "Selecciona paciente, especialidad, profesional, "
                    + "servicio y agenda."
            );
        }

        try (Connection conexion = new cConexion().conectar()) {

            // Las comprobaciones y el guardado pertenecen a una misma operación.
            conexion.setAutoCommit(false);

            try {
                if (original != null) {
                    DatosCita actual = obtenerCita(conexion, original.idCita);
                    validarEditable(conexion, actual);
                    if (actual.idPaciente != original.idPaciente
                            || actual.idAgenda != original.idAgenda
                            || actual.idEspecialidad != original.idEspecialidad
                            || actual.idServicio != original.idServicio
                            || !actual.inicioUTC.equals(original.inicioUTC)
                            || !actual.finUTC.equals(original.finUTC)) {
                        throw new IllegalArgumentException(
                                "La cita cambió en otra ventana. Cierra el diálogo y vuelve a seleccionarla.");
                    }
                }
                cDisponibilidad.validarServicio(
                        conexion,
                        idEspecialidad,
                        idServicio,
                        inicioUTC,
                        finUTC
                );
                // 1. Confirmar que el paciente todavía existe.
                boolean pacienteExiste = existe(
                        conexion,
                        "SELECT 1 FROM Paciente WHERE id_paciente = ?",
                        idPaciente
                );

                if (!pacienteExiste) {
                    throw new IllegalArgumentException(
                            "El paciente seleccionado ya no está disponible."
                    );
                }

                // 2. Confirmar que el servicio está activo.
                boolean servicioDisponible = existe(
                        conexion,
                        "SELECT 1 FROM Servicio "
                        + "WHERE id_servicio = ? AND activo = 1",
                        idServicio
                );

                if (!servicioDisponible) {
                    throw new IllegalArgumentException(
                            "El servicio seleccionado no está activo."
                    );
                }

                // 3. Confirmar agenda, profesional, especialidad y horario.
                String sqlAgenda
                        = "SELECT 1 FROM Agenda a "
                        + "JOIN Usuario u ON u.id_usuario = a.id_usuario "
                        + "JOIN Usuario_Especialidad ue "
                        + "ON ue.id_usuario = u.id_usuario "
                        + "JOIN Especialidad e "
                        + "ON e.id_especialidad = ue.id_especialidad "
                        + "WHERE a.id_agenda = ? "
                        + "AND a.id_usuario = ? "
                        + "AND ue.id_especialidad = ? "
                        + "AND a.estado = ? "
                        + "AND u.activo = 1 "
                        + "AND e.activo = 1 "
                        + "AND a.inicio <= ? "
                        + "AND a.fin >= ?";

                boolean agendaDisponible = existe(
                        conexion,
                        sqlAgenda,
                        idAgenda,
                        idProfesional,
                        idEspecialidad,
                        ESTADO_AGENDA_DISPONIBLE,
                        inicioUTC,
                        finUTC
                );

                if (!agendaDisponible) {
                    throw new IllegalArgumentException(
                            "La agenda ya no está disponible para ese horario "
                            + "o no corresponde al profesional y especialidad."
                    );
                }

                // 4. Revisar cruces del médico, incluso entre agendas distintas.
                String sqlCruceMedico
                        = "SELECT 1 FROM Cita c "
                        + "JOIN Agenda a ON a.id_agenda = c.id_agenda "
                        + "WHERE a.id_usuario = ? "
                        + "AND c.estado <> 'CANCELADA' AND c.id_cita <> ? "
                        + "AND c.inicio < ? "
                        + "AND c.fin > ?";

                boolean medicoOcupado = existe(
                        conexion,
                        sqlCruceMedico,
                        idProfesional,
                        excluir,
                        finUTC,
                        inicioUTC
                );

                if (medicoOcupado) {
                    throw new IllegalArgumentException(
                            "El médico ya tiene otra cita en ese horario. "
                            + "Consulta nuevamente las agendas."
                    );
                }

                // 5. Revisar cruces del paciente, aunque sea con otro médico.
                String sqlCrucePaciente
                        = "SELECT 1 FROM Cita "
                        + "WHERE id_paciente = ? "
                        + "AND estado <> 'CANCELADA' AND id_cita <> ? "
                        + "AND inicio < ? "
                        + "AND fin > ?";

                boolean pacienteOcupado = existe(
                        conexion,
                        sqlCrucePaciente,
                        idPaciente,
                        excluir,
                        finUTC,
                        inicioUTC
                );

                if (pacienteOcupado) {
                    throw new IllegalArgumentException(
                            "El paciente ya tiene otra cita en ese horario."
                    );
                }

                // Reprogramar conserva el identificador, el paciente y la prioridad.
                if (original != null) {
                    String sql = "UPDATE Cita SET inicio=?, fin=?, id_agenda=?, "
                            + "id_especialidad=?, id_servicio=? WHERE id_cita=? "
                            + "AND estado='PENDIENTE' AND NOT EXISTS "
                            + "(SELECT 1 FROM Episodio e WHERE e.id_cita=Cita.id_cita)";
                    try (PreparedStatement ps = conexion.prepareStatement(sql)) {
                        ps.setString(1, inicioUTC); ps.setString(2, finUTC);
                        ps.setLong(3, idAgenda); ps.setLong(4, idEspecialidad);
                        ps.setLong(5, idServicio); ps.setLong(6, original.idCita);
                        if (ps.executeUpdate() != 1) throw new SQLException(
                                "La cita ya no se puede reprogramar. Actualiza la lista.");
                    }
                    conexion.commit();
                    return original.idCita;
                }
                // 6. Guardar la cita después de superar las comprobaciones.
                String sqlInsertar
                        = "INSERT INTO Cita "
                        + "(inicio, fin, estado, prioridad, "
                        + "id_paciente, id_agenda, id_especialidad, id_servicio) "
                        + "VALUES (?, ?, 'PENDIENTE', 'NORMAL', ?, ?, ?, ?)";

                try (PreparedStatement consulta
                        = conexion.prepareStatement(sqlInsertar)) {

                    consulta.setString(1, inicioUTC);
                    consulta.setString(2, finUTC);
                    consulta.setLong(3, idPaciente);
                    consulta.setLong(4, idAgenda);
                    consulta.setLong(5, idEspecialidad);
                    consulta.setLong(6, idServicio);

                    consulta.executeUpdate();
                }

                // 7. Recuperar el identificador en la misma conexión.
                long idCita;

                try (
                        PreparedStatement consulta = conexion.prepareStatement(
                                "SELECT last_insert_rowid()"
                        ); ResultSet resultado = consulta.executeQuery()) {
                            if (!resultado.next()) {
                                throw new SQLException(
                                        "No se pudo recuperar el identificador de la cita."
                                );
                            }

                            idCita = resultado.getLong(1);
                        }

                        // 8. Confirmar el guardado.
                        conexion.commit();

                        return idCita;

            } catch (SQLException | RuntimeException error) {

                // Si algo falla, deshacer la operación.
                try {
                    conexion.rollback();
                } catch (SQLException errorRollback) {
                    error.addSuppressed(errorRollback);
                }

                // SQLite puede estar ocupado por otra operación.
                if (error instanceof SQLException errorSQL) {
                    int codigo = errorSQL.getErrorCode() & 0xFF;

                    if (codigo == 5 || codigo == 6) {
                        throw new SQLException(
                                "La base de datos está ocupada por otra operación. "
                                + "Vuelve a consultar las agendas e intenta guardar.",
                                error
                        );
                    }
                }

                throw error;
            }
        }
    }
// Consulta las citas guardadas.
// Convierte el inicio de UTC a la hora de Colombia para mostrarlo.

    public ArrayList<Object[]> listarCitas() throws SQLException {

        ArrayList<Object[]> filas = new ArrayList<>();

        String sql
                = "SELECT c.id_cita, c.inicio, c.estado, "
                + "p.nombres || ' ' || p.apellidos AS paciente, "
                + "p.numero_documento, "
                + "u.nombres || ' ' || u.apellidos AS medico, "
                + "e.nombre AS especialidad, "
                + "u.id_usuario AS id_medico, "
                + "e.id_especialidad "
                + "FROM Cita c "
                + "JOIN Paciente p ON p.id_paciente = c.id_paciente "
                + "JOIN Agenda a ON a.id_agenda = c.id_agenda "
                + "JOIN Usuario u ON u.id_usuario = a.id_usuario "
                + "JOIN Especialidad e "
                + "ON e.id_especialidad = c.id_especialidad "
                + "ORDER BY c.inicio, c.id_cita";

        DateTimeFormatter formatoBD
                = DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss");

        DateTimeFormatter formatoHora
                = DateTimeFormatter.ofPattern("HH:mm");

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql); ResultSet resultado = consulta.executeQuery()) {
            while (resultado.next()) {

                java.time.ZonedDateTime inicioColombia
                        = LocalDateTime.parse(
                                resultado.getString("inicio"),
                                formatoBD
                        )
                                .atZone(ZoneOffset.UTC)
                                .withZoneSameInstant(
                                        java.time.ZoneId.of("America/Bogota")
                                );

                filas.add(new Object[]{
                    resultado.getLong("id_cita"),
                    inicioColombia.toLocalDate().toString(),
                    inicioColombia.format(formatoHora),
                    resultado.getString("paciente"),
                    resultado.getString("numero_documento"),
                    resultado.getString("medico"),
                    resultado.getString("especialidad"),
                    resultado.getString("estado"),
                    resultado.getLong("id_medico"),
                    resultado.getLong("id_especialidad")
                });
            }
        }

        return filas;
    }

    public static class DatosCita {
        public long idCita, idPaciente, idAgenda, idEspecialidad, idServicio, idMedico;
        public String paciente, documento, estado, inicioUTC, finUTC;
    }

    private DatosCita obtenerCita(Connection con, long idCita) throws SQLException {
        String sql = "SELECT c.*, a.id_usuario, p.nombres || ' ' || p.apellidos AS paciente, "
                + "p.numero_documento FROM Cita c JOIN Agenda a ON a.id_agenda=c.id_agenda "
                + "JOIN Paciente p ON p.id_paciente=c.id_paciente WHERE c.id_cita=?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, idCita);
            try (ResultSet r = ps.executeQuery()) {
                if (!r.next()) throw new IllegalArgumentException("La cita ya no existe.");
                DatosCita d = new DatosCita();
                d.idCita=r.getLong("id_cita"); d.idPaciente=r.getLong("id_paciente");
                d.idAgenda=r.getLong("id_agenda"); d.idEspecialidad=r.getLong("id_especialidad");
                d.idServicio=r.getLong("id_servicio"); d.idMedico=r.getLong("id_usuario");
                d.paciente=r.getString("paciente"); d.documento=r.getString("numero_documento");
                d.estado=r.getString("estado"); d.inicioUTC=r.getString("inicio"); d.finUTC=r.getString("fin");
                return d;
            }
        }
    }

    private void validarEditable(Connection con, DatosCita d) throws SQLException {
        if (!"PENDIENTE".equals(d.estado)) throw new IllegalArgumentException(
                "Solo se pueden modificar citas PENDIENTES.");
        if (existe(con, "SELECT 1 FROM Episodio WHERE id_cita=?", d.idCita)) {
            throw new IllegalArgumentException("Esta cita ya tiene un episodio. No se puede cancelar ni reprogramar.");
        }
    }

    public DatosCita obtenerCitaParaReprogramar(long idCita) throws SQLException {
        try (Connection con = new cConexion().conectar()) {
            DatosCita d = obtenerCita(con, idCita);
            validarEditable(con, d);
            return d;
        }
    }

    public void cancelarCita(long idCita, String motivo) throws SQLException {
        if (motivo == null || motivo.isBlank()) throw new IllegalArgumentException(
                "Escribe el motivo de cancelación.");
        // Una sola sentencia: comprobar y cambiar son una operación indivisible.
        String sql = "UPDATE Cita SET estado='CANCELADA', motivo_cancelacion=? "
                + "WHERE id_cita=? AND estado='PENDIENTE' AND NOT EXISTS "
                + "(SELECT 1 FROM Episodio e WHERE e.id_cita=Cita.id_cita)";
        try (Connection con = new cConexion().conectar(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, motivo.trim()); ps.setLong(2, idCita);
            if (ps.executeUpdate() != 1) throw new IllegalArgumentException(
                    "No se canceló: la cita ya cambió de estado o tiene una atención iniciada. Actualiza la lista.");
        }
    }

}
