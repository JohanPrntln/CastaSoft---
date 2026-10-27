import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/proveedores/cruces_proveedor.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/componentes/icono_adaptativo.dart';

class PantallaFormularioCruce extends StatefulWidget {
  final CruceModelo? cruceEditar; 
  const PantallaFormularioCruce({super.key, this.cruceEditar});

  @override
  State<PantallaFormularioCruce> createState() => _PantallaFormularioCruceState();
}

class _PantallaFormularioCruceState extends State<PantallaFormularioCruce> {
  final _formKey = GlobalKey<FormState>();
  // Campos que dependen entre sí: se revalidan juntos en tiempo real (RN-02)
  final _claveMuertos = GlobalKey<FormFieldState<String>>();
  final _claveMachos = GlobalKey<FormFieldState<String>>();
  final _claveHembras = GlobalKey<FormFieldState<String>>();
  final Color _colorTema = const Color(0xFF059669);

  // Controladores
  final _ctrlCantidad = TextEditingController();
  final _ctrlMuertos = TextEditingController(text: '0');
  final _ctrlMachos = TextEditingController(text: '0'); 
  final _ctrlHembras = TextEditingController(text: '0'); 

  final _ctrlMarca = TextEditingController();
  final _ctrlNotas = TextEditingController();
  final _ctrlFecha = TextEditingController();

  // Variables
  String? _padreId;
  String? _madreId;
  String? _faseLunar;
  
  // 🔥 CAMBIO: Valor por defecto más común
  String _pataMarca = 'Pata Derecha'; 
  
  // 🔥 NUEVA LISTA DE OPCIONES INCLUSIVA
  final List<String> _opcionesIdentificacion = [
    'Pata Derecha',
    'Pata Izquierda',
    'Ambas Patas',
    'Ala Derecha',
    'Ala Izquierda',
    'Placa / Cuello',
    'Sin Marca / Otro'
  ];

  DateTime _fechaSeleccionada = DateTime.now();
  XFile? _imagenNueva;
  String? _fotoActualBase64; 
  Uint8List? _fotoActualBytes; // Decodificada una sola vez (memoizada en el modelo)
  bool _guardando = false;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    if (widget.cruceEditar != null) {
      _cargarDatosEdicion();
    } else {
      _ctrlFecha.text = DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);
    }
  }

  void _cargarDatosEdicion() {
    _esEdicion = true;
    final c = widget.cruceEditar!;
    _padreId = c.padreId;
    _madreId = c.madreId;
    _fechaSeleccionada = c.fechaCruce;
    _ctrlFecha.text = DateFormat('dd/MM/yyyy').format(c.fechaCruce);
    // Valores antiguos ('Llena', 'Nueva'...) se mapean a las 8 fases oficiales
    _faseLunar = Gallo.normalizarFaseLunar(c.faseLunar);
    _ctrlCantidad.text = c.cantidadPollitos.toString();
    _ctrlMuertos.text = c.pollitosMuertos.toString();
    _ctrlMachos.text = c.pollitosMachos.toString();
    _ctrlHembras.text = c.pollitosHembras.toString();
    
    // Si la marca guardada no está en la nueva lista, la agregamos temporalmente o la mandamos a 'Sin Marca'
    if (_opcionesIdentificacion.contains(c.pataMarca)) {
      _pataMarca = c.pataMarca;
    } else {
      // Manejo de compatibilidad con versiones viejas (que decían solo 'Izquierda' o 'Derecha')
      if (c.pataMarca == 'Izquierda') {
        _pataMarca = 'Pata Izquierda';
      } else if (c.pataMarca == 'Derecha') {
        _pataMarca = 'Pata Derecha';
      } else {
        _pataMarca = 'Sin Marca / Otro';
      }
    }

    _ctrlMarca.text = c.detalleMarca;
    _ctrlNotas.text = c.notas ?? '';
    _fotoActualBase64 = c.fotoPath;
    _fotoActualBytes = c.fotoBytes;
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25, maxWidth: 800);
    if (picked != null) {
      // Lo asignamos directo, sin el File()
      setState(() => _imagenNueva = picked); 
    }
  }

  // 🔥 NUEVO: Función para borrar la foto
  void _borrarFoto() {
    setState(() {
      _imagenNueva = null;
      _fotoActualBase64 = null;
      _fotoActualBytes = null;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final int total = int.tryParse(_ctrlCantidad.text.trim()) ?? 0;
    final int muertos = int.tryParse(_ctrlMuertos.text.trim()) ?? 0;
    final int machos = int.tryParse(_ctrlMachos.text.trim()) ?? 0;
    final int hembras = int.tryParse(_ctrlHembras.text.trim()) ?? 0;

    // RN-02 (coherencia biológica) + RN-04 (progenitores obligatorios)
    final String? errorReglas = CruceModelo.validarReglasNegocio(
      padreId: _padreId,
      madreId: _madreId,
      cantidadHuevos: total,
      pollitosMuertos: muertos,
      pollitosMachos: machos,
      pollitosHembras: hembras,
    );
    if (errorReglas != null) {
      _mostrarError(errorReglas);
      return;
    }

    final int vivos = total - muertos;

    // Se capturan ANTES de cualquier await (contexto asíncrono seguro)
    final gallosProv = context.read<GallosProveedor>();
    final crucesProv = context.read<CrucesProveedor>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _guardando = true);

    try {
      // RN-03: nombres desnormalizados (se conservan aunque se borre el ancestro)
      final String nombreP = gallosProv.obtenerGalloPorId(_padreId!)?.nombreMostrar
          ?? (_esEdicion ? widget.cruceEditar!.nombrePadre : 'Desconocido');
      final String nombreM = gallosProv.obtenerGalloPorId(_madreId!)?.nombreMostrar
          ?? (_esEdicion ? widget.cruceEditar!.nombreMadre : 'Desconocida');

      final user = FirebaseAuth.instance.currentUser;

      String? fotoFinal;
      // Lógica: Si hay imagen nueva, úsala. Si no hay nueva pero hay vieja, usa vieja. Si ambas son null (porque se borró), manda null.
      if (_imagenNueva != null) {
        final bytes = await _imagenNueva!.readAsBytes();
        fotoFinal = 'base64,${base64Encode(bytes)}';
      } else {
        fotoFinal = _fotoActualBase64;
      }

      final cruceModelo = CruceModelo(
        id: _esEdicion ? widget.cruceEditar!.id : const Uuid().v4(),
        userId: _esEdicion ? widget.cruceEditar!.userId : user?.uid ?? '', // El proveedor reinyecta el UID activo (RN-05)
        padreId: _padreId!,
        nombrePadre: nombreP,
        madreId: _madreId!,
        nombreMadre: nombreM,
        fechaCruce: _fechaSeleccionada,
        faseLunar: _faseLunar ?? 'Luna creciente',
        cantidadPollitos: total,
        pollitosMuertos: muertos,
        pollitosVivos: vivos, 
        pollitosMachos: machos,
        pollitosHembras: hembras,
        pataMarca: _pataMarca,
        detalleMarca: _ctrlMarca.text.trim(),
        fotoPath: fotoFinal,
        notas: _ctrlNotas.text.trim(),
      );

      // Sin red responde en <= 2.5 s con `confirmado == false` (cola offline)
      final bool confirmado = _esEdicion
          ? await crucesProv.actualizarCruce(cruceModelo)
          : await crucesProv.agregarCruce(cruceModelo);

      messenger.showSnackBar(SnackBar(
        content: Text(confirmado
            ? (_esEdicion ? 'Cruce actualizado' : 'Cruce registrado')
            : 'Cruce guardado sin conexión: se sincronizará al volver el internet'),
        backgroundColor: confirmado ? Colors.green : Colors.orange.shade800,
      ));
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  static int _entero(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  int get _nacidos => _entero(_ctrlCantidad);
  int get _muertos => _entero(_ctrlMuertos);
  int get _vivos => (_nacidos - _muertos).clamp(0, 999);
  int get _sexados => _entero(_ctrlMachos) + _entero(_ctrlHembras);

  void _revalidarConteos() {
    setState(() {});
    for (final clave in [_claveMuertos, _claveMachos, _claveHembras]) {
      clave.currentState?.validate();
    }
  }

  String? _validarMuertos(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    if (_muertos > _nacidos) return CruceModelo.mensajeMuertosExcedidos(_muertos, _nacidos);
    return null;
  }

  // Sexado diferido: 0 machos y 0 hembras (o una suma menor a los vivos) es válido
  String? _validarSexado(String? _) =>
      _sexados > _vivos ? CruceModelo.mensajeSexadoExcedido(_sexados, _vivos) : null;

  String? _validarDetalleMarca(String? v) {
    // Retrocompatibilidad: un detalle antiguo sin cambios no bloquea la edición
    if (_esEdicion && (v ?? '').trim() == widget.cruceEditar!.detalleMarca.trim()) return null;
    return CruceModelo.validarDetalleMarca(v);
  }

  Widget _buildResumenCamada() {
    final muertosValidos = _muertos <= _nacidos;
    final sexadoValido = muertosValidos && _sexados <= _vivos;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (muertosValidos)
          Chip(
            key: const Key('chip-vivos'),
            avatar: const Icon(Icons.favorite, size: 16, color: Color(0xFF059669)),
            label: Text('Pollitos vivos actuales: $_vivos'),
          ),
        if (sexadoValido)
          Chip(
            key: const Key('chip-pendientes'),
            avatar: const Icon(Icons.help_outline, size: 16, color: Colors.orange),
            label: Text('Pendientes por definir sexo: ${_vivos - _sexados}'),
          ),
      ],
    );
  }

  double get _anchoPantalla => MediaQuery.sizeOf(context).width;

  /// Texto de opción de desplegable: hasta 2 líneas, sin ocultar el nombre.
  Widget _textoOpcion(String texto) => Text(
        texto,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: _anchoPantalla < 400 ? 13.5 : 14),
      );

  /// Dos campos en fila; en pantallas más angostas que [corte] se apilan.
  Widget _par(Widget a, Widget b, {required double corte}) {
    if (_anchoPantalla < corte) {
      return Column(children: [a, const SizedBox(height: 12), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(mensaje))]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final gallos = context.watch<GallosProveedor>().gallos;
    final padres = gallos.where((g) => g.sexo == 'Macho').toList();
    final madres = gallos.where((g) => g.sexo == 'Hembra').toList();

    // Ítems de progenitores. Si en edición el ancestro ya no existe, se agrega
    // un ítem con su nombre desnormalizado para no perder el vínculo (RN-03/04)
    // y para que DropdownButtonFormField no falle por valor inexistente.
    List<DropdownMenuItem<String>> itemsProgenitor(List<Gallo> lista, String? idActual, String? nombreGuardado) {
      final items = lista
          .map((g) => DropdownMenuItem(value: g.id, child: _textoOpcion(g.etiquetaSelector)))
          .toList();
      if (idActual != null && !lista.any((g) => g.id == idActual)) {
        items.add(DropdownMenuItem(value: idActual, child: _textoOpcion('${nombreGuardado ?? 'Desconocido'} (eliminado)')));
      }
      return items;
    }

    final itemsPadre = itemsProgenitor(padres, _padreId, widget.cruceEditar?.nombrePadre);
    final itemsMadre = itemsProgenitor(madres, _madreId, widget.cruceEditar?.nombreMadre);
    // El ítem seleccionado se muestra igual que en la lista (hasta 2 líneas)
    List<Widget> seleccionados(List<DropdownMenuItem<String>> items) =>
        items.map((i) => Align(alignment: Alignment.centerLeft, child: i.child)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cruce' : 'Nuevo Cruce Genético'),
        backgroundColor: _colorTema,
      ),
      body: _guardando 
        ? Center(child: CircularProgressIndicator(color: _colorTema))
        : SingleChildScrollView(
            padding: EdgeInsets.all(_anchoPantalla < 480 ? 12 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('* Campos obligatorios',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                    ),
                  ),
                  _buildCard('🧬 Los Padres', [
                    DropdownButtonFormField<String>(
                      key: ValueKey('padre-$_padreId'),
                      isExpanded: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _inputDeco('Padre (Padrote) *', FontAwesomeIcons.mars),
                      initialValue: _padreId,
                      itemHeight: null,
                      items: itemsPadre,
                      selectedItemBuilder: (_) => seleccionados(itemsPadre),
                      onChanged: (v) => setState(() => _padreId = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el padre' : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      key: ValueKey('madre-$_madreId'),
                      isExpanded: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: _inputDeco('Madre (Madrilla) *', FontAwesomeIcons.venus),
                      initialValue: _madreId,
                      itemHeight: null,
                      items: itemsMadre,
                      selectedItemBuilder: (_) => seleccionados(itemsMadre),
                      onChanged: (v) => setState(() => _madreId = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona la madre' : null,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildCard('🐣 Estadísticas de la Camada', [
                    _par(
                      TextFormField(
                          controller: _ctrlFecha,
                          readOnly: true,
                          decoration: _inputDeco('Fecha del Cruce / Nacimiento *', FontAwesomeIcons.calendar),
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: _fechaSeleccionada, firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (d != null) {
                              setState(() {
                                _fechaSeleccionada = d;
                                _ctrlFecha.text = DateFormat('dd/MM/yyyy').format(d);
                              });
                            }
                          },
                        ),
                      DropdownButtonFormField<String>(
                          key: ValueKey('luna-$_faseLunar'),
                          isExpanded: true,
                          initialValue: _faseLunar,
                          items: Gallo.opcionesFaseLunar(_faseLunar)
                              .map((l) => DropdownMenuItem(value: l, child: _textoOpcion(l)))
                              .toList(),
                          onChanged: (v) => setState(() => _faseLunar = v),
                          decoration: _inputDeco('Luna', FontAwesomeIcons.moon),
                        ),
                      corte: 420,
                    ),
                    const SizedBox(height: 15),
                    
                    _par(
                          TextFormField(
                            key: const Key('campo-nacidos'),
                            controller: _ctrlCantidad,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: _inputDeco('Pollitos Nacidos *', FontAwesomeIcons.egg),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            onChanged: (_) => _revalidarConteos(),
                          ),
                          TextFormField(
                            key: _claveMuertos,
                            controller: _ctrlMuertos,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: _inputDeco('Bajas / Muertos *', FontAwesomeIcons.skull),
                            validator: _validarMuertos,
                            onChanged: (_) => _revalidarConteos(),
                          ),
                          corte: 360,
                    ),
                    
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('Clasificación por Sexo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 10),
                    _buildResumenCamada(),
                    const SizedBox(height: 10),

                    _par(
                          TextFormField(
                            key: _claveMachos,
                            controller: _ctrlMachos,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: _inputDeco('Machos', FontAwesomeIcons.mars),
                            validator: _validarSexado,
                            onChanged: (_) => _revalidarConteos(),
                          ),
                          TextFormField(
                            key: _claveHembras,
                            controller: _ctrlHembras,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.bold),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: _inputDeco('Hembras', FontAwesomeIcons.venus),
                            validator: _validarSexado,
                            onChanged: (_) => _revalidarConteos(),
                          ),
                          corte: 360,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildCard('Marcaje e Identificación de la Camada (Pollitos)', [
                      DropdownButtonFormField<String>(
                        key: ValueKey('marca-$_pataMarca'),
                        initialValue: _pataMarca,
                        isExpanded: true, // Para que los textos largos no se corten
                        items: _opcionesIdentificacion.map((l) => DropdownMenuItem(value: l, child: _textoOpcion(l))).toList(),
                        onChanged: (v) => setState(() => _pataMarca = v!),
                        decoration: _inputDeco('Ubicación de la marca en los pollitos', FontAwesomeIcons.locationDot),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        key: const Key('campo-detalle-marca'),
                        controller: _ctrlMarca,
                        maxLines: 2,
                        maxLength: CruceModelo.maxDetalleMarca,
                        inputFormatters: [FilteringTextInputFormatter.allow(CruceModelo.caracteresDetalleMarca)],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: _validarDetalleMarca,
                        decoration: _inputDeco(
                          'Detalle de placa, color de cintillo, marca del lote o placa/anillo',
                          FontAwesomeIcons.tag,
                        ).copyWith(
                          hintText: 'Ej: Cintillo verde, Placas #201 a #205, Marca en ala...',
                        ),
                      ),
                  ]),

                  const SizedBox(height: 20),

                  _buildCard('📝 Notas', [
                      TextFormField(
                        controller: _ctrlNotas,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: _inputDeco('Observaciones adicionales', Icons.note),
                      ),
                  ]),

                  const SizedBox(height: 20),

                  // 🔥 AQUÍ ESTÁ EL CAMBIO DE LA FOTO
                  _buildFotoPreview(),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _colorTema),
                      onPressed: _guardando ? null : _guardar,
                      child: Text(_esEdicion ? 'ACTUALIZAR DATOS' : 'GUARDAR CRUCE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  // 🔥 WIDGET DE FOTO CON BOTÓN DE BORRAR
  Widget _buildFotoPreview() {
    ImageProvider? imgProvider;
    bool hayFoto = false;

    if (_imagenNueva != null) {
      // 🔥 AQUÍ USAMOS kIsWeb Y DESAPARECE TU AVISO
      imgProvider = kIsWeb 
          ? NetworkImage(_imagenNueva!.path) as ImageProvider 
          : FileImage(File(_imagenNueva!.path));
      hayFoto = true;
    } else if (_fotoActualBytes != null) {
      imgProvider = MemoryImage(_fotoActualBytes!);
      hayFoto = true;
    } else if (_fotoActualBase64 != null) {
      hayFoto = true; // Foto corrupta/ilegible: igual se permite borrarla
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: _seleccionarFoto,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              image: imgProvider != null ? DecorationImage(image: imgProvider, fit: BoxFit.cover) : null,
            ),
            child: imgProvider == null 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: _colorTema),
                    Text('Tocar para agregar foto', style: TextStyle(color: _colorTema))
                  ],
                )
              : null,
          ),
        ),
        
        // BOTÓN DE BORRAR (SOLO SI HAY FOTO)
        if (hayFoto)
          Positioned(
            top: 5, right: 5,
            child: GestureDetector(
              onTap: _borrarFoto,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(String titulo, List<Widget> hijos) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(_anchoPantalla < 480 ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: _colorTema)),
            const Divider(),
            ...hijos
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, dynamic icon) {
    // Etiquetas, ejemplos y errores pueden ocupar varias líneas en celulares
    return InputDecoration(
      label: Text(label, maxLines: 2, softWrap: true, overflow: TextOverflow.ellipsis),
      labelStyle: TextStyle(fontSize: _anchoPantalla < 400 ? 12.5 : 13),
      hintMaxLines: 3,
      errorMaxLines: 3,
      helperMaxLines: 2,
      prefixIcon: icon != null 
          ? IconoAdaptativo.prefijo(icon, size: 18, color: const Color(0xFF1E3A8A))
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    );
  }
}