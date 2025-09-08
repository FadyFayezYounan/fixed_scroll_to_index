import 'package:flutter/material.dart';

import '../../fixed_scroll_to_index.dart';

class FixedScrollToIndexConfigProvider extends InheritedWidget {
  const FixedScrollToIndexConfigProvider({
    super.key,
    required this.config,
    required super.child,
  });

  final FixedScrollConfig config;

  // Static method to access the provider from context
  // If listen is true (default: false), the caller will subscribe to updates.
  static FixedScrollToIndexConfigProvider? maybeOf(
    BuildContext context, {
    bool listen = false,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
            FixedScrollToIndexConfigProvider
          >();
    }
    final element = context
        .getElementForInheritedWidgetOfExactType<
          FixedScrollToIndexConfigProvider
        >();
    return element?.widget as FixedScrollToIndexConfigProvider?;
  }

  // Static method with null safety - throws if not found
  static FixedScrollToIndexConfigProvider of(
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
  bool updateShouldNotify(FixedScrollToIndexConfigProvider oldWidget) {
    return config != oldWidget.config;
  }
}
