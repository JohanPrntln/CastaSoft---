import 'dart:io' show Directory, File, Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart';
import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:castasoft/componentes/icono_adaptativo.dart';

class PantallaExportarPedigree extends StatefulWidget {
  final Gallo gallo;

  const PantallaExportarPedigree({super.key, required this.gallo});

  @override
  State<PantallaExportarPedigree> createState() => _PantallaExportarPedigreeState();
}

class _PantallaExportarPedigreeState extends State<PantallaExportarPedigree> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();
  
  // Controladores
  late TextEditingController _nombreCtrl;
  late TextEditingController _placaCtrl;
  late TextEditingController _razaCtrl;
  late TextEditingController _pesoCtrl;
  late TextEditingController _colorCtrl; 
  late TextEditingController _fechaNacCtrl; // 🔥 NUEVO: Controlador para Fecha de Nacimiento
  late TextEditingController _criaderoCtrl;
  late TextEditingController _padreCtrl;
  late TextEditingController _madreCtrl;
  late TextEditingController _abueloPCtrl;
  late TextEditingController _abuelaPCtrl;
  late TextEditingController _abueloMCtrl;
  late TextEditingController _abuelaMCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _linkExtraCtrl;
  late TextEditingController _labelQrDerechoCtrl;
  late TextEditingController _firmaCtrl;

  // País
  String _prefijoPais = '57'; 
  final List<Map<String, String>> _listaPaises = [
    {'nombre': '🇨🇴 COL', 'codigo': '57'},
    {'nombre': '🇺🇸 USA/PR', 'codigo': '1'},
    {'nombre': '🇲🇽 MEX', 'codigo': '52'},
    {'nombre': '🇪🇸 ESP', 'codigo': '34'},
    {'nombre': '🇪🇨 ECU', 'codigo': '593'},
    {'nombre': '🇵🇪 PER', 'codigo': '51'},
    {'nombre': '🇩🇴 DOM', 'codigo': '1'},
    {'nombre': '🇵🇦 PAN', 'codigo': '507'},
  ];

  XFile? _logoPersonalizado; // XFile: compatible con Web (CLAUDE.md, zona 2)
  Uint8List? _logoUsuarioBytes; // Logo del perfil ya decodificado (memoizado)
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    // 1. Datos Gallo
    _nombreCtrl = TextEditingController(text: widget.gallo.nombre);
    _placaCtrl = TextEditingController(text: widget.gallo.placa);
    _razaCtrl = TextEditingController(text: widget.gallo.lineaGenetica);
    _pesoCtrl = TextEditingController(text: '${widget.gallo.pesoActual ?? "--"} Lbs');
    _colorCtrl = TextEditingController(text: widget.gallo.colorPluma); 
    
    // 🔥 Extraemos la fecha de nacimiento directamente del registro y le damos formato
    _fechaNacCtrl = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.gallo.fechaNacimiento)
    );
    
    // 2. Datos Usuario
    final usuarioProv = context.read<UsuarioProveedor>();
    final UsuarioPerfil? usuario = usuarioProv.perfil; 

    String nombreCastaderoPerfil = usuario?.nombreCastadero ?? 'Mi Criadero'; 
    _criaderoCtrl = TextEditingController(text: widget.gallo.criaderoOrigen.isEmpty ? nombreCastaderoPerfil : widget.gallo.criaderoOrigen);
    _logoUsuarioBytes = usuario?.logoBytes;

    // 3. Genealogía
    _padreCtrl = TextEditingController(text: widget.gallo.nombrePadre ?? 'Desconocido');
    _madreCtrl = TextEditingController(text: widget.gallo.nombreMadre ?? 'Desconocido');
    _abueloPCtrl = TextEditingController(text: widget.gallo.nombreAbueloPaterno ?? '---');
    _abuelaPCtrl = TextEditingController(text: widget.gallo.nombreAbuelaPaterna ?? '---');
    _abueloMCtrl = TextEditingController(text: widget.gallo.nombreAbueloMaterno ?? '---');
    _abuelaMCtrl = TextEditingController(text: widget.gallo.nombreAbuelaMaterna ?? '---');

    // 4. Contacto
    String telUsuario = usuario?.telefono ?? '';
    _whatsappCtrl = TextEditingController(text: telUsuario);
    
    // INICIAN VACÍOS PARA QUE SEA OPCIONAL
    _linkExtraCtrl = TextEditingController(text: ''); 
    _labelQrDerechoCtrl = TextEditingController(text: ''); 
    
    String nombreUsuario = usuario?.nombrePropietario ?? '';
    _firmaCtrl = TextEditingController(text: nombreUsuario);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _placaCtrl.dispose(); _razaCtrl.dispose(); _pesoCtrl.dispose(); 
    _colorCtrl.dispose(); _fechaNacCtrl.dispose(); _criaderoCtrl.dispose(); 
    _padreCtrl.dispose(); _madreCtrl.dispose();
    _abueloPCtrl.dispose(); _abuelaPCtrl.dispose(); _abueloMCtrl.dispose(); _abuelaMCtrl.dispose();
    _whatsappCtrl.dispose(); _linkExtraCtrl.dispose(); _labelQrDerechoCtrl.dispose(); _firmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiarLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 500); 
    if (image != null) {
      setState(() => _logoPersonalizado = image);
    }
  }

  Future<void> _guardarImagen({bool soloCompartir = false}) async {
    // Campos requeridos del certificado: no se aceptan solo espacios
    if (_nombreCtrl.text.trim().isEmpty || _placaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El nombre y la placa del ejemplar son obligatorios'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 500)); 

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 20),
        pixelRatio: 2.0 
      );

      if (imageBytes != null) {
        final String fileName = 'pedigree_${widget.gallo.placa}_${DateTime.now().millisecondsSinceEpoch}.png';
        
        // 🔥 EL TRUCO BIFURCADO:
        if (kIsWeb) {
          // Si estamos en la Web, obligamos al navegador a descargar el archivo
          final xfile = XFile.fromData(imageBytes, mimeType: 'image/png', name: fileName);
          await xfile.saveTo(fileName); 
          if(mounted) _mostrarMensajeExito('¡Descargado en tu navegador!');
        } else {
          // Si estamos en Windows/Android/iOS, usamos tu código nativo original
          final Directory tempDir = await getTemporaryDirectory();
          final File tempFile = await File('${tempDir.path}/$fileName').create();
          await tempFile.writeAsBytes(imageBytes);

          if (soloCompartir) {
            await Share.shareXFiles([XFile(tempFile.path)], text: 'Certificado de Pedigrí - ${widget.gallo.nombreMostrar}');
          } else {
            if (Platform.isAndroid || Platform.isIOS) {
              await Gal.putImage(tempFile.path);
              if(mounted) _mostrarMensajeExito('¡Guardado en Galería!');
            } else {
               final downloadsDir = await getDownloadsDirectory();
               if (downloadsDir != null) {
                 final String savePath = '${downloadsDir.path}\\$fileName';
                 await tempFile.copy(savePath);
                 if(mounted) _mostrarMensajeExito('Guardado en Descargas');
               }
            }
          }
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _cargando = false);
    }
}
  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(mensaje))]),
      backgroundColor: const Color(0xFF4E342E),
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _generarLinkWhatsApp() {
    // wa.me solo acepta dígitos: se quitan espacios, guiones y '+'
    String numero = _whatsappCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numero.isEmpty) return 'https://wa.me'; 
    return 'https://wa.me/$_prefijoPais$numero?text=Hola, me interesa ver el pedigrí del gallo ${_nombreCtrl.text} (Placa: ${_placaCtrl.text})';
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // 🎛️ ZONA DE CALIBRACIÓN
    // ============================================================
    const double leftDatos = 190.0; 
    const double topNombre = 185.2;  // 1er Renglón
    const double topPlaca  = 217.0;  // 2do Renglón
    const double topLinea  = 240.0;  // 3er Renglón
    const double topPeso   = 259.0;  // 4to Renglón
    const double topColor  = 279.0;  // 5to Renglón
    const double topFechaNac = 299.0; // 🔥 6to Renglón (Fecha de Nacimiento)

    const double topPadres = 363.0;
    const double topAbuelos1 = 417.0; 
    const double topAbuelos2 = 435.0; 

    // Altura para las etiquetas de "Padre" y "Madre"
    const double topEtiquetasPadres = 350.0; 

    const Color textoCafeArmonico = Color(0xFF4E342E); 
    const Color textoCafeTitulo = Color(0xFF5D4037); 
    const Color doradoSuave = Color(0xFFD4AF37); 

    const double anchoLienzo = 415; 
    const double altoLienzo = 590; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Certificado'),
        backgroundColor: doradoSuave,
        actions: [
          IconButton(icon: const Icon(Icons.share), tooltip: 'Compartir', onPressed: () => _guardarImagen(soloCompartir: true)),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Restaurar Logo', onPressed: () => setState(() => _logoPersonalizado = null))
        ],
      ),
      backgroundColor: Colors.grey.shade200, 
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("VISTA PREVIA (HD)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            
            // LIENZO ESCALABLE
            Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: anchoLienzo, 
                    height: altoLienzo, 
                    color: Colors.white,
                    child: Stack(
                      children: [
                        // 1. FONDO
                        Positioned.fill(child: Image.asset('assets/plantilla_pedigree.png', fit: BoxFit.fill)),

                        // 2. ENCABEZADO CRIADERO
                        Positioned(
                          top: 45, left: 57, 
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(onTap: _cambiarLogo, child: _construirLogoCriadero(90)),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 180, 
                                child: Text(
                                  _criaderoCtrl.text.toUpperCase(), 
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w900, color: textoCafeTitulo, letterSpacing: 1.2),
                                  maxLines: 2, overflow: TextOverflow.ellipsis, 
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. FECHA
                        Positioned(
                          top: 40, right: 49,
                          child: Text('Expedición \n${DateFormat('dd/MM/yyyy').format(DateTime.now())}', textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 7, color: Colors.black54, fontWeight: FontWeight.w500)),
                        ),

                        // 4. FOTO GALLO
                        Positioned(top: 195, left: 63, child: _construirFotoGallo(119, 144)),

                        // 5. DATOS PRINCIPALES
                        _datoEnLienzo('', _nombreCtrl.text, topNombre, leftDatos, maxWidth: 200, size: 11, isTitle: true, colorBase: textoCafeArmonico),
                        _datoEnLienzo('Placa:', _placaCtrl.text, topPlaca, leftDatos, maxWidth: 200, colorBase: textoCafeArmonico),
                        _datoEnLienzo('Línea:', _razaCtrl.text, topLinea, leftDatos, maxWidth: 160, colorBase: textoCafeArmonico),
                        _datoEnLienzo('Peso:', _pesoCtrl.text, topPeso, leftDatos, maxWidth: 160, colorBase: textoCafeArmonico),
                        _datoEnLienzo('Color:', _colorCtrl.text, topColor, leftDatos, maxWidth: 160, colorBase: textoCafeArmonico),
                        
                        // 🔥 MODIFICADO: F. Nacimiento en el lienzo
                        _datoEnLienzo('F. Nac:', _fechaNacCtrl.text, topFechaNac, leftDatos, maxWidth: 160, colorBase: textoCafeArmonico),

                        // ETIQUETAS "PADRE" Y "MADRE"
                        _etiquetaPadreMadre('Padre', top: topEtiquetasPadres, left: 80, width: 120, color: Colors.black54),
                        _etiquetaPadreMadre('Madre', top: topEtiquetasPadres, left: 210, width: 120, color: Colors.black54),

                        // 6. GENEALOGÍA PADRES
                        _textoGenealogia(_padreCtrl.text, top: topPadres, left: 80, width: 120, color: const Color(0xFF1565C0)), // Azul
                        _textoGenealogia(_madreCtrl.text, top: topPadres, left: 210, width: 120, color: const Color(0xFFAD1457)), // Rosa

                        // 7. GENEALOGÍA ABUELOS
                        _textoGenealogia('Ab.P: ${_abueloPCtrl.text}', top: topAbuelos1, left: 70, width: 117, size: 9, color: textoCafeTitulo),
                        _textoGenealogia('Ab.M: ${_abuelaPCtrl.text}', top: topAbuelos2, left: 70, width: 117, size: 9, color: textoCafeTitulo),
                        _textoGenealogia('Ab.P: ${_abueloMCtrl.text}', top: topAbuelos1, left: 213, width: 117, size: 9, color: textoCafeTitulo),
                        _textoGenealogia('Ab.M: ${_abuelaMCtrl.text}', top: topAbuelos2, left: 213, width: 117, size: 9, color: textoCafeTitulo),

                        // 8. CONTACTO Y QR IZQUIERDO (WhatsApp)
                        Positioned(bottom: 62, left: 68, child: _construirQR(_generarLinkWhatsApp())),
                        Positioned(bottom: 43, left: 63, child: SizedBox(width: 60, child: Text("WhatsApp", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold)))),

                        // QR DERECHO OPCIONAL
                        if (_linkExtraCtrl.text.isNotEmpty)
                          Positioned(
                            bottom: 63, 
                            right: 69, 
                            child: _construirQR(_linkExtraCtrl.text)
                          ),
                        
                        // Etiqueta del QR derecho
                        if (_linkExtraCtrl.text.isNotEmpty)
                          Positioned(
                            bottom: 43, 
                            right: 55, 
                            child: SizedBox(
                              width: 75, 
                              child: Text(
                                _labelQrDerechoCtrl.text.isEmpty ? 'Escanéame' : _labelQrDerechoCtrl.text, 
                                textAlign: TextAlign.center, 
                                overflow: TextOverflow.ellipsis, 
                                style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.bold)
                              )
                            )
                          ),

                        // 9. FIRMA
                        Positioned(
                          bottom: 85, left: 40, right: 40, 
                          child: Center(child: Text(_firmaCtrl.text, style: GoogleFonts.dancingScript(fontSize: 18, fontWeight: FontWeight.w600, color: textoCafeArmonico), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ),

                        // 10. MARCA DE AGUA
                        Positioned(
                          bottom: 55, right: 0, left: 0, 
                          child: Center(child: Text('Tecnología CastaSoft ©', style: GoogleFonts.poppins(fontSize: 7, color: Colors.grey.shade400, letterSpacing: 1))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // FORMULARIO DE EDICIÓN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seccionTitulo('1. DATOS DEL CERTIFICADO'),
                  _input('Nombre del Gallo', _nombreCtrl),
                  Row(children: [Expanded(child: _input('Placa', _placaCtrl)), const SizedBox(width: 10), Expanded(child: _input('Línea/Raza', _razaCtrl))]),
                  Row(children: [Expanded(child: _input('Peso', _pesoCtrl)), const SizedBox(width: 10), Expanded(child: _input('Color Pluma', _colorCtrl))]),
                  
                  // 🔥 MODIFICADO: Formulario muestra "Fecha de Nacimiento"
                  _input('Fecha de Nacimiento', _fechaNacCtrl, icon: FontAwesomeIcons.calendarDay),
                  
                  _input('Nombre del Criadero', _criaderoCtrl, icon: FontAwesomeIcons.houseFlag),

                  const SizedBox(height: 15),
                  _seccionTitulo('2. GENEALOGÍA'),
                  _input('Padre', _padreCtrl),
                  _input('Madre', _madreCtrl),
                  
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: const Text('Editar Abuelos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      childrenPadding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 20),
                      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          Text("Rama Paterna (Macho)", style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          _input('Abuelo Paterno', _abueloPCtrl),
                          _input('Abuela Paterna', _abuelaPCtrl),
                          const Divider(),
                          Text("Rama Materna (Hembra)", style: TextStyle(fontSize: 12, color: Colors.pink.shade700, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          _input('Abuelo Materno', _abueloMCtrl),
                          _input('Abuela Materna', _abuelaMCtrl),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  _seccionTitulo('3. CONTACTO'),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _prefijoPais,
                            onChanged: (v) => setState(() => _prefijoPais = v!),
                            items: _listaPaises.map((p) => DropdownMenuItem(value: p['codigo'], child: Text(p['nombre']!, style: const TextStyle(fontSize: 13)))).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _input('WhatsApp', _whatsappCtrl, icon: FontAwesomeIcons.whatsapp, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _input('Firma', _firmaCtrl, icon: FontAwesomeIcons.signature),
                  
                  _seccionTitulo('4. QR DERECHO (OPCIONAL)'),
                  const Text("Si dejas esto vacío, no saldrá el QR derecho.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  _input('Enlace Extra (Ej: Facebook/Instagram)', _linkExtraCtrl, icon: FontAwesomeIcons.link),
                  if (_linkExtraCtrl.text.isNotEmpty)
                    _input('Texto debajo del QR (Ej: Síguenos)', _labelQrDerechoCtrl, icon: Icons.label),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cargando ? null : () => _guardarImagen(soloCompartir: false),
        backgroundColor: doradoSuave,
        icon: _cargando 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Icon(Icons.save_alt, color: Colors.white),
        label: Text(
          _cargando ? 'GUARDANDO...' : 'GUARDAR IMAGEN', 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ), 
    ); 
  } 

  Widget _seccionTitulo(String titulo) {
    return Padding(padding: const EdgeInsets.only(bottom: 15, top: 10), child: Text(titulo, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF4E342E))));
  }

  Widget _input(String label, TextEditingController ctrl, {dynamic icon, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl, keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]'))] : null,
        maxLength: isNumber ? 20 : null,
        decoration: InputDecoration(
          labelText: label, 
          prefixIcon: icon != null 
              ? IconoAdaptativo.prefijo(icon, size: 20, color: Colors.grey.shade600)
              : null, 
          isDense: true, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), 
          filled: true, 
          fillColor: Colors.grey.shade50, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18)
        ),
        onChanged: (v) => setState((){}),
      ),
    );
  }

  Widget _datoEnLienzo(String label, String valor, double top, double left, {required double maxWidth, double size = 11, bool isTitle = false, required Color colorBase}) {
    const Color colorEtiqueta = Colors.black54; 
    return Positioned(
      top: top, left: left,
      child: SizedBox(
        width: maxWidth, 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            if (label.isNotEmpty) 
              Text('$label ', style: GoogleFonts.poppins(fontSize: size, color: colorEtiqueta, fontWeight: FontWeight.w400)),
            Expanded(
              child: Text(
                valor, 
                style: GoogleFonts.poppins(fontSize: isTitle ? size + 4 : size, fontWeight: FontWeight.w500, color: colorBase, height: 1.1),
                maxLines: 2, overflow: TextOverflow.visible, softWrap: true, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _etiquetaPadreMadre(String texto, {required double top, required double left, required double width, required Color color}) {
    return Positioned(
      top: top, left: left,
      child: Container(
        width: width, alignment: Alignment.center,
        child: Text(
          texto, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.poppins(
            fontSize: 8, 
            fontWeight: FontWeight.w500, 
            color: color
          )
        ),
      ),
    );
  }

  Widget _textoGenealogia(String texto, {required double top, required double left, required double width, required Color color, double size = 11}) {
    return Positioned(
      top: top, left: left,
      child: Container(
        width: width, alignment: Alignment.center,
        child: Text(texto, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }

  Widget _construirLogoCriadero(double size) {
    ImageProvider? imagen;
    if (_logoPersonalizado != null) {
      imagen = kIsWeb
          ? NetworkImage(_logoPersonalizado!.path) as ImageProvider
          : FileImage(File(_logoPersonalizado!.path));
    } else if (_logoUsuarioBytes != null) {
      imagen = MemoryImage(_logoUsuarioBytes!);
    }
    
    return Container(
      width: size, height: size, 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        border: Border.all(color: const Color(0xFFD4AF37), width: 3), 
        image: imagen != null ? DecorationImage(image: imagen, fit: BoxFit.cover) : null,
        color: imagen == null ? Colors.white.withValues(alpha: 0.9) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(2, 2))]
      ),
      child: imagen == null ? const FaIcon(FontAwesomeIcons.crown, color: Color(0xFFD4AF37), size: 40) : null,
    );
  }

  Widget _construirFotoGallo(double w, double h) {
    ImageProvider? imagen;
    final bytes = widget.gallo.fotoBytes; // Memoizada en el modelo: O(1)
    if (bytes != null) imagen = MemoryImage(bytes);
    return Container(width: w, height: h, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4), image: imagen != null ? DecorationImage(image: imagen, fit: BoxFit.cover) : null, border: Border.all(color: const Color(0xFFD4AF37), width: 1.5)), child: imagen == null ? Icon(Icons.camera_alt, color: Colors.grey.shade400) : null);
  }

  Widget _construirQR(String data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(2) 
      ), 
      child: QrImageView(
        data: data, 
        version: QrVersions.auto, 
        size: 54.0, 
        backgroundColor: Colors.white, 
        padding: const EdgeInsets.all(2.0), 
        gapless: true, 
        errorStateBuilder: (c, e) => const Icon(Icons.error, size: 20, color: Colors.red),
      ),
    );
  }
}