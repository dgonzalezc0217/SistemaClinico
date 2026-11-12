
package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.Period;


public class cLaboratorio {
    // Método para consultar la base de datos y retornar un arreglo con los datos limpios
public String[] buscarPacientePorCedula(String numeroDocumento) {
        if (numeroDocumento == null || numeroDocumento.trim().isEmpty()) {
            throw new IllegalArgumentException("Debes escribir el número de documento.");
        }

        String[] datos = null;

        // Hacemos LEFT JOIN para traer datos y el ID de la Historia Clínica en una sola consulta
        String sql = "SELECT p.nombres, p.apellidos, p.numero_documento, "
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
                    datos = new String[6]; // Aumentamos el tamaño a 6 para incluir las alergias

                    // 0: Nombre completo
                    String nombres = resultado.getString("nombres");
                    String apellidos = resultado.getString("apellidos");
                    datos[0] = (nombres != null ? nombres : "") + " " + (apellidos != null ? apellidos : "");
                    
                    // 1: Cédula
                    datos[1] = resultado.getString("numero_documento");
                    
                    // 2: Celular
                    datos[2] = resultado.getString("telefono");
                    
                    // 3: Edad calculada
                    datos[3] = calcularEdad(resultado.getString("fecha_nacimiento"));
                    
                    // 4: Tipo de Sangre + RH
                    String sangre = resultado.getString("grupo_sanguineo");
                    String rh = resultado.getString("factor_rh");
                    datos[4] = (sangre != null ? sangre : "") + (rh != null ? rh : "");

                    // 5: Bloque para buscar alergias CONFIRMADAS
                    long idHistoriaClinica = resultado.getLong("id_historia_clinica");
                    String sqlAlergias = "SELECT sustancia FROM Alergia_Paciente WHERE id_historia_clinica = ? AND estado = 'Confirmada'";
                    StringBuilder alergiasConcatenadas = new StringBuilder();

                    try (PreparedStatement consultaAlergias = conexion.prepareStatement(sqlAlergias)) {
                        consultaAlergias.setLong(1, idHistoriaClinica);

                        try (ResultSet rsAlergias = consultaAlergias.executeQuery()) {
                            while (rsAlergias.next()) {
                                if (alergiasConcatenadas.length() > 0) {
                                    alergiasConcatenadas.append(", ");
                                }
                                alergiasConcatenadas.append(rsAlergias.getString("sustancia"));
                            }
                        }
                    }

                    if (alergiasConcatenadas.length() == 0) {
                        datos[5] = "Ninguna confirmada";
                    } else {
                        datos[5] = alergiasConcatenadas.toString();
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("Error al buscar paciente y alergias: " + e.getMessage());
        } 

        return datos;
    }
   
   private String calcularEdad(String fechaNacimiento) {
        if (fechaNacimiento == null || fechaNacimiento.trim().isEmpty()) {
            return "N/A";
        }
        try {
            LocalDate fechaNac = LocalDate.parse(fechaNacimiento);
            return String.valueOf(Period.between(fechaNac, LocalDate.now()).getYears());
        } catch (Exception e) {
            return "N/A";
        }
    }
   
   public java.util.List<String[]> obtenerOrdenesLaboratorio(String cedula) {
        java.util.List<String[]> listaOrdenes = new java.util.ArrayList<>();
        
        // Consulta cruzando desde Orden_Medica hasta Paciente, filtrando solo por LABORATORIO
        String sql = "SELECT o.id_orden_medica, o.emitida_en, s.nombre AS examen, s.tipo AS area, d.estado "
                   + "FROM Orden_Medica o "
                   + "JOIN Detalle_Orden d ON o.id_orden_medica = d.id_orden_medica "
                   + "JOIN Servicio s ON d.id_servicio = s.id_servicio "
                   + "JOIN Episodio e ON o.id_episodio = e.id_episodio "
                   + "JOIN Historia_Clinica hc ON e.id_historia_clinica = hc.id_historia_clinica "
                   + "JOIN Paciente p ON hc.id_paciente = p.id_paciente "
                   + "WHERE p.numero_documento = ? AND s.tipo = 'LABORATORIO' "
                   + "ORDER BY o.id_orden_medica DESC";

        try (java.sql.Connection conn = new Conexion.cConexion().conectar();
             java.sql.PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, cedula);
            
            try (java.sql.ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    String[] fila = new String[5];
                    fila[0] = "ORD-" + rs.getString("id_orden_medica");
                    
                    // Formatear la fecha si existe, o dejarla en N/A
                    String fecha = rs.getString("emitida_en");
                    fila[1] = (fecha != null) ? fecha.split(" ")[0] : "N/A"; 
                    
                    fila[2] = rs.getString("examen");
                    fila[3] = rs.getString("area");
                    fila[4] = rs.getString("estado");
                    listaOrdenes.add(fila);
                }
            }
        } catch (java.sql.SQLException e) {
            System.err.println("Error al consultar órdenes: " + e.getMessage());
        }
        
        return listaOrdenes;
    }
   
   public java.util.List<String[]> obtenerResultadosPorOrden(String idOrdenFormateado) {
        java.util.List<String[]> listaDetalles = new java.util.ArrayList<>();

        // 1. Limpiar el prefijo "ORD-"
        String idReal = idOrdenFormateado.replace("ORD-", "").trim();

        // 2. Consulta SQL ajustada a Resultado_Lab, Valor_Resultado y Detalle_Orden
        String sql = "SELECT r.prueba, v.nombre_analito, "
                   + "COALESCE(v.valor_textual, CAST(v.valor_numerico AS TEXT)) AS resultado, "
                   + "v.unidad, v.referencia_aplicada, v.interpretacion, r.alerta, d.estado "
                   + "FROM Detalle_Orden d "
                   + "JOIN Resultado_Lab r ON d.id_detalle_orden = r.id_detalle_orden "
                   + "JOIN Valor_Resultado v ON r.id_resultado_lab = v.id_resultado_lab "
                   + "WHERE d.id_orden_medica = ?";

        try (java.sql.Connection conn = new Conexion.cConexion().conectar();
             java.sql.PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, Integer.parseInt(idReal));

            try (java.sql.ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    String[] fila = new String[7];
                    fila[0] = rs.getString("prueba");
                    fila[1] = rs.getString("nombre_analito");
                    fila[2] = rs.getString("resultado") != null ? rs.getString("resultado") : "Pendiente";
                    fila[3] = rs.getString("unidad") != null ? rs.getString("unidad") : "-";
                    fila[4] = rs.getString("referencia_aplicada") != null ? rs.getString("referencia_aplicada") : "-";

                    // Combinar interpretación y alerta en la columna Observación
                    String interp = rs.getString("interpretacion");
                    String alerta = rs.getString("alerta");
                    String obs = (interp != null ? interp : "");
                    if (alerta != null && !alerta.isBlank()) {
                        obs += (obs.isEmpty() ? "" : " | ") + "Alerta: " + alerta;
                    }
                    fila[5] = obs.isEmpty() ? "Normal" : obs;

                    fila[6] = rs.getString("estado") != null ? rs.getString("estado") : "COMPLETADO";
                    listaDetalles.add(fila);
                }
            }
        } catch (Exception e) {
            System.err.println("Error al consultar detalles de la orden: " + e.getMessage());
        }

        return listaDetalles;
    }
}