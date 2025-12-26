import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({Key? key}) : super(key: key);

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // Controladores para los campos de entrada
  final TextEditingController _controladorUsuario = TextEditingController();
  final TextEditingController _controladorContrasena = TextEditingController();

  // Variable para controlar visibilidad de contraseña
  bool _mostrarContrasena = false;

  // Variable para mostrar errores de validación
  String? _mensajeErrorUsuario;
  String? _mensajeErrorContrasena;

  // Variable para indicar carga durante el login
  bool _estaCargando = false;

  // Colores del sistema CastaSoft - Paleta Premium
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

  /// Valida los campos del formulario
  bool _validarFormulario() {
    setState(() {
      _mensajeErrorUsuario = null;
      _mensajeErrorContrasena = null;
    });

    bool esValido = true;

    // Validar campo de usuario
    if (_controladorUsuario.text.isEmpty) {
      setState(() {
        _mensajeErrorUsuario = 'El usuario es requerido';
      });
      esValido = false;
    }

    // Validar campo de contraseña
    if (_controladorContrasena.text.isEmpty) {
      setState(() {
        _mensajeErrorContrasena = 'La contraseña es requerida';
      });
      esValido = false;
    } else if (_controladorContrasena.text.length < 6) {
      setState(() {
        _mensajeErrorContrasena =
            'La contraseña debe tener al menos 6 caracteres';
      });
      esValido = false;
    }

    return esValido;
  }

  /// Maneja el proceso de login
  Future<void> _iniciarSesion() async {
    if (!_validarFormulario()) {
      return;
    }

    setState(() {
      _estaCargando = true;
    });

    // Simular un pequeño retraso para autenticación (mockup)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _estaCargando = false;
      });

      // Navegar a la pantalla de inicio
      Navigator.of(context).pushReplacementNamed('/inicio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con Gradiente Radial Premium
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

          // Contenido principal centrado
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
                      // Encabezado con logo
                      _construirEncabezado(),
                      const SizedBox(height: 50),

                      // Tarjeta de login de lujo
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

  /// Construye el encabezado con logo y textos de bienvenida
  Widget _construirEncabezado() {
    return Column(
      children: [
        // Logo con resplandor dorado - Pluma grande y visible
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _dorado.withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: 20,
              ),
              BoxShadow(
                color: _dorado.withOpacity(0.25),
                blurRadius: 80,
                spreadRadius: 35,
              ),
            ],
          ),
          child: Image.asset(
            'assets/pluma_login-removebg-preview.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 50),

        // Título principal
        Text(
          'Bienvenido a CastaSoft',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _blanco,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Subtítulo dorado
        Text(
          'Gestión Genética de Élite',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _dorado,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  /// Construye la tarjeta de login de lujo
  Widget _construirTarjetaLogin() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de Usuario
          _construirCampoUsuario(),
          const SizedBox(height: 24),

          // Campo de Contraseña
          _construirCampoContrasena(),
          const SizedBox(height: 32),

          // Botón de iniciar sesión
          _construirBotonIniciarSesion(),
          const SizedBox(height: 20),

          // Link de contraseña olvidada
          Center(
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _celisteClaro,
                decoration: TextDecoration.underline,
                decorationColor: _celisteClaro.withOpacity(0.3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el campo de entrada de usuario
  Widget _construirCampoUsuario() {
    return TextFormField(
      controller: _controladorUsuario,
      decoration: InputDecoration(
        hintText: 'Ingresa tu usuario o correo',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: _grisNeutro.withOpacity(0.5),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(FontAwesomeIcons.user, size: 16, color: _dorado),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _grisClaro,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _mensajeErrorUsuario != null
                ? Colors.red
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _dorado, width: 2),
        ),
        errorText: _mensajeErrorUsuario,
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: _azulMarino,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (_) {
        if (_mensajeErrorUsuario != null) {
          setState(() {
            _mensajeErrorUsuario = null;
          });
        }
      },
    );
  }

  /// Construye el campo de entrada de contraseña
  Widget _construirCampoContrasena() {
    return TextFormField(
      controller: _controladorContrasena,
      obscureText: !_mostrarContrasena,
      decoration: InputDecoration(
        hintText: 'Ingresa tu contraseña',
        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: _grisNeutro.withOpacity(0.5),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(FontAwesomeIcons.lock, size: 16, color: _dorado),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _mostrarContrasena = !_mostrarContrasena;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(
              _mostrarContrasena
                  ? FontAwesomeIcons.eye
                  : FontAwesomeIcons.eyeSlash,
              size: 16,
              color: _grisNeutro.withOpacity(0.6),
            ),
          ),
        ),
        filled: true,
        fillColor: _grisClaro,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _mensajeErrorContrasena != null
                ? Colors.red
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _dorado, width: 2),
        ),
        errorText: _mensajeErrorContrasena,
        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: _azulMarino,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (_) {
        if (_mensajeErrorContrasena != null) {
          setState(() {
            _mensajeErrorContrasena = null;
          });
        }
      },
    );
  }

  /// Construye el botón de iniciar sesión con StadiumBorder
  Widget _construirBotonIniciarSesion() {
    return ElevatedButton(
      onPressed: _estaCargando ? null : _iniciarSesion,
      style: ElevatedButton.styleFrom(
        backgroundColor: _dorado,
        disabledBackgroundColor: _dorado.withOpacity(0.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 3,
      ),
      child: _estaCargando
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  _azulMarino.withOpacity(0.9),
                ),
                strokeWidth: 2.5,
              ),
            )
          : Text(
              'Iniciar Sesión',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _azulMarino,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
