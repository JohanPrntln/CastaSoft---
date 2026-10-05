import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';

class UsuarioProveedor with ChangeNotifier {
  UsuarioPerfil? _perfilActual;
  bool _cargando = true;

  UsuarioPerfil? get perfil => _perfilActual;
  bool get cargando => _cargando;

  // ==========================================================
  // 1. 🔥 NUEVO MÉTODO: CARGAR PERFIL
  // ==========================================================
  // Este es el que faltaba. Sirve para recuperar los datos
  // automáticamente cuando reinicias la app (R).
  Future<void> cargarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // Si no hay usuario, no hacemos nada
    if (uid == null) {
      _cargando = false;
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        // Recuperamos los datos de Firebase y actualizamos la memoria
        _perfilActual = UsuarioPerfil.fromMap(doc.data()!);
        notifyListeners(); // ¡Avisamos a la pantalla de inicio!
      }
    } catch (e) {
      print('Error cargando perfil: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // 2. VERIFICAR SI EXISTE (Para el Login)
  // ==========================================================
  Future<bool> verificarPerfilExistente() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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

  // ==========================================================
  // 3. GUARDAR PERFIL
  // ==========================================================
  Future<void> guardarPerfil(UsuarioPerfil perfil) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.uid.isEmpty) {
      throw 'Error grave: No se pudo identificar al usuario (ID vacío). Cierre sesión e intente de nuevo.';
    }

    // Aseguramos que el perfil tenga el UID correcto
    perfil.uid = user.uid;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set(perfil.toMap(), SetOptions(merge: true));
          
      _perfilActual = perfil;
      notifyListeners(); // Actualiza la UI instantáneamente
    } catch (e) {
      print("Error guardando perfil: $e");
      rethrow; 
    }
  }
}