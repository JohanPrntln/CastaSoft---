import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:castasoft/proveedores/cruces_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_formulario_cruce.dart';
import 'package:castasoft/pantallas/pantalla_detalle_cruce.dart';

class PantallaListaCruces extends StatefulWidget {
  const PantallaListaCruces({Key? key}) : super(key: key);

  @override
  State<PantallaListaCruces> createState() => _PantallaListaCrucesState();
}

class _PantallaListaCrucesState extends State<PantallaListaCruces> {
  final Color _colorTema = const Color(0xFF059669);
  final TextEditingController _buscarCtrl = TextEditingController();
  String _filtroTexto = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrucesProveedor>().cargarCruces();
    });
  }

  // 🔥 FUNCIÓN PARA EXPANDIR LA FOTO (ZOOM)
  void _mostrarImagenGrande(BuildContext context, String base64String) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9), // Fondo oscuro
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer( // Permite hacer zoom con los dedos
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
    final todosLosCruces = context.watch<CrucesProveedor>().cruces;
    final cargando = context.watch<CrucesProveedor>().cargando;

    final crucesFiltrados = todosLosCruces.where((c) {
      final texto = _filtroTexto.toLowerCase();
      return c.nombrePadre.toLowerCase().contains(texto) ||
             c.nombreMadre.toLowerCase().contains(texto) ||
             c.detalleMarca.toLowerCase().contains(texto);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Historial de Genética'),
        backgroundColor: _colorTema,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _buscarCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por padres o marca...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              onChanged: (val) => setState(() => _filtroTexto = val),
            ),
          ),

          Expanded(
            child: cargando 
              ? Center(child: CircularProgressIndicator(color: _colorTema))
              : crucesFiltrados.isEmpty 
                ? _buildVacio()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: crucesFiltrados.length,
                    itemBuilder: (ctx, i) {
                      final c = crucesFiltrados[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleCruce(cruce: c)));
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // 🔥 FOTO CON ZOOM AL TOCAR 🔥
                                    GestureDetector(
                                      onTap: () {
                                        if (c.fotoPath != null && c.fotoPath!.startsWith('base64')) {
                                          _mostrarImagenGrande(context, c.fotoPath!.split(',').last);
                                        }
                                      },
                                      child: Container(
                                        width: 60, height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: c.fotoPath != null && c.fotoPath!.startsWith('base64')
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(base64Decode(c.fotoPath!.split(',').last), fit: BoxFit.cover),
                                            )
                                          : Icon(FontAwesomeIcons.egg, color: _colorTema),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${c.cantidadPollitos} Nacidos', 
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: _colorTema)
                                          ),
                                          Text('${c.nombrePadre} x ${c.nombreMadre}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                          Text(DateFormat('dd MMM yyyy').format(c.fechaCruce), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _colorTema,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFormularioCruce()));
        },
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.dna, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text('No se encontraron cruces', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}