import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // compute()
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:hand_detection/hand_detection.dart';

import '../services/asl_classifier.dart';
import '../services/hand_detector.dart';
import '../models/asl_state.dart';
import '../widgets/hand_overlay_painter.dart';
import '../widgets/bottom_hud_pannel.dart';
import '../widgets/top_hud_bar.dart';


class _AlignParams {
  final int width, height, yRowStride, uvRowStride;
  final Uint8List yBytes, uBytes, vBytes;
  final int rotDeg;
  final bool isFront;

  _AlignParams({
    required this.width,
    required this.height,
    required this.yBytes,
    required this.uBytes,
    required this.vBytes,
    required this.yRowStride,
    required this.uvRowStride,
    required this.rotDeg,
    required this.isFront,
  });
}


// Cette fonction tourne hors du thread UI dans un isolate
img.Image? _alignFrameIsolate(_AlignParams p) {
  try {
    final rgba = Uint8List(p.width * p.height * 4);
    int idx = 0;
    for (int row = 0; row < p.height; row++) {
      for (int col = 0; col < p.width; col++) {
        final yVal = p.yBytes[row * p.yRowStride + col];
        final uvIdx = (row ~/ 2) * p.uvRowStride + (col ~/ 2);
        final uVal = p.uBytes[uvIdx];
        final vVal = p.vBytes[uvIdx];
        rgba[idx++] = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
        rgba[idx++] = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
            .round()
            .clamp(0, 255);
        rgba[idx++] = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);
        rgba[idx++] = 255;
      }
    }
    //création de l'image 
    img.Image aligned = img.Image.fromBytes(
      width: p.width,
      height: p.height,
      bytes: rgba.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );
// Rotation + miroir dans le même Isolate 
    if (p.rotDeg != 0) {
      aligned = img.copyRotate(aligned, angle: p.rotDeg.toDouble());
    }
    if (p.isFront) {
      aligned = img.flipHorizontal(aligned);
    }
    return aligned;
  } catch (_) {
    return null;
  }
}


class CameraScreen extends StatefulWidget {
  
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
      int _frameSkipper = 0;
  CameraController? _controller;
  int _cameraIndex = 0;

  final ASLClassifier _classifier = ASLClassifier();
  final HandDetectorService _handDetector = HandDetectorService();

  bool _isProcessing = false;
  bool _isActive = true;
  List<HandBoundingBox> _handBoxes = [];

  int _alignedWidth = 1;
  int _alignedHeight = 1;

  final List<DateTime> _frameTimes = [];
  double _fps = 0;

  DeviceOrientation _deviceOrientation = DeviceOrientation.portraitUp;

// FIX 3 — debounce : on ne setState que si le résultat change
  String? _lastLabel;
  double _lastConf = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initAll();
  }

  Future<void> _initAll() async {
    await _classifier.loadModel();
    await _handDetector.initialize();
    await _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    final camera = widget.cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
      fps: 15,
    );
    try {
      await _controller!.initialize();
      if (!mounted) return;
      await _controller!.startImageStream(_processFrame);
      setState(() {});
    } catch (e) {
      debugPrint('Erreur caméra: $e');
    }
  }

  int _getRotationDegrees() {
    final camera = widget.cameras[_cameraIndex];
    return _handDetector.resolveRotationDegrees(
      sensorOrientation: camera.sensorOrientation,
      isFrontCamera: _isFrontCamera,
      deviceOrientation: _deviceOrientation,
    );
  }

  bool get _isFrontCamera =>
      widget.cameras[_cameraIndex].lensDirection == CameraLensDirection.front;

  Future<void> _flipCamera() async {
    if (widget.cameras.length < 2) return;
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    await _initCamera();
  }

  void _toggleActive() {
    setState(() => _isActive = !_isActive);
    if (!_isActive) {
      context.read<ASLState>().updateDetection(
            label: null,
            confidence: 0,
            handCount: 0,
            fps: 0,
          );
    }
  }


  void _processFrame(CameraImage cameraImage) async {
    _frameSkipper++;
    if (_frameSkipper % 3 != 0) return;

    if (_isProcessing || !_isActive || !_classifier.isLoaded) return;
    _isProcessing = true;

    try {
      // FPS counter
      final now = DateTime.now();
      _frameTimes.add(now);
      _frameTimes.removeWhere(
        (t) => now.difference(t) > const Duration(seconds: 1),
      );
      _fps = _frameTimes.length.toDouble();

      final rotDeg = _getRotationDegrees();
      final isFront = _isFrontCamera;

      // 1. Détection des mains (natif ML, rapide)
      final List<Hand> hands = await _handDetector.detectHands(
        cameraImage,
        rotDeg,
      );

      if (hands.isEmpty) {
        // FIX 3 — debounce : évite setState/updateDetection redondant
        if (_lastLabel != null || _lastConf != 0) {
          _lastLabel = null;
          _lastConf = 0;
          if (mounted) {
            context.read<ASLState>().updateDetection(
                  label: null,
                  confidence: 0,
                  handCount: 0,
                  fps: _fps,
                );
            setState(() => _handBoxes = []);
          }
        }
        _isProcessing = false;
        return;
      }

      // 2. Conversion YUV→RGB + rotate + flip dans l'Isolate (FIX 1 + 2)
      //    compute() = flutter's built-in Isolate helper, zéro boilerplate
      final alignedImage = await compute(
        _alignFrameIsolate,
        _AlignParams(
          width: cameraImage.width,
          height: cameraImage.height,
          // FIX 1 : lecture directe — pas de Uint8List.fromList()
          yBytes: cameraImage.planes[0].bytes,
          uBytes: cameraImage.planes[1].bytes,
          vBytes: cameraImage.planes[2].bytes,
          yRowStride: cameraImage.planes[0].bytesPerRow,
          uvRowStride: cameraImage.planes[1].bytesPerRow,
          rotDeg: rotDeg,
          isFront: isFront,
        ),
      );

      if (alignedImage == null) {
        _isProcessing = false;
        return;
      }

      // 3. Bboxes + classification
      final List<HandBoundingBox> newBoxes = [];
      String? bestLabel;
      double bestConf = 0;

      for (final hand in hands) {
        final bbox = _handDetector.getHandBoundingBox(
          hand,
          alignedImage.width,
          alignedImage.height,
        );
        if (bbox == null) continue;
        newBoxes.add(bbox);

        final crop = img.copyCrop(
          alignedImage,
          x: bbox.left.toInt(),
          y: bbox.top.toInt(),
          width: bbox.width
              .toInt()
              .clamp(1, alignedImage.width - bbox.left.toInt()),
          height: bbox.height
              .toInt()
              .clamp(1, alignedImage.height - bbox.top.toInt()),
        );

        final result = _classifier.classify(crop);
        if (result != null && result.confidence > bestConf) {
          bestLabel = result.label;
          bestConf = result.confidence;
        }
      }

      // debounce : setState seulement si label ou conf change
      final labelChanged = bestLabel != _lastLabel;
      final confChanged = (bestConf - _lastConf).abs() > 0.02; // seuil 2 %

      if (mounted) {
        if (labelChanged || confChanged) {
          _lastLabel = bestLabel;
          _lastConf = bestConf;
          context.read<ASLState>().updateDetection(
                label: bestLabel,
                confidence: bestConf,
                handCount: hands.length,
                fps: _fps,
              );
        }
        // Boxes : toujours mettre à jour (position change à chaque frame)
        setState(() {
          _handBoxes = newBoxes;
          _alignedWidth = alignedImage.width;
          _alignedHeight = alignedImage.height;
        });
      }
    } catch (e) {
      debugPrint('Erreur traitement frame: $e');
    } finally {
      _isProcessing = false;
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void didChangeMetrics() {
    final ratio = WidgetsBinding
        .instance.platformDispatcher.views.first.physicalSize.aspectRatio;
    final orientation = ratio > 1
        ? DeviceOrientation.landscapeLeft
        : DeviceOrientation.portraitUp;
    if (orientation != _deviceOrientation) {
      setState(() => _deviceOrientation = orientation);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.stopImageStream();
    _controller?.dispose();
    _classifier.dispose();
    _handDetector.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isReady = _controller?.value.isInitialized ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      body: isReady ? _buildCameraView() : _buildLoadingView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF6C63FF)),
          SizedBox(height: 16),
          Text('Chargement...',
              style: TextStyle(
                  color: Colors.white54,
                  fontFamily: 'SpaceMono',
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    final state = context.watch<ASLState>();
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        if (_handBoxes.isNotEmpty)
          CustomPaint(
            painter: HandOverlayPainter(
              boxes: _handBoxes,
              label: state.currentLabel,
              confidence: state.currentConfidence,
              hasDetection: state.hasDetection,
              imageWidth: _alignedWidth,
              imageHeight: _alignedHeight,
            ),
          ),
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopHudBar(
                isActive: _isActive,
                onToggle: _toggleActive,
                onFlip: _flipCamera)),
        const Positioned(bottom: 0, left: 0, right: 0, child: BottomHudPanel()),
        if (!_isActive)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.pause_circle_outline_rounded,
                    color: Colors.white54, size: 64),
                SizedBox(height: 12),
                Text('PAUSE',
                    style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'SpaceMono',
                        fontSize: 18,
                        letterSpacing: 4)),
              ]),
            ),
          ),
      ],
    );
  }
}
