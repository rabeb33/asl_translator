import 'package:flutter/foundation.dart';
import '../screens/history_screen.dart'; // HistoryEntry

class ASLState extends ChangeNotifier {
  // -- Detection courante --
  String? _currentLabel;
  double _currentConfidence = 0;
  int _handCount = 0;
  double _currentFps = 0;
  
// -- Detection courante --
  String _wordBuffer = '';
  final List<String> _wordHistory = []; // court historique (bottom HUD)
  final List<HistoryEntry> _historyEntries = []; // historique complet

  int _sessionIndex = 1;

  // ── Getters ────────────────────────────────
  String? get currentLabel => _currentLabel;
  double get currentConfidence => _currentConfidence;
  int get handCount => _handCount;
  double get currentFps => _currentFps;
  bool get hasDetection => _currentLabel != null && _currentConfidence > 0;

  String get wordBuffer => _wordBuffer;
  List<String> get wordHistory => List.unmodifiable(_wordHistory);
  List<HistoryEntry> get historyEntries => List.unmodifiable(_historyEntries);

  // ── Mise à jour détection caméra ───────────
  void updateDetection({
    required String? label,
    required double confidence,
    required int handCount,
    required double fps,
  }) {
    _currentLabel = label;
    _currentConfidence = confidence;
    _handCount = handCount;
    _currentFps = fps;
    notifyListeners();
  }

  // ── Buffer de mot ──────────────────────────
  void addCurrentLetter() {
    if (_currentLabel == null || _wordBuffer.length >= 20) return;
    _wordBuffer += _currentLabel!;
    notifyListeners();
  }

  void addSpace() {
    if (_wordBuffer.isEmpty || _wordBuffer.endsWith(' ')) return;
    _wordBuffer += ' ';
    notifyListeners();
  }

  void deleteLastLetter() {
    if (_wordBuffer.isEmpty) return;
    _wordBuffer = _wordBuffer.substring(0, _wordBuffer.length - 1);
    notifyListeners();
  }

  void clearBuffer() {
    _wordBuffer = '';
    notifyListeners();
  }

  /// Valide le mot courant → l'ajoute à l'historique
  void confirmWord() {
    final word = _wordBuffer.trim();
    if (word.isEmpty) return;

    // Historique court (HUD bas)
    _wordHistory.insert(0, word);
    if (_wordHistory.length > 50) _wordHistory.removeLast();

    // Historique complet
    _historyEntries.insert(
      0,
      HistoryEntry(
        word: word,
        avgConfidence: _currentConfidence,
        timestamp: DateTime.now(),
        letterCount: word.replaceAll(' ', '').length,
        sessionLabel: 'Session $_sessionIndex',
      ),
    );

    _wordBuffer = '';
    notifyListeners();
  }

  /// Supprime une entrée précise de l'historique
  void removeHistoryEntry(HistoryEntry entry) {
    _historyEntries.removeWhere((e) =>
        e.word == entry.word &&
        e.timestamp == entry.timestamp);
    notifyListeners();
  }

  /// Efface tout l'historique
  void clearHistory() {
    _historyEntries.clear();
    _wordHistory.clear();
    notifyListeners();
  }

  /// Incrémenter le compteur de session (appeler au démarrage d'une nouvelle session caméra)
  void nextSession() {
    _sessionIndex++;
  }
}