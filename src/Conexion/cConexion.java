/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package Conexion;

import java.sql.Connection;
import java.sql.DriverManager;
import javax.swing.JOptionPane;

/**
 *
 * @author oscar
 */
public class cConexion {

    Connection conectar = null;
    //crear una cadena de conexion con la libreria sqlite
    String cadena = "jdbc:sqlite:C:/Users/admin/Documents/database/data/clinica.db";

    //crear el metodo de conexion
    public Connection conectar() {
        try {
            //Hago publica la conexion con la libreria sqlite
            Class.forName("org.sqlite.JDBC");
            //Abrir la conexion
            conectar = DriverManager.getConnection(cadena);
            JOptionPane.showMessageDialog(null, "Conexion Exitosa!!!");
        } catch (Exception er) {
            JOptionPane.showMessageDialog(null, "Error!! La conexion No se realizo: " + er.getMessage());
        }
        return conectar;
    }
}
