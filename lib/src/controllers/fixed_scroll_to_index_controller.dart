import 'package:flutter/widgets.dart';
import '../core/scrollable_section.dart';

/// Controller for managing scroll-to-index functionality with fixed layouts.
///
/// This controller takes a list of [ScrollableSection] objects that describe
/// the layout structure and provides methods to scroll to specific indices
/// within content sections.
final class FixedScrollToIndexController extends ScrollController {
  /// List of scrollable sections that define the layout structure
  final List<ScrollableSection> sections;

  /// Creates a [FixedScrollToIndexController] with the given sections.
  ///
  /// The [sections] list describes the layout from top to bottom (or left to right
  /// for horizontal scrolling) and is used to calculate scroll offsets.
  FixedScrollToIndexController({
    required this.sections,
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  /// Scrolls to the item at [index] within the [sectionIndex] content section.
  ///
  /// The [sectionIndex] specifies which content section to scroll to (0-based).
  /// The [index] specifies which item within that content section (0-based).
  ///
  /// Optional [duration] and [curve] can be provided for animated scrolling.
  /// If not provided, the scroll will jump instantly to the target position.
  ///
  /// Returns a [Future] that completes when the scroll animation finishes,
  /// or immediately if no animation is used.
  ///
  /// Throws [ArgumentError] if [sectionIndex] is out of bounds or if the
  /// section at [sectionIndex] is not a [ContentSection].
  /// Throws [RangeError] if [index] is out of bounds for the target content section.
  Future<void> scrollToIndex({
    required int sectionIndex,
    required int index,
    Duration? duration,
    Curve curve = Curves.easeInOut,
  }) async {
    if (sectionIndex < 0 || sectionIndex >= sections.length) {
      throw ArgumentError.value(
        sectionIndex,
        'sectionIndex',
        'Section index out of bounds. Must be between 0 and ${sections.length - 1}',
      );
    }

    final targetSection = sections[sectionIndex];
    if (targetSection is! ContentSection) {
      throw ArgumentError.value(
        sectionIndex,
        'sectionIndex',
        'Section at index $sectionIndex is not a ContentSection',
      );
    }

    if (index < 0 || index >= targetSection.itemCount) {
      throw RangeError.index(
        index,
        targetSection,
        'index',
        'Item index out of bounds',
        targetSection.itemCount,
      );
    }

    final offset = _calculateOffsetToIndex(sectionIndex, index);

    if (duration != null) {
      await animateTo(offset, duration: duration, curve: curve);
    } else {
      jumpTo(offset);
    }
  }

  /// Scrolls to the beginning of the content section at [sectionIndex].
  ///
  /// This is equivalent to calling [scrollToIndex] with `index: 0`.
  Future<void> scrollToSection({
    required int sectionIndex,
    Duration? duration,
    Curve curve = Curves.easeInOut,
  }) async {
    return scrollToIndex(
      sectionIndex: sectionIndex,
      index: 0,
      duration: duration,
      curve: curve,
    );
  }

  /// Finds the first content section and scrolls to the item at [index].
  ///
  /// This is a convenience method when you only have one content section
  /// or want to scroll to the first one found.
  ///
  /// Throws [StateError] if no content sections are found.
  Future<void> scrollToIndexInFirstContentSection({
    required int index,
    Duration? duration,
    Curve curve = Curves.easeInOut,
  }) async {
    final contentSectionIndex = sections.indexWhere(
      (section) => section is ContentSection,
    );

    if (contentSectionIndex == -1) {
      throw StateError('No content sections found in the layout');
    }

    return scrollToIndex(
      sectionIndex: contentSectionIndex,
      index: index,
      duration: duration,
      curve: curve,
    );
  }

  /// Calculates the scroll offset needed to reach the item at [index]
  /// within the content section at [sectionIndex].
  double _calculateOffsetToIndex(int sectionIndex, int index) {
    double offset = 0.0;

    // Add offsets from all sections before the target section
    for (int i = 0; i < sectionIndex; i++) {
      offset += sections[i].extent;
    }

    // Add offset within the target content section
    final targetSection = sections[sectionIndex] as ContentSection;

    // Calculate which row the item is in (for grid layouts)
    final row = index ~/ targetSection.mainAxisCount;

    // Add the extent of complete rows before the target row
    offset += row * (targetSection.itemExtent + targetSection.itemSpacing);

    return offset;
  }

  /// Gets information about the item at the current scroll position.
  ///
  /// Returns a [ScrollPositionInfo] object containing details about
  /// which section and item index corresponds to the current scroll offset.
  ScrollPositionInfo getCurrentPositionInfo() {
    final currentOffset = offset;
    double accumulatedOffset = 0.0;

    for (int sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
      final section = sections[sectionIndex];
      final sectionExtent = section.extent;

      if (currentOffset >= accumulatedOffset &&
          currentOffset < accumulatedOffset + sectionExtent) {
        if (section is ContentSection) {
          final offsetInSection = currentOffset - accumulatedOffset;
          final itemIndex = _getItemIndexFromOffset(section, offsetInSection);

          return ScrollPositionInfo(
            sectionIndex: sectionIndex,
            itemIndex: itemIndex,
            section: section,
          );
        } else {
          return ScrollPositionInfo(
            sectionIndex: sectionIndex,
            itemIndex: null,
            section: section,
          );
        }
      }

      accumulatedOffset += sectionExtent;
    }

    // If we're past all sections, return info for the last section
    if (sections.isNotEmpty) {
      final lastSection = sections.last;
      if (lastSection is ContentSection) {
        return ScrollPositionInfo(
          sectionIndex: sections.length - 1,
          itemIndex: lastSection.itemCount - 1,
          section: lastSection,
        );
      }
    }

    return ScrollPositionInfo(sectionIndex: -1, itemIndex: null, section: null);
  }

  /// Calculates which item index corresponds to the given offset within a content section.
  int _getItemIndexFromOffset(ContentSection section, double offsetInSection) {
    if (section.itemCount == 0) return 0;

    final rowHeight = section.itemExtent + section.itemSpacing;
    final row = (offsetInSection / rowHeight).floor();

    // Clamp the row to valid range
    final clampedRow = row.clamp(
      0,
      (section.itemCount / section.mainAxisCount).ceil() - 1,
    );

    // Calculate the first item index in this row
    final itemIndex = clampedRow * section.mainAxisCount;

    // Clamp to valid item range
    return itemIndex.clamp(0, section.itemCount - 1);
  }
}

/// Information about the current scroll position.
class ScrollPositionInfo {
  /// The index of the section at the current scroll position
  final int sectionIndex;

  /// The index of the item within the section (null for non-content sections)
  final int? itemIndex;

  /// The section at the current scroll position
  final ScrollableSection? section;

  const ScrollPositionInfo({
    required this.sectionIndex,
    required this.itemIndex,
    required this.section,
  });

  @override
  String toString() {
    return 'ScrollPositionInfo(sectionIndex: $sectionIndex, itemIndex: $itemIndex, section: $section)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollPositionInfo &&
          runtimeType == other.runtimeType &&
          sectionIndex == other.sectionIndex &&
          itemIndex == other.itemIndex &&
          section == other.section;

  @override
  int get hashCode => Object.hash(sectionIndex, itemIndex, section);
}
