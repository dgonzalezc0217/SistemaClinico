package vistas;

import Modelo.cFacturacion;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.nio.file.Files;
import java.nio.charset.StandardCharsets;

/** Usa los controles originales, sin reemplazar el diseño de la vista. */
public class IntegracionFacturacion {
    private final JPanel vista;
    private final JTable tabla;
    private final JTextField documento,fecha;
    private final JLabel total,pendientes,saldo;
    private final cFacturacion modelo=new cFacturacion();
    private List<cFacturacion.FacturaFila> facturas=List.of();
    private String resumen="Consulta las facturas.";
    private final DefaultTableModel datos=new DefaultTableModel(new String[]{"ID","Número","Emisión (UTC)","Paciente","Documento","Estado","Moneda","Total","Pagado","Saldo contable"},0){
        @Override public boolean isCellEditable(int f,int c){return false;}
        @Override public Class<?> getColumnClass(int c){return c==0?Long.class:(c>=7?BigDecimal.class:String.class);}
    };
    public IntegracionFacturacion(JPanel vista,JTable tabla,JTextField documento,JTextField fecha,
            JLabel total,JLabel pendientes,JLabel saldo,JButton exportar){
        this.vista=vista;this.tabla=tabla;this.documento=documento;this.fecha=fecha;
        this.total=total;this.pendientes=pendientes;this.saldo=saldo;
        tabla.setModel(datos);tabla.setAutoCreateRowSorter(true);tabla.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tabla.setToolTipText("Doble clic para consultar los conceptos de una factura.");
        tabla.addMouseListener(new java.awt.event.MouseAdapter(){@Override public void mouseClicked(java.awt.event.MouseEvent e){if(e.getClickCount()==2&&tabla.rowAtPoint(e.getPoint())>=0)detalles();}});
        fecha.setToolTipText("Fecha de emisión en Colombia: AAAA-MM-DD. Vacío: todas.");
        documento.setToolTipText("Documento exacto. Vacío: todos los pacientes.");
        documento.addActionListener(e->buscar());fecha.addActionListener(e->buscar());
        exportar.setText("Exportar CSV");
        buscar();
    }
    public void buscar(){
        try{
            var lista=modelo.listar(documento.getText().trim(),fecha.getText().trim());
            tabla.clearSelection();datos.setRowCount(0);facturas=lista;
            Map<String,BigDecimal[]> sumas=new TreeMap<>();int porCobrar=0;
            for(var f:lista){
                datos.addRow(new Object[]{f.id(),f.numero()==null?"Sin número":f.numero(),f.fecha()==null?"Sin emitir":f.fecha(),f.paciente(),f.documento(),f.estado(),f.moneda(),f.total(),f.pagado(),f.saldo()});
                var s=sumas.computeIfAbsent(f.moneda(),k->new BigDecimal[]{BigDecimal.ZERO,BigDecimal.ZERO,BigDecimal.ZERO,BigDecimal.ZERO});
                if("EMITIDA".equals(f.estado())){s[0]=s[0].add(f.total());s[1]=s[1].add(f.pagado());s[2]=s[2].add(f.saldo());if(f.saldo().signum()>0)porCobrar++;}
                if("BORRADOR".equals(f.estado()))s[3]=s[3].add(f.total());
            }
            pendientes.setText(Integer.toString(porCobrar));
            total.setText(valorTarjeta(sumas,0));saldo.setText(valorTarjeta(sumas,2));
            StringBuilder s=new StringBuilder("Resumen de los filtros actuales. Facturas: "+lista.size()+"\nAnuladas excluidas del cobro. Borradores separados.\n\n");
            sumas.forEach((m,v)->s.append(m).append(" — Emitido: ").append(v[0].toPlainString()).append(" | Pagado: ").append(v[1].toPlainString()).append(" | Saldo: ").append(v[2].toPlainString()).append(" | Borradores: ").append(v[3].toPlainString()).append('\n'));
            resumen=s.toString();total.setToolTipText(resumen);saldo.setToolTipText(resumen);
        }catch(Exception ex){tabla.clearSelection();datos.setRowCount(0);facturas=List.of();total.setText("—");pendientes.setText("—");saldo.setText("—");total.setToolTipText(null);saldo.setToolTipText(null);resumen="Consulta fallida. Revisa los filtros y vuelve a buscar.";ApoyoIntegracion.error(vista,ex);}
    }
    private String valorTarjeta(Map<String,BigDecimal[]> sumas,int indice){
        if(sumas.isEmpty())return "0.00";
        if(sumas.size()>1)return "Ver reporte";
        var s=sumas.entrySet().iterator().next();return s.getKey()+" "+s.getValue()[indice].setScale(2).toPlainString();
    }
    public void nuevaFactura(){
        try{ApoyoIntegracion.usuario(vista);var d=new dlgFactura(SwingUtilities.getWindowAncestor(vista));
            try{d.setVisible(true);if(d.isGuardado()){documento.setText("");fecha.setText("");buscar();}}finally{d.dispose();}
        }catch(Exception ex){ApoyoIntegracion.error(vista,ex);}
    }
    public void cambiarEstado(){JOptionPane.showMessageDialog(vista,"El cambio de estado necesita una operación de emisión, pago o anulación. No está incluido en la preparación del borrador.");}
    public void reporte(){JTextArea t=new JTextArea(resumen,10,75);t.setEditable(false);t.setLineWrap(true);t.setWrapStyleWord(true);JOptionPane.showMessageDialog(vista,new JScrollPane(t),"Resumen de facturación",JOptionPane.INFORMATION_MESSAGE);}
    public void detalles(){
        try{int fila=tabla.getSelectedRow();if(fila<0)throw new IllegalArgumentException("Selecciona una factura.");var f=facturas.get(tabla.convertRowIndexToModel(fila));
            var m=ApoyoIntegracion.tabla("Concepto","Cantidad","Precio ("+f.moneda()+")","Subtotal ("+f.moneda()+")");
            for(var d:modelo.detalles(f.id()))m.addRow(new Object[]{d.descripcion(),d.cantidad(),d.precio(),d.subtotal()});
            var sc=new JScrollPane(new JTable(m));sc.setPreferredSize(new java.awt.Dimension(800,300));JOptionPane.showMessageDialog(vista,sc,"Conceptos de factura "+f.id(),JOptionPane.PLAIN_MESSAGE);
        }catch(Exception ex){ApoyoIntegracion.error(vista,ex);}
    }
    public void exportar(){
        try{if(facturas.isEmpty())throw new IllegalArgumentException("No hay facturas para exportar.");
            JFileChooser c=new JFileChooser();c.setSelectedFile(new java.io.File("facturas.csv"));if(c.showSaveDialog(vista)!=JFileChooser.APPROVE_OPTION)return;
            var p=c.getSelectedFile().toPath();if(!p.toString().toLowerCase(java.util.Locale.ROOT).endsWith(".csv"))p=p.resolveSibling(p.getFileName()+".csv");
            if(Files.exists(p)&&JOptionPane.showConfirmDialog(vista,"El archivo existe. ¿Reemplazarlo?","Exportar",JOptionPane.YES_NO_OPTION)!=JOptionPane.YES_OPTION)return;
            StringBuilder s=new StringBuilder("\uFEFF");
            for(int col=0;col<tabla.getColumnCount();col++){if(col>0)s.append(';');s.append(csv(tabla.getColumnName(col)));}s.append('\n');
            for(int row=0;row<tabla.getRowCount();row++){for(int col=0;col<tabla.getColumnCount();col++){if(col>0)s.append(';');s.append(csv(tabla.getValueAt(row,col)));}s.append('\n');}
            Files.writeString(p,s,StandardCharsets.UTF_8);JOptionPane.showMessageDialog(vista,"Archivo guardado en:\n"+p.toAbsolutePath());
        }catch(Exception ex){ApoyoIntegracion.error(vista,ex);}
    }
    private static String csv(Object valor){String s=valor==null?"":valor.toString();if(!(valor instanceof Number)&&s.matches("^[=+@\\-\\t\\r].*"))s="'"+s;return "\""+s.replace("\"","\"\"")+"\"";}
}
