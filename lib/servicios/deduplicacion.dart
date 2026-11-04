import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';

/// Resultado de planificar una restauración JSON contra el perfil activo.
class PlanImportacion {
  /// Gallos nuevos listos para escribir (ID nuevo, `userId` activo, genealogía re-vinculada).
  final List<Map<String, dynamic>> gallosNuevos;

  /// Cruces nuevos listos para escribir (ID nuevo, `userId` activo, padres re-vinculados).
  final List<Map<String, dynamic>> crucesNuevos;

  final int gallosOmitidos;
  final int crucesOmitidos;

  const PlanImportacion({
    required this.gallosNuevos,
    required this.crucesNuevos,
    required this.gallosOmitidos,
    required this.crucesOmitidos,
  });

  int get registrosNuevos => gallosNuevos.length + crucesNuevos.length;
  int get registrosOmitidos => gallosOmitidos + crucesOmitidos;

  String get mensajeResultado => 'Restauración completada: $registrosNuevos registros nuevos agregados, '
      '$registrosOmitidos registros existentes omitidos para evitar duplicados.';
}

/// Diagnóstico (sin borrar nada) de los duplicados del perfil activo.
class PlanLimpieza {
  final int totalGallos;

  /// IDs de las copias de gallos a eliminar.
  final List<String> idsGallosEliminar;

  /// IDs de los cruces exactamente duplicados a eliminar.
  final List<String> idsCrucesEliminar;

  /// copiaId -> id del ejemplar original conservado.
  final Map<String, String> reemplazos;

  /// Gallos conservados que apuntaban a una copia: id -> campos a actualizar.
  final Map<String, Map<String, String>> gallosRevincular;

  /// Cruces conservados que apuntaban a una copia: id -> campos a actualizar.
  final Map<String, Map<String, String>> crucesRevincular;

  const PlanLimpieza({
    required this.totalGallos,
    required this.idsGallosEliminar,
    required this.idsCrucesEliminar,
    required this.reemplazos,
    required this.gallosRevincular,
    required this.crucesRevincular,
  });

  int get copias => idsGallosEliminar.length;
  int get unicos => totalGallos - copias;
  bool get sinDuplicados => idsGallosEliminar.isEmpty && idsCrucesEliminar.isEmpty;

  String get mensajeConfirmacion {
    final lineaCruces =
        idsCrucesEliminar.isEmpty ? '' : '\n• Cruces duplicados detectados para eliminar: ${idsCrucesEliminar.length}';
    return 'Análisis del criadero actual:\n'
        '• Ejemplares únicos originales a conservar: $unicos\n'
        '• Copias duplicadas detectadas para eliminar: $copias$lineaCruces\n\n'
        'Se protegerán automáticamente los ejemplares vinculados a cruces y genealogías, '
        'sin afectar ningún otro perfil. ¿Deseas eliminar las $copias copias duplicadas?';
  }

  String get mensajeResultado =>
      'Limpieza completada: se eliminaron $copias copias duplicadas. Quedaron $unicos ejemplares únicos.';
}

/// BUG-18: identidad de registros para restaurar respaldos sin duplicar y
/// limpiar las copias ya creadas. Todo es puro (sin Firebase): opera solo
/// sobre las listas del perfil activo que recibe.
class Deduplicacion {
  /// Campos que referencian a otro gallo (incluye nombres legados).
  static const List<String> camposReferenciaGallo = ['padreId', 'madreId', 'idPadre', 'idMadre'];

  static String _n(String? texto) => texto?.trim().toLowerCase() ?? '';

  /// Clave de identidad: la placa si existe; si no, una firma de los campos
  /// principales (solo la fecha, sin hora, por registros sin fecha guardada).
  static String claveGallo(Gallo g) {
    final placa = _n(g.placa);
    if (placa.isNotEmpty) return 'placa:$placa';
    final fecha = g.fechaNacimiento.toIso8601String().substring(0, 10);
    return 'firma:${_n(g.nombre)}|${_n(g.sexo)}|$fecha|${_n(g.lineaGenetica)}|${_n(g.colorPluma)}|${g.pesoActual ?? ''}';
  }

  /// Firma de un cruce; [remap] traduce IDs de padres (copia -> original).
  static String firmaCruce(CruceModelo c, [Map<String, String> remap = const {}]) {
    String progenitor(String id, String nombre) =>
        id.isNotEmpty ? 'id:${remap[id] ?? id}' : 'nombre:${_n(nombre)}';
    return '${progenitor(c.padreId, c.nombrePadre)}|${progenitor(c.madreId, c.nombreMadre)}|'
        '${c.fechaCruce.toIso8601String()}|${c.cantidadPollitos}|${c.pollitosMuertos}|'
        '${c.pollitosMachos}|${c.pollitosHembras}|${_n(c.detalleMarca)}';
  }

  // ==================== PARTE A: IMPORTACIÓN IDEMPOTENTE ====================

  /// Decide qué registros del JSON se insertan en el perfil [uid].
  ///
  /// Un gallo ya existe si coincide por `id` o por [claveGallo] con uno del
  /// perfil (o con otro ya aceptado del mismo archivo). Los nuevos reciben un
  /// ID de [generarId] para no pisar documentos de otros perfiles.
  static PlanImportacion planificarImportacion({
    required String uid,
    required List<Gallo> gallosExistentes,
    required List<CruceModelo> crucesExistentes,
    required List<Map<String, dynamic>> gallosJson,
    required List<Map<String, dynamic>> crucesJson,
    required String Function(String coleccion) generarId,
  }) {
    final idsGallos = <String>{for (final g in gallosExistentes) g.id};
    final idPorClave = <String, String>{for (final g in gallosExistentes) claveGallo(g): g.id};
    // id del archivo -> id final en el perfil (existente o nuevo)
    final mapaIds = <String, String>{};
    final gallosNuevos = <Map<String, dynamic>>[];
    var gallosOmitidos = 0;

    // Pasada 1: identidad e IDs finales (antes de re-vincular, porque un gallo
    // puede referenciar a otro que aparece más adelante en el archivo).
    for (final datos in gallosJson) {
      final idViejo = datos['id']?.toString() ?? '';
      final clave = claveGallo(Gallo.fromMap(datos));
      final existente = idsGallos.contains(idViejo) ? idViejo : idPorClave[clave];
      if (existente != null) {
        if (idViejo.isNotEmpty) mapaIds[idViejo] = existente;
        gallosOmitidos++;
        continue;
      }
      final idNuevo = generarId('gallos');
      if (idViejo.isNotEmpty) mapaIds[idViejo] = idNuevo;
      idsGallos.add(idNuevo);
      idPorClave[clave] = idNuevo; // repetidos dentro del mismo archivo
      gallosNuevos.add(Map<String, dynamic>.from(datos)
        ..['id'] = idNuevo
        ..['userId'] = uid); // RN-05
    }

    void revincular(Map<String, dynamic> datos) {
      for (final campo in camposReferenciaGallo) {
        final idViejo = datos[campo]?.toString();
        if (idViejo != null && mapaIds.containsKey(idViejo)) datos[campo] = mapaIds[idViejo];
      }
    }

    gallosNuevos.forEach(revincular);

    // Cruces: por id o por firma (con padres ya traducidos al perfil activo)
    final idsCruces = <String>{for (final c in crucesExistentes) c.id};
    final firmas = <String>{for (final c in crucesExistentes) firmaCruce(c)};
    final crucesNuevos = <Map<String, dynamic>>[];
    var crucesOmitidos = 0;
    for (final original in crucesJson) {
      final datos = Map<String, dynamic>.from(original);
      final idViejo = datos['id']?.toString() ?? '';
      revincular(datos);
      final firma = firmaCruce(CruceModelo.fromMap(datos));
      if (idsCruces.contains(idViejo) || firmas.contains(firma)) {
        crucesOmitidos++;
        continue;
      }
      final idNuevo = generarId('cruces');
      idsCruces.add(idNuevo);
      firmas.add(firma);
      crucesNuevos.add(datos
        ..['id'] = idNuevo
        ..['userId'] = uid);
    }

    return PlanImportacion(
      gallosNuevos: gallosNuevos,
      crucesNuevos: crucesNuevos,
      gallosOmitidos: gallosOmitidos,
      crucesOmitidos: crucesOmitidos,
    );
  }

  // ==================== PARTE B: LIMPIEZA DE DUPLICADOS ====================

  /// Cantidad de datos complementarios llenos (desempate entre copias).
  static int _riqueza(Gallo g) {
    bool lleno(String? v) => v != null && v.trim().isNotEmpty;
    return g.vacunas.length +
        g.peleas.length +
        [
          g.fotoPath, g.videoUrl, g.notas, g.jaula, g.padreId, g.madreId, g.nombrePadre, g.nombreMadre,
          g.nombreAbueloPaterno, g.nombreAbuelaPaterna, g.nombreAbueloMaterno, g.nombreAbuelaMaterna,
        ].where(lleno).length +
        [g.pesoActual, g.pesoCombate, g.costoAdquisicion, g.precioVenta].where((v) => v != null).length;
  }

  static int _riquezaCruce(CruceModelo c) =>
      [c.fotoPath, c.notas].where((v) => v != null && v.trim().isNotEmpty).length;

  /// Diagnostica las copias del perfil activo sin borrar nada.
  ///
  /// Por cada grupo con la misma [claveGallo] conserva 1 ejemplar: primero el
  /// referenciado como padre/madre (en cruces u otros gallos), luego el de más
  /// datos. Las referencias a copias se re-vinculan al conservado.
  static PlanLimpieza planificarLimpieza({
    required List<Gallo> gallos,
    required List<CruceModelo> cruces,
  }) {
    // Paso 1: vínculos genealógicos (id -> veces referenciado)
    final referencias = <String, int>{};
    void contar(String? id) {
      if (id != null && id.isNotEmpty) referencias[id] = (referencias[id] ?? 0) + 1;
    }
    for (final c in cruces) {
      contar(c.padreId);
      contar(c.madreId);
    }
    for (final g in gallos) {
      contar(g.padreId);
      contar(g.madreId);
    }

    // Paso 2: agrupación por identidad
    final grupos = <String, List<Gallo>>{};
    for (final g in gallos) {
      grupos.putIfAbsent(claveGallo(g), () => []).add(g);
    }

    // Paso 3: un único ganador por grupo
    final reemplazos = <String, String>{};
    for (final grupo in grupos.values.where((g) => g.length > 1)) {
      final candidatos = List.of(grupo)
        ..sort((a, b) {
          final refA = referencias[a.id] ?? 0, refB = referencias[b.id] ?? 0;
          if ((refA > 0) != (refB > 0)) return refA > 0 ? -1 : 1;
          if (refA != refB) return refB.compareTo(refA);
          final datos = _riqueza(b).compareTo(_riqueza(a));
          return datos != 0 ? datos : a.id.compareTo(b.id); // orden estable
        });
      for (final copia in candidatos.skip(1)) {
        reemplazos[copia.id] = candidatos.first.id;
      }
    }

    Map<String, String> revinculacion(String? padreId, String? madreId) => {
          if (reemplazos.containsKey(padreId)) 'padreId': reemplazos[padreId]!,
          if (reemplazos.containsKey(madreId)) 'madreId': reemplazos[madreId]!,
        };

    final gallosRevincular = <String, Map<String, String>>{};
    for (final g in gallos.where((g) => !reemplazos.containsKey(g.id))) {
      final cambios = revinculacion(g.padreId, g.madreId);
      if (cambios.isNotEmpty) gallosRevincular[g.id] = cambios;
    }

    // Cruces exactamente duplicados (comparando padres ya traducidos)
    final gruposCruces = <String, List<CruceModelo>>{};
    for (final c in cruces) {
      gruposCruces.putIfAbsent(firmaCruce(c, reemplazos), () => []).add(c);
    }
    final idsCrucesEliminar = <String>[];
    final crucesRevincular = <String, Map<String, String>>{};
    for (final grupo in gruposCruces.values) {
      final candidatos = List.of(grupo)
        ..sort((a, b) {
          final datos = _riquezaCruce(b).compareTo(_riquezaCruce(a));
          return datos != 0 ? datos : a.id.compareTo(b.id);
        });
      idsCrucesEliminar.addAll(candidatos.skip(1).map((c) => c.id));
      final cambios = revinculacion(candidatos.first.padreId, candidatos.first.madreId);
      if (cambios.isNotEmpty) crucesRevincular[candidatos.first.id] = cambios;
    }

    return PlanLimpieza(
      totalGallos: gallos.length,
      idsGallosEliminar: reemplazos.keys.toList(),
      idsCrucesEliminar: idsCrucesEliminar,
      reemplazos: reemplazos,
      gallosRevincular: gallosRevincular,
      crucesRevincular: crucesRevincular,
    );
  }
}
