import 'package:flutter/material.dart';
import 'dart:async';

class PomodoroTabContent extends StatefulWidget {
  const PomodoroTabContent({super.key});

  @override
  State<PomodoroTabContent> createState() => _PomodoroTabContentState();
}

class _PomodoroTabContentState extends State<PomodoroTabContent> with SingleTickerProviderStateMixin {
  // Timer state
  Timer? _timer;
  int _currentSeconds = 25 * 60; // 25 minutes default
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;
  
  // Pomodoro settings
  int _pomodoroMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _pomodorosBeforeLongBreak = 4;
  
  // Animation controller for progress
  late AnimationController _animationController;
  
  // Current task
  Map<String, dynamic>? _selectedTask;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _pomodoroMinutes * 60),
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    
    setState(() {
      _isRunning = true;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
          _animationController.value = 1 - (_currentSeconds / (_isBreak 
            ? (_completedPomodoros % _pomodorosBeforeLongBreak == 0 ? _longBreakMinutes : _shortBreakMinutes) * 60 
            : _pomodoroMinutes * 60));
        } else {
          _timer!.cancel();
          _isRunning = false;
          
          if (_isBreak) {
            // Break is over, start a new pomodoro
            _isBreak = false;
            _currentSeconds = _pomodoroMinutes * 60;
            _animationController.duration = Duration(seconds: _pomodoroMinutes * 60);
            _animationController.reset();
          } else {
            // Pomodoro is over, start a break
            _completedPomodoros++;
            _isBreak = true;
            
            if (_completedPomodoros % _pomodorosBeforeLongBreak == 0) {
              // Time for a long break
              _currentSeconds = _longBreakMinutes * 60;
              _animationController.duration = Duration(seconds: _longBreakMinutes * 60);
            } else {
              // Time for a short break
              _currentSeconds = _shortBreakMinutes * 60;
              _animationController.duration = Duration(seconds: _shortBreakMinutes * 60);
            }
            _animationController.reset();
            
            // Show session complete dialog
            _showSessionCompleteDialog();
          }
        }
      });
    });
  }
  
  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }
  
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_isBreak) {
        _currentSeconds = (_completedPomodoros % _pomodorosBeforeLongBreak == 0 
            ? _longBreakMinutes 
            : _shortBreakMinutes) * 60;
      } else {
        _currentSeconds = _pomodoroMinutes * 60;
      }
      _animationController.reset();
    });
  }
  
  void _skipToBreak() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = true;
      _completedPomodoros++;
      
      if (_completedPomodoros % _pomodorosBeforeLongBreak == 0) {
        // Time for a long break
        _currentSeconds = _longBreakMinutes * 60;
        _animationController.duration = Duration(seconds: _longBreakMinutes * 60);
      } else {
        // Time for a short break
        _currentSeconds = _shortBreakMinutes * 60;
        _animationController.duration = Duration(seconds: _shortBreakMinutes * 60);
      }
      _animationController.reset();
    });
  }
  
  void _skipToPomodoro() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _currentSeconds = _pomodoroMinutes * 60;
      _animationController.duration = Duration(seconds: _pomodoroMinutes * 60);
      _animationController.reset();
    });
  }
  
  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomodoro Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Great job! Take a break.'),
            const SizedBox(height: 16),
            const Text('How was your focus session?'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < 3 ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    // Save rating
                    Navigator.of(context).pop();
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showSelectTaskDialog() {
    // Mock tasks
    final tasks = [
      {
        'id': '1',
        'title': 'Wireframing',
        'project': 'Mobile App Design',
        'projectColor': Colors.blue,
      },
      {
        'id': '2',
        'title': 'Research',
        'project': 'Market Analysis',
        'projectColor': Colors.green,
      },
      {
        'id': '3',
        'title': 'Team Meeting',
        'project': 'Project Management',
        'projectColor': Colors.purple,
      },
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Task'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task['title'] as String),
                subtitle: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: task['projectColor'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(task['project'] as String),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedTask = task;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showSettingsDialog() {
    int pomodoroMinutes = _pomodoroMinutes;
    int shortBreakMinutes = _shortBreakMinutes;
    int longBreakMinutes = _longBreakMinutes;
    int pomodorosBeforeLongBreak = _pomodorosBeforeLongBreak;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomodoro Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pomodoro Duration'),
              Slider(
                value: pomodoroMinutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '$pomodoroMinutes minutes',
                onChanged: (value) {
                  pomodoroMinutes = value.round();
                  // Need to call setState to update the label
                  // This is a bit of a hack but works in a dialog
                  (context as Element).markNeedsBuild();
                },
              ),
              
              const SizedBox(height: 16),
              const Text('Short Break Duration'),
              Slider(
                value: shortBreakMinutes.toDouble(),
                min: 1,
                max: 15,
                divisions: 14,
                label: '$shortBreakMinutes minutes',
                onChanged: (value) {
                  shortBreakMinutes = value.round();
                  (context as Element).markNeedsBuild();
                },
              ),
              
              const SizedBox(height: 16),
              const Text('Long Break Duration'),
              Slider(
                value: longBreakMinutes.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '$longBreakMinutes minutes',
                onChanged: (value) {
                  longBreakMinutes = value.round();
                  (context as Element).markNeedsBuild();
                },
              ),
              
              const SizedBox(height: 16),
              const Text('Pomodoros before Long Break'),
              Slider(
                value: pomodorosBeforeLongBreak.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                label: '$pomodorosBeforeLongBreak pomodoros',
                onChanged: (value) {
                  pomodorosBeforeLongBreak = value.round();
                  (context as Element).markNeedsBuild();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pomodoroMinutes = pomodoroMinutes;
                _shortBreakMinutes = shortBreakMinutes;
                _longBreakMinutes = longBreakMinutes;
                _pomodorosBeforeLongBreak = pomodorosBeforeLongBreak;
                
                // Reset timer with new settings
                if (!_isRunning) {
                  if (_isBreak) {
                    _currentSeconds = (_completedPomodoros % _pomodorosBeforeLongBreak == 0 
                        ? _longBreakMinutes 
                        : _shortBreakMinutes) * 60;
                    _animationController.duration = Duration(seconds: _currentSeconds);
                  } else {
                    _currentSeconds = _pomodoroMinutes * 60;
                    _animationController.duration = Duration(seconds: _currentSeconds);
                  }
                  _animationController.reset();
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar showing pomodoro count
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isBreak 
                    ? (_completedPomodoros % _pomodorosBeforeLongBreak == 0 
                        ? 'Long Break' 
                        : 'Short Break')
                    : 'Pomodoro',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($_completedPomodoros/$_pomodorosBeforeLongBreak)',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Main timer content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedTask != null) ...[
                    Text(
                      'Current Task:',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _selectedTask!['projectColor'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTask!['title'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _selectedTask!['project'] as String,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedTask = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Timer circle
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _animationController.value,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.shade200,
                              color: _isBreak ? Colors.green : theme.colorScheme.primary,
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_currentSeconds),
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                            Text(
                              _isBreak ? 'Break time' : 'Focus time',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Skip button (visible during pomodoro for testing)
                      if (!_isBreak)
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: _skipToBreak,
                          tooltip: 'Skip to break',
                        ),
                      
                      // Reset button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _resetTimer,
                        tooltip: 'Reset timer',
                      ),
                      
                      // Play/Pause button
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                        ),
                      ),
                      
                      // Select task button
                      IconButton(
                        icon: const Icon(Icons.list_alt),
                        onPressed: _showSelectTaskDialog,
                        tooltip: 'Select task',
                      ),
                      
                      // Skip button (visible during break for testing)
                      if (_isBreak)
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: _skipToPomodoro,
                          tooltip: 'Skip to pomodoro',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}