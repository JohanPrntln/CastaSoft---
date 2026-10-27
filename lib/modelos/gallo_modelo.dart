import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'package:castasoft/modelos/foto_base64.dart';

/// MODELO MAESTRO - CASTASOFT
/// Contiene: Identificación + Genealogía Expandida + Salud + Finanzas + Multimedia
class Gallo {
  // ==================== CATÁLOGOS (FUENTE ÚNICA DE VERDAD) ====================
  /// Valores válidos de [estado].
  static const List<String> estadosValidos = ['Activo', 'Vendido', 'Baja', 'Retirado'];

  /// Valores válidos de [etapaVida] (Sprint 1).
  static const List<String> etapasVida = [
    'Cría', 'Pollos crestones', 'Pollonas', 'Muda', 'Postura', 'Padrote', 'Madrilla', 'Combate',
  ];

  /// Etapas eliminadas en el Sprint 1. Los registros que aún las tengan se
  /// marcan con el filtro '⚠️ Actualizar' para que el usuario las reasigne.
  static const List<String> etapasLegadas = ['Levante', 'Descanso'];

  /// Etapas biológicamente válidas para un macho.
  static const List<String> etapasMacho = ['Cría', 'Pollos crestones', 'Muda', 'Padrote', 'Combate'];

  /// Etapas biológicamente válidas para una hembra.
  static const List<String> etapasHembra = ['Cría', 'Pollonas', 'Muda', 'Postura', 'Madrilla'];

  /// Etapas permitidas según el sexo (sexo desconocido: catálogo completo).
  static List<String> etapasParaSexo(String? sexo) {
    switch (sexo) {
      case 'Macho':
        return etapasMacho;
      case 'Hembra':
        return etapasHembra;
      default:
        return etapasVida;
    }
  }

  /// Las 8 fases lunares oficiales.
  static const List<String> fasesLunares = [
    'Luna nueva',
    'Luna creciente',
    'Cuarto creciente',
    'Gibosa creciente',
    'Luna llena',
    'Gibosa menguante',
    'Cuarto menguante',
    'Luna menguante',
  ];

  static const Map<String, String> _fasesLunaresLegadas = {
    'nueva': 'Luna nueva',
    'creciente': 'Luna creciente',
    'llena': 'Luna llena',
    'menguante': 'Luna menguante',
  };

  /// Convierte valores antiguos de Firestore ('Llena', 'luna llena'...) a una
  /// de las [fasesLunares]. Si no se reconoce, devuelve el texto original
  /// (recortado) para que el formulario lo conserve; `null` si está vacío.
  static String? normalizarFaseLunar(String? valor) {
    final limpio = valor?.trim() ?? '';
    if (limpio.isEmpty) return null;
    final clave = limpio.toLowerCase();
    for (final fase in fasesLunares) {
      if (fase.toLowerCase() == clave) return fase;
    }
    return _fasesLunaresLegadas[clave] ?? limpio;
  }

  /// Opciones del desplegable de fase lunar; agrega el valor guardado si no es
  /// oficial para que el `DropdownButtonFormField` no falle al editar.
  static List<String> opcionesFaseLunar(String? actual) {
    final opciones = List<String>.of(fasesLunares);
    final normalizada = normalizarFaseLunar(actual);
    if (normalizada != null && !opciones.contains(normalizada)) opciones.add(normalizada);
    return opciones;
  }

  /// Líneas genéticas sugeridas en el selector del formulario.
  static const List<String> lineasGeneticasBase = ['Kelso', 'Hatch', 'Sweater', 'Albany', 'Giro', 'Claret'];

  /// Colores de pluma sugeridos en el selector del formulario.
  static const List<String> coloresPlumaBase = ['Giro', 'Cenizo', 'Colorado', 'Grillo', 'Pinto', 'Negro', 'Blanco'];

  /// Vacunas / tratamientos avícolas sugeridos (HU-04).
  static const List<String> vacunasComunes = [
    'Newcastle', 'Viruela Aviar', 'Bronquitis Infecciosa', 'Gumboro', 'Marek', 'Coriza Infecciosa',
    'Cólera Aviar', 'Desparasitación Interna', 'Desparasitación Externa', 'Complejo Vitamínico',
  ];

  // ==================== VALIDACIONES DE FORMULARIO ====================
  static const double pesoMinimoLbs = 0.1;
  static const double pesoMaximoLbs = 25.0;

  static final RegExp _palabraReal = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]{3,}');
  static final RegExp _letra = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]');
  static final RegExp _cincoDigitos = RegExp(r'\d{5,}');
  static final RegExp _fechaEnTexto = RegExp(r'\(?\s*\d{1,2}\s*[\/\-.]\s*\d{1,2}\s*[\/\-.]\s*\d{2,4}\s*\)?');

  /// Caracteres permitidos al escribir una línea genética (ej: "F1 Hatch 50%").
  static final RegExp caracteresLineaGenetica = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\-\/xX%]');

  /// Caracteres permitidos al escribir un color de pluma: letras, espacios y guiones.
  static final RegExp caracteresColorPluma = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s\-]');

  /// Formato de peso: hasta 2 enteros y 2 decimales.
  static final RegExp formatoPeso = RegExp(r'^\d{0,2}(\.\d{0,2})?$');

  static const String mensajePesoInvalido = 'El peso debe ser mayor a 0.1 y menor o igual a 25.0 Lbs';
  static const String mensajeLineaInvalida = 'Ingresa una línea genética válida (ej: Kelso, F1 Hatch 50%)';
  static const String mensajeColorInvalido = 'Ingresa un color válido usando solo letras (mínimo 3)';
  static const String mensajeEnlaceInvalido = 'Ingresa un enlace web válido que inicie con https:// o http://';

  static bool _soloCaracteres(String texto, RegExp permitidos) =>
      texto.split('').every(permitidos.hasMatch);

  static bool _tienePalabraLarga(String texto) => texto.split(RegExp(r'\s+')).any((p) => p.length > 15);

  /// Peso en Lbs dentro del rango biológico (> 0.1 y <= 25.0).
  static String? validarPeso(String? valor, {bool obligatorio = false}) {
    final texto = valor?.trim().replaceAll(',', '.') ?? '';
    if (texto.isEmpty) return obligatorio ? 'Requerido' : null;
    final peso = double.tryParse(texto);
    if (peso == null || peso <= pesoMinimoLbs || peso > pesoMaximoLbs) return mensajePesoInvalido;
    return null;
  }

  /// Color de pluma escrito a mano: 3-25 caracteres, solo letras/espacios/guiones.
  static String? validarColorPluma(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Requerido';
    if (texto.length < 3 || texto.length > 25 ||
        !_soloCaracteres(texto, caracteresColorPluma) ||
        _letra.allMatches(texto).length < 3 ||
        _tienePalabraLarga(texto)) {
      return mensajeColorInvalido;
    }
    return null;
  }

  /// Línea genética escrita a mano: 3-30 caracteres, al menos una palabra de
  /// 3 letras seguidas, sin rachas de 5+ dígitos ni palabras de 16+ caracteres.
  static String? validarLineaGenetica(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Requerido';
    if (texto.length < 3 || texto.length > 30 ||
        !_soloCaracteres(texto, caracteresLineaGenetica) ||
        !_palabraReal.hasMatch(texto) ||
        _cincoDigitos.hasMatch(texto) ||
        _tienePalabraLarga(texto)) {
      return mensajeLineaInvalida;
    }
    return null;
  }

  /// Enlace opcional: si se escribe, debe ser http(s) con un dominio válido.
  static String? validarEnlace(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    final uri = Uri.tryParse(texto);
    final valido = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.contains('.') &&
        !uri.host.startsWith('.') &&
        !uri.host.endsWith('.');
    return valido ? null : mensajeEnlaceInvalido;
  }

  /// Quita fechas escritas a mano (dd/mm/yyyy, dd-mm-yy...) de un evento.
  static String quitarFechas(String texto) =>
      texto.replaceAll(_fechaEnTexto, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Texto de un evento del historial con su fecha (HU-04), sin fechas duplicadas.
  static String eventoConFecha(String evento, DateTime fecha) =>
      '${quitarFechas(evento)} (${DateFormat('dd/MM/yyyy').format(fecha)})';

  /// Nombre a mostrar en tarjetas y listados; nunca vacío (datos antiguos sin apodo).
  String get nombreMostrar {
    if (nombre.trim().isNotEmpty) return nombre.trim();
    return placa.trim().isEmpty ? 'Sin apodo' : 'Sin apodo (#${placa.trim()})';
  }

  /// Etiqueta inequívoca para selectores de Padre/Madre:
  /// "[Placa #A1] - Rayo (Kelso)" o "[Placa #A1] - Sin apodo (Kelso)".
  String get etiquetaSelector {
    final p = placa.trim();
    final n = nombre.trim();
    final l = lineaGenetica.trim();
    final textoPlaca = p.isEmpty ? 'Sin placa' : '[Placa #$p]';
    final textoNombre = n.isEmpty ? 'Sin apodo' : n;
    return '$textoPlaca - $textoNombre${l.isEmpty ? '' : ' ($l)'}';
  }

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
  /// Estado general: uno de [estadosValidos].
  final String estado; 
  
  /// Etapa detallada: uno de [etapasVida] (o de [etapasLegadas] en datos viejos).
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
  final String? fotoPath; // Foto principal como 'base64,...'

  /// Bytes de la foto decodificados UNA sola vez (perezoso + memoizado).
  /// La UI lee este campo en O(1) en vez de llamar `base64Decode` en `build()`,
  /// y como la instancia de `Uint8List` es siempre la misma, `MemoryImage`
  /// reutiliza la imagen ya decodificada del `ImageCache` entre frames.
  late final Uint8List? fotoBytes = decodificarFotoBase64(fotoPath);
  
  /// [RECOMENDACIÓN] Link a video de YouTube/Drive para ver al gallo peleando/caminando
  final String? videoUrl; 

  // ==================== 7. FINANZAS (RENTABILIDAD) ====================
  /// [RECOMENDACIÓN] Cuánto costó adquirirlo o criarlo
  final double? costoAdquisicion;
  /// [RECOMENDACIÓN] En cuánto se vendió (si estado == 'Vendido')
  final double? precioVenta;


  // === CONSTRUCTOR MAESTRO ===
  // (No es `const` porque [fotoBytes] es un campo `late final` memoizado.)
  Gallo({
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

    // RN-07: nunca se aceptan strings vacíos dentro de vacunas/peleas
    List<String> toListString(dynamic val) {
      if (val is! List) return [];
      return val
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return Gallo(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString(),
      placa: map['placa']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      sexo: map['sexo']?.toString() ?? 'Macho',
      fechaNacimiento: DateTime.tryParse(map['fechaNacimiento']?.toString() ?? '') ?? DateTime.now(),
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
