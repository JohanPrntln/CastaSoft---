import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';

class UsuarioProveedor with ChangeNotifier {
  UsuarioPerfil? _perfilActual;
  bool _cargando = true;

  UsuarioPerfil? get perfil => _perfilActual;
  bool get cargando => _cargando;

  Future<bool> verificarPerfilExistente() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Si no hay usuario logueado, retornamos false
    if (uid == null || uid.isEmpty) return false;

    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _perfilActual = UsuarioPerfil.fromMap(doc.data()!);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error verificando: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> guardarPerfil(UsuarioPerfil perfil) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // 🔥 VALIDACIÓN CRÍTICA: Aseguramos que el UID exista
    if (user == null || user.uid.isEmpty) {
      throw 'Error grave: No se pudo identificar al usuario (ID vacío). Cierre sesión e intente de nuevo.';
    }

    // Aseguramos que el perfil tenga el UID correcto antes de guardar
    perfil.uid = user.uid;

    try {
      // Usamos set con SetOptions para fusionar si ya existe algo
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set(perfil.toMap(), SetOptions(merge: true));
          
      _perfilActual = perfil;
      notifyListeners();
    } catch (e) {
      // Esto nos dirá exactamente qué pasó si vuelve a fallar
      print("Error guardando perfil: $e");
      rethrow; 
    }
  }
}