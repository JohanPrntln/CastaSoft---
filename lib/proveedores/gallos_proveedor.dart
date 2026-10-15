import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/servicios/servicio_firestore.dart'; 

class GallosProveedor extends ChangeNotifier {
  List<Gallo> _gallos = [];
  // Índice id -> Gallo para resolver padres/madres en O(1) desde la UI
  Map<String, Gallo> _indicePorId = {};
  // true cuando ya llegó al menos un snapshot (de servidor o de caché local)
  bool _datosCargados = false;
  final ServicioFirestore _servicioFirestore = ServicioFirestore();
  StreamSubscription? _gallosSubscription;
  StreamSubscription? _authSubscription; 

  String _filtroTexto = '';
  String _filtroEstado = 'Todos';
  // NUEVO: Filtro para etapa de vida
  String _filtroEtapa = 'Todas';

  GallosProveedor() {
    _authSubscription = _servicioFirestore.auth.authStateChanges().listen((usuario) {
      if (usuario != null) {
        _iniciarEscuchaEnTiempoReal();
      } else {
        _gallos = [];
        _indicePorId = {};
        _datosCargados = false;
        _gallosSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void _iniciarEscuchaEnTiempoReal() {
    _gallosSubscription?.cancel();

    if (!_servicioFirestore.estaAutenticado) return;

    _gallosSubscription = _servicioFirestore.gallosEnTiempoReal().listen(
      (snapshot) {
        final List<Gallo> listaTemporal = [];
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            if (!data.containsKey('userId')) {
               data['userId'] = _servicioFirestore.uidUsuarioActual;
            }
            listaTemporal.add(Gallo.fromMap(data));
          } catch (error) {
            debugPrint('🔴 ERROR cargando gallo ${doc.id}: $error');
          }
        }
        _gallos = listaTemporal;
        _indicePorId = {for (final g in listaTemporal) g.id: g};
        _datosCargados = true;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('⚠️ Error Firestore: $error');
      },
    );
  }

  // ==================== GETTERS ====================
  List<Gallo> get gallos => List<Gallo>.unmodifiable(_gallos);

  // 🔥 NUEVO: Getter que revisa si hay gallos con etiquetas viejas
  bool get requiereActualizacionEtapa {
    return _gallos.any((g) => Gallo.etapasLegadas.contains(g.etapaVida));
  }

  // Getter inteligente con TODOS los filtros
  List<Gallo> get gallosFiltrados {
    List<Gallo> resultado = _gallos;

    // 1. Filtro Texto
    if (_filtroTexto.isNotEmpty) {
      final textoLower = _filtroTexto.toLowerCase();
      resultado = resultado.where((gallo) {
        return gallo.nombre.toLowerCase().contains(textoLower) ||
            gallo.placa.toLowerCase().contains(textoLower) ||
            gallo.colorPluma.toLowerCase().contains(textoLower);
      }).toList();
    }

    // 2. Filtro Estado (Activo, Vendido...)
    if (_filtroEstado != 'Todos') {
      resultado = resultado.where((gallo) => gallo.estado == _filtroEstado).toList();
    }

    // 3. Filtro Etapa Modificado para la migración
    if (_filtroEtapa != 'Todas') {
      if (_filtroEtapa == '⚠️ Actualizar') {
        // Trae los gallos huérfanos
        resultado = resultado.where((gallo) => Gallo.etapasLegadas.contains(gallo.etapaVida)).toList();
      } else {
        // Trae los normales
        resultado = resultado.where((gallo) => gallo.etapaVida == _filtroEtapa).toList();
      }
    }

    return List<Gallo>.unmodifiable(resultado);
  }

  // ==================== SETTERS ====================
  void setFiltroTexto(String texto) {
    _filtroTexto = texto;
    notifyListeners();
  }

  void setFiltroEstado(String estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  // NUEVO: Setter para el filtro de etapa
  void setFiltroEtapa(String etapa) {
    _filtroEtapa = etapa;
    notifyListeners();
  }

  // ==================== ESTADÍSTICAS AVANZADAS ====================
  // Esto alimenta tu nueva tarjeta de KPIs
  Map<String, int> obtenerConteoDetallado() {
    int padrotes = 0;
    int madrillas = 0;
    int crias = 0;

    for (var g in _gallos) {
      if (g.estado == 'Activo') { // Solo contamos activos
        if (g.etapaVida == 'Padrote') padrotes++;
        if (g.etapaVida == 'Madrilla') madrillas++;
        if (g.etapaVida == 'Cría') crias++;
      }
    }

    return {
      'padrotes': padrotes,
      'madrillas': madrillas,
      'crias': crias,
      'total': _gallos.where((g) => g.estado == 'Activo').length
    };
  }

  Map<String, int> obtenerEstadisticas() {
    final estadisticas = {'activos': 0, 'vendidos': 0, 'baja': 0};
    for (final gallo in _gallos) {
      switch (gallo.estado) {
        case 'Activo': estadisticas['activos'] = (estadisticas['activos'] ?? 0) + 1; break;
        case 'Vendido': estadisticas['vendidos'] = (estadisticas['vendidos'] ?? 0) + 1; break;
        case 'Baja': estadisticas['baja'] = (estadisticas['baja'] ?? 0) + 1; break;
      }
    }
    return estadisticas;
  }

  // ==================== CRUD ====================
  // Retornan `true` si el servidor confirmó la escritura, `false` si quedó en
  // la caché local de Firestore pendiente de sincronizar (modo offline).

  Future<bool> crearGallo(Gallo nuevoGallo) async {
    if (await _placaEnUso(nuevoGallo.placa)) {
      throw Exception('Ya existe un gallo con la placa ${nuevoGallo.placa}.');
    }
    return _servicioFirestore.crearGallo(nuevoGallo.toMap());
  }

  Future<bool> actualizarGallo(Gallo galloEditado) async {
    if (await _placaEnUso(galloEditado.placa, idExcluir: galloEditado.id)) {
      throw Exception('La placa ya está en uso.');
    }
    return _servicioFirestore.actualizarGallo(galloEditado.id, galloEditado.toMap());
  }

  Future<bool> eliminarGallo(String idGallo) async {
    final gallo = obtenerGalloPorId(idGallo);
    final String? ruta = gallo?.fotoPath;
    // Las fotos actuales viven dentro del documento ('base64,...'): se van con él.
    // Solo se borra un archivo físico para rutas legadas en plataformas nativas
    // (en Web `File` no existe y lanzaría UnsupportedError).
    if (!kIsWeb && ruta != null && ruta.isNotEmpty && !ruta.startsWith('base64,')) {
      try {
        final archivo = File(ruta);
        if (await archivo.exists()) await archivo.delete();
      } catch (e) {
        debugPrint('⚠️ No se pudo borrar la foto local $ruta: $e');
      }
    }
    return _servicioFirestore.eliminarGallo(idGallo);
  }

  Gallo? obtenerGalloPorId(String idGallo) => _indicePorId[idGallo];

  /// Nombre a mostrar para un padre/madre: prioriza el texto desnormalizado
  /// guardado en el gallo (RN-03) y, si falta, lo resuelve por id en O(1).
  String resolverNombrePariente(String? nombreGuardado, String? idPariente) {
    if (nombreGuardado != null && nombreGuardado.isNotEmpty) return nombreGuardado;
    if (idPariente == null) return 'Desconocido';
    return _indicePorId[idPariente]?.nombre ?? 'Desconocido';
  }

  /// RN-01 en memoria: `_gallos` es el espejo en tiempo real de Firestore
  /// (incluye escrituras offline pendientes), así que no requiere red.
  /// Comparación sin distinguir mayúsculas ni espacios extremos.
  bool validarPlacaDuplicada(String placa, {String? idExcluir}) {
    final buscada = placa.trim().toLowerCase();
    return _gallos.any((g) => g.id != idExcluir && g.placa.trim().toLowerCase() == buscada);
  }

  Future<bool> _placaEnUso(String placa, {String? idExcluir}) async {
    if (validarPlacaDuplicada(placa, idExcluir: idExcluir)) return true;
    if (_datosCargados) return false;
    // Aún no llega el primer snapshot: respaldo en Firestore (con fallback a caché)
    return _servicioFirestore.validarPlacaDuplicada(placa, idExcluir: idExcluir);
  }
  
  Future<void> cargarGallos() async {}

  @override
  void dispose() {
    _gallosSubscription?.cancel();
    _authSubscription?.cancel(); 
    super.dispose();
  }
}
