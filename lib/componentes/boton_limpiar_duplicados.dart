import 'package:flutter/material.dart';

import 'package:castasoft/servicios/deduplicacion.dart';

/// BUG-18: botón "🧹 Limpiar registros duplicados" con flujo en 2 pasos:
/// diagnóstico en memoria -> vista previa y confirmación -> eliminación.
class BotonLimpiarDuplicados extends StatefulWidget {
  /// Analiza el perfil activo sin borrar nada.
  final Future<PlanLimpieza> Function() diagnosticar;

  /// Elimina las copias del plan confirmado.
  final Future<void> Function(PlanLimpieza plan) ejecutar;

  final Color color;

  const BotonLimpiarDuplicados({
    super.key,
    required this.diagnosticar,
    required this.ejecutar,
    this.color = const Color(0xFF6D28D9),
  });

  @override
  State<BotonLimpiarDuplicados> createState() => _BotonLimpiarDuplicadosState();
}

class _BotonLimpiarDuplicadosState extends State<BotonLimpiarDuplicados> {
  bool _procesando = false;

  Future<void> _limpiar() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _procesando = true);
    try {
      // Paso 1: diagnóstico (no borra nada)
      final plan = await widget.diagnosticar();
      if (!mounted) return;
      if (plan.sinDuplicados) {
        messenger.showSnackBar(const SnackBar(
          content: Text('No se encontraron registros duplicados en este criadero.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      setState(() => _procesando = false); // sin spinner detrás del diálogo
      final confirmar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirmar limpieza de duplicados'),
              content: SingleChildScrollView(child: Text(plan.mensajeConfirmacion)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  child: const Text('Sí, eliminar duplicados', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmar) return;

      // Paso 2: eliminación segura
      if (!mounted) return;
      setState(() => _procesando = true);
      await widget.ejecutar(plan);
      messenger.showSnackBar(SnackBar(
        content: Text(plan.mensajeResultado, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: _procesando ? null : _limpiar,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _procesando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
                '🧹 Limpiar registros duplicados',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}
