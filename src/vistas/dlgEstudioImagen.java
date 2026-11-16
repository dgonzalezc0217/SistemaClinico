package vistas;

import Modelo.cEstudioImagen;
import javax.swing.*;
import java.awt.*;
import java.time.*;
import java.time.format.*;

/** Formulario Java normal; no necesita .form. Registra estudio e informe inicial. */
public class dlgEstudioImagen extends JDialog {
    private final cEstudioImagen modelo=new cEstudioImagen();
    private final long paciente,autor;
    private final JComboBox<cEstudioImagen.Opcion> orden=new JComboBox<>(),sistema=new JComboBox<>();
    private final JComboBox<String> modalidad=new JComboBox<>(new String[]{"CR","DX","US","CT","MR","MG","OT"});
    private final JTextField uid=new JTextField(),archivo=new JTextField(),pdf=new JTextField();
    private final JTextField fecha=new JTextField(LocalDateTime.now(ZoneId.of("America/Bogota")).format(DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm")));
    private final JTextArea hallazgos=new JTextArea(4,40),conclusion=new JTextArea(3,40);
    private final JButton guardar=new JButton("Guardar estudio e informe borrador");
    private boolean guardado;

    public dlgEstudioImagen(Window padre,long paciente,long autor)throws Exception {
        super(padre,"Registrar estudio de imágenes",ModalityType.APPLICATION_MODAL);
        this.paciente=paciente;this.autor=autor;
        for(var o:modelo.ordenes(paciente))orden.addItem(o);
        for(var s:modelo.sistemas())sistema.addItem(s);
        uid.setToolTipText("Si existe un DICOM, copia su StudyInstanceUID real. Generar UID es solo para un estudio local sin UID previo.");
        JPanel campos=new JPanel();campos.setLayout(new BoxLayout(campos,BoxLayout.Y_AXIS));
        campos.setBorder(BorderFactory.createEmptyBorder(12,12,12,12));
        campos.add(new JLabel("CR/DX: radiografía · US: ecografía · CT: tomografía · MR: resonancia · MG: mamografía"));
        campos.add(ApoyoIntegracion.fila("Detalle de orden emitida:",orden));
        campos.add(ApoyoIntegracion.fila("Sistema de imágenes:",sistema));
        campos.add(ApoyoIntegracion.fila("Modalidad:",modalidad));
        JButton generar=new JButton("Generar UID local");
        generar.addActionListener(e->{java.util.UUID u=java.util.UUID.randomUUID();uid.setText("2.25."+new java.math.BigInteger(u.toString().replace("-",""),16));});
        JPanel uidFila=new JPanel(new BorderLayout());uidFila.add(uid);uidFila.add(generar,BorderLayout.EAST);
        campos.add(ApoyoIntegracion.fila("StudyInstanceUID:",uidFila));
        campos.add(ApoyoIntegracion.fila("Realizado (Colombia, AAAA-MM-DD HH:mm):",fecha));
        campos.add(archivoFila("Archivo del estudio:",archivo,false));
        campos.add(ApoyoIntegracion.fila("Hallazgos:",new JScrollPane(hallazgos)));
        campos.add(ApoyoIntegracion.fila("Conclusión:",new JScrollPane(conclusion)));
        campos.add(archivoFila("PDF del informe (opcional):",pdf,true));
        campos.add(new JLabel("Se guarda la referencia del archivo; no se copia ni se firma el informe."));
        JButton cancelar=new JButton("Cancelar");cancelar.addActionListener(e->dispose());
        JPanel botones=new JPanel();botones.add(cancelar);botones.add(guardar);campos.add(botones);
        guardar.setEnabled(orden.getItemCount()>0&&sistema.getItemCount()>0);
        if(!guardar.isEnabled())campos.add(new JLabel("Falta una orden emitida de imágenes sin estudio o un sistema de imágenes configurado."));
        guardar.addActionListener(e->guardar());
        setContentPane(new JScrollPane(campos));setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setSize(880,650);setLocationRelativeTo(padre);
    }
    private JPanel archivoFila(String nombre,JTextField campo,boolean soloPdf){
        JButton elegir=new JButton("Elegir archivo");elegir.addActionListener(e->ApoyoIntegracion.elegir(this,campo,soloPdf));
        JPanel fila=new JPanel(new BorderLayout());fila.add(campo);fila.add(elegir,BorderLayout.EAST);
        return ApoyoIntegracion.fila(nombre,fila);
    }
    private void guardar(){
        guardar.setEnabled(false);
        try {
            ApoyoIntegracion.validarArchivo(archivo.getText().trim(),false);
            if(!pdf.getText().isBlank())ApoyoIntegracion.validarArchivo(pdf.getText().trim(),true);
            var f=DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm").withResolverStyle(ResolverStyle.STRICT);
            String utc=LocalDateTime.parse(fecha.getText().trim(),f).atZone(ZoneId.of("America/Bogota"))
                    .withZoneSameInstant(ZoneOffset.UTC).format(DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss"));
            long id=modelo.guardar(paciente,((cEstudioImagen.Opcion)orden.getSelectedItem()).id(),
                    ((cEstudioImagen.Opcion)sistema.getSelectedItem()).id(),autor,uid.getText(),
                    modalidad.getSelectedItem().toString(),utc,archivo.getText(),hallazgos.getText(),conclusion.getText(),pdf.getText());
            guardado=true;JOptionPane.showMessageDialog(this,"Estudio "+id+" guardado. Informe en BORRADOR.");dispose();
        }catch(Exception e){ApoyoIntegracion.error(this,e);guardar.setEnabled(true);}
    }
    public boolean isGuardado(){return guardado;}
}
