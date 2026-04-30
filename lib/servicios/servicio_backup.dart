import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart'; // 🔥 LIBRERÍA OFICIAL DE GOOGLE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';

class ServicioBackup {
  // ==========================================
  // 1. EXPORTAR DATOS A JSON 
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
          'plataforma_origen': Platform.operatingSystem,
        },
        'perfil': perfil != null ? perfil.toMap() : null,
        'gallos': gallos.map((g) => g.toMap()).toList(),
        'cruces': cruces.map((c) => c.toMap()).toList(),
      };

      final String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final String fechaFormateada = DateFormat('dd_MMM_yyyy_HH_mm').format(DateTime.now());
      final String fileName = 'CastaSoft_Respaldo_$fechaFormateada.json';

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
      final WriteBatch batch = firestore.batch();

      // 🔥 DICCIONARIO DE CLONACIÓN PARA NO ROMPER LA GENÉTICA
      // Guardaremos la relación: { "id_viejo" : "id_nuevo" }
      Map<String, String> mapaIdsGallos = {};

      // --- RESTAURAR PERFIL ---
      if (backupData['perfil'] != null) {
        final Map<String, dynamic> perfilData = backupData['perfil'];
        perfilData['id'] = nuevoUid; 
        perfilData['uid'] = nuevoUid; // 🔥 Agregamos esta línea para reescribir el campo fantasma
        
        final docRef = firestore.collection('usuarios').doc(nuevoUid);
        batch.set(docRef, perfilData);
      }

      // --- RESTAURAR GALLOS (CREANDO IDs NUEVOS) ---
      if (backupData['gallos'] != null) {
        final List<dynamic> gallosData = backupData['gallos'];
        for (var gallo in gallosData) {
          final String idViejo = gallo['id'];
          
          // Generamos una referencia con un ID 100% nuevo y en blanco en Firebase
          final docRef = firestore.collection('gallos').doc();
          final String idNuevo = docRef.id;
          
          // Guardamos en el diccionario
          mapaIdsGallos[idViejo] = idNuevo;

          // Actualizamos los datos del gallo antes de subirlo
          gallo['id'] = idNuevo; 
          gallo['userId'] = nuevoUid; 
          
          batch.set(docRef, gallo);
        }
      }

      // --- RESTAURAR CRUCES (RECONECTANDO LA GENÉTICA) ---
      if (backupData['cruces'] != null) {
        final List<dynamic> crucesData = backupData['cruces'];
        for (var cruce in crucesData) {
          // Generamos ID nuevo para el cruce
          final docRef = firestore.collection('cruces').doc();
          
          cruce['id'] = docRef.id; 
          cruce['userId'] = nuevoUid; 

          // 🔥 MAGIA: Reconectamos al Padre y a la Madre usando el diccionario
          if (cruce['padreId'] != null && mapaIdsGallos.containsKey(cruce['padreId'])) {
            cruce['padreId'] = mapaIdsGallos[cruce['padreId']];
          }
          if (cruce['madreId'] != null && mapaIdsGallos.containsKey(cruce['madreId'])) {
            cruce['madreId'] = mapaIdsGallos[cruce['madreId']];
          }

          batch.set(docRef, cruce);
        }
      }

      // 5. Enviar a la nube (Todo el clonaje de una sola vez)
      await batch.commit();

    } catch (e) {
      throw Exception('Error al restaurar: $e');
    }
  }
}