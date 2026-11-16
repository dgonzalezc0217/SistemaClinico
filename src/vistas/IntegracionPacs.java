package vistas;

import Modelo.cEstudioImagen;
import Modelo.cPacsConsulta;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.util.List;
import java.time.*;

/** Conecta componentes existentes. No añade paneles ni modifica GroupLayout. */
public class IntegracionPacs {
    private final JPanel vista;
    private final JTable tabla;
    private final JTextField ingreso,nombre,documento,telefono,edad,sangre,alergias;
    private final JTextArea informe;
    private final JLabel visor;
    private final JButton archivos,anexar;
    private final cEstudioImagen modelo=new cEstudioImagen();
    private final cPacsConsulta consulta=new cPacsConsulta();
    private final DefaultTableModel datos=ApoyoIntegracion.tabla("ID Estudio","Fecha (Colombia)","Modalidad","Descripción","Autor del informe","Estado estudio");
    private List<cEstudioImagen.Estudio> estudios=List.of();
    private long paciente;
    public IntegracionPacs(JPanel vista,JTable tabla,JTextField ingreso,JTextField nombre,
            JTextField documento,JTextField telefono,JTextField edad,JTextField sangre,JTextField alergias,
            JTextArea informe,JLabel visor,JButton archivos,JButton anexar) {
        this.vista=vista;this.tabla=tabla;this.ingreso=ingreso;this.nombre=nombre;this.documento=documento;
        this.telefono=telefono;this.edad=edad;this.sangre=sangre;this.alergias=alergias;this.informe=informe;
        this.visor=visor;this.archivos=archivos;this.anexar=anexar;
        tabla.setFillsViewportHeight(true);tabla.setModel(datos);tabla.setAutoCreateRowSorter(true);tabla.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        for(JTextField f:new JTextField[]{nombre,documento,telefono,edad,sangre,alergias})f.setEditable(false);
        informe.setEditable(false);informe.setLineWrap(true);informe.setWrapStyleWord(true);
        archivos.setText("Abrir estudio / PDF");archivos.setEnabled(false);anexar.setEnabled(false);
        archivos.addActionListener(e->abrir());ingreso.addActionListener(e->buscar());
        tabla.getSelectionModel().addListSelectionListener(e->{if(!e.getValueIsAdjusting())mostrar();});
        JPopupMenu menu=new JPopupMenu();
        JMenuItem nuevo=new JMenuItem("Registrar estudio"),actualizar=new JMenuItem("Actualizar estudios"),abrir=new JMenuItem("Abrir estudio / PDF");
        nuevo.addActionListener(e->registrar());actualizar.addActionListener(e->{try{cargar();}catch(Exception ex){ApoyoIntegracion.error(vista,ex);}});abrir.addActionListener(e->abrir());
        menu.add(nuevo);menu.add(actualizar);menu.add(abrir);tabla.setComponentPopupMenu(menu);
        tabla.setToolTipText("Clic derecho: registrar, actualizar o abrir. Ctrl+N: registrar estudio.");
        vista.getInputMap(JComponent.WHEN_ANCESTOR_OF_FOCUSED_COMPONENT).put(KeyStroke.getKeyStroke("control N"),"nuevoEstudio");
        vista.getActionMap().put("nuevoEstudio",new AbstractAction(){@Override public void actionPerformed(java.awt.event.ActionEvent e){registrar();}});
        visor.setText("Seleccione un estudio");visor.setIcon(null);
    }
    public void buscar(){
        try {
            String texto=ingreso.getText().trim();
            limpiar();
            var opcion=ApoyoIntegracion.paciente(vista,texto);if(opcion==null)return;
            var p=consulta.paciente(opcion.getId());paciente=p.id();nombre.setText(p.nombre());documento.setText(p.documento());
            telefono.setText(p.telefono());sangre.setText(p.sangre());alergias.setText(p.alergias());
            try{edad.setText(Integer.toString(Period.between(LocalDate.parse(p.nacimiento()),LocalDate.now(ZoneId.of("America/Bogota"))).getYears()));}
            catch(Exception ex){edad.setText("");}
            cargar();
        }catch(Exception e){limpiar();ApoyoIntegracion.error(vista,e);}
    }
    private void cargar()throws Exception{
        if(paciente<=0)throw new IllegalArgumentException("Busca primero un paciente.");
        var lista=modelo.listar(paciente);var autores=consulta.autores(paciente);
        tabla.clearSelection();datos.setRowCount(0);estudios=lista;
        var f=java.time.format.DateTimeFormatter.ofPattern("uuuu-MM-dd HH:mm:ss");
        for(var x:lista){
            String fecha=LocalDateTime.parse(x.fecha(),f).atZone(ZoneOffset.UTC).withZoneSameInstant(ZoneId.of("America/Bogota")).format(f);
            datos.addRow(new Object[]{x.id(),fecha,x.modalidad(),x.servicio(),autores.getOrDefault(x.id(),"Sin informe"),x.estado()});
        }
        mostrar();if(lista.isEmpty())informe.setText("Sin estudios. Clic derecho sobre la tabla > Registrar estudio.");
    }
    private cEstudioImagen.Estudio seleccionado(){int f=tabla.getSelectedRow();if(f<0)throw new IllegalArgumentException("Selecciona un estudio.");return estudios.get(tabla.convertRowIndexToModel(f));}
    private void mostrar(){
        boolean hay=tabla.getSelectedRow()>=0;archivos.setEnabled(hay);anexar.setEnabled(hay);
        if(!hay){informe.setText("");visor.setText("Seleccione un estudio");visor.setToolTipText(null);return;}
        var x=seleccionado();informe.setText(x.informe());informe.setCaretPosition(0);
        visor.setText("Estudio "+x.id()+" — "+x.modalidad());visor.setToolTipText("Archivo: "+x.referencia()+". Usa Abrir estudio / PDF.");
    }
    private void abrir(){
        try{var x=seleccionado();Object[] opciones={"Abrir estudio","Abrir PDF del informe","Cancelar"};
            int r=JOptionPane.showOptionDialog(vista,"¿Qué archivo deseas abrir?","Archivos del estudio",JOptionPane.DEFAULT_OPTION,JOptionPane.QUESTION_MESSAGE,null,opciones,opciones[0]);
            if(r==0)ApoyoIntegracion.abrir(x.referencia());else if(r==1)ApoyoIntegracion.abrir(x.pdf());
        }catch(Exception e){ApoyoIntegracion.error(vista,e);}
    }
    public void registrar(){
        try{if(paciente<=0)throw new IllegalArgumentException("Busca primero un paciente.");
            var d=new dlgEstudioImagen(SwingUtilities.getWindowAncestor(vista),paciente,ApoyoIntegracion.usuario(vista));
            try{d.setVisible(true);if(d.isGuardado())cargar();}finally{d.dispose();}
        }catch(Exception e){ApoyoIntegracion.error(vista,e);}
    }
    public void anexar(){
        try{ApoyoIntegracion.usuario(vista);var x=seleccionado();var episodios=consulta.episodios(paciente);
            if(episodios.isEmpty())throw new IllegalArgumentException("Este paciente no tiene un episodio ABIERTO al que anexar el estudio.");
            var e=(cEstudioImagen.Opcion)JOptionPane.showInputDialog(vista,"Selecciona la atención del paciente:","Anexar estudio",JOptionPane.QUESTION_MESSAGE,null,episodios.toArray(),episodios.get(0));
            if(e==null)return;
            consulta.anexar(paciente,e.id(),x.id());JOptionPane.showMessageDialog(vista,"El estudio quedó vinculado al episodio "+e.id()+".");
        }catch(Exception e){ApoyoIntegracion.error(vista,e);}
    }
    private void limpiar(){paciente=0;tabla.clearSelection();datos.setRowCount(0);estudios=List.of();for(var f:new JTextField[]{nombre,documento,telefono,edad,sangre,alergias})f.setText("");mostrar();}
}
