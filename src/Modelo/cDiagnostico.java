/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.swing.table.DefaultTableModel;

public class cDiagnostico {

    public DefaultTableModel buscarDiagnosticoEnCatalogo(String codigo, String descripcion) {
        DefaultTableModel modeloTabla = new DefaultTableModel();
        modeloTabla.addColumn("ID");
        modeloTabla.addColumn("Código");
        modeloTabla.addColumn("Descripción");

        String sql = "SELECT id_catalogo_diagnostico, codigo, descripcion FROM Catalogo_Diagnostico "
                + "WHERE codigo LIKE ? AND descripcion LIKE ?";

        try (Connection con = new Conexion.cConexion().conectar(); PreparedStatement ps = con.prepareStatement(sql)) {

            // Usamos % para que busque coincidencias parciales
            ps.setString(1, "%" + (codigo != null ? codigo.trim() : "") + "%");
            ps.setString(2, "%" + (descripcion != null ? descripcion.trim() : "") + "%");

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Object[] fila = new Object[3];
                    fila[0] = rs.getLong("id_catalogo_diagnostico");
                    fila[1] = rs.getString("codigo");
                    fila[2] = rs.getString("descripcion");
                    modeloTabla.addRow(fila);
                }
            }
        } catch (SQLException e) {
            System.err.println("Error al buscar catálogo: " + e.getMessage());
        }
        return modeloTabla;
    }

// 2. Método para insertar en Diagnostico_Clinico
    public boolean registrarDiagnosticoClinico(long idEpisodio, long idUsuario, long idCatalogo, String tipo, String estado) {
        String sql = "INSERT INTO Diagnostico_Clinico "
                + "(tipo, estado, id_usuario, id_episodio, id_catalogo_diagnostico) "
                + "VALUES (?, ?, ?, ?, ?)";

        try (Connection con = new Conexion.cConexion().conectar(); PreparedStatement ps = con.prepareStatement(sql)) {

            // Asignamos valores predeterminados si tipo o estado vienen nulos
            ps.setString(1, tipo != null && !tipo.isEmpty() ? tipo : "PRESUNTIVO");
            ps.setString(2, estado != null && !estado.isEmpty() ? estado : "ACTIVO");
            ps.setLong(3, idUsuario);
            ps.setLong(4, idEpisodio);
            ps.setLong(5, idCatalogo);

            int filas = ps.executeUpdate();
            return filas > 0;
        } catch (SQLException e) {
            System.err.println("Error al registrar diagnóstico: " + e.getMessage());
            return false;
        }
    }

    public boolean existeDiagnosticoEnEpisodio(long idEpisodio, long idCatalogo) {
        String sql = "SELECT 1 FROM Diagnostico_Clinico WHERE id_episodio = ? AND id_catalogo_diagnostico = ?";

        try (java.sql.Connection con = new Conexion.cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, idEpisodio);
            ps.setLong(2, idCatalogo);

            try (java.sql.ResultSet rs = ps.executeQuery()) {
                return rs.next(); // Si devuelve true, significa que el diagnóstico ya existe
            }
        } catch (java.sql.SQLException e) {
            System.err.println("Error al verificar diagnóstico duplicado: " + e.getMessage());
            return false;
        }
    }

    public void deshacerDiagnosticos(long idEpisodio, java.util.List<Long> idsCatalogo) {
        // Si la lista está vacía, no hay nada que borrar
        if (idsCatalogo == null || idsCatalogo.isEmpty()) {
            return;
        }

        String sql = "DELETE FROM Diagnostico_Clinico WHERE id_episodio = ? AND id_catalogo_diagnostico = ?";

        try (java.sql.Connection con = new cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            // Recorremos la lista y borramos uno por uno
            for (Long idCat : idsCatalogo) {
                ps.setLong(1, idEpisodio);
                ps.setLong(2, idCat);
                ps.executeUpdate();
            }

        } catch (java.sql.SQLException e) {
            System.err.println("Error al deshacer diagnósticos: " + e.getMessage());
        }
    }

    public String obtenerDiagnosticosDelEpisodio(long idEpisodio) {
        StringBuilder listaDiagnosticos = new StringBuilder();

        String sql = "SELECT c.codigo, c.descripcion "
                + "FROM Diagnostico_Clinico d "
                + "INNER JOIN Catalogo_Diagnostico c ON d.id_catalogo_diagnostico = c.id_catalogo_diagnostico "
                + "WHERE d.id_episodio = ?";

        try (java.sql.Connection con = new Conexion.cConexion().conectar(); java.sql.PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setLong(1, idEpisodio);

            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String codigo = rs.getString("codigo");
                    String descripcion = rs.getString("descripcion");
                    // Construye el texto con el mismo formato que usaste al agregar
                    listaDiagnosticos.append("• [").append(codigo).append("] - ").append(descripcion).append("\n");
                }
            }
        } catch (java.sql.SQLException e) {
            System.err.println("Error al cargar diagnósticos previos: " + e.getMessage());
        }

        return listaDiagnosticos.toString();
    }
}
