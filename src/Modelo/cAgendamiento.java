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
            Connection conexion = new cConexion().conectar();
            PreparedStatement consulta = conexion.prepareStatement(sql)
        ) {
            consulta.setString(1, busqueda);
            consulta.setString(2, busqueda);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    String tipo = resultado.getString("tipo_documento");
                    String numero = resultado.getString("numero_documento");

                    String documento = numero == null
                            ? "Sin documento"
                            : tipo + " " + numero;

                    String descripcion =
                            resultado.getString("nombres") + " "
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
            Connection conexion = new cConexion().conectar();
            PreparedStatement consulta = conexion.prepareStatement(sql);
            ResultSet resultado = consulta.executeQuery()
        ) {
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
            Connection conexion = new cConexion().conectar();
            PreparedStatement consulta = conexion.prepareStatement(sql)
        ) {
            consulta.setLong(1, idEspecialidad);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    String descripcion =
                            resultado.getString("nombres") + " "
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

        DateTimeFormatter formato =
                DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss")
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
            Connection conexion = new cConexion().conectar();
            PreparedStatement consulta = conexion.prepareStatement(sql)
        ) {
            consulta.setLong(1, idUsuario);
            consulta.setString(2, ESTADO_AGENDA_DISPONIBLE);
            consulta.setString(3, inicio);
            consulta.setString(4, fin);
            consulta.setString(5, fin);
            consulta.setString(6, inicio);

            try (ResultSet resultado = consulta.executeQuery()) {
                while (resultado.next()) {
                    String descripcion =
                            resultado.getString("nombre_sede")
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
            Connection conexion = new cConexion().conectar();
            PreparedStatement consulta = conexion.prepareStatement(sql);
            ResultSet resultado = consulta.executeQuery()
        ) {
            while (resultado.next()) {
                String descripcion =
                        resultado.getString("codigo") + " — "
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
}