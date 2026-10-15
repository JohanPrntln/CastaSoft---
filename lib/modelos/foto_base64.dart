import 'dart:convert';
import 'dart:typed_data';

/// Prefijo con el que CastaSoft guarda las fotos en Firestore (`fotoPath`,
/// `logoPath`): `'base64,<datos>'`.
const String prefijoFotoBase64 = 'base64,';

/// Indica si [valor] es una foto embebida en Base64 (y no una ruta de archivo).
bool esFotoBase64(String? valor) => valor != null && valor.startsWith('base64');

/// Decodifica una foto `'base64,...'` a bytes. Devuelve `null` si no hay foto,
/// si el valor es una ruta de archivo legada o si el Base64 está corrupto.
///
/// Es O(n) sobre el tamaño de la imagen: los modelos la llaman UNA sola vez y
/// cachean el resultado para que `build()` lea los bytes en O(1).
Uint8List? decodificarFotoBase64(String? valor) {
  if (!esFotoBase64(valor)) return null;
  final int coma = valor!.indexOf(',');
  if (coma == -1) return null;
  try {
    return base64Decode(valor.substring(coma + 1));
  } on FormatException {
    return null;
  }
}
