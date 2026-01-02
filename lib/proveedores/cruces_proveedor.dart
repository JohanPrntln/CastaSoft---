import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/modelos/cruce_modelo.dart';

class CrucesProveedor with ChangeNotifier {
  List<CruceModelo> _cruces = [];
  bool _cargando = false;

  List<CruceModelo> get cruces => _cruces;
  bool get cargando => _cargando;

  // 1. CARGAR CRUCES
  Future<void> cargarCruces() async {
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

      _cruces = snapshot.docs
          .map((doc) => CruceModelo.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error cargando cruces: $e");
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // 2. CREAR CRUCE
  Future<void> agregarCruce(CruceModelo cruce) async {
    try {
      await FirebaseFirestore.instance
          .collection('cruces')
          .doc(cruce.id)
          .set(cruce.toMap());
      
      _cruces.insert(0, cruce); // Agregarlo al inicio de la lista local
      notifyListeners();
    } catch (e) {
      print("Error creando cruce: $e");
      rethrow;
    }
  }

  // 3. ELIMINAR CRUCE
  Future<void> eliminarCruce(String id) async {
    try {
      await FirebaseFirestore.instance.collection('cruces').doc(id).delete();
      _cruces.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      print("Error eliminando: $e");
      rethrow;
    }
  }
  // 4. ACTUALIZAR CRUCE (¡NUEVO!)
  Future<void> actualizarCruce(CruceModelo cruce) async {
    try {
      await FirebaseFirestore.instance
          .collection('cruces')
          .doc(cruce.id)
          .update(cruce.toMap());

      // Actualizar la lista localmente para ver el cambio inmediato
      final index = _cruces.indexWhere((c) => c.id == cruce.id);
      if (index != -1) {
        _cruces[index] = cruce;
        notifyListeners();
      }
    } catch (e) {
      print("Error actualizando cruce: $e");
      rethrow;
    }
  }
}