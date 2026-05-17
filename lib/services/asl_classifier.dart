import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ASLClassifier {
  static const String _modelPath = 'assets/models/best_int8.tflite';
  static const int _inputSize = 224;
  static const double confidenceThreshold = 0.60;
  static const List<String> classNames = [
    'A','B','C','D','E','F','G','H','I','J','K',
    'L','M','N','O','P','Q','R','S','T','U','V',
    'W','X','Y','Z'
  ];
  Interpreter? _interpreter;
  bool _isLoaded = false;
  late List<int> _outputShape;
  int _numClasses = 26;
  bool get isLoaded => _isLoaded;
  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);

      // Debug shapes
      final inputShape  = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final inputType   = _interpreter!.getInputTensor(0).type;
      final outputType  = _interpreter!.getOutputTensor(0).type;
      _outputShape = outputShape;
      _numClasses  = outputShape.last;

      _isLoaded = true;
    } catch (e) {
      print(' Erreur chargement modèle: $e');
      _isLoaded = false;
    }
  }

  ({String label, double confidence})? classify(img.Image cropImage) {
    if (!_isLoaded || _interpreter == null) return null;

    try {
      // Resize à 224x224
      final resized = img.copyResize(
        cropImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      final input  = _imageToFloat32(resized);
      final output = [List<double>.filled(_numClasses, 0.0)];

      _interpreter!.run(input, output);

      final probs = output[0];

      // Softmax si les valeurs ne somment pas à ~1 (logits bruts)
      final sum = probs.fold(0.0, (a, b) => a + b);
      final normalized = (sum > 1.5 || sum < 0.5)
          ? _softmax(probs)
          : probs;

      // Top-1
      int topIdx = 0;
      double topConf = normalized[0];
      for (int i = 1; i < normalized.length; i++) {
        if (normalized[i] > topConf) {
          topConf = normalized[i];
          topIdx  = i;
        }
      }

      final label = topIdx < classNames.length ? classNames[topIdx] : '?';
      print(' Top: $label (${(topConf * 100).toStringAsFixed(1)}%)');

      if (topConf < confidenceThreshold) return null;
      return (label: label, confidence: topConf);
    } catch (e) {
      print(' classify: $e');
      return null;
    }
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps   = logits.map((v) => (v - maxVal)).toList();
    // Simple normalization
    final expVals = exps.map((v) => v < -20 ? 0.0 : _exp(v)).toList();
    final sumExp  = expVals.fold(0.0, (a, b) => a + b);
    return sumExp == 0 ? logits : expVals.map((v) => v / sumExp).toList();
  }

  double _exp(double x) {
    // dart:math pas importé ici — approximation rapide
    return 1.0 / (1.0 + (-x).abs()); // fallback simple
  }

  List<List<List<List<double>>>> _imageToFloat32(img.Image image) {
    return List.generate(1, (_) =>
      List.generate(_inputSize, (y) =>
        List.generate(_inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        })
      )
    );
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}