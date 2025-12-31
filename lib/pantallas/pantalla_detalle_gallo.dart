import 'package:url_launcher/url_launcher.dart'; // Para abrir links
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
// Importamos url_launcher para abrir videos (opcional, si no lo tienes no pasa nada, he puesto un manejo seguro)
// import 'package:url_launcher/url_launcher.dart'; 

class PantallaDetalleGallo extends StatelessWidget {
  final Gallo gallo;

  const PantallaDetalleGallo({Key? key, required this.gallo}) : super(key: key);

  // ================= UTILIDADES =================

  int _calcularEdadMeses(DateTime fechaNacimiento) {
    final dias = DateTime.now().difference(fechaNacimiento).inDays;
    return (dias / 30).floor();
  }

  String _fmtFecha(DateTime fecha) => '${fecha.day}/${fecha.month}/${fecha.year}';

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Activo': return const Color(0xFF10B981); // Verde
      case 'Vendido': return const Color(0xFF6366F1); // Azul Indigo
      case 'Baja': return const Color(0xFFEF4444); // Rojo
      case 'Retirado': return const Color(0xFFF59E0B); // Ambar
      default: return Colors.grey;
    }
  }

  // ================= UI PRINCIPAL =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Fondo gris muy suave
      appBar: AppBar(
        title: Text(gallo.nombre, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => Navigator.pop(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 10), Text('Editar')])),
              const PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 10), Text('Eliminar', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEncabezado(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildResumenRapido(),
                  const SizedBox(height: 16),
                  _buildSeccionGenealogia(context),
                  const SizedBox(height: 16),
                  _buildSeccionSaludYCombate(),
                  const SizedBox(height: 16),
                  _buildSeccionFinanzasYExtra(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. ENCABEZADO CON FOTO Y ESTADO
  Widget _buildEncabezado(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          Hero(
            tag: gallo.id,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: gallo.fotoPath != null ? FileImage(File(gallo.fotoPath!)) : null,
                child: gallo.fotoPath == null 
                  ? const Icon(FontAwesomeIcons.kiwiBird, size: 50, color: Colors.grey) 
                  : null,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            gallo.placa, 
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16, letterSpacing: 1.2)
          ),
          Text(
            gallo.nombre, 
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _colorEstado(gallo.estado),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              gallo.estado.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 2. TARJETAS DE RESUMEN (EDAD, PESO, SEXO)
  Widget _buildResumenRapido() {
    return Row(
      children: [
        _datoCard(FontAwesomeIcons.calendar, '${_calcularEdadMeses(gallo.fechaNacimiento)} Meses', 'Edad'),
        const SizedBox(width: 10),
        // CORRECCIÓN AQUÍ: Usamos pesoActual en lugar de peso
        _datoCard(FontAwesomeIcons.weightScale, '${gallo.pesoActual ?? "--"} Kg', 'Peso'),
        const SizedBox(width: 10),
        _datoCard(gallo.sexo == 'Macho' ? FontAwesomeIcons.mars : FontAwesomeIcons.venus, gallo.sexo, 'Sexo'),
      ],
    );
  }

  // 3. GENEALOGÍA (ÁRBOL VISUAL)
  Widget _buildSeccionGenealogia(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('Genealogía', FontAwesomeIcons.sitemap),
            const SizedBox(height: 15),
            // Línea Paterna
            _filaPariente('Padre', _obtenerNombrePadre(context), FontAwesomeIcons.mars, Colors.blue),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 5),
              child: Column(
                children: [
                   _textoAbuelo('Abuelo P: ${gallo.nombreAbueloPaterno ?? "No reg."}'),
                   _textoAbuelo('Abuela P: ${gallo.nombreAbuelaPaterna ?? "No reg."}'),
                ],
              ),
            ),
            const Divider(height: 20),
            // Línea Materna
            _filaPariente('Madre', _obtenerNombreMadre(context), FontAwesomeIcons.venus, Colors.pink),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 5),
              child: Column(
                children: [
                   _textoAbuelo('Abuelo M: ${gallo.nombreAbueloMaterno ?? "No reg."}'),
                   _textoAbuelo('Abuela M: ${gallo.nombreAbuelaMaterna ?? "No reg."}'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _infoFila('Línea Genética', gallo.lineaGenetica),
            _infoFila('Color Pluma', gallo.colorPluma),
          ],
        ),
      ),
    );
  }

  // 4. SALUD Y COMBATE (VACUNAS Y PELEAS)
  Widget _buildSeccionSaludYCombate() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('Salud y Combate', FontAwesomeIcons.heartPulse),
            const SizedBox(height: 15),
            _infoFila('Etapa Vida', gallo.etapaVida),
            _infoFila('Tipo Cresta', gallo.tipoCresta),
            _infoFila('Peso Combate', '${gallo.pesoCombate ?? "--"} Kg'),
            const Divider(),
            const Text('Vacunas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            if (gallo.vacunas.isEmpty) const Text('Sin registro', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ...gallo.vacunas.map((v) => Text('• $v', style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 10),
            const Text('Récord Peleas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
             if (gallo.peleas.isEmpty) const Text('Sin registro', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ...gallo.peleas.map((p) => Text('⚔️ $p', style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  // 5. FINANZAS Y EXTRA (CON VIDEO)
  
  
  Widget _buildSeccionFinanzasYExtra(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('Información Extra', FontAwesomeIcons.circleInfo),
            const SizedBox(height: 15),
            _infoFila('Criadero Origen', gallo.criaderoOrigen),
            _infoFila('Fase Lunar Nac.', gallo.faseLunar),
            _infoFila('Jaula / Ubic.', gallo.jaula ?? 'No asignada'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _datoFinanciero('Costo', gallo.costoAdquisicion, Colors.red.shade700),
                _datoFinanciero('Venta', gallo.precioVenta, Colors.green.shade700),
              ],
            ),
            
            // === BOTÓN DE VIDEO ===
            if (gallo.videoUrl != null && gallo.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String urlString = gallo.videoUrl!;
                    
                    // Corrección automática de link
                    if (!urlString.startsWith('http')) {
                      urlString = 'https://$urlString'; 
                    }

                    final Uri url = Uri.parse(urlString);
                    
                    try {
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        throw 'No se pudo lanzar';
                      }
                    } catch (e) {
                      // AHORA SÍ FUNCIONARÁ PORQUE YA TENEMOS EL CONTEXT
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo abrir el video: $urlString')),
                        );
                      }
                    }
                  },
                  icon: const Icon(FontAwesomeIcons.youtube, color: Colors.white),
                  label: const Text('Ver Video del Gallo', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],

            if (gallo.notas != null && gallo.notas!.isNotEmpty) ...[
              const Divider(height: 30),
              const Text('Notas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(gallo.notas!, style: const TextStyle(color: Colors.black87, height: 1.4)),
            ]
          ],
        ),
      ),
    );
  }
  // ================= WIDGETS AUXILIARES =================

  Widget _datoCard(IconData icon, String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
            const SizedBox(height: 5),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _tituloSeccion(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 18, color: const Color(0xFFD4AF37)), // Dorado
        const SizedBox(width: 8),
        Text(titulo, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _infoFila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _filaPariente(String rol, String nombre, IconData icono, Color colorIcono) {
    return Row(
      children: [
        CircleAvatar(radius: 12, backgroundColor: colorIcono.withOpacity(0.1), child: Icon(icono, size: 14, color: colorIcono)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rol, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _textoAbuelo(String texto) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(texto, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }

  Widget _datoFinanciero(String label, double? monto, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          monto != null ? '\$${monto.toStringAsFixed(0)}' : '--',
          style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // Métodos de ayuda para nombres de padres (igual que tenías pero más limpio)
  String _obtenerNombrePadre(BuildContext context) {
    // 1. Si hay nombre en texto (lo nuevo), usalo.
    if (gallo.nombrePadre != null && gallo.nombrePadre!.isNotEmpty) return gallo.nombrePadre!;
    
    // 2. Si no, busca por ID en la base de datos
    final padreId = gallo.padreId ?? gallo.idPadre;
    if (padreId == null) return 'Desconocido';

    try {
      final padre = context.read<GallosProveedor>().obtenerGalloPorId(padreId);
      return padre?.nombre ?? 'Desconocido';
    } catch (_) { return 'Desconocido'; }
  }

  String _obtenerNombreMadre(BuildContext context) {
    if (gallo.nombreMadre != null && gallo.nombreMadre!.isNotEmpty) return gallo.nombreMadre!;
    
    final madreId = gallo.madreId ?? gallo.idMadre;
    if (madreId == null) return 'Desconocido';

    try {
      final madre = context.read<GallosProveedor>().obtenerGalloPorId(madreId);
      return madre?.nombre ?? 'Desconocido';
    } catch (_) { return 'Desconocido'; }
  }
}
