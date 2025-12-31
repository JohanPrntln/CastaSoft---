class UsuarioPerfil {
  String uid; // El ID único de Firebase
  String nombrePropietario;
  String nombreCastadero;
  String? logoPath; // Aquí guardaremos el logo en Base64
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

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombrePropietario': nombrePropietario,
      'nombreCastadero': nombreCastadero,
      'logoPath': logoPath,
      'telefono': telefono,
      'direccion': direccion,
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