import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/modelos/gallo_modelo.dart'; // Importamos el modelo por si acaso

class ServicioFirestore {
  // Patrón Singleton
  static final ServicioFirestore _instancia = ServicioFirestore._interno();
  factory ServicioFirestore() => _instancia;
  ServicioFirestore._interno();

  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseAuth get auth => _auth;

  // ==================== USUARIO Y SEGURIDAD ====================

  /// Obtiene el ID del usuario actual
  String get uidUsuarioActual => _auth.currentUser?.uid ?? '';

  /// Verifica si hay alguien logueado
  bool get estaAutenticado => _auth.currentUser != null;

  // 🔥 NUEVAS FUNCIONES AGREGADAS PARA EL LOGIN 🔥
  
  /// Inicia sesión con correo y contraseña
  Future<void> iniciarSesion(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Cierra la sesión actual
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
  // -----------------------------------------------------------

  // ==================== LECTURA DE DATOS ====================

  /// Escucha en TIEMPO REAL los gallos del usuario
  Stream<QuerySnapshot<Map<String, dynamic>>> gallosEnTiempoReal() {
    if (!estaAutenticado) {
      return const Stream.empty();
    }
    return _firestore
        .collection('gallos')
        .where('userId', isEqualTo: uidUsuarioActual)
        .snapshots();
  }

  /// Consulta simple
  Future<QuerySnapshot<Map<String, dynamic>>> obtenerGallos() async {
    if (!estaAutenticado) throw Exception('No autenticado');
    return _firestore
        .collection('gallos')
        .where('userId', isEqualTo: uidUsuarioActual)
        .get();
  }

  // ==================== ESCRITURA DE DATOS ====================

  /// Guarda un gallo nuevo
  Future<void> crearGallo(Map<String, dynamic> datosGallo) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');

    datosGallo['userId'] = uidUsuarioActual;
    datosGallo['fechaCreacion'] = DateTime.now().toIso8601String();
    
    // Usamos .doc(id).set() en lugar de .add() si el mapa ya trae un ID generado
    // Esto evita que Firebase cree un ID nuevo si ya tenemos uno
    if (datosGallo.containsKey('id') && datosGallo['id'] != null) {
       await _firestore.collection('gallos').doc(datosGallo['id']).set(datosGallo);
    } else {
       await _firestore.collection('gallos').add(datosGallo);
    }
  }

  /// Actualiza un gallo
  Future<void> actualizarGallo(String idGallo, Map<String, dynamic> datos) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');

    datos['fechaActualizacion'] = DateTime.now().toIso8601String();
    
    // Aseguramos que no se pierda el userId al actualizar
    // (Aunque update solo toca los campos enviados, es mejor prevenir)
    if (!datos.containsKey('userId')) {
       // Opcional: Podríamos revalidar, pero update es seguro
    }

    await _firestore.collection('gallos').doc(idGallo).update(datos);
  }

  /// Elimina un gallo
  Future<void> eliminarGallo(String idGallo) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');
    await _firestore.collection('gallos').doc(idGallo).delete();
  }
  
  // === MÉTODO DE COMPATIBILIDAD (Por si el proveedor usa guardarGallo) ===
  Future<void> guardarGallo(Gallo gallo) async {
      // Convertimos el objeto Gallo a Mapa
      final mapa = gallo.toMap();
      
      // Verificamos si existe para saber si actualizar o crear
      final docRef = _firestore.collection('gallos').doc(gallo.id);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await actualizarGallo(gallo.id, mapa);
      } else {
        await crearGallo(mapa);
      }
  }

  // ==================== VALIDACIONES ====================

  Future<bool> validarPlacaDuplicada(String placa, {String? idExcluir}) async {
    if (!estaAutenticado) return false;

    Query consulta = _firestore
        .collection('gallos')
        .where('userId', isEqualTo: uidUsuarioActual)
        .where('placa', isEqualTo: placa);

    final snapshot = await consulta.get();

    for (var doc in snapshot.docs) {
      if (idExcluir != null && doc.id == idExcluir) continue;
      return true;
    }

    return false;
  }
}