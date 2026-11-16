package Modelo;

import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public final class cClaves {

    private static final String PREFIJO = "pbkdf2$";
    private static final int ITERACIONES = 600_000;

    private cClaves() {
    }

    public static boolean esHash(String valor) {
        return valor != null && valor.startsWith(PREFIJO);
    }

    public static String generar(String clave) {
        if (clave == null || clave.isEmpty()) {
            throw new IllegalArgumentException("La contraseña es obligatoria.");
        }

        byte[] sal = new byte[16];
        new SecureRandom().nextBytes(sal);

        byte[] hash = calcular(clave, sal, ITERACIONES);

        return PREFIJO + ITERACIONES + "$"
                + Base64.getEncoder().encodeToString(sal) + "$"
                + Base64.getEncoder().encodeToString(hash);
    }

    public static boolean verificar(String clave, String almacenada) {
        if (clave == null || !esHash(almacenada)) {
            return false;
        }

        try {
            String[] partes = almacenada.split("\\$");

            if (partes.length != 4) {
                return false;
            }

            int iteraciones = Integer.parseInt(partes[1]);

            if (iteraciones < ITERACIONES || iteraciones > 2_000_000) {
                return false;
            }

            byte[] sal = Base64.getDecoder().decode(partes[2]);
            byte[] esperado = Base64.getDecoder().decode(partes[3]);

            if (sal.length != 16 || esperado.length != 32) {
                return false;
            }

            byte[] obtenido = calcular(clave, sal, iteraciones);

            return MessageDigest.isEqual(esperado, obtenido);

        } catch (IllegalArgumentException error) {
            return false;
        }
    }

    private static byte[] calcular(
            String clave, byte[] sal, int iteraciones) {

        PBEKeySpec especificacion = new PBEKeySpec(
                clave.toCharArray(), sal, iteraciones, 256
        );

        try {
            return SecretKeyFactory
                    .getInstance("PBKDF2WithHmacSHA256")
                    .generateSecret(especificacion)
                    .getEncoded();

        } catch (java.security.GeneralSecurityException error) {
            throw new IllegalStateException(
                    "No se pudo proteger la contraseña.", error
            );
        } finally {
            especificacion.clearPassword();
        }
    }
}