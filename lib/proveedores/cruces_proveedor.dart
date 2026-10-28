import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';

class CrucesProveedor with ChangeNotifier {
  List<CruceModelo> _cruces = [];
  bool _cargando = false;

  List<CruceModelo> get cruces => _cruces;
  bool get cargando => _cargando;

  // 1. CARGAR CRUCES (CORREGIDO PARA LEER DATOS ANTIGUOS)
  /// Con [lanzarErrores] el fallo se propaga: lo usan la restauración y la
  /// limpieza de duplicados, que no deben operar con una lista incompleta.
  Future<void> cargarCruces({bool lanzarErrores = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _cargando = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cruces')
          .where('userId', isEqualTo: uid)
          .orderBy('fechaCruce', descending: true)
          .get();

      _cruces = snapshot.docs.map((doc) {
        // 🔥 TRUCO: Obtenemos los datos y le inyectamos el ID manualmente
        // Esto arregla el problema de que los registros viejos no se veían.
        final data = doc.data();
        data['id'] = doc.id; 
        
        return CruceModelo.fromMap(data);
      }).toList();
      
    } catch (e) {
      debugPrint("Error cargando cruces: $e");
      if (lanzarErrores) rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Retornan `true` si el servidor confirmó, `false` si la escritura quedó en
  // la caché local de Firestore (offline) pendiente de sincronizar.

  /// RN-02 / RN-04 / RN-05: valida el cruce y fuerza el `userId` autenticado.
  Map<String, dynamic> _prepararParaEscritura(CruceModelo cruce) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Debes iniciar sesión');
    final error = cruce.validar();
    if (error != null) throw Exception(error);
    return cruce.toMap()..['userId'] = uid;
  }

  // 2. CREAR CRUCE
  Future<bool> agregarCruce(CruceModelo cruce) async {
    final datos = _prepararParaEscritura(cruce);
    final confirmado = await ServicioFirestore.confirmarEscritura(
      FirebaseFirestore.instance.collection('cruces').doc(cruce.id).set(datos),
    );
    _cruces.insert(0, CruceModelo.fromMap(datos));
    notifyListeners();
    return confirmado;
  }

  // 3. ELIMINAR CRUCE
  Future<bool> eliminarCruce(String id) async {
    final confirmado = await ServicioFirestore.confirmarEscritura(
      FirebaseFirestore.instance.collection('cruces').doc(id).delete(),
    );
    _cruces.removeWhere((c) => c.id == id);
    notifyListeners();
    return confirmado;
  }

  // 4. ACTUALIZAR CRUCE
  Future<bool> actualizarCruce(CruceModelo cruce) async {
    final datos = _prepararParaEscritura(cruce);
    final confirmado = await ServicioFirestore.confirmarEscritura(
      FirebaseFirestore.instance.collection('cruces').doc(cruce.id).update(datos),
    );
    final index = _cruces.indexWhere((c) => c.id == cruce.id);
    if (index != -1) {
      _cruces[index] = CruceModelo.fromMap(datos);
      notifyListeners();
    }
    return confirmado;
  }
}
