package Modelo;

import Conexion.cConexion;
import java.sql.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

/** Consulta servicios habilitados y calcula horarios. No crea citas. */
public class cDisponibilidad {
    public static final ZoneId ZONA = ZoneId.of("America/Bogota");
    public static final DateTimeFormatter FORMATO_BD =
            DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss");
    // Se ofrecen inicios cada 5 minutos; la duración viene del servicio.
    private static final int PASO_MINUTOS = 5;

    public static class Horario {
        public final long idAgenda;
        public final String sede, inicioUTC, finUTC;
        public final int duracion;

        public Horario(long idAgenda, String sede, LocalDateTime inicio,
                LocalDateTime fin, int duracion) {
            this.idAgenda = idAgenda;
            this.sede = sede;
            this.inicioUTC = inicio.format(FORMATO_BD);
            this.finUTC = fin.format(FORMATO_BD);
            this.duracion = duracion;
        }
        public ZonedDateTime inicioLocal() {
            return LocalDateTime.parse(inicioUTC, FORMATO_BD)
                    .atZone(ZoneOffset.UTC).withZoneSameInstant(ZONA);
        }
        public ZonedDateTime finLocal() {
            return LocalDateTime.parse(finUTC, FORMATO_BD)
                    .atZone(ZoneOffset.UTC).withZoneSameInstant(ZONA);
        }
    }

    private static class Intervalo {
        final LocalDateTime inicio, fin;
        Intervalo(String inicio, String fin) {
            this.inicio = LocalDateTime.parse(inicio, FORMATO_BD);
            this.fin = LocalDateTime.parse(fin, FORMATO_BD);
        }
    }

    public ArrayList<cAgendamiento.Opcion> listarServicios(long idEspecialidad)
            throws SQLException {
        ArrayList<cAgendamiento.Opcion> opciones = new ArrayList<>();
        String sql = "SELECT s.id_servicio, s.nombre, s.duracion_minutos "
                + "FROM Servicio s JOIN Servicio_Especialidad se "
                + "ON se.id_servicio = s.id_servicio "
                + "JOIN Especialidad e ON e.id_especialidad = se.id_especialidad "
                + "WHERE se.id_especialidad = ? AND s.activo = 1 "
                + "AND e.activo = 1 AND s.duracion_minutos > 0 "
                + "AND upper(trim(s.tipo)) <> 'MEDICAMENTO' ORDER BY s.nombre";
        try (Connection c = new cConexion().conectar();
                PreparedStatement p = c.prepareStatement(sql)) {
            p.setLong(1, idEspecialidad);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) {
                    opciones.add(new cAgendamiento.Opcion(r.getLong(1),
                            r.getString(2) + " (" + r.getInt(3) + " min)"));
                }
            }
        }
        return opciones;
    }

    private static int duracionServicio(Connection c, long idEspecialidad,
            long idServicio) throws SQLException {
        String sql = "SELECT s.duracion_minutos FROM Servicio s "
                + "JOIN Servicio_Especialidad se ON se.id_servicio = s.id_servicio "
                + "JOIN Especialidad e ON e.id_especialidad = se.id_especialidad "
                + "WHERE s.id_servicio = ? AND se.id_especialidad = ? "
                + "AND s.activo = 1 AND e.activo = 1 "
                + "AND s.duracion_minutos > 0 "
                + "AND upper(trim(s.tipo)) <> 'MEDICAMENTO'";
        try (PreparedStatement p = c.prepareStatement(sql)) {
            p.setLong(1, idServicio);
            p.setLong(2, idEspecialidad);
            try (ResultSet r = p.executeQuery()) {
                if (!r.next()) {
                    throw new IllegalArgumentException(
                            "El servicio no está habilitado para la especialidad "
                            + "o no tiene una duración válida.");
                }
                return r.getInt(1);
            }
        }
    }

    // Llamar dentro de la transacción de guardarCita(), antes del INSERT.
    public static void validarServicio(Connection c, long idEspecialidad,
            long idServicio, String inicioUTC, String finUTC) throws SQLException {
        int minutos = duracionServicio(c, idEspecialidad, idServicio);
        Duration intervalo = Duration.between(
                LocalDateTime.parse(inicioUTC, FORMATO_BD),
                LocalDateTime.parse(finUTC, FORMATO_BD));
        if (!intervalo.equals(Duration.ofMinutes(minutos))) {
            throw new IllegalArgumentException(
                    "La duración del servicio cambió. Selecciona nuevamente el horario.");
        }
    }

    /** Devuelve los días del mes que tienen al menos un horario libre. */
    public Map<LocalDate, List<Horario>> listarMes(long idPaciente,
            long idMedico, long idEspecialidad, long idServicio, YearMonth mes)
            throws SQLException {
        return listarMes(idPaciente, idMedico, idEspecialidad, idServicio, mes, 0);
    }

    public Map<LocalDate, List<Horario>> listarMes(long idPaciente,
            long idMedico, long idEspecialidad, long idServicio, YearMonth mes,
            long idCitaExcluir) throws SQLException {
        Map<LocalDate, List<Horario>> dias = new TreeMap<>();
        LocalDateTime desde = mes.atDay(1).atStartOfDay(ZONA)
                .withZoneSameInstant(ZoneOffset.UTC).toLocalDateTime();
        LocalDateTime hasta = mes.plusMonths(1).atDay(1).atStartOfDay(ZONA)
                .withZoneSameInstant(ZoneOffset.UTC).toLocalDateTime();
        LocalDateTime ahora = LocalDateTime.now(ZoneOffset.UTC);

        try (Connection c = new cConexion().conectar()) {
            // Una misma lectura de la base para duración, ocupaciones y agendas.
            c.setAutoCommit(false);
            try {
                int minutos = duracionServicio(c, idEspecialidad, idServicio);
                ArrayList<Intervalo> ocupados = new ArrayList<>();
                String sqlOcupados = "SELECT c.inicio, c.fin FROM Cita c "
                        + "JOIN Agenda a ON a.id_agenda = c.id_agenda "
                        + "WHERE c.estado <> 'CANCELADA' "
                        + "AND (a.id_usuario = ? OR c.id_paciente = ?) "
                        + "AND c.inicio < ? AND c.fin > ? AND c.id_cita <> ?";
                try (PreparedStatement p = c.prepareStatement(sqlOcupados)) {
                    p.setLong(1, idMedico);
                    p.setLong(2, idPaciente);
                    p.setString(3, hasta.plusMinutes(minutos).format(FORMATO_BD));
                    p.setString(4, desde.format(FORMATO_BD));
                    p.setLong(5, idCitaExcluir);
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) ocupados.add(new Intervalo(r.getString(1), r.getString(2)));
                    }
                }
                String sqlAgendas = "SELECT a.id_agenda, a.inicio, a.fin, s.nombre "
                        + "FROM Agenda a JOIN Sede s ON s.id_sede = a.id_sede "
                        + "JOIN Usuario u ON u.id_usuario = a.id_usuario "
                        + "WHERE a.id_usuario = ? AND u.activo = 1 "
                        + "AND a.estado = 'ABIERTA' AND a.inicio < ? AND a.fin > ? "
                        + "AND EXISTS (SELECT 1 FROM Usuario_Especialidad ue "
                        + "WHERE ue.id_usuario = a.id_usuario AND ue.id_especialidad = ?) "
                        + "ORDER BY a.inicio, a.id_agenda";
                try (PreparedStatement p = c.prepareStatement(sqlAgendas)) {
                    p.setLong(1, idMedico);
                    p.setString(2, hasta.format(FORMATO_BD));
                    p.setString(3, desde.format(FORMATO_BD));
                    p.setLong(4, idEspecialidad);
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) {
                            LocalDateTime inicioAgenda = LocalDateTime.parse(r.getString(2), FORMATO_BD);
                            LocalDateTime finAgenda = LocalDateTime.parse(r.getString(3), FORMATO_BD);
                            LocalDateTime limite = desde.isAfter(ahora) ? desde : ahora;
                            LocalDateTime inicio = inicioAgenda;
                            if (inicio.isBefore(limite)) {
                                long segundos = Duration.between(inicio, limite).getSeconds();
                                long saltos = (segundos + PASO_MINUTOS * 60 - 1) / (PASO_MINUTOS * 60);
                                inicio = inicio.plusMinutes(saltos * PASO_MINUTOS);
                            }
                            while (inicio.isBefore(hasta)
                                    && !inicio.plusMinutes(minutos).isAfter(finAgenda)) {
                                LocalDateTime fin = inicio.plusMinutes(minutos);
                                boolean libre = inicio.isAfter(ahora);
                                for (Intervalo ocupado : ocupados) {
                                    if (inicio.isBefore(ocupado.fin) && fin.isAfter(ocupado.inicio)) {
                                        libre = false;
                                        break;
                                    }
                                }
                                // La consulta también cubre el final de una cita que cruce de mes.
                                if (libre) {
                                    Horario h = new Horario(r.getLong(1), r.getString(4), inicio, fin, minutos);
                                    dias.computeIfAbsent(h.inicioLocal().toLocalDate(),
                                            clave -> new ArrayList<>()).add(h);
                                }
                                inicio = inicio.plusMinutes(PASO_MINUTOS);
                            }
                        }
                    }
                }
                for (List<Horario> horarios : dias.values()) {
                    horarios.sort(Comparator.comparing(h -> h.inicioUTC));
                }
                c.commit();
            } catch (SQLException | RuntimeException error) {
                try { c.rollback(); } catch (SQLException otro) { error.addSuppressed(otro); }
                throw error;
            }
        }
        return dias;
    }
}
