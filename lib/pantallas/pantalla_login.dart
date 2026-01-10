import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_configuracion_perfil.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({Key? key}) : super(key: key);

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _controladorUsuario = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();

  bool _mostrarContrasena = false;
  String? _mensajeErrorUsuario;
  String? _mensajeErrorContrasena;
  bool _estaCargando = false;

  // 🔥 PALETA DE COLORES
  static const Color _colorFondo = Color(0xFF121212); 
  static const Color _dorado = Color(0xFFD4AF37); 
  static const Color _grisOscuro = Color(0xFF2C2C2C); 
  static const Color _blanco = Colors.white;

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  // --- LÓGICA DE INICIO DE SESIÓN ---
  bool _validarFormulario() {
    setState(() {
      _mensajeErrorUsuario = null;
      _mensajeErrorContrasena = null;
    });

    bool esValido = true;
    if (_controladorUsuario.text.trim().isEmpty) {
      setState(() => _mensajeErrorUsuario = 'Campo requerido');
      esValido = false;
    }
    if (_controladorContrasena.text.trim().isEmpty) {
      setState(() => _mensajeErrorContrasena = 'Campo requerido');
      esValido = false;
    }
    return esValido;
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    if (!_validarFormulario()) return;

    setState(() => _estaCargando = true);

    try {
      final servicio = context.read<ServicioFirestore>();
      await servicio.iniciarSesion(
        _controladorUsuario.text.trim(),
        _controladorContrasena.text.trim(),
      );

      if (!mounted) return;

      final usuarioProv = context.read<UsuarioProveedor>();
      final bool tienePerfil = await usuarioProv.verificarPerfilExistente();

      if (!mounted) return;

      if (tienePerfil) {
        Navigator.of(context).pushReplacementNamed('/inicio');
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PantallaConfiguracionPerfil())
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _estaCargando = false);
      
      String mensaje = 'Error de acceso';
      if (e.toString().contains('user-not-found') || e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) {
        mensaje = 'Usuario o contraseña incorrectos';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(mensaje))]),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- POPUP INFO ---
  void _mostrarInfoSoporte() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _dorado, width: 1)),
        title: Column(
          children: [
            Icon(FontAwesomeIcons.circleInfo, color: _dorado, size: 40),
            const SizedBox(height: 10),
            Text('CastaSoft Info', style: GoogleFonts.poppins(color: _blanco, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            Text('PROPIEDAD DE: JORGE AGUDELO', style: TextStyle(color: _dorado, fontSize: 10, letterSpacing: 1.5)),
            Text('CRIADERO GALLO ALEGRE', style: GoogleFonts.poppins(color: _blanco, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 16), SizedBox(width: 5), Text('+57 316 5326838', style: TextStyle(color: Colors.grey))]),
            const SizedBox(height: 20),
            Text('DESARROLLADO POR:', style: TextStyle(color: _dorado, fontSize: 10, letterSpacing: 1.5)),
            Text('JOHAN CRUZ', style: GoogleFonts.poppins(color: _blanco, fontWeight: FontWeight.bold)),
            const Text('DESARROLLADOR DE SOFTWARE', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(FontAwesomeIcons.code, color: Colors.blue, size: 16), SizedBox(width: 5), Text('Soporte Técnico', style: TextStyle(color: Colors.grey))]),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar', style: TextStyle(color: _dorado)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    
                    // 1. LOGO CORREGIDO (Sin offsets raros)
                    _construirLogo(),
                    
                    const SizedBox(height: 10),

                    Text(
                      'Acceso Privado',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: _blanco),
                    ),
                    Text(
                      'Sistema de Gestión Genética',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 25),

                    // 2. FORMULARIO COMPACTO
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          _construirCampoUsuario(),
                          const SizedBox(height: 15), 
                          _construirCampoContrasena(),
                          const SizedBox(height: 25), 
                          _construirBotonIniciarSesion(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 3. FOOTER
                    Column(
                      children: [
                        Text(
                          '© 2026 CastaSoft - Derechos Reservados',
                          style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _mostrarInfoSoporte,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: _dorado.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.help_outline, color: _dorado, size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  'Información y Soporte',
                                  style: GoogleFonts.poppins(color: _dorado, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  // ✅ LOGO LIMPIO Y RESPONSIVE
  Widget _construirLogo() {
    return Container(
      // Usamos constraints para que no crezca infinito en tablets
      constraints: const BoxConstraints(maxHeight: 280, maxWidth: 600),
      alignment: Alignment.center, // 🔥 Esto asegura que esté centrado
      child: Image.asset(
        'assets/logo_login_final.jpg',
        fit: BoxFit.contain, // Ajusta la imagen dentro del espacio sin cortarla
      ),
    );
  }

  Widget _construirCampoUsuario() {
    return TextField(
      controller: _controladorUsuario,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _grisOscuro,
        hintText: 'Usuario Asignado',
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: const Icon(FontAwesomeIcons.user, color: _dorado, size: 16),
        errorText: _mensajeErrorUsuario,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _dorado)),
      ),
    );
  }

  Widget _construirCampoContrasena() {
    return TextField(
      controller: _controladorContrasena,
      obscureText: !_mostrarContrasena,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _grisOscuro,
        hintText: 'Contraseña',
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: const Icon(FontAwesomeIcons.lock, color: _dorado, size: 16),
        suffixIcon: IconButton(
          icon: Icon(_mostrarContrasena ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 18),
          onPressed: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
        ),
        errorText: _mensajeErrorContrasena,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _dorado)),
      ),
    );
  }

  Widget _construirBotonIniciarSesion() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _estaCargando ? null : _iniciarSesion,
        style: ElevatedButton.styleFrom(
          backgroundColor: _dorado,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 5,
          shadowColor: _dorado.withOpacity(0.4),
        ),
        child: _estaCargando
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text('ACCEDER AL SISTEMA', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}