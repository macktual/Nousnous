import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Données des traits pour la signature (notifier pour éviter les setState qui font bouger le pavé).
class _SignatureData {
  _SignatureData({this.strokes = const [], this.currentStroke});

  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;

  _SignatureData copyWith({List<List<Offset>>? strokes, List<Offset>? currentStroke}) {
    return _SignatureData(
      strokes: strokes ?? this.strokes,
      currentStroke: currentStroke ?? this.currentStroke,
    );
  }

  bool get hasContent {
    if (strokes.isNotEmpty) return true;
    if (currentStroke != null && currentStroke!.length > 1) return true;
    return false;
  }

  List<List<Offset>> get allStrokesForPaint {
    final list = List<List<Offset>>.from(strokes);
    if (currentStroke != null && currentStroke!.length > 1) {
      list.add(currentStroke!);
    }
    return list;
  }
}

/// Zone de signature manuscrite à l'écran.
/// Utilise [repaintBoundaryKey] pour capturer l'image via [SignaturePad.capture].
/// Le pavé a une taille fixe et seuls les traits sont redessinés (sans rebuild du layout) pour éviter que la zone bouge pendant la signature.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    this.repaintBoundaryKey,
    this.height = 120,
    this.strokeWidth = 2.0,
    this.strokeColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  final GlobalKey? repaintBoundaryKey;
  final double height;
  final double strokeWidth;
  final Color strokeColor;
  final Color backgroundColor;

  /// Capture la signature en image PNG. Retourne null si la clé n'est pas attachée
  /// ou si la capture échoue.
  static Future<ui.Image?> capture(GlobalKey key, {double pixelRatio = 2.0}) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    try {
      return await boundary.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      return null;
    }
  }

  /// Convertit une [ui.Image] en bytes PNG (pour insertion dans un PDF).
  static Future<List<int>?> imageToPngBytes(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List().toList();
    } catch (_) {
      return null;
    }
  }

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final ValueNotifier<_SignatureData> _data = ValueNotifier<_SignatureData>(_SignatureData());

  void _onPointerDown(PointerDownEvent event) {
    _data.value = _data.value.copyWith(currentStroke: [event.localPosition]);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final cur = _data.value.currentStroke;
    if (cur == null) return;
    final next = List<Offset>.from(cur)..add(event.localPosition);
    _data.value = _data.value.copyWith(currentStroke: next);
  }

  void _onPointerUp(PointerUpEvent event) {
    final cur = _data.value.currentStroke;
    if (cur != null && cur.length > 1) {
      _data.value = _SignatureData(
        strokes: [..._data.value.strokes, cur],
        currentStroke: null,
      );
    } else {
      _data.value = _data.value.copyWith(currentStroke: null);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _data.value = _data.value.copyWith(currentStroke: null);
  }

  void _clear() {
    _data.value = _SignatureData();
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Signez ci-dessous (appuyez puis glissez)', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        SizedBox(
          height: h,
          width: double.infinity,
          child: RepaintBoundary(
            key: widget.repaintBoundaryKey,
            child: Container(
              height: h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  behavior: HitTestBehavior.opaque,
                  child: ValueListenableBuilder<_SignatureData>(
                    valueListenable: _data,
                    builder: (_, data, __) {
                      return CustomPaint(
                        painter: _SignaturePainter(
                          strokes: data.allStrokesForPaint,
                          strokeWidth: widget.strokeWidth,
                          strokeColor: widget.strokeColor,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<_SignatureData>(
          valueListenable: _data,
          builder: (_, data, __) {
            return TextButton.icon(
              onPressed: data.hasContent ? _clear : null,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Effacer'),
            );
          },
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({
    required this.strokes,
    required this.strokeWidth,
    required this.strokeColor,
  });

  final List<List<Offset>> strokes;
  final double strokeWidth;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
