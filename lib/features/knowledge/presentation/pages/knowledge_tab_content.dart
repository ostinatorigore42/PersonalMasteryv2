import 'package:flutter/material.dart';

class KnowledgeTabContent extends StatefulWidget {
  const KnowledgeTabContent({super.key});

  @override
  State<KnowledgeTabContent> createState() => _KnowledgeTabContentState();
}

class _KnowledgeTabContentState extends State<KnowledgeTabContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search knowledge base...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16),
                autofocus: true,
                onSubmitted: (value) {
                  // Handle search
                  setState(() {
                    _isSearching = false;
                  });
                },
              )
            : const Text('Knowledge Base'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notes'),
            Tab(text: 'References'),
            Tab(text: 'Principles'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NotesTab(),
          _ReferencesTab(),
          _PrinciplesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContentDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showAddContentDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add to Knowledge Base',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _AddOption(
                icon: Icons.note_add,
                title: 'Create Note',
                description: 'Add a new note with rich text formatting',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to create note page
                },
              ),
              const SizedBox(height: 16),
              _AddOption(
                icon: Icons.link,
                title: 'Add Reference',
                description: 'Save a link, article, or resource',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add reference page
                },
              ),
              const SizedBox(height: 16),
              _AddOption(
                icon: Icons.lightbulb,
                title: 'Define Principle',
                description: 'Document key principles or values',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to add principle page
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    // Mock notes data
    final notes = [
      {
        'id': '1',
        'title': 'Design System Guidelines',
        'content': 'Key principles for maintaining consistency across platforms...',
        'category': 'Design',
        'categoryColor': Colors.purple,
        'date': 'May 15, 2023',
        'tags': ['design', 'guidelines', 'ui'],
      },
      {
        'id': '2',
        'title': 'Meeting Notes: Product Team',
        'content': 'Discussion about upcoming features and roadmap priorities...',
        'category': 'Work',
        'categoryColor': Colors.blue,
        'date': 'May 12, 2023',
        'tags': ['meeting', 'product', 'planning'],
      },
      {
        'id': '3',
        'title': 'Book Summary: Atomic Habits',
        'content': 'Key takeaways and actionable insights from James Clear\'s book...',
        'category': 'Learning',
        'categoryColor': Colors.green,
        'date': 'May 10, 2023',
        'tags': ['books', 'habits', 'productivity'],
      },
    ];
    
    if (notes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.note_outlined,
        title: 'No Notes Yet',
        message: 'Start capturing your thoughts and ideas',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteCard(
          title: note['title'] as String,
          content: note['content'] as String,
          category: note['category'] as String,
          categoryColor: note['categoryColor'] as Color,
          date: note['date'] as String,
          tags: note['tags'] as List<String>,
          onTap: () {
            // Navigate to note detail
          },
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String title;
  final String content;
  final String category;
  final Color categoryColor;
  final String date;
  final List<String> tags;
  final VoidCallback onTap;

  const _NoteCard({
    required this.title,
    required this.content,
    required this.category,
    required this.categoryColor,
    required this.date,
    required this.tags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) => _TagChip(tag)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip(this.tag);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReferencesTab extends StatelessWidget {
  const _ReferencesTab();

  @override
  Widget build(BuildContext context) {
    // Mock references data
    final references = [
      {
        'id': '1',
        'title': 'The Ultimate Guide to Design Systems',
        'source': 'UX Collective',
        'url': 'https://uxdesign.cc/the-ultimate-guide-to-design-systems-1693ccc2b6a1',
        'type': 'Article',
        'date': 'May 18, 2023',
        'tags': ['design', 'systems', 'ui'],
      },
      {
        'id': '2',
        'title': 'Building a Second Brain: A Proven Method',
        'source': 'Tiago Forte',
        'url': 'https://www.buildingasecondbrain.com/',
        'type': 'Book',
        'date': 'May 15, 2023',
        'tags': ['productivity', 'knowledge', 'notes'],
      },
      {
        'id': '3',
        'title': 'How to Take Smart Notes',
        'source': 'YouTube',
        'url': 'https://www.youtube.com/watch?v=nPOI4f7yCag',
        'type': 'Video',
        'date': 'May 10, 2023',
        'tags': ['notes', 'learning', 'zettelkasten'],
      },
    ];
    
    if (references.isEmpty) {
      return _buildEmptyState(
        icon: Icons.link_outlined,
        title: 'No References Yet',
        message: 'Save links, articles, and other resources',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: references.length,
      itemBuilder: (context, index) {
        final reference = references[index];
        return _ReferenceCard(
          title: reference['title'] as String,
          source: reference['source'] as String,
          type: reference['type'] as String,
          date: reference['date'] as String,
          tags: reference['tags'] as List<String>,
          onTap: () {
            // Navigate to reference detail or open URL
          },
        );
      },
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  final String title;
  final String source;
  final String type;
  final String date;
  final List<String> tags;
  final VoidCallback onTap;

  const _ReferenceCard({
    required this.title,
    required this.source,
    required this.type,
    required this.date,
    required this.tags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData typeIcon;
    Color typeColor;
    
    switch (type) {
      case 'Article':
        typeIcon = Icons.article;
        typeColor = Colors.blue;
        break;
      case 'Book':
        typeIcon = Icons.book;
        typeColor = Colors.purple;
        break;
      case 'Video':
        typeIcon = Icons.video_library;
        typeColor = Colors.red;
        break;
      default:
        typeIcon = Icons.link;
        typeColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          source,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((tag) => _TagChip(tag)).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrinciplesTab extends StatelessWidget {
  const _PrinciplesTab();

  @override
  Widget build(BuildContext context) {
    // Mock principles data
    final principles = [
      {
        'id': '1',
        'title': 'Focus on User Outcomes',
        'description': 'Every feature should address a specific user need and contribute to measurable outcomes',
        'category': 'Design',
        'categoryColor': Colors.blue,
      },
      {
        'id': '2',
        'title': 'Deep Work Before Shallow Work',
        'description': 'Reserve mornings for focused creative work and afternoons for meetings and communication',
        'category': 'Productivity',
        'categoryColor': Colors.orange,
      },
      {
        'id': '3',
        'title': 'Test Assumptions Early',
        'description': 'Identify and test critical assumptions before committing significant resources',
        'category': 'Strategy',
        'categoryColor': Colors.green,
      },
    ];
    
    if (principles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'No Principles Yet',
        message: 'Define core values and guiding principles',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: principles.length,
      itemBuilder: (context, index) {
        final principle = principles[index];
        return _PrincipleCard(
          title: principle['title'] as String,
          description: principle['description'] as String,
          category: principle['category'] as String,
          categoryColor: principle['categoryColor'] as Color,
          onTap: () {
            // Navigate to principle detail
          },
        );
      },
    );
  }
}

class _PrincipleCard extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final Color categoryColor;
  final VoidCallback onTap;

  const _PrincipleCard({
    required this.title,
    required this.description,
    required this.category,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      // Show actions menu
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String message,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 72,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}