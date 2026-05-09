import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../models/asl_state.dart';

// ─────────────────────────────────────────────
// Modèle d'entrée d'historique
// ─────────────────────────────────────────────
class HistoryEntry {
  final String word;
  final double avgConfidence;
  final DateTime timestamp;
  final int letterCount;
  final String sessionLabel;

  HistoryEntry({
    required this.word,
    required this.avgConfidence,
    required this.timestamp,
    required this.letterCount,
    required this.sessionLabel,
  });
}

// ─────────────────────────────────────────────
// Écran historique
// ─────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  _FilterType _currentFilter = _FilterType.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoryEntry> _applyFilter(List<HistoryEntry> entries) {
    List<HistoryEntry> result = entries.where((e) {
      return e.word.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_currentFilter) {
      case _FilterType.today:
        final today = DateTime.now();
        result = result.where((e) =>
            e.timestamp.year == today.year &&
            e.timestamp.month == today.month &&
            e.timestamp.day == today.day).toList();
        break;
      case _FilterType.highConf:
        result = result.where((e) => e.avgConfidence >= 0.85).toList();
        break;
      case _FilterType.longWords:
        result = result.where((e) => e.letterCount >= 5).toList();
        break;
      case _FilterType.shortWords:
        result = result.where((e) => e.letterCount <= 3).toList();
        break;
      case _FilterType.all:
        break;
    }

    // Plus récent en premier
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Color _confColor(double conf) {
    if (conf >= 0.85) return const Color(0xFF00F5A0);
    if (conf >= 0.70) return const Color(0xFFFFD700);
    return const Color(0xFFFF6B6B);
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _copyAll(List<HistoryEntry> entries) async {
    final text = entries.map((e) => e.word).join(' ');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copié dans le presse-papier',
            style: GoogleFonts.spaceMono(fontSize: 12)),
        backgroundColor: const Color(0xFF00F5A0).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ASLState>(
      builder: (context, state, _) {
        final filtered = _applyFilter(state.historyEntries);
        final totalLetters =
            filtered.fold<int>(0, (sum, e) => sum + e.letterCount);
        final avgConf = filtered.isEmpty
            ? null
            : filtered.fold<double>(0, (sum, e) => sum + e.avgConfidence) /
                filtered.length;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──
                _TopBar(
                  onBack: () => Navigator.pop(context),
                  onClearAll: filtered.isEmpty
                      ? null
                      : () => context.read<ASLState>().clearHistory(),
                ),

                // ── Recherche ──
                _SearchBar(
                  controller: _searchController,
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),

                const Gap(12),

                // ── Statistiques ──
                _StatsRow(
                  wordCount: filtered.length,
                  letterCount: totalLetters,
                  avgConf: avgConf,
                ),

                const Gap(12),

                // ── Filtres ──
                _FilterChips(
                  current: _currentFilter,
                  onSelect: (f) => setState(() => _currentFilter = f),
                ),

                // ── Liste ──
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(hasHistory: state.historyEntries.isEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Gap(8),
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            return _WordCard(
                              entry: entry,
                              confColor: _confColor(entry.avgConfidence),
                              fmtTime: _fmtTime(entry.timestamp),
                              onDelete: () =>
                                  context.read<ASLState>().removeHistoryEntry(entry),
                            );
                          },
                        ),
                ),

                // ── Export / Copier ──
                if (filtered.isNotEmpty)
                  _ExportBar(onCopy: () => _copyAll(filtered)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Sous-widgets
// ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onClearAll;

  const _TopBar({required this.onBack, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        border: Border(bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              'HISTORIQUE',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                letterSpacing: 2,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          if (onClearAll != null)
            GestureDetector(
              onTap: onClearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3), width: 0.5),
                ),
                child: Text(
                  'TOUT EFFACER',
                  style: GoogleFonts.spaceMono(
                      fontSize: 10, letterSpacing: 1, color: const Color(0xFFFF6B6B)),
                ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search_rounded, color: Color(0x4DFFFFFF), size: 18),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: GoogleFonts.spaceMono(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un mot...',
                  hintStyle: GoogleFonts.spaceMono(
                      fontSize: 13, color: Colors.white.withOpacity(0.25)),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int wordCount;
  final int letterCount;
  final double? avgConf;

  const _StatsRow(
      {required this.wordCount,
      required this.letterCount,
      required this.avgConf});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            label: 'MOTS',
            value: '$wordCount',
            valueColor: const Color(0xFF00F5A0),
          ),
          const Gap(8),
          _StatCard(
            label: 'LETTRES',
            value: '$letterCount',
            valueColor: const Color(0xFF8B83FF),
          ),
          const Gap(8),
          _StatCard(
            label: 'CONFIANCE MOY.',
            value: avgConf != null ? '${(avgConf! * 100).round()}%' : '—',
            valueColor: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard(
      {required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Colors.white.withOpacity(0.3))),
            const Gap(4),
            Text(value,
                style: GoogleFonts.spaceMono(
                    fontSize: 18, fontWeight: FontWeight.w700, color: valueColor)),
          ],
        ),
      ),
    );
  }
}

enum _FilterType { all, today, highConf, longWords, shortWords }

class _FilterChips extends StatelessWidget {
  final _FilterType current;
  final ValueChanged<_FilterType> onSelect;

  const _FilterChips({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const chips = [
      (_FilterType.all, 'TOUS'),
      (_FilterType.today, "AUJOURD'HUI"),
      (_FilterType.highConf, 'CONFIANCE HAUTE'),
      (_FilterType.longWords, 'LONGS MOTS'),
      (_FilterType.shortWords, 'COURTS MOTS'),
    ];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips.map((chip) {
          final active = current == chip.$1;
          return GestureDetector(
            onTap: () => onSelect(chip.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFF6C63FF).withOpacity(0.5)
                      : Colors.white.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: Text(
                chip.$2,
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: active
                      ? const Color(0xFF8B83FF)
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final HistoryEntry entry;
  final Color confColor;
  final String fmtTime;
  final VoidCallback onDelete;

  const _WordCard({
    required this.entry,
    required this.confColor,
    required this.fmtTime,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          // Badge nombre de lettres
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: confColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: confColor.withOpacity(0.25), width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.letterCount}',
              style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: confColor),
            ),
          ),
          const Gap(12),
          // Mot + méta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.word,
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  '$fmtTime  ·  ${entry.sessionLabel}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          // Confiance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(entry.avgConfidence * 100).round()}%',
                style:
                    GoogleFonts.spaceMono(fontSize: 11, color: confColor),
              ),
              const Gap(4),
              SizedBox(
                width: 40,
                height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: entry.avgConfidence.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(confColor),
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          // Bouton supprimer
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.2),
                    width: 0.5),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasHistory;
  const _EmptyState({required this.hasHistory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.back_hand_outlined,
              color: Colors.white.withOpacity(0.2), size: 48),
          const Gap(12),
          Text(
            hasHistory ? 'AUCUN RÉSULTAT' : 'AUCUN MOT DANS L\'HISTORIQUE',
            style: GoogleFonts.spaceMono(
                fontSize: 12, letterSpacing: 1, color: Colors.white.withOpacity(0.2)),
          ),
          if (!hasHistory) ...[
            const Gap(6),
            Text(
              'Les mots validés via la caméra\napparaissent ici',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceMono(
                  fontSize: 10, color: Colors.white.withOpacity(0.12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExportBar extends StatelessWidget {
  final VoidCallback onCopy;
  const _ExportBar({required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onCopy,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_rounded,
                        color: Color(0xFF8B83FF), size: 16),
                    const Gap(6),
                    Text('COPIER TOUT',
                        style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            letterSpacing: 1,
                            color: const Color(0xFF8B83FF))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}