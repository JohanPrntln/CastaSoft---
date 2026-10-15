import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart'; // 🔥 LIBRERÍA OFICIAL DE GOOGLE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; 

class ServicioBackup {
  // Límites de Firestore por commit: 500 operaciones y ~10 MiB de payload.
  // Se deja margen porque las fotos Base64 viajan dentro de cada documento.
  static const int _maxOperacionesPorLote = 450;
  static const int _maxBytesPorLote = 8 * 1024 * 1024;

  /// Campos que referencian a otro gallo (incluye nombres legados).
  static const List<String> _camposReferenciaGallo = ['padreId', 'madreId', 'idPadre', 'idMadre'];

  // ==========================================
  // 1. EXPORTAR DATOS A JSON (ADAPTADO PARA WEB Y ESCRITORIO)
  // ==========================================
  static Future<String> exportarBackupJSON({
    required UsuarioPerfil? perfil,
    required List<Gallo> gallos,
    required List<CruceModelo> cruces,
  }) async {
    try {
      final Map<String, dynamic> backupData = {
        'metadata': {
          'version_app': '1.0.0',
          'fecha_creacion': DateTime.now().toIso8601String(),
          'total_gallos': gallos.length,
          'total_cruces': cruces.length,
          // 🔥 Evitamos leer el Platform en la web para que no explote
          'plataforma_origen': kIsWeb ? 'Web' : Platform.operatingSystem,
        },
        'perfil': perfil?.toMap(),
        'gallos': gallos.map((g) => g.toMap()).toList(),
        'cruces': cruces.map((c) => c.toMap()).toList(),
      };

      final String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final String fechaFormateada = DateFormat('dd_MMM_yyyy_HH_mm').format(DateTime.now());
      final String fileName = 'CastaSoft_Respaldo_$fechaFormateada.json';

      // 🔥 EL TRUCO BIFURCADO
      if (kIsWeb) {
        // Si estamos en la web, forzamos la descarga desde el navegador
        final bytes = utf8.encode(jsonString);
        final xfile = XFile.fromData(Uint8List.fromList(bytes), mimeType: 'application/json', name: fileName);
        await xfile.saveTo(fileName);
        
        return 'Descargado en tu navegador (Carpeta de Descargas)';
      } else {
        // Si estamos en Windows, Android o iOS, usamos las rutas nativas
        Directory? directorioDestino;

        if (Platform.isAndroid) {
          directorioDestino = Directory('/storage/emulated/0/Download');
          if (!await directorioDestino.exists()) {
            directorioDestino = await getExternalStorageDirectory(); 
          }
        } else {
          directorioDestino = await getDownloadsDirectory();
        }

        if (directorioDestino == null) throw Exception('No se encontró la carpeta.');

        final File backupFile = File('${directorioDestino.path}/$fileName');
        await backupFile.writeAsString(jsonString);

        return backupFile.path;
      }
    } catch (e) {
      throw Exception('Error al guardar: $e');
    }
  }

  // ==========================================
  // 2. RESTAURAR DATOS DESDE JSON A FIREBASE (CLONACIÓN PERFECTA)
  // ==========================================
  static Future<void> restaurarBackupJSON(String nuevoUid) async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Archivos JSON',
        extensions: <String>['json'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

      if (file == null) {
        throw Exception('Operación cancelada por el usuario.');
      }

      final String jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Escrituras pendientes: se reparten luego en uno o más WriteBatch.
      final List<MapEntry<DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>> escrituras = [];

      // 🔥 DICCIONARIO DE CLONACIÓN PARA NO ROMPER LA GENÉTICA
      // Guardaremos la relación: { "id_viejo" : "id_nuevo" }
      final Map<String, String> mapaIdsGallos = {};

      // --- RESTAURAR PERFIL ---
      if (backupData['perfil'] is Map) {
        final Map<String, dynamic> perfilData = Map<String, dynamic>.from(backupData['perfil']);
        perfilData['id'] = nuevoUid; 
        perfilData['uid'] = nuevoUid; // 🔥 Reescribe el campo fantasma con el UID activo
        escrituras.add(MapEntry(firestore.collection('usuarios').doc(nuevoUid), perfilData));
      }

      final List<Map<String, dynamic>> gallosData = (backupData['gallos'] as List? ?? const [])
          .whereType<Map>()
          .map((g) => Map<String, dynamic>.from(g))
          .toList();
      final List<Map<String, dynamic>> crucesData = (backupData['cruces'] as List? ?? const [])
          .whereType<Map>()
          .map((c) => Map<String, dynamic>.from(c))
          .toList();

      // --- PASADA 1: IDs NUEVOS PARA TODOS LOS GALLOS ---
      // Debe completarse ANTES de escribir, porque un gallo puede referenciar
      // como padre/madre a otro que aparece más adelante en el archivo.
      final List<DocumentReference<Map<String, dynamic>>> refsGallos = [];
      for (final gallo in gallosData) {
        final docRef = firestore.collection('gallos').doc(); // ID nuevo, generado localmente
        refsGallos.add(docRef);
        final String? idViejo = gallo['id']?.toString();
        if (idViejo != null && idViejo.isNotEmpty) mapaIdsGallos[idViejo] = docRef.id;
      }

      // Reconecta padreId/madreId de un gallo o cruce usando el diccionario
      void revincular(Map<String, dynamic> datos) {
        for (final campo in _camposReferenciaGallo) {
          final String? idViejo = datos[campo]?.toString();
          if (idViejo != null && mapaIdsGallos.containsKey(idViejo)) {
            datos[campo] = mapaIdsGallos[idViejo];
          }
        }
      }

      // --- PASADA 2: GALLOS (ID nuevo + dueño activo + genealogía re-vinculada) ---
      for (var i = 0; i < gallosData.length; i++) {
        final gallo = gallosData[i];
        gallo['id'] = refsGallos[i].id;
        gallo['userId'] = nuevoUid; // RN-05
        revincular(gallo);
        escrituras.add(MapEntry(refsGallos[i], gallo));
      }

      // --- CRUCES (RECONECTANDO LA GENÉTICA) ---
      for (final cruce in crucesData) {
        final docRef = firestore.collection('cruces').doc();
        cruce['id'] = docRef.id; 
        cruce['userId'] = nuevoUid; 
        revincular(cruce); // 🔥 MAGIA: Padre y Madre apuntan a los gallos clonados
        escrituras.add(MapEntry(docRef, cruce));
      }

      // 5. Enviar a la nube con WriteBatch. Si todo cabe en un lote (caso
      //    normal) la restauración es atómica; si excede los límites de
      //    Firestore se divide en lotes atómicos consecutivos.
      WriteBatch lote = firestore.batch();
      int operaciones = 0;
      int bytes = 0;
      for (final escritura in escrituras) {
        final int tamano = jsonEncode(escritura.value).length;
        if (operaciones > 0 &&
            (operaciones >= _maxOperacionesPorLote || bytes + tamano > _maxBytesPorLote)) {
          await ServicioFirestore.confirmarEscritura(lote.commit());
          lote = firestore.batch();
          operaciones = 0;
          bytes = 0;
        }
        lote.set(escritura.key, escritura.value);
        operaciones++;
        bytes += tamano;
      }
      if (operaciones > 0) {
        await ServicioFirestore.confirmarEscritura(lote.commit());
      }

    } catch (e) {
      throw Exception('Error al restaurar: $e');
    }
  }
}