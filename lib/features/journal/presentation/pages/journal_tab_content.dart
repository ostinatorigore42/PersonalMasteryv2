import 'package:flutter/material.dart';

class JournalTabContent extends StatelessWidget {
  const JournalTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search journals
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter journals
            },
          ),
        ],
      ),
      body: _buildJournalEntries(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new journal entry
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJournalEntries(BuildContext context) {
    // Sample journal entries for demonstration
    final entries = [
      {
        'title': 'Morning Reflection',
        'date': 'May 18, 2023',
        'content': 'Today I am feeling optimistic about the upcoming product launch.',
        'mood': 'happy',
      },
      {
        'title': 'Lunch Break Thoughts',
        'date': 'May 17, 2023',
        'content': 'Had a productive morning meeting with the design team.',
        'mood': 'productive',
      },
      {
        'title': 'Evening Reflection',
        'date': 'May 16, 2023',
        'content': 'Wrapped up the day by completing the presentation.',
        'mood': 'tired',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _JournalEntryCard(
          title: entry['title'] as String,
          date: entry['date'] as String,
          content: entry['content'] as String,
          mood: entry['mood'] as String,
        );
      },
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final String title;
  final String date;
  final String content;
  final String mood;

  const _JournalEntryCard({
    required this.title,
    required this.date,
    required this.content,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    IconData moodIcon;
    Color moodColor;
    
    switch (mood) {
      case 'happy':
        moodIcon = Icons.sentiment_very_satisfied;
        moodColor = Colors.green;
        break;
      case 'productive':
        moodIcon = Icons.trending_up;
        moodColor = Colors.blue;
        break;
      case 'tired':
        moodIcon = Icons.sentiment_dissatisfied;
        moodColor = Colors.orange;
        break;
      default:
        moodIcon = Icons.sentiment_neutral;
        moodColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Open journal entry detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      moodIcon,
                      color: moodColor,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Show options menu
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(fontSize: 15),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}