import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:interfaz_uno_aiq/AIQ-OPS-F008.dart';
import 'package:interfaz_uno_aiq/AIQ-OPS-F007.dart';
import 'package:interfaz_uno_aiq/AIQ-OPS-F005.dart';
import 'derrames.dart'; // Asegúrate de tener este archivo creado con el widget DerramesScreen
import 'package:interfaz_uno_aiq/AIQ_AMB_F-003.DART';
import 'package:interfaz_uno_aiq/derrames.dart' as derrames_lib; // Asegúrate de tener este archivo creado con el widget DerramesScreen
import 'package:interfaz_uno_aiq/AIQ-AMB-F-004.dart';
import 'package:interfaz_uno_aiq/AIQ-AMB-F-004.dart'; // Asegúrate de importar el nuevo formulario
import 'package:interfaz_uno_aiq/AIQ-AMB-F-001.dart';
import 'package:interfaz_uno_aiq/AIQ-AMB-F-002.dart';

class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final List<Map<String, String>> formularios = const [
    {
      "titulo": "NEUTRALIZACION Y LIMPIEZA DE DERRAMES",
      "codigo": "AIQ-F013-OPS",
      "imagen": "assets/AIQ-OPS-F013-FORM-PREVIEW.jpg",
    },
    {
      "titulo": "VERIFICACION CONTINUA",
      "codigo": "AIQ-OPS-F008",
      "imagen": "assets/AIQ-OPS-F008-FORM-PREVIEW.jpg",
    },
     {
      "titulo": "VERIFICACION DIARIA",
      "codigo": "AIQ-OPS-F007",
      "imagen": "assets/AIQ-OPS-F007-FORM-PREVIEW.jpg",
    },
    {
      "titulo": "VERIFICACION PREVENCION DE INCURSIONES",
      "codigo": "AIQ-OPS-F005",
      "imagen": "assets/AIQ-OPS-F005-FORM-PREVIEW.jpg",
    },
    {
      "titulo": "MONITOREO DE RESTOS DE FAUNA EN AREAS OPERATIVAS",
      "codigo": "AIQ-AMB-F-003",
      "imagen": "assets/generica.jpg",
    },
    {
      "titulo": "NUEVO FORMULARIO",
      "codigo": "AIQ-NF-001",
      "imagen": "assets/avionG.jpg",
    },
    {
      "titulo": "Formulario Fauna",
      "codigo": "AIQ-AMB-F-001",
      "imagen": "assets/foto_random.jpg",
    },
    {
      "titulo": "FORMULARIO DE FAUNA Y HABITAD",
      "codigo": "AIQ-AMB-F-002",
      "imagen": "assets/airbus.png",
    }
     
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            bottom: -180,
            left: -400,
            right: -130,
            child: Opacity(
              opacity: 1,
              child: Image.asset(
                "assets/Avion-two.jpg",
                height: 800,
                fit: BoxFit.fitHeight,
              ),
            ),
          ),

          // Botón de retroceso
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 2),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF103A63),
                ),
              ),
            ),
          ),

          // Título
          Positioned(
            top: 80,
            left: 60,
            right: 50,
            child: RichText(
              textAlign: TextAlign.left,
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: "ESCOGE UN\n",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      color: Color(0xFF263A5B),
                    ),
                  ),
                  TextSpan(
                    text: "FORMULARIO",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Avenir',
                      color: Color(0xFF598CBC),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Carrusel
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100), // Espacio entre el título y el carrusel
                CarouselSlider.builder(
                  itemCount: formularios.length,
                  options: CarouselOptions(
                    height: 580,
                    enlargeCenterPage: true,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    viewportFraction: 0.8,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    final form = formularios[index];
                    return GestureDetector(
                      onTap: () {
                        if (index == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const derrames_lib.DerramesScreen()),
                          );
                        } else if (index == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIQOPSF008Screen()),
                          );
                        } else if (index == 2) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIQOPSF007Screen()),
                          );
                        } else if (index == 3) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIQOPSF005Screen()),
                          );
                        } else if (index == 4) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIQ_AMB_F_003class()),
                          );
                        } else if (index == 5) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIQ_AMB_F_004()),
                          );
                        } else if (index == 6) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIQAMBF001Screen()),
                          );
                        } else if (index == 7) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIQAMBF002Screen()),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          form["imagen"]!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: 260, // Ajusta la altura si lo deseas
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Indicadores
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(formularios.length, (index) {
                    return Container(
                      width: 10,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? const Color(0xFF103A63)
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                // Footer TBIB
                const SizedBox(height: 24),
                const Text(
                  "Llenar formulario.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}