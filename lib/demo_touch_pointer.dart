import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DemoTouchPointer {
  static int _nextPointer = 1;

  static Future<void> tap(
    BuildContext context,
    GlobalKey target, {
    required String label,
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
    final pointerId = _nextPointer++;
    var pointerPosition = Offset(
      (overlayObject.size.width - 44).clamp(0, overlayObject.size.width),
      (overlayObject.size.height - 70).clamp(0, overlayObject.size.height),
    );
    var pressed = false;
    var attached = true;
    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              AnimatedPositioned(
                left: pointerPosition.dx - 22,
                top: pointerPosition.dy - 22,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                child: _TouchMark(label: label, pressed: pressed),
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
      GestureBinding.instance.handlePointerEvent(
        PointerDownEvent(
          pointer: pointerId,
          position: globalPosition,
          kind: PointerDeviceKind.touch,
          buttons: kPrimaryButton,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 140));
      GestureBinding.instance.handlePointerEvent(
        PointerUpEvent(
          pointer: pointerId,
          position: globalPosition,
          kind: PointerDeviceKind.touch,
        ),
      );
      pressed = false;
      entry.markNeedsBuild();
      await Future<void>.delayed(const Duration(milliseconds: 420));
    } finally {
      if (attached) {
        entry.remove();
        entry.dispose();
        attached = false;
      }
    }
  }
}

class _TouchMark extends StatelessWidget {
  const _TouchMark({required this.label, required this.pressed});

  final String label;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? 0.86 : 1,
      duration: const Duration(milliseconds: 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
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
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 130),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0088FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
