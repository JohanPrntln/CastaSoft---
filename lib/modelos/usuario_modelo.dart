class UsuarioPerfil {
  String uid;
  String nombrePropietario;
  String nombreCastadero;
  String? logoPath;
  String? telefono;
  String? direccion;
  String email;

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