import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart'; // Importante para acceder al servicio
import 'package:castasoft/servicios/servicio_firestore.dart'; // Tu servicio real

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

  // Colores del sistema CastaSoft
  static const Color _azulMarino = Color(0xFF1E3A8A);
  static const Color _dorado = Color(0xFFD4AF37);
  static const Color _blanco = Color(0xFFFFFFFF);
  static const Color _grisClaro = Color(0xFFF8FAFC);
  static const Color _grisNeutro = Color(0xFF94A3B8);
  static const Color _celisteClaro = Color(0xFF0EA5E9);

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  bool _validarFormulario() {
    setState(() {
      _mensajeErrorUsuario = null;
      _mensajeErrorContrasena = null;
    });

    bool esValido = true;

    if (_controladorUsuario.text.trim().isEmpty) {
      setState(() => _mensajeErrorUsuario = 'El usuario es requerido');
      esValido = false;
    }

    if (_controladorContrasena.text.trim().isEmpty) {
      setState(() => _mensajeErrorContrasena = 'La contraseña es requerida');
      esValido = false;
    } else if (_controladorContrasena.text.length < 6) {
      setState(() => _mensajeErrorContrasena = 'Mínimo 6 caracteres');
      esValido = false;
    }

    return esValido;
  }

  // --- AQUÍ ESTÁ LA LÓGICA DE SEGURIDAD REAL ---
  Future<void> _iniciarSesion() async {
    // 1. Ocultar teclado
    FocusScope.of(context).unfocus();

    if (!_validarFormulario()) return;

    setState(() => _estaCargando = true);

    try {
      // 2. Llamar al servicio REAL de Firebase
      final servicio = context.read<ServicioFirestore>();
      
      // Intentamos entrar con correo y contraseña
      await servicio.iniciarSesion(
        _controladorUsuario.text.trim(),
        _controladorContrasena.text.trim(),
      );

      if (!mounted) return;

      // 3. ¡Éxito! Navegar al inicio
      Navigator.of(context).pushReplacementNamed('/inicio');

    }  catch (e) {
      if (!mounted) return;
      
      setState(() => _estaCargando = false);
      
      // --- CAMBIO TEMPORAL: MOSTRAR EL ERROR REAL ---
      // Esto nos dirá si es "wrong-password", "network-error" o "invalid-api-key"
      String mensajeError = e.toString(); 
      // ----------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(mensajeError)), // Aquí veremos el error técnico
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10), // Que dure bastante para leerlo
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // El diseño visual se mantiene idéntico, solo cambiamos la lógica de arriba.
    // ... (El resto de tu código de UI sigue igual, usa el que tenías o copia este si prefieres) ...
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.5, -0.3),
                radius: 1.5,
                colors: [
                  _azulMarino.withOpacity(0.9),
                  _azulMarino,
                  const Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _construirEncabezado(),
                      const SizedBox(height: 50),
                      _construirTarjetaLogin(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEncabezado() {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _dorado.withOpacity(0.5), blurRadius: 50, spreadRadius: 20),
              BoxShadow(color: _dorado.withOpacity(0.25), blurRadius: 80, spreadRadius: 35),
            ],
          ),
          child: Image.asset('assets/pluma_login-removebg-preview.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 50),
        Text(
          'Bienvenido a CastaSoft',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: _blanco, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Gestión Genética de Élite',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _dorado, letterSpacing: 2.0),
        ),
      ],
    );
  }

  Widget _construirTarjetaLogin() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCampoUsuario(),
          const SizedBox(height: 24),
          _construirCampoContrasena(),
          const SizedBox(height: 32),
          _construirBotonIniciarSesion(),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: GoogleFonts.poppins(fontSize: 13, color: _celisteClaro, decoration: TextDecoration.underline, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCampoUsuario() {
    return TextFormField(
      controller: _controladorUsuario,
      decoration: InputDecoration(
        hintText: 'Ingresa tu usuario o correo',
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: _grisNeutro.withOpacity(0.5)),
        prefixIcon: const Padding(padding: EdgeInsets.only(left: 14, right: 10), child: Icon(FontAwesomeIcons.user, size: 16, color: _dorado)),
        filled: true,
        fillColor: _grisClaro,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorText: _mensajeErrorUsuario,
      ),
      style: GoogleFonts.poppins(fontSize: 13, color: _azulMarino, fontWeight: FontWeight.w500),
    );
  }

  Widget _construirCampoContrasena() {
    return TextFormField(
      controller: _controladorContrasena,
      obscureText: !_mostrarContrasena,
      decoration: InputDecoration(
        hintText: 'Ingresa tu contraseña',
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: _grisNeutro.withOpacity(0.5)),
        prefixIcon: const Padding(padding: EdgeInsets.only(left: 14, right: 10), child: Icon(FontAwesomeIcons.lock, size: 16, color: _dorado)),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
          child: Padding(padding: const EdgeInsets.only(right: 14), child: Icon(_mostrarContrasena ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash, size: 16, color: _grisNeutro.withOpacity(0.6))),
        ),
        filled: true,
        fillColor: _grisClaro,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorText: _mensajeErrorContrasena,
      ),
      style: GoogleFonts.poppins(fontSize: 13, color: _azulMarino, fontWeight: FontWeight.w500),
    );
  }

  Widget _construirBotonIniciarSesion() {
    return ElevatedButton(
      onPressed: _estaCargando ? null : _iniciarSesion,
      style: ElevatedButton.styleFrom(
        backgroundColor: _dorado,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: _estaCargando
          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_azulMarino.withOpacity(0.9)), strokeWidth: 2.5))
          : Text('Iniciar Sesión', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: _azulMarino)),
    );
  }
}
