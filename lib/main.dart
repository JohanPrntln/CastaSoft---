import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:castasoft/pantallas/pantalla_inicio.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/datos/ayudante_db.dart';

/// Función principal de la aplicación CastaSoft
/// Inicia la aplicación ejecutando la clase AplicacionCastaSoft
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar la base de datos antes de ejecutar la aplicación
  await AyudanteDB.instancia.inicializarDB();

  runApp(const AplicacionCastaSoft());
}

/// Clase principal de la aplicación - AplicacionCastaSoft
///
/// Widget raíz de la aplicación que configura:
/// - MaterialApp con tema corporativo
/// - Colores personalizados de la marca CastaSoft
/// - Tipografía con Google Fonts (Poppins)
/// - Provider para gestión de estado con GallosProveedor
/// - Pantalla inicial PantallaInicio
///
/// Colores corporativos:
/// - Primario (Primary): Azul Marino Oscuro (#1E3A8A)
/// - Fondo (Scaffold): Gris muy claro (#F8FAFC)
/// - Acento (Secondary): Dorado (#D4AF37)
class AplicacionCastaSoft extends StatelessWidget {
  /// Constructor de la aplicación principal
  const AplicacionCastaSoft({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      /// Proveedores de estado disponibles en toda la aplicación
      providers: [
        /// Proveedor para gestión de gallos
        /// Disponible a través de context.read<GallosProveedor>()
        /// o Consumer<GallosProveedor>()
        ChangeNotifierProvider(create: (context) => GallosProveedor()),
      ],
      child: MaterialApp(
        /// Título de la aplicación
        title: 'CastaSoft',

        /// Configuración del tema visual corporativo
        theme: ThemeData(
          /// Paleta de colores corporativa usando valores hexadecimales
          primaryColor: const Color(0xFF1E3A8A), // Azul Marino Oscuro
          scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Gris muy claro
          useMaterial3: true,

          /// ColorScheme personalizado con los colores de la marca
          colorScheme: ColorScheme.light(
            primary: const Color(0xFF1E3A8A), // Azul Marino Oscuro
            secondary: const Color(0xFFD4AF37), // Dorado
            surface: const Color(0xFFF8FAFC), // Gris muy claro
            background: const Color(0xFFF8FAFC), // Gris muy claro
          ),

          /// Tipografía base usando Google Fonts - Poppins
          /// Poppins es una fuente moderna y clara ideal para aplicaciones corporativas
          textTheme: GoogleFonts.poppinsTextTheme(),

          /// Configuración del AppBar corporativo
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF1E3A8A), // Azul Marino Oscuro
            elevation: 0,
            centerTitle: false,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),

        /// Configuración de localizaciones para soportar español
        /// Necesario para que DatePickerDialog funcione correctamente
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español
          Locale('en', 'US'), // Inglés
        ],
        locale: const Locale('es', 'ES'), // Locale por defecto
        /// Pantalla inicial de la aplicación
        /// Apunta a PantallaInicio que es el dashboard principal
        home: const PantallaInicio(),

        /// Desactiva el banner de debug en la esquina superior derecha
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
