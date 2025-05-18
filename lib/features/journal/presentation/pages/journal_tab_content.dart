import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JournalTabContent extends StatefulWidget {
  const JournalTabContent({super.key});

  @override
  State<JournalTabContent> createState() => _JournalTabContentState();
}

class _JournalTabContentState extends State<JournalTabContent> {
  DateTime _selectedDate = DateTime.now();
  String _activeView = 'daily'; // daily, weekly, monthly
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _activeView = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'daily',
                child: Text('Daily View'),
              ),
              const PopupMenuItem(
                value: 'weekly',
                child: Text('Weekly View'),
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: Text('Monthly View'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search journals
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ),
            child: _DateSelector(
              selectedDate: _selectedDate,
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              viewType: _activeView,
            ),
          ),
          
          // Journal entries
          Expanded(
            child: _activeView == 'daily'
                ? _DailyJournalView(date: _selectedDate)
                : _activeView == 'weekly'
                    ? _WeeklyJournalView(startDate: _getStartOfWeek(_selectedDate))
                    : _MonthlyJournalView(month: _selectedDate),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createNewEntry(context);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  DateTime _getStartOfWeek(DateTime date) {
    // Go back to the previous Monday (or Sunday based on locale)
    final firstDayOfWeek = date.weekday == 1 ? date : date.subtract(Duration(days: date.weekday - 1));
    return DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
  }
  
  void _createNewEntry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _JournalEntryScreen(
          date: _selectedDate,
          onSave: (entry) {
            // Save entry and refresh
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final String viewType;
  
  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
    required this.viewType,
  });
  
  @override
  Widget build(BuildContext context) {
    String displayText;
    
    if (viewType == 'daily') {
      // For daily view, show specific date
      displayText = DateFormat.yMMMMd().format(selectedDate);
    } else if (viewType == 'weekly') {
      // For weekly view, show week range
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      displayText = '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)}';
    } else {
      // For monthly view, show month and year
      displayText = DateFormat.yMMMM().format(selectedDate);
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (viewType == 'daily') {
              onDateChanged(selectedDate.subtract(const Duration(days: 1)));
            } else if (viewType == 'weekly') {
              onDateChanged(selectedDate.subtract(const Duration(days: 7)));
            } else {
              onDateChanged(DateTime(selectedDate.year, selectedDate.month - 1, 1));
            }
          },
        ),
        GestureDetector(
          onTap: () async {
            // Only show date picker for daily view
            if (viewType == 'daily') {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              
              if (pickedDate != null) {
                onDateChanged(pickedDate);
              }
            }
          },
          child: Text(
            displayText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            if (viewType == 'daily') {
              onDateChanged(selectedDate.add(const Duration(days: 1)));
            } else if (viewType == 'weekly') {
              onDateChanged(selectedDate.add(const Duration(days: 7)));
            } else {
              onDateChanged(DateTime(selectedDate.year, selectedDate.month + 1, 1));
            }
          },
        ),
      ],
    );
  }
}

class _DailyJournalView extends StatelessWidget {
  final DateTime date;
  
  const _DailyJournalView({
    required this.date,
  });
  
  @override
  Widget build(BuildContext context) {
    // Mock data for journal entries
    final journalEntries = [
      {
        'id': '1',
        'time': '08:30 AM',
        'title': 'Morning Reflection',
        'content': 'Today I'm feeling optimistic about the upcoming product launch. The team has been working hard, and I think we're in a good position.',
        'mood': 'happy',
        'tags': ['work', 'reflection'],
      },
      {
        'id': '2',
        'time': '01:15 PM',
        'title': 'Lunch Break Thoughts',
        'content': 'Had a productive morning meeting with the design team. We finalized the UI for the new feature and addressed all the feedback from user testing.',
        'mood': 'productive',
        'tags': ['work', 'design'],
      },
      {
        'id': '3',
        'time': '06:30 PM',
        'title': 'Evening Reflection',
        'content': 'Wrapped up the day by completing the presentation for tomorrow's client meeting. I'm satisfied with the progress but still need to review a few slides.',
        'mood': 'tired',
        'tags': ['work', 'client'],
      },
    ];
    
    if (journalEntries.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: journalEntries.length,
      itemBuilder: (context, index) {
        final entry = journalEntries[index];
        return _JournalEntryCard(
          time: entry['time'] as String,
          title: entry['title'] as String,
          content: entry['content'] as String,
          mood: entry['mood'] as String,
          tags: entry['tags'] as List<String>,
          onTap: () {
            // Navigate to journal entry details
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    // Is it today, tomorrow or yesterday?
    String dateDescription;
    final today = DateTime.now();
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      dateDescription = 'today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      dateDescription = 'tomorrow';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      dateDescription = 'yesterday';
    } else {
      dateDescription = 'this day';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Journal Entries',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing about $dateDescription',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Create new entry
            },
            icon: const Icon(Icons.add),
            label: const Text('New Entry'),
          ),
        ],
      ),
    );
  }
}

class _WeeklyJournalView extends StatelessWidget {
  final DateTime startDate;
  
  const _WeeklyJournalView({
    required this.startDate,
  });
  
  @override
  Widget build(BuildContext context) {
    // Create a list of 7 days starting from startDate
    final weekDays = List<DateTime>.generate(
      7,
      (index) => startDate.add(Duration(days: index)),
    );
    
    // Count entries per day (mock data)
    final entriesPerDay = {
      '${startDate.year}-${startDate.month}-${startDate.day}': 3,
      '${startDate.year}-${startDate.month}-${startDate.day + 2}': 1,
      '${startDate.year}-${startDate.month}-${startDate.day + 4}': 2,
    };
    
    return Column(
      children: [
        // Week day selectors
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekDays.map((day) {
              final isToday = _isToday(day);
              final dayKey = '${day.year}-${day.month}-${day.day}';
              final hasEntries = entriesPerDay.containsKey(dayKey);
              
              return GestureDetector(
                onTap: () {
                  // Navigate to this day
                },
                child: Column(
                  children: [
                    Text(
                      DateFormat('E').format(day),
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : hasEntries
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                        border: Border.all(
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : hasEntries
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : hasEntries
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                            fontWeight: hasEntries ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasEntries)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        
        const Divider(height: 1),
        
        // Week summary
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Week Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _WeekStatCard(
                      title: 'Entries',
                      value: '6',
                      icon: Icons.book,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _WeekStatCard(
                      title: 'Avg. Mood',
                      value: 'Positive',
                      icon: Icons.sentiment_satisfied_alt,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _WeekStatCard(
                      title: 'Tags',
                      value: '12',
                      icon: Icons.tag,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Top Tags This Week',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TopTagChip(label: 'work', count: 5),
                    _TopTagChip(label: 'meeting', count: 3),
                    _TopTagChip(label: 'design', count: 2),
                    _TopTagChip(label: 'client', count: 2),
                    _TopTagChip(label: 'reflection', count: 2),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Entries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _RecentEntryItem(
                        title: 'Project Planning Session',
                        date: 'Friday, May 12',
                        mood: 'productive',
                        onTap: () {
                          // Navigate to entry
                        },
                      ),
                      _RecentEntryItem(
                        title: 'Client Feedback Review',
                        date: 'Wednesday, May 10',
                        mood: 'satisfied',
                        onTap: () {
                          // Navigate to entry
                        },
                      ),
                      _RecentEntryItem(
                        title: 'Team Building Activity',
                        date: 'Monday, May 8',
                        mood: 'happy',
                        onTap: () {
                          // Navigate to entry
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _WeekStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _WeekStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTagChip extends StatelessWidget {
  final String label;
  final int count;

  const _TopTagChip({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: TextStyle(
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEntryItem extends StatelessWidget {
  final String title;
  final String date;
  final String mood;
  final VoidCallback onTap;

  const _RecentEntryItem({
    required this.title,
    required this.date,
    required this.mood,
    required this.onTap,
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
      case 'satisfied':
        moodIcon = Icons.sentiment_satisfied;
        moodColor = Colors.amber;
        break;
      default:
        moodIcon = Icons.sentiment_neutral;
        moodColor = Colors.grey;
    }

    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      leading: CircleAvatar(
        backgroundColor: moodColor.withOpacity(0.2),
        child: Icon(moodIcon, color: moodColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _MonthlyJournalView extends StatelessWidget {
  final DateTime month;
  
  const _MonthlyJournalView({
    required this.month,
  });
  
  @override
  Widget build(BuildContext context) {
    // Mock data for entries per day in this month
    final entriesPerDay = {
      5: 2,
      8: 1,
      12: 3,
      15: 1,
      21: 2,
      22: 1,
      25: 1,
      28: 2,
    };
    
    // Calculate first day of month and the number of days in month
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    
    // Get weekday of first day (0 = Monday, 6 = Sunday in DateTime)
    int firstWeekday = firstDay.weekday - 1; // Convert to 0-indexed (0 = Monday)
    
    // Calculate number of rows needed (including partial first and last weeks)
    final numRows = ((firstWeekday + daysInMonth) / 7).ceil();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Calendar grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: numRows * 7,
              itemBuilder: (context, index) {
                // Calculate the day number (1-based) or 0 if out of month bounds
                final weekday = index % 7;
                final row = index ~/ 7;
                final day = row * 7 + weekday + 1 - firstWeekday;
                
                // Check if day is within the month
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink(); // Empty cell
                }
                
                final isToday = _isToday(DateTime(month.year, month.month, day));
                final hasEntries = entriesPerDay.containsKey(day);
                final entryCount = entriesPerDay[day] ?? 0;
                
                return GestureDetector(
                  onTap: () {
                    // Navigate to day view
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : hasEntries
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                      border: Border.all(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : hasEntries
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            color: isToday ? Colors.white : null,
                            fontWeight: hasEntries || isToday ? FontWeight.bold : null,
                          ),
                        ),
                        if (hasEntries)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isToday
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Month summary
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Month Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _WeekStatCard(
                    title: 'Total Entries',
                    value: entriesPerDay.values.reduce((a, b) => a + b).toString(),
                    icon: Icons.book,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _WeekStatCard(
                    title: 'Writing Days',
                    value: entriesPerDay.length.toString(),
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _WeekStatCard(
                    title: 'Streak',
                    value: '3',
                    icon: Icons.local_fire_department,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _JournalEntryCard extends StatelessWidget {
  final String time;
  final String title;
  final String content;
  final String mood;
  final List<String> tags;
  final VoidCallback onTap;

  const _JournalEntryCard({
    required this.time,
    required this.title,
    required this.content,
    required this.mood,
    required this.tags,
    required this.onTap,
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
        onTap: onTap,
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
                          time,
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
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => _TagChip(tag)).toList(),
                ),
              ],
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
        borderRadius: BorderRadius.circular(16),
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

class _JournalEntryScreen extends StatefulWidget {
  final DateTime date;
  final Function(Map<String, dynamic>) onSave;
  
  const _JournalEntryScreen({
    required this.date,
    required this.onSave,
  });

  @override
  State<_JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<_JournalEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _selectedTags = [];
  String _selectedMood = 'neutral';
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Journal Entry'),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMd().format(widget.date),
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mood selector
            const Text(
              'How are you feeling?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MoodOption(
                  mood: 'happy',
                  icon: Icons.sentiment_very_satisfied,
                  color: Colors.green,
                  label: 'Happy',
                  isSelected: _selectedMood == 'happy',
                  onTap: () => setState(() => _selectedMood = 'happy'),
                ),
                _MoodOption(
                  mood: 'productive',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                  label: 'Productive',
                  isSelected: _selectedMood == 'productive',
                  onTap: () => setState(() => _selectedMood = 'productive'),
                ),
                _MoodOption(
                  mood: 'neutral',
                  icon: Icons.sentiment_neutral,
                  color: Colors.grey,
                  label: 'Neutral',
                  isSelected: _selectedMood == 'neutral',
                  onTap: () => setState(() => _selectedMood = 'neutral'),
                ),
                _MoodOption(
                  mood: 'tired',
                  icon: Icons.sentiment_dissatisfied,
                  color: Colors.orange,
                  label: 'Tired',
                  isSelected: _selectedMood == 'tired',
                  onTap: () => setState(() => _selectedMood = 'tired'),
                ),
                _MoodOption(
                  mood: 'stressed',
                  icon: Icons.sentiment_very_dissatisfied,
                  color: Colors.red,
                  label: 'Stressed',
                  isSelected: _selectedMood == 'stressed',
                  onTap: () => setState(() => _selectedMood = 'stressed'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              minLines: 10,
            ),
            const SizedBox(height: 24),
            
            // Tags
            Row(
              children: [
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedTags.remove(tag);
                        });
                      },
                    )).toList(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddTagDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddTagDialog() {
    // Common tags
    final commonTags = ['work', 'personal', 'health', 'learning', 'meeting', 'ideas', 'goals'];
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Enter a tag',
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _selectedTags.add(value.toLowerCase());
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Common Tags',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: commonTags.map((tag) => ActionChip(
                label: Text(tag),
                onPressed: () {
                  setState(() {
                    if (!_selectedTags.contains(tag)) {
                      _selectedTags.add(tag);
                    }
                  });
                  Navigator.of(context).pop();
                },
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  _selectedTags.add(textController.text.toLowerCase());
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _saveEntry() {
    final entry = {
      'title': _titleController.text.isEmpty ? 'Untitled Entry' : _titleController.text,
      'content': _contentController.text,
      'mood': _selectedMood,
      'tags': _selectedTags,
      'date': widget.date.toIso8601String(),
      'time': DateFormat.jm().format(DateTime.now()),
    };
    
    widget.onSave(entry);
  }
}

class _MoodOption extends StatelessWidget {
  final String mood;
  final IconData icon;
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodOption({
    required this.mood,
    required this.icon,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : null,
              color: isSelected ? color : null,
            ),
          ),
        ],
      ),
    );
  }
}