import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'forms_select.dart';
import 'dart:ui'; // Para ImageFilter

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
                height: 450,
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
                            top: -100,
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
              
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormularioScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3A5F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'COMENZAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19.13,
                    fontFamily: 'Avenir',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}