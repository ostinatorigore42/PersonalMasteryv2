import 'package:flutter/material.dart';

class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              // Navigate to profile page
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Daily focus section
            const _DailyFocusCard(),
            const SizedBox(height: 24),
            
            // Statistics section
            const _DailyStatsSection(),
            const SizedBox(height: 24),
            
            // Today's tasks section
            _SectionHeader(
              title: 'Today\'s Tasks',
              actionText: 'See all',
              onActionTap: () {
                // Navigate to tasks page
              },
            ),
            const SizedBox(height: 8),
            const _TasksList(),
            const SizedBox(height: 24),
            
            // Recent pomodoros section
            _SectionHeader(
              title: 'Recent Focus Sessions',
              actionText: 'History',
              onActionTap: () {
                // Navigate to pomodoro history
              },
            ),
            const SizedBox(height: 8),
            const _RecentPomodorosList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show quick action menu
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _DailyFocusCard extends StatelessWidget {
  const _DailyFocusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TODAY\'S FOCUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    // Edit daily focus
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete the product design for mobile app',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _ProgressIndicator(
                  value: 0.65,
                  label: '65% Complete',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Start pomodoro for this focus
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Focus'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _ProgressIndicator({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey.shade200,
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}

class _DailyStatsSection extends StatelessWidget {
  const _DailyStatsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.timer,
          value: '120',
          label: 'Focus minutes',
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.check_circle,
          value: '5',
          label: 'Completed tasks',
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.trending_up,
          value: '85%',
          label: 'Productivity',
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onActionTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionText),
        ),
      ],
    );
  }
}

class _TasksList extends StatelessWidget {
  const _TasksList();

  @override
  Widget build(BuildContext context) {
    // Mock data for tasks
    final tasks = [
      {
        'title': 'Finish wireframes for mobile app',
        'isCompleted': true,
        'priority': 'high',
        'project': 'Design System',
        'projectColor': Colors.purple,
      },
      {
        'title': 'Team meeting at 2:00 PM',
        'isCompleted': false,
        'priority': 'medium',
        'project': 'Project Management',
        'projectColor': Colors.blue,
      },
      {
        'title': 'Respond to client emails',
        'isCompleted': false,
        'priority': 'high',
        'project': 'Client Work',
        'projectColor': Colors.green,
      },
    ];

    return Column(
      children: tasks.map((task) => _TaskItem(
        title: task['title'] as String,
        isCompleted: task['isCompleted'] as bool,
        priority: task['priority'] as String,
        project: task['project'] as String,
        projectColor: task['projectColor'] as Color,
      )).toList(),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final String priority;
  final String project;
  final Color projectColor;

  const _TaskItem({
    required this.title,
    required this.isCompleted,
    required this.priority,
    required this.project,
    required this.projectColor,
  });

  @override
  Widget build(BuildContext context) {
    // Define priority color
    Color priorityColor;
    if (priority == 'high') {
      priorityColor = Colors.red;
    } else if (priority == 'medium') {
      priorityColor = Colors.orange;
    } else {
      priorityColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: isCompleted,
              activeColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) {
                // Update task completion status
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: projectColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        priority,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () {
                // Show task actions
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPomodorosList extends StatelessWidget {
  const _RecentPomodorosList();

  @override
  Widget build(BuildContext context) {
    // Mock data for recent pomodoros
    final pomodoros = [
      {
        'task': 'Wireframing',
        'project': 'Mobile App',
        'duration': '25 min',
        'time': '11:30 AM',
        'rating': 4.5,
      },
      {
        'task': 'Research',
        'project': 'Market Analysis',
        'duration': '25 min',
        'time': '10:00 AM',
        'rating': 3.0,
      },
    ];

    return Column(
      children: pomodoros.map((pomodoro) => _PomodoroItem(
        task: pomodoro['task'] as String,
        project: pomodoro['project'] as String,
        duration: pomodoro['duration'] as String,
        time: pomodoro['time'] as String,
        rating: pomodoro['rating'] as double,
      )).toList(),
    );
  }
}

class _PomodoroItem extends StatelessWidget {
  final String task;
  final String project;
  final String duration;
  final String time;
  final double rating;

  const _PomodoroItem({
    required this.task,
    required this.project,
    required this.duration,
    required this.time,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.timer,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$project · $duration · $time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                final isHalf = index + 0.5 == rating;
                final isFull = index < rating;
                
                return Icon(
                  isHalf ? Icons.star_half : (isFull ? Icons.star : Icons.star_border),
                  color: Colors.amber,
                  size: 18,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}