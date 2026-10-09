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
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql); ResultSet resultado = consulta.executeQuery()) {

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
    // Reúne los datos completos de un empleado.

    public static class Datos {

        public long id;
        public String nombres, apellidos, tipoDocumento, numeroDocumento;
        public String sujetoIdentidad, telefono, correo, fechaNacimiento;
        public String registroProfesional, nombreTurno;
        public Long idTurno;
        public int activo;
        public ArrayList<Long> idsRoles = new ArrayList<>();
    }

// Conserva el ID real y el nombre de cada turno.
    public static class DatosTurno {

        public long id;
        public String nombre;

        public DatosTurno(long id, String nombre) {
            this.id = id;
            this.nombre = nombre;
        }
    }

    public static class DatosRol {

        public long id;
        public String nombre;

        public DatosRol(long id, String nombre) {
            this.id = id;
            this.nombre = nombre;
        }
    }

// Lista activos e inactivos para poder comprobar la desactivación.
    public ArrayList<Datos> listar() throws SQLException {
        ArrayList<Datos> lista = new ArrayList<>();

        String sql = "SELECT u.*, t.nombre AS nombre_turno "
                + "FROM Usuario u "
                + "LEFT JOIN Turno t ON t.id_turno = u.id_turno "
                + "ORDER BY u.apellidos, u.nombres, u.id_usuario";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql); ResultSet resultado = consulta.executeQuery()) {
            while (resultado.next()) {
                Datos datos = new Datos();

                datos.id = resultado.getLong("id_usuario");
                datos.nombres = resultado.getString("nombres");
                datos.apellidos = resultado.getString("apellidos");
                datos.tipoDocumento = resultado.getString("tipo_documento");
                datos.numeroDocumento = resultado.getString("numero_documento");
                datos.sujetoIdentidad = resultado.getString("sujeto_identidad");
                datos.telefono = resultado.getString("telefono");
                datos.correo = resultado.getString("correo");
                datos.fechaNacimiento = resultado.getString("fecha_nacimiento");
                datos.registroProfesional
                        = resultado.getString("registro_profesional");
                datos.activo = resultado.getInt("activo");
                datos.nombreTurno = resultado.getString("nombre_turno");

                long turno = resultado.getLong("id_turno");
                datos.idTurno = resultado.wasNull() ? null : Long.valueOf(turno);

                lista.add(datos);
            }
        }

        return lista;
    }

    public ArrayList<DatosTurno> listarTurnos() throws SQLException {
        ArrayList<DatosTurno> lista = new ArrayList<>();

        String sql = "SELECT id_turno, nombre FROM Turno "
                + "ORDER BY nombre, id_turno";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql); ResultSet resultado = consulta.executeQuery()) {
            while (resultado.next()) {
                lista.add(new DatosTurno(
                        resultado.getLong("id_turno"),
                        resultado.getString("nombre")
                ));
            }
        }

        return lista;
    }

// Comprueba los campos obligatorios.
    private String obligatorio(String valor, String campo, int limite) {
        String limpio = valor == null ? "" : valor.trim();

        if (limpio.isEmpty()) {
            throw new IllegalArgumentException(
                    "Debes completar el campo: " + campo + "."
            );
        }

        if (limpio.length() > limite) {
            throw new IllegalArgumentException(
                    campo + " admite máximo " + limite + " caracteres."
            );
        }

        return limpio;
    }

// Un campo opcional vacío se guarda como NULL.
    private String opcional(String valor, String campo, int limite) {
        if (valor == null || valor.trim().isEmpty()) {
            return null;
        }

        return obligatorio(valor, campo, limite);
    }

    private void validarDatos(Datos datos) {
        datos.nombres = obligatorio(datos.nombres, "Nombres", 100);
        datos.apellidos = obligatorio(datos.apellidos, "Apellidos", 100);
        datos.tipoDocumento = obligatorio(
                datos.tipoDocumento, "Tipo de documento", 10
        ).toUpperCase(java.util.Locale.ROOT);

        datos.numeroDocumento = obligatorio(
                datos.numeroDocumento, "Número de documento", 30
        );

        datos.sujetoIdentidad = obligatorio(
                datos.sujetoIdentidad, "Sujeto de identidad", Integer.MAX_VALUE
        );

        datos.telefono = opcional(datos.telefono, "Teléfono", 30);
        datos.correo = opcional(datos.correo, "Correo", 254);
        datos.registroProfesional = opcional(
                datos.registroProfesional, "Registro profesional",
                Integer.MAX_VALUE
        );

        datos.fechaNacimiento = opcional(
                datos.fechaNacimiento, "Fecha de nacimiento", 10
        );

        if (datos.fechaNacimiento != null) {
            try {
                java.time.LocalDate fecha
                        = java.time.LocalDate.parse(datos.fechaNacimiento);

                if (!fecha.toString().equals(datos.fechaNacimiento)) {
                    throw new IllegalArgumentException(
                            "La fecha debe tener el formato AAAA-MM-DD."
                    );
                }

                if (fecha.isAfter(java.time.LocalDate.now())) {
                    throw new IllegalArgumentException(
                            "La fecha de nacimiento no puede ser futura."
                    );
                }
            } catch (java.time.format.DateTimeParseException error) {
                throw new IllegalArgumentException(
                        "Escribe una fecha válida con formato AAAA-MM-DD."
                );
            }
        }
    }

// Estos parámetros se utilizan al registrar y al actualizar.
    private void asignarDatos(PreparedStatement consulta, Datos datos)
            throws SQLException {

        consulta.setString(1, datos.nombres);
        consulta.setString(2, datos.apellidos);
        consulta.setString(3, datos.tipoDocumento);
        consulta.setString(4, datos.numeroDocumento);
        consulta.setString(5, datos.sujetoIdentidad);
        consulta.setString(6, datos.telefono);
        consulta.setString(7, datos.correo);
        consulta.setString(8, datos.fechaNacimiento);
        consulta.setString(9, datos.registroProfesional);

        if (datos.idTurno == null) {
            consulta.setNull(10, java.sql.Types.INTEGER);
        } else {
            consulta.setLong(10, datos.idTurno);
        }
    }

    public void registrar(Datos datos) throws SQLException {
        validarDatos(datos);

        if (datos.idsRoles == null || datos.idsRoles.isEmpty()) {
            throw new IllegalArgumentException(
                    "Selecciona al menos un rol para el usuario."
            );
        }

        // Evita intentar guardar dos veces el mismo rol.
        java.util.LinkedHashSet<Long> rolesUnicos
                = new java.util.LinkedHashSet<>(datos.idsRoles);

        for (Long idRol : rolesUnicos) {
            if (idRol == null) {
                throw new IllegalArgumentException(
                        "La selección de roles contiene un valor inválido."
                );
            }
        }

        String sqlUsuario = "INSERT INTO Usuario "
                + "(nombres, apellidos, tipo_documento, numero_documento, "
                + "sujeto_identidad, telefono, correo, fecha_nacimiento, "
                + "registro_profesional, id_turno, activo) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)";

        String sqlRol = "INSERT INTO Usuario_Rol "
                + "(id_usuario, id_rol) VALUES (?, ?)";

        try (Connection conexion = new cConexion().conectar()) {

            // Desde aquí, los cambios quedan pendientes de confirmación.
            conexion.setAutoCommit(false);

            try {
                // 1. Registrar al empleado.
                try (
                        PreparedStatement consulta
                        = conexion.prepareStatement(sqlUsuario)) {
                    asignarDatos(consulta, datos);
                    consulta.executeUpdate();
                }

                // 2. Obtener su ID usando la misma conexión.
                long idUsuario;

                try (
                        PreparedStatement consulta = conexion.prepareStatement(
                                "SELECT last_insert_rowid()"
                        ); ResultSet resultado = consulta.executeQuery()) {
                            if (!resultado.next()) {
                                throw new SQLException(
                                        "No se pudo obtener el ID del usuario registrado."
                                );
                            }

                            idUsuario = resultado.getLong(1);
                        }

                        // 3. Asociar los roles con ese empleado.
                        try (
                                PreparedStatement consulta
                                = conexion.prepareStatement(sqlRol)) {
                            for (Long idRol : rolesUnicos) {
                                consulta.setLong(1, idUsuario);
                                consulta.setLong(2, idRol);
                                consulta.executeUpdate();
                            }
                        }

                        // 4. Confirmar únicamente cuando todo salió bien.
                        conexion.commit();

            } catch (SQLException | RuntimeException error) {

                // Si algo falla, deshacer usuario y asociaciones.
                try {
                    conexion.rollback();
                } catch (SQLException errorAlDeshacer) {
                    error.addSuppressed(errorAlDeshacer);
                }

                throw error;
            }
        }
    }

    public void actualizar(long idUsuario, Datos datos) throws SQLException {
        validarDatos(datos);

        if (datos.activo != 0 && datos.activo != 1) {
            throw new IllegalArgumentException(
                    "El estado del usuario debe ser activo o inactivo."
            );
        }

        String sql = "UPDATE Usuario SET nombres = ?, apellidos = ?, "
                + "tipo_documento = ?, numero_documento = ?, "
                + "sujeto_identidad = ?, telefono = ?, correo = ?, "
                + "fecha_nacimiento = ?, registro_profesional = ?, "
                + "id_turno = ?, activo = ? "
                + "WHERE id_usuario = ?";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql)) {
            // Completa los primeros diez parámetros.
            asignarDatos(consulta, datos);

            // Guarda el estado seleccionado.
            consulta.setInt(11, datos.activo);

            // Identifica al empleado por su ID real.
            consulta.setLong(12, idUsuario);

            if (consulta.executeUpdate() != 1) {
                throw new SQLException(
                        "No se encontró el usuario. Recarga la lista."
                );
            }
        }
    }

    public void desactivar(long idUsuario) throws SQLException {
        String sql = "UPDATE Usuario SET activo = 0 "
                + "WHERE id_usuario = ? AND activo = 1";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql)) {
            consulta.setLong(1, idUsuario);

            if (consulta.executeUpdate() != 1) {
                throw new SQLException(
                        "El usuario ya estaba inactivo o no existe. Recarga la lista."
                );
            }
        }
    }

    public ArrayList<DatosRol> listarRoles() throws SQLException {
        ArrayList<DatosRol> lista = new ArrayList<>();

        String sql = "SELECT id_rol, nombre FROM Rol "
                + "ORDER BY nombre, id_rol";

        try (
                Connection conexion = new cConexion().conectar(); PreparedStatement consulta = conexion.prepareStatement(sql); ResultSet resultado = consulta.executeQuery()) {
            while (resultado.next()) {
                lista.add(new DatosRol(
                        resultado.getLong("id_rol"),
                        resultado.getString("nombre")
                ));
            }
        }

        return lista;
    }
}
