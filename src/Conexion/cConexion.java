package Conexion;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

/**
 *
 * @author oscar
 */
public class cConexion {

    // Cadena de conexión con la base de datos.
    String cadena = "jdbc:sqlite:database/data/clinica.db";

    public Connection conectar() throws SQLException {

        // Comprobar que la biblioteca de SQLite esté disponible.
        try {
            Class.forName("org.sqlite.JDBC");
        } catch (ClassNotFoundException error) {
            throw new SQLException(
                    "No se encontró la biblioteca de SQLite.",
                    error
            );
        }

        // Abrir una nueva conexión.
        Connection conectar = DriverManager.getConnection(cadena);

        // Preparar la conexión antes de utilizarla.
        try (Statement consulta = conectar.createStatement()) {

            consulta.execute("PRAGMA foreign_keys = ON");
            consulta.execute("PRAGMA busy_timeout = 5000");

        } catch (SQLException error) {

            // Si la preparación falla, cerrar la conexión.
            try {
                conectar.close();
            } catch (SQLException errorAlCerrar) {
                error.addSuppressed(errorAlCerrar);
            }

            // Enviar el error al código que llamó al método.
            throw error;
        }
        return conectar;
    }
}