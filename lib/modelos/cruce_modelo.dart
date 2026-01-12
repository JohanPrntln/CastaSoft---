class CruceModelo {
  final String id;
  final String userId;
  final String padreId;
  final String nombrePadre;
  final String madreId;
  final String nombreMadre;
  final DateTime fechaCruce;
  final String faseLunar;
  final int cantidadPollitos;
  final int pollitosMuertos;
  final int pollitosVivos;
  
  // 🔥 NUEVOS CAMPOS
  final int pollitosMachos;
  final int pollitosHembras;
  
  final String pataMarca;
  final String detalleMarca;
  final String? fotoPath;
  final String? notas;

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
    required this.pollitosMuertos,
    required this.pollitosVivos,
    
    // 🔥 INICIALIZAR EN 0 SI NO SE ENVÍAN
    this.pollitosMachos = 0, 
    this.pollitosHembras = 0,
    
    required this.pataMarca,
    required this.detalleMarca,
    this.fotoPath,
    this.notas,
  });

  // Convertir a Map (Para SQLite/Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'padreId': padreId,
      'nombrePadre': nombrePadre,
      'madreId': madreId,
      'nombreMadre': nombreMadre,
      'fechaCruce': fechaCruce.toIso8601String(),
      'faseLunar': faseLunar,
      'cantidadPollitos': cantidadPollitos,
      'pollitosMuertos': pollitosMuertos,
      'pollitosVivos': pollitosVivos,
      'pollitosMachos': pollitosMachos, // 🔥 Guardar
      'pollitosHembras': pollitosHembras, // 🔥 Guardar
      'pataMarca': pataMarca,
      'detalleMarca': detalleMarca,
      'fotoPath': fotoPath,
      'notas': notas,
    };
  }

  // Crear desde Map
  factory CruceModelo.fromMap(Map<String, dynamic> map) {
    return CruceModelo(
      id: map['id'],
      userId: map['userId'],
      padreId: map['padreId'],
      nombrePadre: map['nombrePadre'],
      madreId: map['madreId'],
      nombreMadre: map['nombreMadre'],
      fechaCruce: DateTime.parse(map['fechaCruce']),
      faseLunar: map['faseLunar'],
      cantidadPollitos: map['cantidadPollitos'],
      pollitosMuertos: map['pollitosMuertos'],
      pollitosVivos: map['pollitosVivos'],
      pollitosMachos: map['pollitosMachos'] ?? 0, // 🔥 Recuperar
      pollitosHembras: map['pollitosHembras'] ?? 0, // 🔥 Recuperar
      pataMarca: map['pataMarca'],
      detalleMarca: map['detalleMarca'],
      fotoPath: map['fotoPath'],
      notas: map['notas'],
    );
  }
}