import 'scrollable_extent.dart';

final class AnchorSection extends ScrollableExtent {
  const AnchorSection({this.extent = 0.0});

  @override
  final double extent;

  @override
  String toString() => 'AnchorSection(extent: $extent)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnchorSection &&
          runtimeType == other.runtimeType &&
          extent == other.extent;
  @override
  int get hashCode => extent.hashCode;
}

typedef ContentSectionExtentBuilder = double Function(int itemIndex);

double _defaultItemSpacingBuilder(int itemIndex) => 0.0;

final class ContentSection extends ScrollableExtent {
  final double sectionHeader;
  final int itemCount;
  final ContentSectionExtentBuilder itemSpacingBuilder;
  final ContentSectionExtentBuilder itemExtentBuilder;
  final int mainAxisCount;

  ContentSection({
    this.sectionHeader = 0.0,
    required this.itemCount,
    required this.itemExtentBuilder,
    this.itemSpacingBuilder = _defaultItemSpacingBuilder,
    this.mainAxisCount = 1,
  }) : assert(sectionHeader >= 0, 'Section header must be non-negative'),
       assert(itemCount >= 0, 'Item count must be non-negative'),
       // Validate builder return values when there are items.
       assert(
         itemCount == 0 || itemExtentBuilder(0) > 0,
         'Item extent must be positive',
       ),
       assert(
         itemCount == 0 || itemSpacingBuilder(0) >= 0,
         'Item spacing must be non-negative',
       ),
       assert(mainAxisCount > 0, 'Main axis count must be positive');

  @override
  double get extent {
    if (itemCount == 0) return sectionHeader;

    // Calculate number of rows
    final rows = (itemCount / mainAxisCount).ceil();

    double totalItemExtent = 0.0;
    double totalSpacing = 0.0;

    for (int row = 0; row < rows; row++) {
      // For each row, find the max item extent and spacing in that row
      double maxItemExtent = 0.0;
      double maxSpacing = 0.0;

      for (int col = 0; col < mainAxisCount; col++) {
        final itemIndex = row * mainAxisCount + col;
        if (itemIndex >= itemCount) break;

        final itemExtent = itemExtentBuilder(itemIndex);
        final itemSpacing = itemSpacingBuilder(itemIndex);

        if (itemExtent > maxItemExtent) {
          maxItemExtent = itemExtent;
        }
        if (itemSpacing > maxSpacing) {
          maxSpacing = itemSpacing;
        }
      }

      totalItemExtent += maxItemExtent;
      if (row < rows - 1) {
        totalSpacing += maxSpacing;
      }
    }

    return sectionHeader + totalItemExtent + totalSpacing;
  }
}

final class ScrollableConfig {
  const ScrollableConfig({
    this.anchor = const AnchorSection(),
    required this.sections,
  });

  final AnchorSection anchor;
  final List<ContentSection> sections;

  @override
  String toString() => 'ScrollableConfig(anchor: $anchor, sections: $sections)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollableConfig &&
          runtimeType == other.runtimeType &&
          anchor == other.anchor &&
          sections == other.sections;
  @override
  int get hashCode => Object.hash(anchor, Object.hashAll(sections));
}

// sealed class ScrollableSection {
//   const ScrollableSection();

//   const factory ScrollableSection.spacing({double extent}) = SpacingSection;
//   const factory ScrollableSection.anchor({double extent}) = AnchorSection;
//   const factory ScrollableSection.content({
//     required int itemCount,
//     required double itemExtent,
//     double itemSpacing,
//     int mainAxisCount,
//   }) = ContentSection;

//   /// Gets the total extent (height for vertical, width for horizontal) of this section.
//   ///
//   /// For [SpacingSection] and [AnchorSection], this returns their direct extent.
//   /// For [ContentSection], this calculates the total extent based on item count,
//   /// item extent, spacing, and main axis count.
//   double get extent;

//   /// Pattern matching method that handles all possible cases.
//   ///
//   /// This method must be implemented by all subclasses and requires
//   /// handlers for all three section types: spacing, anchor, and content.
//   T when<T>({
//     required T Function(SpacingSection spacing) spacing,
//     required T Function(AnchorSection anchor) anchor,
//     required T Function(ContentSection content) content,
//   });

//   /// Pattern matching method that allows for optional case handling.
//   ///
//   /// This method provides a default [orElse] handler for cases not
//   /// explicitly handled. Only the cases you're interested in need to be provided.
//   T maybeWhen<T>({
//     T Function(SpacingSection spacing)? spacing,
//     T Function(AnchorSection anchor)? anchor,
//     T Function(ContentSection content)? content,
//     required T Function() orElse,
//   });

//   /// Executes the provided callback if this is a [SpacingSection].
//   ///
//   /// Returns the result of the callback if this is a spacing section,
//   /// otherwise returns null.
//   T? whenSpacing<T>(T Function(SpacingSection spacing) callback);

//   /// Executes the provided callback if this is an [AnchorSection].
//   ///
//   /// Returns the result of the callback if this is an anchor section,
//   /// otherwise returns null.
//   T? whenAnchor<T>(T Function(AnchorSection anchor) callback);

//   /// Executes the provided callback if this is a [ContentSection].
//   ///
//   /// Returns the result of the callback if this is a content section,
//   /// otherwise returns null.
//   T? whenContent<T>(T Function(ContentSection content) callback);
// }

// /// Represents empty space in the scroll view.
// /// Not directly scrollable to, but used for scroll offset calculations.
// final class SpacingSection extends ScrollableSection {
//   /// The extent (height for vertical, width for horizontal) of the spacing
//   @override
//   final double extent;

//   const SpacingSection({this.extent = 0.0})
//     : assert(extent >= 0, 'Spacing extent must be non-negative');

//   @override
//   T when<T>({
//     required T Function(SpacingSection spacing) spacing,
//     required T Function(AnchorSection anchor) anchor,
//     required T Function(ContentSection content) content,
//   }) => spacing(this);

//   @override
//   T maybeWhen<T>({
//     T Function(SpacingSection spacing)? spacing,
//     T Function(AnchorSection anchor)? anchor,
//     T Function(ContentSection content)? content,
//     required T Function() orElse,
//   }) => spacing?.call(this) ?? orElse();

//   @override
//   T? whenSpacing<T>(T Function(SpacingSection spacing) callback) =>
//       callback(this);

//   @override
//   T? whenAnchor<T>(T Function(AnchorSection anchor) callback) => null;

//   @override
//   T? whenContent<T>(T Function(ContentSection content) callback) => null;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is SpacingSection &&
//           runtimeType == other.runtimeType &&
//           extent == other.extent;

//   @override
//   int get hashCode => extent.hashCode;

//   @override
//   String toString() => 'SpacingSection(extent: $extent)';
// }

// /// Defines an anchor point where scroll calculations begin.
// /// Used to mark reference points in the scroll view, such as skipping
// /// header widgets when scrolling to categories.
// final class AnchorSection extends ScrollableSection {
//   /// Optional extent for the anchor (useful for offset calculations)
//   @override
//   final double extent;

//   const AnchorSection({this.extent = 0.0})
//     : assert(extent >= 0, 'Anchor extent must be non-negative');

//   @override
//   T when<T>({
//     required T Function(SpacingSection spacing) spacing,
//     required T Function(AnchorSection anchor) anchor,
//     required T Function(ContentSection content) content,
//   }) => anchor(this);

//   @override
//   T maybeWhen<T>({
//     T Function(SpacingSection spacing)? spacing,
//     T Function(AnchorSection anchor)? anchor,
//     T Function(ContentSection content)? content,
//     required T Function() orElse,
//   }) => anchor?.call(this) ?? orElse();

//   @override
//   T? whenSpacing<T>(T Function(SpacingSection spacing) callback) => null;

//   @override
//   T? whenAnchor<T>(T Function(AnchorSection anchor) callback) => callback(this);

//   @override
//   T? whenContent<T>(T Function(ContentSection content) callback) => null;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is AnchorSection &&
//           runtimeType == other.runtimeType &&
//           extent == other.extent;

//   @override
//   int get hashCode => extent.hashCode;

//   @override
//   String toString() => 'AnchorSection(extent: $extent)';
// }

// /// Represents a scrollable content section with items.
// /// Can be used for both SliverGrid and SliverList implementations.
// final class ContentSection extends ScrollableSection {
//   /// Number of items in this section
//   final int itemCount;

//   /// Spacing between items
//   final double itemSpacing;

//   /// Item extent (height for vertical, width for horizontal)
//   final double itemExtent;

//   /// Number of items in the main axis
//   final int mainAxisCount;

//   const ContentSection({
//     required this.itemCount,
//     required this.itemExtent,
//     this.itemSpacing = 0.0,
//     this.mainAxisCount = 1,
//   }) : assert(itemCount >= 0, 'Item count must be non-negative'),
//        assert(itemExtent > 0, 'Item extent must be positive'),
//        assert(itemSpacing >= 0, 'Item spacing must be non-negative'),
//        assert(mainAxisCount > 0, 'Main axis count must be positive');

//   @override
//   double get extent {
//     if (itemCount == 0) return 0.0;

//     // Calculate number of rows
//     final rows = (itemCount / mainAxisCount).ceil();

//     // Total extent = (rows * itemExtent) + ((rows - 1) * itemSpacing)
//     final totalItemExtent = rows * itemExtent;
//     final totalSpacing = (rows - 1) * itemSpacing;

//     return totalItemExtent + totalSpacing;
//   }

//   @override
//   T when<T>({
//     required T Function(SpacingSection spacing) spacing,
//     required T Function(AnchorSection anchor) anchor,
//     required T Function(ContentSection content) content,
//   }) => content(this);

//   @override
//   T maybeWhen<T>({
//     T Function(SpacingSection spacing)? spacing,
//     T Function(AnchorSection anchor)? anchor,
//     T Function(ContentSection content)? content,
//     required T Function() orElse,
//   }) => content?.call(this) ?? orElse();

//   @override
//   T? whenSpacing<T>(T Function(SpacingSection spacing) callback) => null;

//   @override
//   T? whenAnchor<T>(T Function(AnchorSection anchor) callback) => null;

//   @override
//   T? whenContent<T>(T Function(ContentSection content) callback) =>
//       callback(this);

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is ContentSection &&
//           runtimeType == other.runtimeType &&
//           itemCount == other.itemCount &&
//           itemSpacing == other.itemSpacing &&
//           itemExtent == other.itemExtent &&
//           mainAxisCount == other.mainAxisCount;

//   @override
//   int get hashCode =>
//       Object.hash(itemCount, itemSpacing, itemExtent, mainAxisCount);

//   @override
//   String toString() =>
//       'ContentSection(itemCount: $itemCount, itemExtent: $itemExtent, itemSpacing: $itemSpacing, mainAxisCount: $mainAxisCount)';
// }
