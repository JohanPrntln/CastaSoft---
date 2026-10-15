import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Componente IconoAdaptativo - Renderiza `IconData` (Material) o `FaIconData`
/// (FontAwesome 11) con la misma caja y centrado.
///
/// `FaIcon` elimina a propósito el `SizedBox` + `Center` que sí trae `Icon`,
/// por eso los glifos de FontAwesome quedan desalineados dentro de
/// `InputDecoration.prefixIcon`. Este widget les devuelve una caja cuadrada
/// del tamaño del ícono con el glifo centrado.
///
/// En Flutter 3.47.5 `IconData` es `final class`, así que el parámetro se
/// recibe como `dynamic` y se renderiza condicionalmente (ver CLAUDE.md).
///
/// Uso:
/// ```dart
/// IconoAdaptativo(FontAwesomeIcons.tag, size: 18)
/// InputDecoration(prefixIcon: IconoAdaptativo.prefijo(Icons.search))
/// ```
class IconoAdaptativo extends StatelessWidget {
  /// `IconData` o `FaIconData`.
  final dynamic icono;
  final double size;
  final Color? color;

  /// Ancho de la caja exterior. `null` = caja del mismo tamaño del ícono.
  final double? anchoCaja;

  const IconoAdaptativo(this.icono, {super.key, this.size = 18, this.color})
      : anchoCaja = null;

  /// Variante para `prefixIcon` / `suffixIcon`: reserva el ancho estándar de
  /// Material (48 px) y centra el glifo en ambos ejes.
  const IconoAdaptativo.prefijo(this.icono, {super.key, this.size = 18, this.color})
      : anchoCaja = 48;

  @override
  Widget build(BuildContext context) {
    assert(icono is IconData || icono is FaIconData,
        'IconoAdaptativo solo acepta IconData o FaIconData (recibido: ${icono.runtimeType})');

    final Widget glifo = icono is IconData
        ? Icon(icono as IconData, size: size, color: color)
        : FaIcon(icono as FaIconData, size: size, color: color);

    final Widget cuadrado = SizedBox(
      width: size,
      height: size,
      child: Center(child: glifo),
    );

    if (anchoCaja == null) return cuadrado;

    return SizedBox(
      width: anchoCaja,
      child: Center(heightFactor: 1, child: cuadrado),
    );
  }
}
