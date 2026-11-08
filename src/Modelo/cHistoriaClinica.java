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

    public long obtenerOCrearEpisodio(long idHistoriaClinica, long idSede, Long idCita, String tipoAtencion, String motivoConsulta) throws SQLException {
        try (Connection con = new cConexion().conectar()) {

            // 1. Evitar duplicados si viene enlazado a una cita existente (idCita no es nulo)
            if (idCita != null) {
                String sqlCheck = "SELECT id_episodio FROM Episodio WHERE id_cita = ?";
                try (PreparedStatement psCheck = con.prepareStatement(sqlCheck)) {
                    psCheck.setLong(1, idCita);
                    try (ResultSet rs = psCheck.executeQuery()) {
                        if (rs.next()) {
                            return rs.getLong("id_episodio");
                        }
                    }
                }
            }

            // 2. Validaciones para cumplir con las restricciones de la base de datos
            if (tipoAtencion != null && tipoAtencion.trim().isEmpty()) {
                tipoAtencion = null;
            }
            if (motivoConsulta == null || motivoConsulta.trim().isEmpty()) {
                motivoConsulta = "Consulta iniciada";
            }

            // 3. Insertar nuevo Episodio en estado ABIERTO
            String sqlInsert = "INSERT INTO Episodio (tipo_atencion, motivo_consulta, estado, ingreso_en, id_sede, id_historia_clinica, id_cita) "
                    + "VALUES (?, ?, 'ABIERTO', CURRENT_TIMESTAMP, ?, ?, ?)";

            try (PreparedStatement ps = con.prepareStatement(sqlInsert)) {
                ps.setString(1, tipoAtencion);
                ps.setString(2, motivoConsulta);
                ps.setLong(3, idSede);
                ps.setLong(4, idHistoriaClinica);

                if (idCita != null) {
                    ps.setLong(5, idCita);
                } else {
                    ps.setNull(5, java.sql.Types.INTEGER);
                }

                ps.executeUpdate();

                // 4. Recuperar y retornar el ID del episodio recién creado
                try (PreparedStatement psId = con.prepareStatement("SELECT last_insert_rowid()"); ResultSet rs = psId.executeQuery()) {
                    if (rs.next()) {
                        return rs.getLong(1);
                    }
                }
            }
        }
        throw new SQLException("Error al crear el episodio clínico.");
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
