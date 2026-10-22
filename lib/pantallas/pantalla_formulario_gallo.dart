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
  String? _faseLunar;
  DateTime? _fechaNacimiento;
  String? _padreId;
  String? _madreId;
  
  bool _esEdicion = false;
  XFile? _imagenNuevaSeleccionada; 
  Uint8List? _fotoActualBytes; // Foto guardada (ya decodificada y memoizada en el modelo)

  List<String> _listaVacunas = [];
  List<String> _listaPeleas = [];

  // Selectores híbridos (desplegable / escritura manual)
  static const String _opcionOtro = '➕ Otro (Escribir manualmente...)';
  static const String _opcionOtraVacuna = '➕ Otra (Escribir manualmente...)';
  bool _lineaManual = false;
  bool _colorManual = false;

  // HU-04: evento + fecha de aplicación editable
  String? _vacunaSeleccionada;
  bool _vacunaManual = false;
  DateTime _fechaVacuna = DateTime.now();
  DateTime _fechaPelea = DateTime.now();

  bool get _esHembra => _sexo == 'Hembra';

  /// Solo acepta pesos con hasta 2 enteros y 2 decimales (coma -> punto).
  static final TextInputFormatter _formatoPeso = TextInputFormatter.withFunction((viejo, nuevo) {
    final texto = nuevo.text.replaceAll(',', '.');
    if (Gallo.formatoPeso.hasMatch(texto)) return nuevo.copyWith(text: texto);
    // Permite borrar sobre un valor legado que no cumple el formato
    final viejoInvalido = !Gallo.formatoPeso.hasMatch(viejo.text);
    if (viejoInvalido && texto.length < viejo.text.length) return nuevo.copyWith(text: texto);
    return viejo;
  });

  /// La fecha va en su propio botón: se impide escribir "dd/mm/yyyy" en el texto.
  static final TextInputFormatter _sinFechas = FilteringTextInputFormatter.deny(RegExp(r'/'));

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
    _faseLunar = Gallo.normalizarFaseLunar(g.faseLunar);
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
    _ctrlColor.dispose(); _ctrlFecha.dispose();
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
  
  /// Las pestañas no visibles de `TabBarView` no están montadas y el `Form`
  /// no puede validarlas: se revisan aquí los datos obligatorios.
  String? _validarDatosObligatorios() {
    if (_ctrlPlaca.text.trim().isEmpty) return 'La placa / anillo es obligatoria';
    if (_ctrlNombre.text.trim().isEmpty) return 'El nombre es obligatorio';
    // La regla anti-basura aplica al texto manual; un valor ya guardado que se
    // conserva desde el desplegable no se bloquea (retrocompatibilidad).
    final errorLinea = _lineaManual ? Gallo.validarLineaGenetica(_ctrlLinea.text) : _requerido(_ctrlLinea.text);
    if (errorLinea != null) return 'Línea Genética: $errorLinea';
    final errorColor = _colorManual ? Gallo.validarColorPluma(_ctrlColor.text) : _requerido(_ctrlColor.text);
    if (errorColor != null) return 'Color Pluma: $errorColor';
    if (_faseLunar == null) return 'Selecciona la fase lunar';
    final errorPeso = Gallo.validarPeso(_ctrlPesoActual.text, obligatorio: true);
    if (errorPeso != null) return 'Peso Actual: $errorPeso';
    return null;
  }

  static String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  /// Secciones opcionales que el usuario dejó sin completar (nombre e índice de pestaña).
  List<({String nombre, int pestana})> _seccionesSinCompletar() {
    final genealogiaVacia = _padreId == null &&
        _madreId == null &&
        _ctrlNombrePadre.text.trim().isEmpty &&
        _ctrlNombreMadre.text.trim().isEmpty;
    final gestionVacia = _ctrlJaula.text.trim().isEmpty &&
        _listaVacunas.isEmpty &&
        _ctrlNotas.text.trim().isEmpty &&
        (_esHembra || _listaPeleas.isEmpty);
    final finanzasVacia = _ctrlCosto.text.trim().isEmpty && _ctrlVenta.text.trim().isEmpty;
    return [
      if (genealogiaVacia) (nombre: 'Genealogía', pestana: 1),
      if (gestionVacia) (nombre: 'Gestión', pestana: 2),
      if (finanzasVacia) (nombre: 'Finanzas', pestana: 3),
    ];
  }

  static String _unirNombres(List<String> nombres) => nombres.length == 1
      ? nombres.first
      : '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';

  Future<bool> _confirmarGuardadoIncompleto(List<String> secciones) async {
    final texto = secciones.length == 1
        ? 'en la sección de ${secciones.first}'
        : 'en las secciones de ${_unirNombres(secciones)}';
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Guardar ejemplar?'),
        content: Text('¿Estás seguro de que quieres guardar sin haber completado o revisado la información $texto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, quiero seguir editando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, estoy seguro, guardar'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<void> _guardar() async {
    if (_fechaNacimiento == null) {
      _mostrarSnack('Selecciona fecha de nacimiento', Colors.red);
      return;
    }
    if (!_claveFormulario.currentState!.validate()) return;
    final errorDatos = _validarDatosObligatorios();
    if (errorDatos != null) {
      _tabController.animateTo(0);
      _mostrarSnack(errorDatos, Colors.red);
      return;
    }
    if (!_esHembra && Gallo.validarPeso(_ctrlPesoCombate.text) != null) {
      _tabController.animateTo(2);
      _mostrarSnack('Peso Pactado: ${Gallo.validarPeso(_ctrlPesoCombate.text)}', Colors.red);
      return;
    }
    final errorEnlace = Gallo.validarEnlace(_ctrlVideo.text);
    if (errorEnlace != null) {
      _tabController.animateTo(3);
      _mostrarSnack(errorEnlace, Colors.red);
      return;
    }

    // Se capturan ANTES de cualquier await (contexto asíncrono seguro)
    final proveedor = context.read<GallosProveedor>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final pendientes = _seccionesSinCompletar();
    if (pendientes.isNotEmpty) {
      final confirmado = await _confirmarGuardadoIncompleto([for (final p in pendientes) p.nombre]);
      if (!mounted) return;
      if (!confirmado) {
        _tabController.animateTo(pendientes.first.pestana);
        return;
      }
    }

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
        faseLunar: _faseLunar ?? '',
        tipoCresta: _tipoCresta ?? 'Sierra',
        estado: _estado!,
        etapaVida: _etapaVida ?? 'Cría',
        criaderoOrigen: _ctrlCriadero.text.trim().isEmpty ? 'Propio' : _ctrlCriadero.text.trim(),
        jaula: _ctrlJaula.text.isEmpty ? null : _ctrlJaula.text.trim(),
        
        pesoActual: _limpiarNumero(_ctrlPesoActual.text, esDinero: false),
        // Las hembras no combaten
        pesoCombate: _esHembra ? null : _limpiarNumero(_ctrlPesoCombate.text, esDinero: false),
        
        costoAdquisicion: _limpiarNumero(_ctrlCosto.text, esDinero: true),
        precioVenta: _limpiarNumero(_ctrlVenta.text, esDinero: true),
        
        notas: _ctrlNotas.text.isEmpty ? null : _ctrlNotas.text.trim(),
        fotoPath: fotoFinalString,
        videoUrl: _ctrlVideo.text.trim().isEmpty ? null : _ctrlVideo.text.trim(),
        
        padreId: _padreId,
        madreId: _madreId,
        nombrePadre: _ctrlNombrePadre.text.isEmpty ? null : _ctrlNombrePadre.text,
        nombreMadre: _ctrlNombreMadre.text.isEmpty ? null : _ctrlNombreMadre.text,
        nombreAbueloPaterno: _ctrlAbueloPaterno.text.isEmpty ? null : _ctrlAbueloPaterno.text,
        nombreAbuelaPaterna: _ctrlAbuelaPaterna.text.isEmpty ? null : _ctrlAbuelaPaterna.text,
        nombreAbueloMaterno: _ctrlAbueloMaterno.text.isEmpty ? null : _ctrlAbueloMaterno.text,
        nombreAbuelaMaterna: _ctrlAbuelaMaterna.text.isEmpty ? null : _ctrlAbuelaMaterna.text,
        
        vacunas: _listaVacunas,
        peleas: _esHembra ? const [] : _listaPeleas,
      );

      // Sin red, el proveedor responde en <= 2.5 s con `confirmado == false`:
      // el dato ya está en la caché local y Firestore lo sincronizará solo.
      final bool confirmado = _esEdicion
          ? await proveedor.actualizarGallo(gallo)
          : await proveedor.crearGallo(gallo);

      final accion = _esEdicion ? 'actualizado' : 'creado';
      messenger.showSnackBar(SnackBar(
        content: Text(confirmado
            ? 'Ejemplar $accion correctamente'
            : 'Ejemplar $accion sin conexión: se sincronizará al volver el internet'),
        backgroundColor: confirmado ? Colors.green : Colors.orange.shade800,
      ));
      if (mounted) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _estaGuardando = false);
    }
  }

  String get _tituloAppBar {
    final accion = _esEdicion ? 'Editar' : 'Registrar';
    return _esHembra ? '$accion Gallina / Hembra' : '$accion Gallo / Macho';
  }

  void _mostrarSnack(String msj, Color color) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloAppBar),
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
    final opcionesLinea = _opcionesHibridas(Gallo.lineasGeneticasBase, widget.galloEditar?.lineaGenetica);
    final opcionesColor = _opcionesHibridas(Gallo.coloresPlumaBase, widget.galloEditar?.colorPluma);

    // Etapas según el sexo; si un registro antiguo trae otra (p. ej. legada)
    // se agrega temporalmente para no romper el desplegable.
    final List<String> etapasFormulario = List.of(Gallo.etapasParaSexo(_sexo));
    if (_etapaVida != null && !etapasFormulario.contains(_etapaVida)) {
      etapasFormulario.add(_etapaVida!);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFotoPicker(),
        const SizedBox(height: 20),
        _buildCard('Identificación', [
          _buildResponsiveDualInput(
            _buildInput(_ctrlPlaca, 'Placa / Anillo', icon: FontAwesomeIcons.tag, validacion: true, maxLength: 30),
            _buildInput(_ctrlNombre, 'Nombre', icon: FontAwesomeIcons.signature, validacion: true, maxLength: 40)
          ),
          const SizedBox(height: 15),
          _buildResponsiveDualInput(
            _buildDropdown('Sexo', ['Macho', 'Hembra'], _sexo, (v) => setState(() {
              _sexo = v;
              // Coherencia biológica: la etapa debe existir para el nuevo sexo
              if (!Gallo.etapasParaSexo(v).contains(_etapaVida)) _etapaVida = 'Cría';
            })),
            _buildInput(_ctrlFecha, 'Fec. Nacimiento', icon: FontAwesomeIcons.calendar, readOnly: true, onTap: _seleccionarFecha)
          ),
          const SizedBox(height: 15),
          _buildResponsiveDualInput(
            _buildDropdown('Estado', Gallo.estadosValidos, _estado, (v) => setState(() => _estado = v)),
            _buildDropdown('Etapa de Vida', etapasFormulario, _etapaVida, (v) => setState(() => _etapaVida = v)),
          ),
        ]),
        const SizedBox(height: 15),
        _buildCard('Genética y Físico', [
          _buildResponsiveDualInput(
            _buildSelectorHibrido(
              claveBase: 'linea',
              label: 'Línea Genética',
              icon: FontAwesomeIcons.dna,
              ctrl: _ctrlLinea,
              opciones: opcionesLinea,
              manual: _lineaManual,
              alCambiarModo: (m) => _lineaManual = m,
              maxLength: 30,
              validar: Gallo.validarLineaGenetica,
              formatters: [FilteringTextInputFormatter.allow(Gallo.caracteresLineaGenetica)],
            ),
            _buildSelectorHibrido(
              claveBase: 'color',
              label: 'Color Pluma',
              icon: FontAwesomeIcons.palette,
              ctrl: _ctrlColor,
              opciones: opcionesColor,
              manual: _colorManual,
              alCambiarModo: (m) => _colorManual = m,
              maxLength: 25,
              validar: Gallo.validarColorPluma,
              formatters: [FilteringTextInputFormatter.allow(Gallo.caracteresColorPluma)],
            ),
          ),
          const SizedBox(height: 15),
          _buildResponsiveDualInput(
            _buildDropdown('Cresta', ['Sierra', 'Rosa', 'Pava', 'Boton', 'Simple'], _tipoCresta, (v) => setState(() => _tipoCresta = v)),
            _buildDropdown('Fase Lunar', Gallo.opcionesFaseLunar(_faseLunar), _faseLunar, (v) => setState(() => _faseLunar = v),
                icon: FontAwesomeIcons.moon, validator: (v) => v == null ? 'Requerido' : null),
          ),
          const SizedBox(height: 15),
          _buildInput(
            _ctrlPesoActual, 'Peso Actual (Lbs)',
            key: const Key('campo-peso-actual'),
            isNumber: true,
            icon: FontAwesomeIcons.weightScale,
            formatters: [_formatoPeso],
            validator: (v) => Gallo.validarPeso(v, obligatorio: true),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildCard(_esHembra ? 'Ubicación' : 'Ubicación y Combate', [
          if (_esHembra)
            _buildInput(_ctrlJaula, 'Jaula / Ubicación', maxLength: 20)
          else
            _buildResponsiveDualInput(
              _buildInput(
                _ctrlPesoCombate, 'Peso Pactado (Lbs)',
                key: const Key('campo-peso-pactado'),
                isNumber: true,
                icon: FontAwesomeIcons.dumbbell,
                formatters: [_formatoPeso],
                validator: (v) => Gallo.validarPeso(v),
              ),
              _buildInput(_ctrlJaula, 'Jaula / Ubicación', maxLength: 20),
            ),
        ]),
        const SizedBox(height: 20),
        _buildCard('Vacunas / Historial Sanitario', [
          _buildSeccionVacunas(),
        ]),
        if (!_esHembra) ...[
          const SizedBox(height: 20),
          _buildCard('Historial de Peleas', [
            _buildSeccionPeleas(),
          ]),
        ],
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
          _buildInput(_ctrlCriadero, 'Criadero de Origen', maxLength: 40),
        ]),
        const SizedBox(height: 20),
        _buildCard('Multimedia y Notas', [
          // 🔥 CAMBIO: Etiqueta general para cualquier enlace
          _buildInput(
            _ctrlVideo, 'Enlace (YouTube, Drive, Telegram)',
            key: const Key('campo-enlace'),
            icon: FontAwesomeIcons.link,
            validator: Gallo.validarEnlace,
          ),
          const SizedBox(height: 15),
          _buildInput(_ctrlNotas, 'Notas', maxLines: 3, maxLength: 300),
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
      Key? key,
      dynamic icon, 
      bool isNumber = false, 
      bool isMoney = false, 
      bool validacion = false, 
      int maxLines = 1, 
      int? maxLength,
      bool readOnly = false, 
      VoidCallback? onTap,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator,
      Widget? suffixIcon,
    }) {
    return TextFormField(
      key: key,
      controller: ctrl,
      keyboardType: isNumber 
          ? const TextInputType.numberWithOptions(decimal: true) 
          : TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: isMoney 
          ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()] 
          : formatters,
      decoration: _inputDeco(label, icon: icon, suffixIcon: suffixIcon),
      validator: validator ??
          (validacion ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null : null),
    );
  }

  InputDecoration _inputDeco(String label, {dynamic icon, Widget? suffixIcon, String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: icon != null 
          ? IconoAdaptativo.prefijo(icon, size: 18, color: const Color(0xFF1E3A8A))
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? valor, Function(String?) onChanged,
      {dynamic icon, String? Function(String?)? validator}) {
    return DropdownButtonFormField<String>(
      // Key ligada al valor: si el estado cambia por código, el campo se recrea
      key: ValueKey('$label-$valor'),
      isExpanded: true,
      initialValue: items.contains(valor) ? valor : null,
      decoration: _inputDeco(label, icon: icon),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// Catálogo corto + (en edición) el valor guardado del ejemplar si no es
  /// parte del catálogo, para no perderlo ni romper el desplegable + "Otro".
  List<String> _opcionesHibridas(List<String> base, String? valorGuardado) {
    final guardado = valorGuardado?.trim() ?? '';
    return [
      ...base,
      if (guardado.isNotEmpty && !base.contains(guardado)) guardado,
      _opcionOtro,
    ];
  }

  /// Desplegable con opciones comunes que se convierte en texto libre al
  /// elegir "Otro"; la X del campo manual regresa al desplegable.
  Widget _buildSelectorHibrido({
    required String claveBase,
    required String label,
    required dynamic icon,
    required TextEditingController ctrl,
    required List<String> opciones,
    required bool manual,
    required ValueChanged<bool> alCambiarModo,
    required int maxLength,
    required String? Function(String?) validar,
    List<TextInputFormatter>? formatters,
  }) {
    if (manual) {
      return _buildInput(
        ctrl, label,
        key: Key('$claveBase-manual'),
        icon: icon,
        maxLength: maxLength,
        formatters: formatters,
        validator: validar,
        suffixIcon: IconButton(
          key: Key('$claveBase-volver-lista'),
          tooltip: 'Volver a la lista',
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            alCambiarModo(false);
            if (!opciones.contains(ctrl.text.trim())) ctrl.clear();
          }),
        ),
      );
    }
    final actual = ctrl.text.trim();
    return DropdownButtonFormField<String>(
      key: ValueKey('$claveBase-$actual'),
      isExpanded: true,
      initialValue: opciones.contains(actual) ? actual : null,
      decoration: _inputDeco(label, icon: icon),
      items: opciones
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: (v) => setState(() {
        if (v == _opcionOtro) {
          alCambiarModo(true);
          ctrl.clear();
        } else {
          ctrl.text = v ?? '';
        }
      }),
      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
    );
  }

  Widget _buildSelectorFechaEvento(DateTime fecha, ValueChanged<DateTime> alCambiar, {required Key key}) {
    return OutlinedButton(
      key: key,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1E3A8A),
        side: const BorderSide(color: Color(0xFF1E3A8A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (elegida != null) setState(() => alCambiar(elegida));
      },
      child: Text('📅 Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)} (Cambiar)'),
    );
  }

  Widget _buildSeccionVacunas() {
    final Widget campo = _vacunaManual
        ? TextFormField(
            key: const Key('vacuna-manual'),
            controller: _ctrlNuevaVacuna,
            maxLength: 60,
            inputFormatters: [_sinFechas],
            decoration: _inputDeco(
              'Vacuna / tratamiento',
              hintText: 'Nombre de la vacuna (usa el botón de fecha)',
              suffixIcon: IconButton(
                tooltip: 'Volver a la lista',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _vacunaManual = false;
                  _ctrlNuevaVacuna.clear();
                }),
              ),
            ),
          )
        : DropdownButtonFormField<String>(
            key: ValueKey('vacuna-$_vacunaSeleccionada'),
            isExpanded: true,
            initialValue: _vacunaSeleccionada,
            decoration: _inputDeco('Agregar Vacuna'),
            items: [...Gallo.vacunasComunes, _opcionOtraVacuna]
                .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) => setState(() {
              if (v == _opcionOtraVacuna) {
                _vacunaManual = true;
                _vacunaSeleccionada = null;
              } else {
                _vacunaSeleccionada = v;
              }
            }),
          );

    return Column(
      children: [
        campo,
        Row(children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSelectorFechaEvento(_fechaVacuna, (f) => _fechaVacuna = f, key: const Key('fecha-vacuna')),
            ),
          ),
          IconButton(
            key: const Key('agregar-vacuna'),
            tooltip: 'Agregar vacuna',
            icon: const Icon(Icons.add_circle, color: Color(0xFF1E3A8A)),
            onPressed: _agregarVacuna,
          ),
        ]),
        _buildChipsEventos(_listaVacunas),
      ],
    );
  }

  Widget _buildSeccionPeleas() {
    return Column(
      children: [
        TextFormField(
          key: const Key('pelea-texto'),
          controller: _ctrlNuevaPelea,
          maxLength: 100,
          inputFormatters: [_sinFechas],
          decoration: _inputDeco('Agregar Pelea', hintText: 'Ej: Ganó en 12 min (usa el botón de fecha)'),
        ),
        Row(children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSelectorFechaEvento(_fechaPelea, (f) => _fechaPelea = f, key: const Key('fecha-pelea')),
            ),
          ),
          IconButton(
            key: const Key('agregar-pelea'),
            tooltip: 'Agregar pelea',
            icon: const Icon(Icons.add_circle, color: Color(0xFF1E3A8A)),
            onPressed: _agregarPelea,
          ),
        ]),
        _buildChipsEventos(_listaPeleas),
      ],
    );
  }

  void _agregarVacuna() {
    final evento = Gallo.quitarFechas(_vacunaManual ? _ctrlNuevaVacuna.text : (_vacunaSeleccionada ?? ''));
    // RN-07: prohibido insertar strings vacíos (o solo espacios)
    if (evento.isEmpty) {
      _mostrarSnack('Selecciona o escribe una vacuna', Colors.red);
      return;
    }
    setState(() {
      _listaVacunas.add(Gallo.eventoConFecha(evento, _fechaVacuna));
      _vacunaSeleccionada = null;
      _ctrlNuevaVacuna.clear();
      _fechaVacuna = DateTime.now();
    });
  }

  void _agregarPelea() {
    final evento = Gallo.quitarFechas(_ctrlNuevaPelea.text);
    if (evento.isEmpty) {
      _mostrarSnack('Describe la pelea antes de agregarla', Colors.red);
      return;
    }
    setState(() {
      _listaPeleas.add(Gallo.eventoConFecha(evento, _fechaPelea));
      _ctrlNuevaPelea.clear();
      _fechaPelea = DateTime.now();
    });
  }

  Widget _buildChipsEventos(List<String> lista) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        children: lista.map((e) => Chip(
          label: Text(e),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => setState(() => lista.remove(e)),
        )).toList(),
      ),
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