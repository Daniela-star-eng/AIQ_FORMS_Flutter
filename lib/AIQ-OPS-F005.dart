import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Google Drive & Auth imports
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// GoogleAuthClient for Drive API
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

// Function to upload PDF to Drive in a specific folder
Future<String?> subirPDFaDriveEnCarpeta(File pdfFile, String folderId) async {
  final googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveMetadataScope,
    ],
  );
  await googleSignIn.signOut(); // Always prompt account selection
  final account = await googleSignIn.signIn();
  if (account == null) return null;
  final authHeaders = await account.authHeaders;
  final authenticateClient = GoogleAuthClient(authHeaders);
  final driveApi = drive.DriveApi(authenticateClient);

  final media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
  final driveFile = drive.File();
  driveFile.name = pdfFile.path.split('/').last;
  driveFile.parents = [folderId];

  final uploadedFile = await driveApi.files.create(
    driveFile,
    uploadMedia: media,
  );

  // Make file shareable
  await driveApi.permissions.create(
    drive.Permission()
      ..type = 'anyone'
      ..role = 'reader',
    uploadedFile.id!,
  );

  final fileMeta = await driveApi.files.get(
    uploadedFile.id!,
    // 'fields' is not always supported, so we fetch the full object
  );
  // Return the webViewLink if available
  return (fileMeta as drive.File).webViewLink;
}

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

  int folio = 1;

  // Nueva variable para el consecutivo
  int consecutivoMostrado = 1;
  DateTime? fechaSeleccionada;

  // Errores
  bool _errorFecha = false;
  bool _errorHora = false;
  bool _errorNombre = false;
  bool _errorFechaEnterado = false;
  bool _errorMotivosFallas = false;
  bool _errorFirma = false;

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
      backgroundColor: const Color(0xFFEAEFF8), // <-- aquí el color de fondo
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
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    margin: const EdgeInsets.only(top: 5, bottom: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFF598CBC)),
                    ),
                    child: Text(
                      folioGenerado,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263A5B),
                        fontSize: 14,
                        fontFamily: 'Avenir',
                      ),
                    ),
                  ),
                  // Datos de la Inspección
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
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
                        const SizedBox(height: 5),
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
                          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
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
          padding: const EdgeInsets.only(left: 24.0, bottom: 2.0),
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
        border: Border.all(
          color: _errorFecha ? Colors.red : Colors.transparent,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          icon: isTime ? const Icon(Icons.access_time) : const Icon(Icons.calendar_today),
          border: InputBorder.none,
          errorText: _errorFecha ? 'Campo obligatorio' : null,
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
              final consecutivo = await obtenerConsecutivoParaFecha(pickedDate);
              setState(() {
                fechaSeleccionada = pickedDate;
                fechaController.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                consecutivoMostrado = consecutivo;
                _errorFecha = false;
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
      backgroundColor: const Color.fromARGB(255, 228, 229, 235),
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

  // --- PREPARAR EVIDENCIA FOTOGRÁFICA ---
  // Mapeo de id de selector a descripción legible
  final Map<String, String> descripcionPorId = {
    'cercado': 'Sección 1. Geometría del Área de Movimiento',
    'control_accesos_condicion': 'Sección 2. Condición del Cercado Perimetral',
    'vigilancia_accesos': 'Sección 3. Control de Accesos',
    'bitacora_accesos': 'Sección 3. Control de Accesos',
    'comunicacionesA': 'Sección 4. Comunicaciones terrestres',
    'fallas_comunicacion_terrestre': 'Sección 4. Comunicaciones terrestres',
    'comunicacionesD': 'Sección 4. Comunicaciones terrestres',
    'vehiculos_area_operacional': 'Sección 5. Comunicaciones y señales de vehículos en plataforma',
  };
  final Map<String, List<pw.ImageProvider>> fotosPorSelectorPDF = {};
  for (final entry in fotosPorSelector.entries) {
    final List<pw.ImageProvider> imagenes = [];
    for (final foto in entry.value) {
      final file = File(foto.path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        imagenes.add(pw.MemoryImage(bytes));
      }
    }
    if (imagenes.isNotEmpty) {
      fotosPorSelectorPDF[entry.key] = imagenes;
    }
  }

  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) {
        final List<pw.Widget> widgets = [];
        // Encabezado
        widgets.add(
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
                  pw.Text('Fecha:  {fechaController.text.isNotEmpty ? fechaController.text : _fechaActual()}', style: labelStyle),
                  pw.Text('AIQ-OPS-F005', style: pw.TextStyle(color: PdfColors.blue, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 16));
        widgets.add(pw.Text(
          'LISTA DE VERIFICACIÓN PARA PREVENIR INCURSIONES EN EL ÁREA DE MOVIMIENTO',
          style: headerStyle,
          textAlign: pw.TextAlign.center,
        ));
        widgets.add(pw.Divider());
        // Datos de la Inspección
        widgets.add(pw.Text('Datos de la Inspección', style: sectionTitleStyle));
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(
          pw.Row(
            children: [
              pw.Text('Hora: ', style: labelStyle),
              pw.Text(horaController.text, style: valueStyle),
              pw.SizedBox(width: 30),
              pw.Text('Inspección: ', style: labelStyle),
              pw.Text(_inspeccionSeleccionada == 1 ? "1/2" : "2/2", style: valueStyle),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(
          pw.Row(
            children: [
              pw.Text('Folio: ', style: labelStyle),
              pw.Text(folio.toString(), style: valueStyle),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 18));
        // Sección 1: Geometría del Área de Movimiento
        widgets.add(pw.Text('Sección 1. Geometría del Área de Movimiento.', style: sectionTitleStyle));
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(pw.Center(child: pw.Image(plano, height: 250)));
        // Fotos de sección 1 (si existen)
        if (fotosPorSelectorPDF['cercado'] != null && fotosPorSelectorPDF['cercado']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['cercado']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['cercado']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        widgets.add(pw.SizedBox(height: 18));
        // Sección 2: Condición del Cercado Perimetral
        widgets.add(pw.Text('Sección 2. Condición del Cercado Perimetral', style: sectionTitleStyle));
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Text('a) Estado físico del cercado perimetral: $estadoCercado', style: valueStyle));
        // Fotos de sección 2 (si existen)
        if (fotosPorSelectorPDF['control_accesos_condicion'] != null && fotosPorSelectorPDF['control_accesos_condicion']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['control_accesos_condicion']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['control_accesos_condicion']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        widgets.add(pw.SizedBox(height: 18));
        // Sección 3: Control de Accesos
        widgets.add(pw.Text('Sección 3. Control de Accesos', style: sectionTitleStyle));
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Text('a) Condición de Accesos: $estadoAccesos', style: valueStyle));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('b) Vigilancia en los Accesos: $vigilanciaAccesos', style: valueStyle));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('c) Bitácora de Accesos: $bitacoraAccesos', style: valueStyle));
        // Fotos de sección 3 (si existen)
        if (fotosPorSelectorPDF['vigilancia_accesos'] != null && fotosPorSelectorPDF['vigilancia_accesos']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['vigilancia_accesos']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['vigilancia_accesos']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        if (fotosPorSelectorPDF['bitacora_accesos'] != null && fotosPorSelectorPDF['bitacora_accesos']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['bitacora_accesos']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['bitacora_accesos']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        widgets.add(pw.SizedBox(height: 18));
        // Sección 4: Comunicaciones terrestres
        widgets.add(pw.Text('Sección 4. Comunicaciones terrestres', style: sectionTitleStyle));
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Text('a) Condición del equipo de comunicaciones terrestres: $estadoComunicacionesA', style: valueStyle));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('b) Ha presentado fallas últimamente la comunicación terrestre: $estadoComunicacionesB', style: valueStyle));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('c) Motivo de fallas: ${motivosFallasController.text}', style: obsStyle));
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('d) Se ha recurrido a usar medios visuales para la comunicación: $estadoComunicacionesD', style: valueStyle));
        // Fotos de sección 4 (si existen)
        if (fotosPorSelectorPDF['comunicacionesA'] != null && fotosPorSelectorPDF['comunicacionesA']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['comunicacionesA']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['comunicacionesA']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        if (fotosPorSelectorPDF['fallas_comunicacion_terrestre'] != null && fotosPorSelectorPDF['fallas_comunicacion_terrestre']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['fallas_comunicacion_terrestre']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['fallas_comunicacion_terrestre']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        if (fotosPorSelectorPDF['comunicacionesD'] != null && fotosPorSelectorPDF['comunicacionesD']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['comunicacionesD']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['comunicacionesD']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        widgets.add(pw.SizedBox(height: 18));
        // Sección 5: Comunicaciones y señales de vehículos en plataforma
        widgets.add(pw.Text('Sección 5. Comunicaciones y señales de vehículos en plataforma', style: sectionTitleStyle));
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Text('a) Vehículos con características necesarias: $estadoVehiculosA', style: valueStyle));
        // Fotos de sección 5 (si existen)
        if (fotosPorSelectorPDF['vehiculos_area_operacional'] != null && fotosPorSelectorPDF['vehiculos_area_operacional']!.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text('Evidencia fotográfica:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)));
          for (final img in fotosPorSelectorPDF['vehiculos_area_operacional']!) {
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 180, height: 180, child: pw.Image(img, fit: pw.BoxFit.cover)),
                  pw.SizedBox(height: 4),
                  pw.Text(descripcionPorId['vehiculos_area_operacional']!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                  pw.SizedBox(height: 16),
                ],
              ),
            );
          }
        }
        widgets.add(pw.SizedBox(height: 18));
        // Enterado
        widgets.add(pw.Text('Enterado', style: sectionTitleStyle));
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(
          pw.Row(
            children: [
              pw.Text('Nombre: ', style: labelStyle),
              pw.Text(enteradoNombreController.text, style: valueStyle),
              pw.SizedBox(width: 30),
              pw.Text('Fecha: ', style: labelStyle),
              pw.Text(enteradoFechaController.text, style: valueStyle),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 12));
        widgets.add(pw.Text('Firma:', style: labelStyle));
        widgets.add(
          pw.Container(
            height: 60,
            width: 180,
            alignment: pw.Alignment.center,
            child: firmaImage != null
                ? pw.Image(firmaImage, height: 50)
                : pw.Text('_', style: obsStyle),
          ),
        );
        // --- EVIDENCIA FOTOGRÁFICA AL FINAL DEL PDF ---
        if (fotosPorSelectorPDF.isNotEmpty) {
          widgets.add(pw.Divider());
          widgets.add(pw.Text('Evidencia fotográfica', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.blue900)));
          widgets.add(pw.SizedBox(height: 8));
          fotosPorSelectorPDF.forEach((id, imagenes) {
            final descripcion = descripcionPorId[id] ?? id;
            for (final img in imagenes) {
              widgets.add(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 180,
                      height: 180,
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(descripcion, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 16),
                  ],
                ),
              );
            }
          });
        }
        return widgets;
      },
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

  // Comparte el archivo
  await Share.shareXFiles([XFile(file.path)], text: 'Formulario AIQ-OPS-F005');
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

String get folioGenerado {
  if (fechaSeleccionada == null) return "AIQOPSF005---/--/-----$consecutivoMostrado";
  final anio = fechaSeleccionada!.year.toString();
  final mes = fechaSeleccionada!.month.toString().padLeft(2, '0');
  final dia = fechaSeleccionada!.day.toString().padLeft(2, '0');
  return "AIQOPSF005-$anio-$mes-$dia-$consecutivoMostrado";
}

void guardarFormularioF005() async {
  if (!validarCamposObligatorios()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, completa todos los campos obligatorios y la firma')),
    );
    return;
  }
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
    );

    // 2. Exporta a PDF y guarda en archivo temporal
    final pdf = await generarDocumentoPDF();
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    // Nombre de archivo: AIQ-OPS-F005-$fecha-$folio.pdf
    final fechaStr = fechaController.text.isNotEmpty ? fechaController.text.replaceAll('/', '-') : _fechaActual().replaceAll('/', '-');
    final file = File('${dir.path}/AIQ-OPS-F005-$fechaStr-$folio.pdf');
    await file.writeAsBytes(bytes);

    // 3. Sube el PDF a Drive automáticamente a la carpeta fija
    const folderId = '1H-ZIrZ26_8YykhE_1WZYEw6H90npNk27'; // ID de la carpeta fija
    final link = await subirPDFaDriveEnCarpeta(file, folderId);
    if (link != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF subido a Google Drive. ¡Haz clic para abrir el enlace!'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo subir el PDF a Google Drive.')),
      );
    }

    // 4. Incrementa el folio y limpia campos
    await incrementarFolio();
    limpiarCampos();
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
  };

  await firestore.collection('AIQ-OPS-F005').doc(folioGenerado).set(datos);
}

Future<int> obtenerConsecutivoParaFecha(DateTime fecha) async {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();
  final fechaStr = "$dia/$mes/$anio";

  final snapshot = await FirebaseFirestore.instance
      .collection('AIQ-OPS-F005')
      .where('fecha', isEqualTo: fechaStr)
      .get();

  return snapshot.docs.length + 1;
}

bool validarCamposObligatorios() {
  setState(() {
    _errorFecha = fechaController.text.isEmpty;
    _errorHora = horaController.text.isEmpty;
    _errorNombre = enteradoNombreController.text.isEmpty;
    _errorFechaEnterado = enteradoFechaController.text.isEmpty;
    _errorMotivosFallas = motivosFallasController.text.isEmpty;
    _errorFirma = !enteradoFirmaController.isNotEmpty;
  });
  return !(_errorFecha ||
      _errorHora ||
      _errorNombre ||
      _errorFechaEnterado ||
      _errorMotivosFallas ||
      _errorFirma);
}

void limpiarCampos() {
  fechaController.clear();
  horaController.clear();
  enteradoNombreController.clear();
  enteradoFechaController.clear();
  motivosFallasController.clear();
  estadoCercado = "Bueno";
  estadoAccesos = "Bueno";
  vigilanciaAccesos = "Bueno";
  bitacoraAccesos = "Bueno";
  estadoComunicacionesA = "Bueno";
  estadoComunicacionesB = "Sí";
  estadoComunicacionesD = "Sí";
  estadoVehiculosA = "Sí";
  _inspeccionSeleccionada = 1;
  fechaSeleccionada = null;
  consecutivoMostrado = 1;
  enteradoFirmaController.clear();
  fotosPorSelector.clear();
  setState(() {});
}
}

//revisar lo de observaciones y fotos 
//por que se limpia el formulario cuando se toma una 
//foto y quitarle las validaciones a observaciones. 