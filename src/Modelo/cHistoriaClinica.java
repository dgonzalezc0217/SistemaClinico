
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
        try (Connection conexion = new cConexion().conectar(); 
             PreparedStatement consulta = conexion.prepareStatement(sql)) {

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
}
