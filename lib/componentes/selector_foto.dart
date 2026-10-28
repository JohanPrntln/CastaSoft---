import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Abre la cámara o la galería y devuelve la imagen elegida (`null` si se cancela).
typedef SeleccionarImagen = Future<XFile?> Function(ImageSource origen);

/// Foto de un ejemplar o cruce con vista previa, "Cambiar foto" y "Quitar foto".
///
/// Es controlado: el formulario guarda los bytes y los convierte a
/// `'base64,...'` al guardar, igual que antes (las llaves no cambian).
class SelectorFoto extends StatelessWidget {
  /// Bytes de la vista previa (foto nueva o guardada).
  final Uint8List? bytes;

  /// Hay una foto guardada aunque no se pueda mostrar (ruta legada o
  /// Base64 corrupto): se permite cambiarla o quitarla igual.
  final bool hayFotoGuardada;

  final ValueChanged<Uint8List> onSeleccionada;
  final VoidCallback onQuitada;

  /// Inyectable en pruebas; por defecto usa `ImagePicker` con compresión.
  final SeleccionarImagen? seleccionar;
  final int calidad;
  final double anchoMaximo;

  /// `null` = ocupa todo el ancho disponible.
  final double? ancho;
  final double alto;
  final Color color;

  const SelectorFoto({
    super.key,
    required this.bytes,
    required this.onSeleccionada,
    required this.onQuitada,
    this.hayFotoGuardada = false,
    this.seleccionar,
    this.calidad = 30,
    this.anchoMaximo = 800,
    this.ancho,
    this.alto = 150,
    this.color = const Color(0xFF1E3A8A),
  });

  bool get _hayFoto => bytes != null || hayFotoGuardada;

  /// Hoja inferior "Tomar foto" / "Seleccionar de la galería" / "Cancelar".
  /// Devuelve `null` si se cancela o se toca fuera.
  static Future<ImageSource?> elegirOrigen(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Text('📷', style: TextStyle(fontSize: 22)),
              title: const Text('Tomar foto (Cámara)'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 22)),
              title: const Text('Seleccionar de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _elegir(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final origen = await elegirOrigen(context);
    if (origen == null) return; // cancelado: la foto previa queda igual

    try {
      final XFile? archivo = await (seleccionar ??
          (o) => ImagePicker().pickImage(source: o, imageQuality: calidad, maxWidth: anchoMaximo))(origen);
      if (archivo == null) return; // el usuario cerró la cámara/galería
      onSeleccionada(await archivo.readAsBytes());
    } catch (e) {
      // Permiso denegado, sin cámara (escritorio), etc.: no se altera nada
      debugPrint('⚠️ No se pudo obtener la foto: $e');
      messenger.showSnackBar(SnackBar(
        content: Text(origen == ImageSource.camera
            ? 'No se pudo abrir la cámara. Revisa los permisos o elige una foto de la galería.'
            : 'No se pudo abrir la galería. Revisa los permisos e inténtalo de nuevo.'),
      ));
    }
  }

  Future<void> _quitar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Deseas quitar la fotografía?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                child: const Text('Quitar'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmar) onQuitada();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? marcador = bytes != null
        ? null
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_hayFoto ? Icons.broken_image_outlined : Icons.add_a_photo, size: 40, color: color),
              const SizedBox(height: 6),
              Text(
                _hayFoto ? 'Foto no disponible' : 'Tocar para agregar foto',
                textAlign: TextAlign.center,
                style: TextStyle(color: color),
              ),
            ],
          );

    return Column(
      children: [
        GestureDetector(
          key: const Key('selector-foto'),
          onTap: () => _elegir(context),
          child: Container(
            width: ancho ?? double.infinity,
            height: alto,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
              image: bytes != null ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover) : null,
            ),
            child: marcador,
          ),
        ),
        if (_hayFoto)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _elegir(context),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Cambiar foto'),
                style: TextButton.styleFrom(foregroundColor: color),
              ),
              TextButton.icon(
                onPressed: () => _quitar(context),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Quitar foto'),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              ),
            ],
          ),
      ],
    );
  }
}
