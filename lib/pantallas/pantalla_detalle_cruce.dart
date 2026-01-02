import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:castasoft/modelos/cruce_modelo.dart';
import 'package:castasoft/proveedores/cruces_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_formulario_cruce.dart';

class PantallaDetalleCruce extends StatelessWidget {
  final CruceModelo cruce;

  const PantallaDetalleCruce({Key? key, required this.cruce}) : super(key: key);

  // 🔥 FUNCIÓN PARA EXPANDIR LA FOTO
  void _mostrarImagenGrande(BuildContext context, String base64String) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(base64Decode(base64String), fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTema = const Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Detalle de Camada', style: GoogleFonts.poppins()),
        backgroundColor: colorTema,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaFormularioCruce(cruceEditar: cruce),
                ),
              ).then((_) {
                context.read<CrucesProveedor>().cargarCruces();
                if (context.mounted) Navigator.pop(context);
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. FOTO GRANDE (CON ZOOM AL CLIC)
            GestureDetector(
              onTap: () {
                 if (cruce.fotoPath != null && cruce.fotoPath!.startsWith('base64')) {
                   _mostrarImagenGrande(context, cruce.fotoPath!.split(',').last);
                 }
              },
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  image: cruce.fotoPath != null && cruce.fotoPath!.startsWith('base64')
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(cruce.fotoPath!.split(',').last)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: cruce.fotoPath == null
                    ? Icon(Icons.camera_alt, size: 60, color: Colors.grey.shade500)
                    : null,
              ),
            ),

            // 2. INFORMACIÓN CLAVE
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cruce.nombrePadre} x ${cruce.nombreMadre}',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
                  ),
                  Text(
                    'Fecha: ${DateFormat('dd MMM yyyy').format(cruce.fechaCruce)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  // 3. TARJETA DE ESTADÍSTICAS
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Huevos/Nacidos', style: TextStyle(color: Colors.grey.shade600)),
                              Text('${cruce.cantidadPollitos}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          _buildBarraProgreso('Vivos', cruce.pollitosVivos, cruce.cantidadPollitos, Colors.green),
                          const SizedBox(height: 15),
                          _buildBarraProgreso('Bajas (Muertos)', cruce.pollitosMuertos, cruce.cantidadPollitos, Colors.red),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. DETALLES DE MARCA
                  _buildInfoCard(
                    'Identificación',
                    Icons.tag,
                    [
                      _filaInfo('Ubicación:', 'Pata ${cruce.pataMarca}'),
                      _filaInfo('Marca:', cruce.detalleMarca),
                      _filaInfo('Fase Lunar:', cruce.faseLunar),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. NOTAS
                  if (cruce.notas != null && cruce.notas!.isNotEmpty)
                    _buildInfoCard('Notas', Icons.note, [
                      Text(cruce.notas!, style: const TextStyle(height: 1.5)),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraProgreso(String label, int valor, int total, Color color) {
    double porcentaje = total == 0 ? 0 : valor / total;
    if (porcentaje < 0) porcentaje = 0;
    if (porcentaje > 1) porcentaje = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text('$valor', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: porcentaje,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(String titulo, IconData icono, List<Widget> hijos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: const Color(0xFF059669)),
              const SizedBox(width: 10),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(),
          ...hijos,
        ],
      ),
    );
  }

  Widget _filaInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
        ],
      ),
    );
  }
}