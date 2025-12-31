import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/servicios/servicio_firestore.dart'; 

class GallosProveedor extends ChangeNotifier {
  List<Gallo> _gallos = [];
  final ServicioFirestore _servicioFirestore = ServicioFirestore();
  StreamSubscription? _gallosSubscription;
  StreamSubscription? _authSubscription; // NUEVO: Para escuchar el login

  String _filtroTexto = '';
  String _filtroEstado = 'Todos';

  GallosProveedor() {
    // CAMBIO IMPORTANTE:
    // En lugar de intentar escuchar una sola vez, vigilamos el estado del usuario.
    // Si el usuario entra (login) o sale (logout), esto reacciona automáticamente.
    _authSubscription = _servicioFirestore.auth.authStateChanges().listen((usuario) {
      if (usuario != null) {
        // ¡Alguien entró! Conectamos el audífono de los gallos
        _iniciarEscuchaEnTiempoReal();
      } else {
        // Alguien salió. Limpiamos la lista y desconectamos.
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
        
        // Recorremos los documentos uno por uno con protección
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            
            // Parche de seguridad por si falta el userId
            if (!data.containsKey('userId')) {
               data['userId'] = _servicioFirestore.uidUsuarioActual;
            }
            
            // Intentamos convertirlo
            listaTemporal.add(Gallo.fromMap(data));
            
          } catch (error) {
            // ¡AQUÍ ESTÁ LA MAGIA! 
            // Si un gallo falla, te lo dirá en la consola pero no detendrá la app.
            print('🔴 ERROR GRAVE cargando el gallo con ID ${doc.id}:');
            print('👉 Razón del error: $error');
            print('👉 Datos que intentó leer: ${doc.data()}');
          }
        }

        _gallos = listaTemporal;
        notifyListeners();
      },
      onError: (error) {
        print('⚠️ Error general de conexión con Firestore: $error');
      },
    );
  }

  // ==================== GETTERS ====================
  List<Gallo> get gallos => List<Gallo>.unmodifiable(_gallos);

  List<Gallo> get gallosFiltrados {
    List<Gallo> resultado = _gallos;
    if (_filtroTexto.isNotEmpty) {
      final textoLower = _filtroTexto.toLowerCase();
      resultado = resultado.where((gallo) {
        return gallo.nombre.toLowerCase().contains(textoLower) ||
            gallo.placa.toLowerCase().contains(textoLower) ||
            gallo.colorPluma.toLowerCase().contains(textoLower);
      }).toList();
    }
    if (_filtroEstado != 'Todos') {
      resultado = resultado.where((gallo) => gallo.estado == _filtroEstado).toList();
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

  bool validarPlacaDuplicada(String placa) {
    return _gallos.any((g) => g.placa.toLowerCase() == placa.toLowerCase());
  }
  
  // Como ahora todo es automático, cargarGallos ya no hace falta llamarlo manualmente
  Future<void> cargarGallos() async {}

  @override
  void dispose() {
    _gallosSubscription?.cancel();
    _authSubscription?.cancel(); // Importante cancelar esto también
    super.dispose();
  }
}