# Base de datos del Sistema Clínico

Esta carpeta contiene el archivo `crear_clinica.sql`, que permite crear las 40 tablas de la base de datos y sus relaciones.

Cada integrante del equipo debe crear su propia base local siguiendo estas instrucciones.

## 1. Requisitos

- Tener el proyecto descargado en el computador.
- Tener un programa que permita abrir bases SQLite y ejecutar instrucciones SQL.
- Utilizar SQLite **3.37.0 o superior**.

Para comprobar la versión, ejecutar:

```sql
SELECT sqlite_version();
```

## 2. Ubicación de los archivos

La carpeta principal del proyecto es aquella que contiene `src`, `nbproject` y `build.xml`.

Los archivos deben organizarse así:

| Archivo | Ubicación | Función |
|---|---|---|
| `crear_clinica.sql` | `database/` | Instrucciones para crear la base. |
| `README.md` | `database/` | Esta guía. |
| `clinica.db` | `datos/` | Base de datos local que utilizará la aplicación. |

La ruta `datos/clinica.db` significa que el archivo `clinica.db` se encuentra dentro de la carpeta `datos`.

## 3. Crear la base de datos

Estos pasos se realizan una sola vez.

1. Dentro de la carpeta principal del proyecto, crear una carpeta llamada `datos`.
2. Abrir el programa utilizado para administrar SQLite.
3. Seleccionar la opción para crear una base de datos nueva.
4. Guardarla como `clinica.db` dentro de `datos`.
5. Si el programa solicita crear una tabla manualmente, cancelar ese formulario: las tablas se crearán mediante el script.
6. Abrir la sección para ejecutar instrucciones SQL.
7. Guardar cualquier cambio pendiente antes de continuar.

**Si ya tienes una base creada con las 40 tablas, no repitas la creación. Continúa con la comprobación del paso 5.**

## 4. Ejecutar el script de creación

Primero, ejecutar por separado:

```sql
PRAGMA foreign_keys = ON;
PRAGMA foreign_keys;
```

El resultado de la segunda instrucción debe ser **`1`**. Esto indica que SQLite comprobará las relaciones entre las tablas.

Si aparece `0`, guardar o descartar las operaciones pendientes y volver a ejecutar ambas instrucciones.

Después:

1. Abrir `database/crear_clinica.sql` con un editor de texto.
2. Copiar todo su contenido.
3. Pegarlo en el editor SQL de la base vacía.
4. Ejecutar el script completo.
5. Guardar los cambios si el programa lo solicita.

### Si aparece el error de transacciones

Si aparece:

```text
cannot start a transaction within a transaction
```

el programa ya tiene una operación abierta.

En ese caso:

1. Detener la ejecución.
2. Guardar o descartar las operaciones pendientes.
3. Comprobar que la base sigue vacía.
4. Quitar del código que vas a ejecutar únicamente estas dos instrucciones:

```sql
BEGIN IMMEDIATE;
COMMIT;
```

5. Activar nuevamente las relaciones y comprobar que `PRAGMA foreign_keys;` devuelve `1`.
6. Ejecutar todo el código restante.
7. Guardar los cambios.

En este procedimiento, el programa administra el guardado de la operación.

**Si aparece otro error, detenerse y revisar su mensaje antes de continuar. No ejecutar repetidamente el script sobre tablas ya creadas.**

## 5. Comprobar la creación

Ejecutar las siguientes consultas por separado.

### Cantidad de tablas

```sql
SELECT COUNT(*) AS cantidad_tablas
FROM sqlite_schema
WHERE type = 'table'
  AND name NOT LIKE 'sqlite_%';
```

Resultado esperado: **40**.

### Relaciones activadas

```sql
PRAGMA foreign_keys;
```

Resultado esperado: **1**.

### Relaciones sin errores

```sql
PRAGMA foreign_key_check;
```

Resultado esperado: **ninguna fila**.

### Estado de la base

```sql
PRAGMA integrity_check;
```

Resultado esperado: **ok**.

Estas comprobaciones revisan la estructura y su integridad básica; no sustituyen las pruebas de funcionamiento de la aplicación.

## 6. Abrir la base después de crearla

Para continuar trabajando:

1. Abrir el programa de SQLite.
2. Seleccionar la opción para abrir una base existente.
3. Elegir `datos/clinica.db`.
4. Activar las relaciones:

```sql
PRAGMA foreign_keys = ON;
```

**No volver a ejecutar `crear_clinica.sql`.** Ese archivo sirve para crear una base nueva.

La instrucción que activa las relaciones también debe ejecutarse en cada conexión que abra Java, antes de iniciar operaciones de guardado.

## 7. Reglas para ingresar información

- Los identificadores principales se generan automáticamente cuando se omiten al insertar.
- En las tablas de asociación se utilizan los identificadores de registros que ya existen.
- `NULL`, sin comillas, representa un dato desconocido o pendiente.
- Los campos de activación utilizan `1` para activo y `0` para inactivo.
- Las fechas se escriben como `2026-10-06`.
- Las fechas con hora se guardan en UTC como `2026-10-06 13:00:00`.
- Las horas de los turnos se guardan como `07:00:00`, según la hora local de la clínica.

### Dinero y cantidades facturadas

Los importes se guardan como números enteros de centavos:

| Valor | Número que se guarda |
|---|---:|
| 25 000 pesos | 2500000 |
| 25 000,50 pesos | 2500050 |

Los campos correspondientes son:

- `Detalle_Factura.precio_unitario_centavos`
- `Pago.valor_centavos`

En `Detalle_Factura.cantidad_milesimas`:

| Cantidad | Número que se guarda |
|---|---:|
| 1 unidad | 1000 |
| 2 unidades | 2000 |
| 2,5 unidades | 2500 |

Esta conversión de cantidades se aplica específicamente al detalle de factura.

Para consultar los totales:

```sql
SELECT *
FROM V_Resumen_Factura;
```

Los campos `total_centavos`, `pagado_centavos` y `saldo_centavos` se expresan en centavos.

## 8. Orden recomendado para registrar datos

1. Crear catálogos, usuarios y asignaciones de roles y permisos.
2. Registrar el paciente y su historia clínica.
3. Registrar agenda y cita cuando corresponda.
4. Crear el episodio de atención.
5. Crear la orden como `BORRADOR`.
6. Agregar sus detalles y las prescripciones necesarias.
7. Cambiar la orden a `EMITIDA`, completando los datos requeridos.
8. Registrar resultados, estudios y prestaciones realizadas.
9. Crear la factura como `BORRADOR`, agregar sus detalles y emitirla.
10. Registrar los pagos efectivos.

Las notas e informes firmados se conservan. Sus correcciones se registran mediante nuevas notas o versiones.

## 9. Archivos que se comparten en GitHub

Subir:

- `database/crear_clinica.sql`
- `database/README.md`
- El archivo `.gitignore` del proyecto.

Conservar localmente:

- `datos/clinica.db`
- Archivos auxiliares de SQLite.
- Copias de respaldo.
- Datos reales de pacientes y credenciales.

El archivo `.gitignore` debe incluir:

```gitignore
/datos/
*.db
*.db-journal
*.db-wal
*.db-shm
*.sqlite
*.sqlite3
```

Al cargar archivos desde la página de GitHub, seleccionar manualmente los archivos que se van a compartir.

## 10. Conexión con Java y cambios posteriores

La clase `src/Conexion/cConexion.java` debe implementar la conexión con SQLite.

La ruta prevista es:

```text
jdbc:sqlite:datos/clinica.db
```

Esta ruta supone que la aplicación se ejecuta desde la carpeta principal del proyecto y que el controlador JDBC de SQLite está configurado.

Subir el script a GitHub no conecta automáticamente la aplicación ni sincroniza los datos de los integrantes del equipo.

Si la base ya contiene información, no utilizar el script de creación para actualizarla. Preparar un script separado para cada cambio y realizar primero una copia de respaldo.

Para copiar el archivo de la base como respaldo, guardar los cambios y cerrar previamente la aplicación y el programa de SQLite.
