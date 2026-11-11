package Modelo;

import Conexion.cConexion;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.ResolverStyle;
import java.util.ArrayList;
import java.util.List;

/** Operaciones para el futuro diálogo. No contiene botones ni abre ventanas. */
public class cOrdenMedica {
    private static final DateTimeFormatter UTC = DateTimeFormatter
            .ofPattern("uuuu-MM-dd HH:mm:ss").withResolverStyle(ResolverStyle.STRICT);

    public record ServicioOpcion(long idServicio, String nombre, String tipo) {
        @Override public String toString() { return nombre + " (" + tipo + ")"; }
    }

    // Las fechas se reciben ya convertidas a UTC. finUTC puede ser null.
    public record DatosPrescripcion(double dosis, String unidadDosis, String via,
            String frecuencia, String inicioUTC, String finUTC) { }

    // prescripcion debe ser null si el servicio no es un MEDICAMENTO.
    public record DetalleEntrada(long idServicio, double cantidad,
            String indicaciones, DatosPrescripcion prescripcion) { }

    public record ResumenOrden(long idOrden, long idUsuario, String autor,
            String prioridad, String estado, String emitidaEn, int detalles) { }

    public record DetalleGuardado(long idDetalle, long idServicio, String servicio,
            String tipo, double cantidad, String indicaciones, String estado,
            DatosPrescripcion prescripcion) { }

    public List<ServicioOpcion> listarServiciosActivos() throws SQLException {
        List<ServicioOpcion> lista = new ArrayList<>();
        try (Connection c = new cConexion().conectar();
                PreparedStatement p = c.prepareStatement(
                        "SELECT id_servicio,nombre,tipo FROM Servicio WHERE activo=1 ORDER BY nombre");
                ResultSet r = p.executeQuery()) {
            while (r.next()) lista.add(new ServicioOpcion(r.getLong(1),r.getString(2),r.getString(3)));
        }
        return lista;
    }

    public List<ResumenOrden> listarOrdenes(long idEpisodio) throws SQLException {
        List<ResumenOrden> lista = new ArrayList<>();
        String sql = "SELECT o.*, u.nombres || ' ' || u.apellidos AS autor, "
                + "(SELECT COUNT(*) FROM Detalle_Orden d WHERE d.id_orden_medica=o.id_orden_medica) AS detalles "
                + "FROM Orden_Medica o JOIN Usuario u ON u.id_usuario=o.id_usuario "
                + "WHERE o.id_episodio=? ORDER BY o.id_orden_medica DESC";
        try (Connection c=new cConexion().conectar(); PreparedStatement p=c.prepareStatement(sql)) {
            p.setLong(1,idEpisodio);
            try (ResultSet r=p.executeQuery()) {
                while(r.next()) lista.add(new ResumenOrden(r.getLong("id_orden_medica"),
                        r.getLong("id_usuario"),r.getString("autor"),r.getString("prioridad"),
                        r.getString("estado"),r.getString("emitida_en"),r.getInt("detalles")));
            }
        }
        return lista;
    }

    // Se exige también el episodio para no abrir por accidente una orden de otra atención.
    public List<DetalleGuardado> listarDetalles(long idOrden, long idEpisodio) throws SQLException {
        List<DetalleGuardado> lista=new ArrayList<>();
        String sql="SELECT d.*, s.nombre, s.tipo, p.id_prescripcion, p.dosis, p.unidad_dosis, "
                + "p.via, p.frecuencia, p.inicio, p.fin FROM Detalle_Orden d "
                + "JOIN Servicio s ON s.id_servicio=d.id_servicio "
                + "JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica "
                + "LEFT JOIN Prescripcion p ON p.id_detalle_orden=d.id_detalle_orden "
                + "WHERE o.id_orden_medica=? AND o.id_episodio=? ORDER BY d.id_detalle_orden";
        try(Connection c=new cConexion().conectar()) {
            exigirExiste(c,"SELECT 1 FROM Orden_Medica WHERE id_orden_medica=? AND id_episodio=?",
                    "La orden no pertenece a esta atención.",idOrden,idEpisodio);
            try(PreparedStatement p=c.prepareStatement(sql)) {
                p.setLong(1,idOrden);p.setLong(2,idEpisodio);
                try(ResultSet r=p.executeQuery()) {
                    while(r.next()) {
                        DatosPrescripcion receta=null;
                        if(r.getObject("id_prescripcion")!=null) receta=new DatosPrescripcion(
                                r.getDouble("dosis"),r.getString("unidad_dosis"),r.getString("via"),
                                r.getString("frecuencia"),r.getString("inicio"),r.getString("fin"));
                        lista.add(new DetalleGuardado(r.getLong("id_detalle_orden"),r.getLong("id_servicio"),
                                r.getString("nombre"),r.getString("tipo"),r.getDouble("cantidad"),
                                r.getString("indicaciones"),r.getString("estado"),receta));
                    }
                }
            }
        }
        return lista;
    }

    /** Crea una orden NUEVA con todos sus detalles. No emite ni firma. */
    public long guardarBorrador(long idUsuarioAutor, long idEpisodio,
            String prioridad, List<DetalleEntrada> detalles) throws SQLException {
        if(idUsuarioAutor<=0 || idEpisodio<=0) throw new IllegalArgumentException(
                "La orden necesita el usuario autor y el episodio de la atención.");
        String prioridadLimpia=obligatorio(prioridad,"Selecciona la prioridad.");
        if(detalles==null || detalles.isEmpty()) throw new IllegalArgumentException("Añade al menos un detalle.");
        List<DetalleEntrada> copia=new ArrayList<>(detalles);
        for(DetalleEntrada d:copia) validarDetalle(d);
        try(Connection c=new cConexion().conectar()) {
            c.setAutoCommit(false);
            try {
                exigirExiste(c,"SELECT 1 FROM Usuario WHERE id_usuario=? AND activo=1",
                        "El usuario autor no existe o está inactivo.",idUsuarioAutor);
                exigirExiste(c, "SELECT 1 FROM Episodio WHERE id_episodio=?",
                        "El episodio clínico especificado no existe.", idEpisodio);
                long idOrden;
                try(PreparedStatement p=c.prepareStatement(
                        "INSERT INTO Orden_Medica(prioridad,estado,id_usuario,id_episodio) VALUES (?,'BORRADOR',?,?)")) {
                    p.setString(1,prioridadLimpia);p.setLong(2,idUsuarioAutor);p.setLong(3,idEpisodio);
                    p.executeUpdate();idOrden=ultimoId(c);
                }
                for(DetalleEntrada d:copia) {
                    String tipo;
                    try(PreparedStatement p=c.prepareStatement("SELECT tipo FROM Servicio WHERE id_servicio=? AND activo=1")) {
                        p.setLong(1,d.idServicio());
                        try(ResultSet r=p.executeQuery()) {
                            if(!r.next()) throw new IllegalArgumentException("El servicio "+d.idServicio()+" no está activo.");
                            tipo=r.getString(1);
                        }
                    }
                    // Coincide con las reglas exactas de la base, sin cambiar nombres del catálogo.
                    if("MEDICAMENTO".equals(tipo) && d.prescripcion()==null) throw new IllegalArgumentException(
                            "Completa la prescripción del medicamento "+d.idServicio()+".");
                    if(!"MEDICAMENTO".equals(tipo) && d.prescripcion()!=null) throw new IllegalArgumentException(
                            "Una prescripción solo puede acompañar un MEDICAMENTO.");
                    long idDetalle;
                    try(PreparedStatement p=c.prepareStatement(
                            "INSERT INTO Detalle_Orden(cantidad,indicaciones,estado,id_servicio,id_orden_medica) "
                            + "VALUES (?,?,'PENDIENTE',?,?)")) {
                        p.setDouble(1,d.cantidad());p.setString(2,opcional(d.indicaciones()));
                        p.setLong(3,d.idServicio());p.setLong(4,idOrden);
                        p.executeUpdate();idDetalle=ultimoId(c);
                    }
                    if(d.prescripcion()!=null) insertarPrescripcion(c,idDetalle,d.prescripcion());
                }
                c.commit();
                return idOrden;
            } catch(SQLException | RuntimeException error) {
                try { c.rollback(); } catch(SQLException otro) { error.addSuppressed(otro); }
                throw error;
            }
        }
    }

    private void insertarPrescripcion(Connection c,long idDetalle,DatosPrescripcion d) throws SQLException {
        String sql="INSERT INTO Prescripcion(dosis,unidad_dosis,via,frecuencia,inicio,fin,id_detalle_orden) "
                + "VALUES (?,?,?,?,?,?,?)";
        try(PreparedStatement p=c.prepareStatement(sql)) {
            p.setDouble(1,d.dosis());p.setString(2,d.unidadDosis().trim());p.setString(3,d.via().trim());
            p.setString(4,d.frecuencia().trim());p.setString(5,d.inicioUTC().trim());
            p.setString(6,opcional(d.finUTC()));p.setLong(7,idDetalle);p.executeUpdate();
        }
    }

    private void validarDetalle(DetalleEntrada d) {
        if(d==null || d.idServicio()<=0) throw new IllegalArgumentException("Selecciona un servicio por detalle.");
        positivo(d.cantidad(),"La cantidad");
        DatosPrescripcion p=d.prescripcion();
        if(p!=null) {
            positivo(p.dosis(),"La dosis");
            obligatorio(p.unidadDosis(),"Indica la unidad de dosis.");
            obligatorio(p.via(),"Indica la vía.");
            obligatorio(p.frecuencia(),"Indica la frecuencia.");
            LocalDateTime inicio=fecha(p.inicioUTC(),"inicio");
            String fin=opcional(p.finUTC());
            if(fin!=null && fecha(fin,"fin").isBefore(inicio)) throw new IllegalArgumentException(
                    "El fin de la prescripción no puede ser anterior al inicio.");
        }
    }

    private static LocalDateTime fecha(String valor,String campo) {
        String texto=obligatorio(valor,"Indica la fecha de "+campo+" en UTC.");
        try {
            LocalDateTime fecha=LocalDateTime.parse(texto,UTC);
            if(texto.length()!=19 || !fecha.format(UTC).equals(texto)) throw new IllegalArgumentException();
            return fecha;
        } catch(RuntimeException error) {
            throw new IllegalArgumentException("La fecha de "+campo+" debe ser válida y tener formato AAAA-MM-DD HH:mm:ss (UTC).");
        }
    }

    private static void positivo(double valor,String campo) {
        if(!Double.isFinite(valor) || valor<=0 || valor>=1.0e12) throw new IllegalArgumentException(
                campo+" debe ser mayor que cero y menor que 1.000.000.000.000.");
    }

    private static String obligatorio(String texto,String mensaje) {
        if(texto==null || texto.isBlank()) throw new IllegalArgumentException(mensaje);
        return texto.trim();
    }

    private static String opcional(String texto) { return texto==null || texto.isBlank()?null:texto.trim(); }

    private static long ultimoId(Connection c) throws SQLException {
        try(PreparedStatement p=c.prepareStatement("SELECT last_insert_rowid()");ResultSet r=p.executeQuery()) {
            if(!r.next()) throw new SQLException("No se recuperó el identificador guardado.");
            return r.getLong(1);
        }
    }

    private static void exigirExiste(Connection c,String sql,String mensaje,long... ids) throws SQLException {
        try(PreparedStatement p=c.prepareStatement(sql)) {
            for(int i=0;i<ids.length;i++) p.setLong(i+1,ids[i]);
            try(ResultSet r=p.executeQuery()) { if(!r.next()) throw new IllegalArgumentException(mensaje); }
        }
    }
}
