import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_drive_upload.dart';

class AIQOPSF005Screen extends StatefulWidget {
  const AIQOPSF005Screen({super.key});

  @override
  State<AIQOPSF005Screen> createState() => _AIQOPSF005ScreenState();
}

class _AIQOPSF005ScreenState extends State<AIQOPSF005Screen> {
  int _inspeccionSeleccionada = 1;
  TextEditingController fechaController = TextEditingController();
  TextEditingController horaController = TextEditingController();

  String estadoCercado = "Bueno";
  String estadoAccesos = "Bueno";
  String vigilanciaAccesos = "Bueno";
  String bitacoraAccesos = "Bueno";

  // Controlador para la firma
  final SignatureController enteradoFirmaController = SignatureController(penStrokeWidth: 2, penColor: Colors.black);

  // Controladores para nombre y fecha del enterado
  final TextEditingController enteradoNombreController = TextEditingController();
  final TextEditingController enteradoFechaController = TextEditingController();

  // Controlador para motivos de fallas (inciso c sección 4)
  final TextEditingController motivosFallasController = TextEditingController();

  // Nuevas variables agregadas
  String estadoComunicacionesA = "Bueno";
  String estadoComunicacionesB = "Sí";
  String estadoComunicacionesD = "Sí";
  String estadoVehiculosA = "Sí";

  final Map<String, List<XFile>> fotosPorSelector = {};

  PlatformFile? _pdfFile;

  int folio = 1;

  @override
  void initState() {
    super.initState();
    cargarFolio();
  }

  @override
  void dispose() {
    fechaController.dispose();
    horaController.dispose();
    enteradoFirmaController.dispose();
    enteradoNombreController.dispose();
    enteradoFechaController.dispose();
    motivosFallasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF263A5B), size: 32),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  // Encabezado
                  const Text(
                    "LISTA DE VERIFICACIÓN PARA PREVENIR INCURSIONES EN EL ÁREA DE MOVIMIENTO",
                    style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Avenir',
                                color: Color(0xFF263A5B)
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "AIQ-OPS-F005",
                    style: TextStyle(color: Color(0xFF598CBC), fontSize: 23, fontWeight: FontWeight.bold, fontFamily: 'Avenir'),
                  ),
                  const SizedBox(height: 16),

                  // Datos de la Inspección
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Datos de la Inspección",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Avenir',
                                color: Color(0xFF263A5B),
                              ),
                            ),
                            const Spacer(),
                            DropdownButton<int>(
                              value: _inspeccionSeleccionada,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text("1/2")),
                                DropdownMenuItem(value: 2, child: Text("2/2")),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _inspeccionSeleccionada = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: buildDateField("Fecha de la inspección", controller: fechaController, isTime: false),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: buildDateField("Hora Local", controller: horaController, isTime: true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sección 1: Geometría del Área de Movimiento (PDF Placeholder)
                  const Text(
                    "Sección 1. Geometría del Área de Movimiento.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      fontSize: 20,
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 1,
                            maxScale: 5,
                            child: Image.asset(
                              'assets/plano.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/plano.png',
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sección 2: Condición del Cercado Perimetral
                  const Text(
                    "Seccion 2.  Condición del Cercado Perimetral",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      fontSize: 20,
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const Text(
                    "(Indique el Área donde se detectaron Fallas en el plano Gral)",
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 12,
                      color: Color(0xFF263A5B),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "cercado",
                    label: "a) Estado físico del cercado perimetral.",
                    value: estadoCercado,
                    onChanged: (val) => setState(() => estadoCercado = val),
                  ),
                  const SizedBox(height: 16),

                  // Sección 3: Control de Accesos
                  const Text(
                    "Seccion 3.  Control de Accesos.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      fontSize: 20,
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "control_accesos_condicion",
                    label: "a) Condicion de Accesos.",
                    value: estadoAccesos,
                    onChanged: (val) => setState(() => estadoAccesos = val),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "vigilancia_accesos",
                    label: "b) Vigilancia en los Accesos",
                    value: vigilanciaAccesos,
                    onChanged: (val) => setState(() => vigilanciaAccesos = val),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "bitacora_accesos",
                    label: "c) Bitácora de Accesos.",
                    value: bitacoraAccesos,
                    onChanged: (val) => setState(() => bitacoraAccesos = val),
                  ),
                  const SizedBox(height: 8),
                  // Sección 4: Comunicaciones terrestres
                  const Text(
                    "Seccion 4.  Comunicaciones terrestres.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      fontSize: 20,
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "comunicacionesA",
                    label: "a) Condición del equipo de comunicaciones terrestres.",
                    value: estadoComunicacionesA,
                    onChanged: (val) => setState(() => estadoComunicacionesA = val),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "fallas_comunicacion_terrestre",
                    label: "b) Ha presentado fallas ultimamente la comunicación terrestre.",
                    value: estadoComunicacionesB,
                    onChanged: (val) => setState(() => estadoComunicacionesB = val),
                    soloSiNo: true, // Solo "Sí" y "No"
                  ),
                  const SizedBox(height: 8),
                  // c) Motivos de fallas en la comunicación terrestre
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "c) ¿Cuál es el principal motivo de las fallas?",
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: motivosFallasController,
                          decoration: InputDecoration(
                            hintText: "Describa el motivo...",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "comunicacionesD",
                    label: "d) Se ha recurrido a usar medios visuales para la comunicación.",
                    value: estadoComunicacionesD,
                    onChanged: (val) => setState(() => estadoComunicacionesD = val),
                    soloSiNo: true, // Solo "Sí" y "No"
                  ),
                  const SizedBox(height: 16),

                  // Sección 5: Comunicaciones y señales de vehículos en plataforma
                  const Text(
                    "Seccion 5.  Comunicaciones y señales de vehículos en plataforma.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      fontSize: 20,
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildEstadoSelector(
                    id: "vehiculos_area_operacional",
                    label: "a) Los vehículos que circulan en AREA OPERACIONAL cuentan con las características necesarias para circular en plataforma.",
                    value: estadoVehiculosA,
                    onChanged: (val) => setState(() => estadoVehiculosA = val),
                    soloSiNo: true, // Solo "Sí" y "No"
                  ),
                  const SizedBox(height: 8),
                  // b) TextField
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "b) ¿De qué empresa son estos vehículos que no cumplen?",
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Escriba la empresa...",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // c) TextField
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "c) ¿Cuál es el principal motivo de que no cumplan?",
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Describa el motivo...",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontFamily: 'Avenir'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // d) TextField
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "d) ¿Los conductores están capacitados para operar los vehículos?",
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Describa...",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontFamily: 'Avenir'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // e) TextField
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "e) ¿Se conocen las reglas para circular en el área de movimiento?",
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Describa...",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontFamily: 'Avenir'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Enterado Section
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Enterado",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextField(
                            controller: enteradoNombreController,
                            decoration: const InputDecoration(
                              labelText: "Nombre",
                              border: InputBorder.none, // Sin borde
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                enteradoFechaController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                controller: enteradoFechaController,
                                decoration: const InputDecoration(
                                  labelText: "Fecha",
                                  border: InputBorder.none, // Sin borde
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text("Firma:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Signature(
                            controller: enteradoFirmaController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () => enteradoFirmaController.clear(),
                          child: const Text("Limpiar firma"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      label: const Text("GUARDAR"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263A5B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: guardarFormularioF005,
                    ),
                  ),
                ],
              ),
            ),
            // Logo en la esquina inferior derecha
            Positioned(
              bottom: -5,
              right: 6,
              child: Image.asset(
                'assets/AIQ_LOGO_.png',
                width: 90, // Ajusta el tamaño si lo deseas
                height: 80, // Ajusta el tamaño si lo deseas
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, bottom: 2.0), // Ajusta aquí el espacio al borde
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FloatingActionButton(
                heroTag: 'share',
                backgroundColor: const Color(0xFF263A5B),
                child: const Icon(Icons.share, color: Colors.white),
                onPressed: compartirPDF,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDateField(String label, {required TextEditingController controller, bool isTime = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          icon: isTime ? const Icon(Icons.access_time) : const Icon(Icons.calendar_today),
          border: InputBorder.none,
        ),
        onTap: () async {
          if (isTime) {
            final TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (pickedTime != null) {
              setState(() {
                horaController.text = pickedTime.format(context);
              });
            }
          } else {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                fechaController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
              });
            }
          }
        },
      ),
    );
  }

  Widget buildEstadoSelector({
    required String id, // <--- NUEVO
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool soloSiNo = false,
  }) {
    TextEditingController obsController = TextEditingController();
    fotosPorSelector.putIfAbsent(id, () => []);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Avenir',
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF263A5B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: soloSiNo
                ? [
                    _buildChoiceChip("Sí", value, onChanged, color: const Color(0xFF3B5998)),
                    const SizedBox(width: 8),
                    _buildChoiceChip("No", value, onChanged, color: const Color.fromARGB(255, 185, 198, 221)),
                  ]
                : [
                    _buildChoiceChip("Bueno", value, onChanged, color: const Color(0xFF3B5998)),
                    const SizedBox(width: 8),
                    _buildChoiceChip("Regular", value, onChanged, color: const Color.fromARGB(255, 92, 129, 193)),
                    const SizedBox(width: 8),
                    _buildChoiceChip("Malo", value, onChanged, color: const Color.fromARGB(255, 185, 198, 221)),
                  ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: obsController,
                  decoration: InputDecoration(
                    hintText: "Observaciones...",
                    hintStyle: TextStyle(
                      color: Colors.grey[400], // Gris clarito
                      fontFamily: 'Avenir',
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    color: Color(0xFF263A5B), // Color normal para el texto escrito
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Color(0xFF263A5B)),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? foto = await picker.pickImage(source: ImageSource.camera);
                  if (foto != null) {
                    setState(() {
                      fotosPorSelector[id]!.add(foto);
                    });
                  }
                },
              ),
            ],
          ),
          // Mostrar las fotos capturadas para este selector
          if (fotosPorSelector[id]!.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotosPorSelector[id]!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                    child: kIsWeb
                        ? Image.network(
                            fotosPorSelector[id]![index].path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(fotosPorSelector[id]![index].path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String groupValue, ValueChanged<String> onChanged, {required Color color}) {
    final bool selected = groupValue == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF263A5B),
          fontFamily: 'Avenir',
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: selected,
      selectedColor: color,
      backgroundColor: const Color(0xFFE2E4EC),
      onSelected: (_) => onChanged(label),
    );
  }

  void guardarFormularioF008() async {
  try {
    await exportarPDF();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario guardado y exportado a PDF')),
    );
  } catch (e, st) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al exportar PDF: $e')),
    );
    print('Error al exportar PDF: $e\n$st');
  }
}

  Future<void> exportarPDF() async {
  final pdf = await generarDocumentoPDF();
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

  Future<pw.Document> generarDocumentoPDF() async {
  final pdf = pw.Document();

  final headerStyle = pw.TextStyle(
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue900,
  );
  final sectionTitleStyle = pw.TextStyle(
    fontSize: 15,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue800,
  );
  final labelStyle = pw.TextStyle(
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blueGrey800,
  );
  final valueStyle = pw.TextStyle(
    fontSize: 12,
    color: PdfColors.black,
  );
  final obsStyle = pw.TextStyle(
    fontSize: 11,
    color: PdfColors.grey600,
    fontStyle: pw.FontStyle.italic,
  );

  // Cargar el logo (asegúrate de tener assets/logo_aiq.png en tu proyecto y registrado en pubspec.yaml)
  final logo = await imageFromAssetBundle('assets/AIQ_LOGO_.png');
  final plano = await imageFromAssetBundle('assets/plano.png');

  // Obtener la firma como imagen (Uint8List)
  pw.ImageProvider? firmaImage;
  if (enteradoFirmaController.isNotEmpty) {
    final signatureBytes = await enteradoFirmaController.toPngBytes();
    if (signatureBytes != null) {
      firmaImage = pw.MemoryImage(signatureBytes);
    }
  }

  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        // Encabezado con logo y fecha
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              height: 50,
              width: 50,
              child: pw.Image(logo),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Folio: $folio', style: labelStyle),
                pw.Text('Fecha: ${fechaController.text.isNotEmpty ? fechaController.text : _fechaActual()}', style: labelStyle),
                pw.Text('AIQ-OPS-F005', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'LISTA DE VERIFICACIÓN PARA PREVENIR INCURSIONES EN EL ÁREA DE MOVIMIENTO',
          style: headerStyle,
          textAlign: pw.TextAlign.center,
        ),
        pw.Divider(),

        // Datos de la Inspección
        pw.Text('Datos de la Inspección', style: sectionTitleStyle),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text('Hora: ', style: labelStyle),
            pw.Text(horaController.text, style: valueStyle),
            pw.SizedBox(width: 30),
            pw.Text('Inspección: ', style: labelStyle),
            pw.Text(_inspeccionSeleccionada == 1 ? "1/2" : "2/2", style: valueStyle),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text('Folio: ', style: labelStyle),
            pw.Text(folio.toString(), style: valueStyle),
          ],
        ),
        pw.SizedBox(height: 18),

        // Sección 1: Geometría del Área de Movimiento
        pw.Text('Sección 1. Geometría del Área de Movimiento.', style: sectionTitleStyle),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Image(plano, height: 250),
        ),
        pw.SizedBox(height: 18),

        // Sección 2: Condición del Cercado Perimetral
        pw.Text('Sección 2. Condición del Cercado Perimetral', style: sectionTitleStyle),
        pw.SizedBox(height: 6),
        pw.Text('a) Estado físico del cercado perimetral: $estadoCercado', style: valueStyle),
        pw.SizedBox(height: 18),

        // Sección 3: Control de Accesos
        pw.Text('Sección 3. Control de Accesos', style: sectionTitleStyle),
        pw.SizedBox(height: 6),
        pw.Text('a) Condición de Accesos: $estadoAccesos', style: valueStyle),
        pw.SizedBox(height: 4),
        pw.Text('b) Vigilancia en los Accesos: $vigilanciaAccesos', style: valueStyle),
        pw.SizedBox(height: 4),
        pw.Text('c) Bitácora de Accesos: $bitacoraAccesos', style: valueStyle),
        pw.SizedBox(height: 18),

        // Sección 4: Comunicaciones terrestres
        pw.Text('Sección 4. Comunicaciones terrestres', style: sectionTitleStyle),
        pw.SizedBox(height: 6),
        pw.Text('a) Condición del equipo de comunicaciones terrestres: $estadoComunicacionesA', style: valueStyle),
        pw.SizedBox(height: 4),
        pw.Text('b) Ha presentado fallas últimamente la comunicación terrestre: $estadoComunicacionesB', style: valueStyle),
        pw.SizedBox(height: 4),
        pw.Text('c) Motivo de fallas: ${motivosFallasController.text}', style: obsStyle),
        pw.SizedBox(height: 4),
        pw.Text('d) Se ha recurrido a usar medios visuales para la comunicación: $estadoComunicacionesD', style: valueStyle),
        pw.SizedBox(height: 18),

        // Sección 5: Comunicaciones y señales de vehículos en plataforma
        pw.Text('Sección 5. Comunicaciones y señales de vehículos en plataforma', style: sectionTitleStyle),
        pw.SizedBox(height: 6),
        pw.Text('a) Vehículos con características necesarias: $estadoVehiculosA', style: valueStyle),
        pw.SizedBox(height: 18),

        // Enterado
        pw.Text('Enterado', style: sectionTitleStyle),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text('Nombre: ', style: labelStyle),
            pw.Text(enteradoNombreController.text, style: valueStyle),
            pw.SizedBox(width: 30),
            pw.Text('Fecha: ', style: labelStyle),
            pw.Text(enteradoFechaController.text, style: valueStyle),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text('Firma:', style: labelStyle),
        pw.Container(
          height: 60,
          width: 180,
          alignment: pw.Alignment.center,
          child: firmaImage != null
              ? pw.Image(firmaImage, height: 50)
              : pw.Text('_________________', style: obsStyle),
        ),
      ],
    ),
  );

  return pdf;
}

// Helper para cargar imagen desde assets
Future<pw.ImageProvider> imageFromAssetBundle(String path) async {
  final bytes = await rootBundle.load(path);
  return pw.MemoryImage(bytes.buffer.asUint8List());
}

String _fechaActual() {
  final now = DateTime.now();
  return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
}

Future<void> compartirPDF() async {
  final pdf = await generarDocumentoPDF();

  // Guarda el PDF en un archivo temporal
  final bytes = await pdf.save();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/AIQ-OPS-F005.pdf');
  await file.writeAsBytes(bytes);

  // Sube a Drive
  await uploadPDFToDrive(file, 'AIQ-OPS-F005-${folio}.pdf');
}

Future<void> cargarFolio() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    folio = prefs.getInt('folio_f005') ?? 1;
  });
}

Future<void> incrementarFolio() async {
  final prefs = await SharedPreferences.getInstance();
  folio++;
  await prefs.setInt('folio_f005', folio);
}

void guardarFormularioF005() async {
  try {
    // 1. Guarda en Firebase
    await guardarEnAIQOPSF005(
      folio: folio,
      fecha: fechaController.text.isNotEmpty ? fechaController.text : _fechaActual(),
      hora: horaController.text,
      nombre: enteradoNombreController.text,
      estadoCercado: estadoCercado,
      estadoAccesos: estadoAccesos,
      vigilanciaAccesos: vigilanciaAccesos,
      bitacoraAccesos: bitacoraAccesos,
      estadoVehiculosA: estadoVehiculosA,
      inspeccion: _inspeccionSeleccionada,
      estadoComunicacionesA: estadoComunicacionesA,
      estadoComunicacionesB: estadoComunicacionesB,
      estadoComunicacionesD: estadoComunicacionesD,
      motivosFallas: motivosFallasController.text,
      enteradoFecha: enteradoFechaController.text,
      // Agrega aquí más campos si los necesitas
    );

    // 2. Exporta a PDF
    await exportarPDF();

    // 3. (Opcional) Muestra mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario guardado en Firebase y exportado a PDF')),
    );

    // 4. (Opcional) Incrementa el folio
    await incrementarFolio();

  } catch (e, st) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al guardar/exportar: $e')),
    );
    print('Error al guardar/exportar: $e\n$st');
  }
}

Future<void> guardarEnAIQOPSF005({
  required int folio,
  required String fecha,
  required String hora,
  required String nombre,
  required String estadoCercado,
  required String estadoAccesos,
  required String vigilanciaAccesos,
  required String bitacoraAccesos,
  required String estadoVehiculosA,
  required int inspeccion,
  required String estadoComunicacionesA,
  required String estadoComunicacionesB,
  required String estadoComunicacionesD,
  required String motivosFallas,
  required String enteradoFecha,
  // Agrega aquí más campos si los necesitas
}) async {
  final firestore = FirebaseFirestore.instance;

  final datos = {
    'folio': folio,
    'fecha': fecha,
    'hora': hora,
    'nombre': nombre,
    'estadoCercado': estadoCercado,
    'estadoAccesos': estadoAccesos,
    'vigilanciaAccesos': vigilanciaAccesos,
    'bitacoraAccesos': bitacoraAccesos,
    'vehiculosAreaOperacional': estadoVehiculosA,
    'inspeccion': inspeccion,
    'estadoComunicacionesA': estadoComunicacionesA,
    'estadoComunicacionesB': estadoComunicacionesB,
    'estadoComunicacionesD': estadoComunicacionesD,
    'motivosFallas': motivosFallas,
    'enteradoFecha': enteradoFecha,
    'timestamp': FieldValue.serverTimestamp(),
    // Agrega aquí más campos si los necesitas
  };

  await firestore.collection('AIQ_OPS_F005').doc(folio.toString()).set(datos);
}
}
//falta exportar el resto de formularios a excel.
//editar los botones de compartir y exportar a excel.
//agregar el logo del aiq a los archivos de excel.
// que pueda exportar todos los registros de firebase a excel.
//agregar que el pdf salga con las fotografías. F005 
//Agarrar pdfs y mandar ruta a Drive. -- Dani