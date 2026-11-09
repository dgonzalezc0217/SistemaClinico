package vistas;

import javax.swing.*;
import javax.swing.text.*;

/** Formato visual de cédula. El valor para consultar se obtiene sin puntos. */
public final class FormatoCedula {
    private FormatoCedula() { }

    public static String soloDigitos(String texto) {
        return texto == null ? "" : texto.replaceAll("[^0-9]", "");
    }

    public static void instalar(JTextField campo) {
        ((AbstractDocument) campo.getDocument()).setDocumentFilter(new DocumentFilter() {
            @Override public void insertString(FilterBypass fb, int offset,
                    String texto, AttributeSet a) throws BadLocationException {
                replace(fb, offset, 0, texto, a);
            }
            @Override public void remove(FilterBypass fb, int offset, int largo)
                    throws BadLocationException {
                String actual = fb.getDocument().getText(0, fb.getDocument().getLength());
                // Al borrar un punto, borrar también el dígito anterior.
                if (largo == 1 && offset > 0 && actual.charAt(offset) == '.') {
                    offset--;
                    largo++;
                }
                replace(fb, offset, largo, "", null);
            }
            @Override public void replace(FilterBypass fb, int offset, int largo,
                    String texto, AttributeSet a) throws BadLocationException {
                String entrada = texto == null ? "" : texto;
                if (!entrada.matches("[0-9.\\s]*")) {
                    java.awt.Toolkit.getDefaultToolkit().beep();
                    return;
                }
                String actual = fb.getDocument().getText(0, fb.getDocument().getLength());
                String prefijo = actual.substring(0, offset);
                String nuevo = soloDigitos(prefijo + entrada + actual.substring(offset + largo));
                if (nuevo.length() > 30) return;
                int digitosAntes = soloDigitos(prefijo + entrada).length();
                String visible = nuevo.replaceAll("(?<=\\d)(?=(\\d{3})+$)", ".");
                fb.replace(0, fb.getDocument().getLength(), visible, a);
                int posicion = 0, contados = 0;
                while (posicion < visible.length() && contados < digitosAntes) {
                    if (Character.isDigit(visible.charAt(posicion))) contados++;
                    posicion++;
                }
                final int destino = posicion;
                SwingUtilities.invokeLater(() -> campo.setCaretPosition(
                        Math.min(destino, campo.getDocument().getLength())));
            }
        });
    }
}
