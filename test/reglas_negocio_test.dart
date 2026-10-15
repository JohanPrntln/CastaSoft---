import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:castasoft/componentes/icono_adaptativo.dart';
import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/modelos/foto_base64.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';

void main() {
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
}
