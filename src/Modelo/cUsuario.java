package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

public class cUsuario {

    // Datos que guardaremos de cada usuario.
    private long idUsuario;
    private String nombres;
    private String apellidos;

    // Permite crear el objeto que realizará la consulta.
    public cUsuario() {
    }

    // Permite crear un usuario con los datos encontrados.
    public cUsuario(long idUsuario, String nombres, String apellidos) {
        this.idUsuario = idUsuario;
        this.nombres = nombres;
        this.apellidos = apellidos;
    }

    // Permiten leer los datos de cada usuario.
    public long getIdUsuario() {
        return idUsuario;
    }

    public String getNombres() {
        return nombres;
    }

    public String getApellidos() {
        return apellidos;
    }

    public ArrayList<cUsuario> listarActivos() throws SQLException {

        // La lista empieza vacía.
        ArrayList<cUsuario> usuarios = new ArrayList<>();

        // Busca los usuarios activos y los ordena.
        String sql = "SELECT id_usuario, nombres, apellidos "
                + "FROM Usuario "
                + "WHERE activo = 1 "
                + "ORDER BY apellidos, nombres";

        // Abre la conexión, prepara la consulta y obtiene las filas.
        // Los tres recursos se cierran automáticamente al terminar.
        try (
                Connection conexion = new cConexion().conectar();
                PreparedStatement consulta = conexion.prepareStatement(sql);
                ResultSet resultado = consulta.executeQuery()
        ) {

            // Recorre los usuarios encontrados, uno por uno.
            while (resultado.next()) {

                cUsuario usuario = new cUsuario(
                        resultado.getLong("id_usuario"),
                        resultado.getString("nombres"),
                        resultado.getString("apellidos")
                );

                // Agrega el usuario a la lista.
                usuarios.add(usuario);
            }
        }

        // Devuelve la lista, incluso si no encontró usuarios.
        return usuarios;
    }
}