import 'package:flutter/material.dart';
import 'dart:async';

class PomodoroTabContent extends StatefulWidget {
  const PomodoroTabContent({super.key});

  @override
  State<PomodoroTabContent> createState() => _PomodoroTabContentState();
}

class _PomodoroTabContentState extends State<PomodoroTabContent> {
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
  
  // Current task
  Map<String, dynamic>? _selectedTask;
  
  @override
  void dispose() {
    _timer?.cancel();
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
        } else {
          _timer!.cancel();
          _isRunning = false;
          
          if (_isBreak) {
            // Break is over, start a new pomodoro
            _isBreak = false;
            _currentSeconds = _pomodoroMinutes * 60;
          } else {
            // Pomodoro is over, start a break
            _completedPomodoros++;
            _isBreak = true;
            
            if (_completedPomodoros % _pomodorosBeforeLongBreak == 0) {
              // Time for a long break
              _currentSeconds = _longBreakMinutes * 60;
            } else {
              // Time for a short break
              _currentSeconds = _shortBreakMinutes * 60;
            }
            
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
    // Sample tasks
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
                subtitle: Text(task['project'] as String),
                leading: CircleAvatar(
                  backgroundColor: task['projectColor'] as Color,
                  radius: 12,
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
            onPressed: () {
              // Show settings dialog (simplified)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon'))
              );
            },
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
                            CircleAvatar(
                              backgroundColor: _selectedTask!['projectColor'] as Color,
                              radius: 8,
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
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isBreak ? Colors.green : theme.colorScheme.primary,
                        width: 8,
                      ),
                    ),
                    child: Column(
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
                  ),
                  const SizedBox(height: 32),
                  
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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