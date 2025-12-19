import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';

/// Pantalla de Formulario para Crear/Editar Gallos
///
/// Esta pantalla permite:
/// - Crear un nuevo gallo (si [galloEditar] es null)
/// - Editar un gallo existente (si [galloEditar] no es null)
/// - Validación de formulario completa
/// - Selector de fecha para fecha de nacimiento
/// - Selector de imagen para fotografía del gallo
/// - Dropdowns para sexo y estado
class PantallaFormularioGallo extends StatefulWidget {
  /// Gallo a editar (null si es creación)
  final Gallo? galloEditar;

  /// Constructor de la pantalla de formulario
  const PantallaFormularioGallo({Key? key, this.galloEditar}) : super(key: key);

  @override
  State<PantallaFormularioGallo> createState() =>
      _PantallaFormularioGalloState();
}

class _PantallaFormularioGalloState extends State<PantallaFormularioGallo> {
  /// Clave global del formulario para validación
  final _claveFormulario = GlobalKey<FormState>();

  /// Controladores de texto para cada campo
  late TextEditingController _controladorPlaca;
  late TextEditingController _controladorNombre;
  late TextEditingController _controladorLineaGenetica;
  late TextEditingController _controladorColorPluma;
  late TextEditingController _controladorFaseLunar;
  late TextEditingController _controladorNotas;
  late TextEditingController _controladorFechaNacimiento;

  /// Variables para almacenar selecciones
  String? _sexoSeleccionado;
  String? _estadoSeleccionado;
  DateTime? _fechaNacimientoSeleccionada;

  /// Ruta temporal de la fotografía seleccionada
  String? _rutaFotoTemporal;

  /// Selector de imágenes desde la galería del dispositivo
  final ImagePicker _selectorImagen = ImagePicker();

  /// Indica si la pantalla está en modo edición
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores
    _controladorPlaca = TextEditingController();
    _controladorNombre = TextEditingController();
    _controladorLineaGenetica = TextEditingController();
    _controladorColorPluma = TextEditingController();
    _controladorFaseLunar = TextEditingController();
    _controladorNotas = TextEditingController();
    _controladorFechaNacimiento = TextEditingController();

    // Si hay gallo para editar, llenar los campos
    if (widget.galloEditar != null) {
      _esEdicion = true;
      final gallo = widget.galloEditar!;

      _controladorPlaca.text = gallo.placa;
      _controladorNombre.text = gallo.nombre;
      _controladorLineaGenetica.text = gallo.lineaGenetica;
      _controladorColorPluma.text = gallo.colorPluma;
      _controladorFaseLunar.text = gallo.faseLunar;
      _controladorNotas.text = gallo.notas ?? '';
      _controladorFechaNacimiento.text = _formatearFecha(gallo.fechaNacimiento);

      _sexoSeleccionado = gallo.sexo;
      _estadoSeleccionado = gallo.estado;
      _fechaNacimientoSeleccionada = gallo.fechaNacimiento;
      _rutaFotoTemporal = gallo.fotoPath;
    } else {
      // Valores por defecto para creación
      _sexoSeleccionado = 'Macho';
      _estadoSeleccionado = 'Activo';
    }
  }

  @override
  void dispose() {
    // Limpiar controladores
    _controladorPlaca.dispose();
    _controladorNombre.dispose();
    _controladorLineaGenetica.dispose();
    _controladorColorPluma.dispose();
    _controladorFaseLunar.dispose();
    _controladorNotas.dispose();
    _controladorFechaNacimiento.dispose();
    super.dispose();
  }

  /// Formatea una fecha al formato DD/MM/YYYY
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  /// Abre el selector de imágenes para seleccionar la fotografía del gallo
  ///
  /// Utiliza la galería del dispositivo para permitir al usuario
  /// seleccionar una imagen. La ruta se guarda en [_rutaFotoTemporal]
  ///
  /// NOTA IMPORTANTE - Configuración de Permisos:
  /// - **Android:** Agregar permisos a AndroidManifest.xml:
  ///   ```xml
  ///   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  ///   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  ///   ```
  /// - **iOS:** Agregar configuración a Info.plist:
  ///   ```xml
  ///   <key>NSPhotoLibraryUsageDescription</key>
  ///   <string>CastaSoft necesita acceso a tu galería para seleccionar fotos de gallos</string>
  ///   ```
  Future<void> _seleccionarImagen() async {
    try {
      final imagenSeleccionada = await _selectorImagen.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (imagenSeleccionada != null) {
        setState(() {
          _rutaFotoTemporal = imagenSeleccionada.path;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Copia la imagen seleccionada a un directorio seguro de la aplicación
  /// y devuelve la ruta permanente donde quedó almacenada.
  Future<String> _copiarImagenALocal(String rutaTemporal) async {
    try {
      final archivoOrigen = File(rutaTemporal);

      // Obtener directorio de soporte de la aplicación (no sincronizado con OneDrive)
      // Esto evita problemas de permisos en Windows cuando Documentos está en OneDrive
      final directorioApp = await getApplicationSupportDirectory();

      // Carpeta donde guardaremos las imágenes de gallos
      final carpetaImagenes = Directory(
        path.join(directorioApp.path, 'imagenes_gallos'),
      );
      if (!await carpetaImagenes.exists()) {
        await carpetaImagenes.create(recursive: true);
      }

      // Generar nombre de archivo único conservando la extensión original
      final extension = path.extension(rutaTemporal);
      final nombreUnico = '${const Uuid().v4()}$extension';

      final rutaDestino = path.join(carpetaImagenes.path, nombreUnico);

      // Copiar archivo
      final archivoCopiado = await archivoOrigen.copy(rutaDestino);

      return archivoCopiado.path;
    } catch (e) {
      // Si ocurre un error, relanzarlo para que el llamador lo maneje
      rethrow;
    }
  }

  /// Abre el selector de fecha
  Future<void> _abrirSelectorFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimientoSeleccionada ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaNacimientoSeleccionada = fechaSeleccionada;
        _controladorFechaNacimiento.text = _formatearFecha(fechaSeleccionada);
      });
    }
  }

  /// Guarda el formulario (crea o actualiza)
  Future<void> _guardarFormulario() async {
    // Validar que la fecha esté seleccionada
    if (_fechaNacimientoSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de nacimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar el formulario
    if (!_claveFormulario.currentState!.validate()) {
      return;
    }

    try {
      final gallosProveedor = context.read<GallosProveedor>();

      // Preparar ruta final de la foto (si aplica)
      String? rutaFotoFinal = _rutaFotoTemporal;
      // Si el usuario seleccionó/actualizó la foto y no es la misma ruta
      if (_rutaFotoTemporal != null &&
          _rutaFotoTemporal != widget.galloEditar?.fotoPath) {
        // Copiar la imagen temporal a almacenamiento local de la app
        try {
          rutaFotoFinal = await _copiarImagenALocal(_rutaFotoTemporal!);
        } catch (e) {
          // Mostrar error y abortar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar la imagen: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (_esEdicion) {
        // Editar gallo existente
        final galloEditado = Gallo(
          id: widget.galloEditar!.id,
          placa: _controladorPlaca.text.trim(),
          nombre: _controladorNombre.text.trim(),
          sexo: _sexoSeleccionado!,
          fechaNacimiento: _fechaNacimientoSeleccionada!,
          lineaGenetica: _controladorLineaGenetica.text.trim(),
          colorPluma: _controladorColorPluma.text.trim(),
          faseLunar: _controladorFaseLunar.text.trim(),
          fotoPath: rutaFotoFinal,
          estado: _estadoSeleccionado!,
          notas: _controladorNotas.text.trim().isEmpty
              ? null
              : _controladorNotas.text.trim(),
          idPadre: widget.galloEditar!.idPadre,
          idMadre: widget.galloEditar!.idMadre,
        );

        try {
          await gallosProveedor.actualizarGallo(galloEditado);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
          // No cerrar la pantalla para permitir corrección
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallo actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Crear nuevo gallo
        const generadorUUID = Uuid();
        final nuevoGallo = Gallo(
          id: generadorUUID.v4(),
          placa: _controladorPlaca.text.trim(),
          nombre: _controladorNombre.text.trim(),
          sexo: _sexoSeleccionado!,
          fechaNacimiento: _fechaNacimientoSeleccionada!,
          lineaGenetica: _controladorLineaGenetica.text.trim(),
          colorPluma: _controladorColorPluma.text.trim(),
          faseLunar: _controladorFaseLunar.text.trim(),
          fotoPath: rutaFotoFinal,
          estado: _estadoSeleccionado!,
          notas: _controladorNotas.text.trim().isEmpty
              ? null
              : _controladorNotas.text.trim(),
        );

        try {
          await gallosProveedor.crearGallo(nuevoGallo);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
          // No cerrar la pantalla para permitir corrección
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallo creado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      /// AppBar con título dinámico
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar ${widget.galloEditar!.nombre}' : 'Nuevo Gallo',
        ),
        backgroundColor: const Color(0xFF1E3A8A),
      ),

      /// Cuerpo del formulario
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _claveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// ==================== SECCIÓN 0: FOTO (ENCABEZADO) ====================
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _seleccionarImagen,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _rutaFotoTemporal != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      File(_rutaFotoTemporal!),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        FontAwesomeIcons.edit,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.camera,
                                    size: 48,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Agregar Foto',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Toca la imagen para cambiarla',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              /// ==================== TARJETA 1: IDENTIFICACIÓN ====================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identificación',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _controladorPlaca,
                              decoration: _construirDecoracionCampo(
                                'Placa (Anillo)',
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'La placa es obligatoria';
                                }

                                final gallosProveedor = context
                                    .read<GallosProveedor>();
                                final placaTrimmed = valor.trim();

                                if (_esEdicion &&
                                    widget.galloEditar!.placa == placaTrimmed) {
                                  return null;
                                }

                                if (gallosProveedor.validarPlacaDuplicada(
                                  placaTrimmed,
                                )) {
                                  return 'Esta placa ya está registrada';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _controladorNombre,
                              decoration: _construirDecoracionCampo('Nombre'),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// ==================== TARJETA 2: CARACTERÍSTICAS ====================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Características',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sexoSeleccionado,
                              decoration: _construirDecoracionCampo('Sexo'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Macho',
                                  child: Text('Macho'),
                                ),
                                DropdownMenuItem(
                                  value: 'Hembra',
                                  child: Text('Hembra'),
                                ),
                              ],
                              onChanged: (valor) {
                                setState(() {
                                  _sexoSeleccionado = valor;
                                });
                              },
                              validator: (valor) {
                                if (valor == null) {
                                  return 'Selecciona sexo';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _controladorColorPluma,
                              decoration: _construirDecoracionCampo(
                                'Color de Pluma',
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'Ingresa el color';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _estadoSeleccionado,
                              decoration: _construirDecoracionCampo('Estado'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Activo',
                                  child: Text('Activo'),
                                ),
                                DropdownMenuItem(
                                  value: 'Vendido',
                                  child: Text('Vendido'),
                                ),
                                DropdownMenuItem(
                                  value: 'Retirado',
                                  child: Text('Retirado'),
                                ),
                              ],
                              onChanged: (valor) {
                                setState(() {
                                  _estadoSeleccionado = valor;
                                });
                              },
                              validator: (valor) {
                                if (valor == null) {
                                  return 'Selecciona estado';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _controladorLineaGenetica,
                        decoration: _construirDecoracionCampo(
                          'Línea Genética (Ej: Kelso, Sweater)',
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'La línea genética es obligatoria';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// ==================== TARJETA 3: ORIGEN ====================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Origen',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _controladorFechaNacimiento,
                              decoration: _construirDecoracionCampo(
                                'Fecha de Nacimiento',
                                sufijo: GestureDetector(
                                  onTap: _abrirSelectorFecha,
                                  child: const Icon(Icons.calendar_today),
                                ),
                              ),
                              readOnly: true,
                              validator: (valor) {
                                if (_fechaNacimientoSeleccionada == null) {
                                  return 'Selecciona fecha';
                                }
                                return null;
                              },
                              onTap: _abrirSelectorFecha,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _controladorFaseLunar,
                              decoration: _construirDecoracionCampo(
                                'Fase Lunar (Ej: Luna Nueva)',
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'La fase lunar es obligatoria';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// ==================== CAMPO DE NOTAS ====================
              TextFormField(
                controller: _controladorNotas,
                decoration: _construirDecoracionCampo('Notas (Opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              /// ==================== BOTÓN GUARDAR ====================
              ElevatedButton(
                onPressed: _guardarFormulario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  _esEdicion ? 'Actualizar Gallo' : 'Crear Gallo',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la decoración para los campos de texto
  InputDecoration _construirDecoracionCampo(String etiqueta, {Widget? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF64748B),
      ),
      suffixIcon: sufijo,
    );
  }
}
