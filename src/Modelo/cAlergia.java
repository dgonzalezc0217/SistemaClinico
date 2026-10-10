package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import javax.swing.JOptionPane;

public class cAlergia {

    public boolean añadirAlergia(String sustancia, String reaccion, String estado,
            String observaciones, int idUsuario, int idHistoria) {
        // Sentencia SQL para ingresar los datos en la base de datos
        String sql = "INSERT INTO Alergia_Paciente "
                + "(sustancia, reaccion, estado, registrada_en, id_usuario, id_historia_clinica, observaciones) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql)) {

            //Genera la fecha y hora actual en el formato de SQLite 
            LocalDateTime ahora = LocalDateTime.now();
            DateTimeFormatter formato = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            String fechaRegistro = ahora.format(formato);

            //Asigna los parámetros a la consulta
            consulta.setString(1, sustancia);
            consulta.setString(2, reaccion);
            consulta.setString(3, estado);
            consulta.setString(4, fechaRegistro);
            consulta.setInt(5, idUsuario);
            consulta.setInt(6, idHistoria);
            consulta.setString(7, observaciones);

            //Ejecuta el insert
            int filasAfectadas = consulta.executeUpdate();
            return filasAfectadas > 0;

        } catch (SQLException e) {
            JOptionPane.showMessageDialog(null, "Error al guardar la alergia: " + e.getMessage(), "Error BD", JOptionPane.ERROR_MESSAGE);
            return false;
        }
    }

    public boolean actualizarAlergia(int idAlergia, String sustancia, String reaccion, String estado, String observaciones) {

        //La consulta SQL 
        String sql = "UPDATE Alergia_Paciente SET sustancia = ?, reaccion = ?, estado = ?, observaciones = ? "
                + "WHERE id_alergia_paciente = ?";

        //Usamos try-with-resources para manejar y cerrar la conexión automáticamente
        try (
                java.sql.Connection conexion = new Conexion.cConexion().conectar(); java.sql.PreparedStatement consulta = conexion.prepareStatement(sql)) {
            // Asignar los nuevos valores que van a reemplazar a los viejos
            consulta.setString(1, sustancia);
            consulta.setString(2, reaccion);
            consulta.setString(3, estado);
            consulta.setString(4, observaciones);

            consulta.setInt(5, idAlergia);

            // Ejecutar la actualización en la base de datos
            int filasAfectadas = consulta.executeUpdate();

            // Si filasAfectadas es mayor a 0, significa que se encontró y actualizó la alergia
            return filasAfectadas > 0;

        } catch (java.sql.SQLException e) {
            javax.swing.JOptionPane.showMessageDialog(null, "Error al actualizar la alergia: " + e.getMessage());
            return false;
        }
    }

    public void mostrarAlergias(javax.swing.JTable tblAlergias, int idHistoria) {

        // Crear un objeto para manejar la tabla y hacer que no sea editable
        javax.swing.table.DefaultTableModel modelo = new javax.swing.table.DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false; // Retorna false para que ninguna celda pueda ser editada
            }
        };

        // Crear los títulos de las columnas para las alergias
        modelo.addColumn("ID");
        modelo.addColumn("Sustancia");
        modelo.addColumn("Reacción");
        modelo.addColumn("Estado");
        modelo.addColumn("Observaciones");
        modelo.addColumn("Fecha Registro");

        // Aplicamos el modelo vacío a la tabla visual
        tblAlergias.setModel(modelo);
        tblAlergias.getColumnModel().getColumn(0).setMaxWidth(0);
        tblAlergias.getColumnModel().getColumn(0).setMinWidth(0);
        tblAlergias.getColumnModel().getColumn(0).setPreferredWidth(0);

        // Se asigna la consulta SQL filtrando por la historia clínica del paciente
        String sql = "SELECT id_alergia_paciente, sustancia, reaccion, estado, observaciones, registrada_en "
                + "FROM Alergia_Paciente WHERE id_historia_clinica = ?";

        // Arreglo con 5 espacios, uno para cada columna mostrada
        String[] datos = new String[6];

        // Usamos try-with-resources para asegurar que la conexión se cierre correctamente
        try (
                java.sql.Connection conexion = new Conexion.cConexion().conectar(); java.sql.PreparedStatement consulta = conexion.prepareStatement(sql)) {
            // Asignamos el ID de la historia al interrogante de la consulta SQL
            consulta.setInt(1, idHistoria);

            try (java.sql.ResultSet rs = consulta.executeQuery()) {
                // Ciclo que se repetirá mientras encuentre resultados
                while (rs.next()) {
                    datos[0] = rs.getString("id_alergia_paciente");
                    datos[1] = rs.getString("sustancia");
                    datos[2] = rs.getString("reaccion");
                    datos[3] = rs.getString("estado");
                    datos[4] = rs.getString("observaciones");
                    datos[5] = rs.getString("registrada_en");

                    // Añade la fila completa al modelo de la tabla
                    modelo.addRow(datos);
                }
            }

        } catch (java.sql.SQLException er) {
            javax.swing.JOptionPane.showMessageDialog(null, "Error al cargar las alergias: " + er.getMessage());
        }
    }
}
