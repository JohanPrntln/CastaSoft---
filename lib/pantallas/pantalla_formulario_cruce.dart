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
      final String nombreP = gallosProv.obtenerGalloPorId(_padreId!)?.nombre
          ?? (_esEdicion ? widget.cruceEditar!.nombrePadre : 'Desconocido');
      final String nombreM = gallosProv.obtenerGalloPorId(_madreId!)?.nombre
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
      final items = lista.map((g) => DropdownMenuItem(value: g.id, child: Text(g.nombre))).toList();
      if (idActual != null && !lista.any((g) => g.id == idActual)) {
        items.add(DropdownMenuItem(value: idActual, child: Text('${nombreGuardado ?? 'Desconocido'} (eliminado)')));
      }
      return items;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cruce' : 'Nuevo Cruce Genético'),
        backgroundColor: _colorTema,
      ),
      body: _guardando 
        ? Center(child: CircularProgressIndicator(color: _colorTema))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildCard('🧬 Los Padres', [
                    DropdownButtonFormField<String>(
                      key: ValueKey('padre-$_padreId'),
                      decoration: _inputDeco('Padre (Macho)', FontAwesomeIcons.mars),
                      initialValue: _padreId,
                      items: itemsProgenitor(padres, _padreId, widget.cruceEditar?.nombrePadre),
                      onChanged: (v) => setState(() => _padreId = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona el padre' : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      key: ValueKey('madre-$_madreId'),
                      decoration: _inputDeco('Madre (Hembra)', FontAwesomeIcons.venus),
                      initialValue: _madreId,
                      items: itemsProgenitor(madres, _madreId, widget.cruceEditar?.nombreMadre),
                      onChanged: (v) => setState(() => _madreId = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Selecciona la madre' : null,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildCard('🐣 Estadísticas de la Camada', [
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ctrlFecha,
                          readOnly: true,
                          decoration: _inputDeco('Fecha', FontAwesomeIcons.calendar),
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
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('luna-$_faseLunar'),
                          isExpanded: true,
                          initialValue: _faseLunar,
                          items: Gallo.opcionesFaseLunar(_faseLunar)
                              .map((l) => DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _faseLunar = v),
                          decoration: _inputDeco('Luna', FontAwesomeIcons.moon),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 15),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ctrlCantidad,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            decoration: _inputDeco('Total Huevos', FontAwesomeIcons.egg),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            onChanged: (v) => setState((){}),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: _ctrlMuertos,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            decoration: _inputDeco('Bajas/Muertos', FontAwesomeIcons.skull),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                            onChanged: (v) => setState((){}),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('Sexado (La suma no puede superar los vivos)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ctrlMachos,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                            decoration: _inputDeco('Machos', FontAwesomeIcons.mars),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: _ctrlHembras,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 3,
                            style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.bold),
                            decoration: _inputDeco('Hembras', FontAwesomeIcons.venus),
                          ),
                        ),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 20),

                  _buildCard('🏷️ Identificación Inclusiva', [
                      DropdownButtonFormField<String>(
                        key: ValueKey('marca-$_pataMarca'),
                        initialValue: _pataMarca,
                        isExpanded: true, // Para que los textos largos no se corten
                        items: _opcionesIdentificacion.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (v) => setState(() => _pataMarca = v!),
                        decoration: _inputDeco('Zona de Marca', FontAwesomeIcons.locationDot),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _ctrlMarca,
                        maxLines: 2,
                        maxLength: 60,
                        decoration: _inputDeco('Detalle (Ej: Argolla roja #2, Placa 55)', FontAwesomeIcons.tag),
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
        padding: const EdgeInsets.all(16),
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
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: icon != null 
          ? IconoAdaptativo.prefijo(icon, size: 18, color: const Color(0xFF1E3A8A))
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    );
  }
}