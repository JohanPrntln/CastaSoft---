import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart'; // Importante para acceder al servicio
import 'package:castasoft/servicios/servicio_firestore.dart'; // Tu servicio real
import 'package:castasoft/proveedores/usuario_proveedor.dart'; // <--- NUEVO
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

Future<void> _iniciarSesion() async {
    // 1. Ocultar teclado y validar
    FocusScope.of(context).unfocus();
    if (!_validarFormulario()) return;

    setState(() => _estaCargando = true);

    try {
      // 2. Llamar al servicio REAL de Firebase (Autenticación)
      final servicio = context.read<ServicioFirestore>();
      
      await servicio.iniciarSesion(
        _controladorUsuario.text.trim(),
        _controladorContrasena.text.trim(),
      );

      if (!mounted) return;

      // 3. 🔥 VERIFICACIÓN DE PERFIL (LO NUEVO) 🔥
      // Preguntamos: ¿Este usuario ya tiene logo y nombre de castadero?
      final usuarioProv = context.read<UsuarioProveedor>();
      final bool tienePerfil = await usuarioProv.verificarPerfilExistente();

      if (!mounted) return;

      if (tienePerfil) {
        // CASO A: Usuario viejo (Ya configuró todo) -> Va al Inicio
        Navigator.of(context).pushReplacementNamed('/inicio');
      } else {
        // CASO B: Usuario nuevo (Primera vez) -> Va a Configuración
        // Nota: Asegúrate de importar la pantalla arriba
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PantallaConfiguracionPerfil())
        );
      }

    } catch (e) {
      if (!mounted) return;
      
      setState(() => _estaCargando = false);
      
      // Mensaje de error amigable
      String mensajeError = 'Error de conexión o datos incorrectos';
      if (e.toString().contains('user-not-found')) mensajeError = 'Usuario no encontrado';
      if (e.toString().contains('wrong-password')) mensajeError = 'Contraseña incorrecta';
      if (e.toString().contains('invalid-credential')) mensajeError = 'Credenciales inválidas';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(mensajeError)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
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
