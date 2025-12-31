import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// === TUS IMPORTACIONES ===
import 'package:castasoft/pantallas/pantalla_inicio.dart';
import 'package:castasoft/pantallas/pantalla_login.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/datos/ayudante_db.dart';
// 🔥 IMPORTACIÓN CLAVE QUE FALTABA:
import 'package:castasoft/servicios/servicio_firestore.dart'; 

void main() async {
  // 1. Asegura que los widgets estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // print('Error inicializando Firebase: $e');
  }

  // 3. Inicializar DB Local (Opcional si ya migraste todo, pero lo dejamos por seguridad)
  await AyudanteDB.instancia.inicializarDB();

  // 4. Ejecutar la aplicación
  runApp(const AplicacionCastaSoft());
}

class AplicacionCastaSoft extends StatelessWidget {
  const AplicacionCastaSoft({super.key});

  @override
  Widget build(BuildContext context) {
    // AQUÍ ESTABA EL PROBLEMA: Faltaba inyectar el ServicioFirestore
    return MultiProvider(
      providers: [
        // 🔥 1. Proveedor de Servicios de Firebase (Login y Datos)
        // Esto permite que PantallaLogin encuentre el servicio
        Provider<ServicioFirestore>(
          create: (_) => ServicioFirestore(),
        ),

        // 2. Proveedor de Lógica de Gallos
        ChangeNotifierProvider(
          create: (_) => GallosProveedor(),
        ),
      ],
      child: MaterialApp(
        title: 'CastaSoft',
        debugShowCheckedModeBanner: false,

        // === CONFIGURACIÓN VISUAL (MANTUVE TU DISEÑO) ===
        theme: ThemeData(
          primaryColor: const Color(0xFF1E3A8A),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E3A8A),
            secondary: Color(0xFFD4AF37),
            surface: Color(0xFFF8FAFC),
            background: Color(0xFFF8FAFC),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),

        // === IDIOMA ESPAÑOL ===
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        locale: const Locale('es', 'ES'),

        // === NAVEGACIÓN ===
        // Arrancamos en el Login para obligar a autenticarse
        initialRoute: '/login', 
        routes: {
          '/login': (context) => const PantallaLogin(),
          '/inicio': (context) => const PantallaInicio(),
        },
      ),
    );
  }
}