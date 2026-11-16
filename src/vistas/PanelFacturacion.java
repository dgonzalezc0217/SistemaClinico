package vistas;

import Modelo.cFacturacion;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class PanelFacturacion extends JPanel {
    private final cFacturacion modelo=new cFacturacion();
    private final JTextField documento=new JTextField(16),fecha=new JTextField(10);
    private final JTextArea resumen=new JTextArea(4,60);
    private final DefaultTableModel datos=new DefaultTableModel(
            new String[]{"ID","Número","Emisión (UTC)","Paciente","Documento","Estado","Moneda","Total","Pagado","Saldo contable"},0){
        @Override public boolean isCellEditable(int f,int c){return false;}
        @Override public Class<?> getColumnClass(int c){return c==0?Long.class:(c>=7?BigDecimal.class:String.class);}
    };
    private final JTable tabla=new JTable(datos);
    private List<cFacturacion.FacturaFila> facturas=List.of();
    public PanelFacturacion(){
        super(new BorderLayout(10,10));setBorder(BorderFactory.createEmptyBorder(15,15,15,15));
        JButton buscar=new JButton("Consultar / actualizar"),limpiar=new JButton("Ver todas"),nuevo=new JButton("Nueva factura"),detalle=new JButton("Ver conceptos");
        JPanel superior=new JPanel(new FlowLayout(FlowLayout.LEFT));superior.add(new JLabel("Documento exacto:"));superior.add(documento);superior.add(new JLabel("Fecha emisión Colombia (AAAA-MM-DD):"));superior.add(fecha);superior.add(buscar);superior.add(limpiar);
        add(superior,BorderLayout.NORTH);tabla.setRowHeight(27);tabla.setAutoCreateRowSorter(true);tabla.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);add(new JScrollPane(tabla));
        resumen.setEditable(false);resumen.setLineWrap(true);resumen.setWrapStyleWord(true);
        JPanel inferior=new JPanel(new BorderLayout());inferior.add(new JScrollPane(resumen));JPanel botones=new JPanel();botones.add(nuevo);botones.add(detalle);inferior.add(botones,BorderLayout.SOUTH);add(inferior,BorderLayout.SOUTH);
        buscar.addActionListener(e->cargar());documento.addActionListener(e->cargar());fecha.addActionListener(e->cargar());
        limpiar.addActionListener(e->{documento.setText("");fecha.setText("");cargar();});
        nuevo.addActionListener(e->{try{ApoyoIntegracion.usuario(this);dlgFactura d=new dlgFactura(SwingUtilities.getWindowAncestor(this));try{d.setVisible(true);if(d.isGuardado()){documento.setText("");fecha.setText("");cargar();}}finally{d.dispose();}}catch(Exception ex){ApoyoIntegracion.error(this,ex);}});
        detalle.addActionListener(e->{try{
            int n=tabla.getSelectedRow();if(n<0)throw new IllegalArgumentException("Selecciona una factura.");
            var f=facturas.get(tabla.convertRowIndexToModel(n));
            var m=ApoyoIntegracion.tabla("Concepto","Cantidad","Precio unitario ("+f.moneda()+")","Subtotal ("+f.moneda()+")");
            for(var d:modelo.detalles(f.id()))m.addRow(new Object[]{d.descripcion(),d.cantidad(),d.precio(),d.subtotal()});
            JTable t=new JTable(m);t.setRowHeight(25);JScrollPane sc=new JScrollPane(t);sc.setPreferredSize(new Dimension(850,330));
            JOptionPane.showMessageDialog(this,sc,"Conceptos — factura "+f.id(),JOptionPane.PLAIN_MESSAGE);
        }catch(Exception ex){ApoyoIntegracion.error(this,ex);}});
        addComponentListener(new java.awt.event.ComponentAdapter(){@Override public void componentShown(java.awt.event.ComponentEvent e){cargar();}});
        resumen.setText("Pulsa Consultar para leer las facturas desde SQLite. Los borradores no tienen fecha de emisión.");
    }
    private void cargar(){
        try {
            var nuevas=modelo.listar(documento.getText().trim(),fecha.getText().trim());
            tabla.clearSelection();datos.setRowCount(0);facturas=nuevas;
            // Totales por moneda. No sumar COP con USD ni contar borradores como deuda emitida.
            Map<String,BigDecimal[]> totales=new TreeMap<>();
            for(var f:facturas){
                datos.addRow(new Object[]{f.id(),f.numero()==null?"Sin número (borrador)":f.numero(),f.fecha()==null?"Sin emitir":f.fecha(),f.paciente(),f.documento(),f.estado(),f.moneda(),f.total(),f.pagado(),f.saldo()});
                var t=totales.computeIfAbsent(f.moneda(),k->new BigDecimal[]{BigDecimal.ZERO,BigDecimal.ZERO,BigDecimal.ZERO,BigDecimal.ZERO});
                if("EMITIDA".equals(f.estado())){t[0]=t[0].add(f.total());t[1]=t[1].add(f.pagado());t[2]=t[2].add(f.saldo());}
                if("BORRADOR".equals(f.estado()))t[3]=t[3].add(f.total());
            }
            StringBuilder s=new StringBuilder("Resultados: "+facturas.size()+". Resumen de la consulta actual; anuladas excluidas del cobro.\n");
            totales.forEach((m,t)->s.append(m).append(" — Emitido: ").append(t[0].toPlainString()).append(" | Pagado: ").append(t[1].toPlainString()).append(" | Por cobrar: ").append(t[2].toPlainString()).append(" | Borradores: ").append(t[3].toPlainString()).append('\n'));
            if(facturas.isEmpty())s.append("Sin facturas para los filtros indicados.");resumen.setText(s.toString());
        }catch(Exception ex){tabla.clearSelection();datos.setRowCount(0);facturas=List.of();resumen.setText("No se pudo consultar. Revisa el documento y el formato de fecha.");ApoyoIntegracion.error(this,ex);}
    }
}
