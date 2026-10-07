package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class cPaciente {

    private long idPaciente;
    private String nombres;
    private String apellidos;
    private String tipoDocumento;
    private String numeroDocumento;

    // Estado acordado para este ejercicio.
    private static final String ESTADO_IDENTIFICACION = "IDENTIFICADO";

    // Se usa para crear el objeto que realizará las consultas.
    public cPaciente() {
    }

    // Se usa para reunir los datos del paciente.
    public cPaciente(String nombres, String apellidos,
            String tipoDocumento, String numeroDocumento) {

        this.nombres = nombres;
        this.apellidos = apellidos;
        this.tipoDocumento = tipoDocumento;
        this.numeroDocumento = numeroDocumento;
    }

    public long getIdPaciente() {
        return idPaciente;
    }

    public String getNombres() {
        return nombres;
    }

    public String getApellidos() {
        return apellidos;
    }

    public String getTipoDocumento() {
        return tipoDocumento;
    }

    public String getNumeroDocumento() {
        return numeroDocumento;
    }

    // Comprueba que un texto tenga contenido y una longitud válida.
    private String validarTexto(String texto, String campo, int limite) {

        if (texto == null || texto.trim().isEmpty()) {
            throw new IllegalArgumentException(
                    "Debes escribir el campo: " + campo + "."
            );
        }

        String limpio = texto.trim();

        if (limpio.length() > limite) {
            throw new IllegalArgumentException(
                    "El campo " + campo + " admite hasta "
                    + limite + " caracteres."
            );
        }

        return limpio;
    }

    public cPaciente buscarPorDocumento(String tipo, String numero)
            throws SQLException {

        tipo = validarTexto(tipo, "tipo de documento", 10);
        numero = validarTexto(numero, "numero de documento", 30);

        String sql = "SELECT id_paciente, nombres, apellidos, "
                + "tipo_documento, numero_documento "
                + "FROM Paciente "
                + "WHERE tipo_documento = ? AND numero_documento = ?";

        try (
                Connection conexion = new cConexion().conectar();
                PreparedStatement consulta = conexion.prepareStatement(sql)
        ) {

            consulta.setString(1, tipo);
            consulta.setString(2, numero);

            try (ResultSet resultado = consulta.executeQuery()) {

                if (resultado.next()) {

                    cPaciente paciente = new cPaciente(
                            resultado.getString("nombres"),
                            resultado.getString("apellidos"),
                            resultado.getString("tipo_documento"),
                            resultado.getString("numero_documento")
                    );

                    paciente.idPaciente = resultado.getLong("id_paciente");

                    return paciente;
                }
            }
        }

        // No encontrar al paciente no es un error.
        return null;
    }

    public long registrarConHistoria(cPaciente datos)
            throws SQLException {

        if (datos == null) {
            throw new IllegalArgumentException(
                    "Debes proporcionar los datos del paciente."
            );
        }

        String nombres = validarTexto(datos.nombres, "nombres", 100);
        String apellidos = validarTexto(datos.apellidos, "apellidos", 100);
        String tipo = validarTexto(
                datos.tipoDocumento, "tipo de documento", 10
        );
        String numero = validarTexto(
                datos.numeroDocumento, "numero de documento", 30
        );

        // Primera comprobación para informar de un documento repetido.
        if (buscarPorDocumento(tipo, numero) != null) {
            throw new SQLException(
                    "Ya existe un paciente con ese tipo y numero de documento."
            );
        }

        String sqlPaciente = "INSERT INTO Paciente "
                + "(nombres, apellidos, tipo_documento, "
                + "numero_documento, estado_identificacion) "
                + "VALUES (?, ?, ?, ?, ?)";

        String sqlHistoria = "INSERT INTO Historia_Clinica "
                + "(numero_historia, id_paciente) "
                + "VALUES (?, ?)";

        try (Connection conexion = new cConexion().conectar()) {

            // Los cambios quedan pendientes hasta ejecutar commit().
            conexion.setAutoCommit(false);

            try {

                // 1. Insertar el paciente.
                try (PreparedStatement consulta =
                        conexion.prepareStatement(sqlPaciente)) {

                    consulta.setString(1, nombres);
                    consulta.setString(2, apellidos);
                    consulta.setString(3, tipo);
                    consulta.setString(4, numero);
                    consulta.setString(5, ESTADO_IDENTIFICACION);

                    consulta.executeUpdate();
                }

                // 2. Recuperar el ID en esta misma conexión.
                long idGenerado;

                try (
                        PreparedStatement consulta = conexion.prepareStatement(
                                "SELECT last_insert_rowid()"
                        );
                        ResultSet resultado = consulta.executeQuery()
                ) {

                    if (!resultado.next()) {
                        throw new SQLException(
                                "No se pudo recuperar el ID del paciente."
                        );
                    }

                    idGenerado = resultado.getLong(1);
                }

                // 3. Crear la historia para ese paciente.
                try (PreparedStatement consulta =
                        conexion.prepareStatement(sqlHistoria)) {

                    consulta.setString(1, "HC" + idGenerado);
                    consulta.setLong(2, idGenerado);

                    consulta.executeUpdate();
                }

                // 4. Guardar definitivamente ambos registros.
                conexion.commit();

                return idGenerado;

            } catch (SQLException error) {

                // Deshacer los cambios si alguna operación falla.
                try {
                    conexion.rollback();
                } catch (SQLException errorAlDeshacer) {
                    error.addSuppressed(errorAlDeshacer);
                }

                // La base también protege contra documentos repetidos.
                String mensaje = error.getMessage();

                if (mensaje != null
                        && mensaje.contains("UNIQUE constraint failed")
                        && mensaje.contains("Paciente.tipo_documento")
                        && mensaje.contains("Paciente.numero_documento")) {

                    throw new SQLException(
                            "Ya existe un paciente con ese tipo y numero "
                            + "de documento.",
                            error
                    );
                }

                // Conservar la información de cualquier otro error.
                throw error;
            }
        }
    }
}