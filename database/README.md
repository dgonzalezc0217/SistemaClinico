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

La carpeta principal del proyecto contiene `src`, `nbproject` y `build.xml`.

Dentro de ella, la carpeta `database` reúne el script, esta guía y la carpeta de la base local:

| Archivo | Ubicación dentro del proyecto | Función |
|---|---|---|
| Script de creación | `database/crear_clinica.sql` | Crea las tablas y relaciones. |
| Esta guía | `database/README.md` | Explica la configuración. |
| Base local | `database/datos/clinica.db` | Guarda las tablas y los datos utilizados en este computador. |

La ruta `database/datos/clinica.db` significa: entrar en `database`, después en `datos` y abrir `clinica.db`.

## 3. Crear la base de datos

Estos pasos se realizan una sola vez:

1. Abrir la carpeta principal del proyecto.
2. Entrar en `database`.
3. Crear dentro de ella una carpeta llamada `datos`, si todavía no existe.
4. Abrir el programa utilizado para administrar SQLite.
5. Seleccionar la opción para crear una base nueva.
6. Guardarla como `clinica.db` dentro de `database/datos`.
7. Si el programa solicita crear una tabla manualmente, cancelar ese formulario: las tablas se crearán mediante el script.
8. Continuar con el apartado 4, «Ejecutar el script de creación».

**Si `database/datos/clinica.db` ya existe y contiene las 40 tablas, no volver a crearla ni ejecutar el script de creación. Continuar con las comprobaciones del apartado 5.**

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

1. Abrir el programa de SQLite.
2. Seleccionar la opción para abrir una base existente.
3. Buscar la carpeta principal del proyecto.
4. Entrar en `database` y después en `datos`.
5. Abrir `clinica.db`.
6. Activar las relaciones:

```sql
PRAGMA foreign_keys = ON;
```

No volver a ejecutar `crear_clinica.sql` sobre esta base ya creada.

La activación de las relaciones también debe realizarse en cada conexión que abra Java, antes de iniciar operaciones de guardado.

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
- El archivo `.gitignore` ubicado en la carpeta principal del proyecto.

Conservar localmente:

- `database/datos/clinica.db`
- Archivos auxiliares de SQLite.
- Copias de respaldo y datos reales de pacientes.

En el `.gitignore` de la carpeta principal, conservar las reglas existentes y utilizar:

```gitignore
# Base de datos local
/database/datos/

# Archivos SQLite y archivos auxiliares
*.db
*.db-journal
*.db-wal
*.db-shm
*.sqlite
*.sqlite3
```

Si se había agregado la regla `/datos/`, sustituirla por `/database/datos/`.

**Al subir archivos desde la página de GitHub, seleccionar únicamente `crear_clinica.sql` y `README.md` dentro de `database`. No arrastrar toda la carpeta `database`, porque ahora también contiene la base local.**

## 10. Conexión con Java y cambios posteriores

La clase `src/Conexion/cConexion.java` debe utilizar esta ruta:

```text
jdbc:sqlite:database/datos/clinica.db
```

Esta ruta supone que la aplicación se ejecuta desde la carpeta principal del proyecto y que el controlador JDBC de SQLite está configurado.

Antes de conectar, comprobar que el archivo existe en esa ubicación. Una ruta equivocada podría provocar la creación de otra base vacía.

Subir el script a GitHub no conecta automáticamente la aplicación ni sincroniza los datos de los integrantes del equipo.

Para modificar una base que ya contiene información, preparar un script separado y realizar primero una copia de respaldo. Para copiar el archivo como respaldo, guardar los cambios y cerrar previamente la aplicación y el programa de SQLite.

Para copiar el archivo de la base como respaldo, guardar los cambios y cerrar previamente la aplicación y el programa de SQLite.
