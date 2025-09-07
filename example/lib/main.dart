import 'package:flutter/material.dart';
import 'package:fixed_scroll_to_index/fixed_scroll_to_index.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixed Scroll To Index Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Fixed Scroll To Index Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late FixedScrollToIndexController _controller;
  late TabController _tabController;
  int _currentIndex = 0;

  // Sample data for different sections
  final List<String> categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Sports',
  ];
  final Map<String, List<String>> categoryItems = {
    'Electronics': List.generate(20, (index) => 'Electronic Item ${index + 1}'),
    'Clothing': List.generate(15, (index) => 'Clothing Item ${index + 1}'),
    'Books': List.generate(25, (index) => 'Book ${index + 1}'),
    'Sports': List.generate(18, (index) => 'Sports Item ${index + 1}'),
  };

  @override
  void initState() {
    super.initState();

    // Initialize TabController
    _tabController = TabController(length: categories.length, vsync: this);

    // Create the ScrollableConfig with sections
    final config = ScrollableConfig(
      sections: categories.map((category) {
        final items = categoryItems[category]!;
        return ContentSection(
          sectionHeader: 60.0, // Height for section title
          itemCount: items.length,
          mainAxisCount: 2, // 2 columns grid
          itemExtentBuilder: (index) => 120.0, // Fixed item height
          itemSpacingBuilder: (index) => 8.0, // Spacing between rows
        );
      }).toList(),
    );

    _controller = FixedScrollToIndexController(config: config);

    // Listen for index changes from scroll controller
    _controller.addIndexListener((int index) {
      if (index != _currentIndex && index >= 0 && index < categories.length) {
        setState(() {
          _currentIndex = index;
        });
        // Update tab controller without triggering scroll
        _tabController.animateTo(index);
      }
    });

    // Listen for tab changes to scroll to sections
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _scrollToCategory(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToCategory(int categoryIndex) {
    // Scroll to the beginning of the selected category section
    _controller.scrollToSection(
      sectionIndex: categoryIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        children: [
          // TabBar for category navigation
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: categories
                  .map(
                    (category) => Tab(
                      icon: Icon(_getIconForCategory(category)),
                      text: category,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(),

          // Debug info showing current section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Text(
              'Current Section: ${_currentIndex + 1}/${categories.length} - ${categories[_currentIndex]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Main scrollable content
          Expanded(
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                // Build slivers for each category section
                for (
                  int sectionIndex = 0;
                  sectionIndex < categories.length;
                  sectionIndex++
                ) ...[
                  // Section header
                  SliverToBoxAdapter(
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.all(16),
                      color: _currentIndex == sectionIndex
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey[100],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getIconForCategory(categories[sectionIndex]),
                                color: _currentIndex == sectionIndex
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categories[sectionIndex],
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: _currentIndex == sectionIndex
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                      fontWeight: _currentIndex == sectionIndex
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                              if (_currentIndex == sectionIndex) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Scroll to this section
                              _scrollToCategory(sectionIndex);
                            },
                            child: const Text('Go to Section'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Grid content for this section
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          mainAxisExtent: 120.0,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final items = categoryItems[categories[sectionIndex]]!;
                        if (index >= items.length) return null;

                        return Card(
                          margin: const EdgeInsets.all(4),
                          child: InkWell(
                            onTap: () {
                              // Show item details
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tapped: ${items[index]}'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getIconForCategory(
                                      categories[sectionIndex],
                                    ),
                                    size: 32,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    items[index],
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Section: $sectionIndex, Item: $index',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount:
                          categoryItems[categories[sectionIndex]]!.length,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),

      // Floating action button with quick navigation
      floatingActionButton: PopupMenuButton<String>(
        child: const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.navigation),
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'top', child: Text('Go to Top')),
          for (int i = 0; i < categories.length; i++)
            PopupMenuItem(
              value: 'category_$i',
              child: Text('Go to ${categories[i]}'),
            ),
          const PopupMenuItem(value: 'bottom', child: Text('Go to Bottom')),
        ],
        onSelected: (value) {
          if (value == 'top') {
            _controller.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else if (value == 'bottom') {
            _controller.animateTo(
              _controller.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else if (value.startsWith('category_')) {
            final categoryIndex = int.parse(value.split('_')[1]);
            _scrollToCategory(categoryIndex);
          }
        },
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices;
      case 'Clothing':
        return Icons.checkroom;
      case 'Books':
        return Icons.book;
      case 'Sports':
        return Icons.sports_basketball;
      default:
        return Icons.category;
    }
  }
}
