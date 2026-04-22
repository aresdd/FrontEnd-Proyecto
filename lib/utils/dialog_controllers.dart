import 'package:flutter/widgets.dart';

/// Disposes [controllers] after the dialog route has finished releasing [TextField]s.
/// Call from `finally` after `showDialog` — immediate dispose on Cancel can crash.
void scheduleDisposeTextControllers(List<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}
