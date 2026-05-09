import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/home_screen.dart'; // ← une seule ligne, chemin correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _permissionGranted = false;
  bool _loading = false;
  String _status = 'Bienvenue';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
    }
  }

  Future<void> _requestAndLaunch() async {
    setState(() { 
      _loading = true; 
      _status = 'Demande de permission...'; 
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() { 
        _loading = false; 
        _status = 'Permission refusée'; 
      });
      return;
    }

    setState(() => _status = 'Initialisation caméra...');
    
    try {
      final cameras = await availableCameras();

      if (!mounted) return;
      
      // ← CHANGEMENT ICI : Navigation vers HomeScreen au lieu de CameraScreen directement
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(cameras: cameras),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Erreur caméra';
      });
      print('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  size: 48,
                  color: Color(0xFF6C63FF),
                ),
              ).animate().scale(
                delay: 200.ms, 
                duration: 600.ms,
                curve: Curves.elasticOut
              ),

              const SizedBox(height: 32),

              Text(
                'ASL Translator',
                style: GoogleFonts.spaceMono(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 8),

              Text(
                'Traduction de la langue des signes\naméricaine en temps réel',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: Colors.white38,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 48),

              // Features
              ...[
                ('Détection des mains Mediapipe', Icons.back_hand_outlined),
                ('Classification YOLOv8 TFLite', Icons.psychology_outlined),
                ('26 lettres ASL A→Z', Icons.abc_rounded),
              ].asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32, 
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        e.value.$2, 
                        size: 16,
                        color: const Color(0xFF6C63FF)
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      e.value.$1,
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ).animate().slideX(
                begin: -0.3, 
                end: 0,
                delay: Duration(milliseconds: 700 + e.key * 100),
                duration: 400.ms,
              )),

              const SizedBox(height: 48),

              // Bouton lancer
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _loading ? null : _requestAndLaunch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _loading
                          ? const Color(0xFF6C63FF).withOpacity(0.3)
                          : const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _loading ? [] : [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _loading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16, 
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _status,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'LANCER',
                              style: GoogleFonts.spaceMono(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 3,
                              ),
                            ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}