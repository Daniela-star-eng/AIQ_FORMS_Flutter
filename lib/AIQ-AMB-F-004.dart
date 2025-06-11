import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';

class AIQ_AMB_F_004 extends StatefulWidget {
  const AIQ_AMB_F_004({super.key});

  @override
  State<AIQ_AMB_F_004> createState() => _AIQ_AMB_F_004State();
}

class _AIQ_AMB_F_004State extends State<AIQ_AMB_F_004> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController campo1Controller = TextEditingController();
  final TextEditingController campo2Controller = TextEditingController();
  final TextEditingController campo3Controller = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController horaController = TextEditingController();
  String? dropdownSeleccionado;
  String? jaulaSeleccionada;
  final SignatureController firmaController = SignatureController(penStrokeWidth: 2, penColor: const Color(0xFF263A5B));

  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada;

  bool _errorFirma = false;
  String? resultadoSeleccionado;

  int folio = 1;
  int consecutivoMostrado = 1;
  
  get folioGenerado => null;

  @override
  void dispose() {
    campo1Controller.dispose();
    campo2Controller.dispose();
    campo3Controller.dispose();
    fechaController.dispose();
    horaController.dispose();
    firmaController.dispose();
    super.dispose();
  }

  void guardarFormulario() async {
    setState(() {
      _errorFirma = firmaController.isEmpty;
    });

    if (_formKey.currentState!.validate() && !_errorFirma) {
      final folioGenerado = await generarFolio();
      await FirebaseFirestore.instance
          .collection('AIQ-AMB-F-004')
          .doc(folioGenerado) // <--- El ID será el folio
          .set({
        'folio': folioGenerado,
        'fecha': fechaController.text,
        'hora': horaController.text,
        'ubicacion': campo1Controller.text,
        'jaula': jaulaSeleccionada,
        'especie': campo2Controller.text,
        'resultado': resultadoSeleccionado,
        'nombre_prestador': campo3Controller.text,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      await _generarPDF(folioGenerado);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulario guardado en Firebase')),
      );

      await _incrementarFolio();
    } else if (_errorFirma) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La firma es obligatoria')),
      );
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
      folio = prefs.getInt('folio_f004') ?? 1;
    });
  }

  Future<void> _incrementarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    folio++;
    await prefs.setInt('folio_f004', folio);
    setState(() {});
  }

  Future<void> _compartirFormulario() async {
    await Share.share('Folio del formulario: $folio');
  }

  Future<void> _generarPDF(String folioGenerado) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final firmaBytes = await firmaController.isNotEmpty ? await firmaController.toPngBytes() : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Encabezado
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logoImage, width: 80),
              pw.Column(
                children: [
                  pw.Text(
                    'AIQ_AMB-F-004',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF263A5B),
                    ),
                  ),
                  pw.Text(
                    'REGISTRO DE CAPTURA DE FAUNA',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF598CBC),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 80),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),

          // Folio y fecha/hora
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Folio: $folioGenerado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Fecha: ${fechaController.text}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Hora: ${horaController.text}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 16),

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
                    child: pw.Text(campo1Controller.text),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Jaula:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(jaulaSeleccionada ?? ''),
                  ),
                ],
              ),
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8EAF2)),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Especie capturada:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(campo2Controller.text),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Resultados y comentarios:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(resultadoSeleccionado ?? ''),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Nombre y firma
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nombre del prestador:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(campo3Controller.text),
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
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Exportado por AIQ-Forms',
            style: pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF598CBC)),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> guardarEnExcel() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/AIQ_AMB_F_004.xlsx';
    final file = File(filePath);

    ex.Excel excel;
    if (await file.exists()) {
      var bytes = await file.readAsBytes();
      excel = ex.Excel.decodeBytes(bytes);
    } else {
      excel = ex.Excel.createExcel();
      excel.rename('Sheet1', 'Registros');
      excel['Registros'].appendRow([
        'Folio', 'Fecha', 'Hora', 'Ubicación', 'Jaula', 'Especie', 'Resultado', 'Nombre Prestador'
      ]);
    }

    excel['Registros'].appendRow([
      folio,
      fechaController.text,
      horaController.text,
      campo1Controller.text,
      jaulaSeleccionada ?? '',
      campo2Controller.text,
      resultadoSeleccionado ?? '',
      campo3Controller.text,
    ]);

    final excelBytes = excel.encode();
    if (excelBytes != null) {
      await file.writeAsBytes(excelBytes, flush: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Exportado a Excel correctamente!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al exportar a Excel')),
      );
    }
  }

  Future<void> compartirExcel() async {
    print('Intentando compartir Excel...');
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/AIQ_AMB_F_004.xlsx';
    final file = File(filePath);

    if (await file.exists()) {
      print('El archivo existe, compartiendo...');
      await Share.shareXFiles([XFile(filePath)], text: 'Archivo Excel de registros AIQ');
    } else {
      print('El archivo NO existe');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay archivo Excel generado aún')),
      );
    }
  }

  Future<int> obtenerConsecutivoParaFecha(DateTime fecha) async {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final fechaStr = "$dia/$mes/$anio";

    final snapshot = await FirebaseFirestore.instance
        .collection('AIQ-AMB-F-004')
        .where('fecha', isEqualTo: fechaStr)
        .get();

    return snapshot.docs.length + 1;
  }

  Future<String> generarFolio() async {
    if (fechaSeleccionada == null) return "";
    final dia = fechaSeleccionada!.day.toString().padLeft(2, '0');
    final mes = fechaSeleccionada!.month.toString().padLeft(2, '0');
    final anio = fechaSeleccionada!.year.toString();
    final consecutivo = consecutivoMostrado;
    return "AIQAMBF004-$dia-$mes-$anio-$consecutivo";
  }

  void limpiarCampos() {
    campo1Controller.clear();
    campo2Controller.clear();
    campo3Controller.clear();
    fechaController.clear();
    horaController.clear();
    jaulaSeleccionada = null;
    resultadoSeleccionado = null;
    firmaController.clear();
    fechaSeleccionada = null;
    horaSeleccionada = null;
    consecutivoMostrado = 1;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF2),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF263A5B),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                          "TÍTULO DEL FORMULARIO",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          "SUBTÍTULO O DESCRIPCIÓN",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Avenir',
                            color: Color(0xFF598CBC),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "AIQ-AMB-F-004",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF263A5B),
                      fontFamily: 'Avenir',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF598CBC)),
                    ),
                    child: Text(
                      "AIQAMBF004-${fechaSeleccionada != null
                          ? "${fechaSeleccionada!.day.toString().padLeft(2, '0')}-${fechaSeleccionada!.month.toString().padLeft(2, '0')}-${fechaSeleccionada!.year}"
                          : "--/--/----"}-$consecutivoMostrado",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263A5B),
                        fontSize: 14,
                        fontFamily: 'Avenir',
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9), // Fondo azul claro
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Fecha y hora",
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
                              child: TextField(
                                controller: fechaController,
                                readOnly: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "Selecciona la fecha",
                                  hintStyle: const TextStyle(color: Colors.black54),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFFC2C8D9)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onTap: () async {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: fechaSeleccionada ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    final consecutivo = await obtenerConsecutivoParaFecha(picked);
                                    setState(() {
                                      fechaSeleccionada = picked;
                                      fechaController.text =
                                          "${picked.day.toString().padLeft(2, '0')}/"
                                          "${picked.month.toString().padLeft(2, '0')}/"
                                          "${picked.year}";
                                      consecutivoMostrado = consecutivo;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: horaController,
                                readOnly: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "Selecciona la hora",
                                  hintStyle: const TextStyle(color: Colors.black54),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFFC2C8D9)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onTap: () async {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: horaSeleccionada ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      horaSeleccionada = picked;
                                      horaController.text = picked.format(context);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Campo de fecha y hora
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9), // Fondo azul claro
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: campo1Controller,
                          decoration: InputDecoration(
                            hintText: "Escribe la ubicación...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.location_on, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9), // Fondo azul claro
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Jaula",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: jaulaSeleccionada,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.grid_on, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            hintText: "Selecciona la jaula...",
                          ),
                          items: List.generate(
                            9,
                            (index) => DropdownMenuItem(
                              value: (index + 1).toString(),
                              child: Text((index + 1).toString()),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              jaulaSeleccionada = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9), // Fondo azul claro
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Especie capturada",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: campo2Controller,
                          decoration: InputDecoration(
                            hintText: "Escribe la especie...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.pets, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9), // Fondo azul claro
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: resultadoSeleccionado,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.comment, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            hintText: "Selecciona un resultado...",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "cerrada con cebo",
                              child: Text("Cerrada con cebo"),
                            ),
                            DropdownMenuItem(
                              value: "activada sin cebo",
                              child: Text("Activada sin cebo"),
                            ),
                            DropdownMenuItem(
                              value: "activada con cebo",
                              child: Text("Activada con cebo"),
                            ),
                            DropdownMenuItem(
                              value: "captura",
                              child: Text("Captura"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              resultadoSeleccionado = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Firma
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2C8D9), // Fondo azul claro
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Firma prestador de Servicio",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: campo3Controller,
                          decoration: InputDecoration(
                            hintText: "Nombre del prestador",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.person, color: Color(0xFFC2C8D9)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0, top: 2.0),
                            child: Text(
                              'Firma obligatoria',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        guardarFormulario();   // Espera a que termine de guardar
                        await guardarEnExcel();      // Luego exporta a Excel
                      },
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
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: compartirExcel,
                      icon: const Icon(Icons.share),
                      label: const Text("COMPARTIR EXCEL"),
                    ),
                  ),
                ],
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
          Positioned(
            bottom: 24,
            left: 24,
            child: FloatingActionButton(
              heroTag: 'share_formulario',
              backgroundColor: const Color(0xFF263A5B),
              onPressed: _compartirFormulario,
              child: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Compartir',
            ),
          ),
        ],
      ),
    );
  }
}

//quitarle lo de pdf a los últimos forms que realicé
// cambiar las fotos de los forms 
//ver como exportar a excel