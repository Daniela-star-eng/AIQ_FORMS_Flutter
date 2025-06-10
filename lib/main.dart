import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'forms_select.dart';
import 'dart:ui'; // Para ImageFilter
import 'package:slide_to_act/slide_to_act.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIQ Forms',
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E4EC),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset(
                'assets/AIQ_LOGO_.png',
                height: 280,           
                fit: BoxFit.contain,
              ),
              SizedBox(
                height: 430,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRect(
                    child: SizedBox(
                      width: 700, // Solo la mitad izquierda visible
                      height: 700,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Círculo con blur
                          Positioned(
                            left: -60,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  width: 420,
                                  height: 420,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Color.fromARGB(255, 255, 255, 255),
                                        Color.fromARGB(174, 226, 228, 236),
                                      ],
                                      center: Alignment.center,
                                      radius: 0.55,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Imagen del avión recortada
                          Positioned(
                            left: -380,
                            top: -165,
                            child: Image.asset(
                              'assets/Avion-one.png',
                              fit: BoxFit.contain,
                              height: 740,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                child: SlideAction(
                  text: 'COMENZAR',
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Avenir',
                    color: Colors.white,
                  ),
                  outerColor: const Color(0xFF1F3A5F),
                  innerColor: const Color(0xFF598CBC),
                  onSubmit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FormularioScreen(),
                      ),
                    );
                  },
                  elevation: 2,
                  sliderButtonIcon: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}