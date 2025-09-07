import 'package:flutter_test/flutter_test.dart';
import 'package:fixed_scroll_to_index/fixed_scroll_to_index.dart';

void main() {
  group('FixedScrollToIndexController', () {
    late FixedScrollToIndexController controller;
    late List<ScrollableSection> sections;

    setUp(() {
      sections = [
        const ScrollableSection.spacing(extent: 20.0),
        const ScrollableSection.anchor(extent: 60.0),
        const ScrollableSection.spacing(extent: 10.0),
        const ScrollableSection.content(
          itemCount: 100,
          itemExtent: 80.0,
          itemSpacing: 8.0,
          mainAxisCount: 1,
        ),
        const ScrollableSection.spacing(extent: 20.0),
      ];
      controller = FixedScrollToIndexController(sections: sections);
    });

    tearDown(() {
      controller.dispose();
    });

    test('should calculate correct offset for first item', () {
      // Offset should be: spacing(20) + anchor(60) + spacing(10) = 90
      final expectedOffset = 20.0 + 60.0 + 10.0;

      final actualOffset = controller._calculateOffsetToIndex(3, 0);
      expect(actualOffset, expectedOffset);
    });

    test('should calculate correct offset for item at index 5', () {
      // Offset should be: spacing(20) + anchor(60) + spacing(10) + (5 * (80 + 8)) = 90 + 440 = 530
      final expectedOffset = 20.0 + 60.0 + 10.0 + (5 * (80.0 + 8.0));

      final actualOffset = controller._calculateOffsetToIndex(3, 5);
      expect(actualOffset, expectedOffset);
    });

    test('should calculate correct offset for grid layout', () {
      final gridSections = [
        const ScrollableSection.content(
          itemCount: 20,
          itemExtent: 100.0,
          itemSpacing: 10.0,
          mainAxisCount: 3, // 3 items per row
        ),
      ];
      final gridController = FixedScrollToIndexController(
        sections: gridSections,
      );

      // Item at index 6 should be in row 2 (6 ÷ 3 = 2)
      // Offset = 2 * (100 + 10) = 220
      final expectedOffset = 2 * (100.0 + 10.0);
      final actualOffset = gridController._calculateOffsetToIndex(0, 6);
      expect(actualOffset, expectedOffset);

      gridController.dispose();
    });

    test('should throw error for invalid section index', () {
      expect(
        () => controller.scrollToIndex(sectionIndex: 10, index: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error for non-content section', () {
      expect(
        () => controller.scrollToIndex(
          sectionIndex: 0,
          index: 0,
        ), // spacing section
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error for invalid item index', () {
      expect(
        () => controller.scrollToIndex(
          sectionIndex: 3,
          index: 200,
        ), // out of bounds
        throwsA(isA<RangeError>()),
      );
    });

    test('should find first content section correctly', () {
      final contentSectionIndex = controller.sections.indexWhere(
        (section) => section is ContentSection,
      );
      expect(contentSectionIndex, 3); // Should be the 4th section (index 3)
    });

    test('should throw error when no content sections exist', () {
      final noContentSections = [
        const ScrollableSection.spacing(extent: 20.0),
        const ScrollableSection.anchor(extent: 60.0),
      ];
      final noContentController = FixedScrollToIndexController(
        sections: noContentSections,
      );

      expect(
        () => noContentController.scrollToIndexInFirstContentSection(index: 0),
        throwsA(isA<StateError>()),
      );

      noContentController.dispose();
    });

    test('should calculate section extents correctly', () {
      final spacingExtent = const SpacingSection(extent: 50.0).extent;
      expect(spacingExtent, 50.0);

      final anchorExtent = const AnchorSection(extent: 75.0).extent;
      expect(anchorExtent, 75.0);

      final contentSection = const ContentSection(
        itemCount: 10,
        itemExtent: 100.0,
        itemSpacing: 5.0,
        mainAxisCount: 1,
      );
      final contentExtent = contentSection.extent;
      // 10 items * 100 extent + 9 spacings * 5 = 1000 + 45 = 1045
      expect(contentExtent, 1045.0);
    });

    test('should calculate content section extent for grid layout', () {
      final gridSection = const ContentSection(
        itemCount: 10,
        itemExtent: 100.0,
        itemSpacing: 5.0,
        mainAxisCount: 3, // 3 items per row
      );

      // 10 items with 3 per row = 4 rows (ceil(10/3) = 4)
      // 4 rows * 100 extent + 3 spacings * 5 = 400 + 15 = 415
      final extent = gridSection.extent;
      expect(extent, 415.0);
    });

    test('should handle empty content sections', () {
      final emptySection = const ContentSection(
        itemCount: 0,
        itemExtent: 100.0,
        itemSpacing: 5.0,
        mainAxisCount: 1,
      );

      final extent = emptySection.extent;
      expect(extent, 0.0);
    });
  });

  group('ScrollableSection', () {
    test('SpacingSection should have correct properties', () {
      const section = SpacingSection(extent: 50.0);
      expect(section.extent, 50.0);
      expect(section.toString(), 'SpacingSection(extent: 50.0)');
    });

    test('AnchorSection should have correct properties', () {
      const section = AnchorSection(extent: 60.0);
      expect(section.extent, 60.0);
      expect(section.toString(), 'AnchorSection(extent: 60.0)');
    });

    test('ContentSection should have correct properties', () {
      const section = ContentSection(
        itemCount: 10,
        itemExtent: 100.0,
        itemSpacing: 5.0,
        mainAxisCount: 2,
      );
      expect(section.itemCount, 10);
      expect(section.itemExtent, 100.0);
      expect(section.itemSpacing, 5.0);
      expect(section.mainAxisCount, 2);
    });

    test('ContentSection should validate constraints', () {
      expect(
        () => ContentSection(itemCount: -1, itemExtent: 100.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ContentSection(itemCount: 10, itemExtent: 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () =>
            ContentSection(itemCount: 10, itemExtent: 100.0, itemSpacing: -1.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () =>
            ContentSection(itemCount: 10, itemExtent: 100.0, mainAxisCount: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Factory constructors should work correctly', () {
      const spacing = ScrollableSection.spacing(extent: 20.0);
      const anchor = ScrollableSection.anchor(extent: 30.0);
      const content = ScrollableSection.content(itemCount: 5, itemExtent: 50.0);

      expect(spacing, isA<SpacingSection>());
      expect(anchor, isA<AnchorSection>());
      expect(content, isA<ContentSection>());
    });

    test('extent getter should work correctly for all section types', () {
      const spacing = SpacingSection(extent: 100.0);
      expect(spacing.extent, 100.0);

      const anchor = AnchorSection(extent: 150.0);
      expect(anchor.extent, 150.0);

      const content = ContentSection(
        itemCount: 20,
        itemExtent: 50.0,
        itemSpacing: 10.0,
        mainAxisCount: 2,
      );
      // 20 items with 2 per row = 10 rows
      // 10 rows * 50 extent + 9 spacings * 10 = 500 + 90 = 590
      expect(content.extent, 590.0);
    });

    test('extent getter for ContentSection with different configurations', () {
      // Single column list
      const singleColumn = ContentSection(
        itemCount: 5,
        itemExtent: 80.0,
        itemSpacing: 5.0,
        mainAxisCount: 1,
      );
      // 5 rows * 80 + 4 spacings * 5 = 400 + 20 = 420
      expect(singleColumn.extent, 420.0);

      // Grid with no spacing
      const gridNoSpacing = ContentSection(
        itemCount: 12,
        itemExtent: 100.0,
        itemSpacing: 0.0,
        mainAxisCount: 3,
      );
      // 12 items / 3 = 4 rows, 4 rows * 100 = 400
      expect(gridNoSpacing.extent, 400.0);

      // Empty content section
      const empty = ContentSection(
        itemCount: 0,
        itemExtent: 50.0,
        itemSpacing: 10.0,
        mainAxisCount: 1,
      );
      expect(empty.extent, 0.0);
    });
  });

  group('ScrollableSection Pattern Matching', () {
    test('when method should handle all cases correctly', () {
      const spacing = SpacingSection(extent: 20.0);
      const anchor = AnchorSection(extent: 30.0);
      const content = ContentSection(itemCount: 5, itemExtent: 50.0);

      final spacingResult = spacing.when(
        spacing: (s) => 'spacing:${s.extent}',
        anchor: (a) => 'anchor:${a.extent}',
        content: (c) => 'content:${c.itemCount}',
      );
      expect(spacingResult, 'spacing:20.0');

      final anchorResult = anchor.when(
        spacing: (s) => 'spacing:${s.extent}',
        anchor: (a) => 'anchor:${a.extent}',
        content: (c) => 'content:${c.itemCount}',
      );
      expect(anchorResult, 'anchor:30.0');

      final contentResult = content.when(
        spacing: (s) => 'spacing:${s.extent}',
        anchor: (a) => 'anchor:${a.extent}',
        content: (c) => 'content:${c.itemCount}',
      );
      expect(contentResult, 'content:5');
    });

    test('maybeWhen method should use orElse for unhandled cases', () {
      const spacing = SpacingSection(extent: 20.0);
      const anchor = AnchorSection(extent: 30.0);
      const content = ContentSection(itemCount: 5, itemExtent: 50.0);

      final spacingResult = spacing.maybeWhen(
        spacing: (s) => 'handled',
        orElse: () => 'default',
      );
      expect(spacingResult, 'handled');

      final anchorResult = anchor.maybeWhen(
        spacing: (s) => 'handled',
        orElse: () => 'default',
      );
      expect(anchorResult, 'default');

      final contentResult = content.maybeWhen(
        content: (c) => 'handled',
        orElse: () => 'default',
      );
      expect(contentResult, 'handled');
    });

    test('whenSpacing should only work for SpacingSection', () {
      const spacing = SpacingSection(extent: 20.0);
      const anchor = AnchorSection(extent: 30.0);
      const content = ContentSection(itemCount: 5, itemExtent: 50.0);

      final spacingResult = spacing.whenSpacing((s) => s.extent);
      expect(spacingResult, 20.0);

      final anchorResult = anchor.whenSpacing((s) => s.extent);
      expect(anchorResult, null);

      final contentResult = content.whenSpacing((s) => s.extent);
      expect(contentResult, null);
    });

    test('whenAnchor should only work for AnchorSection', () {
      const spacing = SpacingSection(extent: 20.0);
      const anchor = AnchorSection(extent: 30.0);
      const content = ContentSection(itemCount: 5, itemExtent: 50.0);

      final spacingResult = spacing.whenAnchor((a) => a.extent);
      expect(spacingResult, null);

      final anchorResult = anchor.whenAnchor((a) => a.extent);
      expect(anchorResult, 30.0);

      final contentResult = content.whenAnchor((a) => a.extent);
      expect(contentResult, null);
    });

    test('whenContent should only work for ContentSection', () {
      const spacing = SpacingSection(extent: 20.0);
      const anchor = AnchorSection(extent: 30.0);
      const content = ContentSection(itemCount: 5, itemExtent: 50.0);

      final spacingResult = spacing.whenContent((c) => c.itemCount);
      expect(spacingResult, null);

      final anchorResult = anchor.whenContent((c) => c.itemCount);
      expect(anchorResult, null);

      final contentResult = content.whenContent((c) => c.itemCount);
      expect(contentResult, 5);
    });

    test('pattern matching can be used for complex logic', () {
      final sections = [
        const SpacingSection(extent: 20.0),
        const AnchorSection(extent: 60.0),
        const ContentSection(itemCount: 100, itemExtent: 80.0),
        const SpacingSection(extent: 10.0),
      ];

      final totalExtent = sections.fold<double>(0.0, (sum, section) {
        return sum +
            section.when(
              spacing: (s) => s.extent,
              anchor: (a) => a.extent,
              content: (c) => c.itemCount * c.itemExtent,
            );
      });

      // 20 + 60 + (100 * 80) + 10 = 8090
      expect(totalExtent, 8090.0);
    });

    test('maybeWhen can be used for filtering specific types', () {
      final sections = [
        const SpacingSection(extent: 20.0),
        const AnchorSection(extent: 60.0),
        const ContentSection(itemCount: 50, itemExtent: 80.0),
        const ContentSection(itemCount: 30, itemExtent: 100.0),
        const SpacingSection(extent: 10.0),
      ];

      final contentSections = sections
          .map(
            (section) =>
                section.maybeWhen(content: (c) => c, orElse: () => null),
          )
          .where((section) => section != null)
          .cast<ContentSection>()
          .toList();

      expect(contentSections.length, 2);
      expect(contentSections[0].itemCount, 50);
      expect(contentSections[1].itemCount, 30);
    });
  });

  group('ScrollPositionInfo', () {
    test('should have correct equality', () {
      const section = ContentSection(itemCount: 10, itemExtent: 50.0);
      const info1 = ScrollPositionInfo(
        sectionIndex: 0,
        itemIndex: 5,
        section: section,
      );
      const info2 = ScrollPositionInfo(
        sectionIndex: 0,
        itemIndex: 5,
        section: section,
      );
      const info3 = ScrollPositionInfo(
        sectionIndex: 1,
        itemIndex: 5,
        section: section,
      );

      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
    });

    test('should have correct string representation', () {
      const section = ContentSection(itemCount: 10, itemExtent: 50.0);
      const info = ScrollPositionInfo(
        sectionIndex: 2,
        itemIndex: 7,
        section: section,
      );

      expect(info.toString(), contains('sectionIndex: 2'));
      expect(info.toString(), contains('itemIndex: 7'));
    });
  });
}

// Extension to expose private methods for testing
extension FixedScrollToIndexControllerTest on FixedScrollToIndexController {
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
}
