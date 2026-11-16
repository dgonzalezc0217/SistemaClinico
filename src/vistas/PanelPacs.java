package vistas;

import Modelo.cEstudioImagen;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.List;

public class PanelPacs extends JPanel {
    private final cEstudioImagen modelo=new cEstudioImagen();
    private final JTextField busqueda=new JTextField(20);
    private final JLabel paciente=new JLabel("Busca y selecciona un paciente.");
    private final JTextArea informe=new JTextArea();
    private final DefaultTableModel datos=ApoyoIntegracion.tabla("ID","Realizado (UTC)","Modalidad","Servicio","Estado estudio");
    private final JTable tabla=new JTable(datos);
    private List<cEstudioImagen.Estudio> estudios=List.of();
    private long idPaciente;
    public PanelPacs(){
        super(new BorderLayout(10,10));setBorder(BorderFactory.createEmptyBorder(15,15,15,15));
        JButton buscar=new JButton("Buscar paciente"),nuevo=new JButton("Registrar estudio"),actualizar=new JButton("Actualizar"),abrir=new JButton("Abrir estudio"),pdf=new JButton("Abrir PDF del informe");
        JPanel arriba=new JPanel(new FlowLayout(FlowLayout.LEFT));arriba.add(new JLabel("Documento o nombre:"));arriba.add(busqueda);arriba.add(buscar);arriba.add(actualizar);arriba.add(nuevo);
        JPanel encabezado=new JPanel(new BorderLayout());encabezado.add(arriba,BorderLayout.NORTH);encabezado.add(paciente,BorderLayout.SOUTH);add(encabezado,BorderLayout.NORTH);
        tabla.setAutoCreateRowSorter(true);tabla.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);tabla.setRowHeight(26);
        informe.setEditable(false);informe.setLineWrap(true);informe.setWrapStyleWord(true);
        JSplitPane centro=new JSplitPane(JSplitPane.VERTICAL_SPLIT,new JScrollPane(tabla),new JScrollPane(informe));centro.setResizeWeight(.55);add(centro);
        JPanel abajo=new JPanel();abajo.add(abrir);abajo.add(pdf);add(abajo,BorderLayout.SOUTH);
        buscar.addActionListener(e->{try{var p=ApoyoIntegracion.paciente(this,busqueda.getText());if(p!=null){idPaciente=p.getId();paciente.setText(p.toString());cargar();}}catch(Exception ex){limpiar();ApoyoIntegracion.error(this,ex);}});
        busqueda.addActionListener(e->buscar.doClick());
        actualizar.addActionListener(e->{try{cargar();}catch(Exception ex){ApoyoIntegracion.error(this,ex);}});
        nuevo.addActionListener(e->{try{
            if(idPaciente<=0)throw new IllegalArgumentException("Selecciona un paciente.");
            dlgEstudioImagen d=new dlgEstudioImagen(SwingUtilities.getWindowAncestor(this),idPaciente,ApoyoIntegracion.usuario(this));
            try{d.setVisible(true);if(d.isGuardado())cargar();}finally{d.dispose();}
        }catch(Exception ex){ApoyoIntegracion.error(this,ex);}});
        tabla.getSelectionModel().addListSelectionListener(e->{if(!e.getValueIsAdjusting()){int n=tabla.getSelectedRow();informe.setText(n<0?"":estudios.get(tabla.convertRowIndexToModel(n)).informe());}});
        abrir.addActionListener(e->{try{ApoyoIntegracion.abrir(seleccionado().referencia());}catch(Exception ex){ApoyoIntegracion.error(this,ex);}});
        pdf.addActionListener(e->{try{ApoyoIntegracion.abrir(seleccionado().pdf());}catch(Exception ex){ApoyoIntegracion.error(this,ex);}});
    }
    private cEstudioImagen.Estudio seleccionado(){int n=tabla.getSelectedRow();if(n<0)throw new IllegalArgumentException("Selecciona un estudio.");return estudios.get(tabla.convertRowIndexToModel(n));}
    private void cargar()throws Exception{
        if(idPaciente<=0)throw new IllegalArgumentException("Selecciona un paciente.");
        var nuevos=modelo.listar(idPaciente);tabla.clearSelection();datos.setRowCount(0);estudios=nuevos;informe.setText("");
        for(var x:estudios)datos.addRow(new Object[]{x.id(),x.fecha(),x.modalidad(),x.servicio(),x.estado()});
        if(estudios.isEmpty())informe.setText("Este paciente no tiene estudios registrados.");
    }
    private void limpiar(){idPaciente=0;tabla.clearSelection();datos.setRowCount(0);estudios=List.of();informe.setText("");paciente.setText("Busca y selecciona un paciente.");}
}
