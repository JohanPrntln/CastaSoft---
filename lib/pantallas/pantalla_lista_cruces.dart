import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:castasoft/proveedores/cruces_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_formulario_cruce.dart';
import 'package:castasoft/pantallas/pantalla_detalle_cruce.dart';

class PantallaListaCruces extends StatefulWidget {
  const PantallaListaCruces({super.key});

  @override
  State<PantallaListaCruces> createState() => _PantallaListaCrucesState();
}

class _PantallaListaCrucesState extends State<PantallaListaCruces> {
  final Color _colorTema = const Color(0xFF059669);
  final TextEditingController _buscarCtrl = TextEditingController();
  String _filtroTexto = '';
  
  // Variable para controlar el chip activo
  bool _ordenMasReciente = true; // True = Recientes, False = Antiguos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrucesProveedor>().cargarCruces();
    });
  }

  void _mostrarImagenGrande(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true, minScale: 0.5, maxScale: 4,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(ctx)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, String id, String titulo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Cruce?'),
        content: Text('Se borrará permanentemente el registro de "$titulo".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              // Se capturan antes del await (contexto asíncrono seguro)
              final crucesProv = context.read<CrucesProveedor>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                final confirmado = await crucesProv.eliminarCruce(id);
                messenger.showSnackBar(SnackBar(content: Text(confirmado
                    ? 'Cruce eliminado'
                    : 'Cruce eliminado sin conexión: se sincronizará al volver el internet')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            }, 
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todosLosCruces = context.watch<CrucesProveedor>().cruces;
    final cargando = context.watch<CrucesProveedor>().cargando;

    // 1. FILTRADO POR TEXTO
    var listaFinal = todosLosCruces.where((c) {
      final texto = _filtroTexto.toLowerCase();
      return c.nombrePadre.toLowerCase().contains(texto) ||
             c.nombreMadre.toLowerCase().contains(texto) ||
             c.detalleMarca.toLowerCase().contains(texto);
    }).toList();

    // 2. ORDENAMIENTO
    listaFinal.sort((a, b) {
      if (_ordenMasReciente) {
        return b.fechaCruce.compareTo(a.fechaCruce); // Más recientes arriba
      } else {
        return a.fechaCruce.compareTo(b.fechaCruce); // Más antiguos arriba
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Historial de Genética'),
        backgroundColor: _colorTema,
      ),
      body: Column(
        children: [
          // TARJETA RESUMEN
          if (!cargando)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(color: _colorTema, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
              child: Column(
                children: [
                  const Text('Total Cruces Realizados', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('${listaFinal.length}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          const SizedBox(height: 15),

          // BUSCADOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _buscarCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por padres o marca...', prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              onChanged: (val) => setState(() => _filtroTexto = val),
            ),
          ),

          const SizedBox(height: 10),

          // FILTROS (CHIPS)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text("Ordenar por: ", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                _buildFilterChip('⬇️ Más Recientes', true),
                const SizedBox(width: 10),
                _buildFilterChip('⬆️ Más Antiguos', false),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LISTA
          Expanded(
            child: cargando 
              ? Center(child: CircularProgressIndicator(color: _colorTema))
              : listaFinal.isEmpty 
                ? _buildVacio()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
                    itemCount: listaFinal.length,
                    itemBuilder: (ctx, i) {
                      final c = listaFinal[i];
                      final fotoBytes = c.fotoBytes; // Memoizada en el modelo: O(1)
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaDetalleCruce(cruce: c))),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // FOTO
                                    GestureDetector(
                                      onTap: () {
                                        if (fotoBytes != null) _mostrarImagenGrande(context, fotoBytes);
                                      },
                                      child: Container(
                                        width: 70, height: 70,
                                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                                        child: fotoBytes != null
                                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(fotoBytes, fit: BoxFit.cover, gaplessPlayback: true))
                                          : FaIcon(FontAwesomeIcons.egg, color: _colorTema, size: 30),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    
                                    // INFO
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${c.nombrePadre.trim().isEmpty ? 'Sin apodo' : c.nombrePadre} x ${c.nombreMadre.trim().isEmpty ? 'Sin apodo' : c.nombreMadre}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Row(children: [FaIcon(FontAwesomeIcons.calendar, size: 12, color: Colors.grey.shade500), const SizedBox(width: 5), Text(DateFormat('dd MMM yyyy').format(c.fechaCruce), style: const TextStyle(color: Colors.grey, fontSize: 12))]),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6, runSpacing: 6,
                                            children: [
                                              _buildChip('${c.pollitosVivos} Vivos', Colors.green, FontAwesomeIcons.check),
                                              if (c.pollitosMachos > 0) _buildChip('${c.pollitosMachos} M', Colors.blue, FontAwesomeIcons.mars),
                                              if (c.pollitosHembras > 0) _buildChip('${c.pollitosHembras} H', Colors.pink, FontAwesomeIcons.venus),
                                              if (c.pollitosMuertos > 0) _buildChip('${c.pollitosMuertos} Bajas', Colors.red, FontAwesomeIcons.skull),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 25),
                                
                                // 🔥 BOTONES DE ACCIÓN (SOLO ICONOS PEQUEÑOS)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Botón Editar
                                    Tooltip(
                                      message: 'Editar Cruce',
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 22, color: Colors.blue),
                                        // visualDensity compact reduce el espacio extra alrededor del icono
                                        visualDensity: VisualDensity.compact, 
                                        onPressed: () {
                                           Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaFormularioCruce(cruceEditar: c)));
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 5), // Separación pequeña
                                    // Botón Eliminar
                                    Tooltip(
                                      message: 'Eliminar Cruce',
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, size: 22, color: Colors.red),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _confirmarEliminar(context, c.id, '${c.nombrePadre} x ${c.nombreMadre}'),
                                      ),
                                    ),
                                  ],
                                )
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaFormularioCruce())),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool esModoReciente) {
    bool estaSeleccionado = (_ordenMasReciente == esModoReciente);
    
    return ChoiceChip(
      label: Text(label),
      selected: estaSeleccionado,
      selectedColor: _colorTema.withValues(alpha: 0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: estaSeleccionado ? _colorTema : Colors.grey.shade700,
        fontWeight: FontWeight.bold
      ),
      side: BorderSide(
        color: estaSeleccionado ? _colorTema : Colors.grey.shade300,
      ),
      onSelected: (bool selected) {
        setState(() {
          _ordenMasReciente = esModoReciente;
        });
      },
    );
  }

  Widget _buildChip(String texto, Color color, dynamic icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // Actualizado a sintaxis moderna
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color.withValues(alpha: 0.3)) // Actualizado a sintaxis moderna
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AQUÍ ESTÁ LA SOLUCIÓN DEL ICONO
          icon is IconData 
              ? Icon(icon, size: 10, color: color)
              : FaIcon(icon, size: 10, color: color), 
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.dna, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text('No se encontraron cruces', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}