package Modelo;

import Conexion.cConexion;
import java.sql.*;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

public class cFacturacion {
    public record FacturaFila(long id, String numero, String fecha, String paciente,
            String documento, String estado, String moneda, BigDecimal total,
            BigDecimal pagado, BigDecimal saldo) { }
    public record PrestacionFila(long id, String servicio, String fecha, BigDecimal cantidad) { }
    public record Concepto(long idPrestacion, BigDecimal precioUnitario) { }
    public record DetalleFila(String descripcion, BigDecimal cantidad,
            BigDecimal precio, BigDecimal subtotal) { }

    public List<FacturaFila> listar(String documento, String fecha) throws SQLException {
        if (!fecha.isBlank()) java.time.LocalDate.parse(fecha);
        String sql="SELECT r.*, f.emitida_en, p.nombres||' '||p.apellidos paciente, p.numero_documento "
                + "FROM V_Resumen_Factura r JOIN Factura f USING(id_factura) "
                + "JOIN Paciente p ON p.id_paciente=r.id_paciente "
                + "WHERE (?='' OR p.numero_documento=?) "
                + "AND (?='' OR date(f.emitida_en,'-5 hours')=?) ORDER BY r.id_factura DESC";
        List<FacturaFila> lista=new ArrayList<>();
        try(Connection c=new cConexion().conectar();PreparedStatement ps=c.prepareStatement(sql)) {
            ps.setString(1,documento);ps.setString(2,documento);ps.setString(3,fecha);ps.setString(4,fecha);
            try(ResultSet r=ps.executeQuery()) {
                while(r.next()) lista.add(new FacturaFila(r.getLong("id_factura"),r.getString("numero"),
                        r.getString("emitida_en"),r.getString("paciente"),r.getString("numero_documento"),
                        r.getString("estado"),r.getString("moneda"),dinero(r.getString("total_centavos")),
                        dinero(r.getString("pagado_centavos")),dinero(r.getString("saldo_centavos"))));
            }
        }
        return lista;
    }
    private static BigDecimal dinero(String valor) { return new BigDecimal(valor).movePointLeft(2); }

    public List<DetalleFila> detalles(long idFactura) throws SQLException {
        List<DetalleFila> lista=new ArrayList<>();
        try(Connection c=new cConexion().conectar();PreparedStatement ps=c.prepareStatement(
                "SELECT * FROM V_Detalle_Factura WHERE id_factura=? ORDER BY id_detalle_factura")) {
            ps.setLong(1,idFactura);
            try(ResultSet r=ps.executeQuery()) {
                while(r.next()) lista.add(new DetalleFila(r.getString("descripcion"),
                        new BigDecimal(r.getString("cantidad_milesimas")).movePointLeft(3),
                        dinero(r.getString("precio_unitario_centavos")),dinero(r.getString("subtotal_centavos"))));
            }
        }
        return lista;
    }

    private static final String DISPONIBLES="SELECT p.id_prestacion, s.nombre, p.realizada_en, p.cantidad "
            + "FROM Prestacion p JOIN Servicio s ON s.id_servicio=p.id_servicio "
            + "JOIN Episodio e ON e.id_episodio=p.id_episodio "
            + "JOIN Historia_Clinica h ON h.id_historia_clinica=e.id_historia_clinica "
            + "WHERE h.id_paciente=? AND p.estado='REALIZADA' "
            + "AND NOT EXISTS(SELECT 1 FROM Detalle_Factura d WHERE d.id_prestacion=p.id_prestacion)";

    public List<PrestacionFila> disponibles(long idPaciente) throws SQLException {
        List<PrestacionFila> lista=new ArrayList<>();
        try(Connection c=new cConexion().conectar();PreparedStatement ps=c.prepareStatement(DISPONIBLES+" ORDER BY p.realizada_en")) {
            ps.setLong(1,idPaciente);
            try(ResultSet r=ps.executeQuery()) {
                while(r.next()) lista.add(new PrestacionFila(r.getLong(1),r.getString(2),r.getString(3),new BigDecimal(r.getString(4))));
            }
        }
        return lista;
    }

    public long guardarBorrador(long paciente, String moneda, List<Concepto> conceptos) throws SQLException {
        if(paciente<=0 || moneda==null || !moneda.matches("[A-Z]{3}")) throw new IllegalArgumentException("Selecciona paciente y moneda.");
        if(conceptos==null || conceptos.isEmpty()) throw new IllegalArgumentException("Selecciona al menos una prestación.");
        List<Concepto> entradas=List.copyOf(conceptos);
        Set<Long> ids=new HashSet<>();
        for(Concepto d:entradas) {
            if(!ids.add(d.idPrestacion())) throw new IllegalArgumentException("Hay una prestación repetida.");
            centavos(d.precioUnitario());
        }
        try(Connection c=new cConexion().conectar()) {
            c.setAutoCommit(false);
            try {
                long id;
                try(PreparedStatement ps=c.prepareStatement("INSERT INTO Factura(estado,moneda,id_paciente) VALUES('BORRADOR',?,?)")) {
                    ps.setString(1,moneda);ps.setLong(2,paciente);ps.executeUpdate();
                }
                try(Statement st=c.createStatement();ResultSet r=st.executeQuery("SELECT last_insert_rowid()")) { r.next();id=r.getLong(1); }
                for(Concepto d:entradas) {
                    String nombre;long cantidad;
                    try(PreparedStatement ps=c.prepareStatement(DISPONIBLES+" AND p.id_prestacion=?")) {
                        ps.setLong(1,paciente);ps.setLong(2,d.idPrestacion());
                        try(ResultSet r=ps.executeQuery()) {
                            if(!r.next()) throw new IllegalArgumentException("La prestación "+d.idPrestacion()+" ya está facturada, no está realizada o es de otro paciente.");
                            nombre=r.getString(2);
                            try { cantidad=new BigDecimal(r.getString(4)).movePointRight(3).longValueExact(); }
                            catch(ArithmeticException ex) { throw new IllegalArgumentException("La cantidad admite como máximo tres decimales."); }
                            if(cantidad<1 || cantidad>100000000) throw new IllegalArgumentException("Cantidad fuera del límite de Detalle_Factura.");
                        }
                    }
                    try(PreparedStatement ps=c.prepareStatement("INSERT INTO Detalle_Factura(descripcion,cantidad_milesimas,precio_unitario_centavos,id_factura,id_prestacion) VALUES(?,?,?,?,?)")) {
                        ps.setString(1,nombre);ps.setLong(2,cantidad);ps.setLong(3,centavos(d.precioUnitario()));
                        ps.setLong(4,id);ps.setLong(5,d.idPrestacion());ps.executeUpdate();
                    }
                }
                c.commit();return id;
            } catch(SQLException|RuntimeException e) {
                try {c.rollback();}catch(SQLException otro){e.addSuppressed(otro);}throw e;
            }
        }
    }
    private static long centavos(BigDecimal precio) {
        if(precio==null) throw new IllegalArgumentException("Escribe el precio unitario de cada prestación seleccionada.");
        try {
            long n=precio.setScale(2,RoundingMode.UNNECESSARY).movePointRight(2).longValueExact();
            if(n<0 || n>10000000000L) throw new IllegalArgumentException("Precio fuera del límite permitido.");
            return n;
        }catch(ArithmeticException e){throw new IllegalArgumentException("El precio debe tener como máximo dos decimales y estar dentro del límite permitido.");}
    }
}
