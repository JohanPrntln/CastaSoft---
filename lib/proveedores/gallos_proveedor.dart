import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/datos/ayudante_db.dart';

/// Proveedor de estado para gestionar los gallos de la aplicación
///
/// Implementa el patrón [ChangeNotifier] para proporcionar:
/// - Notificación de cambios a los widgets observadores (Provider)
/// - Gestión centralizada de estado de los gallos
/// - Operaciones CRUD completas sobre la base de datos
/// - Estadísticas y consultas sobre los gallos
///
/// Características principales:
/// - Inicializa la base de datos automáticamente en el constructor
/// - Mantiene una lista en memoria de todos los gallos
/// - Sincroniza automáticamente con SQLite
/// - Notifica a la interfaz de usuario cada vez que hay cambios
///
/// Uso con Provider:
/// ```dart
/// MultiProvider(
///   providers: [
///     ChangeNotifierProvider(create: (_) => GallosProveedor()),
///   ],
///   child: const MiAplicacion(),
/// )
/// ```
class GallosProveedor extends ChangeNotifier {
  /// Lista privada que almacena todos los gallos en memoria
  /// Esta lista se sincroniza constantemente con la base de datos
  late List<Gallo> _gallos = [];

  /// Referencia a la instancia única del ayudante de base de datos (Singleton)
  final AyudanteDB _ayudanteDB = AyudanteDB.instancia;

  /// Texto de búsqueda para filtrar gallos
  String _filtroTexto = '';

  /// Estado seleccionado para filtrar gallos ('Todos', 'Activo', 'Vendido', 'Retirado')
  String _filtroEstado = 'Todos';

  /// Constructor del proveedor
  ///
  /// Inicializa la base de datos automáticamente al crear la instancia
  /// del proveedor. Esto asegura que la base de datos esté lista
  /// antes de cualquier operación.
  GallosProveedor() {
    _inicializarBaseDatos();
  }

  // ==================== SETTERS PARA FILTROS ====================

  /// Establece el texto de búsqueda y notifica cambios
  ///
  /// Parámetros:
  /// - [texto] - Texto a buscar en nombre, placa o color
  ///
  /// Ejemplo:
  /// ```dart
  /// gallosProveedor.setFiltroTexto('Rojo');
  /// ```
  void setFiltroTexto(String texto) {
    _filtroTexto = texto;
    notifyListeners();
  }

  /// Establece el estado de filtro y notifica cambios
  ///
  /// Parámetros:
  /// - [estado] - Estado a filtrar ('Todos', 'Activo', 'Vendido', 'Retirado')
  ///
  /// Ejemplo:
  /// ```dart
  /// gallosProveedor.setFiltroEstado('Activo');
  /// ```
  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  /// Getter público para acceder a la lista de gallos
  ///
  /// Retorna: [List<Gallo>] - Lista inmutable (copia) de todos los gallos
  ///
  /// Nota: Se retorna una copia de la lista para evitar
  /// modificaciones externas que no notifiquen cambios
  List<Gallo> get gallos => List<Gallo>.unmodifiable(_gallos);

  /// Getter para obtener la lista de gallos filtrada por búsqueda y estado
  ///
  /// Aplica filtros de:
  /// - **Texto de búsqueda:** Busca en nombre, placa y color (insensible a mayúsculas)
  /// - **Estado:** Filtra por estado si no es 'Todos'
  ///
  /// Retorna: [List<Gallo>] - Lista filtrada de gallos
  ///
  /// Ejemplo:
  /// ```dart
  /// // Si se busca "rojo" y estado es "Activo"
  /// final gallosFiltrados = gallosProveedor.gallosFiltrados;
  /// // Retorna solo gallos activos con nombre, placa o color "rojo"
  /// ```
  List<Gallo> get gallosFiltrados {
    List<Gallo> resultado = _gallos;

    // Filtrar por texto de búsqueda
    if (_filtroTexto.isNotEmpty) {
      final textoLower = _filtroTexto.toLowerCase();
      resultado = resultado.where((gallo) {
        return gallo.nombre.toLowerCase().contains(textoLower) ||
            gallo.placa.toLowerCase().contains(textoLower) ||
            gallo.colorPluma.toLowerCase().contains(textoLower);
      }).toList();
    }

    // Filtrar por estado
    if (_filtroEstado != 'Todos') {
      resultado = resultado
          .where((gallo) => gallo.estado == _filtroEstado)
          .toList();
    }

    return List<Gallo>.unmodifiable(resultado);
  }

  /// Inicializa la base de datos de forma asíncrona
  ///
  /// Método privado que se ejecuta en el constructor
  /// Prepara la base de datos para operaciones
  void _inicializarBaseDatos() {
    _ayudanteDB.inicializarDB();
  }

  // ==================== OPERACIONES CRUD ====================

  /// Carga todos los gallos desde la base de datos
  ///
  /// **Operación:** READ (Lectura)
  ///
  /// Este método:
  /// 1. Ejecuta una consulta SELECT a la tabla 'Gallos'
  /// 2. Deserializa cada fila a un objeto [Gallo] usando [Gallo.fromMap]
  /// 3. Actualiza la lista privada `_gallos`
  /// 4. Notifica a los observadores del cambio
  ///
  /// Retorna: [Future<void>]
  ///
  /// Throws: Puede lanzar excepciones si hay error en la BD
  ///
  /// Ejemplo:
  /// ```dart
  /// await gallosProveedor.cargarGallos();
  /// print('Gallos cargados: ${gallosProveedor.gallos.length}');
  /// ```
  Future<void> cargarGallos() async {
    try {
      // Ejecutar consulta SELECT * FROM Gallos
      final listaMapas = await _ayudanteDB.baseDatos.query('Gallos');

      // Convertir cada mapa a un objeto Gallo
      _gallos = listaMapas.map((mapa) => Gallo.fromMap(mapa)).toList();

      // Notificar a los observadores que la lista cambió
      notifyListeners();
    } catch (error) {
      print('Error al cargar gallos: $error');
      rethrow;
    }
  }

  /// Crea y guarda un nuevo gallo en la base de datos
  ///
  /// **Operación:** CREATE (Creación)
  ///
  /// Este método:
  /// 1. Valida que el gallo no exista (por ID)
  /// 2. Convierte el objeto [Gallo] a un mapa usando [toMap]
  /// 3. Inserta el mapa en la tabla 'Gallos'
  /// 4. Añade el gallo a la lista en memoria
  /// 5. Notifica a los observadores
  ///
  /// Parámetros:
  /// - [nuevoGallo] - Objeto [Gallo] con los datos a guardar
  ///
  /// Retorna: [Future<void>]
  ///
  /// Throws: Lanza [Exception] si el gallo ya existe
  ///
  /// Ejemplo:
  /// ```dart
  /// final gallo = Gallo(
  ///   id: 'gallo_001',
  ///   placa: 'A001',
  ///   nombre: 'Rojo',
  ///   sexo: 'Macho',
  ///   fechaNacimiento: DateTime(2023, 1, 15),
  ///   lineaGenetica: 'Kelso',
  ///   colorPluma: 'Rojo',
  ///   faseLunar: 'Luna Llena',
  ///   estado: 'Activo',
  /// );
  /// await gallosProveedor.crearGallo(gallo);
  /// ```
  Future<void> crearGallo(Gallo nuevoGallo) async {
    try {
      // Verificar si el gallo ya existe
      if (_gallos.any((gallo) => gallo.id == nuevoGallo.id)) {
        throw Exception('El gallo con ID ${nuevoGallo.id} ya existe');
      }

      // Validación de negocio: placa única (insensible a mayúsculas/minúsculas)
      if (_existePlaca(nuevoGallo.placa)) {
        throw Exception('Ya existe un gallo con la placa ${nuevoGallo.placa}.');
      }

      // Convertir el objeto Gallo a mapa para la base de datos
      final mapaGallo = nuevoGallo.toMap();

      // Añadir timestamps obligatorios que exige el esquema
      final nowIso = DateTime.now().toIso8601String();
      mapaGallo['fechaCreacion'] = nowIso;
      mapaGallo['fechaActualizacion'] = nowIso;

      // Insertar en la tabla Gallos
      // IMPORTANTE: conflictAlgorithm.abort respeta la constrainta UNIQUE en placa
      await _ayudanteDB.baseDatos.insert(
        'Gallos',
        mapaGallo,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // Añadir a la lista en memoria
      _gallos.add(nuevoGallo);

      // Notificar cambios a observadores
      notifyListeners();

      print('Gallo creado: ${nuevoGallo.nombre}');
    } catch (error) {
      print('Error al crear gallo: $error');
      rethrow;
    }
  }

  /// Actualiza un gallo existente en la base de datos
  ///
  /// **Operación:** UPDATE (Actualización)
  ///
  /// Este método:
  /// 1. Valida que el gallo exista en la lista
  /// 2. Convierte el objeto [Gallo] modificado a un mapa
  /// 3. Actualiza el registro en la tabla 'Gallos' por su ID
  /// 4. Actualiza la instancia correspondiente en la lista en memoria
  /// 5. Notifica a los observadores
  ///
  /// Parámetros:
  /// - [galloEditado] - Objeto [Gallo] con los datos actualizados
  ///
  /// Retorna: [Future<void>]
  ///
  /// Throws: Lanza [Exception] si el gallo no existe
  ///
  /// Ejemplo:
  /// ```dart
  /// final galloActualizado = galloExistente.copyWith(nombre: 'Nuevo Nombre');
  /// await gallosProveedor.actualizarGallo(galloActualizado);
  /// ```
  Future<void> actualizarGallo(Gallo galloEditado) async {
    try {
      // Verificar si el gallo existe
      final indiceGallo = _gallos.indexWhere((g) => g.id == galloEditado.id);
      if (indiceGallo == -1) {
        throw Exception('El gallo con ID ${galloEditado.id} no existe');
      }

      // Validación de negocio: placa única al actualizar (ignorar el propio ID)
      if (_existePlaca(galloEditado.placa, idExcluir: galloEditado.id)) {
        throw Exception(
          'Ya existe un gallo con la placa ${galloEditado.placa}.',
        );
      }

      // Convertir a mapa para actualización
      final mapaGallo = galloEditado.toMap();

      // Actualizar la fecha de actualización exigida por el esquema
      mapaGallo['fechaActualizacion'] = DateTime.now().toIso8601String();

      // Ejecutar UPDATE en la base de datos
      await _ayudanteDB.baseDatos.update(
        'Gallos',
        mapaGallo,
        where: 'id = ?',
        whereArgs: [galloEditado.id],
      );

      // Actualizar en la lista en memoria
      _gallos[indiceGallo] = galloEditado;

      // Notificar cambios
      notifyListeners();

      print('Gallo actualizado: ${galloEditado.nombre}');
    } catch (error) {
      print('Error al actualizar gallo: $error');
      rethrow;
    }
  }

  /// Elimina un gallo de la base de datos
  ///
  /// **Operación:** DELETE (Eliminación)
  ///
  /// Este método:
  /// 1. Valida que el gallo exista
  /// 2. Ejecuta DELETE en la tabla 'Gallos' por ID
  /// 3. Remueve el gallo de la lista en memoria
  /// 4. Notifica a los observadores
  ///
  /// Parámetros:
  /// - [idGallo] - ID único del gallo a eliminar
  ///
  /// Retorna: [Future<void>]
  ///
  /// Throws: Lanza [Exception] si el gallo no existe
  ///
  /// Ejemplo:
  /// ```dart
  /// await gallosProveedor.eliminarGallo('gallo_001');
  /// ```
  Future<void> eliminarGallo(String idGallo) async {
    try {
      // Encontrar el gallo en la lista
      final galloAEliminar = _gallos.firstWhere(
        (gallo) => gallo.id == idGallo,
        orElse: () {
          throw Exception('El gallo con ID $idGallo no existe');
        },
      );

      // Eliminar archivo de imagen asociado (si existe) para evitar archivos huérfanos
      try {
        if (galloAEliminar.fotoPath != null &&
            galloAEliminar.fotoPath!.isNotEmpty) {
          final archivoFoto = File(galloAEliminar.fotoPath!);
          if (await archivoFoto.exists()) {
            await archivoFoto.delete();
          }
        }
      } catch (e) {
        // No debe impedir la eliminación del registro en la BD; registrar y continuar
        print('Advertencia: no se pudo eliminar la imagen asociada: $e');
      }

      // Ejecutar DELETE en la base de datos
      await _ayudanteDB.baseDatos.delete(
        'Gallos',
        where: 'id = ?',
        whereArgs: [idGallo],
      );

      // Remover de la lista en memoria
      _gallos.remove(galloAEliminar);

      // Notificar cambios
      notifyListeners();

      print('Gallo eliminado: ${galloAEliminar.nombre}');
    } catch (error) {
      print('Error al eliminar gallo: $error');
      rethrow;
    }
  }

  // ==================== MÉTODOS DE CONSULTA ====================

  /// Obtiene estadísticas de los gallos por estado
  ///
  /// Analiza la lista en memoria y cuenta cuántos gallos hay
  /// en cada estado posible.
  ///
  /// Estados posibles:
  /// - 'Activo' - Gallos disponibles en el sistema
  /// - 'Vendido' - Gallos que han sido vendidos
  /// - 'Baja' - Gallos dados de baja del sistema
  ///
  /// Retorna: [Map<String, int>] con conteo por estado
  ///
  /// Ejemplo:
  /// ```dart
  /// final estadisticas = gallosProveedor.obtenerEstadisticas();
  /// print(estadisticas); // {activos: 5, vendidos: 3, baja: 1}
  /// ```
  ///
  /// Nota: Este es un método síncrono que no requiere acceso a la BD
  Map<String, int> obtenerEstadisticas() {
    // Inicializar mapa con conteos en 0
    final estadisticas = {'activos': 0, 'vendidos': 0, 'baja': 0};

    // Contar gallos por estado
    for (final gallo in _gallos) {
      switch (gallo.estado) {
        case 'Activo':
          estadisticas['activos'] = (estadisticas['activos'] ?? 0) + 1;
          break;
        case 'Vendido':
          estadisticas['vendidos'] = (estadisticas['vendidos'] ?? 0) + 1;
          break;
        case 'Baja':
          estadisticas['baja'] = (estadisticas['baja'] ?? 0) + 1;
          break;
        default:
          print('Estado desconocido: ${gallo.estado}');
      }
    }

    return estadisticas;
  }

  /// Método para obtener un gallo específico por su ID
  ///
  /// Búsqueda rápida en la lista en memoria
  ///
  /// Parámetros:
  /// - [idGallo] - ID único del gallo
  ///
  /// Retorna: [Gallo?] - El gallo si existe, null si no existe
  ///
  /// Ejemplo:
  /// ```dart
  /// final gallo = gallosProveedor.obtenerGalloPorId('gallo_001');
  /// if (gallo != null) {
  ///   print('Gallo encontrado: ${gallo.nombre}');
  /// }
  /// ```
  Gallo? obtenerGalloPorId(String idGallo) {
    try {
      return _gallos.firstWhere((gallo) => gallo.id == idGallo);
    } catch (error) {
      return null;
    }
  }

  /// Método para obtener gallos filtrados por estado
  ///
  /// Filtra la lista en memoria según el estado especificado
  ///
  /// Parámetros:
  /// - [estado] - Estado a filtrar ('Activo', 'Vendido', 'Baja')
  ///
  /// Retorna: [List<Gallo>] - Lista de gallos con el estado especificado
  ///
  /// Ejemplo:
  /// ```dart
  /// final gallosActivos = gallosProveedor.obtenerPorEstado('Activo');
  /// print('Gallos activos: ${gallosActivos.length}');
  /// ```
  List<Gallo> obtenerPorEstado(String estado) {
    return _gallos.where((gallo) => gallo.estado == estado).toList();
  }

  /// Valida si una placa ya existe en la base de datos
  ///
  /// Parámetro:
  /// - [placa] - Número de anillo/placa a validar
  ///
  /// Retorna: [bool] - true si la placa existe, false si está disponible
  ///
  /// Ejemplo:
  /// ```dart
  /// final placaExiste = gallosProveedor.validarPlacaDuplicada('1234');
  /// if (placaExiste) {
  ///   print('Esta placa ya está registrada');
  /// }
  /// ```
  bool validarPlacaDuplicada(String placa) {
    return _gallos.any(
      (gallo) => gallo.placa.toLowerCase() == placa.toLowerCase(),
    );
  }

  /// Comprueba si ya existe un gallo con la misma placa
  ///
  /// - La comparación es insensible a mayúsculas/minúsculas.
  /// - Si se proporciona `idExcluir`, se ignora ese ID (útil al editar).
  bool _existePlaca(String? placa, {String? idExcluir}) {
    if (placa == null || placa.trim().isEmpty) return false;
    final placaLower = placa.toLowerCase();
    for (final g in _gallos) {
      if (idExcluir != null && g.id == idExcluir) continue;
      final gPlaca = g.placa.toLowerCase();
      if (gPlaca == placaLower) return true;
    }
    return false;
  }

  /// Cierra la base de datos al destruir el proveedor
  ///
  /// Importante llamar cuando la aplicación se cierra
  @override
  void dispose() {
    _ayudanteDB.cerrar();
    super.dispose();
  }
}
