import 'package:fixed_scroll_to_index/fixed_scroll_to_index.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyGridApp());
}

final class Category {
  final String name;
  final List<String> items;

  Category(this.name, this.items);
}

final categories = [
  Category('Fruits', List.generate(20, (i) => 'Fruit ${i + 1}')),
  Category('Vegetables', List.generate(10, (i) => 'Vegetable ${i + 1}')),
  Category('Dairy', List.generate(5, (i) => 'Dairy ${i + 1}')),
  Category('Meat', List.generate(7, (i) => 'Meat ${i + 1}')),
  Category('Bakery', List.generate(12, (i) => 'Bakery ${i + 1}')),
  Category('Beverages', List.generate(8, (i) => 'Beverage ${i + 1}')),
  Category('Snacks', List.generate(15, (i) => 'Snack ${i + 1}')),
  Category('Frozen Foods', List.generate(6, (i) => 'Frozen Food ${i + 1}')),
  Category('Condiments', List.generate(9, (i) => 'Condiment ${i + 1}')),
  Category('Cereals', List.generate(4, (i) => 'Cereal ${i + 1}')),
];

class MyGridApp extends StatelessWidget {
  const MyGridApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixedScrollToIndex Grid Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _GridDemoPage(),
    );
  }
}

class _GridDemoPage extends StatefulWidget {
  const _GridDemoPage();

  @override
  State<_GridDemoPage> createState() => _GridDemoPageState();
}

class _GridDemoPageState extends State<_GridDemoPage> {
  // Use the categories list defined at the top for groups and counts
  static const double _itemHeight =
      120.0; // visual height used to compute aspect
  static const double _groupHeaderHeight = 56.0;
  static const double _spacing = 8.0;
  static const int _crossAxisCount = 2;

  late final FixedScrollToIndexController _controller =
      FixedScrollToIndexController(
        sections: [
          for (int c = 0; c < categories.length; c++) ...[
            ScrollableSection.spacing(extent: _groupHeaderHeight),
            ScrollableSection.content(
              itemCount: categories[c].items.length,
              itemExtent: _itemHeight,
              itemSpacing: _spacing,
              mainAxisCount: _crossAxisCount,
            ),
          ],
        ],
      );

  int _currentTarget = 0;

  @override
  void initState() {
    super.initState();
    // _controller.addIndexListener((i) {
    //   if (mounted) setState(() => _currentTarget = i);
    // });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goTo(int groupIndex) async {
    setState(() => _currentTarget = groupIndex);
    await _controller.scrollToSection(
      // sections are added as: spacing(header), content => content index = groupIndex*2 + 1
      sectionIndex: groupIndex * 2 + 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CustomScrollView + SliverGrid'),
        actions: [
          IconButton(
            tooltip: 'Prev group',
            onPressed: () {
              final int prev = (_currentTarget - 1).clamp(
                0,
                categories.length - 1,
              );
              _goTo(prev);
            },
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton(
            tooltip: 'Next group',
            onPressed: () {
              final int next = (_currentTarget + 1).clamp(
                0,
                categories.length - 1,
              );
              _goTo(next);
            },
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _controller,
        slivers: [
          for (int c = 0; c < categories.length; c++) ...[
            SliverToBoxAdapter(
              child: _GroupHeader(index: c, height: _groupHeaderHeight),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  mainAxisSpacing: _spacing,
                  crossAxisSpacing: _spacing,
                  mainAxisExtent: _itemHeight,
                  // childAspectRatio: childAspect,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  final count = categories[c].items.length;
                  if (i >= count) return null;
                  return _GridItem(group: c, index: i);
                }, childCount: categories[c].items.length),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
      bottomNavigationBar: _GroupBar(
        groups: categories.length,
        current: _currentTarget,
        onTap: _goTo,
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.index, required this.height});
  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.teal.withOpacity(0.1 * ((index % 7) + 3)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        categories[index].name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({required this.group, required this.index});
  final int group;
  final int index;

  @override
  Widget build(BuildContext context) {
    final label = categories[group].items[index];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.teal.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _GroupBar extends StatelessWidget {
  const _GroupBar({
    required this.groups,
    required this.current,
    required this.onTap,
  });
  final int groups;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < groups; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    selected: current == i,
                    label: Text(categories[i].name),
                    onSelected: (_) => onTap(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
