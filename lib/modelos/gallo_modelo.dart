/// MODELO MAESTRO - CASTASOFT
/// Contiene: Identificación + Genealogía Expandida + Salud + Finanzas + Multimedia
class Gallo {
  // ==================== 1. IDENTIFICACIÓN ====================
  final String id;
  final String? userId; // Dueño del gallo (Seguridad Nube)
  final String placa;   // Anillo único
  final String nombre;
  final String sexo;    // 'Macho', 'Hembra'
  final String criaderoOrigen; // De dónde vino
  
  // ==================== 2. BIOLOGÍA Y FÍSICO ====================
  final DateTime fechaNacimiento;
  final String lineaGenetica; // Ej: Kelso, Sweater, Radio
  final String colorPluma;
  final String faseLunar;     // Dato tradicional
  final String tipoCresta;    // Ej: Sierra, Rosa, Pava
  final double? pesoActual;   // Peso al día de hoy
  final double? pesoCombate;  // Peso ideal para pelear
  final String? jaula;        // Ubicación física

  // ==================== 3. ESTADO Y GESTIÓN ====================
  /// Estado general: 'Activo', 'Vendido', 'Baja', 'Retirado'
  final String estado; 
  
  /// [RECOMENDACIÓN] Etapa detallada: 'Cría', 'Levante', 'Muda', 'Postura/Cuido', 'Padrote'
  final String etapaVida; 

  // ==================== 4. GENEALOGÍA VISUAL (ÁRBOL COMPLETO) ====================
  // IDs para vincular con gallos que SÍ tienen ficha en la app
  final String? padreId;
  final String? madreId;
  
  // [PEDIDO CLIENTE] Texto libre para imprimir en PDF aunque el ancestro no tenga ficha
  final String? nombrePadre; 
  final String? nombreMadre;
  final String? nombreAbueloPaterno;
  final String? nombreAbuelaPaterna;
  final String? nombreAbueloMaterno;
  final String? nombreAbuelaMaterna;

  // ==================== 5. HISTORIAL Y SALUD (LISTAS) ====================
  // [PEDIDO CLIENTE] Listas para ir agregando eventos uno tras otro
  final List<String> vacunas; // Ej: ["Newcastle - Enero 2024", "Coriza - Feb 2024"]
  final List<String> peleas;  // Ej: ["Ganó a Giro en 12min", "Entabló en Club X"]
  final String? notas;        // Observaciones generales

  // ==================== 6. MULTIMEDIA Y EXTRAS ====================
  final String? fotoPath; // Ruta de la imagen principal
  
  /// [RECOMENDACIÓN] Link a video de YouTube/Drive para ver al gallo peleando/caminando
  final String? videoUrl; 

  // ==================== 7. FINANZAS (RENTABILIDAD) ====================
  /// [RECOMENDACIÓN] Cuánto costó adquirirlo o criarlo
  final double? costoAdquisicion;
  /// [RECOMENDACIÓN] En cuánto se vendió (si estado == 'Vendido')
  final double? precioVenta;


  // === CONSTRUCTOR MAESTRO ===
  const Gallo({
    required this.id,
    this.userId,
    required this.placa,
    required this.nombre,
    required this.sexo,
    required this.fechaNacimiento,
    required this.lineaGenetica,
    required this.colorPluma,
    required this.faseLunar,
    required this.estado,
    this.etapaVida = 'Cría', // Valor por defecto sugerido
    this.tipoCresta = 'Sierra',
    this.criaderoOrigen = 'Propio',
    this.jaula,
    this.pesoActual,
    this.pesoCombate,
    this.notas,
    this.fotoPath,
    this.videoUrl,
    this.costoAdquisicion,
    this.precioVenta,
    // Genealogía
    this.padreId,
    this.madreId,
    this.nombrePadre,
    this.nombreMadre,
    this.nombreAbueloPaterno,
    this.nombreAbuelaPaterna,
    this.nombreAbueloMaterno,
    this.nombreAbuelaMaterna,
    // Listas (Inician vacías si no se pasan datos)
    this.vacunas = const [],
    this.peleas = const [],
    // Compatibilidad vieja (si existe código viejo llamando esto)
    String? idPadre,
    String? idMadre,
  }); 

  // Compatibilidad Getters
  String? get idPadre => padreId;
  String? get idMadre => madreId;

  // === MAPEO PARA FIREBASE (SERIALIZACIÓN) ===
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'placa': placa,
      'nombre': nombre,
      'sexo': sexo,
      'fechaNacimiento': fechaNacimiento.toIso8601String(),
      'lineaGenetica': lineaGenetica,
      'colorPluma': colorPluma,
      'faseLunar': faseLunar,
      'tipoCresta': tipoCresta,
      'estado': estado,
      'etapaVida': etapaVida, // Nuevo campo
      'criaderoOrigen': criaderoOrigen,
      'jaula': jaula,
      'pesoActual': pesoActual,
      'pesoCombate': pesoCombate,
      'notas': notas,
      'fotoPath': fotoPath,
      'videoUrl': videoUrl,   // Nuevo campo
      'costoAdquisicion': costoAdquisicion, // Nuevo campo
      'precioVenta': precioVenta,           // Nuevo campo
      // Genealogía Completa
      'padreId': padreId,
      'madreId': madreId,
      'nombrePadre': nombrePadre,
      'nombreMadre': nombreMadre,
      'nombreAbueloPaterno': nombreAbueloPaterno,
      'nombreAbuelaPaterna': nombreAbuelaPaterna,
      'nombreAbueloMaterno': nombreAbueloMaterno,
      'nombreAbuelaMaterna': nombreAbuelaMaterna,
      // Listas
      'vacunas': vacunas,
      'peleas': peleas,
    };
  }

  // === DESDE FIREBASE A OBJETO (VERSIÓN BLINDADA) ===
  factory Gallo.fromMap(Map<String, dynamic> map) {
    // Funciones de ayuda para evitar errores de conversión
    double? toDouble(dynamic val) {
      if (val == null) return null;
      if (val is int) return val.toDouble(); // Convierte 2500 a 2500.0
      if (val is double) return val;
      if (val is String) return double.tryParse(val); // Intenta leer "2500" como número
      return null;
    }

    List<String> toListString(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        // Convierte cada elemento a String a la fuerza para que no falle
        return val.map((e) => e.toString()).toList();
      }
      return [];
    }

    return Gallo(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString(),
      placa: map['placa']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      sexo: map['sexo']?.toString() ?? 'Macho',
      fechaNacimiento: map['fechaNacimiento'] != null 
          ? DateTime.parse(map['fechaNacimiento'].toString()) 
          : DateTime.now(),
      lineaGenetica: map['lineaGenetica']?.toString() ?? '',
      colorPluma: map['colorPluma']?.toString() ?? '',
      faseLunar: map['faseLunar']?.toString() ?? '',
      tipoCresta: map['tipoCresta']?.toString() ?? 'Sierra',
      estado: map['estado']?.toString() ?? 'Activo',
      etapaVida: map['etapaVida']?.toString() ?? 'Cría',
      criaderoOrigen: map['criaderoOrigen']?.toString() ?? 'Propio',
      jaula: map['jaula']?.toString(),
      
      // Aquí usamos la función segura toDouble
      pesoActual: toDouble(map['pesoActual']) ?? toDouble(map['peso']),
      pesoCombate: toDouble(map['pesoCombate']),
      costoAdquisicion: toDouble(map['costoAdquisicion']),
      precioVenta: toDouble(map['precioVenta']),
      
      notas: map['notas']?.toString(),
      fotoPath: map['fotoPath']?.toString(),
      videoUrl: map['videoUrl']?.toString(),
      
      // Genealogía
      padreId: map['padreId']?.toString() ?? map['idPadre']?.toString(),
      madreId: map['madreId']?.toString() ?? map['idMadre']?.toString(),
      nombrePadre: map['nombrePadre']?.toString(),
      nombreMadre: map['nombreMadre']?.toString(),
      nombreAbueloPaterno: map['nombreAbueloPaterno']?.toString(),
      nombreAbuelaPaterna: map['nombreAbuelaPaterna']?.toString(),
      nombreAbueloMaterno: map['nombreAbueloMaterno']?.toString(),
      nombreAbuelaMaterna: map['nombreAbuelaMaterna']?.toString(),
      
      // Aquí usamos la función segura toListString
      vacunas: toListString(map['vacunas']),
      peleas: toListString(map['peleas']),
    );
  }
}
