
package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class cInicio 
{
    private boolean esRolMedico(String rol) {
        if (rol == null) return false;
        String r = rol.trim().toLowerCase();
        return r.equals("medico") || r.equals("médico");
    }

    /**
     * Retorna un arreglo de 3 posiciones:
     * [0] = Citas del día (no canceladas)
     * [1] = Citas pendientes del día
     * [2] = Episodios clínicos abiertos
     */
    public int[] obtenerContadoresDashboard(long idUsuario, String rol) {
        int[] contadores = new int[]{0, 0, 0};
        boolean filtrarMedico = esRolMedico(rol);
        String filtroMedico = filtrarMedico ? " AND a.id_usuario = ? " : "";

        String sqlCitas = "SELECT "
                + "COUNT(*) AS total_dia, "
                + "COALESCE(SUM(CASE WHEN UPPER(c.estado) = 'PENDIENTE' THEN 1 ELSE 0 END), 0) AS pendientes "
                + "FROM Cita c "
                + "JOIN Agenda a ON c.id_agenda = a.id_agenda "
                + "WHERE DATE(c.inicio) = DATE('now', 'localtime') "
                + "AND UPPER(c.estado) <> 'CANCELADA' " + filtroMedico;

        String sqlEpisodios = "SELECT COUNT(*) AS abiertos FROM Episodio WHERE UPPER(estado) = 'ABIERTO'";

        try (Connection conn = new cConexion().conectar()) {
            try (PreparedStatement ps = conn.prepareStatement(sqlCitas)) {
                if (filtrarMedico) {
                    ps.setLong(1, idUsuario);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        contadores[0] = rs.getInt("total_dia");
                        contadores[1] = rs.getInt("pendientes");
                    }
                }
            }

            try (PreparedStatement psEp = conn.prepareStatement(sqlEpisodios);
                 ResultSet rsEp = psEp.executeQuery()) {
                if (rsEp.next()) {
                    contadores[2] = rsEp.getInt("abiertos");
                }
            }
        } catch (SQLException e) {
            System.err.println("Error al consultar contadores de inicio: " + e.getMessage());
        }

        return contadores;
    }

    /**
     * Retorna las filas para la tabla Citas del día:
     * {Hora, Paciente, Cédula, Motivo, Estado}
     */
    public List<Object[]> obtenerCitasDelDia(long idUsuario, String rol) {
        List<Object[]> lista = new ArrayList<>();
        boolean filtrarMedico = esRolMedico(rol);
        String filtroMedico = filtrarMedico ? " AND a.id_usuario = ? " : "";

        String sql = "SELECT SUBSTR(c.inicio, 12, 5) AS hora, "
                + "p.nombres || ' ' || p.apellidos AS paciente, "
                + "p.numero_documento AS cedula, "
                + "s.nombre AS motivo, "
                + "c.estado "
                + "FROM Cita c "
                + "JOIN Paciente p ON c.id_paciente = p.id_paciente "
                + "JOIN Servicio s ON c.id_servicio = s.id_servicio "
                + "JOIN Agenda a ON c.id_agenda = a.id_agenda "
                + "WHERE DATE(c.inicio) = DATE('now', 'localtime') " + filtroMedico
                + "ORDER BY c.inicio ASC";

        try (Connection conn = new cConexion().conectar();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (filtrarMedico) {
                ps.setLong(1, idUsuario);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lista.add(new Object[]{
                        rs.getString("hora"),
                        rs.getString("paciente"),
                        rs.getString("cedula"),
                        rs.getString("motivo"),
                        rs.getString("estado")
                    });
                }
            }
        } catch (SQLException e) {
            System.err.println("Error al consultar citas del día: " + e.getMessage());
        }

        return lista;
    }
}
