package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.swing.JOptionPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;

public class cHistoriaClinica {

    public cHistoriaClinica() {
        // Constructor vacío como en cPaciente
    }

    // 1. Clase interna para agrupar los resultados de la búsqueda y enviarlos a la vista.
    public static class DatosPaciente {

        public long idPaciente;
        public long idHistoriaClinica;
        public String nombreCompleto;
        public String numeroDocumento;
        public String celular;
        public String fechaNacimiento;
        public String grupoSanguineo;
        public String factorRh;
        public String alergias; // A llenar posteriormente
    }

    //Método principal para buscar al paciente por su número de cédula
    public DatosPaciente buscarPacienteParaAtencion(String numeroDocumento) throws SQLException {

        if (numeroDocumento == null || numeroDocumento.trim().isEmpty()) {
            throw new IllegalArgumentException("Debes escribir el número de documento.");
        }

        DatosPaciente datos = null;

        String sql = "SELECT p.id_paciente, p.nombres, p.apellidos, p.numero_documento, "
                + "p.telefono, p.fecha_nacimiento, p.grupo_sanguineo, p.factor_rh, "
                + "hc.id_historia_clinica "
                + "FROM Paciente p "
                + "LEFT JOIN Historia_Clinica hc ON p.id_paciente = hc.id_paciente "
                + "WHERE p.numero_documento = ?";

        // Abrimos la conexión
        try (Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql)) {

            consulta.setString(1, numeroDocumento.trim());

            try (ResultSet resultado = consulta.executeQuery()) {
                if (resultado.next()) {
                    datos = new DatosPaciente();
                    datos.idPaciente = resultado.getLong("id_paciente");

                    // Concatenamos nombres y apellidos
                    String nombres = resultado.getString("nombres");
                    String apellidos = resultado.getString("apellidos");
                    datos.nombreCompleto = (nombres != null ? nombres : "") + " " + (apellidos != null ? apellidos : "");

                    datos.numeroDocumento = resultado.getString("numero_documento");
                    datos.celular = resultado.getString("telefono");
                    datos.fechaNacimiento = resultado.getString("fecha_nacimiento");
                    datos.grupoSanguineo = resultado.getString("grupo_sanguineo");
                    datos.factorRh = resultado.getString("factor_rh");

                    // Manejo del ID de la Historia Clínica
                    datos.idHistoriaClinica = resultado.getLong("id_historia_clinica");
                    String sqlAlergias = "SELECT sustancia FROM Alergia_Paciente WHERE id_historia_clinica = ? AND estado = 'Confirmada'";
                    StringBuilder alergiasConcatenadas = new StringBuilder();

                    try (PreparedStatement consultaAlergias = conexion.prepareStatement(sqlAlergias)) {

                        consultaAlergias.setLong(1, datos.idHistoriaClinica);

                        try (ResultSet rsAlergias = consultaAlergias.executeQuery()) {
                            while (rsAlergias.next()) {
                                if (alergiasConcatenadas.length() > 0) {
                                    alergiasConcatenadas.append(", "); // Separador
                                }
                                alergiasConcatenadas.append(rsAlergias.getString("sustancia"));
                            }
                        }
                    }

                    // Si no se encontraron alergias confirmadas, mostrar un texto por defecto
                    if (alergiasConcatenadas.length() == 0) {
                        datos.alergias = "Ninguna confirmada";
                    } else {
                        datos.alergias = alergiasConcatenadas.toString();
                    }
                    // ---------------------------------------------------------
                }
            }
        } // AQUÍ SE CIERRA LA CONEXIÓN, DESPUÉS DE HABER HECHO AMBAS CONSULTAS

        return datos;
    }

    public Long buscarCitaPendiente(long idPaciente) throws java.sql.SQLException {
        String sql = "SELECT id_cita FROM Cita WHERE id_paciente = ? AND estado = 'PENDIENTE' LIMIT 1";
        try (java.sql.Connection con = new cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, idPaciente);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id_cita");
                }
            }
        }
        return null; // Retorna null si no hay cita pendiente
    }

    public long obtenerOCrearEpisodio(long idHistoriaClinica, long idSede,
            Long idCita, String tipoAtencion, String motivoConsulta) throws SQLException {
        try (Connection con = new cConexion().conectar()) {
            con.setAutoCommit(false);
            try {
                long id = obtenerOCrearEpisodio(con, idHistoriaClinica, idSede,
                        idCita, tipoAtencion, motivoConsulta);
                con.commit();
                return id;
            } catch (SQLException | RuntimeException error) {
                try {
                    con.rollback();
                } catch (SQLException otro) {
                    error.addSuppressed(otro);
                }
                throw error;
            }
        }
    }

    // La sobrecarga usa la misma conexión y transacción de quien abre la atención.
    private long obtenerOCrearEpisodio(Connection con, long idHistoriaClinica,
            long idSede, Long idCita, String tipoAtencion, String motivoConsulta) throws SQLException {
        if (idHistoriaClinica <= 0 || idSede <= 0) {
            throw new IllegalArgumentException(
                    "El paciente necesita historia clínica y una sede válida.");
        }
        if (idCita != null) {
            // Reserva el acceso de escritura y valida la relación antes de crear el episodio.
            String bloqueo = "UPDATE Cita SET estado=estado WHERE id_cita=? AND estado='PENDIENTE' "
                    + "AND EXISTS (SELECT 1 FROM Historia_Clinica h WHERE "
                    + "h.id_historia_clinica=? AND h.id_paciente=Cita.id_paciente) "
                    + "AND EXISTS (SELECT 1 FROM Agenda a WHERE a.id_agenda=Cita.id_agenda AND a.id_sede=?)";
            try (PreparedStatement ps = con.prepareStatement(bloqueo)) {
                ps.setLong(1, idCita);
                ps.setLong(2, idHistoriaClinica);
                ps.setLong(3, idSede);
                if (ps.executeUpdate() != 1) {
                    throw new IllegalArgumentException(
                            "La cita ya no está pendiente o no coincide con el paciente y la sede.");
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT id_episodio, estado, id_historia_clinica, id_sede FROM Episodio WHERE id_cita=?")) {
                ps.setLong(1, idCita);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        if (!"ABIERTO".equals(rs.getString("estado"))
                                || rs.getLong("id_historia_clinica") != idHistoriaClinica
                                || rs.getLong("id_sede") != idSede) {
                            throw new IllegalArgumentException("El episodio de esta cita está cerrado o no coincide con sus datos.");
                        }
                        return rs.getLong("id_episodio");
                    }
                }
            }
        }
        String tipo = tipoAtencion == null || tipoAtencion.isBlank() ? "Ambulatoria" : tipoAtencion.trim();
        String motivo = motivoConsulta == null || motivoConsulta.isBlank() ? "Consulta iniciada" : motivoConsulta.trim();
        try (PreparedStatement ps = con.prepareStatement(
                "INSERT INTO Episodio (tipo_atencion,motivo_consulta,estado,ingreso_en,id_sede,id_historia_clinica,id_cita) "
                + "VALUES (?,?,'ABIERTO',CURRENT_TIMESTAMP,?,?,?)")) {
            ps.setString(1, tipo);
            ps.setString(2, motivo);
            ps.setLong(3, idSede);
            ps.setLong(4, idHistoriaClinica);
            if (idCita == null) {
                ps.setNull(5, java.sql.Types.INTEGER);
            } else {
                ps.setLong(5, idCita);
            }
            ps.executeUpdate();
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT last_insert_rowid()"); ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                throw new SQLException("No se pudo recuperar el episodio.");
            }
            return rs.getLong(1);
        }
    }

    public static class AtencionCita {

        public long idCita, idEpisodio, idSede;
        public DatosPaciente paciente;
        public String tipo, motivo, tension, frecuencia, temperatura, peso;
        public Integer triage;
    }

    public AtencionCita abrirAtencionDesdeCita(long idCita) throws SQLException {
        if (idCita <= 0) {
            throw new IllegalArgumentException("Selecciona una cita.");
        }
        try (Connection con = new cConexion().conectar()) {
            con.setAutoCommit(false);
            try {
                AtencionCita d = new AtencionCita();
                d.idCita = idCita;
                String sql = "SELECT p.*, h.id_historia_clinica, a.id_sede, c.estado AS estado_cita "
                        + "FROM Cita c JOIN Paciente p ON p.id_paciente=c.id_paciente "
                        + "JOIN Agenda a ON a.id_agenda=c.id_agenda LEFT JOIN Historia_Clinica h "
                        + "ON h.id_paciente=p.id_paciente WHERE c.id_cita=?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setLong(1, idCita);
                    try (ResultSet r = ps.executeQuery()) {
                        if (!r.next()) {
                            throw new IllegalArgumentException("La cita no existe.");
                        }
                        if (!"PENDIENTE".equals(r.getString("estado_cita"))) {
                            throw new IllegalArgumentException(
                                    "Solo se puede iniciar o continuar una cita PENDIENTE.");
                        }
                        DatosPaciente p = new DatosPaciente();
                        p.idPaciente = r.getLong("id_paciente");
                        p.idHistoriaClinica = r.getLong("id_historia_clinica");
                        if (p.idHistoriaClinica <= 0) {
                            throw new IllegalArgumentException(
                                    "El paciente no tiene historia clínica. Completen su registro antes de atender.");
                        }
                        p.nombreCompleto = r.getString("nombres") + " " + r.getString("apellidos");
                        p.numeroDocumento = r.getString("numero_documento");
                        p.celular = r.getString("telefono");
                        p.fechaNacimiento = r.getString("fecha_nacimiento");
                        p.grupoSanguineo = r.getString("grupo_sanguineo");
                        p.factorRh = r.getString("factor_rh");
                        d.paciente = p;
                        d.idSede = r.getLong("id_sede");
                    }
                }
                d.idEpisodio = obtenerOCrearEpisodio(con, d.paciente.idHistoriaClinica, d.idSede,
                        idCita, "Ambulatoria", "Consulta iniciada");
                try (PreparedStatement ps = con.prepareStatement("SELECT * FROM Episodio WHERE id_episodio=?")) {
                    ps.setLong(1, d.idEpisodio);
                    try (ResultSet r = ps.executeQuery()) {
                        if (!r.next()) {
                            throw new SQLException("No se encontró el episodio.");
                        }
                        d.tipo = r.getString("tipo_atencion");
                        d.motivo = r.getString("motivo_consulta");
                        int nivel = r.getInt("nivel_triage");
                        d.triage = r.wasNull() ? null : nivel;
                        d.tension = r.getString("tension_arterial");
                        d.frecuencia = r.getString("frecuencia_cardiaca");
                        d.temperatura = r.getString("temperatura");
                        d.peso = r.getString("peso");
                    }
                }
                StringBuilder alergias = new StringBuilder();
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT sustancia FROM Alergia_Paciente WHERE id_historia_clinica=? AND estado='Confirmada'")) {
                    ps.setLong(1, d.paciente.idHistoriaClinica);
                    try (ResultSet r = ps.executeQuery()) {
                        while (r.next()) {
                            if (alergias.length() > 0) {
                                alergias.append(", ");
                            }
                            alergias.append(r.getString(1));
                        }
                    }
                }
                d.paciente.alergias = alergias.length() == 0 ? "Ninguna confirmada" : alergias.toString();
                con.commit();
                return d;
            } catch (SQLException | RuntimeException error) {
                try {
                    con.rollback();
                } catch (SQLException otro) {
                    error.addSuppressed(otro);
                }
                throw error;
            }
        }
    }

    public boolean agregarNotaClinica(long idEpisodio, long idUsuario, String examenFisico, String descripcionNota) {
        String sqlInsertNota = "INSERT INTO Nota_Clinica "
                + "(examen_fisico, descripcion, registrada_en, id_episodio, id_usuario) "
                + "VALUES (?, ?, CURRENT_TIMESTAMP, ?, ?)";

        try (java.sql.Connection con = new Conexion.cConexion().conectar(); java.sql.PreparedStatement psNota = con.prepareStatement(sqlInsertNota)) {

            psNota.setString(1, examenFisico);
            psNota.setString(2, descripcionNota);
            psNota.setLong(3, idEpisodio);
            psNota.setLong(4, idUsuario);

            int filasAfectadas = psNota.executeUpdate();
            return filasAfectadas > 0;

        } catch (java.sql.SQLException e) {
            System.err.println("Error al agregar nota: " + e.getMessage());
            return false;
        }
    }
}
