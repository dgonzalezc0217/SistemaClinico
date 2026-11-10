package vistas;

import Modelo.cDisponibilidad;
import Modelo.cDisponibilidad.Horario;
import java.awt.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.*;
import java.util.List;
import javax.swing.*;
import javax.swing.table.DefaultTableModel;

/**
 * Diálogo escrito a mano: no necesita archivo .form ni librerías adicionales.
 */
public class dlgSeleccionarHorario extends JDialog {

    private final long idPaciente, idMedico, idEspecialidad,
            idServicio, idCitaExcluir;
    private final cDisponibilidad modelo = new cDisponibilidad();
    private YearMonth mes = YearMonth.now(cDisponibilidad.ZONA);
    private final JLabel titulo = new JLabel("", SwingConstants.CENTER);
    private final JLabel estado = new JLabel(" ");
    private final JPanel calendario = new JPanel(new GridLayout(7, 7, 4, 4));
    private final DefaultTableModel tablaModelo = new DefaultTableModel(
            new String[]{"Inicio", "Fin", "Minutos", "Sede", "Agenda"}, 0) {
        @Override
        public boolean isCellEditable(int fila, int columna) {
            return false;
        }
    };
    private final JTable tabla = new JTable(tablaModelo);
    private final JButton anterior = new JButton("<");
    private final JButton siguiente = new JButton(">");
    private final JButton actualizar = new JButton("Actualizar disponibilidad");
    private final JButton seleccionar = new JButton("Usar horario");
    private Map<LocalDate, List<Horario>> disponibles = new TreeMap<>();
    private List<Horario> horariosDia = new ArrayList<>();
    private Horario elegido;
    private boolean cargando;
    private SwingWorker<Map<LocalDate, List<Horario>>, Void> trabajo;

    public dlgSeleccionarHorario(
            Window padre,
            long idPaciente,
            long idMedico,
            long idEspecialidad,
            long idServicio) {

        this(
                padre,
                idPaciente,
                idMedico,
                idEspecialidad,
                idServicio,
                0
        );
    }

    public dlgSeleccionarHorario(
            Window padre,
            long idPaciente,
            long idMedico,
            long idEspecialidad,
            long idServicio,
            long idCitaExcluir) {

        super(
                padre,
                "Seleccionar fecha y horario",
                ModalityType.APPLICATION_MODAL
        );

        this.idCitaExcluir = idCitaExcluir;
        this.idPaciente = idPaciente;
        this.idMedico = idMedico;
        this.idEspecialidad = idEspecialidad;
        this.idServicio = idServicio;

        setDefaultCloseOperation(DISPOSE_ON_CLOSE);

        construirVentana();
        cargarMes();
    }

    private void construirVentana() {
        JPanel contenido = new JPanel(new BorderLayout(12, 12));
        contenido.setBorder(BorderFactory.createEmptyBorder(14, 14, 14, 14));
        setContentPane(contenido);
        JPanel encabezado = new JPanel(new BorderLayout(8, 8));
        encabezado.add(anterior, BorderLayout.WEST);
        encabezado.add(titulo, BorderLayout.CENTER);
        encabezado.add(siguiente, BorderLayout.EAST);
        JPanel izquierda = new JPanel(new BorderLayout(8, 8));
        izquierda.add(encabezado, BorderLayout.NORTH);
        izquierda.add(calendario, BorderLayout.CENTER);
        izquierda.add(new JLabel("Verde: tiene horarios libres. Hora de Colombia."), BorderLayout.SOUTH);
        izquierda.setPreferredSize(new Dimension(360, 310));
        contenido.add(izquierda, BorderLayout.WEST);
        tabla.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        tabla.setRowHeight(26);
        JScrollPane desplazamiento = new JScrollPane(tabla);
        desplazamiento.setPreferredSize(new Dimension(510, 310));
        contenido.add(desplazamiento, BorderLayout.CENTER);
        JPanel inferior = new JPanel(new BorderLayout(8, 8));
        inferior.add(estado, BorderLayout.NORTH);
        JPanel botones = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        JButton cancelar = new JButton("Cancelar");
        botones.add(actualizar);
        botones.add(cancelar);
        botones.add(seleccionar);
        inferior.add(botones, BorderLayout.SOUTH);
        contenido.add(inferior, BorderLayout.SOUTH);
        seleccionar.setEnabled(false);
        anterior.addActionListener(e -> {
            mes = mes.minusMonths(1);
            cargarMes();
        });
        siguiente.addActionListener(e -> {
            mes = mes.plusMonths(1);
            cargarMes();
        });
        actualizar.addActionListener(e -> cargarMes());
        cancelar.addActionListener(e -> dispose());
        tabla.getSelectionModel().addListSelectionListener(e
                -> seleccionar.setEnabled(!cargando && tabla.getSelectedRow() >= 0));
        seleccionar.addActionListener(e -> {
            int fila = tabla.getSelectedRow();
            if (fila < 0 || cargando) {
                return;
            }
            elegido = horariosDia.get(tabla.convertRowIndexToModel(fila));
            dispose();
        });
        addWindowListener(new java.awt.event.WindowAdapter() {
            @Override
            public void windowClosed(java.awt.event.WindowEvent e) {
                if (trabajo != null) {
                    trabajo.cancel(true);
                }
            }
        });
        pack();
        setLocationRelativeTo(getOwner());
    }

    private void cargarMes() {
        cargando = true;
        anterior.setEnabled(false);
        siguiente.setEnabled(false);
        actualizar.setEnabled(false);
        seleccionar.setEnabled(false);
        tablaModelo.setRowCount(0);
        horariosDia = new ArrayList<>();
        disponibles = new TreeMap<>();
        pintarCalendario();
        estado.setText("Consultando horarios del médico y del paciente...");
        YearMonth solicitado = mes;
        trabajo = new SwingWorker<>() {
            @Override
            protected Map<LocalDate, List<Horario>> doInBackground() throws Exception {
                return modelo.listarMes(
        idPaciente,
        idMedico,
        idEspecialidad,
        idServicio,
        solicitado,
        idCitaExcluir
);
            }

            @Override
            protected void done() {
                if (isCancelled() || !isDisplayable()) {
                    return;
                }
                cargando = false;
                anterior.setEnabled(mes.isAfter(YearMonth.now(cDisponibilidad.ZONA)));
                siguiente.setEnabled(true);
                actualizar.setEnabled(true);
                try {
                    disponibles = get();
                    estado.setText(disponibles.isEmpty()
                            ? "Sin horarios libres este mes. Revisa las agendas o cambia de mes."
                            : "Selecciona un día verde y después un horario de la tabla.");
                } catch (Exception error) {
                    Throwable causa = error.getCause() == null ? error : error.getCause();
                    estado.setText("No se pudo consultar la disponibilidad.");
                    JOptionPane.showMessageDialog(dlgSeleccionarHorario.this,
                            causa.getMessage(), "Revisar disponibilidad", JOptionPane.WARNING_MESSAGE);
                }
                pintarCalendario();
            }
        };
        trabajo.execute();
    }

    private void pintarCalendario() {
        titulo.setText(mes.getMonth().getDisplayName(TextStyle.FULL,
                Locale.forLanguageTag("es-CO")) + " " + mes.getYear());
        calendario.removeAll();
        for (String nombre : new String[]{"Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"}) {
            calendario.add(new JLabel(nombre, SwingConstants.CENTER));
        }
        int vacios = mes.atDay(1).getDayOfWeek().getValue() - 1;
        for (int i = 0; i < vacios; i++) {
            calendario.add(new JLabel());
        }
        for (int dia = 1; dia <= mes.lengthOfMonth(); dia++) {
            LocalDate fecha = mes.atDay(dia);
            JButton boton = new JButton(String.valueOf(dia));
            boolean libre = !cargando && disponibles.containsKey(fecha);
            boton.setEnabled(libre);
            if (libre) {
                boton.setBackground(new Color(190, 225, 195));
                boton.setOpaque(true);
                boton.setToolTipText("Ver horarios del " + fecha);
            }
            boton.addActionListener(e -> mostrarDia(fecha));
            calendario.add(boton);
        }
        while (calendario.getComponentCount() < 49) {
            calendario.add(new JLabel());
        }
        calendario.revalidate();
        calendario.repaint();
    }

    private void mostrarDia(LocalDate fecha) {
        tablaModelo.setRowCount(0);
        horariosDia = disponibles.getOrDefault(fecha, Collections.emptyList());
        DateTimeFormatter hora = DateTimeFormatter.ofPattern("HH:mm");
        for (Horario h : horariosDia) {
            String fin = h.finLocal().format(hora);
            if (!h.finLocal().toLocalDate().equals(fecha)) {
                fin += " (" + h.finLocal().toLocalDate() + ")";
            }
            tablaModelo.addRow(new Object[]{h.inicioLocal().format(hora), fin,
                h.duracion, h.sede, h.idAgenda});
        }
        estado.setText("Fecha: " + fecha + ". Selecciona un horario. Se volverá a validar al guardar.");
        seleccionar.setEnabled(false);
    }

    public Horario getHorarioSeleccionado() {
        return elegido;
    }
}
