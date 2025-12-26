import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform, Directory;
import 'dart:async';
import 'package:path/path.dart' as ruta_paquete;

/// Clase AyudanteDB - Gestor de la base de datos SQLite
///
/// Implementa el patrón Singleton para asegurar una única instancia
/// de la base de datos en toda la aplicación.
///
/// Características:
/// - Administra la conexión a SQLite
/// - Crea y gestiona la tabla 'Gallos'
/// - Compatible con Android, iOS, Windows y Desktop
/// - Manejo automático de rutas según la plataforma
///
/// Uso:
/// ```dart
/// final db = AyudanteDB.instancia;
/// await db.inicializarDB();
/// ```
class AyudanteDB {
  /// Variable privada estática que almacena la única instancia del ayudante
  static final AyudanteDB _instancia = AyudanteDB._interno();

  /// Instancia privada de la base de datos
  late Database _baseDatos;

  /// Constructor privado para implementar el patrón Singleton
  /// El parámetro fijo es requerido para evitar duplicación
  AyudanteDB._interno();

  /// Getter para obtener la instancia única del AyudanteDB
  ///
  /// Retorna: [AyudanteDB] - Instancia única del gestor de base de datos
  static AyudanteDB get instancia => _instancia;

  /// Getter para acceder a la instancia de la base de datos
  ///
  /// Retorna: [Database] - Conexión activa a SQLite
  ///
  /// Nota: Lanzará una excepción si se accede antes de inicializar
  Database get baseDatos => _baseDatos;

  /// Inicializa la base de datos SQLite
  ///
  /// Este método realiza las siguientes operaciones:
  /// 1. Configura el soporte para SQLite en Desktop (Windows, macOS, Linux)
  /// 2. Obtiene la ruta de almacenamiento según la plataforma
  /// 3. Abre o crea el archivo de base de datos 'castasoft_db.db'
  /// 4. Ejecuta el script de creación de tabla en la primera inicialización
  ///
  /// Retorna: [Future<Database>] - La instancia de base de datos inicializada
  ///
  /// Throws: Lanza excepciones si hay errores en la creación de la BD
  Future<Database> inicializarDB() async {
    // Configurar soporte para FFI en plataformas Desktop
    _configurarSoporteDesktop();

    // Obtener la ruta de la base de datos según la plataforma
    final rutaDB = await _obtenerRutaDB();

    // Abrir o crear la base de datos
    _baseDatos = await openDatabase(
      rutaDB,
      // Incrementamos la versión para soportar nuevas columnas en la tabla Gallos
      version: 2,
      onCreate: _crearTablas,
      onConfigure: _configurarBaseDatos,
      onUpgrade: _onUpgrade,
    );

    return _baseDatos;
  }

  /// Configura el soporte para SQLite en plataformas Desktop (FFI)
  ///
  /// En Windows, macOS y Linux se requiere sqflite_common_ffi
  /// para acceder a la base de datos usando FFI (Foreign Function Interface)
  void _configurarSoporteDesktop() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Obtiene la ruta completa del archivo de la base de datos
  ///
  /// En Android e iOS: Utiliza [getApplicationDocumentsDirectory]
  /// En Windows, macOS, Linux: Utiliza [getApplicationSupportDirectory]
  ///
  /// Retorna: [Future<String>] - Ruta completa al archivo de base de datos
  Future<String> _obtenerRutaDB() async {
    // Determinar el directorio según la plataforma
    final Directory directorioBase;

    if (Platform.isAndroid || Platform.isIOS) {
      // Para móviles: documentos de la aplicación
      directorioBase = await getApplicationDocumentsDirectory();
    } else {
      // Para Desktop: soporte de aplicación
      directorioBase = await getApplicationSupportDirectory();
    }

    // Crear la ruta completa del archivo de base de datos
    final rutaCompleta = ruta_paquete.join(
      directorioBase.path,
      'castasoft_db.db',
    );

    return rutaCompleta;
  }

  /// Configura la base de datos antes de abrirla
  ///
  /// Parámetro: [database] - La instancia de base de datos a configurar
  ///
  /// Configuración:
  /// - Activa claves foráneas (FOREIGN KEY)
  /// - Mejora el rendimiento y la integridad referencial
  Future<void> _configurarBaseDatos(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  /// Crea las tablas de la base de datos en la primera ejecución
  ///
  /// Parámetros:
  /// - [database] - Instancia de base de datos
  /// - [version] - Versión del esquema de base de datos
  ///
  /// Tablas creadas:
  /// - Gallos: Almacena la información de los gallos
  Future<void> _crearTablas(Database database, int version) async {
    // Crear tabla de Gallos
    await database.execute('''
      CREATE TABLE Gallos (
        id TEXT PRIMARY KEY,
        placa TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        sexo TEXT NOT NULL,
        fechaNacimiento TEXT NOT NULL,
        idPadre TEXT,
        idMadre TEXT,
        padreId TEXT,
        madreId TEXT,
        peso REAL,
        jaula TEXT,
        criaderoOrigen TEXT DEFAULT 'Propio',
        lineaGenetica TEXT NOT NULL,
        colorPluma TEXT NOT NULL,
        faseLunar TEXT NOT NULL,
        fotoPath TEXT,
        estado TEXT NOT NULL,
        notas TEXT,
        fechaCreacion TEXT NOT NULL,
        fechaActualizacion TEXT NOT NULL
      )
      ''');

    // Crear índices para optimizar búsquedas frecuentes
    await database.execute('CREATE INDEX idx_gallos_placa ON Gallos(placa)');

    await database.execute('CREATE INDEX idx_gallos_estado ON Gallos(estado)');

    await database.execute(
      'CREATE INDEX idx_gallos_lineaGenetica ON Gallos(lineaGenetica)',
    );
  }

  /// Maneja actualizaciones del esquema de la base de datos
  ///
  /// Añade de forma segura las columnas nuevas que requieren los modelos
  /// actuales. Para evitar errores en instalaciones existentes, primero
  /// inspecciona las columnas presentes y solo ejecuta los `ALTER TABLE`
  /// para las que faltan.
  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Obtener lista de columnas existentes
      final List<Map<String, Object?>> info = await database.rawQuery(
        "PRAGMA table_info(Gallos)",
      );
      final existingColumns = info.map((row) => row['name'] as String).toSet();

      // Definiciones de las nuevas columnas que queremos asegurar
      final columnsToAdd = <String, String>{
        'padreId': 'TEXT',
        'madreId': 'TEXT',
        'peso': 'REAL',
        'jaula': 'TEXT',
        'criaderoOrigen': "TEXT DEFAULT 'Propio'",
      };

      for (final entry in columnsToAdd.entries) {
        final columnName = entry.key;
        final definition = entry.value;
        if (!existingColumns.contains(columnName)) {
          await database.execute(
            'ALTER TABLE Gallos ADD COLUMN $columnName $definition',
          );
        }
      }
    }
  }

  /// Cierra la conexión a la base de datos
  ///
  /// Debe ser llamado cuando la aplicación se cierra
  /// para liberar recursos correctamente
  ///
  /// Retorna: [Future<void>]
  Future<void> cerrar() async {
    await _baseDatos.close();
  }
}
