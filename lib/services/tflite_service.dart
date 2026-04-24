import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteResult {
  final String label;
  final double confidence;
  const TfliteResult({required this.label, required this.confidence});
}

enum _OutputLayout {
  classification, // [1, C]
  yoloChannelFirst, // [1, 4+C, N] — YOLOv8 default
  yoloAnchorFirst, // [1, N, 4+C]
  unknown,
}

class TfliteService {
  static const String _modelAsset = 'assets/best_float32.tflite';
  static const String _labelsAsset = 'assets/labels.txt';

  Interpreter? _interpreter;
  List<String> _labels = const [];

  int _inputH = 640;
  int _inputW = 640;
  bool _inputChannelFirst = false;

  _OutputLayout _outputLayout = _OutputLayout.unknown;
  int _outNumClasses = 0;
  int _outNumAnchors = 0;

  bool get isReady =>
      _interpreter != null && _outputLayout != _OutputLayout.unknown;

  Future<bool> init() async {
    try {
      final interpreter = await Interpreter.fromAsset(_modelAsset);

      final labelsRaw = await rootBundle.loadString(_labelsAsset);
      _labels = labelsRaw
          .split(RegExp(r'[\r\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final inShape = interpreter.getInputTensor(0).shape;
      final outShape = interpreter.getOutputTensor(0).shape;

      debugPrint('[TFLite] input shape: $inShape');
      debugPrint('[TFLite] output shape: $outShape');
      debugPrint('[TFLite] labels count: ${_labels.length}');

      if (inShape.length == 4) {
        if (inShape[1] == 3) {
          _inputChannelFirst = true;
          _inputH = inShape[2];
          _inputW = inShape[3];
        } else {
          _inputChannelFirst = false;
          _inputH = inShape[1];
          _inputW = inShape[2];
        }
      }

      if (outShape.length == 2 && outShape[1] == _labels.length) {
        _outputLayout = _OutputLayout.classification;
      } else if (outShape.length == 3) {
        final a = outShape[1];
        final b = outShape[2];
        if (a == 4 + _labels.length) {
          _outputLayout = _OutputLayout.yoloChannelFirst;
          _outNumClasses = _labels.length;
          _outNumAnchors = b;
        } else if (b == 4 + _labels.length) {
          _outputLayout = _OutputLayout.yoloAnchorFirst;
          _outNumClasses = _labels.length;
          _outNumAnchors = a;
        }
      }

      if (_outputLayout == _OutputLayout.unknown) {
        debugPrint(
          '[TFLite] output shape $outShape does not match ${_labels.length} labels — disabling tflite',
        );
        interpreter.close();
        return false;
      }

      _interpreter = interpreter;
      debugPrint(
        '[TFLite] ready — input=${_inputW}x$_inputH channelFirst=$_inputChannelFirst layout=$_outputLayout',
      );
      return true;
    } catch (e, st) {
      debugPrint('[TFLite] init failed: $e\n$st');
      return false;
    }
  }

  Future<TfliteResult?> classify(
    Uint8List imageBytes, {
    double minConfidence = 0.5,
  }) async {
    final interp = _interpreter;
    if (interp == null || _outputLayout == _OutputLayout.unknown) return null;

    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final resized = img.copyResize(
        decoded,
        width: _inputW,
        height: _inputH,
      );

      final inputLen = _inputW * _inputH * 3;
      final floatBuf = Float32List(inputLen);

      if (_inputChannelFirst) {
        int rIdx = 0;
        int gIdx = _inputW * _inputH;
        int bIdx = 2 * _inputW * _inputH;
        for (int y = 0; y < _inputH; y++) {
          for (int x = 0; x < _inputW; x++) {
            final p = resized.getPixel(x, y);
            floatBuf[rIdx++] = p.r / 255.0;
            floatBuf[gIdx++] = p.g / 255.0;
            floatBuf[bIdx++] = p.b / 255.0;
          }
        }
      } else {
        int i = 0;
        for (int y = 0; y < _inputH; y++) {
          for (int x = 0; x < _inputW; x++) {
            final p = resized.getPixel(x, y);
            floatBuf[i++] = p.r / 255.0;
            floatBuf[i++] = p.g / 255.0;
            floatBuf[i++] = p.b / 255.0;
          }
        }
      }

      final inputShape = _inputChannelFirst
          ? [1, 3, _inputH, _inputW]
          : [1, _inputH, _inputW, 3];
      final input = floatBuf.reshape(inputShape);

      switch (_outputLayout) {
        case _OutputLayout.classification:
          return _runClassification(interp, input, minConfidence);
        case _OutputLayout.yoloChannelFirst:
          return _runYoloChannelFirst(interp, input, minConfidence);
        case _OutputLayout.yoloAnchorFirst:
          return _runYoloAnchorFirst(interp, input, minConfidence);
        case _OutputLayout.unknown:
          return null;
      }
    } catch (e, st) {
      debugPrint('[TFLite] classify error: $e\n$st');
      return null;
    }
  }

  TfliteResult? _runClassification(
    Interpreter interp,
    Object input,
    double minConfidence,
  ) {
    final out = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    interp.run(input, out);

    final scores =
        List<double>.from((out[0] as List).map((v) => (v as num).toDouble()));
    final total = scores.fold<double>(0, (a, b) => a + b);
    final isProb = scores.every((v) => v >= 0 && v <= 1) && total <= 1.2;
    final probs = isProb ? scores : _softmax(scores);

    double best = 0;
    int bestIdx = 0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > best) {
        best = probs[i];
        bestIdx = i;
      }
    }

    if (bestIdx >= _labels.length || best < minConfidence) return null;
    return TfliteResult(label: _labels[bestIdx], confidence: best);
  }

  TfliteResult? _runYoloChannelFirst(
    Interpreter interp,
    Object input,
    double minConfidence,
  ) {
    final out = List.filled(
      (4 + _outNumClasses) * _outNumAnchors,
      0.0,
    ).reshape([1, 4 + _outNumClasses, _outNumAnchors]);
    interp.run(input, out);

    double best = 0;
    int bestClass = -1;
    for (int n = 0; n < _outNumAnchors; n++) {
      for (int c = 0; c < _outNumClasses; c++) {
        final score = (out[0][4 + c][n] as num).toDouble();
        if (score > best) {
          best = score;
          bestClass = c;
        }
      }
    }

    if (bestClass < 0 || best < minConfidence) return null;
    return TfliteResult(label: _labels[bestClass], confidence: best);
  }

  TfliteResult? _runYoloAnchorFirst(
    Interpreter interp,
    Object input,
    double minConfidence,
  ) {
    final out = List.filled(
      _outNumAnchors * (4 + _outNumClasses),
      0.0,
    ).reshape([1, _outNumAnchors, 4 + _outNumClasses]);
    interp.run(input, out);

    double best = 0;
    int bestClass = -1;
    for (int n = 0; n < _outNumAnchors; n++) {
      for (int c = 0; c < _outNumClasses; c++) {
        final score = (out[0][n][4 + c] as num).toDouble();
        if (score > best) {
          best = score;
          bestClass = c;
        }
      }
    }

    if (bestClass < 0 || best < minConfidence) return null;
    return TfliteResult(label: _labels[bestClass], confidence: best);
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    double sum = 0;
    final exps = logits.map((v) {
      final e = math.exp(v - maxVal);
      sum += e;
      return e;
    }).toList();
    if (sum == 0) return exps;
    return exps.map((e) => e / sum).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
