import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/servicios/servicio_firestore.dart'; 

class GallosProveedor extends ChangeNotifier {
  List<Gallo> _gallos = [];
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
            print('🔴 ERROR cargando gallo ${doc.id}: $error');
          }
        }
        _gallos = listaTemporal;
        notifyListeners();
      },
      onError: (error) {
        print('⚠️ Error Firestore: $error');
      },
    );
  }

  // ==================== GETTERS ====================
  List<Gallo> get gallos => List<Gallo>.unmodifiable(_gallos);

  // 🔥 NUEVO: Getter que revisa si hay gallos con etiquetas viejas
  bool get requiereActualizacionEtapa {
    return _gallos.any((g) => g.etapaVida == 'Levante' || g.etapaVida == 'Descanso');
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
        resultado = resultado.where((gallo) => gallo.etapaVida == 'Levante' || gallo.etapaVida == 'Descanso').toList();
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
  Future<void> crearGallo(Gallo nuevoGallo) async {
    try {
      final existe = await _servicioFirestore.validarPlacaDuplicada(nuevoGallo.placa);
      if (existe) throw Exception('Ya existe un gallo con la placa ${nuevoGallo.placa}.');
      await _servicioFirestore.crearGallo(nuevoGallo.toMap());
    } catch (error) {
      rethrow;
    }
  }

  Future<void> actualizarGallo(Gallo galloEditado) async {
    try {
      final existe = await _servicioFirestore.validarPlacaDuplicada(
        galloEditado.placa, idExcluir: galloEditado.id
      );
      if (existe) throw Exception('La placa ya está en uso.');
      await _servicioFirestore.actualizarGallo(galloEditado.id, galloEditado.toMap());
    } catch (error) {
      rethrow;
    }
  }

  Future<void> eliminarGallo(String idGallo) async {
    try {
      final gallo = obtenerGalloPorId(idGallo);
      if (gallo != null && gallo.fotoPath != null) {
         final archivo = File(gallo.fotoPath!);
         if (await archivo.exists()) await archivo.delete(); 
      }
      await _servicioFirestore.eliminarGallo(idGallo);
    } catch (error) {
      rethrow;
    }
  }

  Gallo? obtenerGalloPorId(String idGallo) {
    try {
      return _gallos.firstWhere((gallo) => gallo.id == idGallo);
    } catch (e) { return null; }
  }

  bool validarPlacaDuplicada(String placa) {
    return _gallos.any((g) => g.placa.toLowerCase() == placa.toLowerCase());
  }
  
  Future<void> cargarGallos() async {}

  @override
  void dispose() {
    _gallosSubscription?.cancel();
    _authSubscription?.cancel(); 
    super.dispose();
  }
}