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

class PantallaFormularioGallo extends StatefulWidget {
  final Gallo? galloEditar;
  const PantallaFormularioGallo({Key? key, this.galloEditar}) : super(key: key);

  @override
  State<PantallaFormularioGallo> createState() => _PantallaFormularioGalloState();
}

class _PantallaFormularioGalloState extends State<PantallaFormularioGallo> with TickerProviderStateMixin {
  final _claveFormulario = GlobalKey<FormState>();
  late TabController _tabController;

  // ================== CONTROLADORES DE TEXTO ==================
  // 1. Datos Básicos
  late TextEditingController _ctrlPlaca;
  late TextEditingController _ctrlNombre;
  late TextEditingController _ctrlLinea;
  late TextEditingController _ctrlColor;
  late TextEditingController _ctrlFase;
  late TextEditingController _ctrlFecha;
  
  // 2. Gestión y Salud
  late TextEditingController _ctrlPesoActual;
  late TextEditingController _ctrlPesoCombate;
  late TextEditingController _ctrlJaula;
  late TextEditingController _ctrlCriadero;
  
  // 3. Genealogía Visual (Nombres texto)
  late TextEditingController _ctrlNombrePadre;
  late TextEditingController _ctrlNombreMadre;
  late TextEditingController _ctrlAbueloPaterno;
  late TextEditingController _ctrlAbuelaPaterna;
  late TextEditingController _ctrlAbueloMaterno;
  late TextEditingController _ctrlAbuelaMaterna;

  // 4. Finanzas y Extras
  late TextEditingController _ctrlCosto;
  late TextEditingController _ctrlVenta;
  late TextEditingController _ctrlVideo;
  late TextEditingController _ctrlNotas;

  // Controladores auxiliares para listas
  final TextEditingController _ctrlNuevaVacuna = TextEditingController();
  final TextEditingController _ctrlNuevaPelea = TextEditingController();

  // ================== VARIABLES DE ESTADO ==================
  String? _sexo;
  String? _estado;
  String? _etapaVida;
  String? _tipoCresta;
  DateTime? _fechaNacimiento;
  String? _padreId;
  String? _madreId;
  String? _rutaFoto;

  // Listas dinámicas
  List<String> _listaVacunas = [];
  List<String> _listaPeleas = [];

  final ImagePicker _picker = ImagePicker();
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _inicializarControladores();
    
    if (widget.galloEditar != null) {
      _cargarDatosExistentes(widget.galloEditar!);
    } else {
      _valoresPorDefecto();
    }
  }

  void _inicializarControladores() {
    _ctrlPlaca = TextEditingController();
    _ctrlNombre = TextEditingController();
    _ctrlLinea = TextEditingController();
    _ctrlColor = TextEditingController();
    _ctrlFase = TextEditingController();
    _ctrlFecha = TextEditingController();
    
    _ctrlPesoActual = TextEditingController();
    _ctrlPesoCombate = TextEditingController();
    _ctrlJaula = TextEditingController();
    _ctrlCriadero = TextEditingController();

    _ctrlNombrePadre = TextEditingController();
    _ctrlNombreMadre = TextEditingController();
    _ctrlAbueloPaterno = TextEditingController();
    _ctrlAbuelaPaterna = TextEditingController();
    _ctrlAbueloMaterno = TextEditingController();
    _ctrlAbuelaMaterna = TextEditingController();

    _ctrlCosto = TextEditingController();
    _ctrlVenta = TextEditingController();
    _ctrlVideo = TextEditingController();
    _ctrlNotas = TextEditingController();
  }

  void _cargarDatosExistentes(Gallo g) {
    _esEdicion = true;
    _ctrlPlaca.text = g.placa;
    _ctrlNombre.text = g.nombre;
    _ctrlLinea.text = g.lineaGenetica;
    _ctrlColor.text = g.colorPluma;
    _ctrlFase.text = g.faseLunar;
    _ctrlFecha.text = _formatearFecha(g.fechaNacimiento);
    
    _ctrlPesoActual.text = g.pesoActual?.toString() ?? '';
    _ctrlPesoCombate.text = g.pesoCombate?.toString() ?? '';
    _ctrlJaula.text = g.jaula ?? '';
    _ctrlCriadero.text = g.criaderoOrigen;

    // Genealogía Visual
    _ctrlNombrePadre.text = g.nombrePadre ?? '';
    _ctrlNombreMadre.text = g.nombreMadre ?? '';
    _ctrlAbueloPaterno.text = g.nombreAbueloPaterno ?? '';
    _ctrlAbuelaPaterna.text = g.nombreAbuelaPaterna ?? '';
    _ctrlAbueloMaterno.text = g.nombreAbueloMaterno ?? '';
    _ctrlAbuelaMaterna.text = g.nombreAbuelaMaterna ?? '';

    // Finanzas
    _ctrlCosto.text = g.costoAdquisicion?.toString() ?? '';
    _ctrlVenta.text = g.precioVenta?.toString() ?? '';
    _ctrlVideo.text = g.videoUrl ?? '';
    _ctrlNotas.text = g.notas ?? '';

    // Listas
    _listaVacunas = List.from(g.vacunas);
    _listaPeleas = List.from(g.peleas);

    // Dropdowns y Variables
    _sexo = g.sexo;
    _estado = g.estado;
    _etapaVida = g.etapaVida;
    _tipoCresta = g.tipoCresta;
    _fechaNacimiento = g.fechaNacimiento;
    _padreId = g.padreId;
    _madreId = g.madreId;
    _rutaFoto = g.fotoPath;
  }

  void _valoresPorDefecto() {
    _sexo = 'Macho';
    _estado = 'Activo';
    _etapaVida = 'Cría';
    _tipoCresta = 'Sierra';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ctrlPlaca.dispose(); _ctrlNombre.dispose(); _ctrlLinea.dispose();
    _ctrlColor.dispose(); _ctrlFase.dispose(); _ctrlFecha.dispose();
    _ctrlPesoActual.dispose(); _ctrlPesoCombate.dispose();
    _ctrlJaula.dispose(); _ctrlCriadero.dispose();
    _ctrlNombrePadre.dispose(); _ctrlNombreMadre.dispose();
    _ctrlAbueloPaterno.dispose(); _ctrlAbuelaPaterna.dispose();
    _ctrlAbueloMaterno.dispose(); _ctrlAbuelaMaterna.dispose();
    _ctrlCosto.dispose(); _ctrlVenta.dispose(); _ctrlVideo.dispose(); _ctrlNotas.dispose();
    _ctrlNuevaVacuna.dispose(); _ctrlNuevaPelea.dispose();
    super.dispose();
  }

  // ================== LÓGICA DE NEGOCIO ==================

  String _formatearFecha(DateTime fecha) => '${fecha.day}/${fecha.month}/${fecha.year}';

  Future<void> _seleccionarImagen() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _rutaFoto = image.path);
  }

  /// Función para limpiar números (quita puntos de miles y arregla decimales)
  /// Entra: "5.000.000" -> Sale: 5000000.0
  /// Entra: "600,50" -> Sale: 600.5
  /// Función INTELIGENTE para limpiar números
  /// [esDinero] = true  -> Borra puntos de miles (1.000 -> 1000)
  /// [esDinero] = false -> Respeta el punto como decimal (2.5 -> 2.5)
  double? _limpiarNumero(String valor, {bool esDinero = false}) {
    if (valor.trim().isEmpty) return null;
    String limpio = valor.trim();
    
    if (esDinero) {
      // Lógica para Precios (Colombia): Quitamos puntos de mil
      limpio = limpio.replaceAll('.', '');
      // Cambiamos coma por punto por si acaso
      limpio = limpio.replaceAll(',', '.');
    } else {
      // Lógica para Pesos: Solo aseguramos que la coma sea punto
      limpio = limpio.replaceAll(',', '.');
      // ¡NO quitamos los puntos aquí!
    }
    
    return double.tryParse(limpio);
  }
  
  Future<void> _guardar() async {
    if (_fechaNacimiento == null) {
      _mostrarSnack('Selecciona fecha de nacimiento', Colors.red);
      return;
    }
    if (!_claveFormulario.currentState!.validate()) return;

    try {
      final proveedor = context.read<GallosProveedor>();
      
      // Manejo de imagen local (copiar a carpeta segura)
      String? rutaFinal = _rutaFoto;
      if (_rutaFoto != null && _rutaFoto != widget.galloEditar?.fotoPath) {
        final directorio = await getApplicationSupportDirectory();
        final carpeta = Directory(path.join(directorio.path, 'imagenes_gallos'));
        if (!await carpeta.exists()) await carpeta.create(recursive: true);
        final nuevoNombre = '${const Uuid().v4()}${path.extension(_rutaFoto!)}';
        final rutaDestino = path.join(carpeta.path, nuevoNombre);
        await File(_rutaFoto!).copy(rutaDestino);
        rutaFinal = rutaDestino;
      }

      final gallo = Gallo(
        id: _esEdicion ? widget.galloEditar!.id : const Uuid().v4(),
        userId: _esEdicion ? widget.galloEditar!.userId : null,
        placa: _ctrlPlaca.text.trim(),
        nombre: _ctrlNombre.text.trim(),
        sexo: _sexo!,
        fechaNacimiento: _fechaNacimiento!,
        lineaGenetica: _ctrlLinea.text.trim(),
        colorPluma: _ctrlColor.text.trim(),
        faseLunar: _ctrlFase.text.trim(),
        tipoCresta: _tipoCresta ?? 'Sierra',
        estado: _estado!,
        etapaVida: _etapaVida ?? 'Cría',
        criaderoOrigen: _ctrlCriadero.text.trim().isEmpty ? 'Propio' : _ctrlCriadero.text.trim(),
        jaula: _ctrlJaula.text.isEmpty ? null : _ctrlJaula.text.trim(),
        
        // === AQUÍ USAMOS LA LIMPIEZA ===
        
        // PESOS (esDinero: false -> Respeta el 2.8)
        pesoActual: _limpiarNumero(_ctrlPesoActual.text, esDinero: false),
        pesoCombate: _limpiarNumero(_ctrlPesoCombate.text, esDinero: false),
        
        // DINERO (esDinero: true -> Convierte 5.000.000 en 5000000)
        costoAdquisicion: _limpiarNumero(_ctrlCosto.text, esDinero: true),
        precioVenta: _limpiarNumero(_ctrlVenta.text, esDinero: true),
        // ===============================

        notas: _ctrlNotas.text.isEmpty ? null : _ctrlNotas.text.trim(),
        fotoPath: rutaFinal,
        videoUrl: _ctrlVideo.text.isEmpty ? null : _ctrlVideo.text.trim(),
        // Genealogía
        padreId: _padreId,
        madreId: _madreId,
        nombrePadre: _ctrlNombrePadre.text.isEmpty ? null : _ctrlNombrePadre.text,
        nombreMadre: _ctrlNombreMadre.text.isEmpty ? null : _ctrlNombreMadre.text,
        nombreAbueloPaterno: _ctrlAbueloPaterno.text.isEmpty ? null : _ctrlAbueloPaterno.text,
        nombreAbuelaPaterna: _ctrlAbuelaPaterna.text.isEmpty ? null : _ctrlAbuelaPaterna.text,
        nombreAbueloMaterno: _ctrlAbueloMaterno.text.isEmpty ? null : _ctrlAbueloMaterno.text,
        nombreAbuelaMaterna: _ctrlAbuelaMaterna.text.isEmpty ? null : _ctrlAbuelaMaterna.text,
        // Listas
        vacunas: _listaVacunas,
        peleas: _listaPeleas,
      );

      if (_esEdicion) {
        await proveedor.actualizarGallo(gallo);
        _mostrarSnack('Gallo actualizado correctamente', Colors.green);
      } else {
        await proveedor.crearGallo(gallo);
        _mostrarSnack('Gallo creado correctamente', Colors.green);
      }
      if (mounted) Navigator.pop(context);

    } catch (e) {
      _mostrarSnack('Error: $e', Colors.red);
    }
  }

  void _mostrarSnack(String msj, Color color) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj), backgroundColor: color));
  }

  // ================== INTERFAZ GRÁFICA (UI) ==================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Gallo' : 'Nuevo Gallo'),
        backgroundColor: const Color(0xFF1E3A8A),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(FontAwesomeIcons.kiwiBird), text: 'Datos'),
            Tab(icon: Icon(FontAwesomeIcons.sitemap), text: 'Genealogía'),
            Tab(icon: Icon(FontAwesomeIcons.heartPulse), text: 'Gestión'),
            Tab(icon: Icon(FontAwesomeIcons.sackDollar), text: 'Finanzas'),
          ],
        ),
      ),
      body: Form(
        key: _claveFormulario,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabDatos(),      // Pestaña 1
            _buildTabGenealogia(), // Pestaña 2
            _buildTabGestion(),    // Pestaña 3
            _buildTabFinanzas(),   // Pestaña 4
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _guardar,
        backgroundColor: const Color(0xFFD4AF37),
        icon: const Icon(Icons.save),
        label: const Text('GUARDAR'),
      ),
    );
  }

  // === PESTAÑA 1: DATOS BÁSICOS ===
  Widget _buildTabDatos() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFotoPicker(),
        const SizedBox(height: 20),
        _buildCard('Identificación', [
          Row(children: [
            Expanded(child: _buildInput(_ctrlPlaca, 'Placa / Anillo', icon: FontAwesomeIcons.tag, validacion: true)),
            const SizedBox(width: 15),
            Expanded(child: _buildInput(_ctrlNombre, 'Nombre', icon: FontAwesomeIcons.signature, validacion: true)),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _buildDropdown('Sexo', ['Macho', 'Hembra'], _sexo, (v) => setState(() => _sexo = v))),
            const SizedBox(width: 15),
            Expanded(child: _buildInput(_ctrlFecha, 'Fec. Nacimiento', icon: FontAwesomeIcons.calendar, readOnly: true, onTap: _seleccionarFecha)),
          ]),
        ]),
        const SizedBox(height: 15),
        _buildCard('Genética y Físico', [
          Row(children: [
            Expanded(child: _buildInput(_ctrlLinea, 'Línea Genética', icon: FontAwesomeIcons.dna, validacion: true)),
            const SizedBox(width: 15),
            Expanded(child: _buildInput(_ctrlColor, 'Color Pluma', icon: FontAwesomeIcons.palette, validacion: true)),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _buildDropdown('Cresta', ['Sierra', 'Rosa', 'Pava', 'Boton', 'Simple'], _tipoCresta, (v) => setState(() => _tipoCresta = v))),
            const SizedBox(width: 15),
            Expanded(child: _buildInput(_ctrlFase, 'Fase Lunar', icon: FontAwesomeIcons.moon, validacion: true)),
          ]),
        ]),
        const SizedBox(height: 60), // Espacio para el botón flotante
      ],
    );
  }

  // === PESTAÑA 2: GENEALOGÍA ===
  Widget _buildTabGenealogia() {
    final gallos = context.read<GallosProveedor>().gallos;
    final padres = gallos.where((g) => g.sexo == 'Macho' && g.id != widget.galloEditar?.id).toList();
    final madres = gallos.where((g) => g.sexo == 'Hembra' && g.id != widget.galloEditar?.id).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard('Padres en el Sistema (IDs)', [
          const Text('Vincular con gallos ya registrados:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _padreId,
            items: padres.map((g) => DropdownMenuItem(value: g.id, child: Text('${g.nombre} (${g.placa})'))).toList(),
            onChanged: (v) => setState(() => _padreId = v),
            decoration: _inputDeco('Padre (Macho Registrado)'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _madreId,
            items: madres.map((g) => DropdownMenuItem(value: g.id, child: Text('${g.nombre} (${g.placa})'))).toList(),
            onChanged: (v) => setState(() => _madreId = v),
            decoration: _inputDeco('Madre (Hembra Registrada)'),
          ),
        ]),
        const SizedBox(height: 20),
        _buildCard('Árbol Genealógico Visual (PDF)', [
          const Text('Nombres para mostrar en el PDF (si no están registrados):', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          _buildInput(_ctrlNombrePadre, 'Nombre del Padre'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildInput(_ctrlAbueloPaterno, 'Abuelo Paterno')),
            const SizedBox(width: 10),
            Expanded(child: _buildInput(_ctrlAbuelaPaterna, 'Abuela Paterna')),
          ]),
          const Divider(height: 30),
          _buildInput(_ctrlNombreMadre, 'Nombre de la Madre'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildInput(_ctrlAbueloMaterno, 'Abuelo Materno')),
            const SizedBox(width: 10),
            Expanded(child: _buildInput(_ctrlAbuelaMaterna, 'Abuela Materna')),
          ]),
        ]),
        const SizedBox(height: 60),
      ],
    );
  }

  // === PESTAÑA 3: GESTIÓN Y SALUD ===
  Widget _buildTabGestion() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard('Estado Actual', [
          Row(children: [
            Expanded(child: _buildDropdown('Estado', ['Activo', 'Vendido', 'Baja', 'Retirado'], _estado, (v) => setState(() => _estado = v))),
            const SizedBox(width: 15),
            Expanded(child: _buildDropdown('Etapa', ['Cría', 'Levante', 'Muda', 'Postura', 'Padrote'], _etapaVida, (v) => setState(() => _etapaVida = v))),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            // Peso Actual
            Expanded(child: _buildInput(_ctrlPesoActual, 'Peso Actual (Kg)', isNumber: true, icon: FontAwesomeIcons.weightScale)),
            const SizedBox(width: 15),
            // Peso Combate (¡NUEVO!)
            Expanded(child: _buildInput(_ctrlPesoCombate, 'Peso Pactado/Combate', isNumber: true, icon: FontAwesomeIcons.dumbbell)),
          ]),
          const SizedBox(height: 15),
          _buildInput(_ctrlJaula, 'Jaula / Ubicación'),
          
        ]),
        const SizedBox(height: 20),
        _buildCard('Historial de Vacunas', [
          _buildListaDinamica(_ctrlNuevaVacuna, _listaVacunas, 'Agregar Vacuna (Ej: Newcastle)'),
        ]),
        const SizedBox(height: 20),
        _buildCard('Récord de Peleas', [
          _buildListaDinamica(_ctrlNuevaPelea, _listaPeleas, 'Agregar Pelea (Ej: Ganó en 12min)'),
        ]),
        const SizedBox(height: 60),
      ],
    );
  }

  // === PESTAÑA 4: FINANZAS Y EXTRA ===
  Widget _buildTabFinanzas() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard('Rentabilidad', [
          Row(children: [
            Expanded(child: _buildInput(_ctrlCosto, 'Costo Adquisición', isNumber: true, icon: Icons.money_off)),
            const SizedBox(width: 15),
            Expanded(child: _buildInput(_ctrlVenta, 'Precio Venta', isNumber: true, icon: Icons.attach_money)),
          ]),
          const SizedBox(height: 15),
          _buildInput(_ctrlCriadero, 'Criadero de Origen'),
        ]),
        const SizedBox(height: 20),
        _buildCard('Multimedia y Notas', [
          _buildInput(_ctrlVideo, 'Link de Video (YouTube/Drive)', icon: Icons.video_library),
          const SizedBox(height: 15),
          _buildInput(_ctrlNotas, 'Notas / Observaciones', maxLines: 3),
        ]),
        const SizedBox(height: 60),
      ],
    );
  }

  // ================== WIDGETS AUXILIARES ==================

  Widget _buildFotoPicker() {
    return Center(
      child: GestureDetector(
        onTap: _seleccionarImagen,
        child: Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
            image: _rutaFoto != null ? DecorationImage(image: FileImage(File(_rutaFoto!)), fit: BoxFit.cover) : null,
          ),
          child: _rutaFoto == null ? const Icon(Icons.add_a_photo, size: 50, color: Color(0xFF1E3A8A)) : null,
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
          const Divider(),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, {IconData? icon, bool isNumber = false, bool validacion = false, int maxLines = 1, bool readOnly = false, VoidCallback? onTap}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      decoration: _inputDeco(label, icon: icon),
      validator: validacion ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null : null,
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF1E3A8A)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? valor, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: valor,
      decoration: _inputDeco(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildListaDinamica(TextEditingController ctrl, List<String> lista, String hint) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: TextFormField(controller: ctrl, decoration: _inputDeco(hint))),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF1E3A8A)),
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() => lista.add(ctrl.text));
                ctrl.clear();
              }
            },
          )
        ]),
        Wrap(
          spacing: 8,
          children: lista.map((e) => Chip(
            label: Text(e),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => lista.remove(e)),
          )).toList(),
        )
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
        _ctrlFecha.text = _formatearFecha(picked);
      });
    }
  }
}
