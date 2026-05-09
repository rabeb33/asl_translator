import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:gap/gap.dart';
import '../screens/camera_screen.dart';
import '../screens/alphabet_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

// ─── Palette ───────────────────────────────────────────────────────────────
const _bg       = Color(0xFF0A0A0F);
const _surface  = Color(0xFF111120);
const _card     = Color(0xFF13132B);
const _accent   = Color(0xFF7C6FFF);
const _accentLt = Color(0xFF9D93FF);
const _green    = Color(0xFF00E5A0);
const _coral    = Color(0xFFFF6B6B);
const _teal     = Color(0xFF4ECDC4);
const _border   = Color(0x12FFFFFF);
const _borderHi = Color(0x407C6FFF);

// ─── HomeScreen ────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeContent(cameras: widget.cameras),
      CameraScreen(cameras: widget.cameras),
      const HistoryScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── HomeContent (contenu de l'onglet Accueil) ─────────────────────────────
class _HomeContent extends StatelessWidget {
  final List<CameraDescription> cameras;
  const _HomeContent({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            _HeroCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CameraScreen(cameras: cameras),
                ),
              ),
            ),
            _SectionLabel('FONCTIONNALITÉS'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FeatureCard(
                      title: 'Alphabet',
                      subtitle: '26 signes ASL',
                      icon: Icons.sign_language_rounded,
                      color: _coral,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AlphabetScreen(),
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: _FeatureCard(
                      title: 'Historique',
                      subtitle: 'Mots traduits',
                      icon: Icons.history_rounded,
                      color: _teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),
            _SectionLabel('STATISTIQUES'),
            _StatsRow(),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIENVENUE',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                const Gap(6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.spaceMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: Colors.white,
                    ),
                    children: const [
                      TextSpan(text: 'ASL\n'),
                      TextSpan(
                        text: 'Translator',
                        style: TextStyle(color: _accentLt),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Text(
                  'AMERICAN SIGN LANGUAGE',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 0.5),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Card (Caméra) ─────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderHi, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent.withOpacity(0.35), width: 0.5),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: _accentLt, size: 26),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TEMPS RÉEL',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: _accent,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Détection caméra',
                    style: GoogleFonts.spaceMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(3),
                  Text(
                    'Traduire les signes ASL',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _accent.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Card ──────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2), width: 0.5),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(14),
            Text(
              title,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Gap(3),
            Text(
              subtitle,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const Gap(12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.15),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        text,
        style: GoogleFonts.spaceMono(
          fontSize: 9,
          letterSpacing: 2.5,
          color: Colors.white.withOpacity(0.22),
        ),
      ),
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(value: '26', label: 'SIGNES',   dotColor: _accent),
          const Gap(10),
          _StatCard(value: '—',  label: 'TRADUITS', dotColor: _teal),
          const Gap(10),
          _StatCard(value: '—',  label: 'SESSION',  dotColor: _coral),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color dotColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Gap(4),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const Gap(5),
                Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    letterSpacing: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Navigation ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded,       label: 'Accueil',    active: currentIndex == 0, onTap: () => onTap(0)),
          _NavItem(icon: Icons.camera_alt_rounded, label: 'Caméra',     active: currentIndex == 1, onTap: () => onTap(1)),
          _NavItem(icon: Icons.history_rounded,    label: 'Historique', active: currentIndex == 2, onTap: () => onTap(2)),
          _NavItem(icon: Icons.settings_rounded,   label: 'Réglages',   active: currentIndex == 3, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _accentLt : Colors.white.withOpacity(0.25);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(4),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 8,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}