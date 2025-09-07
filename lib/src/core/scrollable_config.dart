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

double _defaultItemSpacingBuilder(int itemIndex) => 0.0;

final class ContentSection extends ScrollableExtent with EquatableMixin {
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

  @override
  List<Object?> get props => [
    sectionHeader,
    itemCount,
    itemExtentBuilder,
    itemSpacingBuilder,
    mainAxisCount,
  ];
}

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
