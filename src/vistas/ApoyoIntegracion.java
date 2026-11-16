package vistas;

import Modelo.cAgendamiento;
import java.awt.*;
import java.nio.file.*;
import java.net.URI;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

final class ApoyoIntegracion {
    private ApoyoIntegracion() { }
    static DefaultTableModel tabla(String... columnas) {
        return new DefaultTableModel(columnas,0) {
            @Override public boolean isCellEditable(int fila,int columna){return false;}
        };
    }
    static void error(Component padre,Exception e){
        JOptionPane.showMessageDialog(padre,e.getMessage(),"Revisar datos",JOptionPane.WARNING_MESSAGE);
    }
    static cAgendamiento.Opcion paciente(Component padre,String texto)throws Exception {
        if(texto==null||texto.isBlank())throw new IllegalArgumentException("Escribe un documento o nombre de paciente.");
        var opciones=new cAgendamiento().buscarPacientes(texto.trim());
        if(opciones.isEmpty())throw new IllegalArgumentException("No se encontraron pacientes.");
        return (cAgendamiento.Opcion)JOptionPane.showInputDialog(padre,"Selecciona al paciente:",
                "Paciente",JOptionPane.QUESTION_MESSAGE,null,opciones.toArray(),opciones.get(0));
    }
    static long usuario(Component padre) {
        Window w=SwingUtilities.getWindowAncestor(padre);
        if(w instanceof vPrincipal principal && principal.getIdUsuarioLogueado()>0)return principal.getIdUsuarioLogueado();
        throw new IllegalArgumentException("Inicia sesión desde la ventana principal.");
    }
    static void abrir(String referencia)throws Exception {
        if(referencia==null||referencia.isBlank())throw new IllegalArgumentException("Este registro no tiene archivo asociado.");
        if(!Desktop.isDesktopSupported())throw new IllegalArgumentException("Este equipo no permite abrir archivos desde Java.");
        Desktop desktop=Desktop.getDesktop();
        if(referencia.startsWith("https://")||referencia.startsWith("http://")) {
            if(!desktop.isSupported(Desktop.Action.BROWSE))throw new IllegalArgumentException("No hay un navegador disponible.");
            desktop.browse(URI.create(referencia));return;
        }
        if(referencia.contains("://")&&!referencia.startsWith("file://"))throw new IllegalArgumentException("Referencia no compatible: usa un archivo local o una dirección HTTP/HTTPS.");
        Path p=referencia.startsWith("file://")?Paths.get(URI.create(referencia)):Paths.get(referencia);
        p=p.toAbsolutePath().normalize();validarArchivo(p.toString(),false);
        if(!desktop.isSupported(Desktop.Action.OPEN))throw new IllegalArgumentException("No hay una aplicación disponible para abrir el archivo.");
        desktop.open(p.toFile());
    }
    static void validarArchivo(String referencia,boolean soloPDF) {
        Path p=Paths.get(referencia).toAbsolutePath().normalize();
        if(!Files.isRegularFile(p)||!Files.isReadable(p))throw new IllegalArgumentException("El archivo falta o no se puede leer:\n"+p);
        String n=p.getFileName().toString().toLowerCase(java.util.Locale.ROOT);
        boolean permitido=soloPDF?n.endsWith(".pdf"):n.matches(".*\\.(pdf|png|jpg|jpeg|dcm|dicom)");
        if(!permitido)throw new IllegalArgumentException(soloPDF?"Selecciona un PDF.":"Selecciona PDF, PNG, JPG o DICOM (.dcm/.dicom).");
    }
    static void elegir(Component padre,JTextField destino,boolean pdf) {
        JFileChooser f=new JFileChooser();
        f.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter(pdf?"Informe PDF":"Estudio (PDF, imagen o DICOM)",
                pdf?new String[]{"pdf"}:new String[]{"pdf","png","jpg","jpeg","dcm","dicom"}));
        if(f.showOpenDialog(padre)==JFileChooser.APPROVE_OPTION)destino.setText(f.getSelectedFile().getAbsolutePath());
    }
    static JPanel fila(String etiqueta,Component campo){JPanel p=new JPanel(new BorderLayout(8,4));p.add(new JLabel(etiqueta),BorderLayout.WEST);p.add(campo,BorderLayout.CENTER);return p;}
}
