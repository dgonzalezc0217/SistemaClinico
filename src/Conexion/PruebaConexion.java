package Conexion;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class PruebaConexion {

    public static void main(String[] args) {

        try (Connection conexion = new cConexion().conectar(); Statement consulta = conexion.createStatement()) {

            // 1. Mostrar la versión de SQLite.
            try (ResultSet resultado = consulta.executeQuery(
                    "SELECT sqlite_version()")) {

                if (resultado.next()) {
                    System.out.println(
                            "Versión de SQLite: " + resultado.getString(1)
                    );
                }
            }

            // 2. Comprobar que las relaciones estén activadas.
            try (ResultSet resultado = consulta.executeQuery(
                    "PRAGMA foreign_keys")) {

                if (resultado.next()) {
                    int valor = resultado.getInt(1);

                    System.out.println("foreign_keys: " + valor);

                    if (valor != 1) {
                        throw new SQLException(
                                "Las relaciones entre tablas no están activadas."
                        );
                    }
                } else {
                    throw new SQLException(
                            "No se pudo comprobar foreign_keys."
                    );
                }
            }

            // 3. Mostrar las tablas de la base de datos.
            System.out.println("Tablas encontradas:");

            try (ResultSet resultado = consulta.executeQuery(
                    "SELECT name FROM sqlite_master "
                    + "WHERE type = 'table' "
                    + "AND name NOT LIKE 'sqlite_%' "
                    + "ORDER BY name")) {

                while (resultado.next()) {
                    System.out.println("- " + resultado.getString("name"));
                }
            }

            // 4. Consultar Paciente, aunque no tenga registros.
            try (ResultSet resultado = consulta.executeQuery(
                    "SELECT COUNT(*) FROM Paciente")) {

                if (resultado.next()) {
                    System.out.println(
                            "Cantidad de pacientes: " + resultado.getInt(1)
                    );
                }
            }

            System.out.println("Prueba completada correctamente.");

        } catch (SQLException error) {
            System.out.println("Error: " + error.getMessage());
        }
    }
}
