import 'dart:typed_data';

import 'package:castasoft/modelos/foto_base64.dart';

class UsuarioPerfil {
  String uid;
  String nombrePropietario;
  String nombreCastadero;
  String? logoPath;
  String? telefono;
  String? direccion;
  String email;

  // Caché del logo decodificado. Se invalida sola si `logoPath` cambia
  // (este modelo es mutable), comparando por identidad la cadena fuente.
  String? _logoFuenteCache;
  Uint8List? _logoBytesCache;

  /// Bytes del logo en Base64, decodificados una sola vez por valor de [logoPath].
  Uint8List? get logoBytes {
    if (!identical(_logoFuenteCache, logoPath)) {
      _logoFuenteCache = logoPath;
      _logoBytesCache = decodificarFotoBase64(logoPath);
    }
    return _logoBytesCache;
  }

  UsuarioPerfil({
    required this.uid,
    required this.nombrePropietario,
    required this.nombreCastadero,
    this.logoPath,
    this.telefono,
    this.direccion,
    required this.email,
  });

  // 🔥 AQUÍ ESTABA EL RIESGO: Vamos a evitar enviar NULLs
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombrePropietario': nombrePropietario,
      'nombreCastadero': nombreCastadero,
      'logoPath': logoPath ?? '', // Si es null, envía texto vacío
      'telefono': telefono ?? '', // Si es null, envía texto vacío
      'direccion': direccion ?? '', // Si es null, envía texto vacío
      'email': email,
    };
  }

  factory UsuarioPerfil.fromMap(Map<String, dynamic> map) {
    return UsuarioPerfil(
      uid: map['uid'] ?? '',
      nombrePropietario: map['nombrePropietario'] ?? '',
      nombreCastadero: map['nombreCastadero'] ?? 'Mi Castadero',
      logoPath: map['logoPath'],
      telefono: map['telefono'],
      direccion: map['direccion'],
      email: map['email'] ?? '',
    );
  }
}