package vistas;

import Modelo.cFacturacion;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/** Selecciona prestaciones realizadas. Crea un borrador, no emite ni registra pagos. */
public class dlgFactura extends JDialog {
    private final cFacturacion modelo=new cFacturacion();
    private final JTextField documento=new JTextField(22);
    private final JLabel paciente=new JLabel("Selecciona un paciente.");
    private final JComboBox<String> moneda=new JComboBox<>(new String[]{"COP","USD","EUR"});
    private final JButton guardar=new JButton("Guardar borrador");
    private final DefaultTableModel datos=new DefaultTableModel(
            new String[]{"Incluir","ID prestación","Servicio","Realizada (UTC)","Cantidad","Precio unitario"},0){
        @Override public boolean isCellEditable(int f,int c){return c==0||c==5;}
        @Override public Class<?> getColumnClass(int c){return c==0?Boolean.class:(c==1?Long.class:(c==4?BigDecimal.class:String.class));}
    };
    private final JTable tabla=new JTable(datos);
    private List<cFacturacion.PrestacionFila> prestaciones=List.of();
    private long idPaciente;
    private boolean guardado;
    public dlgFactura(Window padre){
        super(padre,"Preparar factura",ModalityType.APPLICATION_MODAL);
        JPanel contenido=new JPanel(new BorderLayout(10,10));contenido.setBorder(BorderFactory.createEmptyBorder(12,12,12,12));
        JButton buscar=new JButton("Buscar paciente"),cancelar=new JButton("Cancelar");
        JPanel superior=new JPanel(new FlowLayout(FlowLayout.LEFT));superior.add(new JLabel("Documento o nombre:"));superior.add(documento);superior.add(buscar);superior.add(new JLabel("Moneda:"));superior.add(moneda);
        JPanel encabezado=new JPanel(new BorderLayout());encabezado.add(superior,BorderLayout.NORTH);encabezado.add(paciente,BorderLayout.SOUTH);contenido.add(encabezado,BorderLayout.NORTH);
        tabla.setRowHeight(27);tabla.setAutoCreateRowSorter(true);contenido.add(new JScrollPane(tabla));
        JPanel inferior=new JPanel(new BorderLayout());inferior.add(new JLabel("Precio por unidad en la moneda elegida; sin separador de miles. Ejemplo: 125000.50. Cantidad tomada de SQLite."),BorderLayout.NORTH);
        JPanel botones=new JPanel();botones.add(cancelar);botones.add(guardar);inferior.add(botones,BorderLayout.SOUTH);contenido.add(inferior,BorderLayout.SOUTH);
        guardar.setEnabled(false);
        buscar.addActionListener(e->{try{
            var p=ApoyoIntegracion.paciente(this,documento.getText());if(p==null)return;
            var lista=modelo.disponibles(p.getId());datos.setRowCount(0);prestaciones=lista;idPaciente=p.getId();paciente.setText(p.toString());
            for(var x:lista)datos.addRow(new Object[]{false,x.id(),x.servicio(),x.fecha(),x.cantidad(),""});
            guardar.setEnabled(!lista.isEmpty());
            if(lista.isEmpty())JOptionPane.showMessageDialog(this,"No hay prestaciones REALIZADAS sin facturar para este paciente.");
        }catch(Exception ex){idPaciente=0;datos.setRowCount(0);prestaciones=List.of();paciente.setText("Selecciona un paciente.");guardar.setEnabled(false);ApoyoIntegracion.error(this,ex);}});
        documento.addActionListener(e->buscar.doClick());cancelar.addActionListener(e->dispose());guardar.addActionListener(e->guardar());
        setContentPane(contenido);setDefaultCloseOperation(DISPOSE_ON_CLOSE);setSize(1020,520);setLocationRelativeTo(padre);
    }
    private void guardar(){
        try {
            if(tabla.isEditing()&&!tabla.getCellEditor().stopCellEditing())return;
            List<cFacturacion.Concepto> seleccion=new ArrayList<>();
            for(int i=0;i<datos.getRowCount();i++){
                if(Boolean.TRUE.equals(datos.getValueAt(i,0))){
                    String precio=String.valueOf(datos.getValueAt(i,5)).trim();
                    if(!precio.matches("[0-9]+([.,][0-9]{1,2})?"))throw new IllegalArgumentException("Escribe un precio válido en la prestación "+prestaciones.get(i).id()+". Ejemplo: 125000.50.");
                    seleccion.add(new cFacturacion.Concepto(prestaciones.get(i).id(),new BigDecimal(precio.replace(',','.'))));
                }
            }
            if(seleccion.isEmpty())throw new IllegalArgumentException("Marca al menos una prestación en Incluir.");
            if(JOptionPane.showConfirmDialog(this,"¿Crear borrador con "+seleccion.size()+" concepto(s) en "+moneda.getSelectedItem()+"?",
                    "Confirmar",JOptionPane.YES_NO_OPTION)!=JOptionPane.YES_OPTION)return;
            guardar.setEnabled(false);
            long id=modelo.guardarBorrador(idPaciente,moneda.getSelectedItem().toString(),seleccion);
            guardado=true;JOptionPane.showMessageDialog(this,"Borrador "+id+" guardado con sus conceptos. Todavía no es una factura emitida.");dispose();
        }catch(Exception ex){ApoyoIntegracion.error(this,ex);guardar.setEnabled(idPaciente>0&&!prestaciones.isEmpty());}
    }
    public boolean isGuardado(){return guardado;}
}
