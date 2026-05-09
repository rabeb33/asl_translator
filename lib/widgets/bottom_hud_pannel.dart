import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../models/asl_state.dart';

class BottomHudPanel extends StatelessWidget {
  const BottomHudPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ASLState>(
      builder: (context, state, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.95),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lettre courante + confiance
              _CurrentLetterRow(state: state),
              const Gap(12),
              // Buffer mot
              _WordBuffer(state: state),
              const Gap(12),
              // Boutons d'action
              _ActionButtons(state: state),
              const Gap(8),
              // Historique
              if (state.wordHistory.isNotEmpty) 
                _WordHistory(state: state),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentLetterRow extends StatelessWidget {
  final ASLState state;
  const _CurrentLetterRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasDetection = state.hasDetection;
    final label = state.currentLabel;
    final conf = state.currentConfidence;

    return Row(
      children: [
        // Grande lettre animée
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Text(
            label ?? '—',
            key: ValueKey(label),
            style: GoogleFonts.spaceMono(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: hasDetection
                  ? const Color(0xFF00F5A0)
                  : Colors.white.withOpacity(0.2),
              height: 1,
            ),
          ),
        ),
        const Gap(16),
        // Info colonne droite
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signe détecté',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              const Gap(4),
              if (hasDetection) ...[
                // Barre de confiance
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: conf.clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      conf > 0.85
                          ? const Color(0xFF00F5A0)
                          : conf > 0.70
                              ? const Color(0xFFFFD700)
                              : const Color(0xFFFF6B6B),
                    ),
                    minHeight: 6,
                  ),
                ),
                const Gap(4),
                Text(
                  '${(conf * 100).toStringAsFixed(0)}% confiance',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ] else
                Text(
                  'Montrez votre main',
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: Colors.white24,
                  ),
                ),
            ],
          ),
        ),
        // Stats FPS / mains
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatChip(
              icon: Icons.speed_rounded,
              value: '${state.currentFps.toStringAsFixed(0)} fps',
            ),
            const Gap(4),
            _StatChip(
              icon: Icons.back_hand_outlined,
              value: '${state.handCount} main${state.handCount > 1 ? 's' : ''}',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const Gap(4),
          Text(
            value,
            style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _WordBuffer extends StatelessWidget {
  final ASLState state;
  const _WordBuffer({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state.wordBuffer.isNotEmpty
              ? const Color(0xFF6C63FF).withOpacity(0.5)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.wordBuffer.isEmpty ? 'Mot en cours...' : state.wordBuffer,
              style: GoogleFonts.spaceMono(
                fontSize: state.wordBuffer.isEmpty ? 14 : 20,
                color: state.wordBuffer.isEmpty
                    ? Colors.white24
                    : Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: state.wordBuffer.isEmpty ? 0 : 3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (state.wordBuffer.isNotEmpty)
            Text(
              '${state.wordBuffer.length}/20',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.white24,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ASLState state;
  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ajouter lettre (désactivé si pas de détection)
        Expanded(
          flex: 3,
          child: _HudButton(
            icon: Icons.add_rounded,
            label: 'AJOUTER',
            color: state.hasDetection ? const Color(0xFF00F5A0) : Colors.white24,
            onTap: state.hasDetection 
                ? () => context.read<ASLState>().addCurrentLetter()
                : null,
          ),
        ),
        const Gap(8),
        // Espace
        _HudButton(
          icon: Icons.space_bar_rounded,
          label: 'ESP',
          color: Colors.white38,
          onTap: () => context.read<ASLState>().addSpace(),
        ),
        const Gap(8),
        // Effacer lettre
        _HudButton(
          icon: Icons.backspace_outlined,
          label: 'DEL',
          color: state.wordBuffer.isNotEmpty ? const Color(0xFFFF6B6B) : Colors.white24,
          onTap: state.wordBuffer.isNotEmpty 
              ? () => context.read<ASLState>().deleteLastLetter()
              : null,
        ),
        const Gap(8),
        // Valider mot
        _HudButton(
          icon: Icons.check_rounded,
          label: 'OK',
          color: state.wordBuffer.isNotEmpty ? const Color(0xFF6C63FF) : Colors.white24,
          onTap: state.wordBuffer.isNotEmpty
              ? () => context.read<ASLState>().confirmWord()
              : null,
        ),
        const Gap(8),
        // Reset
        _HudButton(
          icon: Icons.clear_rounded,
          label: 'CLR',
          color: state.wordBuffer.isNotEmpty ? Colors.red : Colors.white24,
          onTap: state.wordBuffer.isNotEmpty
              ? () => context.read<ASLState>().clearBuffer()
              : null,
        ),
      ],
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _HudButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(2),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordHistory extends StatelessWidget {
  final ASLState state;
  const _WordHistory({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10),
        const Gap(4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HISTORIQUE',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                color: Colors.white24,
                letterSpacing: 2,
              ),
            ),
            if (state.wordHistory.length > 5)
              TextButton(
                onPressed: () {
                  // Navigation vers l'écran d'historique complet
                  Navigator.pushNamed(context, '/history');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
          ],
        ),
        const Gap(6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: state.wordHistory.take(5).map((word) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
            ),
            child: Text(
              word,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}