import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/proveedores/cruces_proveedor.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';

class PantallaFormularioCruce extends StatefulWidget {
  final CruceModelo? cruceEditar; // Puede recibir un cruce para editar
  const PantallaFormularioCruce({Key? key, this.cruceEditar}) : super(key: key);

  @override
  State<PantallaFormularioCruce> createState() => _PantallaFormularioCruceState();
}

class _PantallaFormularioCruceState extends State<PantallaFormularioCruce> {
  final _formKey = GlobalKey<FormState>();
  final Color _colorTema = const Color(0xFF059669);

  // Controladores
  final _ctrlCantidad = TextEditingController();
  final _ctrlMuertos = TextEditingController(text: '0'); // Nuevo campo para bajas
  final _ctrlMarca = TextEditingController();
  final _ctrlNotas = TextEditingController();
  final _ctrlFecha = TextEditingController();

  // Variables
  String? _padreId;
  String? _madreId;
  String? _faseLunar;
  String _pataMarca = 'Derecha';
  DateTime _fechaSeleccionada = DateTime.now();
  File? _imagenNueva;
  String? _fotoActualBase64; // Para mostrar la foto vieja al editar
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
    _faseLunar = c.faseLunar;
    _ctrlCantidad.text = c.cantidadPollitos.toString();
    _ctrlMuertos.text = c.pollitosMuertos.toString(); // Cargar muertos
    _pataMarca = c.pataMarca;
    _ctrlMarca.text = c.detalleMarca;
    _ctrlNotas.text = c.notas ?? '';
    _fotoActualBase64 = c.fotoPath;
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25, maxWidth: 800);
    if (picked != null) setState(() => _imagenNueva = File(picked.path));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_padreId == null || _madreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona Padre y Madre')));
      return;
    }

    // Validar lógica de números
    int total = int.tryParse(_ctrlCantidad.text) ?? 0;
    int muertos = int.tryParse(_ctrlMuertos.text) ?? 0;
    if (muertos > total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pueden haber más muertos que nacidos')));
      return;
    }

    setState(() => _guardando = true);

    try {
      final gallosProv = context.read<GallosProveedor>();
      
      // Intentamos buscar los nombres actualizados, si no existen (fueron borrados), usamos los viejos si es edición
      String nombreP = 'Desconocido';
      String nombreM = 'Desconocida';
      
      try {
        final padre = gallosProv.gallos.firstWhere((g) => g.id == _padreId);
        nombreP = padre.nombre;
      } catch (_) { if(_esEdicion) nombreP = widget.cruceEditar!.nombrePadre; }

      try {
        final madre = gallosProv.gallos.firstWhere((g) => g.id == _madreId);
        nombreM = madre.nombre;
      } catch (_) { if(_esEdicion) nombreM = widget.cruceEditar!.nombreMadre; }

      final user = FirebaseAuth.instance.currentUser;

      // Manejo de la foto
      String? fotoFinal;
      if (_imagenNueva != null) {
        final bytes = await _imagenNueva!.readAsBytes();
        fotoFinal = 'base64,${base64Encode(bytes)}';
      } else {
        fotoFinal = _fotoActualBase64;
      }

      final cruceModelo = CruceModelo(
        id: _esEdicion ? widget.cruceEditar!.id : const Uuid().v4(),
        userId: _esEdicion ? widget.cruceEditar!.userId : user!.uid,
        padreId: _padreId!,
        nombrePadre: nombreP,
        madreId: _madreId!,
        nombreMadre: nombreM,
        fechaCruce: _fechaSeleccionada,
        faseLunar: _faseLunar ?? 'Creciente',
        cantidadPollitos: total,
        pollitosMuertos: muertos,
        pollitosVivos: total - muertos, // 🔥 CÁLCULO AUTOMÁTICO
        pataMarca: _pataMarca,
        detalleMarca: _ctrlMarca.text.trim(),
        fotoPath: fotoFinal,
        notas: _ctrlNotas.text.trim(),
      );

      if (_esEdicion) {
        await context.read<CrucesProveedor>().actualizarCruce(cruceModelo);
      } else {
        await context.read<CrucesProveedor>().agregarCruce(cruceModelo);
      }
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listas para los dropdowns
    final gallos = context.watch<GallosProveedor>().gallos;
    final padres = gallos.where((g) => g.sexo == 'Macho').toList();
    final madres = gallos.where((g) => g.sexo == 'Hembra').toList();

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
                  // 1. PADRES
                  _buildCard('🧬 Los Padres', [
                    DropdownButtonFormField<String>(
                      decoration: _inputDeco('Padre (Macho)', FontAwesomeIcons.mars),
                      value: _padreId,
                      // Si editamos y el padre fue borrado, no aparecerá en la lista, hay que manejar eso visualmente
                      items: padres.map((g) => DropdownMenuItem(value: g.id, child: Text(g.nombre))).toList(),
                      onChanged: (v) => setState(() => _padreId = v),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      decoration: _inputDeco('Madre (Hembra)', FontAwesomeIcons.venus),
                      value: _madreId,
                      items: madres.map((g) => DropdownMenuItem(value: g.id, child: Text(g.nombre))).toList(),
                      onChanged: (v) => setState(() => _madreId = v),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // 2. ESTADÍSTICAS DE VIDA (MODIFICADO)
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
                          value: _faseLunar,
                          items: ['Creciente', 'Menguante', 'Llena', 'Nueva'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                          onChanged: (v) => setState(() => _faseLunar = v),
                          decoration: _inputDeco('Luna', FontAwesomeIcons.moon),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 15),
                    
                    // 🔥 AQUÍ ESTÁ EL CAMBIO IMPORTANTE: TOTAL vs MUERTOS
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ctrlCantidad,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco('Total Huevos', FontAwesomeIcons.egg),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: _ctrlMuertos,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            decoration: _inputDeco('Bajas/Muertos', FontAwesomeIcons.skull),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text('El sistema calculará automáticamente los vivos.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),

                  const SizedBox(height: 20),

                  // 3. IDENTIFICACIÓN
                  _buildCard('🏷️ Identificación', [
                     DropdownButtonFormField<String>(
                        value: _pataMarca,
                        items: ['Izquierda', 'Derecha'].map((l) => DropdownMenuItem(value: l, child: Text('Pata $l'))).toList(),
                        onChanged: (v) => setState(() => _pataMarca = v!),
                        // 🔥 RECOMENDACIÓN: Usamos 'locationDot' (Pin de ubicación)
                        // Significa: "¿En qué lugar está la marca?"
                        decoration: _inputDeco('Ubicación', FontAwesomeIcons.locationDot),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _ctrlMarca,
                        maxLines: 2,
                        decoration: _inputDeco('Detalle Marca (Ej: Argolla roja #2)', FontAwesomeIcons.tag),
                      ),
                  ]),

                  const SizedBox(height: 20),

                  // 4. NOTAS
                  _buildCard('📝 Notas', [
                     TextFormField(
                        controller: _ctrlNotas,
                        maxLines: 3,
                        decoration: _inputDeco('Observaciones adicionales', Icons.note),
                      ),
                  ]),

                  const SizedBox(height: 20),

                  // 5. FOTO
                  GestureDetector(
                    onTap: _seleccionarFoto,
                    child: _buildFotoPreview(),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _colorTema),
                      onPressed: _guardar,
                      child: Text(_esEdicion ? 'ACTUALIZAR DATOS' : 'GUARDAR CRUCE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFotoPreview() {
    ImageProvider? imgProvider;
    if (_imagenNueva != null) {
      imgProvider = FileImage(_imagenNueva!);
    } else if (_fotoActualBase64 != null && _fotoActualBase64!.startsWith('base64')) {
      imgProvider = MemoryImage(base64Decode(_fotoActualBase64!.split(',').last));
    }

    return Container(
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
              Text('Foto de la camada', style: TextStyle(color: _colorTema))
            ],
          )
        : null,
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

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: _colorTema),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    );
  }
}