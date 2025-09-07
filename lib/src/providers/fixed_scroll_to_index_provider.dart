import 'package:flutter/material.dart';

import '../../fixed_scroll_to_index.dart';

class FixedScrollToIndexProvider extends InheritedWidget {
  FixedScrollToIndexProvider({
    super.key,
    required this.controller,
    required super.child,
  }) : config = controller.config;

  final FixedScrollToIndexController controller;
  final ScrollableConfig config;

  // Static method to access the provider from context
  // If listen is true (default: false), the caller will subscribe to updates.
  static FixedScrollToIndexProvider? maybeOf(
    BuildContext context, {
    bool listen = false,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<FixedScrollToIndexProvider>();
    }
    final element = context
        .getElementForInheritedWidgetOfExactType<FixedScrollToIndexProvider>();
    return element?.widget as FixedScrollToIndexProvider?;
  }

  // Static method with null safety - throws if not found
  static FixedScrollToIndexProvider of(
    BuildContext context, {
    bool listen = false,
  }) {
    final provider = maybeOf(context, listen: listen);
    if (provider == null) {
      throw FlutterError(
        'FixedScrollToIndexProvider.of() was called with a context that does not contain '
        'a FixedScrollToIndexProvider.\n'
        'Ensure your widget tree includes FixedScrollToIndexProvider (e.g., via FixedScrollToIndexBuilder).',
      );
    }
    return provider;
  }

  @override
  bool updateShouldNotify(FixedScrollToIndexProvider oldWidget) {
    return controller != oldWidget.controller || config != oldWidget.config;
  }
}
