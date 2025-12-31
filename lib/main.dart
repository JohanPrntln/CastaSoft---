import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// === TUS IMPORTACIONES ===
import 'package:castasoft/pantallas/pantalla_inicio.dart';
import 'package:castasoft/pantallas/pantalla_login.dart';
import 'package:castasoft/datos/ayudante_db.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';

// === PROVEEDORES ===
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart'; // 🔥 Importación del nuevo proveedor

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

  // 3. Inicializar DB Local (Solo por seguridad/legado)
  await AyudanteDB.instancia.inicializarDB();

  // 4. Ejecutar la aplicación
  runApp(const AplicacionCastaSoft());
}

class AplicacionCastaSoft extends StatelessWidget {
  const AplicacionCastaSoft({super.key});

  @override
  Widget build(BuildContext context) {
    // AQUÍ CONECTAMOS TODOS LOS CEREBROS DE LA APP
    return MultiProvider(
      providers: [
        // 1. Servicio Base de Datos (Conexión Firebase)
        Provider<ServicioFirestore>(
          create: (_) => ServicioFirestore(),
        ),

        // 2. Proveedor de Gallos (Lógica de negocio principal)
        ChangeNotifierProvider(
          create: (_) => GallosProveedor(),
        ),

        // 🔥 3. NUEVO: Proveedor de Usuario (Para el Logo y Perfil)
        // Este es el que faltaba agregar en la lista
        ChangeNotifierProvider(
          create: (_) => UsuarioProveedor(),
        ),
      ],
      child: MaterialApp(
        title: 'CastaSoft',
        debugShowCheckedModeBanner: false,

        // === DISEÑO VISUAL (TEMA) ===
        theme: ThemeData(
          primaryColor: const Color(0xFF1E3A8A), // Azul Corporativo
          scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Fondo Gris Claro
          useMaterial3: true,
          
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E3A8A),
            secondary: Color(0xFFD4AF37), // Dorado Premium
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

        // === CONFIGURACIÓN DE IDIOMA (ESPAÑOL) ===
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        locale: const Locale('es', 'ES'),

        // === RUTAS DE NAVEGACIÓN ===
        initialRoute: '/login', 
        routes: {
          '/login': (context) => const PantallaLogin(),
          '/inicio': (context) => const PantallaInicio(),
          // Nota: La pantalla de configuración de perfil la llamamos
          // dinámicamente desde el Login, no necesitamos ruta nombrada aquí por ahora.
        },
      ),
    );
  }
}