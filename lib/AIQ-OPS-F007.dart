import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:signature/signature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AIQ-OPS-F007_LIST.dart';

class AIQOPSF007Screen extends StatefulWidget {
  const AIQOPSF007Screen({super.key});

  @override
  State<AIQOPSF007Screen> createState() => _AIQOPSF007ScreenState();
}

class _AIQOPSF007ScreenState extends State<AIQOPSF007Screen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TextEditingController fechaController = TextEditingController();
  TextEditingController horaController = TextEditingController();
  TextEditingController observacionesGeneralesController = TextEditingController();
  TextEditingController enteradoNombreController = TextEditingController();
  TextEditingController enteradoFechaController = TextEditingController();
  final SignatureController enteradoFirmaController = SignatureController(penStrokeWidth: 4, penColor: Colors.black);

  // Mapa para guardar la selección de cada ítem
  final Map<String, String> _selecciones = {};

  int _inspeccionSeleccionada = 1;
  int folio = 1;

  @override
  void dispose() {
    fechaController.dispose();
    horaController.dispose();
    observacionesGeneralesController.dispose();
    enteradoNombreController.dispose();
    enteradoFechaController.dispose();
    enteradoFirmaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargarFolio();
  }

  Future<void> _cargarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      folio = prefs.getInt('folio_f007') ?? 1;
    });
  }

  Future<void> _incrementarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    folio++;
    await prefs.setInt('folio_f007', folio);
    setState(() {}); // Para actualizar el UI
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFEAEFF8),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con botón de regreso funcional
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "LISTA DE VERIFICACIÓN PARA LA INSPECCIÓN DIARIA",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B)
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "(ANTES DE LA APERTURA DE OPERACIONES)",
                            style: TextStyle(color: Color.fromARGB(255, 66, 66, 66), fontSize: 15),
                          ),
                          Text(
                            "AIQ-OPS-F007",
                            style: TextStyle(color: Color(0xFF598CBC), fontSize: 19, fontWeight: FontWeight.bold, fontFamily: 'Avenir'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "DATOS DE LA INSPECCIÓN",
                              style: TextStyle(fontWeight: FontWeight.bold , fontSize: 20, fontFamily: 'Avenir', color: Color(0xFF263A5B)),
                            ),
                          ],
                        ),
                        
                        Row(
                          children: [
                            const Text(
                              "Numero de Inspección: ",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263A5B),
                                ),
                            ),
                            SizedBox(width: 8),
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

                  // Botones de selección
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                        SizedBox(
                        
                        height: 60, 
                        child: Chip(
                          label: const Text(
                          "Satisfactorio(✔)",
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                            fontWeight: FontWeight.normal,
                          ),
                          ),
                          backgroundColor: Color(0xFFDBEDFF),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        ),
                      SizedBox(
                         child: Chip(
                          label: const Text(
                        "Inadecuado(✖)",
                        style: TextStyle(
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                            fontWeight: FontWeight.normal,
                          ),
                          ),
                          backgroundColor: Color(0xFFDBEDFF),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        ),
                      SizedBox(
                        
                        height: 60, 
                        child: Chip(
                          label: const Text(
                        "No Aplica(N/A)",
                        style: TextStyle(
                            fontFamily: 'Avenir',
                            color: Color(0xFF263A5B),
                            fontWeight: FontWeight.normal,
                          ),
                          ),
                          backgroundColor: Color(0xFFDBEDFF),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        ),
                    ],
                    ),

                  const SizedBox(height: 16),

                  // Secciones
                  buildSeccion("ZONAS PAVIMENTADAS", [
                    "Borde del pavimento por encima de 3 pulgadas",
                    "Hoyo de 5 pulgadas de diámetro y 3 pulgadas de profundidad o mayores",
                    "Grietas / Fragmentaciones / Elevaciones",
                    "Grava / Escombros / Etc.",
                    "Acumulación de caucho",
                    "Charcas / represas del borde",
                    "Observaciones"
                  ]),
                  buildSeccion("FRANJAS DE SEGURIDAD", [
                    "Surcos / montesillos / erosión",
                    "Drenaje / construcciones",
                    "Objetos / bases al ras del terreno",
                    "Observaciones"
                  ]),
                  buildSeccion("SEÑALES Y LETREROS", [
                    "Visible de acuerdo con normas",
                    "Punto de espera en rodaje",
                    "Señales",
                    "Letreros frangibles",
                    "Observaciones"
                  ]),
                  buildSeccion("ILUMINACIÓN", [
                    "Obstruidas / sucias / desteñidas...",
                    "Dañada / faltante...",
                    "Inoperante",
                    "Orientación inadecuada / ajuste",
                    "Observaciones"
                  ]),
                  buildSeccion("AYUDAS A LA NAVEGACIÓN", [
                    "Conos de viento",
                    "Sistema PAPI",
                    "Observaciones"
                  ]),
                  buildSeccion("OBSTRUCCIONES", [
                    "Luces de abstracción",
                    "Grúas / árboles",
                    "Observaciones"
                  ]),
                  buildSeccion("OPERACIONES DE ABASTECIMIENTO DE COMBUSTIBLE", [
                    "Cercado / puertas / señales",
                    "Marcas / etiquetas / señales",
                    "Extintores de incendios",
                    "Conexiones a tierra",
                    "Fugas de combustible / vegetación",
                    "Observaciones"
                  ]),
                  buildSeccion("HIELO", [
                    "Condiciones de la superficie",
                    "Libres de amontonamiento de hielo",
                    "Obstrucción de luces y señales",
                    "Acceso de radio ayuda",
                    "Acceso al CREL",
                    "Observaciones"
                  ]),
                  buildSeccion("CONSTRUCCIÓN", [
                    "Barricas / luces",
                    "Estacionamiento de equipo",
                    "Observaciones"
                  ]),
                  buildSeccion("SEI", [
                    "Equipo / disponibilidad de personal",
                    "Comunicaciones / alarma",
                    "Observaciones"
                  ]),
                  buildSeccion("PELIGROS DE LA FAUNA", [
                    "Animales muertos",
                    "Presencia de animales",
                    "Presencia de aves",
                    "Observaciones"
                  ]),
                  buildSeccion("ACCESOS INFORME", [
                    "LIL",
                    "CP",
                    "Observaciones"
                  ]),

                  const SizedBox(height: 20),

                  // Observaciones generales
                  const Text("Observaciones Generales" , style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263A5B),
                                ),),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: observacionesGeneralesController,
                      maxLines: null,
                      decoration: const InputDecoration.collapsed(hintText: "Escribe aquí..."),
                    ),
                  ),

                  const SizedBox(height: 24), // Espacio antes del botón guardar

                  // Sección de Enterado
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
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
                              border: InputBorder.none,
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
                                  border: InputBorder.none,
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
                      onPressed: () async {
                        await guardarFormularioF007();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ],
              ),
            ),
          ),
        ),
        // Botón de compartir en la esquina inferior izquierda
        Positioned(
          bottom: 24,
          left: 24,
          child: FloatingActionButton(
            heroTag: 'share_pdf_f007',
            backgroundColor: const Color(0xFF263A5B),
            onPressed: compartirPDF,
            child: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Compartir PDF',
          ),
        ),
        // Logo del AIQ en la esquina inferior derecha
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
      ],
    );
  }

  Widget buildDateField(String label, {required TextEditingController controller, bool isTime = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                selectedTime = pickedTime;
                controller.text = pickedTime.format(context);
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
                selectedDate = pickedDate;
                controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
              });
            }
          }
        },
      ),
    );
  }

  Widget buildSeccion(String titulo, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 215, 219, 231),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF263A5B),
              ),
            ),
            const SizedBox(height: 8),
            ...items.asMap().entries.map((entry) {
  final index = entry.key;
  final item = entry.value;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (item.toLowerCase().contains("observaciones")) ...[
        // Aquí puedes personalizar el estilo del título y del TextField de Observaciones
        Text(
          item,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            fontFamily: 'Avenir',
            color: Color(0xFF263A5B),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          // Aquí puedes personalizar el fondo, borderRadius, padding, etc. del campo de texto de Observaciones
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            // Aquí puedes personalizar el estilo del texto del TextField
            decoration: const InputDecoration(
              hintText: "Escribe aquí...",
              border: InputBorder.none,
              isDense: false,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
            maxLines: null,
            onChanged: (value) {
              _selecciones["$titulo-$item"] = value;
            },
          ),
        ),
      ] else ...[
        Container(
            height: (titulo == "ZONAS PAVIMENTADAS" && (index == 0 || index == 1 || index == 2)) ? 60
                : (titulo == "FRANJAS DE SEGURIDAD" && index == 2) ? 60
                : (titulo == "ILUMINACIÓN" && index == 0) ? 60
                : (titulo == "OPERACIONES DE ABASTECIMIENTO DE COMBUSTIBLE" && index == 4) ? 60
                : (titulo == "HIELO" && index == 1) ? 60
                : (titulo == "SEI" && index == 0) ? 60
                : 40,
            decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(40),
            ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontFamily: 'Avenir'),
                ),
              ),
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 206, 228, 252),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selecciones["$titulo-$item"],
                    dropdownColor: const Color(0xFFDBEDFF),
                    borderRadius: BorderRadius.circular(20),
                    hint: const Text("Selecciona", style: TextStyle(fontFamily: 'Avenir')),
                    items: const [
                      DropdownMenuItem(value: "✔", child: Text("✔", style: TextStyle(fontFamily: 'Avenir'))),
                      DropdownMenuItem(value: "✖", child: Text("✖", style: TextStyle(fontFamily: 'Avenir'))),
                      DropdownMenuItem(value: "N/A", child: Text("N/A", style: TextStyle(fontFamily: 'Avenir'))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selecciones["$titulo-$item"] = value!;
                      });
                    },
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263A5B),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF263A5B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const Divider(),
    ],
  );
})
          ],
        ),
      ),
    );
  }

Future<void> exportarPDF() async {
  try {
    final pdf = pw.Document();

    // Carga el logo
    final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final fechaGeneracion = DateTime.now();
    final fechaStr = "${fechaGeneracion.day.toString().padLeft(2, '0')}/"
        "${fechaGeneracion.month.toString().padLeft(2, '0')}/"
        "${fechaGeneracion.year}";

    // Define las secciones igual que en tu formulario
    final List<Map<String, dynamic>> secciones = [
      {
        "titulo": "ZONAS PAVIMENTADAS",
        "items": [
          "Borde del pavimento por encima de 3 pulgadas",
          "Hoyo de 5 pulgadas de diámetro y 3 pulgadas de profundidad o mayores",
          "Grietas / Fragmentaciones / Elevaciones",
          "Grava / Escombros / Etc.",
          "Acumulación de caucho",
          "Charcas / represas del borde",
          "Observaciones"
        ]
      },
      {
        "titulo": "FRANJAS DE SEGURIDAD",
        "items": [
          "Surcos / montesillos / erosión",
          "Drenaje / construcciones",
          "Objetos / bases al ras del terreno",
          "Observaciones"
        ]
      },
      {
        "titulo": "SEÑALES Y LETREROS",
        "items": [
          "Visible de acuerdo con normas",
          "Punto de espera en rodaje",
          "Señales",
          "Letreros frangibles",
          "Observaciones"
        ]
      },
      {
        "titulo": "ILUMINACIÓN",
        "items": [
          "Obstruidas / sucias / desteñidas...",
          "Dañada / faltante...",
          "Inoperante",
          "Orientación inadecuada / ajuste",
          "Observaciones"
        ]
      },
      {
        "titulo": "AYUDAS A LA NAVEGACIÓN",
        "items": [
          "Conos de viento",
          "Sistema PAPI",
          "Observaciones"
        ]
      },
      {
        "titulo": "OBSTRUCCIONES",
        "items": [
          "Luces de abstracción",
          "Grúas / árboles",
          "Observaciones"
        ]
      },
      {
        "titulo": "OPERACIONES DE ABASTECIMIENTO DE COMBUSTIBLE",
        "items": [
          "Cercado / puertas / señales",
          "Marcas / etiquetas / señales",
          "Extintores de incendios",
          "Conexiones a tierra",
          "Fugas de combustible / vegetación",
          "Observaciones"
        ]
      },
      {
        "titulo": "HIELO",
        "items": [
          "Condiciones de la superficie",
          "Libres de amontonamiento de hielo",
          "Obstrucción de luces y señales",
          "Acceso de radio ayuda",
          "Acceso al CREL",
          "Observaciones"
        ]
      },
      {
        "titulo": "CONSTRUCCIÓN",
        "items": [
          "Barricas / luces",
          "Estacionamiento de equipo",
          "Observaciones"
        ]
      },
      {
        "titulo": "SEI",
        "items": [
          "Equipo / disponibilidad de personal",
          "Comunicaciones / alarma",
          "Observaciones"
        ]
      },
      {
        "titulo": "PELIGROS DE LA FAUNA",
        "items": [
          "Animales muertos",
          "Presencia de animales",
          "Presencia de aves",
          "Observaciones"
        ]
      },
      {
        "titulo": "ACCESOS INFORME",
        "items": [
          "LIL",
          "CP",
          "Observaciones"
        ]
      },
    ];

    // Obtener la firma como bytes
    Uint8List? signatureBytes;
    if (enteradoFirmaController.isNotEmpty) {
      signatureBytes = await enteradoFirmaController.toPngBytes();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Folio: $folio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColor.fromInt(0xFF263A5B))),
              pw.Text('Fecha: $fechaStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColor.fromInt(0xFF263A5B))),
              pw.Image(logoImage, width: 70),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.Header(
            level: 0,
            child: pw.Text(
              'LISTA DE VERIFICACIÓN PARA LA INSPECCIÓN DIARIA\nAIQ-OPS-F007',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF263A5B)),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fecha de la inspección: ${fechaController.text}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Hora Local: ${horaController.text}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Número de Inspección: $_inspeccionSeleccionada', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Text('Resultados de la Inspección:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromInt(0xFF263A5B))),
          pw.SizedBox(height: 8),

          // Secciones e ítems en tablas
          ...secciones.map((seccion) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 10),
              pw.Text(
                seccion['titulo'],
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: PdfColor.fromInt(0xFF263A5B),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD7DBE7)),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Ítem', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Resultado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  ...List<pw.TableRow>.from(
                    (seccion['items'] as List<String>).map((item) {
                      final key = "${seccion['titulo']}-${item}";
                      final value = _selecciones[key] ?? '';
                      if (item.toLowerCase().contains("observaciones")) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(item, style: pw.TextStyle(fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                value.toString().isEmpty ? "Sin observaciones" : value,
                                style: pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(item, style: pw.TextStyle(fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                getTextoSeleccion(value),
                                style: pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        );
                      }
                    }),
                  ),
                ],
              ),
            ],
          )),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 260,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFFFFF),
                  borderRadius: pw.BorderRadius.circular(24),
                ),
                padding: const pw.EdgeInsets.all(18),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Enterado", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColor.fromInt(0xFF263A5B))),
                    pw.SizedBox(height: 10),
                    pw.Text("Nombre: ${enteradoNombreController.text}", style: pw.TextStyle(fontSize: 12)),
                    pw.Text("Fecha: ${enteradoFechaController.text}", style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Text("Firma:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 6),
                    if (signatureBytes != null)
                      pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(signatureBytes),
                          width: 120,
                          height: 40,
                        ),
                      )
                    else
                      pw.Container(
                        width: 120,
                        height: 40,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  } catch (e, st) {
    // Muestra el error en consola y en pantalla
    print('Error al generar PDF: $e\n$st');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }
}

  Future<void> compartirPDF() async {
  try {
    final pdf = pw.Document();

    // Carga el logo
    final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Definir la fecha de generación y el string de fecha
    final fechaGeneracion = DateTime.now();
    final fechaStr = "${fechaGeneracion.day.toString().padLeft(2, '0')}/"
        "${fechaGeneracion.month.toString().padLeft(2, '0')}/"
        "${fechaGeneracion.year}";

    // Definir las secciones igual que en tu formulario
    final List<Map<String, dynamic>> secciones = [
      {
        "titulo": "ZONAS PAVIMENTADAS",
        "items": [
          "Borde del pavimento por encima de 3 pulgadas",
          "Hoyo de 5 pulgadas de diámetro y 3 pulgadas de profundidad o mayores",
          "Grietas / Fragmentaciones / Elevaciones",
          "Grava / Escombros / Etc.",
          "Acumulación de caucho",
          "Charcas / represas del borde",
          "Observaciones"
        ]
      },
      {
        "titulo": "FRANJAS DE SEGURIDAD",
        "items": [
          "Surcos / montesillos / erosión",
          "Drenaje / construcciones",
          "Objetos / bases al ras del terreno",
          "Observaciones"
        ]
      },
      {
        "titulo": "SEÑALES Y LETREROS",
        "items": [
          "Visible de acuerdo con normas",
          "Punto de espera en rodaje",
          "Señales",
          "Letreros frangibles",
          "Observaciones"
        ]
      },
      {
        "titulo": "ILUMINACIÓN",
        "items": [
          "Obstruidas / sucias / desteñidas...",
          "Dañada / faltante...",
          "Inoperante",
          "Orientación inadecuada / ajuste",
          "Observaciones"
        ]
      },
      {
        "titulo": "AYUDAS A LA NAVEGACIÓN",
        "items": [
          "Conos de viento",
          "Sistema PAPI",
          "Observaciones"
        ]
      },
      {
        "titulo": "OBSTRUCCIONES",
        "items": [
          "Luces de abstracción",
          "Grúas / árboles",
          "Observaciones"
        ]
      },
      {
        "titulo": "OPERACIONES DE ABASTECIMIENTO DE COMBUSTIBLE",
        "items": [
          "Cercado / puertas / señales",
          "Marcas / etiquetas / señales",
          "Extintores de incendios",
          "Conexiones a tierra",
          "Fugas de combustible / vegetación",
          "Observaciones"
        ]
      },
      {
        "titulo": "HIELO",
        "items": [
          "Condiciones de la superficie",
          "Libres de amontonamiento de hielo",
          "Obstrucción de luces y señales",
          "Acceso de radio ayuda",
          "Acceso al CREL",
          "Observaciones"
        ]
      },
      {
        "titulo": "CONSTRUCCIÓN",
        "items": [
          "Barricas / luces",
          "Estacionamiento de equipo",
          "Observaciones"
        ]
      },
      {
        "titulo": "SEI",
        "items": [
          "Equipo / disponibilidad de personal",
          "Comunicaciones / alarma",
          "Observaciones"
        ]
      },
      {
        "titulo": "PELIGROS DE LA FAUNA",
        "items": [
          "Animales muertos",
          "Presencia de animales",
          "Presencia de aves",
          "Observaciones"
        ]
      },
      {
        "titulo": "ACCESOS INFORME",
        "items": [
          "LIL",
          "CP",
          "Observaciones"
        ]
      },
    ];

    // Obtener la firma como bytes
    Uint8List? signatureBytes;
    if (enteradoFirmaController.isNotEmpty) {
      signatureBytes = await enteradoFirmaController.toPngBytes();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Folio: $folio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColor.fromInt(0xFF263A5B))),
              pw.Text('Fecha: $fechaStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColor.fromInt(0xFF263A5B))),
              pw.Image(logoImage, width: 70),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.Header(
            level: 0,
            child: pw.Text(
              'LISTA DE VERIFICACIÓN PARA LA INSPECCIÓN DIARIA\nAIQ-OPS-F007',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF263A5B)),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fecha de la inspección: ${fechaController.text}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Hora Local: ${horaController.text}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Número de Inspección: $_inspeccionSeleccionada', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Text('Resultados de la Inspección:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromInt(0xFF263A5B))),
          pw.SizedBox(height: 8),

          // Secciones e ítems en tablas
          ...secciones.map((seccion) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 10),
              pw.Text(
                seccion['titulo'],
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: PdfColor.fromInt(0xFF263A5B),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFD7DBE7)),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Ítem', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Resultado', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  ...List<pw.TableRow>.from(
                    (seccion['items'] as List<String>).map((item) {
                      final key = "${seccion['titulo']}-${item}";
                      final value = _selecciones[key] ?? '';
                      if (item.toLowerCase().contains("observaciones")) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(item, style: pw.TextStyle(fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                value.toString().isEmpty ? "Sin observaciones" : value,
                                style: pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(item, style: pw.TextStyle(fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                getTextoSeleccion(value),
                                style: pw.TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        );
                      }
                    }),
                  ),
                ],
              ),
            ],
          )),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 260,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFFFFF),
                  borderRadius: pw.BorderRadius.circular(24),
                ),
                padding: const pw.EdgeInsets.all(18),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Enterado", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColor.fromInt(0xFF263A5B))),
                    pw.SizedBox(height: 10),
                    pw.Text("Nombre: ${enteradoNombreController.text}", style: pw.TextStyle(fontSize: 12)),
                    pw.Text("Fecha: ${enteradoFechaController.text}", style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Text("Firma:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 6),
                    if (signatureBytes != null)
                      pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(signatureBytes),
                          width: 120,
                          height: 40,
                        ),
                      )
                    else
                      pw.Container(
                        width: 120,
                        height: 40,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Guardar el PDF en un archivo temporal
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/AIQ-OPS-F007.pdf');
    await file.writeAsBytes(await pdf.save());

    // Compartir el archivo
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Formulario AIQ-OPS-F007',
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

  Future<void> guardarFormularioF007() async {
  await FirebaseFirestore.instance.collection('aiq_ops_f007').doc(folio.toString()).set({
    'folio': folio,
    'fecha': fechaController.text,
    'hora': horaController.text,
    'numero_inspeccion': _inspeccionSeleccionada,
    'observaciones_generales': observacionesGeneralesController.text,
    'selecciones': _selecciones,
    'enterado_nombre': enteradoNombreController.text,
    'enterado_fecha': enteradoFechaController.text,
    'timestamp': FieldValue.serverTimestamp(),
    // Puedes guardar la firma como base64 si lo deseas
  });
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario guardado correctamente')),
    );
    await _incrementarFolio();
    await exportarPDF();
  }
}

  String getTextoSeleccion(String? valor) {
    switch (valor) {
      case "✔":
        return "Satisfactorio";
      case "✖":
        return "Inadecuado";
      case "N/A":
        return "No Aplica";
      default:
        return "Sin seleccionar";
    }
  }

  void guardarYExportar() async {
  await guardarFormularioF007();
  await exportarPDF();
  await _incrementarFolio();
}

Future<void> guardarYExportarF007() async {
  try {
    // 1. Guarda en Firestore (un documento por folio)
    await FirebaseFirestore.instance.collection('aiq_ops_f007').doc(folio.toString()).set({
      'folio': folio,
      'fecha': fechaController.text,
      'hora': horaController.text,
      'numero_inspeccion': _inspeccionSeleccionada,
      'observaciones_generales': observacionesGeneralesController.text,
      'selecciones': _selecciones,
      'enterado_nombre': enteradoNombreController.text,
      'enterado_fecha': enteradoFechaController.text,
      'timestamp': FieldValue.serverTimestamp(),
      // Puedes guardar la firma como base64 si lo deseas
    });

    // 2. Exporta a PDF
    await exportarPDF();

    // 3. Incrementa el folio para el siguiente formulario
    await _incrementarFolio();

    // 4. Mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulario guardado y exportado correctamente')),
      );
    }
  } catch (e, st) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar/exportar: $e')),
      );
    }
    print('Error al guardar/exportar: $e\n$st');
  }
}
}