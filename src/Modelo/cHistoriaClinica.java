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
        // 1. Si idCita viene en 0 o negativo, se trata como atención sin cita (null)
        Long citaValida = (idCita != null && idCita > 0) ? idCita : null;
        long sedeEfectiva = idSede;

        if (idHistoriaClinica <= 0 || (citaValida == null && sedeEfectiva <= 0)) {
            throw new IllegalArgumentException(
                    "El paciente necesita historia clínica y una sede válida.");
        }

        if (citaValida != null) {
            // 2. Bloquea la cita PENDIENTE verificando que pertenezca al mismo paciente
            String bloqueo = "UPDATE Cita SET estado=estado WHERE id_cita=? AND estado='PENDIENTE' "
                    + "AND EXISTS (SELECT 1 FROM Historia_Clinica h WHERE "
                    + "h.id_historia_clinica=? AND h.id_paciente=Cita.id_paciente)";
            try (PreparedStatement ps = con.prepareStatement(bloqueo)) {
                ps.setLong(1, citaValida);
                ps.setLong(2, idHistoriaClinica);
                if (ps.executeUpdate() != 1) {
                    throw new IllegalArgumentException(
                            "La cita ya no está pendiente o no coincide con el paciente.");
                }
            }

            // 3. Obtiene la sede real de la agenda asociada a esa cita
            String sqlSedeCita = "SELECT a.id_sede FROM Cita c "
                    + "JOIN Agenda a ON a.id_agenda = c.id_agenda "
                    + "WHERE c.id_cita = ?";
            try (PreparedStatement ps = con.prepareStatement(sqlSedeCita)) {
                ps.setLong(1, citaValida);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        throw new IllegalArgumentException("La cita no tiene una agenda o sede válida.");
                    }
                    sedeEfectiva = rs.getLong("id_sede");
                }
            }

            // 4. Idempotencia: si ya existe un episodio abierto para esta cita, lo devuelve
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT id_episodio, estado, id_historia_clinica, id_sede FROM Episodio WHERE id_cita=?")) {
                ps.setLong(1, citaValida);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        if (!"ABIERTO".equals(rs.getString("estado"))
                                || rs.getLong("id_historia_clinica") != idHistoriaClinica
                                || rs.getLong("id_sede") != sedeEfectiva) {
                            throw new IllegalArgumentException(
                                    "El episodio de esta cita está cerrado o no coincide con sus datos.");
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
            ps.setLong(3, sedeEfectiva);
            ps.setLong(4, idHistoriaClinica);
            if (citaValida == null) {
                ps.setNull(5, java.sql.Types.INTEGER);
            } else {
                ps.setLong(5, citaValida);
            }
            ps.executeUpdate();
        }

        try (PreparedStatement ps = con.prepareStatement("SELECT last_insert_rowid()");
             ResultSet rs = ps.executeQuery()) {
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

    public DatosPaciente obtenerPacientePorCita(long idCita) throws SQLException {
        if (idCita <= 0) {
            throw new IllegalArgumentException("Selecciona una cita válida.");
        }

        try (Connection con = new cConexion().conectar()) {
            // 1. Buscar los datos del paciente asociados a la cita
            String sql = "SELECT p.*, h.id_historia_clinica "
                    + "FROM Cita c "
                    + "JOIN Paciente p ON p.id_paciente = c.id_paciente "
                    + "LEFT JOIN Historia_Clinica h ON h.id_paciente = p.id_paciente "
                    + "WHERE c.id_cita = ?";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setLong(1, idCita);
                try (ResultSet r = ps.executeQuery()) {
                    if (!r.next()) {
                        throw new IllegalArgumentException("La cita no existe en la base de datos.");
                    }

                    DatosPaciente p = new DatosPaciente();
                    p.idPaciente = r.getLong("id_paciente");
                    p.idHistoriaClinica = r.getLong("id_historia_clinica");

                    if (p.idHistoriaClinica <= 0) {
                        throw new IllegalArgumentException("El paciente no tiene historia clínica. Completen su registro antes de atender.");
                    }

                    p.nombreCompleto = r.getString("nombres") + " " + r.getString("apellidos");
                    p.numeroDocumento = r.getString("numero_documento");
                    p.celular = r.getString("telefono");
                    p.fechaNacimiento = r.getString("fecha_nacimiento");
                    p.grupoSanguineo = r.getString("grupo_sanguineo");
                    p.factorRh = r.getString("factor_rh");

                    // 2. Buscar las alergias del paciente
                    StringBuilder alergias = new StringBuilder();
                    String sqlAlergias = "SELECT sustancia FROM Alergia_Paciente WHERE id_historia_clinica=? AND estado='Confirmada'";
                    try (PreparedStatement psA = con.prepareStatement(sqlAlergias)) {
                        psA.setLong(1, p.idHistoriaClinica);
                        try (ResultSet rA = psA.executeQuery()) {
                            while (rA.next()) {
                                if (alergias.length() > 0) {
                                    alergias.append(", ");
                                }
                                alergias.append(rA.getString(1));
                            }
                        }
                    }
                    p.alergias = alergias.length() == 0 ? "Ninguna confirmada" : alergias.toString();

                    // 3. Devolver SOLO al paciente (Sin crear el episodio)
                    return p;
                }
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

    public boolean tieneDiagnosticos(long idEpisodio) {
        String sql = "SELECT COUNT(*) AS total FROM Diagnostico_Clinico WHERE id_episodio = ?";

        try (java.sql.Connection con = new Conexion.cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, idEpisodio);

            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total") > 0; // Retorna true si hay 1 o más
                }
            }
        } catch (java.sql.SQLException e) {
            System.err.println("Error al verificar diagnósticos: " + e.getMessage());
        }
        return false;
    }

    public boolean guardarYCerrarEpisodioYCita(
            long idEpisodio, String tipoAtencion, int nivelTriage,
            String ta, String fc, String temp, String peso,
            String motivoConsulta) {

        // 1. Actualiza el episodio (signos vitales y motivo) y lo cierra
        String updateEpisodio = "UPDATE Episodio SET "
                + "tipo_atencion = ?, nivel_triage = ?, tension_arterial = ?, "
                + "frecuencia_cardiaca = ?, temperatura = ?, peso = ?, "
                + "motivo_consulta = ?, "
                + "estado = 'CERRADO', egreso_en = CURRENT_TIMESTAMP "
                + "WHERE id_episodio = ?";

        // 2. Actualiza la cita vinculada a este episodio
        String updateCita = "UPDATE Cita SET estado = 'ATENDIDA' "
                + "WHERE id_cita = (SELECT id_cita FROM Episodio WHERE id_episodio = ?)";

        try (java.sql.Connection con = new Conexion.cConexion().conectar()) {
            con.setAutoCommit(false);

            try {
                try (java.sql.PreparedStatement psEpi = con.prepareStatement(updateEpisodio)) {
                    psEpi.setString(1, tipoAtencion);
                    psEpi.setInt(2, nivelTriage);
                    psEpi.setString(3, ta);
                    psEpi.setString(4, fc);
                    psEpi.setString(5, temp);
                    psEpi.setString(6, peso);
                    psEpi.setString(7, motivoConsulta);
                    psEpi.setLong(8, idEpisodio);
                    psEpi.executeUpdate();
                }

                try (java.sql.PreparedStatement psCita = con.prepareStatement(updateCita)) {
                    psCita.setLong(1, idEpisodio);
                    psCita.executeUpdate();
                }

                con.commit();
                return true;

            } catch (java.sql.SQLException ex) {
                con.rollback();
                throw ex;
            }
        } catch (java.sql.SQLException e) {
            System.err.println("Error al cerrar episodio y cita: " + e.getMessage());
            return false;
        }
    }

    public javax.swing.table.DefaultTableModel consultarHistorialPaciente(long idPaciente) {
        // 1. Definimos las columnas que verá el médico (más una oculta para el ID)
        String[] columnas = {"ID Episodio", "Fecha", "Motivo de Consulta", "Diagnósticos"};

        // 2. Creamos el modelo de la tabla bloqueando la edición (solo lectura)
        javax.swing.table.DefaultTableModel modeloTabla = new javax.swing.table.DefaultTableModel(null, columnas) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        // 3. Consulta SQL: Busca episodios cerrados del paciente y concatena sus diagnósticos
        String sql = "SELECT e.id_episodio, date(e.ingreso_en) AS fecha, e.motivo_consulta, "
                + "(SELECT GROUP_CONCAT(cat.codigo, ', ') "
                + " FROM Diagnostico_Clinico dc "
                + " INNER JOIN Catalogo_Diagnostico cat ON dc.id_catalogo_diagnostico = cat.id_catalogo_diagnostico "
                + " WHERE dc.id_episodio = e.id_episodio) AS codigos_diagnosticos "
                + "FROM Episodio e "
                + "INNER JOIN Cita c ON e.id_cita = c.id_cita " // Enlazamos con Cita para llegar al id_paciente
                + "WHERE c.id_paciente = ? AND e.estado = 'CERRADO' "
                + "ORDER BY e.ingreso_en DESC"; // Del más reciente al más antiguo

        try (java.sql.Connection con = new Conexion.cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, idPaciente);

            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Object[] fila = new Object[4];
                    fila[0] = rs.getLong("id_episodio");
                    fila[1] = rs.getString("fecha");
                    fila[2] = rs.getString("motivo_consulta");

                    // Si no tiene diagnósticos, ponemos "Ninguno"
                    String diag = rs.getString("codigos_diagnosticos");
                    fila[3] = (diag != null && !diag.trim().isEmpty()) ? diag : "Ninguno";

                    modeloTabla.addRow(fila);
                }
            }
        } catch (java.sql.SQLException ex) {
            System.err.println("Error al consultar historial: " + ex.getMessage());
        }

        return modeloTabla;
    }

    public java.util.HashMap<String, String> obtenerDetalleConsultaPrevia(long idEpisodioViejo) {
        java.util.HashMap<String, String> datos = new java.util.HashMap<>();

        // 1. Obtener signos vitales y motivo del episodio
        String sqlEpisodio = "SELECT tension_arterial, frecuencia_cardiaca, temperatura, peso, "
                + "motivo_consulta, tipo_atencion, nivel_triage "
                + "FROM Episodio WHERE id_episodio = ?";

        try (java.sql.Connection con = new Conexion.cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sqlEpisodio)) {

            ps.setLong(1, idEpisodioViejo);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    datos.put("ta", rs.getString("tension_arterial") != null ? rs.getString("tension_arterial") : "");
                    datos.put("fc", rs.getString("frecuencia_cardiaca") != null ? rs.getString("frecuencia_cardiaca") : "");
                    datos.put("temp", rs.getString("temperatura") != null ? rs.getString("temperatura") : "");
                    datos.put("peso", rs.getString("peso") != null ? rs.getString("peso") : "");
                    datos.put("motivo", rs.getString("motivo_consulta") != null ? rs.getString("motivo_consulta") : "");
                    datos.put("triage", rs.getString("nivel_triage") != null ? rs.getString("nivel_triage") : "0");
                    datos.put("tipo_atencion", rs.getString("tipo_atencion") != null ? rs.getString("tipo_atencion") : "");
                }
            }

            // 2. Concatenar Exámenes Físicos y Notas Clínicas en lista limpia (sin fecha/hora)
            String sqlNotas = "SELECT examen_fisico, descripcion "
                    + "FROM Nota_Clinica WHERE id_episodio = ? ORDER BY registrada_en ASC";

            try (java.sql.PreparedStatement psNotas = con.prepareStatement(sqlNotas)) {
                psNotas.setLong(1, idEpisodioViejo);
                try (java.sql.ResultSet rsNotas = psNotas.executeQuery()) {
                    StringBuilder sbExamen = new StringBuilder();
                    StringBuilder sbNota = new StringBuilder();

                    while (rsNotas.next()) {
                        String examen = rsNotas.getString("examen_fisico");
                        String desc = rsNotas.getString("descripcion");

                        if (examen != null && !examen.trim().isEmpty()) {
                            if (sbExamen.length() > 0) {
                                sbExamen.append("\n");
                            }
                            sbExamen.append("• ").append(examen);
                        }

                        if (desc != null && !desc.trim().isEmpty()) {
                            if (sbNota.length() > 0) {
                                sbNota.append("\n");
                            }
                            sbNota.append("• ").append(desc);
                        }
                    }

                    datos.put("examen", sbExamen.toString());
                    datos.put("nota", sbNota.toString());
                }
            }

        } catch (java.sql.SQLException e) {
            System.err.println("Error al cargar datos previos: " + e.getMessage());
        }
        return datos;
    }

// 2. Método para clonar los diagnósticos al episodio nuevo (evitando duplicados)
    public boolean clonarDiagnosticos(long idEpisodioViejo, long idEpisodioNuevo, long idUsuario) {
        String sql = "INSERT INTO Diagnostico_Clinico (id_episodio, id_usuario, id_catalogo_diagnostico, tipo_diagnostico, estado) "
                + "SELECT ?, ?, id_catalogo_diagnostico, tipo_diagnostico, estado "
                + "FROM Diagnostico_Clinico WHERE id_episodio = ? "
                + "AND id_catalogo_diagnostico NOT IN (SELECT id_catalogo_diagnostico FROM Diagnostico_Clinico WHERE id_episodio = ?)";

        try (java.sql.Connection con = new Conexion.cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, idEpisodioNuevo);
            ps.setLong(2, idUsuario);
            ps.setLong(3, idEpisodioViejo);
            ps.setLong(4, idEpisodioNuevo); // Para validar que no exista ya en el nuevo

            ps.executeUpdate();
            return true;
        } catch (java.sql.SQLException e) {
            System.err.println("Error al clonar diagnósticos: " + e.getMessage());
            return false;
        }
    }

}
