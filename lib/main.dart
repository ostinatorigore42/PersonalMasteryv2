import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // Ensure device orientation is portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const ProductivityApp());
}

class ProductivityApp extends StatelessWidget {
  const ProductivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second Brain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Dark theme matching the reference images
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE57373), // Light red for primary actions
          secondary: Color(0xFF4CAF50), // Green for completed tasks
          surface: Color(0xFF1E1E1E), // Card background
          background: Color(0xFF121212), // App background
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Sample project data
  final List<Map<String, dynamic>> _projects = [
    {
      'name': 'Academic Education',
      'color': Colors.purple,
      'focusMinutes': '0m',
      'taskCount': 5,
    },
    {
      'name': 'Reading',
      'color': Colors.cyan,
      'focusMinutes': '0m',
      'taskCount': 1,
    },
    {
      'name': 'Self-improvement Leisure',
      'color': Colors.pink,
      'focusMinutes': '0m',
      'taskCount': 3,
    },
    {
      'name': 'Zeitgeist',
      'color': Colors.orange,
      'focusMinutes': '0m',
      'taskCount': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App header with date
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Projects',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Project list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  return ProjectCard(
                    name: project['name'],
                    color: project['color'],
                    focusMinutes: project['focusMinutes'],
                    taskCount: project['taskCount'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailPage(
                            projectName: project['name'],
                            projectColor: project['color'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddProjectDialog();
        },
      ),
    );
  }

  void _showAddProjectDialog() {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Color'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _colorOption(Colors.purple, selectedColor == Colors.purple, () {
                      setState(() => selectedColor = Colors.purple);
                      Navigator.pop(context);
                      _showAddProjectDialog();
                    }),
                    _colorOption(Colors.cyan, selectedColor == Colors.cyan, () {
                      setState(() => selectedColor = Colors.cyan);
                      Navigator.pop(context);
                      _showAddProjectDialog();
                    }),
                    _colorOption(Colors.pink, selectedColor == Colors.pink, () {
                      setState(() => selectedColor = Colors.pink);
                      Navigator.pop(context);
                      _showAddProjectDialog();
                    }),
                    _colorOption(Colors.orange, selectedColor == Colors.orange, () {
                      setState(() => selectedColor = Colors.orange);
                      Navigator.pop(context);
                      _showAddProjectDialog();
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Create'),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _projects.add({
                      'name': nameController.text,
                      'color': selectedColor,
                      'focusMinutes': '0m',
                      'taskCount': 0,
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _colorOption(Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final String name;
  final Color color;
  final String focusMinutes;
  final int taskCount;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.name,
    required this.color,
    required this.focusMinutes,
    required this.taskCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              focusMinutes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 24),
            Text(
              '$taskCount',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectDetailPage extends StatefulWidget {
  final String projectName;
  final Color projectColor;

  const ProjectDetailPage({
    super.key,
    required this.projectName,
    required this.projectColor,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  // Sample task data - would come from a database in a real app
  late List<Map<String, dynamic>> _tasks;
  bool _showCompletedTasks = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize tasks based on project
    if (widget.projectName == 'Academic Education') {
      _tasks = [
        {
          'title': 'CS: Programming',
          'isCompleted': false,
          'pomodoroCount': 1,
          'dueDate': null,
        },
        {
          'title': 'Macroeconomics: Revision',
          'isCompleted': false,
          'pomodoroCount': 2,
          'dueDate': null,
        },
        {
          'title': 'Physics: Work and Mechanical Energy',
          'isCompleted': false,
          'pomodoroCount': 1,
          'dueDate': null,
        },
        {
          'title': 'Biology: Meiosis and genetic diversity',
          'isCompleted': false,
          'pomodoroCount': 2,
          'dueDate': null,
        },
        {
          'title': 'Physics 1: Newtonian Laws',
          'isCompleted': false,
          'pomodoroCount': 1,
          'dueDate': 'Sun, 8 Jan',
        },
      ];
    } else if (widget.projectName == 'Reading') {
      _tasks = [
        {
          'title': 'Descartes Error',
          'isCompleted': false,
          'pomodoroCount': 9,
          'dueDate': null,
        },
        {
          'title': 'Homo Deus',
          'isCompleted': true,
          'pomodoroCount': 15,
          'dueDate': 'Sun, 15 Jan 2023',
        },
        {
          'title': 'Webs of Humankind: Ch 25',
          'isCompleted': true,
          'pomodoroCount': 1,
          'dueDate': 'Fri, 6 Jan 2023',
        },
        {
          'title': 'Red Pill - Andrew Kurpatov',
          'isCompleted': true,
          'pomodoroCount': 1,
          'dueDate': 'Tue, 15 Feb 2022',
        },
      ];
    } else {
      _tasks = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks based on completion status
    final displayTasks = _showCompletedTasks 
        ? _tasks 
        : _tasks.where((task) => !task['isCompleted']).toList();
    
    // Calculate stats
    final incompleteTaskCount = _tasks.where((task) => !task['isCompleted']).length;
    final completedTaskCount = _tasks.where((task) => task['isCompleted']).length;
    
    // Calculate total time
    int totalPomodoroCount = 0;
    for (var task in _tasks.where((task) => task['isCompleted'])) {
      totalPomodoroCount += task['pomodoroCount'] as int;
    }
    
    // Format as hours and minutes (assuming 25 mins per pomodoro)
    final totalMinutes = totalPomodoroCount * 25;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final elapsedTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_showCompletedTasks ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: () {
              setState(() {
                _showCompletedTasks = !_showCompletedTasks;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show project options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('HH    MM', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          '00:00',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Estimated Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('', style: TextStyle(fontSize: 12)),
                        Text(
                          '$incompleteTaskCount',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Tasks to be Completed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('HH    MM', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          elapsedTime,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Elapsed Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('', style: TextStyle(fontSize: 12)),
                        Text(
                          '$completedTaskCount',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Completed Tasks', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Add task card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: InkWell(
                onTap: () {
                  _showAddTaskDialog();
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Colors.grey),
                      SizedBox(width: 16),
                      Text('Add a task...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Task list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: displayTasks.length,
              itemBuilder: (context, index) {
                final task = displayTasks[index];
                return TaskCard(
                  title: task['title'],
                  isCompleted: task['isCompleted'],
                  pomodoroCount: task['pomodoroCount'],
                  dueDate: task['dueDate'],
                  projectColor: widget.projectColor,
                  onToggleComplete: () {
                    setState(() {
                      task['isCompleted'] = !task['isCompleted'];
                    });
                  },
                  onStartTimer: () {
                    // Navigate to timer screen
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => PomodoroTimerPage(
                          taskTitle: task['title'],
                          projectName: widget.projectName,
                          projectColor: widget.projectColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Completed tasks toggle
          if (_tasks.any((task) => task['isCompleted']))
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showCompletedTasks = !_showCompletedTasks;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showCompletedTasks ? 'Hide Completed Tasks' : 'Show Completed Tasks',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Icon(
                      _showCompletedTasks ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    int pomodoroCount = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Estimated Pomodoros:'),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: pomodoroCount > 1 ? () {
                            setState(() {
                              pomodoroCount--;
                            });
                          } : null,
                        ),
                        Text('$pomodoroCount', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              pomodoroCount++;
                            });
                          },
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Add'),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add({
                      'title': titleController.text,
                      'isCompleted': false,
                      'pomodoroCount': pomodoroCount,
                      'dueDate': null,
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final int pomodoroCount;
  final String? dueDate;
  final Color projectColor;
  final VoidCallback onToggleComplete;
  final VoidCallback onStartTimer;

  const TaskCard({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.pomodoroCount,
    this.dueDate,
    required this.projectColor,
    required this.onToggleComplete,
    required this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            
            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : Colors.white,
                    ),
                  ),
                  if (pomodoroCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$pomodoroCount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          dueDate!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Start timer button
            IconButton(
              icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
              onPressed: onStartTimer,
            ),
          ],
        ),
      ),
    );
  }
}

class PomodoroTimerPage extends StatefulWidget {
  final String taskTitle;
  final String projectName;
  final Color projectColor;

  const PomodoroTimerPage({
    super.key,
    required this.taskTitle,
    required this.projectName,
    required this.projectColor,
  });

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  bool _isRunning = false;
  int _minutes = 25;
  int _seconds = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.taskTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.projectName,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Focus time', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset button
                IconButton(
                  icon: const Icon(Icons.replay, color: Colors.white, size: 28),
                  onPressed: () {
                    setState(() {
                      _minutes = 25;
                      _seconds = 0;
                      _isRunning = false;
                    });
                  },
                ),
                const SizedBox(width: 32),
                
                // Play/Pause button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isRunning = !_isRunning;
                    });
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                
                // Skip button
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                  onPressed: () {
                    // Skip to next pomodoro/break
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedView = 'Week';
  String _dateRange = 'May 12 - May 18';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      _viewButton('Day', _selectedView == 'Day', () {
                        setState(() {
                          _selectedView = 'Day';
                        });
                      }),
                      _viewButton('Week', _selectedView == 'Week', () {
                        setState(() {
                          _selectedView = 'Week';
                        });
                      }),
                      _viewButton('Month', _selectedView == 'Month', () {
                        setState(() {
                          _selectedView = 'Month';
                        });
                      }),
                      _viewButton('Year', _selectedView == 'Year', () {
                        setState(() {
                          _selectedView = 'Year';
                        });
                      }),
                    ],
                  ),
                ),
              ),
            ),
            
            // Date range selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      // Previous date range
                    },
                  ),
                  Text(_dateRange, style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      // Next date range
                    },
                  ),
                ],
              ),
            ),
            
            // Tomato stats
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                              Image.network(
                                'https://em-content.zobj.net/thumbs/120/apple/354/tomato_1f345.png',
                                width: 24,
                                height: 24,
                              ),
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
            ),
            
            // Focus stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      _focusBar('Focus', 0.42, const Color(0xFFE67E22), '4h15m'),
                      const SizedBox(height: 12),
                      _focusBar('Work', 0.37, const Color(0xFF2ECC71), '3h52m'),
                      const SizedBox(height: 12),
                      _focusBar('Read', 0.21, const Color(0xFFBDC581), '2h14m'),
                    ],
                  ),
                ),
              ),
            ),
            
            // Weekly focus
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Week\'s Focus', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Image.network(
                                'https://em-content.zobj.net/thumbs/120/apple/354/tomato_1f345.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text('21', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Abandoned', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Image.network(
                                'https://em-content.zobj.net/thumbs/120/apple/354/tomato_1f345.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text('1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Week calendar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('May 12, Mon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _dayButton('Mon', '12', true),
                          _dayButton('Tue', '13', false),
                          _dayButton('Wed', '14', false),
                          _dayButton('Thu', '15', false),
                          _dayButton('Fri', '16', false),
                          _dayButton('Sat', '17', false),
                          _dayButton('Sun', '18', true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _viewButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
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
      ),
    );
  }
  
  Widget _focusBar(String label, double percentage, Color color, String time) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white)),
                  Text(time, style: const TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                width: MediaQuery.of(context).size.width * percentage - 64,
                child: Center(
                  child: Text('${(percentage * 100).round()}%', 
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _dayButton(String day, String date, bool isHighlighted) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isHighlighted ? 
          (day == 'Mon' ? const Color(0xFFE74C3C) : const Color(0xFF8E44AD)) : 
          const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day, style: const TextStyle(fontSize: 10, color: Colors.white)),
          Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
