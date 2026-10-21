import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_inicio.dart';
import 'package:castasoft/componentes/icono_adaptativo.dart';

class PantallaConfiguracionPerfil extends StatefulWidget {
  final UsuarioPerfil? perfilEditar; // 🔥 NUEVO: Recibe datos para editar
  const PantallaConfiguracionPerfil({super.key, this.perfilEditar});

  @override
  State<PantallaConfiguracionPerfil> createState() => _PantallaConfiguracionPerfilState();
}

class _PantallaConfiguracionPerfilState extends State<PantallaConfiguracionPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  // Controladores
  final _ctrlCastadero = TextEditingController();
  final _ctrlPropietario = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  final _ctrlDireccion = TextEditingController();

  XFile? _imagenSeleccionada; // XFile: funciona igual en Web y nativo
  String? _fotoActualBase64; // Para mostrar la vieja si no selecciona nueva
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // 🔥 LÓGICA DE PRE-LLENADO
    if (widget.perfilEditar != null) {
      final p = widget.perfilEditar!;
      _ctrlCastadero.text = p.nombreCastadero;
      _ctrlPropietario.text = p.nombrePropietario;
      _ctrlTelefono.text = p.telefono ?? '';
      _ctrlDireccion.text = p.direccion ?? '';
      _fotoActualBase64 = p.logoPath;
    }
  }

  Future<void> _seleccionarLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 25, 
      maxWidth: 400,
    );
    if (image != null) {
      setState(() => _imagenSeleccionada = image);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Se capturan antes de cualquier await (contexto asíncrono seguro)
    final usuarioProv = context.read<UsuarioProveedor>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _guardando = true);

    try {
      String? logoBase64;
      
      // Si seleccionó imagen nueva, la procesamos
      if (_imagenSeleccionada != null) {
        final bytes = await _imagenSeleccionada!.readAsBytes();
        logoBase64 = 'base64,${base64Encode(bytes)}';
      } else {
        // Si no, mantenemos la vieja
        logoBase64 = _fotoActualBase64;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No se encontró sesión activa';

      final perfil = UsuarioPerfil(
        uid: user.uid,
        email: user.email ?? '',
        nombreCastadero: _ctrlCastadero.text.trim(),
        nombrePropietario: _ctrlPropietario.text.trim(),
        telefono: _ctrlTelefono.text.trim(),
        direccion: _ctrlDireccion.text.trim(),
        logoPath: logoBase64,
      );

      final confirmado = await usuarioProv.guardarPerfil(perfil);

      if (mounted) {
        // Si venimos de editar, hacemos pop. Si es registro inicial, vamos a inicio.
        if (widget.perfilEditar != null) {
          navigator.pop();
          messenger.showSnackBar(SnackBar(content: Text(confirmado
              ? 'Perfil actualizado correctamente'
              : 'Perfil guardado sin conexión: se sincronizará al volver el internet')));
        } else {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PantallaInicio()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esEdicion = widget.perfilEditar != null;

    // Vista previa: XFile en Web (blob URL) o archivo nativo; si no, el logo
    // guardado ya decodificado y memoizado en el modelo.
    ImageProvider? vistaPrevia;
    if (_imagenSeleccionada != null) {
      vistaPrevia = kIsWeb
          ? NetworkImage(_imagenSeleccionada!.path) as ImageProvider
          : FileImage(File(_imagenSeleccionada!.path));
    } else if (_fotoActualBase64 != null && widget.perfilEditar?.logoBytes != null) {
      vistaPrevia = MemoryImage(widget.perfilEditar!.logoBytes!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Perfil' : 'Configuración Inicial'),
        backgroundColor: const Color(0xFF1E3A8A), // Azul Corporativo
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                esEdicion ? 'Actualiza los datos de tu criadero' : '¡Bienvenido! Configuremos tu marca.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 30),

              // SELECCIÓN DE LOGO
              GestureDetector(
                onTap: _seleccionarLogo,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                    image: vistaPrevia != null
                        ? DecorationImage(image: vistaPrevia, fit: BoxFit.cover)
                        : null,
                  ),
                  child: vistaPrevia == null
                      ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Text('Toca para cambiar logo', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),

              const SizedBox(height: 30),

              _buildInput(_ctrlCastadero, 'Nombre del Castadero / Criadero', FontAwesomeIcons.houseUser, true),
              const SizedBox(height: 20),
              _buildInput(_ctrlPropietario, 'Nombre del Propietario', FontAwesomeIcons.userTie, true),
              const SizedBox(height: 20),
              _buildInput(_ctrlTelefono, 'Teléfono / WhatsApp', FontAwesomeIcons.whatsapp, false, isNumber: true),
              const SizedBox(height: 20),
              _buildInput(_ctrlDireccion, 'Ciudad / Ubicación', FontAwesomeIcons.locationDot, false),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _guardando 
                    ? const CircularProgressIndicator()
                    : Text(esEdicion ? 'ACTUALIZAR DATOS' : 'GUARDAR Y COMENZAR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, dynamic icon, bool requerido, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]'))] : null,
      maxLength: isNumber ? 20 : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: IconoAdaptativo.prefijo(icon, color: const Color(0xFF1E3A8A), size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: requerido ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null : null,
    );
  }
}