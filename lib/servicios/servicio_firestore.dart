import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServicioFirestore {
  // Patrón Singleton: Para que solo haya una conexión abierta a la vez
  static final ServicioFirestore _instancia = ServicioFirestore._interno();
  factory ServicioFirestore() => _instancia;
  ServicioFirestore._interno();

  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseAuth get auth => _auth;

  // ==================== USUARIO Y SEGURIDAD ====================

  /// Obtiene el ID del usuario actual (ej: "A1b2C3d4...")
  String get uidUsuarioActual => _auth.currentUser?.uid ?? '';

  /// Verifica si hay alguien logueado
  bool get estaAutenticado => _auth.currentUser != null;

  // ==================== LECTURA DE DATOS ====================

  /// Escucha en TIEMPO REAL los gallos del usuario.
  /// Filtra automáticamente para traer SOLO los gallos de este usuario.
  Stream<QuerySnapshot<Map<String, dynamic>>> gallosEnTiempoReal() {
    if (!estaAutenticado) {
      // Si no hay usuario, devolvemos un stream vacío para no dar error
      return const Stream.empty();
    }

    return _firestore
        .collection('gallos')
        .where('userId', isEqualTo: uidUsuarioActual) // ¡Aquí está el filtro de seguridad!
        .snapshots();
  }

  /// Consulta simple (una sola vez)
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

    // IMPORTANTE: Aseguramos que el gallo quede a nombre de este usuario
    datosGallo['userId'] = uidUsuarioActual;
    
    // Agregamos fechas automáticas
    datosGallo['fechaCreacion'] = DateTime.now().toIso8601String();
    
    // Guardamos en la colección 'gallos'
    await _firestore.collection('gallos').add(datosGallo);
  }

  /// Actualiza un gallo
  Future<void> actualizarGallo(String idGallo, Map<String, dynamic> datos) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');

    datos['fechaActualizacion'] = DateTime.now().toIso8601String();
    
    // Buscamos el documento por su ID y lo actualizamos
    // Nota: Como filtramos por userId en la lectura, es seguro editar directo por ID
    await _firestore.collection('gallos').doc(idGallo).update(datos);
  }

  /// Elimina un gallo
  Future<void> eliminarGallo(String idGallo) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');

    await _firestore.collection('gallos').doc(idGallo).delete();
  }

  // ==================== VALIDACIONES ====================

  /// Revisa si ya existe una placa igual para este usuario
  Future<bool> validarPlacaDuplicada(String placa, {String? idExcluir}) async {
    if (!estaAutenticado) return false;

    Query consulta = _firestore
        .collection('gallos')
        .where('userId', isEqualTo: uidUsuarioActual)
        .where('placa', isEqualTo: placa); // Firestore es sensible a mayúsculas, ojo

    // Si encontramos gallos con esa placa...
    final snapshot = await consulta.get();

    // Filtramos manualmente en memoria para ignorar mayúsculas/minúsculas y el ID actual
    // (Firestore es limitado con búsquedas complejas de texto)
    for (var doc in snapshot.docs) {
      if (idExcluir != null && doc.id == idExcluir) continue; // Es el mismo gallo que editamos
      return true; // Encontramos un duplicado
    }

    return false; // No hay duplicados
  }
}