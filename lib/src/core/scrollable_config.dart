import 'package:equatable/equatable.dart';

import 'scrollable_extent.dart';

final class AnchorSection extends ScrollableExtent with EquatableMixin {
  const AnchorSection({this.extent = 0.0});

  @override
  final double extent;

  @override
  String toString() => 'AnchorSection(extent: $extent)';

  @override
  List<Object?> get props => [extent];
}

typedef ContentSectionExtentBuilder = double Function(int itemIndex);

sealed class ContentSection extends ScrollableExtent with EquatableMixin {
  final double sectionHeader;
  final int itemCount;
  final int mainAxisCount;

  const ContentSection({
    this.sectionHeader = 0.0,
    required this.itemCount,
    this.mainAxisCount = 0,
  }) : assert(sectionHeader >= 0, 'Section header must be non-negative'),
       assert(itemCount >= 0, 'Item count must be non-negative'),
       assert(mainAxisCount > 0, 'Main axis count must be positive');
  @override
  List<Object?> get props => [sectionHeader, itemCount, mainAxisCount];

  double asFixedItemExtent();
  double asFixedItemSpacing();
}

final class FixedContentSection extends ContentSection with EquatableMixin {
  final double itemSpacing;
  final double itemExtent;

  FixedContentSection({
    super.sectionHeader,
    required super.itemCount,
    super.mainAxisCount,
    required this.itemSpacing,
    required this.itemExtent,
  });
  @override
  double get extent {
    if (itemCount == 0) return 0;

    // Calculate number of rows needed
    final rows = (itemCount / mainAxisCount).ceil();

    final totalItemExtent = itemExtent * rows;
    final totalSpacing = itemSpacing * (rows - 1);
    return sectionHeader + totalItemExtent + totalSpacing;
  }

  @override
  List<Object?> get props => [...super.props, itemSpacing, itemExtent];

  @override
  double asFixedItemExtent() => itemExtent;

  @override
  double asFixedItemSpacing() => itemSpacing;
}

// double _defaultItemSpacingBuilder(int itemIndex) => 0.0;

// final class VariableContentSection extends ContentSection with EquatableMixin {
//   final ContentSectionExtentBuilder itemSpacingBuilder;
//   final ContentSectionExtentBuilder itemExtentBuilder;

//   VariableContentSection({
//     super.sectionHeader,
//     required super.itemCount,
//     super.mainAxisCount,
//     required this.itemExtentBuilder,
//     this.itemSpacingBuilder = _defaultItemSpacingBuilder,
//   }) : assert(
//          itemCount == 0 || itemExtentBuilder(0) > 0,
//          'Item extent must be positive',
//        ),
//        assert(
//          itemCount == 0 || itemSpacingBuilder(0) >= 0,
//          'Item spacing must be non-negative',
//        );

//   @override
//   double get extent {
//     if (itemCount == 0) return sectionHeader;

//     // Calculate number of rows
//     final rows = (itemCount / mainAxisCount).ceil();

//     double totalItemExtent = 0.0;
//     double totalSpacing = 0.0;

//     for (int row = 0; row < rows; row++) {
//       // For each row, find the max item extent and spacing in that row
//       double maxItemExtent = 0.0;
//       double maxSpacing = 0.0;

//       for (int col = 0; col < mainAxisCount; col++) {
//         final itemIndex = row * mainAxisCount + col;
//         if (itemIndex >= itemCount) break;

//         final itemExtent = itemExtentBuilder(itemIndex);
//         final itemSpacing = itemSpacingBuilder(itemIndex);

//         if (itemExtent > maxItemExtent) {
//           maxItemExtent = itemExtent;
//         }
//         if (itemSpacing > maxSpacing) {
//           maxSpacing = itemSpacing;
//         }
//       }

//       totalItemExtent += maxItemExtent;
//       if (row < rows - 1) {
//         totalSpacing += maxSpacing;
//       }
//     }

//     return sectionHeader + totalItemExtent + totalSpacing;
//   }

//   @override
//   List<Object?> get props => [
//     ...super.props,
//     itemExtentBuilder,
//     itemSpacingBuilder,
//   ];

//   @override
//   double asFixedItemExtent() => itemExtentBuilder(0);

//   @override
//   double asFixedItemSpacing() => itemSpacingBuilder(0);
// }

// final class ContentSection extends ScrollableExtent with EquatableMixin {
//   final double sectionHeader;
//   final int itemCount;
//   final ContentSectionExtentBuilder itemSpacingBuilder;
//   final ContentSectionExtentBuilder itemExtentBuilder;
//   final int mainAxisCount;

//   ContentSection({
//     this.sectionHeader = 0.0,
//     required this.itemCount,
//     required this.itemExtentBuilder,
//     this.itemSpacingBuilder = _defaultItemSpacingBuilder,
//     this.mainAxisCount = 1,
//   }) : assert(sectionHeader >= 0, 'Section header must be non-negative'),
//        assert(itemCount >= 0, 'Item count must be non-negative'),
//        // Validate builder return values when there are items.
//        assert(
//          itemCount == 0 || itemExtentBuilder(0) > 0,
//          'Item extent must be positive',
//        ),
//        assert(
//          itemCount == 0 || itemSpacingBuilder(0) >= 0,
//          'Item spacing must be non-negative',
//        ),
//        assert(mainAxisCount > 0, 'Main axis count must be positive');

//   @override
//   double get extent {
//     if (itemCount == 0) return sectionHeader;

//     // Calculate number of rows
//     final rows = (itemCount / mainAxisCount).ceil();

//     double totalItemExtent = 0.0;
//     double totalSpacing = 0.0;

//     for (int row = 0; row < rows; row++) {
//       // For each row, find the max item extent and spacing in that row
//       double maxItemExtent = 0.0;
//       double maxSpacing = 0.0;

//       for (int col = 0; col < mainAxisCount; col++) {
//         final itemIndex = row * mainAxisCount + col;
//         if (itemIndex >= itemCount) break;

//         final itemExtent = itemExtentBuilder(itemIndex);
//         final itemSpacing = itemSpacingBuilder(itemIndex);

//         if (itemExtent > maxItemExtent) {
//           maxItemExtent = itemExtent;
//         }
//         if (itemSpacing > maxSpacing) {
//           maxSpacing = itemSpacing;
//         }
//       }

//       totalItemExtent += maxItemExtent;
//       if (row < rows - 1) {
//         totalSpacing += maxSpacing;
//       }
//     }

//     return sectionHeader + totalItemExtent + totalSpacing;
//   }

//   @override
//   List<Object?> get props => [
//     sectionHeader,
//     itemCount,
//     itemExtentBuilder,
//     itemSpacingBuilder,
//     mainAxisCount,
//   ];
// }

final class ScrollableConfig extends Equatable {
  const ScrollableConfig({
    this.anchor = const AnchorSection(),
    required this.sections,
  });

  final AnchorSection anchor;
  final List<ContentSection> sections;

  @override
  String toString() => 'ScrollableConfig(anchor: $anchor, sections: $sections)';

  @override
  List<Object?> get props => [anchor, sections];
}
