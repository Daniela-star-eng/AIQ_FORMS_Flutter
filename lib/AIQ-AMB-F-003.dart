import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AIQAMBF003Screen extends StatefulWidget {
  const AIQAMBF003Screen({super.key});

  @override
  State<AIQAMBF003Screen> createState() => _FaunaScreenState();
}

class _FaunaScreenState extends State<AIQAMBF003Screen> {
  int folio = 1;
  String fechaHoy = "${DateTime.now().day.toString().padLeft(2, '0')}/"
      "${DateTime.now().month.toString().padLeft(2, '0')}/"
      "${DateTime.now().year}";

  final TextEditingController especieController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController responsableController = TextEditingController();
  final TextEditingController fechaHoraNotificacionController = TextEditingController();
  final TextEditingController horaLlegadaController = TextEditingController();
  final TextEditingController impactoController = TextEditingController();

  DateTime? fechaHoraNotificacion;
  TimeOfDay? horaLlegada;

  final SignatureController firmaController = SignatureController(penStrokeWidth: 2, penColor: Color(0xFF263A5B));

  final _formKey = GlobalKey<FormState>();
  bool _errorEspecie = false;
  bool _errorCantidad = false;
  bool _errorUbicacion = false;
  bool _errorResponsable = false;
  bool _errorFirma = false;

  String? destinoRestosSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarFolio();
  }

  Future<void> _cargarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      folio = prefs.getInt('folio_fauna') ?? 1;
    });
  }

  Future<void> _incrementarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    folio++;
    await prefs.setInt('folio_fauna', folio);
    setState(() {});
  }

  @override
  void dispose() {
    especieController.dispose();
    cantidadController.dispose();
    ubicacionController.dispose();
    observacionesController.dispose();
    responsableController.dispose();
    fechaHoraNotificacionController.dispose();
    horaLlegadaController.dispose();
    firmaController.dispose();
    impactoController.dispose(); // Liberar el controlador de impacto
    super.dispose();
  }

  Future<void> _exportarPDF() async {
    try {
      final pdf = pw.Document();

      final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      final firmaBytes = await firmaController.isNotEmpty ? await firmaController.toPngBytes() : null;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // Encabezado con logo y título
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 80),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'MONITOREO DE RESTOS DE FAUNA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF263A5B),
                      ),
                    ),
                    pw.Text(
                      'EN ÁREAS OPERATIVAS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF598CBC),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'AIQ_AMB-F-003',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF263A5B),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(width: 80), // Espacio para equilibrar el logo
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),

            // Folio y fecha
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Folio: $folio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Fecha: $fechaHoy', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 12),

            // Tabla de datos principales
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFC2C8D9), width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8EAF2)),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Ubicación:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(ubicacionController.text),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Partes encontradas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(cantidadController.text),
                    ),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8EAF2)),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Especie:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(especieController.text),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('¿Se reportó impacto?', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        impactoController.text, // Usa el controlador correspondiente
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8EAF2)),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Destino de los restos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        destinoRestosSeleccionado ?? '',
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Observaciones:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(observacionesController.text),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Responsable y firma
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFC2C8D9),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Responsable:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(responsableController.text),
                    ],
                  ),
                  if (firmaBytes != null)
                    pw.Column(
                      children: [
                        pw.Text('Firma:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Image(pw.MemoryImage(firmaBytes), width: 120, height: 60),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
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

      final firmaBytes = await firmaController.isNotEmpty ? await firmaController.toPngBytes() : null;

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
                'Monitoreo de restos de fauna en áreas operativas',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Folio: $folio    Fecha: $fechaHoy', style: pw.TextStyle(fontSize: 11)),
            pw.Divider(),

            pw.Text('Especie: ${especieController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Cantidad: ${cantidadController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Ubicación: ${ubicacionController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Observaciones: ${observacionesController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Text('Responsable: ${responsableController.text}', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            pw.Text('Firma', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (firmaBytes != null)
              pw.Image(pw.MemoryImage(firmaBytes), width: 120, height: 60),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reporte_fauna.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte de Monitoreo de Fauna AIQ',
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
    await FirebaseFirestore.instance.collection('AIQ_AMB_F-003').doc(folio.toString()).set({
      'folio': folio,
      'fecha': fechaHoy,
      'especie': especieController.text,
      'cantidad': cantidadController.text,
      'ubicacion': ubicacionController.text,
      'observaciones': observacionesController.text,
      'responsable': responsableController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void guardarYExportar() async {
    setState(() {
      _errorEspecie = especieController.text.trim().isEmpty;
      _errorCantidad = cantidadController.text.trim().isEmpty;
      _errorUbicacion = ubicacionController.text.trim().isEmpty;
      _errorResponsable = responsableController.text.trim().isEmpty;
      _errorFirma = firmaController.isEmpty;
    });

    if (_errorEspecie ||
        _errorCantidad ||
        _errorUbicacion ||
        _errorResponsable ||
        _errorFirma) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos obligatorios')),
      );
      return;
    }

    await guardarFormulario();
    await _exportarPDF();
    await _incrementarFolio();
  }

  String _nombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MONITOREO DE RESTOS DE FAUNA",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          "EN ÁREAS OPERATIVAS",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Avenir',
                            color: Color(0xFF598CBC), // Nuevo color solo para esta línea
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "AIQ_AMB-F-003",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF263A5B),
                      fontFamily: 'Avenir',
                    ),
                    textAlign: TextAlign.center,
                    
                  ),
                  const SizedBox(height: 8), // Espacio opcional
                  Text(
                    "Folio: $folio",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  const SizedBox(height: 24),         
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Bitácora: ${_nombreMes(DateTime.now().month)} ${DateTime.now().year}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF263A5B),
                          fontFamily: 'Avenir'
                        ),
                      ),
                    ),
                  ),
                  // Fechas y horas
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
                          "FECHA Y HORA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                    labelText: "Fecha",
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
                                      setState(() {
                                        fechaHoraNotificacion = fecha;
                                        fechaHoraNotificacionController.text =
                                            "${fecha.day.toString().padLeft(2, '0')}/"
                                            "${fecha.month.toString().padLeft(2, '0')}/"
                                            "${fecha.year}";
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
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
                                    prefixIcon: Icon(Icons.access_time, color: Color(0xFFC2C8D9)),
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
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Datos generales
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Ubicación
                        const Text("Ubicación", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263A5B))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: ubicacionController,
                          decoration: InputDecoration(
                            hintText: "Escribe aquí...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _errorUbicacion ? 'Campo obligatorio' : null,
                            prefixIcon: const Icon(Icons.location_on, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16), // <-- Esto centra el texto con el icono
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Partes encontradas
                        const Text("Partes encontradas", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263A5B))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: cantidadController,
                          decoration: InputDecoration(
                            hintText: "Escribe aquí...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _errorCantidad ? 'Campo obligatorio' : null,
                            prefixIcon: const Icon(Icons.format_list_numbered, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16), // <-- Esto centra el texto con el icono

                          ),
                        ),
                        const SizedBox(height: 12),

                        // Especie
                        const Text("Especie", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263A5B))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: especieController,
                          decoration: InputDecoration(
                            hintText: "Escribe aquí",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _errorEspecie ? 'Campo obligatorio' : null,
                            prefixIcon: const Icon(Icons.pets, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16), // <-- Esto centra el texto con el icono

                          ),
                        ),
                        const SizedBox(height: 12),

                        // ¿Se reportó impacto?
                        const Text("¿Se reportó impacto?", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263A5B))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: impactoController,
                          decoration: InputDecoration(
                            hintText: "Escribe aquí...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.report_problem, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16), // <-- Esto centra el texto con el icono

                          ),
                        ),
                        const SizedBox(height: 12),

                        // Destino de los restos
                        const Text("Destino de los restos", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263A5B))),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: destinoRestosSeleccionado,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.delete, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            hintText: "Selecciona una opción...",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "Entierro",
                              child: Text("Entierro"),
                            ),
                            DropdownMenuItem(
                              value: "Incineración",
                              child: Text("Incineración"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              destinoRestosSeleccionado = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Observaciones
                        const Text("Observaciones", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF263A5B))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: observacionesController,
                          maxLines: 2,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: "Escribe aquí...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.comment, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Responsable y firma
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
                          "Responsable del registro",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: responsableController,
                          decoration: InputDecoration(
                            hintText: "Nombre del responsable",
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
                                color: _errorResponsable ? Colors.red : Colors.transparent,
                              ),
                            ),
                            errorText: _errorResponsable ? 'Campo obligatorio' : null,
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
                            controller: firmaController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () => firmaController.clear(),
                          child: const Text("Limpiar", style: TextStyle(fontSize: 12)),
                        ),
                        if (_errorFirma)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Text(
                              'Firma obligatoria',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
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