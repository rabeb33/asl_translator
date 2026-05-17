import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';


class _AslSign {
  final String letter;
  final String description;
  final String pngAsset; // assets/images/asl_A.png, etc.

  const _AslSign({
    required this.letter,
    required this.description,
    required this.pngAsset,
  });
}


const List<_AslSign> _aslAlphabet = [
  _AslSign(letter: 'A', description: 'Poing fermé, pouce sur le côté.', pngAsset: 'assets/images/A.jpg'),
  _AslSign(letter: 'B', description: 'Main ouverte, doigts joints vers le haut, pouce replié.', pngAsset: 'assets/images/B.png'),
  _AslSign(letter: 'C', description: 'Main courbée en forme de C.', pngAsset: 'assets/images/C.jpg'),
  _AslSign(letter: 'D', description: 'Index pointé vers le haut, autres doigts forment un O avec le pouce.', pngAsset: 'assets/images/D.png'),
  _AslSign(letter: 'E', description: 'Doigts recourbés vers la paume, pouce replié dessous.', pngAsset: 'assets/images/E.png'),
  _AslSign(letter: 'F', description: 'Pouce et index forment un cercle, trois autres doigts tendus.', pngAsset: 'assets/images/F.png'),
  _AslSign(letter: 'G', description: 'Index et pouce pointent horizontalement.', pngAsset: 'assets/images/G.png'),
  _AslSign(letter: 'H', description: 'Index et majeur tendus horizontalement côte à côte.', pngAsset: 'assets/images/H.jpg'),
  _AslSign(letter: 'I', description: 'Auriculaire levé, autres doigts repliés en poing.', pngAsset: 'assets/images/I.png'),
  _AslSign(letter: 'J', description: "Auriculaire levé, trace un J dans l'air.", pngAsset: 'assets/images/J.jpg'),
  _AslSign(letter: 'K', description: 'Index et majeur tendus, pouce entre les deux.', pngAsset: 'assets/images/K.png'),
  _AslSign(letter: 'L', description: 'Pouce et index forment un L.', pngAsset: 'assets/images/L.png'),
  _AslSign(letter: 'M', description: 'Trois doigts reposent sur le pouce replié.', pngAsset: 'assets/images/M.png'),
  _AslSign(letter: 'N', description: 'Deux doigts sur le pouce replié.', pngAsset: 'assets/images/N.jpg'),
  _AslSign(letter: 'O', description: 'Doigts et pouce forment un O.', pngAsset: 'assets/images/O.png'),
  _AslSign(letter: 'P', description: "Index pointé en bas, majeur vers l'avant, pouce sorti.", pngAsset: 'assets/images/P.png'),
  _AslSign(letter: 'Q', description: 'Index et pouce pointent vers le bas.', pngAsset: 'assets/images/Q.png'),
  _AslSign(letter: 'R', description: 'Index et majeur croisés.', pngAsset: 'assets/images/R.png'),
  _AslSign(letter: 'S', description: 'Poing fermé, pouce sur les doigts.', pngAsset: 'assets/images/S.png'),
  _AslSign(letter: 'T', description: 'Pouce entre index et majeur.', pngAsset: 'assets/images/T.png'),
  _AslSign(letter: 'U', description: 'Index et majeur joints, tendus vers le haut.', pngAsset: 'assets/images/U.jpg'),
  _AslSign(letter: 'V', description: 'Index et majeur tendus en V.', pngAsset: 'assets/images/V.png'),
  _AslSign(letter: 'W', description: 'Index, majeur et annulaire tendus en éventail.', pngAsset: 'assets/images/W.png'),
  _AslSign(letter: 'X', description: 'Index recourbé en crochet.', pngAsset: 'assets/images/X.jpg'),
  _AslSign(letter: 'Y', description: 'Pouce et auriculaire tendus, autres doigts repliés.', pngAsset: 'assets/images/Y.png'),
  _AslSign(letter: 'Z', description: "Index trace un Z dans l'air.", pngAsset: 'assets/images/Z.png'),
];


const _bg       = Color(0xFF0A0A0F);
const _surface  = Color(0xFF12121C);
const _card     = Color(0xFF1A1A28);
const _accent   = Color(0xFF7C6FFF);
const _accentLt = Color(0xFF9D93FF);
const _green    = Color(0xFF00E5A0);
const _border   = Color(0x1AFFFFFF);
const _borderHi = Color(0x4D7C6FFF);


// Écran principal

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _AslSign? _selected;

  List<_AslSign> get _filtered {
    if (_query.isEmpty) return _aslAlphabet;
    return _aslAlphabet
        .where((s) => s.letter.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.pop(context)),
            const Gap(12),
            _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _query = v;
                _selected = null;
              }),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _selected != null
                  ? _DetailPanel(sign: _selected!)
                  : const SizedBox.shrink(),
            ),
            const Gap(8),
            Expanded(
              child: _filtered.isEmpty
                  ? const _EmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final sign = _filtered[i];
                        final active = _selected?.letter == sign.letter;
                        return _LetterCard(
                          sign: sign,
                          isActive: active,
                          onTap: () =>
                              setState(() => _selected = active ? null : sign),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Top bar

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
                border: Border.all(color: _border, width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 15),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              'ALPHABET ASL',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                letterSpacing: 2.5,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.35), width: 0.5),
            ),
            child: Text(
              '26 SIGNES',
              style: GoogleFonts.spaceMono(
                  fontSize: 9, letterSpacing: 1.2, color: _accentLt),
            ),
          ),
        ],
      ),
    );
  }
}


class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Icon(Icons.search_rounded,
                  color: Color(0x55FFFFFF), size: 18),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.spaceMono(
                    fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Chercher une lettre…',
                  hintStyle: GoogleFonts.spaceMono(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.22)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white.withOpacity(0.3), size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _DetailPanel extends StatelessWidget {
  final _AslSign sign;
  const _DetailPanel({required this.sign});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderHi, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image PNG grande
          Container(
            width: 90,
            height: 110,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border, width: 0.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset(
              sign.pngAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  sign.letter,
                  style: GoogleFonts.spaceMono(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: _accentLt,
                  ),
                ),
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lettre en grand
                Text(
                  sign.letter,
                  style: GoogleFonts.spaceMono(
                    fontSize: 54,
                    fontWeight: FontWeight.w700,
                    color: _green,
                    height: 1,
                  ),
                ),
                const Gap(10),
                // Description
                Text(
                  sign.description,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.48),
                    height: 1.65,
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


class _LetterCard extends StatelessWidget {
  final _AslSign sign;
  final bool isActive;
  final VoidCallback onTap;

  const _LetterCard({
    required this.sign,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isActive ? _accent.withOpacity(0.14) : _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? _borderHi : _border,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image PNG du signe
            SizedBox(
              width: 54,
              height: 54,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  sign.pngAsset,
                  fit: BoxFit.contain,
                  // Fallback si l'image n'existe pas encore
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.back_hand_outlined,
                    color: Colors.white.withOpacity(0.18),
                    size: 30,
                  ),
                ),
              ),
            ),
            const Gap(7),
            Text(
              sign.letter,
              style: GoogleFonts.spaceMono(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: isActive ? _accentLt : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              color: Colors.white.withOpacity(0.18), size: 38),
          const Gap(14),
          Text(
            'AUCUNE LETTRE TROUVÉE',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
        ],
      ),
    );
  }
}