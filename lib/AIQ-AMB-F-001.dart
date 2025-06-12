// ignore: file_names
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleAuthClient extends BaseClient {
  final Map<String, String> _headers;
  final Client _client = Client();

  GoogleAuthClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}

class AIQAMBF001Screen extends StatefulWidget {
  const AIQAMBF001Screen({super.key});

  @override
  State<AIQAMBF001Screen> createState() => _AIQAMBF001ScreenState();
}

class _AIQAMBF001ScreenState extends State<AIQAMBF001Screen> {
  int folio = 1;
  bool _isSaving = false;

  // NUEVO: controladores y variables para fecha y hora
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _errorFecha = false;
  bool _errorHora = false;

  // Controladores de los campos actuales
  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController especieController = TextEditingController();
  final TextEditingController numeroFaunaController = TextEditingController();
  final TextEditingController metodoControlController = TextEditingController();
  final TextEditingController resultadosComentariosController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController persona1NombreController = TextEditingController();

  final SignatureController firma1Controller = SignatureController(penStrokeWidth: 2, penColor: Color(0xFF263A5B));

  // Errores de campos obligatorios
  bool _errorUbicacion = false;
  bool _errorEspecie = false;
  bool _errorNumero = false;
  bool _errorMetodo = false;
  bool _errorResultados = false;
  bool _errorObservaciones = false;
  bool _errorNombre = false;
  bool _errorFirma = false;

  int consecutivoMostrado = 1;
  String nombreDocumento = "AIQ-AMB-F-001";
  
  @override
  void initState() {
    super.initState();
    _cargarFolio();
  }

  Future<void> _cargarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      folio = prefs.getInt('folio_f-001') ?? 1;
    });
  }

  Future<void> _incrementarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    folio++;
    await prefs.setInt('folio_f-001', folio);
    setState(() {});
  }

  @override
  void dispose() {
    ubicacionController.dispose();
    especieController.dispose();
    numeroFaunaController.dispose();
    metodoControlController.dispose();
    resultadosComentariosController.dispose();
    observacionesController.dispose();
    persona1NombreController.dispose();
    firma1Controller.dispose();
    super.dispose();
  }

  bool validarCampos() {
    setState(() {
      _errorUbicacion = ubicacionController.text.trim().isEmpty;
      _errorEspecie = especieController.text.trim().isEmpty;
      _errorNumero = numeroFaunaController.text.trim().isEmpty;
      _errorMetodo = metodoControlController.text.trim().isEmpty;
      _errorResultados = resultadosComentariosController.text.trim().isEmpty;
      _errorObservaciones = observacionesController.text.trim().isEmpty;
      _errorNombre = persona1NombreController.text.trim().isEmpty;
      _errorFirma = firma1Controller.isEmpty;
    });
    return !(_errorUbicacion ||
        _errorEspecie ||
        _errorNumero ||
        _errorMetodo ||
        _errorResultados ||
        _errorObservaciones ||
        _errorNombre ||
        _errorFirma);
  }

  Future<void> guardarEnFirestore(String fechaHoy, String folioGenerado) async {
    await FirebaseFirestore.instance
        .collection('AIQ-AMB-F-001')
        .doc(folioGenerado) // El ID será el folio generado
        .set({
      'folio': folioGenerado,
      'fecha': fechaHoy,
      'ubicacion': ubicacionController.text.trim(),
      'especie': especieController.text.trim(),
      'numero': numeroFaunaController.text.trim(),
      'metodo_control': metodoControlController.text.trim(),
      'resultados_comentarios': resultadosComentariosController.text.trim(),
      'observaciones': observacionesController.text.trim(),
      'nombre_firma': persona1NombreController.text.trim(),
      'fecha_seleccionada': _fechaSeleccionada != null
          ? "${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}"
          : "",
      'hora_seleccionada': _horaSeleccionada != null
          ? "${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}"
          : "",
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void limpiarCampos() {
    ubicacionController.clear();
    especieController.clear();
    numeroFaunaController.clear();
    metodoControlController.clear();
    resultadosComentariosController.clear();
    observacionesController.clear();
    persona1NombreController.clear();
    firma1Controller.clear();
    _fechaSeleccionada = null;
    _horaSeleccionada = null;
    consecutivoMostrado = 1;
    setState(() {});
  }

  // Permite cerrar sesión de Google para seleccionar otra cuenta antes de subir a Drive
  Future<void> logoutGoogle() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  // Sube PDF a Google Drive y retorna el enlace compartible
  Future<String?> subirPDFaDrive(File pdfFile) async {
    final googleSignIn = GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/drive.file'],
    );
    final account = await googleSignIn.signIn();
    if (account == null) return null;
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    final media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
    final driveFile = drive.File();
    driveFile.name = pdfFile.path.split('/').last;
    final uploaded = await driveApi.files.create(
      driveFile,
      uploadMedia: media,
    );
    // Hacer el archivo compartible
    await driveApi.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      uploaded.id!,
    );
    return 'https://drive.google.com/file/d/${uploaded.id}/view?usp=sharing';
  }

  // Sube PDF a Google Drive en una carpeta específica y retorna el enlace compartible
  Future<String?> subirPDFaDriveEnCarpeta(File pdfFile, String folderId) async {
    final googleSignIn = GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/drive.file'],
    );
    final account = await googleSignIn.signIn();
    if (account == null) return null;
    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    final media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
    final driveFile = drive.File();
    driveFile.name = pdfFile.path.split('/').last;
    driveFile.parents = [folderId]; // Usa el parámetro folderId correctamente
    final uploaded = await driveApi.files.create(
      driveFile,
      uploadMedia: media,
    );
    // Hacer el archivo compartible
    await driveApi.permissions.create(
      drive.Permission()
        ..type = 'anyone'
        ..role = 'reader',
      uploaded.id!,
    );
    return 'https://drive.google.com/file/d/${uploaded.id}/view?usp=sharing';
  }

  // Exporta el PDF, lo guarda localmente y lo sube a Drive
  Future<File?> _generarPDFyGuardar(String fechaHoy, String folioGenerado) async {
    try {
      final pdf = pw.Document();
      final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final firma1Bytes = firma1Controller.isNotEmpty ? await firma1Controller.toPngBytes() : null;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 80),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('AIQ-AMB-F-001', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text('MONITOREO Y AVISTAMIENTO DE FAUNA', style: pw.TextStyle(fontSize: 12, color: PdfColors.blueGrey800)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              color: PdfColors.blue100,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Folio: $folioGenerado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Fecha: $fechaHoy'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Ubicación', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text(ubicacionController.text),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Fauna', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Bullet(text: 'Especie: ${especieController.text}'),
                  pw.Bullet(text: 'Número: ${numeroFaunaController.text}'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Método de control', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text(metodoControlController.text),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Resultados y comentarios', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text(resultadosComentariosController.text),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Observaciones', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text(observacionesController.text),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Firma', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Text('Nombre: ${persona1NombreController.text}', style: pw.TextStyle(fontSize: 12)),
            if (firma1Bytes != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Image(pw.MemoryImage(firma1Bytes), width: 120, height: 40),
              ),
          ],
        ),
      );
      final output = await getTemporaryDirectory();
      // Corregir el nombre del archivo para evitar caracteres inválidos
      final folioGeneradoSafe = folioGenerado.replaceAll('/', '-');
      final file = File('${output.path}/$folioGeneradoSafe.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
      return null;
    }
  }

  Future<String> generarFolio() async {
    if (_fechaSeleccionada == null) return "";
    final dia = _fechaSeleccionada!.day.toString().padLeft(2, '0');
    final mes = _fechaSeleccionada!.month.toString().padLeft(2, '0');
    final anio = _fechaSeleccionada!.year.toString();
    final fechaStr = "$dia/$mes/$anio";

    final snapshot = await FirebaseFirestore.instance
        .collection('AIQ-AMB-F-001')
        .where('fecha_seleccionada', isEqualTo: fechaStr)
        .get();

    final consecutivo = snapshot.docs.length + 1;
    return "AIQAMBF001-$dia-$mes-$anio-$consecutivo";
  }

  // MODIFICADO: Guardar, exportar PDF y subir a Drive con feedback
  void guardarYExportar() async {
    if (_isSaving) return;
    if (!validarCampos()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, completa todos los campos obligatorios y la firma')),
        );
      }
      return;
    }
    setState(() => _isSaving = true);
    final fechaHoy = "${DateTime.now().day.toString().padLeft(2, '0')}/"
        "${DateTime.now().month.toString().padLeft(2, '0')}/"
        "${DateTime.now().year}";
    const folderId = '10xo5X1yi4DZPb5s8w-sLHNs9w2EslxGp'; // <-- Cambia esto por el ID de tu carpeta de Drive
    try {
      final folioGenerado = await generarFolio();
      await guardarEnFirestore(fechaHoy, folioGenerado);
      await logoutGoogle(); // Permitir selección de cuenta
      final pdfFile = await _generarPDFyGuardar(fechaHoy, folioGenerado);
      if (pdfFile == null) throw 'No se pudo generar el PDF';
      final driveLink = await subirPDFaDriveEnCarpeta(pdfFile, folderId);
      await _incrementarFolio();
      limpiarCampos();
      if (mounted) {
        if (driveLink != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Formulario guardado y PDF subido a Drive'),
              action: SnackBarAction(
                label: 'Ver PDF',
                onPressed: () async {
                  if (await canLaunch(driveLink)) {
                    await launch(driveLink);
                  }
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulario guardado, pero no se pudo subir el PDF a Drive')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar/exportar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<int> obtenerConsecutivoParaFecha(DateTime fecha) async {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final fechaStr = "$dia/$mes/$anio";

    final snapshot = await FirebaseFirestore.instance
        .collection('AIQ-AMB-F-001')
        .where('fecha_seleccionada', isEqualTo: fechaStr)
        .get();

    return snapshot.docs.length + 1;
  }

  // NUEVO: Métodos para seleccionar fecha y hora
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
            data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF598CBC),
            colorScheme: ColorScheme.light(primary: const Color(0xFF598CBC)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      final consecutivo = await obtenerConsecutivoParaFecha(fecha);
      setState(() {
        _fechaSeleccionada = fecha;
        consecutivoMostrado = consecutivo;
        _errorFecha = false;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF598CBC),
            colorScheme: ColorScheme.light(primary: const Color(0xFF598CBC)),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
        _errorHora = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: const Color(0xFF263A5B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                "MONITOREO Y AVISTAMIENTO DE FAUNA",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Avenir',
                  color: Color(0xFF263A5B),
                ),
              ),
            ),
            const Text(
              "AIQ-AMB-F-001",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF598CBC),
                fontFamily: 'Avenir',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Selector de fecha y folio en la misma fila
            Row(
              children: [
                // Selector de fecha (izquierda)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Fecha del monitoreo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF263A5B),
                        ),
                      ),
                      
                      InkWell(
                        onTap: _seleccionarFecha,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: _errorFecha ? Border.all(color: Colors.red) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[700]),
                              const SizedBox(width: 10),
                              Text(
                                _fechaSeleccionada != null
                                    ? "${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}"
                                    : "Selecciona una fecha",
                                style: TextStyle(
                                  color: _fechaSeleccionada != null ? Colors.black : Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_errorFecha)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 8),
                          child: Text(
                            "La fecha es obligatoria",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Folio (derecha)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  margin: const EdgeInsets.only(top: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF598CBC)),
                  ),
                  child: Text(
                    "AIQAMBF001-${_fechaSeleccionada != null
                        ? "${_fechaSeleccionada!.day.toString().padLeft(2, '0')}-${_fechaSeleccionada!.month.toString().padLeft(2, '0')}-${_fechaSeleccionada!.year}"
                        : "--/--/----"}-$consecutivoMostrado",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263A5B),
                      fontSize: 14,
                      fontFamily: 'Avenir',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selector de hora
            Text(
              "Hora del monitoreo",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF263A5B),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _seleccionarHora,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: _errorHora ? Border.all(color: Colors.red) : null,
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[700]),
                    const SizedBox(width: 10),
                    Text(
                      _horaSeleccionada != null
                          ? "${_horaSeleccionada!.hour.toString().padLeft(2, '0')}:${_horaSeleccionada!.minute.toString().padLeft(2, '0')}"
                          : "Selecciona una hora",
                      style: TextStyle(
                        color: _horaSeleccionada != null ? Colors.black : Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorHora)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 8),
                child: Text(
                  "La hora es obligatoria",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),

            // Ubicación
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFC2C8D9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ubicación",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: _errorUbicacion
                          ? Border.all(color: Colors.red)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: ubicacionController,
                      decoration: InputDecoration(
                        labelText: "Ubicación",
                        labelStyle: const TextStyle(color: Colors.grey),
                        icon: const Icon(Icons.location_on, color: Colors.grey),
                        border: InputBorder.none,
                        errorText: _errorUbicacion ? "Este campo es obligatorio" : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fauna
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFC2C8D9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Fauna",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: _errorEspecie
                          ? Border.all(color: Colors.red)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: especieController,
                      decoration: InputDecoration(
                        labelText: "Especie",
                        labelStyle: const TextStyle(color: Colors.grey),
                        icon: const Icon(Icons.pets, color: Colors.grey),
                        border: InputBorder.none,
                        errorText: _errorEspecie ? "Este campo es obligatorio" : null,
                      ),
                    ),
                  ),
                  if (_errorEspecie)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Este campo es obligatorio",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: _errorNumero
                          ? Border.all(color: Colors.red)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: numeroFaunaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Número",
                        labelStyle: const TextStyle(color: Colors.grey),
                        icon: const Icon(Icons.format_list_numbered, color: Colors.grey),
                        border: InputBorder.none,
                        errorText: _errorNumero ? "Este campo es obligatorio" : null,
                      ),
                    ),
                  ),
                  if (_errorNumero)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Este campo es obligatorio",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            // Método de control
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFC2C8D9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Método de control",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: _errorMetodo
                          ? Border.all(color: Colors.red)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: metodoControlController,
                      decoration: InputDecoration(
                        labelText: "Método de control",
                        labelStyle: const TextStyle(color: Colors.grey),
                        icon: const Icon(Icons.build, color: Colors.grey),
                        border: InputBorder.none,
                        errorText: _errorMetodo ? "Este campo es obligatorio" : null,
                      ),
                    ),
                  ),
                  if (_errorMetodo)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Este campo es obligatorio",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            // Resultados y comentarios
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFC2C8D9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resultados y comentarios",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: _errorResultados
                          ? Border.all(color: Colors.red)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: resultadosComentariosController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Resultados y comentarios",
                        labelStyle: const TextStyle(color: Colors.grey),
                        icon: const Icon(Icons.comment, color: Colors.grey),
                        border: InputBorder.none,
                        errorText: _errorResultados ? "Este campo es obligatorio" : null,
                      ),
                    ),
                  ),
                  if (_errorResultados)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Este campo es obligatorio",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            // Observaciones
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFC2C8D9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Observaciones",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: _errorObservaciones
                          ? Border.all(color: Colors.red)
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: observacionesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Observaciones",
                        labelStyle: const TextStyle(color: Colors.grey),
                        icon: const Icon(Icons.comment_bank, color: Colors.grey),
                        border: InputBorder.none,
                        errorText: _errorObservaciones ? "Este campo es obligatorio" : null,
                      ),
                    ),
                  ),
                  if (_errorObservaciones)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Este campo es obligatorio",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            // Firma
            const SizedBox(height: 24),
            const Text(
              "Nombre y Firma del prestador de servicio",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF263A5B),
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: persona1NombreController,
              decoration: InputDecoration(
                hintText: "Nombre",
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                errorText: _errorNombre ? "Este campo es obligatorio" : null,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: _errorFirma
                    ? Border.all(color: Colors.red)
                    : null,
              ),
              child: Signature(
                controller: firma1Controller,
                backgroundColor: Colors.white,
              ),
            ),
            if (_errorFirma)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "La firma es obligatoria",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            TextButton(
              onPressed: () => firma1Controller.clear(),
              child: const Text("Limpiar", style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: _isSaving ? null : guardarYExportar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF598CBC),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "GUARDAR",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}