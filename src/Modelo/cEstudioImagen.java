package Modelo;

import Conexion.cConexion;
import java.sql.*;
import java.util.*;
import java.time.*;
import java.time.format.*;

public class cEstudioImagen {
    public record Opcion(long id, String texto) { @Override public String toString(){return texto;} }
    public record Estudio(long id,String fecha,String modalidad,String servicio,String estado,
            String referencia,String informe,String pdf) { }
    private static final String ORIGEN=" FROM Detalle_Orden d JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica "
            + "JOIN Episodio e ON e.id_episodio=o.id_episodio JOIN Historia_Clinica h ON h.id_historia_clinica=e.id_historia_clinica "
            + "JOIN Servicio s ON s.id_servicio=d.id_servicio ";
    public List<Opcion> ordenes(long paciente) throws SQLException {
        String sql="SELECT d.id_detalle_orden, s.nombre, o.id_orden_medica"+ORIGEN
                + "WHERE h.id_paciente=? AND o.estado='EMITIDA' AND s.tipo IN ('IMAGEN','IMAGENOLOGIA') "
                + "AND NOT EXISTS(SELECT 1 FROM Estudio_Imagen x WHERE x.id_detalle_orden=d.id_detalle_orden) ORDER BY d.id_detalle_orden";
        List<Opcion> lista=new ArrayList<>();
        try(Connection c=new cConexion().conectar();PreparedStatement ps=c.prepareStatement(sql)) {
            ps.setLong(1,paciente);try(ResultSet r=ps.executeQuery()) {
                while(r.next())lista.add(new Opcion(r.getLong(1),"Orden "+r.getLong(3)+" / detalle "+r.getLong(1)+" — "+r.getString(2)));
            }
        }return lista;
    }
    public List<Opcion> sistemas() throws SQLException {
        List<Opcion> lista=new ArrayList<>();
        try(Connection c=new cConexion().conectar();Statement st=c.createStatement();ResultSet r=st.executeQuery(
                "SELECT id_sistema_externo,nombre FROM Sistema_Externo WHERE upper(tipo) IN ('PACS','IMAGEN','IMAGENOLOGIA') ORDER BY nombre")) {
            while(r.next())lista.add(new Opcion(r.getLong(1),r.getString(2)));
        }return lista;
    }
    public List<Estudio> listar(long paciente) throws SQLException {
        String sql="SELECT x.*,s.nombre"+ORIGEN+"JOIN Estudio_Imagen x ON x.id_detalle_orden=d.id_detalle_orden "
                + "WHERE h.id_paciente=? ORDER BY x.realizado_en DESC,x.id_estudio_imagen DESC";
        List<Estudio> lista=new ArrayList<>();
        try(Connection c=new cConexion().conectar();PreparedStatement ps=c.prepareStatement(sql)) {
            ps.setLong(1,paciente);try(ResultSet r=ps.executeQuery()) {
                while(r.next()) {
                    StringBuilder informes=new StringBuilder();String pdf=null;
                    try(PreparedStatement pi=c.prepareStatement("SELECT i.*,u.nombres||' '||u.apellidos autor FROM Informe_Imagen i JOIN Usuario u ON u.id_usuario=i.id_usuario WHERE id_estudio_imagen=? ORDER BY i.creado_en DESC,i.id_informe DESC")) {
                        pi.setLong(1,r.getLong("id_estudio_imagen"));try(ResultSet ri=pi.executeQuery()) {
                            boolean primero=true;
                            while(ri.next()) {
                                if(primero){pdf=ri.getString("referencia_pdf");primero=false;}
                                informes.append("Versión ").append(ri.getString("version")).append(" · ").append(ri.getString("estado"))
                                        .append(" · ").append(ri.getString("autor")).append("\nHallazgos: ")
                                        .append(Objects.toString(ri.getString("hallazgos"),"Sin registrar")).append("\nConclusión: ")
                                        .append(Objects.toString(ri.getString("conclusion"),"Sin registrar")).append("\n\n");
                            }
                        }
                    }
                    lista.add(new Estudio(r.getLong("id_estudio_imagen"),r.getString("realizado_en"),r.getString("modalidad"),
                            r.getString("nombre"),r.getString("estado"),r.getString("referencia_pacs"),
                            informes.length()==0?"Sin informe registrado.":informes.toString(),pdf));
                }
            }
        }return lista;
    }
    public long guardar(long paciente,long detalle,long sistema,long autor,String uid,String modalidad,
            String fechaUTC,String referencia,String hallazgos,String conclusion,String pdf) throws SQLException {
        uid=obligatorio(uid,"UID");modalidad=obligatorio(modalidad,"modalidad");
        referencia=obligatorio(referencia,"archivo del estudio");hallazgos=obligatorio(hallazgos,"hallazgos");
        conclusion=obligatorio(conclusion,"conclusión");
        if(uid.length()>64 || !uid.matches("[0-9]+(\\.[0-9]+)*"))throw new IllegalArgumentException("El UID debe ser numérico, separado por puntos y de máximo 64 caracteres.");
        DateTimeFormatter f=DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss").withResolverStyle(ResolverStyle.STRICT);
        if(LocalDateTime.parse(fechaUTC,f).isAfter(LocalDateTime.now(ZoneOffset.UTC)))throw new IllegalArgumentException("El estudio realizado no puede tener una fecha futura.");
        try(Connection c=new cConexion().conectar()) {
            c.setAutoCommit(false);
            try {
                exigir(c,"SELECT 1 FROM Usuario WHERE id_usuario=? AND activo=1",autor,"Inicia sesión con un usuario activo.");
                exigir(c,"SELECT 1 FROM Sistema_Externo WHERE id_sistema_externo=? AND upper(tipo) IN ('PACS','IMAGEN','IMAGENOLOGIA')",sistema,"Selecciona un sistema de imágenes.");
                try(PreparedStatement ps=c.prepareStatement("SELECT 1"+ORIGEN+"WHERE d.id_detalle_orden=? AND h.id_paciente=? AND o.estado='EMITIDA' AND s.tipo IN ('IMAGEN','IMAGENOLOGIA') AND NOT EXISTS(SELECT 1 FROM Estudio_Imagen x WHERE x.id_detalle_orden=d.id_detalle_orden)")) {
                    ps.setLong(1,detalle);ps.setLong(2,paciente);try(ResultSet r=ps.executeQuery()) {
                        if(!r.next())throw new IllegalArgumentException("La orden no está emitida, no pertenece al paciente, no es de imágenes o ya tiene un estudio.");
                    }
                }
                long id;
                try(PreparedStatement ps=c.prepareStatement("INSERT INTO Estudio_Imagen(study_instance_uid,modalidad,referencia_pacs,realizado_en,estado,id_sistema_externo,id_detalle_orden) VALUES(?,?,?,?,'REALIZADO',?,?)")) {
                    ps.setString(1,uid);ps.setString(2,modalidad);ps.setString(3,referencia);ps.setString(4,fechaUTC);
                    ps.setLong(5,sistema);ps.setLong(6,detalle);ps.executeUpdate();
                }
                try(Statement st=c.createStatement();ResultSet r=st.executeQuery("SELECT last_insert_rowid()")){r.next();id=r.getLong(1);}
                try(PreparedStatement ps=c.prepareStatement("INSERT INTO Informe_Imagen(version,hallazgos,conclusion,referencia_pdf,estado,id_estudio_imagen,id_usuario) VALUES('1',?,?,?,'BORRADOR',?,?)")) {
                    ps.setString(1,hallazgos);ps.setString(2,conclusion);ps.setString(3,pdf==null||pdf.isBlank()?null:pdf.trim());
                    ps.setLong(4,id);ps.setLong(5,autor);ps.executeUpdate();
                }
                c.commit();return id;
            }catch(SQLException|RuntimeException e){try{c.rollback();}catch(SQLException otro){e.addSuppressed(otro);}throw e;}
        }
    }
    private static String obligatorio(String s,String nombre){if(s==null||s.isBlank())throw new IllegalArgumentException("Completa "+nombre+".");return s.trim();}
    private static void exigir(Connection c,String sql,long id,String mensaje)throws SQLException{
        try(PreparedStatement p=c.prepareStatement(sql)){p.setLong(1,id);try(ResultSet r=p.executeQuery()){if(!r.next())throw new IllegalArgumentException(mensaje);}}
    }
}
