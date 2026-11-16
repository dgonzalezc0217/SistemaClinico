package Modelo;

import Conexion.cConexion;
import java.sql.*;
import java.util.*;

/** Consultas complementarias para conservar la pantalla PACS original. */
public class cPacsConsulta {
    public record Paciente(long id,String nombre,String documento,String telefono,
            String nacimiento,String sangre,String alergias) { }
    public Paciente paciente(long id) throws SQLException {
        String sql="SELECT p.*,h.id_historia_clinica FROM Paciente p LEFT JOIN Historia_Clinica h ON h.id_paciente=p.id_paciente WHERE p.id_paciente=?";
        try(Connection c=new cConexion().conectar();PreparedStatement ps=c.prepareStatement(sql)) {
            ps.setLong(1,id);try(ResultSet r=ps.executeQuery()){
                if(!r.next())throw new IllegalArgumentException("El paciente ya no existe.");
                StringJoiner alergias=new StringJoiner(", ");
                try(PreparedStatement pa=c.prepareStatement("SELECT sustancia FROM Alergia_Paciente WHERE id_historia_clinica=? AND estado='Confirmada'")) {
                    pa.setLong(1,r.getLong("id_historia_clinica"));try(ResultSet a=pa.executeQuery()){while(a.next())alergias.add(a.getString(1));}
                }
                return new Paciente(id,r.getString("nombres")+" "+r.getString("apellidos"),r.getString("numero_documento"),
                        r.getString("telefono"),r.getString("fecha_nacimiento"),Objects.toString(r.getString("grupo_sanguineo"),"")+Objects.toString(r.getString("factor_rh"),""),
                        alergias.length()==0?"Ninguna confirmada":alergias.toString());
            }
        }
    }
    public Map<Long,String> autores(long paciente)throws SQLException {
        String sql="SELECT x.id_estudio_imagen,u.nombres||' '||u.apellidos autor FROM Estudio_Imagen x "
                + "JOIN Detalle_Orden d ON d.id_detalle_orden=x.id_detalle_orden JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica "
                + "JOIN Episodio e ON e.id_episodio=o.id_episodio JOIN Historia_Clinica h ON h.id_historia_clinica=e.id_historia_clinica "
                + "LEFT JOIN Informe_Imagen i ON i.id_informe=(SELECT i2.id_informe FROM Informe_Imagen i2 WHERE i2.id_estudio_imagen=x.id_estudio_imagen ORDER BY i2.creado_en DESC,i2.id_informe DESC LIMIT 1) "
                + "LEFT JOIN Usuario u ON u.id_usuario=i.id_usuario WHERE h.id_paciente=?";
        Map<Long,String> m=new HashMap<>();
        try(Connection c=new cConexion().conectar();PreparedStatement p=c.prepareStatement(sql)) {
            p.setLong(1,paciente);try(ResultSet r=p.executeQuery()){while(r.next())m.put(r.getLong(1),Objects.toString(r.getString(2),"Sin informe"));}
        }return m;
    }
    public List<cEstudioImagen.Opcion> episodios(long paciente)throws SQLException {
        List<cEstudioImagen.Opcion> l=new ArrayList<>();
        try(Connection c=new cConexion().conectar();PreparedStatement p=c.prepareStatement(
                "SELECT e.id_episodio,e.ingreso_en,e.motivo_consulta FROM Episodio e JOIN Historia_Clinica h ON h.id_historia_clinica=e.id_historia_clinica WHERE h.id_paciente=? AND e.estado='ABIERTO' ORDER BY e.id_episodio DESC")){
            p.setLong(1,paciente);try(ResultSet r=p.executeQuery()){while(r.next())l.add(new cEstudioImagen.Opcion(r.getLong(1),"Episodio "+r.getLong(1)+" — "+r.getString(2)+" — "+r.getString(3)));}
        }return l;
    }
    public void anexar(long paciente,long episodio,long estudio)throws SQLException {
        try(Connection c=new cConexion().conectar()) {
            c.setAutoCommit(false);
            try {
                String sql="SELECT 1 FROM Episodio e JOIN Historia_Clinica h ON h.id_historia_clinica=e.id_historia_clinica WHERE e.id_episodio=? AND e.estado='ABIERTO' AND h.id_paciente=? AND EXISTS(" 
                        + "SELECT 1 FROM Estudio_Imagen x JOIN Detalle_Orden d ON d.id_detalle_orden=x.id_detalle_orden JOIN Orden_Medica o ON o.id_orden_medica=d.id_orden_medica JOIN Episodio origen ON origen.id_episodio=o.id_episodio WHERE x.id_estudio_imagen=? AND origen.id_historia_clinica=e.id_historia_clinica)";
                try(PreparedStatement p=c.prepareStatement(sql)) {
                    p.setLong(1,episodio);p.setLong(2,paciente);p.setLong(3,estudio);
                    try(ResultSet r=p.executeQuery()){if(!r.next())throw new IllegalArgumentException("El episodio debe estar abierto y pertenecer al mismo paciente del estudio.");}
                }
                try(PreparedStatement p=c.prepareStatement("INSERT INTO Episodio_Estudio_Imagen(id_episodio,id_estudio_imagen) VALUES(?,?) ON CONFLICT(id_episodio,id_estudio_imagen) DO NOTHING")){
                    p.setLong(1,episodio);p.setLong(2,estudio);p.executeUpdate();
                }
                c.commit();
            }catch(SQLException|RuntimeException e){try{c.rollback();}catch(SQLException otro){e.addSuppressed(otro);}throw e;}
        }
    }
}
