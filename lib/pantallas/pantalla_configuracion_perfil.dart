import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:castasoft/modelos/usuario_modelo.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_inicio.dart';

class PantallaConfiguracionPerfil extends StatefulWidget {
  const PantallaConfiguracionPerfil({Key? key}) : super(key: key);

  @override
  State<PantallaConfiguracionPerfil> createState() => _PantallaConfiguracionPerfilState();
}

class _PantallaConfiguracionPerfilState extends State<PantallaConfiguracionPerfil> {
  final _formKey = GlobalKey<FormState>();
  
  final _ctrlCastadero = TextEditingController();
  final _ctrlPropietario = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  final _ctrlDireccion = TextEditingController();

  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();
  bool _guardando = false;

  // 1. COMPRESIÓN AGRESIVA (Para que funcione en celulares con cámaras potentes)
  Future<void> _seleccionarLogo() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 25, // Bajamos calidad al 25% (Suficiente para un logo pequeño)
      maxWidth: 400,    // Ancho máximo 400px (Para que no pese MBs)
    );
    if (image != null) {
      setState(() => _imagenSeleccionada = File(image.path));
    }
  }

  // 2. GUARDADO BLINDADO
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      String? logoBase64;
      
      // Convertir logo a Base64
      if (_imagenSeleccionada != null) {
        final bytes = await _imagenSeleccionada!.readAsBytes();
        logoBase64 = 'base64,${base64Encode(bytes)}';
        
        // Verificación de seguridad (Opcional, solo para tu tranquilidad)
        // Si el texto es demasiado largo, Firestore fallará. Con la compresión de arriba
        // esto no debería pasar, pero es bueno saberlo.
        if (logoBase64.length > 900000) { 
           throw 'La imagen es demasiado pesada incluso comprimida. Intenta con otra.';
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No se encontró sesión activa';

      final perfil = UsuarioPerfil(
        uid: user.uid,
        email: user.email ?? '',
        nombreCastadero: _ctrlCastadero.text.trim(),
        nombrePropietario: _ctrlPropietario.text.trim(),
        telefono: _ctrlTelefono.text.trim(), // Si está vacío, el Modelo lo convierte a ""
        direccion: _ctrlDireccion.text.trim(), // Si está vacío, el Modelo lo convierte a ""
        logoPath: logoBase64,
      );

      await context.read<UsuarioProveedor>().guardarPerfil(perfil);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PantallaInicio()),
          (route) => false,
        );
      }
    } catch (e) {
      // Mostrar el error real en pantalla para saber qué pasa
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        backgroundColor: const Color(0xFF1E3A8A),
        automaticallyImplyLeading: false, // Quitar botón atrás
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                '¡Bienvenido a CastaSoft!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Antes de empezar, personaliza tu experiencia. Estos datos aparecerán en tu aplicación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // SELECCIÓN DE LOGO
              GestureDetector(
                onTap: _seleccionarLogo,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imagenSeleccionada != null ? FileImage(_imagenSeleccionada!) : null,
                  child: _imagenSeleccionada == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
                            Text('Logo', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 30),

              // CAMPOS DE TEXTO
              TextFormField(
                controller: _ctrlCastadero,
                decoration: _inputDeco('Nombre del Castadero / Criadero', FontAwesomeIcons.house),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ctrlPropietario,
                decoration: _inputDeco('Nombre del Propietario', FontAwesomeIcons.user),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ctrlTelefono,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco('Teléfono / WhatsApp', FontAwesomeIcons.whatsapp),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ctrlDireccion,
                decoration: _inputDeco('Ubicación / Ciudad', FontAwesomeIcons.locationDot),
              ),
              
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _guardando 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR Y COMENZAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1E3A8A), size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}