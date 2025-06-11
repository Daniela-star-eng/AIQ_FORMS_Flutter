import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart'; // <-- Agrega esta línea
import 'derrames_list.dart'; // Asegúrate de importar la pantalla de la lista
import 'package:flutter/services.dart' show rootBundle; // Agrega esto arriba si no lo tienes
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

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

class DerramesScreen extends StatefulWidget {
  const DerramesScreen({super.key});

  @override
  State<DerramesScreen> createState() => _DerramesScreenState();
}

class _DerramesScreenState extends State<DerramesScreen> {
  double criticidadValue = 1; // 0 = Bajo, 1 = Medio, 2 = Alto
  int areaAfectada = 0;
  int tiempoMinutos = 0; // <-- AGREGA ESTA LÍNEA
  int horasEmpleadas = 0; // <-- Agrega esta línea para definir la variable
  int folio = 1; // Preguntar en que folio van y cambiar el 1 para da seguimiento
  String fechaHoy = "${DateTime.now().day.toString().padLeft(2, '0')}/"
      "${DateTime.now().month.toString().padLeft(2, '0')}/"
      "${DateTime.now().year}";

  DateTime? fechaHoraNotificacion;
  TimeOfDay? horaLlegada;

  final List<String> materiales = [
    "Espuma Contra Incendio",
    "Material Absorbente",
    "Líquido Desengrasante",
    "Agua",
  ];
  final List<int> cantidades = [0, 0, 0, 0];
  final Set<int> seleccionados = {};
  final TextEditingController tiempoController = TextEditingController();
  final TextEditingController horaLlegadaController = TextEditingController();
  String? ubicacionSeleccionada;
  TextEditingController especificarUbicacionController = TextEditingController();
  String? productoSeleccionado;
  TextEditingController especificarProductoController = TextEditingController();

  final SignatureController firma1Controller = SignatureController(penStrokeWidth: 2, penColor: Color(0xFF263A5B));
  final SignatureController firma2Controller = SignatureController(penStrokeWidth: 2, penColor: Color(0xFF263A5B));
  final SignatureController firma3Controller = SignatureController(penStrokeWidth: 2, penColor: Color(0xFF263A5B));

  final TextEditingController nombreNotificaController = TextEditingController();
  final TextEditingController originadoPorController = TextEditingController();
  final TextEditingController vueloMatriculaController = TextEditingController();
  final TextEditingController causaController = TextEditingController();
  final TextEditingController personalController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController fechaHoraNotificacionController = TextEditingController();
  final TextEditingController areaAfectadaController = TextEditingController();
  final TextEditingController tiempoMinutosController = TextEditingController();
  final TextEditingController persona1NombreController = TextEditingController();
  final TextEditingController persona2NombreController = TextEditingController();
  final TextEditingController persona3NombreController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _errorUbicacion = false;
  bool _errorProducto = false;
  bool _errorNombreNotifica = false;
  bool _errorAreaAfectada = false;
  bool _errorHorasEmpleadas = false;
  bool _errorTiempoMinutos = false;
  bool _errorCausa = false;
  bool _errorPersonal = false;
  bool _errorObservaciones = false;
  bool _errorPersona1 = false;
  bool _errorPersona2 = false;
  bool _errorPersona3 = false;
  bool _errorFirma1 = false;
  bool _errorFirma2 = false;
  bool _errorFirma3 = false;
  bool _errorVueloMatricula = false; // <-- Agrega esta línea

  Color getSliderColor(double value) {
    if (value <= 1.5) {
      // Verde a amarillo
      return Color.lerp(Colors.green, Colors.yellow, value / 1.5)!;
    } else {
      // Amarillo a rojo
      return Color.lerp(Colors.yellow, Colors.red, (value - 1.5) / 1.5)!;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarFolio();
  }

  Future<void> _cargarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      folio = prefs.getInt('folio_derrames') ?? 1;
    });
  }

  Future<void> _incrementarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    folio++;
    await prefs.setInt('folio_derrames', folio);
    setState(() {}); // Para actualizar el UI
  }

  @override
  void dispose() {
    firma1Controller.dispose();
    firma2Controller.dispose();
    firma3Controller.dispose();
    tiempoController.dispose();
    especificarUbicacionController.dispose();
    especificarProductoController.dispose();
    nombreNotificaController.dispose();
    originadoPorController.dispose();
    vueloMatriculaController.dispose();
    causaController.dispose();
    personalController.dispose();
    observacionesController.dispose();
    fechaHoraNotificacionController.dispose();
    horaLlegadaController.dispose();
    areaAfectadaController.dispose();
    tiempoMinutosController.dispose();
    persona1NombreController.dispose();
    persona2NombreController.dispose();
    persona3NombreController.dispose();
    super.dispose();
  }

  String get formattedFecha {
    // Usa la fecha seleccionada si existe, si no la de hoy
    final DateTime fecha = fechaHoraNotificacion ?? DateTime.now();
    return "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  String get nombreDocumento {
    return "AIQ-SMS-F013-$formattedFecha-$folio";
  }

  Future<void> _exportarPDF() async {
    try {
      final pdf = pw.Document();

      final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // Convertir firmas a imágenes (si existen)
      final firma1Bytes = await firma1Controller.isNotEmpty ? await firma1Controller.toPngBytes() : null;
      final firma2Bytes = await firma2Controller.isNotEmpty ? await firma2Controller.toPngBytes() : null;
      final firma3Bytes = await firma3Controller.isNotEmpty ? await firma3Controller.toPngBytes() : null;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(50),
          build: (pw.Context context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Image(logoImage, width: 90),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Header(
              level: 0,
              child: pw.Text(
                'NEUTRALIZACION Y LIMPIEZA DE DERRAMES',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Folio: $folio    Fecha: $fechaHoy', style: pw.TextStyle(fontSize: 11)),
            pw.Divider(),

            pw.Text('Nombre de quien notifica: ${nombreNotificaController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Ubicación: ${ubicacionSeleccionada ?? ""}', style: pw.TextStyle(fontSize: 12)),
            if (ubicacionSeleccionada == 'Otro')
              pw.Text('Especificar ubicación: ${especificarUbicacionController.text}', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Criticidad: ${getCriticidadTexto(criticidadValue)}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Producto Derramado: ${productoSeleccionado ?? ""}', style: pw.TextStyle(fontSize: 12)),
            if (productoSeleccionado == 'Otro')
              pw.Text('Especificar producto: ${especificarProductoController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Originado por: ${originadoPorController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Vuelo/Matrícula/etc: ${vueloMatriculaController.text}', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Materiales Utilizados', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Espuma', 'Absorbente', 'Desengrasante', 'Agua'],
              data: [
                [
                  '${cantidades[0]} lt',
                  '${cantidades[1]} kg',
                  '${cantidades[2]} lt',
                  '${cantidades[3]} lt',
                ]
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Text('Área afectada: ${areaAfectadaController.text} m²', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Tiempo empleado: ${horasEmpleadas} h ${tiempoMinutosController.text} min', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Causa del derrame:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(causaController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Personal y vehículos que atienden:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(personalController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Observaciones / Comentarios:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(observacionesController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 16),
            pw.Text('Firmas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Oficial/Operaciones:\n${persona1NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma1Bytes != null) pw.Image(pw.MemoryImage(firma1Bytes), width: 60, height: 30),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Personal SSEI:\n${persona2NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma2Bytes != null) pw.Image(pw.MemoryImage(firma2Bytes), width: 60, height: 30),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Empresa:\n${persona3NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma3Bytes != null) pw.Image(pw.MemoryImage(firma3Bytes), width: 60, height: 30),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Solo mostrar el PDF (no compartir)
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      // Si quieres guardar el archivo localmente, puedes dejar esto:
      // final output = await getTemporaryDirectory();
      // final file = File('${output.path}/reporte_derrames.pdf');
      // await file.writeAsBytes(await pdf.save());

    } catch (e, st) {
      print('Error al exportar PDF: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar PDF: $e')),
        );
      }
    }
  }

  Future<void> _compartirPDF() async {
    try {
      final pdf = pw.Document();

      final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // Convertir firmas a imágenes (si existen)
      final firma1Bytes = await firma1Controller.isNotEmpty ? await firma1Controller.toPngBytes() : null;
      final firma2Bytes = await firma2Controller.isNotEmpty ? await firma2Controller.toPngBytes() : null;
      final firma3Bytes = await firma3Controller.isNotEmpty ? await firma3Controller.toPngBytes() : null;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(50),
          build: (pw.Context context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Image(logoImage, width: 90),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Header(
              level: 0,
              child: pw.Text(
                'NEUTRALIZACION Y LIMPIEZA DE DERRAMES',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Folio: $folio    Fecha: $fechaHoy', style: pw.TextStyle(fontSize: 11)),
            pw.Divider(),

            pw.Text('Nombre de quien notifica: ${nombreNotificaController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Ubicación: ${ubicacionSeleccionada ?? ""}', style: pw.TextStyle(fontSize: 12)),
            if (ubicacionSeleccionada == 'Otro')
              pw.Text('Especificar ubicación: ${especificarUbicacionController.text}', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Criticidad: ${getCriticidadTexto(criticidadValue)}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Producto Derramado: ${productoSeleccionado ?? ""}', style: pw.TextStyle(fontSize: 12)),
            if (productoSeleccionado == 'Otro')
              pw.Text('Especificar producto: ${especificarProductoController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Originado por: ${originadoPorController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Vuelo/Matrícula/etc: ${vueloMatriculaController.text}', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Materiales Utilizados', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Espuma', 'Absorbente', 'Desengrasante', 'Agua'],
              data: [
                [
                  '${cantidades[0]} lt',
                  '${cantidades[1]} kg',
                  '${cantidades[2]} lt',
                  '${cantidades[3]} lt',
                ]
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Text('Área afectada: ${areaAfectadaController.text} m²', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Tiempo empleado: ${horasEmpleadas} h ${tiempoMinutosController.text} min', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Causa del derrame:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(causaController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Personal y vehículos que atienden:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(personalController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Observaciones / Comentarios:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(observacionesController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 16),
            pw.Text('Firmas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Oficial/Operaciones:\n${persona1NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma1Bytes != null) pw.Image(pw.MemoryImage(firma1Bytes), width: 60, height: 30),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Personal SSEI:\n${persona2NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma2Bytes != null) pw.Image(pw.MemoryImage(firma2Bytes), width: 60, height: 30),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Empresa:\n${persona3NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma3Bytes != null) pw.Image(pw.MemoryImage(firma3Bytes), width: 60, height: 30),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      
      // Guardar el PDF en un archivo temporal
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$nombreDocumento.pdf');
      await file.writeAsBytes(await pdf.save());

      // Compartir el archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte de Derrames AIQ',
      );
    } catch (e, st) {
      print('Error al compartir PDF: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir PDF: $e')),
        );
      }
    }
  }

  Future<void> guardarFormulario() async {
    final areaAfectadaValue = int.tryParse(areaAfectadaController.text) ?? 0;
    final tiempoMinutosValue = int.tryParse(tiempoMinutosController.text) ?? 0;

    await FirebaseFirestore.instance.collection('AIQ-SMS-F013').doc(nombreDocumento).set({
      'folio': folio,
      'fecha': fechaHoy, 
      'nombreNotifica': nombreNotificaController.text,
      'ubicacion': ubicacionSeleccionada,
      'especificarUbicacion': especificarUbicacionController.text,
      'criticidad': getCriticidadTexto(criticidadValue),
      'producto': productoSeleccionado,
      'especificarProducto': especificarProductoController.text,
      'cantidades': {
        'Espuma Contra Incendio': cantidades[0],
        'Material Absorbente': cantidades[1],
        'Líquido Desengrasante': cantidades[2],
        'Agua': cantidades[3],
      },
      'areaAfectada': areaAfectadaValue,
      'horasEmpleadas': horasEmpleadas,
      'tiempoMinutos': tiempoMinutosValue,
      'causaDerrame': causaController.text,
      'personalVehiculos': personalController.text,
      'observaciones': observacionesController.text,
      'timestamp': FieldValue.serverTimestamp(),
      // Puedes agregar más campos aquí si lo necesitas
    });
  }

  String getCriticidadTexto(double value) {
    switch (value.round()) {
      case 0:
        return 'Bajo';
      case 1:
        return 'Medio';
      case 2:
        return 'Alto';
      default:
        return 'Medio';
    }
  }

  void guardarYExportar() async {
    setState(() {
      _errorUbicacion = ubicacionSeleccionada == null || ubicacionSeleccionada!.isEmpty;
      _errorProducto = productoSeleccionado == null || productoSeleccionado!.isEmpty;
      _errorNombreNotifica = nombreNotificaController.text.trim().isEmpty;
      _errorAreaAfectada = areaAfectadaController.text.trim().isEmpty;
      _errorHorasEmpleadas = horasEmpleadas == 0;
      _errorTiempoMinutos = tiempoMinutosController.text.trim().isEmpty;
      _errorCausa = causaController.text.trim().isEmpty;
      _errorPersonal = personalController.text.trim().isEmpty;
      _errorObservaciones = observacionesController.text.trim().isEmpty;
      _errorPersona1 = persona1NombreController.text.trim().isEmpty;
      _errorPersona2 = persona2NombreController.text.trim().isEmpty;
      _errorPersona3 = persona3NombreController.text.trim().isEmpty;
      _errorFirma1 = firma1Controller.isEmpty;
      _errorFirma2 = firma2Controller.isEmpty;
      _errorFirma3 = firma3Controller.isEmpty;
      _errorVueloMatricula = vueloMatriculaController.text.trim().isEmpty;
    });

    if (_errorUbicacion ||
        _errorProducto ||
        _errorNombreNotifica ||
        _errorAreaAfectada ||
        _errorHorasEmpleadas ||
        _errorTiempoMinutos ||
        _errorCausa ||
        _errorPersonal ||
        _errorObservaciones ||
        _errorPersona1 ||
        _errorPersona2 ||
        _errorPersona3 ||
        _errorFirma1 ||
        _errorFirma2 ||
        _errorFirma3 ||
        _errorVueloMatricula) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos obligatorios')),
      );
      return;
    }

    await guardarFormulario();

    // Genera y guarda el PDF localmente
    final pdf = await _generarPDFyGuardar(); // Debes adaptar tu función para que retorne el File
    if (pdf != null) {
      await logoutGoogle(); // <-- Esto fuerza el logout
      await subirPDFaDrive(pdf);
      // El feedback de éxito/fracaso ya se da en subirPDFaDrive
    }

    await _incrementarFolio();
  }

  Future<File?> _generarPDFyGuardar() async {
    try {
      final pdf = pw.Document();
      final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // Convertir firmas a imágenes (si existen)
      final firma1Bytes = await firma1Controller.isNotEmpty ? await firma1Controller.toPngBytes() : null;
      final firma2Bytes = await firma2Controller.isNotEmpty ? await firma2Controller.toPngBytes() : null;
      final firma3Bytes = await firma3Controller.isNotEmpty ? await firma3Controller.toPngBytes() : null;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(50),
          build: (pw.Context context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Image(logoImage, width: 90),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Header(
              level: 0,
              child: pw.Text(
                'NEUTRALIZACION Y LIMPIEZA DE DERRAMES',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Folio: $folio    Fecha: $fechaHoy', style: pw.TextStyle(fontSize: 11)),
            pw.Divider(),

            pw.Text('Nombre de quien notifica: ${nombreNotificaController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Ubicación: ${ubicacionSeleccionada ?? ""}', style: pw.TextStyle(fontSize: 12)),
            if (ubicacionSeleccionada == 'Otro')
              pw.Text('Especificar ubicación: ${especificarUbicacionController.text}', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Criticidad: ${getCriticidadTexto(criticidadValue)}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Producto Derramado: ${productoSeleccionado ?? ""}', style: pw.TextStyle(fontSize: 12)),
            if (productoSeleccionado == 'Otro')
              pw.Text('Especificar producto: ${especificarProductoController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Originado por: ${originadoPorController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Vuelo/Matrícula/etc: ${vueloMatriculaController.text}', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Materiales Utilizados', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Espuma', 'Absorbente', 'Desengrasante', 'Agua'],
              data: [
                [
                  '${cantidades[0]} lt',
                  '${cantidades[1]} kg',
                  '${cantidades[2]} lt',
                  '${cantidades[3]} lt',
                ]
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Text('Área afectada: ${areaAfectadaController.text} m²', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Tiempo empleado: ${horasEmpleadas} h ${tiempoMinutosController.text} min', style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Causa del derrame:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(causaController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Personal y vehículos que atienden:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(personalController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 8),
            pw.Text('Observaciones / Comentarios:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text(observacionesController.text, style: pw.TextStyle(fontSize: 12)),

            pw.SizedBox(height: 16),
            pw.Text('Firmas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Oficial/Operaciones:\n${persona1NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma1Bytes != null) pw.Image(pw.MemoryImage(firma1Bytes), width: 60, height: 30),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Personal SSEI:\n${persona2NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma2Bytes != null) pw.Image(pw.MemoryImage(firma2Bytes), width: 60, height: 30),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Empresa:\n${persona3NombreController.text}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10)),
                    if (firma3Bytes != null) pw.Image(pw.MemoryImage(firma3Bytes), width: 60, height: 30),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$nombreDocumento.pdf');
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

  //Google Drive - Comienza lo de Google Drive Para comenzar el login
  Future<void> subirPDFaDrive(File pdfFile) async {
    final googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        // Usuario canceló el login
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión cancelado. No se subió el PDF.')),
        );
        return;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
      final driveFile = drive.File();
      driveFile.name = '$nombreDocumento.pdf';
      driveFile.parents = ['19OnlCEtrpzbWd8OEViZyTha11OZRuDY_'];

      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );
      final fileId = response.id;
      final fileUrl = 'https://drive.google.com/file/d/$fileId/view';
      print('Archivo subido: $fileUrl');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF subido a Google Drive.\nAbrir: $fileUrl'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () async {
              // Si tienes url_launcher, puedes abrir el enlace así:
              // await launchUrl(Uri.parse(fileUrl));
            },
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      print('Error al subir PDF a Drive: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir PDF a Drive: $e')),
      );
    }
  }

  Future<void> logoutGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    await googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final sliderColor = getSliderColor(criticidadValue);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE8EAF2),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF263A5B),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "NEUTRALIZACION Y LIMPIEZA\n",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Avenir',
                              color: Color(0xFF263A5B),
                            ),
                          ),
                          TextSpan(
                            text: "DE DERRAMES",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Avenir',
                              color: Color(0xFF598CBC),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const Text(
                    "AIQ-SMS-F013",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF263A5B),
                      fontFamily: 'Avenir',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Datos de notificación
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
                          "Datos de Notificación",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Folio: $folio",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                            Text(
                              "Fecha: $fechaHoy",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        //Fecha y hora de notificacion
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: fechaHoraNotificacionController,
                                  readOnly: true,
                                  cursorColor: const Color(0xFF263A5B),
                                  style: const TextStyle(color: Color(0xFF263A5B)),
                                  decoration: const InputDecoration(
                                    labelText: "Fecha/Hora de Notificación",
                                    labelStyle: TextStyle(color: Colors.grey),
                                    icon: Icon(Icons.calendar_today, color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  onTap: () async {
                                    FocusScope.of(context).requestFocus(FocusNode()); // Quita el teclado
                                    final fecha = await showDatePicker(
                                      context: context,
                                      initialDate: fechaHoraNotificacion ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (fecha != null) {
                                      final hora = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(fechaHoraNotificacion ?? DateTime.now()),
                                      );
                                      if (hora != null) {
                                        final seleccionada = DateTime(
                                          fecha.year, fecha.month, fecha.day, hora.hour, hora.minute,
                                        );
                                        setState(() {
                                          fechaHoraNotificacion = seleccionada;
                                          fechaHoraNotificacionController.text =
                                              "${fecha.day.toString().padLeft(2, '0')}/"
                                              "${fecha.month.toString().padLeft(2, '0')}/"
                                              "${fecha.year} ${hora.format(context)}";
                                        });
                                      }
                                    }
                                  },
                                ),
                                
                            ),
                          ),

                          //Hora de llegada al lugar
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: horaLlegadaController,
                                readOnly: true,
                                cursorColor: const Color(0xFF263A5B),
                                style: const TextStyle(color: Color(0xFF263A5B)),
                                decoration: const InputDecoration(
                                  labelText: "Hora de llegada",
                                  labelStyle: TextStyle(color: Colors.grey),
                                  icon: Icon(Icons.access_time, color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                                onTap: () async {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: horaLlegada ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      horaLlegada = picked;
                                      horaLlegadaController.text = picked.format(context);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                        ),
                        //Nombre de quien notifica
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: nombreNotificaController,
                            decoration: InputDecoration(
                              labelText: "Nombre de quien notifica",
                              labelStyle: TextStyle(color: Colors.grey),
                              icon: Icon(Icons.person, color: Colors.grey),
                              border: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _errorNombreNotifica ? Colors.red : Color(0xFF263A5B),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _errorNombreNotifica ? Colors.red : Colors.grey,
                                ),
                              ),
                              errorText: _errorNombreNotifica ? 'Campo obligatorio' : null,
                            ),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ubicación del derrame
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
                          "Ubicacion de Derrame",
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
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonFormField<String>(
                            value: ubicacionSeleccionada,
                            decoration: InputDecoration(
                              labelText: "Ubicación del Derrame",
                              labelStyle: TextStyle(color: Colors.grey),
                              icon: Icon(Icons.location_on, color: Colors.grey),
                              border: InputBorder.none,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _errorUbicacion ? Colors.red : Colors.grey,
                                ),
                              ),
                              errorText: _errorUbicacion ? 'Campo obligatorio' : null,
                            ),
                            items: ['Plataforma', 'Pista', 'Rodaje', 'Hangares','Otro']
                                .map((opcion) => DropdownMenuItem(
                                      value: opcion,
                                      child: Text(opcion),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                ubicacionSeleccionada = value;
                              });
                            },
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: Color(0xFF263A5B)),
                          ),
                        ),
                        if (ubicacionSeleccionada == 'Otro')
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: especificarUbicacionController,
                                cursorColor: const Color(0xFF263A5B),
                                style: const TextStyle(color: Color(0xFF263A5B)),
                                decoration: const InputDecoration(
                                  labelText: "Especifique",
                                  labelStyle: TextStyle(color: Colors.grey),
                                  icon: Icon(Icons.edit_location_alt, color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Datos del derrame con slider
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
                          "Datos del Derrame",
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Criticidad",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Avenir',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263A5B),
                                ),
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: getSliderColor(criticidadValue),
                                  inactiveTrackColor: getSliderColor(criticidadValue).withOpacity(0.3),
                                  thumbColor: getSliderColor(criticidadValue),
                                  overlayColor: Colors.transparent,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                                  trackHeight: 8,
                                ),
                                child: Slider(
                                  value: criticidadValue,
                                  min: 0,
                                  max: 2,
                                  divisions: 2,
                                  label: getCriticidadTexto(criticidadValue),
                                  onChanged: (value) {
                                    setState(() {
                                      criticidadValue = value;
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text("Bajo", style: TextStyle(color: Colors.grey)),
                                    Text("Medio", style: TextStyle(color: Colors.grey)),
                                    Text("Alto", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Campo: Líquido Derramado
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: productoSeleccionado,
                                decoration: const InputDecoration(
                                  labelText: "Producto Derramado",
                                  labelStyle: TextStyle(color: Colors.grey),
                                  icon: Icon(Icons.water_drop_rounded, color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                                items: [
                                  'Combustible',
                                  'Aceite',
                                  'Hidraulico',
                                  'Otro',
                                ].map((opcion) => DropdownMenuItem(
                                      value: opcion,
                                      child: Text(opcion),
                                    )).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    productoSeleccionado = value;
                                  });
                                },
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Color(0xFF263A5B)),
                              ),
                              if (productoSeleccionado == 'Otro')
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: TextField(
                                      controller: especificarProductoController,
                                      cursorColor: const Color(0xFF263A5B),
                                      style: const TextStyle(color: Color(0xFF263A5B)),
                                      decoration: const InputDecoration(
                                        labelText: "Especifique",
                                        labelStyle: TextStyle(color: Colors.grey),
                                        icon: Icon(Icons.edit, color: Colors.grey),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Campo: Originado por...
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: originadoPorController,
                            cursorColor: const Color(0xFF263A5B),
                            style: const TextStyle(color: Color(0xFF263A5B)),
                            decoration: const InputDecoration(
                              labelText: "Originado por...",
                              labelStyle: TextStyle(color: Colors.grey),
                              icon: Icon(Icons.airplanemode_active_rounded, color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start, // Alinea a la izquierda
                          children: [
                            Text(
                              "No. Vuelo",
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 15, // Un poquito más grande
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "/",
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Matrícula",
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "/",
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "No. Económico",
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "/",
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Compañía",
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: vueloMatriculaController,
                            cursorColor: const Color(0xFF263A5B),
                            style: const TextStyle(color: Color(0xFF263A5B)),
                            decoration: InputDecoration(
                              labelText: "Escriba la información aquí...",
                              labelStyle: const TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _errorVueloMatricula ? Colors.red : Color(0xFF263A5B),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: _errorVueloMatricula ? Colors.red : Colors.transparent,
                                ),
                              ),
                              errorText: _errorVueloMatricula ? 'Campo obligatorio' : null,
                            ),
                            onChanged: (_) {
                              setState(() {
                                _errorVueloMatricula = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Material utilizado (LITROS) ---
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Material utilizado",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263A5B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        
                        // Títulos en una sola línea
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            materiales.length,
                            (index) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 4),
                                child: Text(
                                  materiales[index],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF263A5B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        // Contadores en una sola línea
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            materiales.length,
                            (index) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  height: 48,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: TextFormField(
                                          initialValue: cantidades[index].toString(),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF263A5B),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              final val = int.tryParse(value) ?? 0;
                                              cantidades[index] = val < 0 ? 0 : val;
                                            });
                                          },
                                        ),
                                      ),
                                      Text(
                                        index == 1 ? ' kg' : ' lt',
                                        style: const TextStyle(
                                          color: Color(0xFF263A5B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Área afectada y tiempo empleado con títulos e íconos
                        Row(
                          children: [
                            // Área afectada
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Área afectada (m²)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF263A5B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    height: 48,
                                    child: TextFormField(
                                      controller: areaAfectadaController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                        hintText: "Ej: 10",
                                        hintStyle: TextStyle(color: Colors.grey),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _errorAreaAfectada ? Colors.red : Color(0xFF263A5B),
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _errorAreaAfectada ? Colors.red : Colors.transparent,
                                          ),
                                        ),
                                        errorText: _errorAreaAfectada ? 'Campo obligatorio' : null,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF263A5B),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          areaAfectada = int.tryParse(value) ?? 0;
                                          _errorAreaAfectada = false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tiempo empleado (horas y minutos)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Tiempo empleado",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF263A5B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      // Horas
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          height: 48,
                                          margin: const EdgeInsets.only(right: 4),
                                          child: TextFormField(
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                              hintText: "Horas",
                                              hintStyle: TextStyle(color: Colors.grey),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: _errorHorasEmpleadas ? Colors.red : Color(0xFF263A5B),
                                                ),
                                              ),
                                              enabledBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: _errorHorasEmpleadas ? Colors.red : Colors.transparent,
                                                ),
                                              ),
                                              errorText: _errorHorasEmpleadas ? 'Campo obligatorio' : null,
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF263A5B),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                horasEmpleadas = int.tryParse(value) ?? 0;
                                                _errorHorasEmpleadas = false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Minutos
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          height: 48,
                                          margin: const EdgeInsets.only(left: 4),
                                          child: TextFormField(
                                            controller: tiempoMinutosController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                              hintText: "Min",
                                              hintStyle: TextStyle(color: Colors.grey),
                                              focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: _errorTiempoMinutos ? Colors.red : Color(0xFF263A5B),
                                                ),
                                              ),
                                              enabledBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: _errorTiempoMinutos ? Colors.red : Colors.transparent,
                                                ),
                                              ),
                                              errorText: _errorTiempoMinutos ? 'Campo obligatorio' : null,
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF263A5B),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                tiempoMinutos = int.tryParse(value) ?? 0;
                                                _errorTiempoMinutos = false;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9), // Fondo igual que los demás bloques
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFF263A5B), size: 20),
                            SizedBox(width: 6),
                            Text(
                              "Causa del derrame",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: causaController,
                            maxLines: 2,
                            cursorColor: const Color(0xFF263A5B),
                            style: const TextStyle(color: Color(0xFF263A5B)),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintText: "Describa brevemente la causa...",
                              hintStyle: const TextStyle(color: Colors.grey),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _errorCausa ? Colors.red : Color(0xFF263A5B),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _errorCausa ? Colors.red : Colors.transparent,
                                ),
                              ),
                              errorText: _errorCausa ? 'Campo obligatorio' : null,
                            ),
                            onChanged: (_) {
                              setState(() {
                                _errorCausa = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        Row(
                          children: const [
                            Icon(Icons.groups_rounded, color: Color(0xFF263A5B), size: 20),
                            SizedBox(width: 6),
                            Text(
                              "Personal y vehículos que atienden",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: personalController,
                            maxLines: 2,
                            cursorColor: const Color(0xFF263A5B),
                            style: const TextStyle(color: Color(0xFF263A5B)),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintText: "Describa brevemente...",
                              hintStyle: const TextStyle(color: Colors.grey),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _errorPersonal ? Colors.red : Color(0xFF263A5B),
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: _errorPersonal ? Colors.red : Colors.transparent,
                                ),
                              ),
                              errorText: _errorPersonal ? 'Campo obligatorio' : null,
                            ),
                            onChanged: (_) {
                              setState(() {
                                _errorPersonal = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        Row(
                          children: const [
                            Icon(Icons.comment_rounded, color: Color(0xFF263A5B), size: 20),
                            SizedBox(width: 6),
                            Text(
                              "Observaciones / Comentarios",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263A5B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: observacionesController,
                            maxLines: 2,
                            cursorColor: const Color(0xFF263A5B),
                            style: const TextStyle(color: Color(0xFF263A5B)),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintText: "Escriba aquí...",
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Oficial de Operaciones y/o Supervisor SMS
                      const Text(
                        "Nombre y Firma del Oficial de Operaciones y/o Supervisor SMS",
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
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _errorPersona1 ? Colors.red : Colors.transparent,
                            ),
                          ),
                          errorText: _errorPersona1 ? 'Campo obligatorio' : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Signature(
                          controller: firma1Controller,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => firma1Controller.clear(),
                        child: const Text("Limpiar", style: TextStyle(fontSize: 12)),
                      ),
                      if (_errorFirma1)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                          child: Text(
                            'Firma obligatoria',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Personal del SSEI
                      const Text(
                        "Nombre y Firma del Personal del SSEI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF263A5B),
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 6),
                      TextField(
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
                        ),
                        controller: persona2NombreController,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Signature(
                          controller: firma2Controller,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => firma2Controller.clear(),
                        child: const Text("Limpiar", style: TextStyle(fontSize: 12)),
                      ),
                      if (_errorFirma2)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                          child: Text(
                            'Firma obligatoria',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Representante de la empresa involucrada
                      const Text(
                        "Representante de la empresa involucrada",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF263A5B),
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 6),
                      TextField(
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
                        ),
                        controller: persona3NombreController,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Signature(
                          controller: firma3Controller,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => firma3Controller.clear(),
                        child: const Text("Limpiar", style: TextStyle(fontSize: 12)),
                      ),
                      if (_errorFirma3)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                          child: Text(
                            'Firma obligatoria',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: guardarYExportar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF598CBC),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        "GUARDAR",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),              
                ],
              ),
            ),
          ),
        ),
        // Imagen en la esquina inferior derecha del logo del AIQ
        Positioned(
          bottom: 16,
          right: 16,
          child: Opacity(
            opacity: 0.85,
            child: Image.asset(
              'assets/AIQ_LOGO_.png',
              width: 100,
            ),
          ),
        ),
        // Icono de compartir en la esquina inferior izquierda
        Positioned(
          bottom: 24,
          left: 24,
          child: FloatingActionButton(
            heroTag: 'share_pdf',
            backgroundColor: const Color(0xFF263A5B),
            onPressed: _compartirPDF,
            child: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Compartir PDF',
          ),
        ),
      ],
    );
  }
}