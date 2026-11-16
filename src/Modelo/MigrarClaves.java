package Modelo;

import Conexion.cConexion;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MigrarClaves {

    public static void main(String[] args) throws SQLException {

        try (Connection con = new cConexion().conectar()) {
            con.setAutoCommit(false);

            try {
                List<Long> ids = new ArrayList<>();
                List<String> hashes = new ArrayList<>();

                try (
                    PreparedStatement ps = con.prepareStatement(
                            "SELECT id_usuario, contrasena FROM Usuario"
                    );
                    ResultSet rs = ps.executeQuery()
                ) {
                    while (rs.next()) {
                        String clave = rs.getString("contrasena");

                        if (clave == null || clave.isBlank()
                                || cClaves.esHash(clave)) {
                            continue;
                        }

                        ids.add(rs.getLong("id_usuario"));
                        hashes.add(cClaves.generar(clave));
                    }
                }

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE Usuario SET contrasena=? WHERE id_usuario=?"
                )) {
                    for (int i = 0; i < ids.size(); i++) {
                        ps.setString(1, hashes.get(i));
                        ps.setLong(2, ids.get(i));
                        ps.addBatch();
                    }

                    ps.executeBatch();
                }

                con.commit();

                System.out.println(
                        "Contraseñas convertidas: " + ids.size()
                );

            } catch (SQLException | RuntimeException error) {
                try {
                    con.rollback();
                } catch (SQLException otro) {
                    error.addSuppressed(otro);
                }

                throw error;
            }
        }
    }
}