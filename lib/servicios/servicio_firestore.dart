import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:castasoft/modelos/gallo_modelo.dart'; // Importamos el modelo por si acaso
import 'package:castasoft/servicios/deduplicacion.dart';

class ServicioFirestore {
  // Patrón Singleton
  static final ServicioFirestore _instancia = ServicioFirestore._interno();
  factory ServicioFirestore() => _instancia;
  ServicioFirestore._interno();

  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseAuth get auth => _auth;

  // ==================== MODO OFFLINE ====================

  /// Tiempo máximo que la UI espera el ACK del servidor antes de asumir que la
  /// escritura quedó en la caché local de Firestore (cola de sincronización).
  static const Duration tiempoMaximoEsperaServidor = Duration(milliseconds: 2500);

  /// Espera una escritura de Firestore sin bloquear la UI cuando no hay red.
  ///
  /// Con la persistencia habilitada, Firestore aplica la escritura en la caché
  /// local de inmediato (los `snapshots()` la emiten al instante), pero el
  /// `Future` solo se completa cuando el servidor confirma. Sin internet eso
  /// nunca ocurre y el formulario se quedaría en el spinner.
  ///
  /// Retorna `true` si el servidor confirmó, `false` si se agotó el tiempo y
  /// la escritura quedó pendiente de sincronizar. Los errores reales (p. ej.
  /// `permission-denied`) dentro del plazo se propagan normalmente.
  static Future<bool> confirmarEscritura(Future<void> escritura) async {
    try {
      await escritura.timeout(tiempoMaximoEsperaServidor);
      return true;
    } on TimeoutException {
      // La operación sigue viva en la cola local; si luego falla, solo se registra.
      unawaited(escritura.then(
        (_) {},
        onError: (Object e) => debugPrint('⚠️ Escritura offline rechazada al sincronizar: $e'),
      ));
      return false;
    }
  }

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

  /// Escucha en TIEMPO REAL los gallos del usuario (incluye escrituras locales pendientes)
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
  // Todas retornan `true` si el servidor confirmó o `false` si quedaron en cola offline.

  /// Guarda un gallo nuevo
  Future<bool> crearGallo(Map<String, dynamic> datosGallo) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');

    datosGallo['userId'] = uidUsuarioActual; // RN-05
    datosGallo['fechaCreacion'] = DateTime.now().toIso8601String();

    // Usamos .doc(id).set() en lugar de .add() si el mapa ya trae un ID generado
    // Esto evita que Firebase cree un ID nuevo si ya tenemos uno.
    // (.doc() sin argumentos genera el ID localmente: también funciona offline)
    final String? id = datosGallo['id']?.toString();
    final docRef = (id != null && id.isNotEmpty)
        ? _firestore.collection('gallos').doc(id)
        : _firestore.collection('gallos').doc();
    datosGallo['id'] = docRef.id;
    return confirmarEscritura(docRef.set(datosGallo));
  }

  /// Actualiza un gallo
  Future<bool> actualizarGallo(String idGallo, Map<String, dynamic> datos) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');

    datos['userId'] = uidUsuarioActual; // RN-05: nunca se pierde el dueño al actualizar
    datos['fechaActualizacion'] = DateTime.now().toIso8601String();

    return confirmarEscritura(_firestore.collection('gallos').doc(idGallo).update(datos));
  }

  /// Elimina un gallo
  Future<bool> eliminarGallo(String idGallo) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');
    return confirmarEscritura(_firestore.collection('gallos').doc(idGallo).delete());
  }

  /// BUG-18: aplica un [PlanLimpieza] del perfil activo en lotes atómicos.
  /// Primero re-vincula padres/madres hacia los originales y luego borra las
  /// copias. No toca archivos de fotos: las copias comparten `fotoPath` con
  /// el original. Todos los IDs provienen de listas filtradas por `userId`.
  Future<void> aplicarLimpiezaDuplicados(PlanLimpieza plan) async {
    if (!estaAutenticado) throw Exception('Debes iniciar sesión');
    final gallos = _firestore.collection('gallos');
    final cruces = _firestore.collection('cruces');
    final operaciones = <void Function(WriteBatch)>[
      for (final e in plan.gallosRevincular.entries)
        (b) => b.update(gallos.doc(e.key), {...e.value, 'userId': uidUsuarioActual}),
      for (final e in plan.crucesRevincular.entries) (b) => b.update(cruces.doc(e.key), e.value),
      for (final id in plan.idsCrucesEliminar) (b) => b.delete(cruces.doc(id)),
      for (final id in plan.idsGallosEliminar) (b) => b.delete(gallos.doc(id)),
    ];
    // Límite de Firestore: 500 operaciones por lote
    for (var i = 0; i < operaciones.length; i += 450) {
      final lote = _firestore.batch();
      operaciones.skip(i).take(450).forEach((op) => op(lote));
      await confirmarEscritura(lote.commit());
    }
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

  /// RN-01: consulta en Firestore si la [placa] ya existe para el usuario
  /// autenticado, excluyendo el documento [idExcluir] (modo edición).
  ///
  /// Respaldo de `GallosProveedor.validarPlacaDuplicada` (que valida en RAM).
  /// Si el servidor no responde en [tiempoMaximoEsperaServidor] o no hay red,
  /// consulta la caché local de Firestore en lugar de bloquear la UI.
  Future<bool> validarPlacaDuplicada(String placa, {String? idExcluir}) async {
    if (!estaAutenticado) return false;

    final Query<Map<String, dynamic>> consulta = _firestore
        .collection('gallos')
        .where('userId', isEqualTo: uidUsuarioActual)
        .where('placa', isEqualTo: placa);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await consulta.get().timeout(tiempoMaximoEsperaServidor);
    } catch (_) {
      // Offline (TimeoutException / FirebaseException 'unavailable'): caché local
      try {
        snapshot = await consulta.get(const GetOptions(source: Source.cache));
      } catch (e) {
        debugPrint('⚠️ No se pudo validar la placa en caché: $e');
        return false;
      }
    }

    return snapshot.docs.any((doc) => doc.id != idExcluir);
  }
}
