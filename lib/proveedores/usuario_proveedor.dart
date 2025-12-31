import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';

class UsuarioProveedor with ChangeNotifier {
  UsuarioPerfil? _perfilActual;
  bool _cargando = true;

  UsuarioPerfil? get perfil => _perfilActual;
  bool get cargando => _cargando;

  // Verificar si el usuario ya tiene perfil configurado
  Future<bool> verificarPerfilExistente() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        _perfilActual = UsuarioPerfil.fromMap(doc.data()!);
        notifyListeners();
        return true; // Ya tiene perfil
      } else {
        return false; // Es nuevo, debe configurar
      }
    } catch (e) {
      print('Error verificando perfil: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Guardar o Actualizar el perfil
  Future<void> guardarPerfil(UsuarioPerfil perfil) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(perfil.toMap());
    _perfilActual = perfil;
    notifyListeners();
  }
}