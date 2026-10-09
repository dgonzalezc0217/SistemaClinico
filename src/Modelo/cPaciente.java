package Modelo;

import Conexion.cConexion;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.swing.JOptionPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;

public class cPaciente {

    private long idPaciente;
    private String nombres;
    private String apellidos;
    private String tipoDocumento;
    private String numeroDocumento;
    private String fechaNacimiento;
    private String tipoSangre;
    private String factorrh;
    private String sexo;
    private String telefono;
    private String correo;
    private String fechaCreacion;

    // Estado acordado para este ejercicio.
    private static final String ESTADO_IDENTIFICACION = "IDENTIFICADO";

    // Se usa para crear el objeto que realizará las consultas.
    public cPaciente() {
    }

    // Se usa para reunir los datos del paciente.
    public cPaciente(String nombres, String apellidos,
            String tipoDocumento, String numeroDocumento,String fechaNacimiento,String tipoSangre,String factorrh,String sexo,
            String telefono,String correo,String fechaCreacion) {

        this.nombres = nombres;
        this.apellidos = apellidos;
        this.tipoDocumento = tipoDocumento;
        this.numeroDocumento = numeroDocumento;
        this.fechaNacimiento = fechaNacimiento;
        this.tipoSangre = tipoSangre;
        this.factorrh = factorrh;
        this.sexo = sexo;
        this.telefono = telefono;
        this.correo = correo;
        this.fechaCreacion = fechaCreacion; 
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
    
    public String getfechaNacimiento() {
        return fechaNacimiento;
    }
    
    public String getTipoSangre() {
        return tipoSangre;
    }
    
    public String getFactorrh() {
        return factorrh;
    }

    public String getSexo() {
        return sexo;
    }

    public String getTelefono() {
        return telefono;
    }

    public String getCorreo() {
        return correo;
    }

    public String getfechaCreacion() {
        return fechaCreacion;
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

        String sql = "SELECT id_paciente, nombres, apellidos, tipo_documento, numero_documento, "
                    + "fecha_nacimiento, grupo_sanguineo, sexo, telefono, correo, creado_en "
                    + "FROM Paciente WHERE tipo_documento = ? AND numero_documento = ?";

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
                            resultado.getString("numero_documento"),
                            resultado.getString("fecha_nacimiento"),
                            resultado.getString("grupo_sanguineo"),
                            resultado.getString("factor_rh"),
                            resultado.getString("sexo"),
                            resultado.getString("telefono"),
                            resultado.getString("correo"),
                            resultado.getString("creado_en")
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
                        + "(nombres, apellidos, tipo_documento, numero_documento, "
                        + "fecha_nacimiento, grupo_sanguineo, factor_rh, sexo, telefono, correo, "
                        + "creado_en, estado_identificacion) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

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
                    consulta.setString(5, datos.fechaNacimiento);
                    consulta.setString(6, datos.tipoSangre);
                    consulta.setString(7, datos.factorrh);
                    consulta.setString(8, datos.sexo);
                    consulta.setString(9, datos.telefono);
                    consulta.setString(10, datos.correo);
                    consulta.setString(11, datos.fechaCreacion);
                    consulta.setString(12, ESTADO_IDENTIFICACION);

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
    
    public boolean actualizarPaciente(String tipoDocumento, String numeroDocumento, String nombres, String apellidos, 
                                      String fechaNacimiento, String tipoSangre, String factorrh, 
                                      String sexo, String telefono, String correo) {
        
        // La consulta SQL UPDATE. Usamos el WHERE para afectar solo al paciente que coincida con el documento.
        String sql = "UPDATE Paciente SET nombres = ?, apellidos = ?, fecha_nacimiento = ?, "
                   + "grupo_sanguineo = ?, factor_rh = ?, sexo = ?, telefono = ?, correo = ? "
                   + "WHERE tipo_documento = ? AND numero_documento = ?";
        
        // Usamos try-with-resources para manejar y cerrar la conexión automáticamente
        try (
            Connection conexion = new cConexion().conectar();
            PreparedStatement consulta = conexion.prepareStatement(sql)
        ) {
            // 1. Asignar los nuevos valores que van a reemplazar a los viejos
            consulta.setString(1, nombres);
            consulta.setString(2, apellidos);
            consulta.setString(3, fechaNacimiento);
            consulta.setString(4, tipoSangre);
            consulta.setString(5, factorrh);
            consulta.setString(6, sexo);
            consulta.setString(7, telefono);
            consulta.setString(8, correo);
            
            // 2. Asignar los datos del WHERE (para encontrar al paciente correcto)
            consulta.setString(9, tipoDocumento);
            consulta.setString(10, numeroDocumento);
            
            // Ejecutar la actualización en la base de datos
            int filasAfectadas = consulta.executeUpdate();
            
            // Si filasAfectadas es mayor a 0, significa que se encontró y actualizó el paciente
            return filasAfectadas > 0;
            
        } catch (SQLException e) {
            javax.swing.JOptionPane.showMessageDialog(null, "Error al actualizar el paciente: " + e.getMessage());
            return false;
        }
    }
    //Tabla
    public void mostrarPacientes(JTable tblPacientes) {
        
        // Crear un objeto para manejar la tabla y hacer que no sea editable
        DefaultTableModel modelo = new DefaultTableModel() {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false; // Retorna false para que ninguna celda pueda ser editada
            }
        };

        // Crear los títulos de las columnas coincidiendo con tu interfaz gráfica
        modelo.addColumn("Tipo documento");
        modelo.addColumn("Numero documento");
        modelo.addColumn("Nombres");
        modelo.addColumn("Apellidos");
        modelo.addColumn("Fecha de nacimiento");
        modelo.addColumn("Tipo de sangre");
        modelo.addColumn("Factor rh");
        modelo.addColumn("Sexo");
        modelo.addColumn("Telefono");
        modelo.addColumn("Correo");
        modelo.addColumn("Fecha de creacion");

        // Aplicamos el modelo vacío a la tabla visual
        tblPacientes.setModel(modelo);

        // Se asigna la consulta SQL especificando el orden exacto de las columnas
        String sql = "SELECT tipo_documento, numero_documento, nombres, apellidos, "
                + "fecha_nacimiento, grupo_sanguineo, factor_rh, sexo, telefono, correo, creado_en "
                + "FROM Paciente";

        // Arreglo con 10 espacios, uno para cada columna requerida
        String[] datos = new String[11];

        // Usamos try-with-resources para asegurar que la conexión se cierre correctamente
        try (
            Connection conexion = new cConexion().conectar();
            PreparedStatement consulta = conexion.prepareStatement(sql);
            ResultSet rs = consulta.executeQuery()
        ) {
            // Ciclo que se repetirá mientras encuentre resultados en la BD
            while (rs.next()) {
                // Extrae los valores usando el nombre de la columna para mayor seguridad
                datos[0] = rs.getString("tipo_documento");
                datos[1] = rs.getString("numero_documento");
                datos[2] = rs.getString("nombres");
                datos[3] = rs.getString("apellidos");
                datos[4] = rs.getString("fecha_nacimiento");
                datos[5] = rs.getString("grupo_sanguineo");
                datos[6] = rs.getString("factor_rh");
                datos[7] = rs.getString("sexo");
                datos[8] = rs.getString("telefono");
                datos[9] = rs.getString("correo");
                datos[10] = rs.getString("creado_en");
                
                // Añade la fila completa al modelo de la tabla
                modelo.addRow(datos);
            }
            
        } catch (SQLException er) {
            // Muestra una ventana emergente indicando que hubo un error 
            JOptionPane.showMessageDialog(null, "Error al cargar los pacientes de la base de datos: " + er.getMessage());
        }
    }
}