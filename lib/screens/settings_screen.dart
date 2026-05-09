import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../models/asl_state.dart';

// Réutilisez la même palette que home_screen.dart
const _bg      = Color(0xFF0A0A0F);
const _surface = Color(0xFF111120);
const _accent  = Color(0xFF7C6FFF);
const _accentLt= Color(0xFF9D93FF);
const _green   = Color(0xFF00E5A0);
const _coral   = Color(0xFFFF6B6B);
const _teal    = Color(0xFF4ECDC4);
const _border  = Color(0x12FFFFFF);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showOverlay = true;
  bool _showFps     = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('DÉTECTION'),
                      _group([
                        _rowChevron(Icons.tune_rounded,        _accent, 'Seuil de confiance', 'Min. 70 %'),
                        _rowChevron(Icons.camera_alt_rounded,  _green,  'Caméra par défaut',  'Avant'),
                        _rowChevron(Icons.speed_rounded,       Colors.amber, 'Frame skip',    '1 frame sur 3'),
                      ]),
                      const Gap(20),
                      _sectionLabel('AFFICHAGE'),
                      _group([
                        _rowToggle(Icons.crop_free_rounded, _teal,  'Overlay main',  'Afficher les boîtes',   _showOverlay, (v) => setState(() => _showOverlay = v)),
                        _rowToggle(Icons.speed_rounded,     _coral, 'Afficher FPS',  'HUD temps réel',        _showFps,     (v) => setState(() => _showFps = v)),
                      ]),
                      const Gap(20),
                      _sectionLabel('DONNÉES'),
                      _group([
                        _rowChevron(Icons.delete_outline_rounded, _coral, 'Vider l\'historique', 'Suppression définitive',
                          onTap: () => context.read<ASLState>().clearHistory()),
                      ]),
                      const Gap(20),
                      _sectionLabel('À PROPOS'),
                      _group([
                        _rowInfo(Icons.info_outline_rounded, _accentLt, 'Version', '1.0.0'),
                      ]),
                      const Gap(32),
                      Center(
                        child: Text('ASL Translator',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9, letterSpacing: 2,
                            color: Colors.white.withOpacity(0.15))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: const BoxDecoration(
      color: Color(0xFF0F0F1A),
      border: Border(bottom: BorderSide(color: _border, width: 0.5)),
    ),
    child: Text('RÉGLAGES',
      style: GoogleFonts.spaceMono(fontSize: 13, letterSpacing: 2, color: Colors.white.withOpacity(0.7))),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.spaceMono(
      fontSize: 9, letterSpacing: 2, color: Colors.white.withOpacity(0.25))),
  );

  Widget _group(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border, width: 0.5),
    ),
    child: Column(children: rows),
  );

  Widget _rowBase(IconData icon, Color color, String label, String sub, Widget trailing, {VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _border, width: 0.5))),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2), width: 0.5)),
            child: Icon(icon, color: color, size: 18)),
          const Gap(12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(sub,   style: GoogleFonts.spaceMono(fontSize: 9,  color: Colors.white.withOpacity(0.3))),
            ],
          )),
          trailing,
        ]),
      ),
    );

  Widget _rowChevron(IconData icon, Color color, String label, String sub, {VoidCallback? onTap}) =>
    _rowBase(icon, color, label, sub, Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.15), size: 12), onTap: onTap);

  Widget _rowToggle(IconData icon, Color color, String label, String sub, bool value, ValueChanged<bool> onChanged) =>
    _rowBase(icon, color, label, sub, Switch(
      value: value, onChanged: onChanged,
      activeColor: _accentLt, inactiveThumbColor: Colors.white38,
      activeTrackColor: _accent.withOpacity(0.4),
      inactiveTrackColor: Colors.white12,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ));

  Widget _rowInfo(IconData icon, Color color, String label, String value) =>
    _rowBase(icon, color, label, value, Text(value,
      style: GoogleFonts.spaceMono(fontSize: 11, color: Colors.white.withOpacity(0.4))));
}