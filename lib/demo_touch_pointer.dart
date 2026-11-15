import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const _touchMarkDiameter = 44.0;
const _touchMarkHeight = 76.0;
const _touchMarkMaxWidth = 180.0;
const _touchMarkMargin = 8.0;

class DemoTouchPointer {
  static Future<void> showAndActivate(
    BuildContext context,
    GlobalKey target, {
    required String label,
    Future<void> Function()? onActivate,
    ScrollController? scrollController,
    bool Function()? shouldContinue,
  }) async {
    if (shouldContinue != null && !shouldContinue()) return;
    if (!context.mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayObject = overlay.context.findRenderObject();
    var targetContext = target.currentContext;
    if (targetContext == null &&
        scrollController != null &&
        scrollController.hasClients) {
      for (var attempt = 0; attempt < 40 && targetContext == null; attempt++) {
        final positions = scrollController.positions;
        if (positions.length != 1) {
          throw StateError(
              'The automated demo scroll target "$label" is ambiguous.');
        }
        final position = positions.single;
        final next = (position.pixels + position.viewportDimension * 0.75)
            .clamp(0.0, position.maxScrollExtent);
        if (next <= position.pixels) break;
        await scrollController.animateTo(
          next,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
        );
        targetContext = target.currentContext;
        if (shouldContinue != null && !shouldContinue()) return;
      }
    }
    final revealContext = target.currentContext;
    if (revealContext == null) {
      throw StateError('The automated demo target "$label" is not visible.');
    }
    if (!overlay.mounted || !revealContext.mounted) return;
    await Scrollable.ensureVisible(
      revealContext,
      alignment: 0.42,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final laidOutContext = target.currentContext;
    if (!overlay.mounted ||
        laidOutContext == null ||
        !laidOutContext.mounted ||
        (shouldContinue != null && !shouldContinue())) {
      return;
    }

    final renderObject = laidOutContext.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        overlayObject is! RenderBox ||
        !overlayObject.hasSize) {
      throw StateError('The automated demo target "$label" has no layout.');
    }

    final globalPosition = renderObject.localToGlobal(
      renderObject.size.center(Offset.zero),
    );
    final overlayPosition = overlayObject.globalToLocal(globalPosition);
    var pointerPosition = Offset(
      overlayObject.size.width - _touchMarkMargin - _touchMarkDiameter / 2,
      overlayObject.size.height - _touchMarkMargin - _touchMarkHeight / 2,
    );
    final markWidth = math.min(
      _touchMarkMaxWidth,
      math.max(0.0, overlayObject.size.width - _touchMarkMargin * 2),
    ).toDouble();
    var pressed = false;
    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              AnimatedPositioned(
                left: _boundedMarkLeft(
                  pointerPosition.dx,
                  overlayObject.size.width,
                  markWidth,
                ),
                top: _boundedMarkTop(pointerPosition, overlayObject.size),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                child: _TouchMark(
                  label: label,
                  pressed: pressed,
                  width: markWidth,
                  markerLeft: _boundedMarkerLeft(
                    pointerPosition.dx,
                    overlayObject.size.width,
                    markWidth,
                  ),
                  labelAlignment: _labelAlignment(
                    pointerPosition.dx,
                    overlayObject.size.width,
                    markWidth,
                  ),
                  labelAbove: _labelAbove(
                    pointerPosition.dy,
                    overlayObject.size.height,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    overlay.insert(entry);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!context.mounted || (shouldContinue != null && !shouldContinue())) {
        return;
      }
      pointerPosition = overlayPosition;
      entry.markNeedsBuild();
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!context.mounted || (shouldContinue != null && !shouldContinue())) {
        return;
      }
      pressed = true;
      entry.markNeedsBuild();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!context.mounted || (shouldContinue != null && !shouldContinue())) {
        return;
      }
      await onActivate?.call();
      pressed = false;
      entry.markNeedsBuild();
      await Future<void>.delayed(const Duration(milliseconds: 420));
    } finally {
      entry.remove();
      entry.dispose();
    }
  }
}

double _boundedMarkLeft(double x, double overlayWidth, double markWidth) {
  return (x - markWidth / 2).clamp(
    _touchMarkMargin,
    _maxMarkLeft(overlayWidth, markWidth),
  ).toDouble();
}

double _maxMarkLeft(double overlayWidth, double markWidth) => math.max(
      _touchMarkMargin,
      overlayWidth - markWidth - _touchMarkMargin,
    );

double _boundedMarkerLeft(double x, double overlayWidth, double markWidth) {
  final markLeft = _boundedMarkLeft(x, overlayWidth, markWidth);
  return (x - markLeft - _touchMarkDiameter / 2)
      .clamp(0.0, math.max(0.0, markWidth - _touchMarkDiameter))
      .toDouble();
}

Alignment _labelAlignment(double x, double overlayWidth, double markWidth) {
  final desiredLeft = x - markWidth / 2;
  if (desiredLeft < _touchMarkMargin) return Alignment.centerLeft;
  if (desiredLeft > _maxMarkLeft(overlayWidth, markWidth)) {
    return Alignment.centerRight;
  }
  return Alignment.center;
}

bool _labelAbove(double y, double overlayHeight) =>
    y + _touchMarkHeight / 2 > overlayHeight - _touchMarkMargin;

double _boundedMarkTop(Offset pointerPosition, Size overlaySize) {
  final top = _labelAbove(pointerPosition.dy, overlaySize.height)
      ? pointerPosition.dy - (_touchMarkHeight - _touchMarkDiameter / 2)
      : pointerPosition.dy - _touchMarkDiameter / 2;
  final maxTop = math.max(
    _touchMarkMargin,
    overlaySize.height - _touchMarkHeight - _touchMarkMargin,
  );
  return top.clamp(_touchMarkMargin, maxTop).toDouble();
}

class _TouchMark extends StatelessWidget {
  const _TouchMark({
    required this.label,
    required this.pressed,
    required this.width,
    required this.markerLeft,
    required this.labelAlignment,
    required this.labelAbove,
  });

  final String label;
  final bool pressed;
  final double width;
  final double markerLeft;
  final Alignment labelAlignment;
  final bool labelAbove;

  @override
  Widget build(BuildContext context) {
    final marker = Container(
      width: _touchMarkDiameter,
      height: _touchMarkDiameter,
      decoration: BoxDecoration(
        color: const Color(0xFF0088FF).withValues(alpha: 0.24),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF0088FF),
          width: pressed ? 4 : 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x990088FF),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.touch_app_rounded,
        color: Colors.white,
        size: 25,
      ),
    );
    final labelContainer = Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0088FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return AnimatedScale(
      scale: pressed ? 0.86 : 1,
      duration: const Duration(milliseconds: 120),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (labelAbove) ...[
              Align(
                alignment: labelAlignment,
                child: labelContainer,
              ),
              const SizedBox(height: 4),
            ],
            Align(
              alignment: Alignment(
                width <= _touchMarkDiameter
                    ? 0
                    : 2 * markerLeft / (width - _touchMarkDiameter) - 1,
                0,
              ),
              child: marker,
            ),
            if (!labelAbove) ...[
              const SizedBox(height: 4),
              Align(
                alignment: labelAlignment,
                child: labelContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
