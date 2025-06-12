import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class AIQOPSF008Screen extends StatefulWidget {
  const AIQOPSF008Screen({super.key});

  @override
  State<AIQOPSF008Screen> createState() => _AIQOPSF008ScreenState();
}

// Dummy screen for AIQOPSF008ListScreen to fix the error.
// Replace this with your actual implementation or import if it exists elsewhere.
class AIQOPSF008ListScreen extends StatelessWidget {
  const AIQOPSF008ListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formularios Guardados'),
      ),
      body: const Center(
        child: Text('Lista de formularios guardados aquí.'),
      ),
    );
  }
}

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

Future<String?> subirPDFaDriveEnCarpeta(File pdfFile, String folderId) async {
  final googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );
  await googleSignIn.signOut(); // Permite elegir cuenta cada vez
  final account = await googleSignIn.signIn();
  if (account == null) return null;
  final authHeaders = await account.authHeaders;
  final authenticateClient = GoogleAuthClient(authHeaders);
  final driveApi = drive.DriveApi(authenticateClient);
  final media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
  final driveFile = drive.File();
  driveFile.name = pdfFile.path.split('/').last;
  driveFile.parents = [folderId];
  final uploaded = await driveApi.files.create(
    driveFile,
    uploadMedia: media,
  );
  await driveApi.permissions.create(
    drive.Permission()
      ..type = 'anyone'
      ..role = 'reader',
    uploaded.id!,
  );
  return 'https://drive.google.com/file/d/${uploaded.id}/view?usp=sharing';
}

class _AIQOPSF008ScreenState extends State<AIQOPSF008Screen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TextEditingController fechaController = TextEditingController();
  TextEditingController horaController = TextEditingController();
  final TextEditingController observacionesGeneralesController = TextEditingController();
  final TextEditingController enteradoNombreController = TextEditingController();
  DateTime? enteradoFecha;
  final TextEditingController enteradoFechaController = TextEditingController();

  // Mapa para guardar la selección de cada ítem
  final Map<String, String> _selecciones = {};

  int _inspeccionSeleccionada = 1;
  int folio = 1;

  // Controlador para la firma
  final SignatureController enteradoFirmaController = SignatureController(penStrokeWidth: 2, penColor: Colors.black);

  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _errores = {}; // Para los campos de las secciones
  bool _errorObservacionesGenerales = false;
  bool _errorEnteradoNombre = false;
  bool _errorEnteradoFecha = false;

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
      folio = prefs.getInt('folio_f008') ?? 1;
    });
  }

  Future<void> _incrementarFolio() async {
    final prefs = await SharedPreferences.getInstance();
    folio++;
    await prefs.setInt('folio_f008', folio);
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
              child: Form(
                key: _formKey,
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
                            "LISTA DE VERIFICACIÓN PARA LA INSPECCIÓN CONTINUA",
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
                              "(2 VECES AL DÍA)",
                              style: TextStyle(color: Color.fromARGB(255, 66, 66, 66), fontSize: 15),
                            ),
                            Text(
                              "AIQ-OPS-F008",
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

                    // Folio y fecha actuales
                    Row(
                      children: [
                        Text(
                          "Folio: $folio",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Fecha: ${DateTime.now().day.toString().padLeft(2, '0')}/"
                                "${DateTime.now().month.toString().padLeft(2, '0')}/"
                                "${DateTime.now().year}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF263A5B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

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
                    buildSeccion("VEHÍCULOS TERRESTRES", [
                      "Acercamiento a los segmentos",
                      "Procedimientos",
                      "Observaciones"
                    ]),
                    buildSeccion("OPERACIONES DE ABASTECIMIENTO DE COMBUSTIBLE", [
                      "Peligros de Incendio / Explosión",
                      "Procedimientos",
                      "Conexiones a tierra",
                      "Letrero de 'NO FUMAR'",
                      "Observaciones"
                    ]),
                    buildSeccion("CONSTRUCCIÓN", [
                      "Plan de seguridad",
                      "Riesgos en áreas públicas y colindantes",
                      "Observaciones"
                    ]),
                    buildSeccion("ACCESOS", [
                      "Personas NO Autorizadas",
                      "Vehículos NO Autorizados",
                      "Puertas libres",
                      "Peatones en zona de movimiento de aeronaves",
                      "Embarque y desembarque de pasajeros",
                      "Accesos en zonas de aeronaves",
                      "Observaciones"
                    ]),
                    buildSeccion("PELIGRO DE FAUNA", [
                      "Aves",
                      "Animales",
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
                    TextFormField(
                      controller: observacionesGeneralesController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: "Escribe aquí...",
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _errorObservacionesGenerales ? 'Campo obligatorio' : null,
                        border: InputBorder.none,
                      ),
                      onChanged: (_) {
                        setState(() {
                          _errorObservacionesGenerales = false;
                        });
                      },
                    ),

                    const SizedBox(height: 24),
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
                              decoration: InputDecoration(
                                labelText: "Nombre",
                                border: InputBorder.none,
                                errorText: _errorEnteradoNombre ? 'Campo obligatorio' : null,
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _errorEnteradoNombre = false;
                                });
                              },
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
                                  enteradoFecha = picked;
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
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: "Fecha",
                                    border: InputBorder.none,
                                    suffixIcon: Icon(Icons.calendar_today),
                                    errorText: _errorEnteradoFecha ? 'Campo obligatorio' : null,
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        enteradoFecha = picked;
                                        enteradoFechaController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                        _errorEnteradoFecha = false;
                                      });
                                    }
                                  },
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
                          backgroundColor: Color(0xFF263A5B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: guardarFormularioF008,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Icono de compartir en la esquina inferior izquierda
        Positioned(
          bottom: 24,
          left: 24,
          child: FloatingActionButton(
            heroTag: 'share_pdf_f008',
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
            ...items.map((item) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.toLowerCase().contains("observaciones")) ...[
                      Text(item, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, fontFamily: 'Avenir', color: Color(0xFF263A5B))),
                      const SizedBox(height: 3),
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255), // Azul claro
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Escribe aquí...",
                            border: InputBorder.none,
                            isDense: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            _selecciones["$titulo-$item"] = value;
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 255, 255), // Azul claro
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                              height: 20,
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 206, 228, 252), // Un azul más fuerte para el selector
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
                                      _errores["$titulo-$item"] = null;
                                    });
                                  },
                                  style: const TextStyle(
                                    fontFamily: 'Avenir',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263A5B),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF263A5B)),
                                  underline: Container(
    height: 2,
    color: _errores["$titulo-$item"] != null ? Colors.red : Colors.transparent,
  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  void guardarFormularioF008() async {
  bool valido = true;

  setState(() {
    // Validar fecha de inspección
    if (fechaController.text.trim().isEmpty) {
      valido = false;
      // Puedes agregar un bool _errorFecha si quieres mostrar error visual
    }

    // Validar hora local
    if (horaController.text.trim().isEmpty) {
      valido = false;
      // Puedes agregar un bool _errorHora si quieres mostrar error visual
    }

    // Observaciones generales
    _errorObservacionesGenerales = observacionesGeneralesController.text.trim().isEmpty;
    if (_errorObservacionesGenerales) valido = false;

    // Nombre y fecha del enterado
    _errorEnteradoNombre = enteradoNombreController.text.trim().isEmpty;
    if (_errorEnteradoNombre) valido = false;

    _errorEnteradoFecha = enteradoFechaController.text.trim().isEmpty;
    if (_errorEnteradoFecha) valido = false;

    // Validar firma del enterado
    if (enteradoFirmaController.isEmpty) {
      valido = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor firma en el campo de Enterado')),
      );
    }

    // Validar cada selección de cada sección
    _errores.clear();
    final secciones = [
      {
        "titulo": "VEHÍCULOS TERRESTRES",
        "items": [
          "Acercamiento a los segmentos",
          "Procedimientos",
          "Observaciones"
        ]
      },
      {
        "titulo": "OPERACIONES DE ABASTECIMIENTO DE COMBUSTIBLE",
        "items": [
          "Peligros de Incendio / Explosión",
          "Procedimientos",
          "Conexiones a tierra",
          "Letrero de 'NO FUMAR'",
          "Observaciones"
        ]
      },
      {
        "titulo": "CONSTRUCCIÓN",
        "items": [
          "Plan de seguridad",
          "Riesgos en áreas públicas y colindantes",
          "Observaciones"
        ]
      },
      {
        "titulo": "ACCESOS",
        "items": [
          "Personas NO Autorizadas",
          "Vehículos NO Autorizados",
          "Puertas libres",
          "Peatones en zona de movimiento de aeronaves",
          "Embarque y desembarque de pasajeros",
          "Accesos en zonas de aeronaves",
          "Observaciones"
        ]
      },
      {
        "titulo": "PELIGRO DE FAUNA",
        "items": [
          "Aves",
          "Animales",
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
    for (final seccion in secciones) {
      for (final item in seccion['items'] as List<String>) {
        final key = "${seccion['titulo']}-${item}";
        if (item.toLowerCase().contains("observaciones")) {
          if ((_selecciones[key] ?? "").trim().isEmpty) {
            _errores[key] = 'Campo obligatorio';
            valido = false;
          }
        } else {
          if (_selecciones[key] == null || _selecciones[key]!.isEmpty) {
            _errores[key] = 'Selecciona una opción';
            valido = false;
          }
        }
      }
    }
  });

  if (!valido) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor llena todos los campos obligatorios')),
    );
    return;
  }

  // Guarda el formulario usando el folio como ID
  await FirebaseFirestore.instance.collection('aiq_ops_f008').doc(folio.toString()).set({
    'folio': folio,
    'fecha': fechaController.text,
    'hora': horaController.text,
    'numero_inspeccion': _inspeccionSeleccionada,
    'observaciones_generales': observacionesGeneralesController.text,
    'selecciones': _selecciones,
    'enterado_nombre': enteradoNombreController.text,
    'enterado_fecha': enteradoFechaController.text,
    'timestamp': FieldValue.serverTimestamp(),
    // Puedes agregar más campos aquí si lo necesitas
  });

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario guardado correctamente')),
    );
    await exportarPDF();
    await _incrementarFolio(); // Incrementa el folio para el siguiente formulario
  }
}

  Future<void> exportarPDF() async {
  final pdf = pw.Document();

  final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final fechaGeneracion = DateTime.now();
  final fechaStr = "${fechaGeneracion.day.toString().padLeft(2, '0')}-"
      "${fechaGeneracion.month.toString().padLeft(2, '0')}-"
      "${fechaGeneracion.year}";
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/AIQ-OPS-F008-$fechaStr-$folio.pdf');
  await file.writeAsBytes(await pdf.save());

  // Subir a Google Drive automáticamente
  const folderId = 'TU_ID_DE_CARPETA_DRIVE'; // <-- Cambia esto por tu ID real
  final link = await subirPDFaDriveEnCarpeta(file, folderId);
  if (link != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF subido a Google Drive. ¡Haz clic para abrir el enlace!'),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
        ),
        duration: Duration(seconds: 8),
      ),
    );
  }
}

Future<void> compartirPDF() async {
  try {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/AIQ_LOGO_.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Define las secciones y sus ítems igual que en tu formulario
    final List<Map<String, dynamic>> secciones = [
      {
        "titulo": "VEHÍCULOS TERRESTRES",
        "items": [
          "Acercamiento a los segmentos",
          "Procedimientos",
          "Observaciones"
        ]
      },
      {
        "titulo": "OPERACIONES DE ABASTECIMIENTO DE COMBUSTIBLE",
        "items": [
          "Peligros de Incendio / Explosión",
          "Procedimientos",
          "Conexiones a tierra",
          "Letrero de 'NO FUMAR'",
          "Observaciones"
        ]
      },
      {
        "titulo": "CONSTRUCCIÓN",
        "items": [
          "Plan de seguridad",
          "Riesgos en áreas públicas y colindantes",
          "Observaciones"
        ]
      },
      {
        "titulo": "ACCESOS",
        "items": [
          "Personas NO Autorizadas",
          "Vehículos NO Autorizados",
          "Puertas libres",
          "Peatones en zona de movimiento de aeronaves",
          "Embarque y desembarque de pasajeros",
          "Accesos en zonas de aeronaves",
          "Observaciones"
        ]
      },
      {
        "titulo": "PELIGRO DE FAUNA",
        "items": [
          "Aves",
          "Animales",
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

    Uint8List? signatureBytes;
    if (enteradoFirmaController.isNotEmpty) {
      signatureBytes = await enteradoFirmaController.toPngBytes();
    }

    // Definir fechaStr para la cabecera
    final fechaGeneracion = DateTime.now();
    final fechaStr = "${fechaGeneracion.day.toString().padLeft(2, '0')}-"
        "${fechaGeneracion.month.toString().padLeft(2, '0')}-"
        "${fechaGeneracion.year}";

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
              'LISTA DE VERIFICACIÓN PARA LA INSPECCIÓN CONTINUA\nAIQ-OPS-F008',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fecha: ${fechaController.text}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Hora: ${horaController.text}', style: pw.TextStyle(fontSize: 12)),
          pw.Text('Número de Inspección: $_inspeccionSeleccionada', style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Text('Observaciones Generales:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.Text(observacionesGeneralesController.text, style: pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Text('Resultados de la Inspección:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
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
                width: 260, // Más compacto y centrado
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFFFFF),
                  borderRadius: pw.BorderRadius.circular(24),
                ),
                padding: const pw.EdgeInsets.all(18),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center, // Centra el contenido dentro del recuadro
                  children: [
                    pw.Text("Enterado", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColor.fromInt(0xFF263A5B))),
                    pw.SizedBox(height: 10),
                    pw.Text("Nombre: ${enteradoNombreController.text}", style: pw.TextStyle(fontSize: 12)),
                    pw.Text("Fecha: ${enteradoFechaController.text}", style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Text("Firma:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 6),
                    if (signatureBytes != null) ...[
                      pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(signatureBytes),
                          width: 120,
                          height: 40,
                        ),
                      ),
                    ] else ...[
                      pw.Container(
                        width: 120,
                        height: 40,
                      ),
                    ],
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
    final file = File('${output.path}/AIQ-OPS-F008-$fechaStr-$folio.pdf');
    await file.writeAsBytes(await pdf.save());

    // Compartir el archivo
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Formulario AIQ-OPS-F008',
    );

    // Subir a Google Drive y obtener el enlace
    const folderId = '1mbbaYH9Nr1UhT6vcK2hnIU_3XPcJ0vWp'; // Reemplaza por tu ID real
    final link = await subirPDFaDriveEnCarpeta(file, folderId);
    if (link != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF subido a Google Drive. ¡Haz clic para abrir el enlace!'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
          ),
          duration: Duration(seconds: 8),
        ),
      );
    }
  } catch (e, st) {
    print('Error al compartir PDF: $e\n$st');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir PDF: $e')),
      );
    }
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
}

//Formularios para agregar Drive
//F008, F007, F005.