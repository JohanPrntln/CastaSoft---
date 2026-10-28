import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:castasoft/componentes/boton_limpiar_duplicados.dart';
import 'package:castasoft/componentes/icono_adaptativo.dart';
import 'package:castasoft/componentes/selector_foto.dart';
import 'package:castasoft/componentes/tarjeta_gallo.dart';
import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/modelos/foto_base64.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/pantallas/pantalla_formulario_cruce.dart';
import 'package:castasoft/pantallas/pantalla_formulario_gallo.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/servicios/deduplicacion.dart';

Gallo galloCompleto({
  String id = 'gc',
  String placa = 'C3',
  String? videoUrl,
  String? nombrePadre,
  String? jaula,
  double? costo,
  String nombre = 'Centella',
  String sexo = 'Macho',
  String linea = 'Kelso',
}) =>
    Gallo(
      id: id, placa: placa, nombre: nombre, sexo: sexo, fechaNacimiento: DateTime(2024),
      lineaGenetica: linea, colorPluma: 'Giro', faseLunar: 'Luna llena', estado: 'Activo', etapaVida: 'Padrote',
      pesoActual: 5.0, videoUrl: videoUrl, nombrePadre: nombrePadre, jaula: jaula, costoAdquisicion: costo,
    );

extension on Gallo {
  Gallo copyWithLineaColor(String linea, String color) {
    final mapa = toMap()
      ..['id'] = id
      ..['lineaGenetica'] = linea
      ..['colorPluma'] = color;
    return Gallo.fromMap(mapa);
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('RN-02 / RN-04: CruceModelo.validarReglasNegocio', () {
    String? validar({String? padre = 'p', String? madre = 'm', int total = 10, int muertos = 0, int machos = 0, int hembras = 0}) =>
        CruceModelo.validarReglasNegocio(
          padreId: padre,
          madreId: madre,
          cantidadHuevos: total,
          pollitosMuertos: muertos,
          pollitosMachos: machos,
          pollitosHembras: hembras,
        );

    test('cruce coherente es válido', () {
      expect(validar(total: 10, muertos: 2, machos: 4, hembras: 4), isNull);
    });
    test('exige padre y madre', () {
      expect(validar(padre: null), isNotNull);
      expect(validar(madre: ''), isNotNull);
    });
    test('muertos no pueden superar el total', () {
      expect(validar(total: 5, muertos: 6), isNotNull);
    });
    test('machos + hembras no pueden superar los vivos', () {
      expect(validar(total: 10, muertos: 3, machos: 4, hembras: 4), isNotNull);
    });
    test('rechaza cantidades negativas', () {
      expect(validar(machos: -1), isNotNull);
    });
  });

  group('RN-07: Gallo.fromMap con tipos inseguros', () {
    test('parsea números como String/int y descarta strings vacíos en listas', () {
      final g = Gallo.fromMap({
        'id': 'x',
        'placa': 'A1',
        'costoAdquisicion': '250000',
        'precioVenta': 300000,
        'fechaNacimiento': 'no-es-fecha',
        'vacunas': ['Newcastle', '', '   ', null],
        'peleas': 'no-es-lista',
      });
      expect(g.costoAdquisicion, 250000.0);
      expect(g.precioVenta, 300000.0);
      expect(g.vacunas, ['Newcastle']);
      expect(g.peleas, isEmpty);
    });
  });

  group('Fotos Base64 memoizadas', () {
    final fotoPath = '$prefijoFotoBase64${base64Encode([1, 2, 3])}';

    test('Gallo.fotoBytes decodifica una vez y devuelve la misma instancia', () {
      final g = Gallo.fromMap({'id': 'x', 'fotoPath': fotoPath});
      final primera = g.fotoBytes;
      expect(primera, [1, 2, 3]);
      expect(identical(primera, g.fotoBytes), isTrue);
    });

    test('CruceModelo.fotoBytes tolera Base64 corrupto', () {
      final c = CruceModelo.fromMap({'id': 'c', 'fotoPath': 'base64,%%%'});
      expect(c.fotoBytes, isNull);
    });

    test('rutas de archivo legadas no se interpretan como Base64', () {
      expect(decodificarFotoBase64('/data/user/0/foto.jpg'), isNull);
    });
  });

  testWidgets('IconoAdaptativo.prefijo centra IconData y FaIconData en la misma caja', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          IconoAdaptativo.prefijo(Icons.search, key: Key('material')),
          IconoAdaptativo.prefijo(FontAwesomeIcons.magnifyingGlass, key: Key('fa')),
        ]),
      ),
    ));
    expect(tester.getSize(find.byKey(const Key('material'))), tester.getSize(find.byKey(const Key('fa'))));
    expect(tester.getSize(find.byKey(const Key('fa'))).width, 48);
  });

  group('Coherencia biológica: Gallo.etapasParaSexo', () {
    test('macho y hembra tienen etapas propias', () {
      expect(Gallo.etapasParaSexo('Macho'), ['Cría', 'Pollos crestones', 'Muda', 'Padrote', 'Combate']);
      expect(Gallo.etapasParaSexo('Hembra'), ['Cría', 'Pollonas', 'Muda', 'Postura', 'Madrilla']);
    });
    test('un macho no puede ser Madrilla/Pollonas/Postura ni una hembra Padrote/Pollos crestones/Combate', () {
      for (final e in ['Madrilla', 'Pollonas', 'Postura']) {
        expect(Gallo.etapasParaSexo('Macho'), isNot(contains(e)));
      }
      for (final e in ['Padrote', 'Pollos crestones', 'Combate']) {
        expect(Gallo.etapasParaSexo('Hembra'), isNot(contains(e)));
      }
    });
    test('sexo desconocido devuelve el catálogo completo', () {
      expect(Gallo.etapasParaSexo(null), Gallo.etapasVida);
    });
  });

  group('Fases lunares: Gallo.normalizarFaseLunar', () {
    test('las 8 fases oficiales se conservan', () {
      expect(Gallo.fasesLunares, hasLength(8));
      for (final fase in Gallo.fasesLunares) {
        expect(Gallo.normalizarFaseLunar(fase), fase);
        expect(Gallo.normalizarFaseLunar('  ${fase.toUpperCase()} '), fase);
      }
    });
    test('mapea valores antiguos de Firestore', () {
      expect(Gallo.normalizarFaseLunar('Nueva'), 'Luna nueva');
      expect(Gallo.normalizarFaseLunar('luna nueva'), 'Luna nueva');
      expect(Gallo.normalizarFaseLunar('Creciente'), 'Luna creciente');
      expect(Gallo.normalizarFaseLunar('luna creciente'), 'Luna creciente');
      expect(Gallo.normalizarFaseLunar('Llena'), 'Luna llena');
      expect(Gallo.normalizarFaseLunar(' luna llena '), 'Luna llena');
      expect(Gallo.normalizarFaseLunar('Menguante'), 'Luna menguante');
      expect(Gallo.normalizarFaseLunar('LUNA MENGUANTE'), 'Luna menguante');
    });
    test('vacíos son null y desconocidos se conservan en las opciones del desplegable', () {
      expect(Gallo.normalizarFaseLunar(null), isNull);
      expect(Gallo.normalizarFaseLunar('   '), isNull);
      expect(Gallo.normalizarFaseLunar('Eclipse'), 'Eclipse');
      expect(Gallo.opcionesFaseLunar('Eclipse'), [...Gallo.fasesLunares, 'Eclipse']);
      expect(Gallo.opcionesFaseLunar('Llena'), Gallo.fasesLunares);
    });
  });

  group('Validaciones de formulario', () {
    test('peso: rango biológico > 0.1 y <= 25.0 Lbs', () {
      expect(Gallo.validarPeso('5.5', obligatorio: true), isNull);
      expect(Gallo.validarPeso('25', obligatorio: true), isNull);
      expect(Gallo.validarPeso('0.11'), isNull);
      expect(Gallo.validarPeso('4,5'), isNull);
      expect(Gallo.validarPeso('25.01'), isNotNull);
      expect(Gallo.validarPeso('0.1'), isNotNull);
      expect(Gallo.validarPeso('0'), isNotNull);
      expect(Gallo.validarPeso('abc'), isNotNull);
      expect(Gallo.validarPeso('', obligatorio: true), 'Requerido');
      expect(Gallo.validarPeso(''), isNull);
    });
    test('peso: mensaje de error humano, sin símbolos matemáticos', () {
      const mensaje = 'El peso debe ser mayor a 0.1 y menor o igual a 25.0 Lbs';
      expect(Gallo.validarPeso('30'), mensaje);
      expect(Gallo.validarPeso('0.1', obligatorio: true), mensaje);
      expect(Gallo.validarPeso('abc'), mensaje);
      expect(mensaje, isNot(contains('>')));
      expect(mensaje, isNot(contains('<')));
    });
    test('formato de peso: hasta 2 enteros y 2 decimales, sin signos', () {
      expect(Gallo.formatoPeso.hasMatch('12.34'), isTrue);
      expect(Gallo.formatoPeso.hasMatch('123'), isFalse);
      expect(Gallo.formatoPeso.hasMatch('1.234'), isFalse);
      expect(Gallo.formatoPeso.hasMatch('-5'), isFalse);
      expect(Gallo.formatoPeso.hasMatch('+5'), isFalse);
    });
    test('color pluma anti-basura: solo letras/espacios/guiones, 3-25 caracteres', () {
      const mensaje = 'Ingresa un color válido usando solo letras (mínimo 3)';
      expect(Gallo.validarColorPluma('Giro'), isNull);
      expect(Gallo.validarColorPluma('Negro - Blanco'), isNull);
      expect(Gallo.validarColorPluma('Cenizo Colorado'), isNull);
      expect(Gallo.validarColorPluma('Giro2'), mensaje);
      expect(Gallo.validarColorPluma('Negro / Blanco'), mensaje);
      expect(Gallo.validarColorPluma('"Giro"'), mensaje);
      expect(Gallo.validarColorPluma('123'), mensaje);
      expect(Gallo.validarColorPluma('ab'), mensaje);
      expect(Gallo.validarColorPluma('Abcdefghijklmnopq'), mensaje); // palabra de 17 letras
      expect(Gallo.validarColorPluma('Giro Cenizo Colorado Negro'), mensaje); // 26 caracteres
      expect(Gallo.validarColorPluma('   '), 'Requerido');
    });
    test('línea genética anti-basura: admite cruces filiales y rechaza texto sin sentido', () {
      const mensaje = 'Ingresa una línea genética válida (ej: Kelso, F1 Hatch 50%)';
      expect(Gallo.validarLineaGenetica('F1 Kelso 50%'), isNull);
      expect(Gallo.validarLineaGenetica('F1 Hatch 50%'), isNull);
      expect(Gallo.validarLineaGenetica('Kelso x Hatch'), isNull);
      expect(Gallo.validarLineaGenetica('Sweater/Albany 1/2'), isNull);
      expect(Gallo.validarLineaGenetica('Hatch'), isNull);
      expect(Gallo.validarLineaGenetica('265154545454545222222d2df2dlf5e"W"rwe'), mensaje);
      expect(Gallo.validarLineaGenetica('Kelso!!'), mensaje);
      expect(Gallo.validarLineaGenetica('Kelso 123456'), mensaje); // 5+ dígitos seguidos
      expect(Gallo.validarLineaGenetica('Supercalifragilistico'), mensaje); // palabra de 21 letras
      expect(Gallo.validarLineaGenetica('Kelso Hatch Sweater Albany Giro'), mensaje); // 31 caracteres
      expect(Gallo.validarLineaGenetica('12345'), mensaje);
      expect(Gallo.validarLineaGenetica('50% - 25%'), mensaje);
      expect(Gallo.validarLineaGenetica('F1'), mensaje);
      expect(Gallo.validarLineaGenetica('F1 Ke'), mensaje); // sin palabra de 3 letras
      expect(Gallo.validarLineaGenetica(''), 'Requerido');
    });
    test('enlace de video: opcional, pero si existe debe ser http(s) con dominio', () {
      const mensaje = 'Ingresa un enlace web válido que inicie con https:// o http://';
      expect(Gallo.validarEnlace(''), isNull);
      expect(Gallo.validarEnlace('   '), isNull);
      expect(Gallo.validarEnlace(null), isNull);
      expect(Gallo.validarEnlace('https://www.youtube.com/watch?v=abc'), isNull);
      expect(Gallo.validarEnlace('http://drive.google.com/file/d/1'), isNull);
      expect(Gallo.validarEnlace('https://t.me/criadero'), isNull);
      expect(Gallo.validarEnlace('12345'), mensaje);
      expect(Gallo.validarEnlace('hola'), mensaje);
      expect(Gallo.validarEnlace('www.youtube.com'), mensaje);
      expect(Gallo.validarEnlace('ftp://archivos.com'), mensaje);
      expect(Gallo.validarEnlace('https://localhost'), mensaje);
      expect(Gallo.validarEnlace('https://'), mensaje);
    });
    test('HU-04: evento + fecha, sin fechas duplicadas', () {
      final fecha = DateTime(2026, 3, 7);
      expect(Gallo.eventoConFecha('  Newcastle ', fecha), 'Newcastle (07/03/2026)');
      expect(Gallo.eventoConFecha('Newcastle 01/02/2026', fecha), 'Newcastle (07/03/2026)');
      expect(Gallo.eventoConFecha('Gumboro (1-2-25)', fecha), 'Gumboro (07/03/2026)');
      expect(Gallo.quitarFechas('15/01/2026'), '');
    });
  });

  group('PantallaFormularioGallo', () {
    Future<void> abrirFormulario(WidgetTester tester, {Gallo? galloEditar}) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<GallosProveedor>(
        create: (_) => GallosProveedor.enMemoria([if (galloEditar != null) galloEditar]),
        child: MaterialApp(home: PantallaFormularioGallo(galloEditar: galloEditar)),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> elegir(WidgetTester tester, String actual, String nuevo) async {
      await tester.tap(find.text(actual).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(nuevo).last);
      await tester.pumpAndSettle();
    }

    Future<void> irAGestion(WidgetTester tester) async {
      await tester.tap(find.text('Gestión'));
      await tester.pumpAndSettle();
    }

    testWidgets('título dinámico y ocultamiento de combate al elegir Hembra', (tester) async {
      await abrirFormulario(tester);
      expect(find.text('Registrar Gallo / Macho'), findsOneWidget);

      await irAGestion(tester);
      expect(find.text('Peso Pactado (Lbs)'), findsOneWidget);
      expect(find.text('Historial de Peleas'), findsOneWidget);

      await tester.tap(find.text('Datos'));
      await tester.pumpAndSettle();
      await elegir(tester, 'Macho', 'Hembra');
      expect(find.text('Registrar Gallina / Hembra'), findsOneWidget);

      await irAGestion(tester);
      expect(find.text('Peso Pactado (Lbs)'), findsNothing);
      expect(find.text('Historial de Peleas'), findsNothing);
    });

    testWidgets('al cambiar de sexo, una etapa incompatible vuelve a Cría', (tester) async {
      final macho = Gallo(
        id: 'g1', placa: 'A1', nombre: 'Rayo', sexo: 'Macho', fechaNacimiento: DateTime(2024),
        lineaGenetica: 'Kelso', colorPluma: 'Giro', faseLunar: 'Llena', estado: 'Activo', etapaVida: 'Combate',
      );
      await abrirFormulario(tester, galloEditar: macho);
      expect(find.text('Editar Gallo / Macho'), findsOneWidget);
      // Fase lunar antigua normalizada
      expect(find.text('Luna llena'), findsOneWidget);

      // Estado y Etapa de Vida viven en la pestaña Datos
      expect(find.text('Etapa de Vida'), findsOneWidget);
      expect(find.text('Combate'), findsOneWidget);
      await elegir(tester, 'Macho', 'Hembra');
      expect(find.text('Editar Gallina / Hembra'), findsOneWidget);
      expect(find.text('Combate'), findsNothing);
      expect(find.text('Cría'), findsOneWidget);
    });

    testWidgets('registro antiguo con etapa legada abre sin errores', (tester) async {
      final hembra = Gallo(
        id: 'g2', placa: 'ARGOLLA AZUL PATA DERECHA', nombre: 'Perla', sexo: 'Hembra', fechaNacimiento: DateTime(2023),
        lineaGenetica: 'Hatch', colorPluma: 'Cenizo', faseLunar: 'Eclipse', estado: 'Activo', etapaVida: 'Levante',
      );
      await abrirFormulario(tester, galloEditar: hembra);
      expect(tester.takeException(), isNull);
      expect(find.text('Eclipse'), findsOneWidget);
      expect(find.text('Levante'), findsOneWidget);
    });

    testWidgets('peso bloquea letras/signos y Color Pluma manual bloquea números', (tester) async {
      await abrirFormulario(tester);
      final peso = find.byKey(const Key('campo-peso-actual'));
      await tester.enterText(peso, '-abc');
      expect(tester.widget<TextFormField>(peso).controller!.text, '');
      await tester.enterText(peso, '12.5');
      expect(tester.widget<TextFormField>(peso).controller!.text, '12.5');

      await elegir(tester, 'Color Pluma *', '➕ Otro (Escribir manualmente...)');
      final color = find.byKey(const Key('color-manual'));
      expect(color, findsOneWidget);
      await tester.enterText(color, 'Giro123');
      expect(tester.widget<TextFormField>(color).controller!.text, 'Giro');

      await tester.tap(find.byKey(const Key('color-volver-lista')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('color-manual')), findsNothing);
    });

    testWidgets('Línea/Color solo muestran el catálogo corto, sin histórico del proveedor', (tester) async {
      final otro = galloCompleto(id: 'otro', placa: 'Z9').copyWithLineaColor('Linea Sucia Vieja', 'Color Raro');
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<GallosProveedor>(
        create: (_) => GallosProveedor.enMemoria([otro]),
        child: const MaterialApp(home: PantallaFormularioGallo()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Línea Genética *'));
      await tester.pumpAndSettle();
      for (final l in ['Kelso', 'Hatch', 'Sweater', 'Albany', 'Claret', '➕ Otro (Escribir manualmente...)']) {
        expect(find.text(l), findsWidgets);
      }
      expect(find.text('Linea Sucia Vieja'), findsNothing);
      expect(find.text('Asil'), findsNothing);
      await tester.tap(find.text('Kelso').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Color Pluma *'));
      await tester.pumpAndSettle();
      expect(find.text('Cenizo'), findsWidgets);
      expect(find.text('Color Raro'), findsNothing);
      expect(find.text('Jabao'), findsNothing);
    });

    testWidgets('edición: un valor guardado fuera del catálogo se conserva en el desplegable', (tester) async {
      final legado = galloCompleto().copyWithLineaColor('¡Radio Viejo!', 'Jabao');
      await abrirFormulario(tester, galloEditar: legado);
      expect(tester.takeException(), isNull);
      expect(find.text('¡Radio Viejo!'), findsOneWidget);
      expect(find.text('Jabao'), findsOneWidget);
    });

    testWidgets('Línea Genética manual bloquea comillas y símbolos raros', (tester) async {
      await abrirFormulario(tester);
      await elegir(tester, 'Línea Genética *', '➕ Otro (Escribir manualmente...)');
      final linea = find.byKey(const Key('linea-manual'));
      await tester.enterText(linea, 'F1 "Hatch"! 50%');
      expect(tester.widget<TextFormField>(linea).controller!.text, 'F1 Hatch 50%');
    });

    testWidgets('enlace inválido bloquea el guardado y lleva a su pestaña', (tester) async {
      await abrirFormulario(tester, galloEditar: galloCompleto(videoUrl: 'hola'));
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      expect(find.text('Multimedia y Notas'), findsOneWidget);
      expect(find.text('Ingresa un enlace web válido que inicie con https:// o http://'), findsWidgets);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('confirmación: lista las secciones vacías y "No" lleva a la primera', (tester) async {
      await abrirFormulario(tester, galloEditar: galloCompleto());
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      expect(find.text('¿Guardar ejemplar?'), findsOneWidget);
      expect(
        find.text('¿Estás seguro de que quieres guardar sin haber completado o revisado la información '
            'en las secciones de Genealogía, Gestión y Finanzas?'),
        findsOneWidget,
      );
      await tester.tap(find.text('No, quiero seguir editando'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Padres en el Sistema'), findsOneWidget);
    });

    testWidgets('confirmación: solo menciona las secciones vacías y "Sí" continúa el guardado', (tester) async {
      await abrirFormulario(tester, galloEditar: galloCompleto(nombrePadre: 'Rayo', jaula: 'J-1'));
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Estás seguro de que quieres guardar sin haber completado o revisado la información '
            'en la sección de Finanzas?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Sí, estoy seguro, guardar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      // Sin Firebase en las pruebas, el intento de guardado termina en un SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('sin secciones vacías se guarda sin preguntar', (tester) async {
      await abrirFormulario(
        tester,
        galloEditar: galloCompleto(nombrePadre: 'Rayo', jaula: 'J-1', costo: 50000),
      );
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('botón de fecha visible en vacunas y peleas, y sin "/" en el texto', (tester) async {
      await abrirFormulario(tester);
      await irAGestion(tester);
      final hoy = DateFormat('dd/MM/yyyy').format(DateTime.now());
      expect(find.text('📅 Fecha: $hoy (Cambiar)'), findsNWidgets(2));
      expect(find.widgetWithText(OutlinedButton, '📅 Fecha: $hoy (Cambiar)'), findsNWidgets(2));
      final pelea = find.byKey(const Key('pelea-texto'));
      await tester.enterText(pelea, 'Ganó 12/03/2026');
      expect(tester.widget<TextFormField>(pelea).controller!.text, 'Ganó 12032026');
    });

    testWidgets('HU-04: agregar vacuna concatena la fecha seleccionada', (tester) async {
      await abrirFormulario(tester);
      await irAGestion(tester);
      await elegir(tester, 'Agregar Vacuna', 'Newcastle');
      await tester.tap(find.byKey(const Key('agregar-vacuna')));
      await tester.pumpAndSettle();
      final hoy = DateFormat('dd/MM/yyyy').format(DateTime.now());
      expect(find.text('Newcastle ($hoy)'), findsOneWidget);

      // Vacío: no se agrega nada (RN-07)
      await tester.tap(find.byKey(const Key('agregar-vacuna')));
      await tester.pumpAndSettle();
      expect(find.byType(Chip), findsOneWidget);
    });
  });

  testWidgets('TarjetaGallo muestra el botón "Ver ficha"', (tester) async {
    var abierto = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TarjetaGallo(
          gallo: Gallo(
            id: 'g3', placa: 'B2', nombre: 'Trueno', sexo: 'Macho', fechaNacimiento: DateTime(2024),
            lineaGenetica: 'Kelso', colorPluma: 'Giro', faseLunar: 'Luna llena', estado: 'Activo',
          ),
          onTap: () => abierto = true,
        ),
      ),
    ));
    expect(find.text('Ver ficha'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byKey(const Key('boton-ver-ficha')));
    expect(abierto, isTrue);
  });

  group('Ejemplares sin nombre (datos históricos)', () {
    test('nombreMostrar y etiquetaSelector nunca quedan en blanco', () {
      final sinNombre = galloCompleto(nombre: '   ', placa: 'P1');
      expect(sinNombre.nombreMostrar, 'Sin apodo (#P1)');
      expect(sinNombre.etiquetaSelector, 'Sin apodo (#P1) • Kelso');
      expect(galloCompleto(placa: 'A7', nombre: 'Rayo').etiquetaSelector, 'Rayo (#A7) • Kelso');
      expect(galloCompleto(placa: 'A7', linea: '').etiquetaSelector, 'Centella (#A7)');
      expect(galloCompleto(nombre: '', placa: 'P1', linea: '').etiquetaSelector, 'Sin apodo (#P1)');
      expect(galloCompleto(nombre: '', placa: '', linea: '').etiquetaSelector, 'Sin apodo (Sin placa)');
      expect(galloCompleto(nombre: '', placa: '').nombreMostrar, 'Sin apodo');
    });

    testWidgets('TarjetaGallo muestra "Sin apodo (#placa)" si el nombre está vacío', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TarjetaGallo(gallo: galloCompleto(nombre: '', placa: 'P1'), onTap: () {})),
      ));
      expect(find.text('Sin apodo (#P1)'), findsOneWidget);
    });
  });

  group('PantallaFormularioGallo: placa en tiempo real y obligatorios', () {
    Future<void> abrir(WidgetTester tester, List<Gallo> gallos, {Gallo? editar}) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<GallosProveedor>(
        create: (_) => GallosProveedor.enMemoria(gallos),
        child: MaterialApp(home: PantallaFormularioGallo(galloEditar: editar)),
      ));
      await tester.pumpAndSettle();
    }

    const duplicada = 'Esta placa ya está registrada en otro ejemplar de este criadero';

    testWidgets('detecta placa duplicada al escribir (sin distinguir mayúsculas/espacios)', (tester) async {
      await abrir(tester, [galloCompleto(id: 'g-a', placa: 'A-100')]);
      final placa = find.byKey(const Key('campo-placa'));
      await tester.enterText(placa, '  a-100 ');
      await tester.pump();
      expect(find.text(duplicada), findsOneWidget);
      expect(find.text('✓ Placa disponible'), findsNothing);

      await tester.enterText(placa, 'A-101');
      await tester.pump();
      expect(find.text(duplicada), findsNothing);
      expect(find.text('✓ Placa disponible'), findsOneWidget);
    });

    testWidgets('en edición conserva su propia placa sin marcarse como duplicada', (tester) async {
      final propio = galloCompleto(id: 'g-a', placa: 'A-100');
      await abrir(tester, [propio, galloCompleto(id: 'g-b', placa: 'B-200')], editar: propio);
      final placa = find.byKey(const Key('campo-placa'));
      await tester.enterText(placa, 'A-100');
      await tester.pump();
      expect(find.text(duplicada), findsNothing);
      expect(find.text('✓ Placa disponible'), findsOneWidget);

      await tester.enterText(placa, 'b-200');
      await tester.pump();
      expect(find.text(duplicada), findsOneWidget);
    });

    testWidgets('marca los obligatorios con * y muestra la nota', (tester) async {
      await abrir(tester, []);
      expect(find.text('* Campos obligatorios'), findsOneWidget);
      for (final label in [
        'Placa / Anillo *', 'Nombre *', 'Sexo *', 'Fecha de Nacimiento *',
        'Línea Genética *', 'Color Pluma *', 'Peso Actual (Lbs) *',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('nombre vacío muestra "Requerido" en tiempo real', (tester) async {
      await abrir(tester, []);
      final nombre = find.widgetWithText(TextFormField, 'Nombre *');
      await tester.enterText(nombre, 'Rayo');
      await tester.pump();
      await tester.enterText(nombre, '   ');
      await tester.pump();
      expect(find.text('Requerido'), findsOneWidget);
    });
  });

  group('PantallaFormularioCruce', () {
    Future<void> abrirCruce(WidgetTester tester, List<Gallo> gallos) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<GallosProveedor>(
        create: (_) => GallosProveedor.enMemoria(gallos),
        child: const MaterialApp(home: PantallaFormularioCruce()),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> escribir(WidgetTester tester, Finder campo, String texto) async {
      await tester.enterText(campo, texto);
      await tester.pump();
    }

    final nacidos = find.byKey(const Key('campo-nacidos'));
    final muertos = find.widgetWithText(TextFormField, 'Bajas / Muertos *');
    final machos = find.widgetWithText(TextFormField, 'Machos');
    final hembras = find.widgetWithText(TextFormField, 'Hembras');

    testWidgets('selectores de Padre/Madre muestran placa y "Sin apodo", nunca en blanco', (tester) async {
      await abrirCruce(tester, [
        galloCompleto(id: 'p1', placa: 'P1', nombre: ''),
        galloCompleto(id: 'p2', placa: 'P2', nombre: 'Rayo', linea: 'Hatch'),
        galloCompleto(id: 'm1', placa: 'M1', nombre: ' ', sexo: 'Hembra', linea: 'Sweater'),
      ]);
      await tester.tap(find.text('Padre (Padrote) *'));
      await tester.pumpAndSettle();
      expect(find.text('Sin apodo (#P1) • Kelso'), findsWidgets);
      expect(find.text('Rayo (#P2) • Hatch'), findsWidgets);
      final textos = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data?.trim());
      expect(textos.where((t) => t != null && t.isEmpty), isEmpty);
      await tester.tap(find.text('Sin apodo (#P1) • Kelso').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Madre (Madrilla) *'));
      await tester.pumpAndSettle();
      expect(find.text('Sin apodo (#M1) • Sweater'), findsWidgets);
    });

    testWidgets('error inmediato si hay más muertos que nacidos', (tester) async {
      await abrirCruce(tester, []);
      await escribir(tester, nacidos, '4');
      await escribir(tester, muertos, '5');
      expect(find.text('No puedes registrar más bajas (5) que los pollitos nacidos (4)'), findsOneWidget);
      expect(find.byKey(const Key('chip-vivos')), findsNothing);
      // Al corregir los nacidos, el error desaparece en tiempo real
      await escribir(tester, nacidos, '10');
      expect(find.textContaining('No puedes registrar más bajas'), findsNothing);
      expect(find.text('Pollitos vivos actuales: 5'), findsOneWidget);
    });

    testWidgets('error inmediato si machos + hembras superan a los vivos', (tester) async {
      await abrirCruce(tester, []);
      await escribir(tester, nacidos, '4');
      await escribir(tester, muertos, '1');
      await escribir(tester, machos, '2');
      await escribir(tester, hembras, '2');
      expect(find.text('La suma de machos y hembras (4) supera los pollitos vivos actuales (3)'), findsNWidgets(2));
      expect(find.byKey(const Key('chip-pendientes')), findsNothing);
      await escribir(tester, hembras, '1');
      expect(find.textContaining('La suma de machos y hembras'), findsNothing);
      expect(find.text('Pendientes por definir sexo: 0'), findsOneWidget);
    });

    testWidgets('0 machos y 0 hembras es válido (sexado diferido) y el resumen se calcula', (tester) async {
      await abrirCruce(tester, []);
      await escribir(tester, nacidos, '8');
      await escribir(tester, muertos, '2');
      await escribir(tester, machos, '0');
      await escribir(tester, hembras, '0');
      expect(find.textContaining('La suma de machos y hembras'), findsNothing);
      expect(find.text('Pollitos vivos actuales: 6'), findsOneWidget);
      expect(find.text('Pendientes por definir sexo: 6'), findsOneWidget);
      await escribir(tester, machos, '2');
      expect(find.text('Pendientes por definir sexo: 4'), findsOneWidget);
      expect(find.text('Clasificación por Sexo'), findsOneWidget);
      expect(find.textContaining('Sexado'), findsNothing);
    });

    testWidgets('obligatorios con * y etiquetas claras del marcaje de la camada', (tester) async {
      await abrirCruce(tester, []);
      expect(find.text('* Campos obligatorios'), findsOneWidget);
      for (final label in [
        'Padre (Padrote) *', 'Madre (Madrilla) *', 'Fecha del Cruce / Nacimiento *', 'Pollitos Nacidos *',
        'Marcaje e Identificación de la Camada (Pollitos)', 'Ubicación de la marca en los pollitos',
        'Detalle de placa, color de cintillo, marca del lote o placa/anillo',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final detalle = find.byKey(const Key('campo-detalle-marca'));
      final campo = tester.widget<TextField>(find.descendant(of: detalle, matching: find.byType(TextField)));
      expect(campo.maxLength, 80);
      expect(campo.decoration!.hintText, 'Ej: Cintillo verde, Placas #201 a #205, Marca en ala...');

      await escribir(tester, detalle, 'A' * 95);
      expect(tester.widget<TextFormField>(detalle).controller!.text.length, 80);
      await escribir(tester, detalle, 'Cintillo verde, Placas #201 a #205');
      expect(find.text(CruceModelo.mensajeDetalleMarcaInvalido), findsNothing);
      await escribir(tester, detalle, '#-');
      expect(find.text(CruceModelo.mensajeDetalleMarcaInvalido), findsOneWidget);
    });
  });

  group('CruceModelo.validarDetalleMarca', () {
    test('opcional, 3-80 caracteres y sin cadenas de solo símbolos', () {
      expect(CruceModelo.validarDetalleMarca(''), isNull);
      expect(CruceModelo.validarDetalleMarca('  '), isNull);
      expect(CruceModelo.validarDetalleMarca('Cintillo verde, Placas #201 a #205'), isNull);
      expect(CruceModelo.validarDetalleMarca('Ala-D.'), isNull);
      expect(CruceModelo.validarDetalleMarca('ab'), isNotNull);
      expect(CruceModelo.validarDetalleMarca('#-,.'), isNotNull);
      expect(CruceModelo.validarDetalleMarca('Marca "roja"!'), isNotNull);
      expect(CruceModelo.validarDetalleMarca('a' * 81), isNotNull);
    });
    test('mensajes humanos de RN-02', () {
      expect(
        CruceModelo.validarReglasNegocio(
            padreId: 'p', madreId: 'm', cantidadHuevos: 4, pollitosMuertos: 5, pollitosMachos: 0, pollitosHembras: 0),
        'No puedes registrar más bajas (5) que los pollitos nacidos (4)',
      );
      expect(
        CruceModelo.validarReglasNegocio(
            padreId: 'p', madreId: 'm', cantidadHuevos: 4, pollitosMuertos: 1, pollitosMachos: 2, pollitosHembras: 2),
        'La suma de machos y hembras (4) supera los pollitos vivos actuales (3)',
      );
    });
  });

  group('Responsive móvil (360x640)', () {
    final progenitores = [
      galloCompleto(id: 'p-rayo', placa: 'A7', nombre: 'Rayo'),
      galloCompleto(id: 'p-sin', placa: 'P1', nombre: ''),
      galloCompleto(id: 'm-perla', placa: 'H3', nombre: 'Perla', sexo: 'Hembra', linea: 'Hatch'),
    ];

    Future<void> pantallaMovil(WidgetTester tester, Widget pantalla, {Size tamano = const Size(360, 640)}) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<GallosProveedor>(
        create: (_) => GallosProveedor.enMemoria(progenitores),
        child: MaterialApp(home: pantalla),
      ));
      await tester.pumpAndSettle();
    }

    void expectDecoracionesMultilinea(WidgetTester tester) {
      final decoradores = tester.widgetList<InputDecorator>(find.byType(InputDecorator));
      expect(decoradores, isNotEmpty);
      for (final d in decoradores) {
        expect(d.decoration.hintMaxLines, greaterThanOrEqualTo(2));
        expect(d.decoration.errorMaxLines, greaterThanOrEqualTo(2));
      }
    }

    testWidgets('PantallaFormularioGallo: 4 pestañas sin overflow y textos multilínea', (tester) async {
      await pantallaMovil(tester, const PantallaFormularioGallo());
      expect(tester.takeException(), isNull);
      for (final tab in ['Datos', 'Genealogía', 'Gestión', 'Finanzas']) {
        expect(find.text(tab), findsOneWidget);
      }
      expectDecoracionesMultilinea(tester);

      // Línea Genética y Color Pluma se apilan a ancho completo en < 420 px
      await tester.dragUntilVisible(find.text('Color Pluma *'), find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      final linea = tester.getTopLeft(find.text('Línea Genética *'));
      final color = tester.getTopLeft(find.text('Color Pluma *'));
      expect(color.dy, greaterThan(linea.dy));

      for (final tab in ['Genealogía', 'Gestión', 'Finanzas']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
        expectDecoracionesMultilinea(tester);
      }
    });

    testWidgets('PantallaFormularioGallo: Genealogía muestra el nombre primero', (tester) async {
      await pantallaMovil(tester, const PantallaFormularioGallo());
      await tester.tap(find.text('Genealogía'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Padre (Macho)'));
      await tester.pumpAndSettle();
      expect(find.text('Rayo (#A7) • Kelso'), findsWidgets);
      expect(find.text('Sin apodo (#P1) • Kelso'), findsWidgets);
      await tester.tap(find.text('Rayo (#A7) • Kelso').last);
      await tester.pumpAndSettle();
      expect(find.text('Rayo (#A7) • Kelso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PantallaFormularioCruce: sin overflow, nombre primero y errores largos legibles', (tester) async {
      await pantallaMovil(tester, const PantallaFormularioCruce());
      expect(tester.takeException(), isNull);
      expectDecoracionesMultilinea(tester);

      await tester.tap(find.text('Padre (Padrote) *'));
      await tester.pumpAndSettle();
      expect(find.text('Rayo (#A7) • Kelso'), findsWidgets);
      expect(find.text('Sin apodo (#P1) • Kelso'), findsWidgets);
      await tester.tap(find.text('Sin apodo (#P1) • Kelso').last);
      await tester.pumpAndSettle();
      expect(find.text('Sin apodo (#P1) • Kelso'), findsOneWidget);

      await tester.tap(find.text('Madre (Madrilla) *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perla (#H3) • Hatch').last);
      await tester.pumpAndSettle();
      expect(find.text('Perla (#H3) • Hatch'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('campo-nacidos')), '4');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextFormField, 'Bajas / Muertos *'), '5');
      await tester.pump();
      expect(find.text('No puedes registrar más bajas (5) que los pollitos nacidos (4)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Fecha y Luna se apilan en < 420 px
      final fecha = tester.getTopLeft(find.text('Fecha del Cruce / Nacimiento *'));
      final luna = tester.getTopLeft(find.text('Luna'));
      expect(luna.dy, greaterThan(fecha.dy));
    });

    testWidgets('PantallaFormularioCruce en 320 px apila los pares numéricos', (tester) async {
      await pantallaMovil(tester, const PantallaFormularioCruce(), tamano: const Size(320, 640));
      expect(tester.takeException(), isNull);
      final nacidos = tester.getTopLeft(find.text('Pollitos Nacidos *'));
      final muertos = tester.getTopLeft(find.text('Bajas / Muertos *'));
      expect(muertos.dy, greaterThan(nacidos.dy));
      final machos = tester.getTopLeft(find.text('Machos'));
      final hembras = tester.getTopLeft(find.text('Hembras'));
      expect(hembras.dy, greaterThan(machos.dy));
    });

    testWidgets('Gestión en 320 px: botones de fecha sin overflow', (tester) async {
      await pantallaMovil(tester, const PantallaFormularioGallo(), tamano: const Size(320, 640));
      await tester.tap(find.text('Gestión'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('(Cambiar)'), findsOneWidget);
      // El de peleas está más abajo en la lista
      await tester.dragUntilVisible(find.text('Historial de Peleas'), find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.textContaining('(Cambiar)'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TarjetaGallo en 320 px: nombre largo en 2 líneas sin overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TarjetaGallo(
            gallo: galloCompleto(nombre: 'Relámpago Dorado del Valle Alto', placa: 'ARGOLLA AZUL 2024-77'),
            onTap: () {},
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      final nombre = tester.widget<Text>(find.text('Relámpago Dorado del Valle Alto'));
      expect(nombre.maxLines, 2);
    });
  });

  // ==================== BUG-18: RESPALDOS SIN DUPLICADOS ====================

  Gallo ejemplar(String id, {String placa = '', String nombre = '', String? padreId, String? madreId,
          List<String> vacunas = const []}) =>
      Gallo(
        id: id, userId: 'uidA', placa: placa, nombre: nombre, sexo: 'Macho', fechaNacimiento: DateTime(2024, 3, 1),
        lineaGenetica: 'Kelso', colorPluma: 'Giro', faseLunar: 'Luna llena', estado: 'Activo',
        pesoActual: 4.5, padreId: padreId, madreId: madreId, vacunas: vacunas,
      );

  CruceModelo cruce(String id, String padreId, String madreId) => CruceModelo(
        id: id, userId: 'uidA', padreId: padreId, nombrePadre: 'P', madreId: madreId, nombreMadre: 'M',
        fechaCruce: DateTime(2025, 1, 10), faseLunar: 'Luna llena', cantidadPollitos: 8, pollitosMuertos: 1,
        pollitosVivos: 7, pollitosMachos: 3, pollitosHembras: 2, pataMarca: 'Derecha', detalleMarca: 'Muesca 1',
      );

  String Function(String) generadorIds() {
    var n = 0;
    return (coleccion) => '$coleccion-nuevo-${++n}';
  }

  group('BUG-18: restauración JSON idempotente', () {
    test('no duplica los existentes (por id, placa o firma) y solo agrega el nuevo', () {
      final existentes = [
        ejemplar('g1', placa: 'A7', nombre: 'Rayo'),
        ejemplar('g2', placa: 'B2', nombre: 'Trueno'),
        ejemplar('g3', nombre: ''), // histórico sin placa ni nombre
      ];
      final proveedor = GallosProveedor.enMemoria(existentes);
      // Respaldo exportado: mismos ejemplares (uno con otro id y placa con
      // mayúsculas/espacios distintos) + 1 ejemplar nuevo hijo de Rayo.
      final json = [
        ejemplar('g1', placa: 'A7', nombre: 'Rayo').toMap(),
        ejemplar('viejo-2', placa: ' b2 ', nombre: 'Trueno').toMap(),
        ejemplar('viejo-3', nombre: '').toMap(),
        ejemplar('viejo-4', placa: 'P9', nombre: 'Prueba', padreId: 'g1').toMap(),
      ];
      final plan = proveedor.planificarImportacion(
        uid: 'uidA', crucesExistentes: const [], gallosJson: json, crucesJson: const [], generarId: generadorIds(),
      );
      expect(plan.gallosOmitidos, 3);
      expect(plan.gallosNuevos, hasLength(1));
      final nuevo = plan.gallosNuevos.single;
      expect(nuevo['placa'], 'P9');
      expect(nuevo['id'], 'gallos-nuevo-1');
      expect(nuevo['userId'], 'uidA');
      expect(nuevo['padreId'], 'g1');
      expect(plan.mensajeResultado,
          'Restauración completada: 1 registros nuevos agregados, 3 registros existentes omitidos para evitar duplicados.');
    });

    test('repetidos dentro del mismo archivo se insertan una sola vez y la genealogía apunta al insertado', () {
      final proveedor = GallosProveedor.enMemoria(const []);
      final plan = proveedor.planificarImportacion(
        uid: 'uidB',
        crucesExistentes: const [],
        gallosJson: [
          ejemplar('x1', placa: 'Z1', nombre: 'Uno').toMap(),
          ejemplar('x2', placa: 'z1', nombre: 'Uno copia').toMap(),
          ejemplar('x3', placa: 'Z3', nombre: 'Hijo', padreId: 'x2').toMap(),
        ],
        crucesJson: const [],
        generarId: generadorIds(),
      );
      expect(plan.gallosNuevos.map((g) => g['placa']), ['Z1', 'Z3']);
      expect(plan.gallosOmitidos, 1);
      expect(plan.gallosNuevos.last['padreId'], plan.gallosNuevos.first['id']);
      expect(plan.gallosNuevos.every((g) => g['userId'] == 'uidB'), isTrue);
    });

    test('cruces existentes se omiten por id o por firma (con padres re-vinculados)', () {
      final proveedor = GallosProveedor.enMemoria([ejemplar('p', placa: 'P'), ejemplar('m', placa: 'M')]);
      final plan = proveedor.planificarImportacion(
        uid: 'uidA',
        crucesExistentes: [cruce('c1', 'p', 'm')],
        gallosJson: [ejemplar('p-viejo', placa: 'P').toMap(), ejemplar('m-viejo', placa: 'M').toMap()],
        crucesJson: [
          cruce('c-viejo', 'p-viejo', 'm-viejo').toMap(), // misma firma que c1
          cruce('c1', 'p', 'm').toMap(), // mismo id
          (cruce('c-nuevo', 'p-viejo', 'm-viejo').toMap()..['cantidadPollitos'] = 10),
        ],
        generarId: generadorIds(),
      );
      expect(plan.gallosNuevos, isEmpty);
      expect(plan.crucesOmitidos, 2);
      expect(plan.crucesNuevos, hasLength(1));
      expect(plan.crucesNuevos.single['padreId'], 'p');
      expect(plan.crucesNuevos.single['madreId'], 'm');
      expect(plan.crucesNuevos.single['id'], 'cruces-nuevo-1');
    });
  });

  group('BUG-18: limpieza segura de duplicados', () {
    test('conserva 1 por grupo (placa y firma sin placa/nombre)', () {
      final proveedor = GallosProveedor.enMemoria([
        ejemplar('a1', placa: 'A7', nombre: 'Rayo'),
        ejemplar('a2', placa: ' a7 ', nombre: 'Rayo'),
        ejemplar('a3', placa: 'A7', nombre: ''),
        ejemplar('h1'),
        ejemplar('h2'),
        ejemplar('u1', placa: 'U1', nombre: 'Único'),
      ]);
      final plan = proveedor.planificarLimpiezaDuplicados(const []);
      expect(plan.copias, 3);
      expect(plan.unicos, 3);
      expect(plan.idsGallosEliminar, isNot(contains('u1')));
      expect(plan.mensajeConfirmacion, contains('• Ejemplares únicos originales a conservar: 3'));
      expect(plan.mensajeConfirmacion, contains('• Copias duplicadas detectadas para eliminar: 3'));
    });

    test('siempre conserva el id referenciado en un cruce y re-vincula las referencias a copias', () async {
      final proveedor = GallosProveedor.enMemoria([
        // La copia tiene más datos, pero el original es padre en un cruce
        ejemplar('copia', placa: 'A7', nombre: 'Rayo', vacunas: ['Newcastle (01/01/2025)']),
        ejemplar('original', placa: 'A7', nombre: 'Rayo'),
        ejemplar('madre', placa: 'M1', nombre: 'Luna'),
        ejemplar('hijo', placa: 'H1', nombre: 'Hijo', padreId: 'copia', madreId: 'madre'),
        ejemplar('hijo2', placa: 'H2', nombre: 'Hijo 2', padreId: 'original'),
      ]);
      final cruces = [
        cruce('c1', 'original', 'madre'),
        cruce('c2', 'copia', 'madre'), // copia de c1 creada por la restauración
        CruceModelo.fromMap(cruce('c3', 'original', 'madre').toMap()..['cantidadPollitos'] = 12),
      ];
      final plan = proveedor.planificarLimpiezaDuplicados(cruces);
      // Ambos están referenciados; gana el de más vínculos aunque tenga menos datos
      expect(plan.idsGallosEliminar, ['copia']);
      expect(plan.reemplazos, {'copia': 'original'});
      expect(plan.gallosRevincular, {'hijo': {'padreId': 'original'}});
      // c2 apuntaba a la copia: es el mismo cruce que c1 y se elimina
      expect(plan.idsCrucesEliminar, ['c2']);

      await proveedor.ejecutarLimpiezaDuplicados(plan);
      expect(proveedor.gallos.map((g) => g.id), ['original', 'madre', 'hijo', 'hijo2']);
      expect(proveedor.obtenerGalloPorId('hijo')!.padreId, 'original');
    });

    test('referenciado solo como padre de otro gallo gana aunque tenga menos datos', () {
      final proveedor = GallosProveedor.enMemoria([
        ejemplar('rico', placa: 'B1', vacunas: ['Marek (02/02/2025)', 'Gumboro (03/03/2025)']),
        ejemplar('vinculado', placa: 'b1'),
        ejemplar('cria', placa: 'C1', madreId: 'vinculado'),
      ]);
      final plan = proveedor.planificarLimpiezaDuplicados(const []);
      expect(plan.idsGallosEliminar, ['rico']);
    });

    test('rechaza planes con ejemplares que no son del criadero activo', () {
      final proveedor = GallosProveedor.enMemoria([ejemplar('a', placa: 'A')]);
      final ajeno = Deduplicacion.planificarLimpieza(
        gallos: [ejemplar('otro1', placa: 'X'), ejemplar('otro2', placa: 'X')],
        cruces: const [],
      );
      expect(() => proveedor.ejecutarLimpiezaDuplicados(ajeno), throwsException);
      expect(proveedor.gallos, hasLength(1));
    });

    Future<GallosProveedor> pantallaLimpieza(WidgetTester tester, List<Gallo> gallos,
        {List<CruceModelo> cruces = const []}) async {
      final proveedor = GallosProveedor.enMemoria(gallos);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BotonLimpiarDuplicados(
            diagnosticar: () async => proveedor.planificarLimpiezaDuplicados(cruces),
            ejecutar: proveedor.ejecutarLimpiezaDuplicados,
          ),
        ),
      ));
      await tester.tap(find.text('🧹 Limpiar registros duplicados'));
      await tester.pumpAndSettle();
      return proveedor;
    }

    testWidgets('botón sin duplicados: mensaje informativo y sin diálogo', (tester) async {
      await pantallaLimpieza(tester, [ejemplar('a', placa: 'A'), ejemplar('b', placa: 'B')]);
      expect(find.text('No se encontraron registros duplicados en este criadero.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('botón: vista previa, "Cancelar" no borra nada', (tester) async {
      final proveedor = await pantallaLimpieza(tester, [ejemplar('a', placa: 'A'), ejemplar('b', placa: 'A')]);
      expect(find.text('Confirmar limpieza de duplicados'), findsOneWidget);
      expect(find.textContaining('• Copias duplicadas detectadas para eliminar: 1'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(proveedor.gallos, hasLength(2));
    });

    testWidgets('botón: "Sí, eliminar duplicados" conserva el referenciado y confirma', (tester) async {
      final proveedor = await pantallaLimpieza(
        tester,
        [
          ejemplar('copia1', placa: 'A7', nombre: 'Rayo'),
          ejemplar('padre', placa: 'A7', nombre: 'Rayo'),
          ejemplar('copia2', placa: 'a7', nombre: ''),
          ejemplar('madre', placa: 'M1', nombre: 'Luna'),
        ],
        cruces: [cruce('c1', 'padre', 'madre')],
      );
      expect(find.textContaining('• Ejemplares únicos originales a conservar: 2'), findsOneWidget);
      expect(find.textContaining('¿Deseas eliminar las 2 copias duplicadas?'), findsOneWidget);
      await tester.tap(find.text('Sí, eliminar duplicados'));
      await tester.pumpAndSettle();
      expect(find.text('Limpieza completada: se eliminaron 2 copias duplicadas. Quedaron 2 ejemplares únicos.'),
          findsOneWidget);
      expect(proveedor.gallos.map((g) => g.id), unorderedEquals(['padre', 'madre']));
    });
  });

  // ==================== FOTOS: CÁMARA / GALERÍA ====================

  group('Selector de foto (cámara y galería)', () {
    // PNG válido de 1x1 px
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

    late List<ImageSource> origenes;
    Future<XFile?> falso(ImageSource origen) async {
      origenes.add(origen);
      return XFile.fromData(png, name: 'foto.png', mimeType: 'image/png');
    }

    setUp(() => origenes = []);

    Future<void> abrirGallo(WidgetTester tester, {Gallo? editar, SeleccionarImagen? seleccionar}) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<GallosProveedor>(
        create: (_) => GallosProveedor.enMemoria([if (editar != null) editar]),
        child: MaterialApp(
          home: PantallaFormularioGallo(galloEditar: editar, seleccionarImagen: seleccionar ?? falso),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> tocar(WidgetTester tester, Finder objetivo) async {
      await tester.ensureVisible(objetivo);
      await tester.tap(objetivo);
      await tester.pumpAndSettle();
    }

    final selector = find.byKey(const Key('selector-foto'));
    final miniatura = find.descendant(of: selector, matching: find.byType(Container));
    bool hayVistaPrevia(WidgetTester tester) =>
        (tester.widget<Container>(miniatura).decoration as BoxDecoration).image != null;

    testWidgets('muestra Cámara, Galería y Cancelar; Cancelar no altera la foto', (tester) async {
      await abrirGallo(tester);
      await tocar(tester, selector);
      expect(find.text('Tomar foto (Cámara)'), findsOneWidget);
      expect(find.text('Seleccionar de la galería'), findsOneWidget);
      await tocar(tester, find.text('Cancelar'));
      expect(origenes, isEmpty);
      expect(find.text('Tocar para agregar foto'), findsOneWidget);
      expect(find.text('Quitar foto'), findsNothing);
    });

    testWidgets('elegir de la galería muestra la vista previa y "Quitar foto" la limpia', (tester) async {
      await abrirGallo(tester);
      await tocar(tester, selector);
      await tocar(tester, find.text('Seleccionar de la galería'));
      expect(origenes, [ImageSource.gallery]);
      expect(hayVistaPrevia(tester), isTrue);
      expect(find.text('Cambiar foto'), findsOneWidget);

      await tocar(tester, find.text('Quitar foto'));
      expect(find.text('¿Deseas quitar la fotografía?'), findsOneWidget);
      await tocar(tester, find.widgetWithText(TextButton, 'Quitar'));
      expect(hayVistaPrevia(tester), isFalse);
      expect(find.text('Tocar para agregar foto'), findsOneWidget);
      expect(find.text('Quitar foto'), findsNothing);
    });

    testWidgets('"Cambiar foto" vuelve a ofrecer el origen y usa la cámara', (tester) async {
      await abrirGallo(tester);
      await tocar(tester, selector);
      await tocar(tester, find.text('Seleccionar de la galería'));
      await tocar(tester, find.text('Cambiar foto'));
      await tocar(tester, find.text('Tomar foto (Cámara)'));
      expect(origenes, [ImageSource.gallery, ImageSource.camera]);
      expect(hayVistaPrevia(tester), isTrue);
    });

    testWidgets('edición: la foto guardada se puede quitar; cancelar la confirmación la conserva', (tester) async {
      final guardado = Gallo.fromMap(galloCompleto().toMap()..['fotoPath'] = '$prefijoFotoBase64${base64Encode(png)}');
      await abrirGallo(tester, editar: guardado);
      expect(hayVistaPrevia(tester), isTrue);
      await tocar(tester, find.text('Quitar foto'));
      await tocar(tester, find.widgetWithText(TextButton, 'Cancelar'));
      expect(hayVistaPrevia(tester), isTrue);
      await tocar(tester, find.text('Quitar foto'));
      await tocar(tester, find.widgetWithText(TextButton, 'Quitar'));
      expect(hayVistaPrevia(tester), isFalse);
    });

    testWidgets('permiso denegado: no crashea, avisa y deja la foto igual', (tester) async {
      await abrirGallo(tester,
          seleccionar: (_) async => throw PlatformException(code: 'camera_access_denied'));
      await tocar(tester, selector);
      await tocar(tester, find.text('Tomar foto (Cámara)'));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('No se pudo abrir la cámara'), findsOneWidget);
      expect(find.text('Tocar para agregar foto'), findsOneWidget);
    });

    testWidgets('formulario de cruce: galería, vista previa y quitar', (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ChangeNotifierProvider<GallosProveedor>(
        create: (_) => GallosProveedor.enMemoria(const []),
        child: MaterialApp(home: PantallaFormularioCruce(seleccionarImagen: falso)),
      ));
      await tester.pumpAndSettle();
      await tocar(tester, selector);
      expect(find.text('Tomar foto (Cámara)'), findsOneWidget);
      await tocar(tester, find.text('Seleccionar de la galería'));
      expect(hayVistaPrevia(tester), isTrue);
      await tocar(tester, find.text('Quitar foto'));
      await tocar(tester, find.widgetWithText(TextButton, 'Quitar'));
      expect(hayVistaPrevia(tester), isFalse);
      expect(find.text('Quitar foto'), findsNothing);
    });
  });
}
