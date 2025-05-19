import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE57373),
          secondary: Color(0xFF4CAF50),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const ProjectsPage(),
    );
  }
}

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final List<Map<String, dynamic>> projects = [
    {
      'name': 'Academic Education',
      'color': Colors.purple,
      'minutes': '0m',
      'tasks': 5,
    },
    {
      'name': 'Reading',
      'color': Colors.cyan,
      'minutes': '0m',
      'tasks': 1,
    },
    {
      'name': 'Self-improvement Leisure',
      'color': Colors.pink,
      'minutes': '0m',
      'tasks': 3,
    },
    {
      'name': 'Zeitgeist',
      'color': Colors.orange,
      'minutes': '0m',
      'tasks': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: project['color'],
              radius: 12,
            ),
            title: Text(project['name']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project['minutes'],
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 24),
                Text('${project['tasks']}'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskListPage(
                    projectName: project['name'],
                    projectColor: project['color'],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
        onPressed: () => _showAddProjectDialog(),
      ),
    );
  }

  void _showAddProjectDialog() {
    final nameController = TextEditingController();
    Color selectedColor = Colors.purple;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _colorOption(Colors.purple),
                  _colorOption(Colors.cyan),
                  _colorOption(Colors.pink),
                  _colorOption(Colors.orange),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    projects.add({
                      'name': nameController.text,
                      'color': selectedColor,
                      'minutes': '0m',
                      'tasks': 0,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class TaskListPage extends StatefulWidget {
  final String projectName;
  final Color projectColor;

  const TaskListPage({
    super.key,
    required this.projectName,
    required this.projectColor,
  });

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late List<Map<String, dynamic>> tasks;
  bool showCompleted = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.projectName == 'Academic Education') {
      tasks = [
        {
          'title': 'CS: Programming',
          'completed': false,
          'pomodoros': 1,
        },
        {
          'title': 'Macroeconomics: Revision',
          'completed': false,
          'pomodoros': 2,
        },
        {
          'title': 'Physics: Work and Mechanical Energy',
          'completed': false,
          'pomodoros': 1,
        },
        {
          'title': 'Biology: Meiosis and genetic diversity',
          'completed': false,
          'pomodoros': 2,
        },
        {
          'title': 'Physics 1: Newtonian Laws',
          'completed': false,
          'pomodoros': 1,
          'dueDate': 'Sun, 8 Jan',
        },
      ];
    } else if (widget.projectName == 'Reading') {
      tasks = [
        {
          'title': 'Descartes Error',
          'completed': false,
          'pomodoros': 9,
        },
        {
          'title': 'Homo Deus',
          'completed': true,
          'pomodoros': 15,
          'dueDate': 'Sun, 15 Jan 2023',
        },
        {
          'title': 'Webs of Humankind: Ch 25',
          'completed': true,
          'pomodoros': 1,
          'dueDate': 'Fri, 6 Jan 2023',
        },
      ];
    } else {
      tasks = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTasks = showCompleted 
        ? tasks 
        : tasks.where((task) => !task['completed']).toList();
    
    final incompleteTasks = tasks.where((task) => !task['completed']).length;
    final completedTasks = tasks.where((task) => task['completed']).length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            icon: Icon(showCompleted ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: () {
              setState(() {
                showCompleted = !showCompleted;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn('00:00', 'Estimated Time'),
                  _statColumn('$incompleteTasks', 'Tasks to Complete'),
                  _statColumn('75:27', 'Elapsed Time'),
                  _statColumn('$completedTasks', 'Completed Tasks'),
                ],
              ),
            ),
          ),
          
          // Add task button
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add a task...'),
              onTap: _showAddTaskDialog,
            ),
          ),
          
          // Task list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayTasks.length,
              itemBuilder: (context, index) {
                final task = displayTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        setState(() {
                          task['completed'] = !task['completed'];
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                          color: task['completed'] ? Colors.green : Colors.transparent,
                        ),
                        child: task['completed'] 
                            ? const Icon(Icons.check, size: 18, color: Colors.white) 
                            : null,
                      ),
                    ),
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: task['completed'] ? TextDecoration.lineThrough : null,
                        color: task['completed'] ? Colors.grey : Colors.white,
                      ),
                    ),
                    subtitle: task['pomodoros'] != null ? Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Theme.of(context).colorScheme.primary),
                        Text(' ${task['pomodoros']}'),
                        if (task['dueDate'] != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.primary),
                          Text(' ${task['dueDate']}'),
                        ],
                      ],
                    ) : null,
                    trailing: IconButton(
                      icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PomodoroPage(
                              taskTitle: task['title'],
                              projectName: widget.projectName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    int pomodoros = 1;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Estimated Pomodoros:'),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: pomodoros > 1 ? () {
                          setState(() => pomodoros--);
                        } : null,
                      ),
                      Text('$pomodoros'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => pomodoros++);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    tasks.add({
                      'title': titleController.text,
                      'completed': false,
                      'pomodoros': pomodoros,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class PomodoroPage extends StatefulWidget {
  final String taskTitle;
  final String projectName;

  const PomodoroPage({
    super.key, 
    required this.taskTitle, 
    required this.projectName,
  });

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  bool isRunning = false;
  int minutes = 25;
  int seconds = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.taskTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.projectName,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Focus time', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                  onPressed: () {
                    setState(() {
                      minutes = 25;
                      seconds = 0;
                      isRunning = false;
                    });
                  },
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isRunning = !isRunning;
                    });
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View selector
            Card(
              child: Row(
                children: [
                  _viewButton('Day', false),
                  _viewButton('Week', true),
                  _viewButton('Month', false),
                  _viewButton('Year', false),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Date range
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {},
                ),
                const Text('May 12 - May 18'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Stats cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Tomatoes', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text('39', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Days', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text('9', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Focus stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Week\'s Focus', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('10h 21m', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Focus', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('17h 59m', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _focusBar(context, 'Focus', 0.42, const Color(0xFFE67E22), '4h15m'),
                    const SizedBox(height: 12),
                    _focusBar(context, 'Work', 0.37, const Color(0xFF2ECC71), '3h52m'),
                    const SizedBox(height: 12),
                    _focusBar(context, 'Read', 0.21, const Color(0xFFBDC581), '2h14m'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewButton(String text, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _focusBar(BuildContext context, String label, double percentage, Color color, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(time),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 24,
          width: MediaQuery.of(context).size.width * percentage - 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '${(percentage * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
