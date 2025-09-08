import 'package:fixed_scroll_to_index/fixed_scroll_to_index.dart';
import 'package:flutter/material.dart';

typedef FixedScrollToIndexBuilderCallback =
    Widget Function(
      BuildContext context,
      FixedScrollToIndexController controller,
    );

class FixedScrollToIndexBuilder extends StatefulWidget {
  const FixedScrollToIndexBuilder({
    this.onIndexChanged,
    this.initialIndex,
    required this.config,
    required this.builder,
    super.key,
  });
  final FixedScrollConfig config;
  final int? initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final FixedScrollToIndexBuilderCallback builder;

  @override
  State<FixedScrollToIndexBuilder> createState() =>
      _FixedScrollToIndexBuilderState();
}

class _FixedScrollToIndexBuilderState extends State<FixedScrollToIndexBuilder> {
  late FixedScrollToIndexController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedScrollToIndexController(config: widget.config);
    if (widget.onIndexChanged != null) {
      _controller.addIndexListener(widget.onIndexChanged!);
    }

    if (widget.initialIndex != null) {
      WidgetsBinding.instance.endOfFrame.then((_) {
        if (mounted) {
          _controller.scrollToSection(
            widget.initialIndex!,
            duration: Duration.zero,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(FixedScrollToIndexBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update config if it changed
    if (widget.config != oldWidget.config) {
      _controller.dispose();
      _controller = FixedScrollToIndexController(config: widget.config);
    }

    // Handle onIndexChanged listener updates
    if (widget.onIndexChanged != oldWidget.onIndexChanged) {
      // Remove old listener if it existed
      if (oldWidget.onIndexChanged != null) {
        _controller.removeIndexListener(oldWidget.onIndexChanged!);
      }

      // Add new listener if it exists
      if (widget.onIndexChanged != null) {
        _controller.addIndexListener(widget.onIndexChanged!);
      }
    }

    // Handle initialIndex changes
    if (widget.initialIndex != oldWidget.initialIndex &&
        widget.initialIndex != null) {
      WidgetsBinding.instance.endOfFrame.then((_) {
        if (mounted) {
          _controller.scrollToSection(
            widget.initialIndex!,
            duration: Duration.zero,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.onIndexChanged != null) {
      _controller.removeIndexListener(widget.onIndexChanged!);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FixedScrollToIndexProvider(
      controller: _controller,
      child: Builder(
        builder: (context) {
          return widget.builder(context, _controller);
        },
      ),
    );
  }
}
