import 'package:flutter/widgets.dart';
import '../core/scrollable_config.dart';

/// Callback function type for index change notifications.
///
/// Called whenever the visible group index changes during scrolling.
/// The [index] parameter represents the current visible group (0-based).
typedef IndexListener = void Function(int index);

final class FixedScrollToIndexController extends ScrollController {
  final FixedScrollConfig config;
  FixedScrollToIndexController({
    required this.config,
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  bool _isScrollingToSection = false;
  int _currentVisibleIndex = 0;

  // /// Threshold for detecting significant scroll changes.
  // /// Index change notifications are only triggered when scroll position
  // /// changes by more than this amount to avoid excessive callbacks.
  // static const double _scrollThreshold = 10.0;

  /// Scrolls to the beginning of a specific ContentSection.
  ///
  /// [index] - Index of the ContentSection in the config.sections list
  /// [duration] - Animation duration (optional, defaults to 300ms)
  /// [curve] - Animation curve (optional, defaults to Curves.easeInOut)
  ///
  /// The scroll offset is calculated by:
  /// 1. Adding the AnchorSection extent (height before the list)
  /// 2. Adding the extents of all ContentSections before the target section
  Future<void> scrollToSection(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    if (index < 0 || index >= config.sections.length) {
      throw ArgumentError(
        'sectionIndex must be within bounds of config.sections',
      );
    }

    _isScrollingToSection = true;

    double offset = 0.0;

    // Add the AnchorSection extent (height before the list)
    offset += config.anchor.extent;

    // Add extents of all sections before the target section
    for (int i = 0; i < index; i++) {
      offset += config.sections[i].extent;
    }

    // Animate to the calculated offset (beginning of the target section)
    await animateTo(offset, duration: duration, curve: curve);

    _isScrollingToSection = false;

    // Update the current visible index and notify listeners
    _updateCurrentVisibleIndex();
  }

  /// Empty listener array used as default to avoid null checks.
  /// This is a performance optimization to prevent allocation when no listeners are present.
  static final List<IndexListener?> _emptyIndexListeners =
      List<IndexListener?>.filled(0, null);

  /// Dynamic array of index change listeners.
  /// Uses a manual array management approach for better performance than List<T>.
  /// Contains null values in unused positions after listeners are removed.
  List<IndexListener?> _indexListeners = _emptyIndexListeners;

  /// Current number of active listeners in the [_indexListeners] array.
  /// This allows us to track active listeners without scanning the entire array.
  int _listenerCount = 0;

  /// Adds a listener that will be called whenever the visible group index changes.
  ///
  /// The listener function receives the new group index (0-based) as its parameter.
  /// Index changes are detected automatically during user scrolling and reported
  /// with a tolerance defined by [_scrollThreshold].
  ///
  /// The listener array automatically resizes as needed, doubling in size when full.
  ///
  /// Example:
  /// ```dart
  /// controller.addIndexListener((int index) {
  ///   print('Now viewing group: $index');
  ///   updateUI(index);
  /// });
  /// ```
  ///
  /// Note: Listener exceptions are caught silently to prevent breaking the
  /// scroll functionality. Ensure your listeners handle errors appropriately.
  void addIndexListener(IndexListener listener) {
    // Resize the array if we've reached capacity
    if (_listenerCount == _indexListeners.length) {
      if (_listenerCount == 0) {
        // Initialize with size 1 for first listener
        _indexListeners = List<IndexListener?>.filled(1, null);
      } else {
        // Double the size when we run out of space (exponential growth)
        final List<IndexListener?> newListeners = List<IndexListener?>.filled(
          _indexListeners.length * 2,
          null,
        );
        // Copy existing listeners to the new array
        for (int i = 0; i < _listenerCount; i++) {
          newListeners[i] = _indexListeners[i];
        }
        _indexListeners = newListeners;
      }
    }
    // Add the new listener at the next available position
    _indexListeners[_listenerCount++] = listener;
  }

  /// Removes a previously added index listener.
  ///
  /// Searches for the specified [listener] in the listeners array and removes it.
  /// The array is compacted and potentially shrunk to save memory if it becomes
  /// too sparse after removal.
  ///
  /// [listener] - The exact function reference that was previously added
  ///
  /// Returns true if the listener was found and removed, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// void myListener(int index) { /* ... */ }
  ///
  /// controller.addIndexListener(myListener);
  /// // ... later ...
  /// bool removed = controller.removeIndexListener(myListener);
  /// ```
  ///
  /// Note: This uses reference equality, so the exact same function instance
  /// must be provided for successful removal.
  bool removeIndexListener(IndexListener listener) {
    // Linear search for the listener (typically small number of listeners)
    for (int i = 0; i < _listenerCount; i++) {
      final IndexListener? listenerAtIndex = _indexListeners[i];
      if (listenerAtIndex == listener) {
        _removeAt(i);
        return true;
      }
    }
    return false; // Listener not found
  }

  /// Internal method to remove a listener at a specific array index.
  ///
  /// Handles array compaction and shrinking for memory efficiency.
  /// The array is shrunk by half when it becomes less than 50% utilized
  /// to prevent excessive memory usage with many add/remove cycles.
  ///
  /// [index] - The array index of the listener to remove
  void _removeAt(int index) {
    _listenerCount -= 1;

    // Shrink the array if we have too much unused space (less than 50% utilization)
    if (_listenerCount * 2 <= _indexListeners.length) {
      // Create new array with exact size needed
      final List<IndexListener?> newListeners = List<IndexListener?>.filled(
        _listenerCount,
        null,
      );

      // Copy listeners before the removed index
      for (int i = 0; i < index; i++) {
        newListeners[i] = _indexListeners[i];
      }

      // Copy listeners after the removed index
      for (int i = index; i < _listenerCount; i++) {
        newListeners[i] = _indexListeners[i + 1];
      }

      _indexListeners = newListeners;
    } else {
      // Just shift the remaining listeners to fill the gap
      for (int i = index; i < _listenerCount; i++) {
        _indexListeners[i] = _indexListeners[i + 1];
      }
      // Clear the last position
      _indexListeners[_listenerCount] = null;
    }
  }

  /// Notifies all registered index listeners about a group index change.
  ///
  /// Iterates through all active listeners and calls them with the new index.
  /// Listener exceptions are caught and silently ignored to prevent breaking
  /// the scroll functionality. This ensures that a misbehaving listener doesn't
  /// affect the overall scrolling experience.
  ///
  /// [index] - The new visible group index to report to listeners
  void _notifyIndexListeners(int index) {
    // Call all active listeners (up to _listenerCount, ignore null entries)
    for (int i = 0; i < _listenerCount; i++) {
      final listener = _indexListeners[i];
      if (listener != null) {
        try {
          listener(index);
        } catch (e) {
          // Silently catch listener errors to prevent breaking the scroll functionality
          // In a production app, you might want to log this error
          // debugPrint('IndexListener error: $e');
        }
      }
    }
  }

  /// Calculates which section is currently visible based on scroll position.
  ///
  /// Returns the index of the section that is most prominently visible
  /// in the viewport. This calculation accounts for the anchor section
  /// and cumulative section extents.
  ///
  /// Returns -1 if no sections are configured or if scroll position is invalid.
  int _calculateVisibleSectionIndex() {
    if (!hasClients || config.sections.isEmpty) {
      return -1;
    }

    final double currentOffset = offset;
    double cumulativeOffset = config.anchor.extent;

    // Find which section the current scroll position falls into
    for (int i = 0; i < config.sections.length; i++) {
      final sectionExtent = config.sections[i].extent;

      // Check if current position is within this section
      if (currentOffset < cumulativeOffset + sectionExtent) {
        return i;
      }

      cumulativeOffset += sectionExtent;
    }

    // If we've scrolled past all sections, return the last section index
    return config.sections.length - 1;
  }

  /// Updates the current visible index and notifies listeners if it has changed.
  ///
  /// This method is called during scroll updates to detect when the user
  /// has scrolled into a different section. It only triggers notifications
  /// when the visible section actually changes to avoid excessive callbacks.
  ///
  /// The method respects the [_isScrollingToSection] flag to prevent
  /// notifications during programmatic scrolling operations.
  void _updateCurrentVisibleIndex() {
    final newIndex = _calculateVisibleSectionIndex();

    // Only notify if the index has actually changed and we're not in a programmatic scroll
    if (newIndex != _currentVisibleIndex && newIndex >= 0) {
      _currentVisibleIndex = newIndex;

      // Don't notify during programmatic scrolling to avoid conflicting signals
      if (!_isScrollingToSection && _listenerCount > 0) {
        _notifyIndexListeners(_currentVisibleIndex);
      }
    }
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);

    // Add scroll listener to detect index changes during user scrolling
    position.addListener(_onScrollPositionChanged);
  }

  @override
  void detach(ScrollPosition position) {
    // Remove scroll listener when detaching
    position.removeListener(_onScrollPositionChanged);

    super.detach(position);
  }

  /// Called whenever the scroll position changes.
  ///
  /// This method monitors scroll position changes and updates the visible
  /// section index accordingly. It implements a threshold-based approach
  /// to avoid excessive calculations during rapid scrolling.
  void _onScrollPositionChanged() {
    // Only process scroll changes if we have listeners and aren't programmatically scrolling
    if (_listenerCount > 0 && !_isScrollingToSection && hasClients) {
      _updateCurrentVisibleIndex();
    }
  }

  /// Gets the current visible section index.
  ///
  /// Returns the 0-based index of the section that is currently most visible
  /// in the viewport. Returns -1 if no sections are visible or configured.
  ///
  /// This getter provides read-only access to the current state without
  /// triggering any calculations or notifications.
  int get currentVisibleIndex => _currentVisibleIndex;

  @override
  void dispose() {
    _indexListeners = _emptyIndexListeners;
    _listenerCount = 0;
    print('FixedScrollToIndexController disposed');
    super.dispose();
  }
}

// import 'package:flutter/widgets.dart';

// import '../core/scrollable_config.dart';

// /// Callback function type for index change notifications.
// ///
// /// Called whenever the visible group index changes during scrolling.
// /// The [index] parameter represents the current visible group (0-based).
// typedef IndexListener = void Function(int index);

// final class FixedScrollToIndexController extends ScrollController {
//   FixedScrollToIndexController({
//     required this.config,
//     super.initialScrollOffset,
//     super.keepScrollOffset,
//     super.debugLabel,
//     super.onAttach,
//     super.onDetach,
//   });

//   final ScrollableConfig config;

//   bool _isScrollingToSection = false;
//   int _currentVisibleIndex = 0;

//   /// Threshold for detecting significant scroll changes.
//   /// Index change notifications are only triggered when scroll position
//   /// changes by more than this amount to avoid excessive callbacks.
//   static const double _scrollThreshold = 10.0;

//   /// Checks if the controller is properly attached and ready for scrolling
//   bool get isReadyForScrolling => hasClients && positions.isNotEmpty;

//   /// Scrolls to the beginning of a specific ContentSection.
//   ///
//   /// [sectionIndex] - Index of the ContentSection in the config.sections list
//   /// [duration] - Animation duration (optional, defaults to 300ms)
//   /// [curve] - Animation curve (optional, defaults to Curves.easeInOut)
//   /// [maxRetries] - Maximum number of retry attempts if controller isn't ready
//   /// [retryDelay] - Delay between retry attempts
//   ///
//   /// The scroll offset is calculated by:
//   /// 1. Adding the AnchorSection extent (height before the list)
//   /// 2. Adding the extents of all ContentSections before the target section
//   Future<void> scrollToSection({
//     required int sectionIndex,
//     Duration duration = const Duration(milliseconds: 300),
//     Curve curve = Curves.easeInOut,
//     int maxRetries = 10,
//     Duration retryDelay = const Duration(milliseconds: 50),
//   }) async {
//     if (sectionIndex < 0 || sectionIndex >= config.sections.length) {
//       throw ArgumentError(
//         'sectionIndex must be within bounds of config.sections',
//       );
//     }

//     // Wait for the controller to be ready with retry mechanism
//     int retryCount = 0;
//     while (!isReadyForScrolling && retryCount < maxRetries) {
//       await Future.delayed(retryDelay);
//       retryCount++;
//     }

//     if (!isReadyForScrolling) {
//       throw StateError(
//         'ScrollController is not attached to any scroll views after $maxRetries retries. '
//         'Make sure the CustomScrollView is properly built and the controller is attached.',
//       );
//     }

//     _isScrollingToSection = true;

//     double offset = 0.0;

//     // Add the AnchorSection extent (height before the list)
//     offset += config.anchor.extent;

//     // Add extents of all sections before the target section
//     for (int i = 0; i < sectionIndex; i++) {
//       offset += config.sections[i].extent;
//     }

//     try {
//       // Animate to the calculated offset (beginning of the target section)
//       await animateTo(offset, duration: duration, curve: curve);
//     } finally {
//       _isScrollingToSection = false;

//       // Update the current visible index and notify listeners
//       _updateCurrentVisibleIndex();
//     }
//   }

//   /// Alternative method that waits for the next frame before scrolling
//   /// This is useful when calling immediately after widget creation
//   Future<void> scrollToSectionAfterFrame({
//     required int sectionIndex,
//     Duration duration = const Duration(milliseconds: 300),
//     Curve curve = Curves.easeInOut,
//   }) async {
//     // Wait for the next frame to ensure the widget tree is fully built
//     await WidgetsBinding.instance.endOfFrame;

//     // Additional small delay to ensure attachment
//     await Future.delayed(const Duration(milliseconds: 16));

//     return scrollToSection(
//       sectionIndex: sectionIndex,
//       duration: duration,
//       curve: curve,
//     );
//   }

//   /// Scrolls to section immediately if controller is ready, otherwise schedules it
//   void scrollToSectionWhenReady({
//     required int sectionIndex,
//     Duration duration = const Duration(milliseconds: 300),
//     Curve curve = Curves.easeInOut,
//   }) {
//     if (isReadyForScrolling) {
//       scrollToSection(
//         sectionIndex: sectionIndex,
//         duration: duration,
//         curve: curve,
//       );
//     } else {
//       // Schedule for next frame
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         scrollToSectionAfterFrame(
//           sectionIndex: sectionIndex,
//           duration: duration,
//           curve: curve,
//         );
//       });
//     }
//   }

//   /// Empty listener array used as default to avoid null checks.
//   /// This is a performance optimization to prevent allocation when no listeners are present.
//   static final List<IndexListener?> _emptyIndexListeners =
//       List<IndexListener?>.filled(0, null);

//   /// Dynamic array of index change listeners.
//   /// Uses a manual array management approach for better performance than List<T>.
//   /// Contains null values in unused positions after listeners are removed.
//   List<IndexListener?> _indexListeners = _emptyIndexListeners;

//   /// Current number of active listeners in the [_indexListeners] array.
//   /// This allows us to track active listeners without scanning the entire array.
//   int _listenerCount = 0;

//   /// Adds a listener that will be called whenever the visible group index changes.
//   ///
//   /// The listener function receives the new group index (0-based) as its parameter.
//   /// Index changes are detected automatically during user scrolling and reported
//   /// with a tolerance defined by [_scrollThreshold].
//   ///
//   /// The listener array automatically resizes as needed, doubling in size when full.
//   ///
//   /// Example:
//   /// ```dart
//   /// controller.addIndexListener((int index) {
//   ///   print('Now viewing group: $index');
//   ///   updateUI(index);
//   /// });
//   /// ```
//   ///
//   /// Note: Listener exceptions are caught silently to prevent breaking the
//   /// scroll functionality. Ensure your listeners handle errors appropriately.
//   void addIndexListener(IndexListener listener) {
//     // Resize the array if we've reached capacity
//     if (_listenerCount == _indexListeners.length) {
//       if (_listenerCount == 0) {
//         // Initialize with size 1 for first listener
//         _indexListeners = List<IndexListener?>.filled(1, null);
//       } else {
//         // Double the size when we run out of space (exponential growth)
//         final List<IndexListener?> newListeners = List<IndexListener?>.filled(
//           _indexListeners.length * 2,
//           null,
//         );
//         // Copy existing listeners to the new array
//         for (int i = 0; i < _listenerCount; i++) {
//           newListeners[i] = _indexListeners[i];
//         }
//         _indexListeners = newListeners;
//       }
//     }
//     // Add the new listener at the next available position
//     _indexListeners[_listenerCount++] = listener;
//   }

//   /// Removes a previously added index listener.
//   ///
//   /// Searches for the specified [listener] in the listeners array and removes it.
//   /// The array is compacted and potentially shrunk to save memory if it becomes
//   /// too sparse after removal.
//   ///
//   /// [listener] - The exact function reference that was previously added
//   ///
//   /// Returns true if the listener was found and removed, false otherwise.
//   ///
//   /// Example:
//   /// ```dart
//   /// void myListener(int index) { /* ... */ }
//   ///
//   /// controller.addIndexListener(myListener);
//   /// // ... later ...
//   /// bool removed = controller.removeIndexListener(myListener);
//   /// ```
//   ///
//   /// Note: This uses reference equality, so the exact same function instance
//   /// must be provided for successful removal.
//   bool removeIndexListener(IndexListener listener) {
//     // Linear search for the listener (typically small number of listeners)
//     for (int i = 0; i < _listenerCount; i++) {
//       final IndexListener? listenerAtIndex = _indexListeners[i];
//       if (listenerAtIndex == listener) {
//         _removeAt(i);
//         return true;
//       }
//     }
//     return false; // Listener not found
//   }

//   /// Internal method to remove a listener at a specific array index.
//   ///
//   /// Handles array compaction and shrinking for memory efficiency.
//   /// The array is shrunk by half when it becomes less than 50% utilized
//   /// to prevent excessive memory usage with many add/remove cycles.
//   ///
//   /// [index] - The array index of the listener to remove
//   void _removeAt(int index) {
//     _listenerCount -= 1;

//     // Shrink the array if we have too much unused space (less than 50% utilization)
//     if (_listenerCount * 2 <= _indexListeners.length) {
//       // Create new array with exact size needed
//       final List<IndexListener?> newListeners = List<IndexListener?>.filled(
//         _listenerCount,
//         null,
//       );

//       // Copy listeners before the removed index
//       for (int i = 0; i < index; i++) {
//         newListeners[i] = _indexListeners[i];
//       }

//       // Copy listeners after the removed index
//       for (int i = index; i < _listenerCount; i++) {
//         newListeners[i] = _indexListeners[i + 1];
//       }

//       _indexListeners = newListeners;
//     } else {
//       // Just shift the remaining listeners to fill the gap
//       for (int i = index; i < _listenerCount; i++) {
//         _indexListeners[i] = _indexListeners[i + 1];
//       }
//       // Clear the last position
//       _indexListeners[_listenerCount] = null;
//     }
//   }

//   /// Notifies all registered index listeners about a group index change.
//   ///
//   /// Iterates through all active listeners and calls them with the new index.
//   /// Listener exceptions are caught and silently ignored to prevent breaking
//   /// the scroll functionality. This ensures that a misbehaving listener doesn't
//   /// affect the overall scrolling experience.
//   ///
//   /// [index] - The new visible group index to report to listeners
//   void _notifyIndexListeners(int index) {
//     // Call all active listeners (up to _listenerCount, ignore null entries)
//     for (int i = 0; i < _listenerCount; i++) {
//       final listener = _indexListeners[i];
//       if (listener != null) {
//         try {
//           listener(index);
//         } catch (e) {
//           // Silently catch listener errors to prevent breaking the scroll functionality
//           // In a production app, you might want to log this error
//           // debugPrint('IndexListener error: $e');
//         }
//       }
//     }
//   }

//   /// Calculates which section is currently visible based on scroll position.
//   ///
//   /// Returns the index of the section that is most prominently visible
//   /// in the viewport. This calculation accounts for the anchor section
//   /// and cumulative section extents.
//   ///
//   /// Returns -1 if no sections are configured or if scroll position is invalid.
//   int _calculateVisibleSectionIndex() {
//     if (!isReadyForScrolling || config.sections.isEmpty) {
//       return -1;
//     }

//     final double currentOffset = offset;
//     double cumulativeOffset = config.anchor.extent;

//     // Find which section the current scroll position falls into
//     for (int i = 0; i < config.sections.length; i++) {
//       final sectionExtent = config.sections[i].extent;

//       // Check if current position is within this section
//       if (currentOffset < cumulativeOffset + sectionExtent) {
//         return i;
//       }

//       cumulativeOffset += sectionExtent;
//     }

//     // If we've scrolled past all sections, return the last section index
//     return config.sections.length - 1;
//   }

//   /// Updates the current visible index and notifies listeners if it has changed.
//   ///
//   /// This method is called during scroll updates to detect when the user
//   /// has scrolled into a different section. It only triggers notifications
//   /// when the visible section actually changes to avoid excessive callbacks.
//   ///
//   /// The method respects the [_isScrollingToSection] flag to prevent
//   /// notifications during programmatic scrolling operations.
//   void _updateCurrentVisibleIndex() {
//     final newIndex = _calculateVisibleSectionIndex();

//     // Only notify if the index has actually changed and we're not in a programmatic scroll
//     if (newIndex != _currentVisibleIndex && newIndex >= 0) {
//       _currentVisibleIndex = newIndex;

//       // Don't notify during programmatic scrolling to avoid conflicting signals
//       if (!_isScrollingToSection && _listenerCount > 0) {
//         _notifyIndexListeners(_currentVisibleIndex);
//       }
//     }
//   }

//   @override
//   void attach(ScrollPosition position) {
//     super.attach(position);

//     // Add scroll listener to detect index changes during user scrolling
//     position.addListener(_onScrollPositionChanged);
//   }

//   @override
//   void detach(ScrollPosition position) {
//     // Remove scroll listener when detaching
//     position.removeListener(_onScrollPositionChanged);

//     super.detach(position);
//   }

//   /// Called whenever the scroll position changes.
//   ///
//   /// This method monitors scroll position changes and updates the visible
//   /// section index accordingly. It implements a threshold-based approach
//   /// to avoid excessive calculations during rapid scrolling.
//   void _onScrollPositionChanged() {
//     // Only process scroll changes if we have listeners and aren't programmatically scrolling
//     if (_listenerCount > 0 && !_isScrollingToSection && isReadyForScrolling) {
//       _updateCurrentVisibleIndex();
//     }
//   }

//   /// Gets the current visible section index.
//   ///
//   /// Returns the 0-based index of the section that is currently most visible
//   /// in the viewport. Returns -1 if no sections are visible or configured.
//   ///
//   /// This getter provides read-only access to the current state without
//   /// triggering any calculations or notifications.
//   int get currentVisibleIndex => _currentVisibleIndex;

//   @override
//   void dispose() {
//     _indexListeners = _emptyIndexListeners;
//     _listenerCount = 0;
//     super.dispose();
//   }
// }
