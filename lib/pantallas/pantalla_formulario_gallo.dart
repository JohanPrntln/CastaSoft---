import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; 
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/componentes/icono_adaptativo.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class PantallaFormularioGallo extends StatefulWidget {
  final Gallo? galloEditar;
  const PantallaFormularioGallo({super.key, this.galloEditar});

  @override
  State<PantallaFormularioGallo> createState() => _PantallaFormularioGalloState();
}

class _PantallaFormularioGalloState extends State<PantallaFormularioGallo> with TickerProviderStateMixin {
  final _claveFormulario = GlobalKey<FormState>();
  late TabController _tabController;

  // ================== CONTROLADORES ==================
  final TextEditingController _ctrlPlaca = TextEditingController();
  final TextEditingController _ctrlNombre = TextEditingController();
  final TextEditingController _ctrlLinea = TextEditingController();
  final TextEditingController _ctrlColor = TextEditingController();
  final TextEditingController _ctrlFase = TextEditingController();
  final TextEditingController _ctrlFecha = TextEditingController();
  
  final TextEditingController _ctrlPesoActual = TextEditingController();
  final TextEditingController _ctrlPesoCombate = TextEditingController();
  final TextEditingController _ctrlJaula = TextEditingController();
  final TextEditingController _ctrlCriadero = TextEditingController();
  
  final TextEditingController _ctrlNombrePadre = TextEditingController();
  final TextEditingController _ctrlNombreMadre = TextEditingController();
  final TextEditingController _ctrlAbueloPaterno = TextEditingController();
  final TextEditingController _ctrlAbuelaPaterna = TextEditingController();
  final TextEditingController _ctrlAbueloMaterno = TextEditingController();
  final TextEditingController _ctrlAbuelaMaterna = TextEditingController();

  final TextEditingController _ctrlCosto = TextEditingController();
  final TextEditingController _ctrlVenta = TextEditingController();
  final TextEditingController _ctrlVideo = TextEditingController();
  final TextEditingController _ctrlNotas = TextEditingController();

  final TextEditingController _ctrlNuevaVacuna = TextEditingController();
  final TextEditingController _ctrlNuevaPelea = TextEditingController();

  // ================== VARIABLES ==================
  String? _sexo;
  String? _estado;
  String? _etapaVida;
  String? _tipoCresta;
  DateTime? _fechaNacimiento;
  String? _padreId;
  String? _madreId;
  
  bool _esEdicion = false;
  XFile? _imagenNuevaSeleccionada; 
  Uint8List? _fotoActualBytes; // Foto guardada (ya decodificada y memoizada en el modelo)

  List<String> _listaVacunas = [];
  List<String> _listaPeleas = [];

  final ImagePicker _picker = ImagePicker();
  bool _estaGuardando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    if (widget.galloEditar != null) {
      _cargarDatosExistentes(widget.galloEditar!);
    } else {
      _valoresPorDefecto();
    }
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

    _ctrlNombrePadre.text = g.nombrePadre ?? '';
    _ctrlNombreMadre.text = g.nombreMadre ?? '';
    _ctrlAbueloPaterno.text = g.nombreAbueloPaterno ?? '';
    _ctrlAbuelaPaterna.text = g.nombreAbuelaPaterna ?? '';
    _ctrlAbueloMaterno.text = g.nombreAbueloMaterno ?? '';
    _ctrlAbuelaMaterna.text = g.nombreAbuelaMaterna ?? '';

    // CARGAR PRECIOS
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0);
    if (g.costoAdquisicion != null) {
      _ctrlCosto.text = currencyFormat.format(g.costoAdquisicion).trim();
    }
    if (g.precioVenta != null) {
      _ctrlVenta.text = currencyFormat.format(g.precioVenta).trim();
    }

    _ctrlVideo.text = g.videoUrl ?? '';
    _ctrlNotas.text = g.notas ?? '';

    _listaVacunas = List.from(g.vacunas);
    _listaPeleas = List.from(g.peleas);

    _sexo = g.sexo;
    _estado = g.estado;
    _etapaVida = g.etapaVida;
    _tipoCresta = g.tipoCresta;
    _fechaNacimiento = g.fechaNacimiento;
    _padreId = g.padreId;
    _madreId = g.madreId;
    _fotoActualBytes = g.fotoBytes;
  }

  void _valoresPorDefecto() {
    _sexo = 'Macho';
    _estado = Gallo.estadosValidos.first;
    _etapaVida = Gallo.etapasVida.first;
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

  String _formatearFecha(DateTime fecha) => '${fecha.day}/${fecha.month}/${fecha.year}';

  Future<void> _seleccionarImagen() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30, 
      maxWidth: 800,    
    );
    if (image != null) {
      // Guardamos el XFile directamente sin convertirlo
      setState(() => _imagenNuevaSeleccionada = image); 
    }
}

  double? _limpiarNumero(String valor, {bool esDinero = false}) {
    if (valor.trim().isEmpty) return null;
    String limpio = valor.trim();
    if (esDinero) {
      limpio = limpio.replaceAll('.', '').replaceAll('\$', '').replaceAll(' ', '');
      limpio = limpio.replaceAll(',', '.');
    } else {
      limpio = limpio.replaceAll(',', '.');
    }
    return double.tryParse(limpio);
  }
  
  Future<void> _guardar() async {
    if (_fechaNacimiento == null) {
      _mostrarSnack('Selecciona fecha de nacimiento', Colors.red);
      return;
    }
    if (!_claveFormulario.currentState!.validate()) return;

    // Se capturan ANTES de cualquier await (contexto asíncrono seguro)
    final proveedor = context.read<GallosProveedor>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _estaGuardando = true);

    try {
      
      String? fotoFinalString;
      if (_imagenNuevaSeleccionada != null) {
        final bytes = await _imagenNuevaSeleccionada!.readAsBytes();
        fotoFinalString = 'base64,${base64Encode(bytes)}';
      } else {
        fotoFinalString = widget.galloEditar?.fotoPath;
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
        
        pesoActual: _limpiarNumero(_ctrlPesoActual.text, esDinero: false),
        pesoCombate: _limpiarNumero(_ctrlPesoCombate.text, esDinero: false),
        
        costoAdquisicion: _limpiarNumero(_ctrlCosto.text, esDinero: true),
        precioVenta: _limpiarNumero(_ctrlVenta.text, esDinero: true),
        
        notas: _ctrlNotas.text.isEmpty ? null : _ctrlNotas.text.trim(),
        fotoPath: fotoFinalString,
        videoUrl: _ctrlVideo.text.isEmpty ? null : _ctrlVideo.text.trim(),
        
        padreId: _padreId,
        madreId: _madreId,
        nombrePadre: _ctrlNombrePadre.text.isEmpty ? null : _ctrlNombrePadre.text,
        nombreMadre: _ctrlNombreMadre.text.isEmpty ? null : _ctrlNombreMadre.text,
        nombreAbueloPaterno: _ctrlAbueloPaterno.text.isEmpty ? null : _ctrlAbueloPaterno.text,
        nombreAbuelaPaterna: _ctrlAbuelaPaterna.text.isEmpty ? null : _ctrlAbuelaPaterna.text,
        nombreAbueloMaterno: _ctrlAbueloMaterno.text.isEmpty ? null : _ctrlAbueloMaterno.text,
        nombreAbuelaMaterna: _ctrlAbuelaMaterna.text.isEmpty ? null : _ctrlAbuelaMaterna.text,
        
        vacunas: _listaVacunas,
        peleas: _listaPeleas,
      );

      // Sin red, el proveedor responde en <= 2.5 s con `confirmado == false`:
      // el dato ya está en la caché local y Firestore lo sincronizará solo.
      final bool confirmado = _esEdicion
          ? await proveedor.actualizarGallo(gallo)
          : await proveedor.crearGallo(gallo);

      final accion = _esEdicion ? 'actualizado' : 'creado';
      messenger.showSnackBar(SnackBar(
        content: Text(confirmado
            ? 'Gallo $accion correctamente'
            : 'Gallo $accion sin conexión: se sincronizará al volver el internet'),
        backgroundColor: confirmado ? Colors.green : Colors.orange.shade800,
      ));
      if (mounted) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _estaGuardando = false);
    }
  }

  void _mostrarSnack(String msj, Color color) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj), backgroundColor: color));
  }

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
          isScrollable: true,
          tabs: const [
            Tab(icon: FaIcon(FontAwesomeIcons.kiwiBird), text: 'Datos'),
            Tab(icon: FaIcon(FontAwesomeIcons.sitemap), text: 'Genealogía'),
            Tab(icon: FaIcon(FontAwesomeIcons.heartPulse), text: 'Gestión'),
            Tab(icon: FaIcon(FontAwesomeIcons.sackDollar), text: 'Finanzas'),
          ],
        ),
      ),
      body: _estaGuardando 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : Form(
              key: _claveFormulario,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabDatos(),      
                  _buildTabGenealogia(), 
                  _buildTabGestion(),    
                  _buildTabFinanzas(),   
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _estaGuardando ? null : _guardar,
        backgroundColor: const Color(0xFFD4AF37),
        icon: const Icon(Icons.save),
        label: const Text('GUARDAR'),
      ),
    );
  }

  Widget _buildFotoPicker() {
    ImageProvider? imagenMostrar;
    if (_imagenNuevaSeleccionada != null) {
      // 🔥 EL TRUCO SE MANTIENE
      imagenMostrar = kIsWeb 
          ? NetworkImage(_imagenNuevaSeleccionada!.path) as ImageProvider 
          // Reconstruimos el File solo para el renderizado nativo
          : FileImage(File(_imagenNuevaSeleccionada!.path)); 
    } else if (_fotoActualBytes != null) {
      imagenMostrar = MemoryImage(_fotoActualBytes!);
    }

    return Center(
      child: GestureDetector(
        onTap: _seleccionarImagen,
        child: Container(
          width: 150, height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
            image: imagenMostrar != null 
                ? DecorationImage(image: imagenMostrar, fit: BoxFit.cover) 
                : null,
          ),
          child: imagenMostrar == null 
              ? const Icon(Icons.add_a_photo, size: 50, color: Color(0xFF1E3A8A)) 
              : null,
        ),
      ),
    );
  }

  Widget _buildResponsiveDualInput(Widget input1, Widget input2) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 350) { 
          return Column(
            children: [
              input1,
              const SizedBox(height: 15),
              input2,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: input1),
              const SizedBox(width: 15),
              Expanded(child: input2),
            ],
          );
        }
      },
    );
  }

  // PESTAÑA 1
  Widget _buildTabDatos() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFotoPicker(),
        const SizedBox(height: 20),
        _buildCard('Identificación', [
          _buildResponsiveDualInput(
            _buildInput(_ctrlPlaca, 'Placa / Anillo', icon: FontAwesomeIcons.tag, validacion: true),
            _buildInput(_ctrlNombre, 'Nombre', icon: FontAwesomeIcons.signature, validacion: true)
          ),
          const SizedBox(height: 15),
          _buildResponsiveDualInput(
            _buildDropdown('Sexo', ['Macho', 'Hembra'], _sexo, (v) => setState(() => _sexo = v)),
            _buildInput(_ctrlFecha, 'Fec. Nacimiento', icon: FontAwesomeIcons.calendar, readOnly: true, onTap: _seleccionarFecha)
          ),
        ]),
        const SizedBox(height: 15),
        _buildCard('Genética y Físico', [
          _buildResponsiveDualInput(
            _buildInput(_ctrlLinea, 'Línea Genética', icon: FontAwesomeIcons.dna, validacion: true),
            _buildInput(_ctrlColor, 'Color Pluma', icon: FontAwesomeIcons.palette, validacion: true)
          ),
          const SizedBox(height: 15),
          _buildResponsiveDualInput(
            _buildDropdown('Cresta', ['Sierra', 'Rosa', 'Pava', 'Boton', 'Simple'], _tipoCresta, (v) => setState(() => _tipoCresta = v)),
            _buildInput(_ctrlFase, 'Fase Lunar', icon: FontAwesomeIcons.moon, validacion: true)
          ),
        ]),
        const SizedBox(height: 60), 
      ],
    );
  }

  // PESTAÑA 2
  Widget _buildTabGenealogia() {
    final gallos = context.watch<GallosProveedor>().gallos; 
    final padres = gallos.where((g) => g.sexo == 'Macho' && g.id != widget.galloEditar?.id).toList();
    final madres = gallos.where((g) => g.sexo == 'Hembra' && g.id != widget.galloEditar?.id).toList();

    // `initialValue` solo se lee al crear el FormField. Para conservar la
    // reactividad (p. ej. si la lista de gallos llega después del primer
    // frame), la Key depende del valor visible y fuerza a recrear el campo.
    // Si el ancestro fue eliminado, se muestra vacío pero se conserva el
    // `_padreId`/`_madreId` y sus nombres en texto (RN-03).
    final String? padreVisible = padres.any((g) => g.id == _padreId) ? _padreId : null;
    final String? madreVisible = madres.any((g) => g.id == _madreId) ? _madreId : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard('Padres en el Sistema', [
          DropdownButtonFormField<String>(
            key: ValueKey('padre-$padreVisible'),
            isExpanded: true,
            initialValue: padreVisible,
            items: padres.map((g) => DropdownMenuItem(value: g.id, child: Text('${g.nombre} (${g.placa})', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              setState(() {
                _padreId = v;
                // 🔥 MAGIA: Auto-llenado en cascada para la rama paterna
                if (v != null) {
                  final padreSeleccionado = padres.firstWhere((g) => g.id == v);
                  _ctrlNombrePadre.text = padreSeleccionado.nombre;
                  _ctrlAbueloPaterno.text = padreSeleccionado.nombrePadre ?? '';
                  _ctrlAbuelaPaterna.text = padreSeleccionado.nombreMadre ?? '';
                }
              });
            },
            decoration: _inputDeco('Padre (Macho)'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('madre-$madreVisible'),
            isExpanded: true,
            initialValue: madreVisible,
            items: madres.map((g) => DropdownMenuItem(value: g.id, child: Text('${g.nombre} (${g.placa})', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              setState(() {
                _madreId = v;
                // 🔥 MAGIA: Auto-llenado en cascada para la rama materna
                if (v != null) {
                  final madreSeleccionada = madres.firstWhere((g) => g.id == v);
                  _ctrlNombreMadre.text = madreSeleccionada.nombre;
                  _ctrlAbueloMaterno.text = madreSeleccionada.nombrePadre ?? '';
                  _ctrlAbuelaMaterna.text = madreSeleccionada.nombreMadre ?? '';
                }
              });
            },
            decoration: _inputDeco('Madre (Hembra)'),
          ),
        ]),
        const SizedBox(height: 20),
        _buildCard('Árbol Genealógico Texto', [
          _buildInput(_ctrlNombrePadre, 'Nombre del Padre'),
          const SizedBox(height: 10),
          _buildResponsiveDualInput(
            _buildInput(_ctrlAbueloPaterno, 'Abuelo Paterno'),
            _buildInput(_ctrlAbuelaPaterna, 'Abuela Paterna')
          ),
          const Divider(height: 20),
          _buildInput(_ctrlNombreMadre, 'Nombre de la Madre'),
          const SizedBox(height: 10),
          _buildResponsiveDualInput(
            _buildInput(_ctrlAbueloMaterno, 'Abuelo Materno'),
            _buildInput(_ctrlAbuelaMaterna, 'Abuela Materna')
          ),
        ]),
        const SizedBox(height: 60),
      ],
    );
  }

  // PESTAÑA 3
  Widget _buildTabGestion() {
    // 🔥 Truco Anti-Crash: Lista nueva, pero agregamos la vieja temporalmente si la tiene
    final List<String> etapasFormulario = List.of(Gallo.etapasVida);
    if (_etapaVida != null && !etapasFormulario.contains(_etapaVida)) {
      etapasFormulario.add(_etapaVida!); 
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard('Estado Actual', [
          _buildResponsiveDualInput(
            _buildDropdown('Estado', Gallo.estadosValidos, _estado, (v) => setState(() => _estado = v)),
            // Pasamos la lista dinámica en vez de la estática
            _buildDropdown('Etapa', etapasFormulario, _etapaVida, (v) => setState(() => _etapaVida = v))
          ),
          const SizedBox(height: 15),
          _buildResponsiveDualInput(
            _buildInput(_ctrlPesoActual, 'Peso Actual (Lbs)', isNumber: true, icon: FontAwesomeIcons.weightScale),
            _buildInput(_ctrlPesoCombate, 'Peso Pactado (Lbs)', isNumber: true, icon: FontAwesomeIcons.dumbbell)
          ),
          const SizedBox(height: 15),
          _buildInput(_ctrlJaula, 'Jaula / Ubicación'),
        ]),
        const SizedBox(height: 20),
        _buildCard('Vacunas', [
          _buildListaDinamica(_ctrlNuevaVacuna, _listaVacunas, 'Agregar Vacuna'),
        ]),
        const SizedBox(height: 20),
        _buildCard('Peleas', [
          _buildListaDinamica(_ctrlNuevaPelea, _listaPeleas, 'Agregar Pelea'),
        ]),
        const SizedBox(height: 60),
      ],
    );
  }

  // PESTAÑA 4
  Widget _buildTabFinanzas() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard('Rentabilidad', [
          _buildResponsiveDualInput(
            _buildInput(_ctrlCosto, 'Costo Adquisición', isNumber: true, isMoney: true, icon: Icons.money_off),
            _buildInput(_ctrlVenta, 'Precio Venta', isNumber: true, isMoney: true, icon: Icons.attach_money)
          ),
          const SizedBox(height: 15),
          _buildInput(_ctrlCriadero, 'Criadero de Origen'),
        ]),
        const SizedBox(height: 20),
        _buildCard('Multimedia y Notas', [
          // 🔥 CAMBIO: Etiqueta general para cualquier enlace
          _buildInput(_ctrlVideo, 'Enlace (YouTube, Drive, Telegram)', icon: FontAwesomeIcons.link),
          const SizedBox(height: 15),
          _buildInput(_ctrlNotas, 'Notas', maxLines: 3),
        ]),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
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

  Widget _buildInput(
    TextEditingController ctrl, 
    String label, {
      dynamic icon, 
      bool isNumber = false, 
      bool isMoney = false, 
      bool validacion = false, 
      int maxLines = 1, 
      bool readOnly = false, 
      VoidCallback? onTap
    }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber 
          ? const TextInputType.numberWithOptions(decimal: true) 
          : TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      inputFormatters: isMoney 
          ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()] 
          : null,
      decoration: _inputDeco(label, icon: icon),
      validator: validacion ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null : null,
    );
  }

  InputDecoration _inputDeco(String label, {dynamic icon}) {
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
  Widget _buildDropdown(String label, List<String> items, String? valor, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      // Key ligada al valor: si el estado cambia por código, el campo se recrea
      key: ValueKey('$label-$valor'),
      isExpanded: true,
      initialValue: items.contains(valor) ? valor : null,
      decoration: _inputDeco(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
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
              // RN-07: prohibido insertar strings vacíos (o solo espacios)
              final texto = ctrl.text.trim();
              if (texto.isNotEmpty) {
                setState(() => lista.add(texto));
              }
              ctrl.clear();
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final double? value = double.tryParse(newValue.text);
    if (value == null) return newValue;
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}