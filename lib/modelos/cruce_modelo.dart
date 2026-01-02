class CruceModelo {
  String id;
  String userId;
  
  // PADRES
  String padreId;
  String nombrePadre;
  String madreId;
  String nombreMadre;

  // DETALLES DEL EVENTO
  DateTime fechaCruce;
  String faseLunar;
  int cantidadPollitos; // Total que nacieron

  // ESTADÍSTICAS DE VIDA (¡NUEVO!)
  int pollitosVivos;
  int pollitosMuertos;

  // IDENTIFICACIÓN
  String pataMarca;
  String detalleMarca;

  // MULTIMEDIA Y EXTRAS
  String? fotoPath;
  String? notas;

  CruceModelo({
    required this.id,
    required this.userId,
    required this.padreId,
    required this.nombrePadre,
    required this.madreId,
    required this.nombreMadre,
    required this.fechaCruce,
    required this.faseLunar,
    required this.cantidadPollitos,
    required this.pollitosVivos,   // Nuevo
    required this.pollitosMuertos, // Nuevo
    required this.pataMarca,
    required this.detalleMarca,
    this.fotoPath,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'padreId': padreId,
      'nombrePadre': nombrePadre,
      'madreId': madreId,
      'nombreMadre': nombreMadre,
      'fechaCruce': fechaCruce.toIso8601String(),
      'faseLunar': faseLunar,
      'cantidadPollitos': cantidadPollitos,
      'pollitosVivos': pollitosVivos,     // Nuevo
      'pollitosMuertos': pollitosMuertos, // Nuevo
      'pataMarca': pataMarca,
      'detalleMarca': detalleMarca,
      'fotoPath': fotoPath ?? '',
      'notas': notas ?? '',
    };
  }

  factory CruceModelo.fromMap(Map<String, dynamic> map, String docId) {
    return CruceModelo(
      id: docId,
      userId: map['userId'] ?? '',
      padreId: map['padreId'] ?? '',
      nombrePadre: map['nombrePadre'] ?? 'Desconocido',
      madreId: map['madreId'] ?? '',
      nombreMadre: map['nombreMadre'] ?? 'Desconocida',
      fechaCruce: DateTime.parse(map['fechaCruce']),
      faseLunar: map['faseLunar'] ?? '',
      cantidadPollitos: map['cantidadPollitos'] ?? 0,
      pollitosVivos: map['pollitosVivos'] ?? map['cantidadPollitos'] ?? 0, // Por defecto todos vivos
      pollitosMuertos: map['pollitosMuertos'] ?? 0,
      pataMarca: map['pataMarca'] ?? 'Derecha',
      detalleMarca: map['detalleMarca'] ?? '',
      fotoPath: map['fotoPath'],
      notas: map['notas'],
    );
  }
}