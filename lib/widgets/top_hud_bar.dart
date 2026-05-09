import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

class TopHudBar extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onFlip;

  const TopHudBar({
    super.key,
    required this.isActive,
    required this.onToggle,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Logo / titre
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 18),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASL Translator',
                    style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isActive ? '● ACTIF' : '○ PAUSE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: isActive
                          ? const Color(0xFF00F5A0)
                          : Colors.white38,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Bouton flip caméra
          _TopButton(
            icon: Icons.flip_camera_ios_rounded,
            onTap: onFlip,
          ),
          const Gap(8),
          // Bouton pause/play
          _TopButton(
            icon: isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: onToggle,
            highlight: isActive,
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  const _TopButton({
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF6C63FF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight
                ? const Color(0xFF6C63FF).withOpacity(0.6)
                : Colors.white70,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
