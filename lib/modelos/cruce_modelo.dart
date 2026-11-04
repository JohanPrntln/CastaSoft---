import 'dart:typed_data';

import 'package:castasoft/modelos/foto_base64.dart';

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

  /// Bytes de la foto decodificados una sola vez (ver `Gallo.fotoBytes`).
  late final Uint8List? fotoBytes = decodificarFotoBase64(fotoPath);

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

  /// RN-02 (Coherencia Biológica) y RN-04 (Progenitores Obligatorios).
  /// Devuelve el mensaje de error o `null` si el cruce es válido.
  static String? validarReglasNegocio({
    required String? padreId,
    required String? madreId,
    required int cantidadHuevos,
    required int pollitosMuertos,
    required int pollitosMachos,
    required int pollitosHembras,
  }) {
    if (padreId == null || padreId.isEmpty || madreId == null || madreId.isEmpty) {
      return 'Selecciona Padre y Madre';
    }
    if (cantidadHuevos < 0 || pollitosMuertos < 0 || pollitosMachos < 0 || pollitosHembras < 0) {
      return 'Las cantidades no pueden ser negativas';
    }
    if (pollitosMuertos > cantidadHuevos) {
      return mensajeMuertosExcedidos(pollitosMuertos, cantidadHuevos);
    }
    final int vivos = cantidadHuevos - pollitosMuertos;
    final int sexados = pollitosMachos + pollitosHembras;
    if (sexados > vivos) {
      return mensajeSexadoExcedido(sexados, vivos);
    }
    return null;
  }

  static String mensajeMuertosExcedidos(int muertos, int nacidos) =>
      'No puedes registrar más bajas ($muertos) que los pollitos nacidos ($nacidos)';

  static String mensajeSexadoExcedido(int suma, int vivos) =>
      'La suma de machos y hembras ($suma) supera los pollitos vivos actuales ($vivos)';

  /// Caracteres permitidos en el detalle de marcaje de la camada.
  static final RegExp caracteresDetalleMarca = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9\s#\-,.]');
  static const int maxDetalleMarca = 80;
  static const String mensajeDetalleMarcaInvalido =
      'Ingresa un detalle válido: mínimo 3 caracteres (letras, números, #, -, coma o punto)';

  /// Detalle opcional del marcaje: si se escribe, 3-80 caracteres permitidos y
  /// al menos una letra o número (no solo símbolos). No exige unicidad.
  static String? validarDetalleMarca(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    final valido = texto.length >= 3 &&
        texto.length <= maxDetalleMarca &&
        texto.split('').every(caracteresDetalleMarca.hasMatch) &&
        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ0-9]').hasMatch(texto);
    return valido ? null : mensajeDetalleMarcaInvalido;
  }

  /// Aplica [validarReglasNegocio] sobre esta instancia.
  String? validar() => validarReglasNegocio(
        padreId: padreId,
        madreId: madreId,
        cantidadHuevos: cantidadPollitos,
        pollitosMuertos: pollitosMuertos,
        pollitosMachos: pollitosMachos,
        pollitosHembras: pollitosHembras,
      );

  // Convertir a Map (Para Firebase / Backup JSON)
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

  // Crear desde Map (parseo seguro: JSON de backups puede traer num/String)
  factory CruceModelo.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return CruceModelo(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      padreId: map['padreId']?.toString() ?? '',
      nombrePadre: map['nombrePadre']?.toString() ?? 'Desconocido',
      madreId: map['madreId']?.toString() ?? '',
      nombreMadre: map['nombreMadre']?.toString() ?? 'Desconocida',
      fechaCruce: DateTime.tryParse(map['fechaCruce']?.toString() ?? '') ?? DateTime.now(),
      faseLunar: map['faseLunar']?.toString() ?? 'Creciente',
      cantidadPollitos: toInt(map['cantidadPollitos']),
      pollitosMuertos: toInt(map['pollitosMuertos']),
      pollitosVivos: toInt(map['pollitosVivos']),
      pollitosMachos: toInt(map['pollitosMachos']), // 🔥 Recuperar
      pollitosHembras: toInt(map['pollitosHembras']), // 🔥 Recuperar
      pataMarca: map['pataMarca']?.toString() ?? 'Sin Marca / Otro',
      detalleMarca: map['detalleMarca']?.toString() ?? '',
      fotoPath: map['fotoPath']?.toString(),
      notas: map['notas']?.toString(),
    );
  }
}
