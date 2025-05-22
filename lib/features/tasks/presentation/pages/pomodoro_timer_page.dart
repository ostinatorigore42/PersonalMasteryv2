import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../models/task.dart';
import '../../../../core/services/firebase_service.dart';

class PomodoroTimerPage extends StatefulWidget {
  final String projectId;
  final String projectName;
  final Task task;

  const PomodoroTimerPage({
    Key? key,
    required this.projectId,
    required this.projectName,
    required this.task,
  }) : super(key: key);

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  bool _isRunning = false;
  Timer? _timer;
  int _remainingSeconds = 25 * 60; // Time left in the current session (work or break)
  int _completedPomodoros = 0;
  bool _isBreak = false;
  bool _isLongBreak = false;
  int _pomodorosUntilLongBreak = 4;
  int _sessionElapsedSeconds = 0; // Elapsed time in the current work session
  int _totalTaskElapsedTime = 0; // Total elapsed time for the task (loaded from task + session time)

  // Timer settings
  int _workDuration = 25; // minutes
  int _shortBreakDuration = 5; // minutes
  int _longBreakDuration = 15; // minutes
  bool _autoStartBreaks = true;
  bool _autoStartPomodoros = true;

  late final FirebaseService _firebaseService;

  @override
  void initState() {
    super.initState();
    // Load timer settings from task, use defaults if null
    _workDuration = widget.task.workDuration ?? 25;
    _shortBreakDuration = widget.task.shortBreakDuration ?? 5;
    _longBreakDuration = widget.task.longBreakDuration ?? 15;
    _pomodorosUntilLongBreak = widget.task.pomodorosUntilLongBreak ?? 4;
    _autoStartBreaks = widget.task.autoStartBreaks ?? true;
    _autoStartPomodoros = widget.task.autoStartPomodoros ?? true;
    
    _remainingSeconds = _workDuration * 60;
    _completedPomodoros = widget.task.completedPomodoros;
    _totalTaskElapsedTime = widget.task.elapsedTime; // Load total elapsed time
    _firebaseService = FirebaseService.instance;

    print('PomodoroTimerPage initState: task: ${widget.task.title}, initial total elapsed time: ${_totalTaskElapsedTime}, initial completed pomodoros: ${widget.task.completedPomodoros}, workDuration: $_workDuration, shortBreakDuration: $_shortBreakDuration, longBreakDuration: $_longBreakDuration, pomodorosUntilLongBreak: $_pomodorosUntilLongBreak, autoStartBreaks: $_autoStartBreaks, autoStartPomodoros: $_autoStartPomodoros');
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Save any accumulated session elapsed time before disposing if the timer was running
    if (_isRunning && !_isBreak && _sessionElapsedSeconds > 0) {
      _updateTaskPomodoros(addSessionTime: true);
    }
    super.dispose();
  }

  Future<void> _updateTaskPomodoros({bool addSessionTime = false}) async {
    try {
      // Calculate new total elapsed time only if adding session time
      final int newTotalElapsedTime = addSessionTime 
          ? _totalTaskElapsedTime + _sessionElapsedSeconds // Add to the current total state
          : _totalTaskElapsedTime; // Otherwise keep existing total

      await _firebaseService.updateUserDocument(
        'projects/${widget.projectId}/tasks',
        widget.task.id,
        {
          'completedPomodoros': _completedPomodoros,
          'lastPomodoroCompleted': DateTime.now(),
          'elapsedTime': newTotalElapsedTime,
          // Save timer settings
          'workDuration': _workDuration,
          'shortBreakDuration': _shortBreakDuration,
          'longBreakDuration': _longBreakDuration,
          'pomodorosUntilLongBreak': _pomodorosUntilLongBreak,
          'autoStartBreaks': _autoStartBreaks,
          'autoStartPomodoros': _autoStartPomodoros,
        },
      );
       // Update the local state with the new total elapsed time after successful save
       setState(() {
         _totalTaskElapsedTime = newTotalElapsedTime;
       });
    } catch (e) {
      print('Error updating task pomodoros: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    print('Timer started. Remaining seconds: $_remainingSeconds, Session Elapsed: $_sessionElapsedSeconds');
    _isRunning = true; // Set isRunning here
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (!_isBreak) {
            _sessionElapsedSeconds++;
            // Add print to see elapsed time incrementing
            print('Task: ${widget.task.title}, Timer ticking. Remaining: $_remainingSeconds, Session Elapsed: $_sessionElapsedSeconds, Total Elapsed: ${_totalTaskElapsedTime + _sessionElapsedSeconds}, IsBreak: $_isBreak');
          }
        } else {
          _timer?.cancel();
          print('Timer finished. IsBreak: $_isBreak');
          if (!_isBreak) {
            // Work session completed
            setState(() {
              _completedPomodoros++;
              _isBreak = true;
              _isLongBreak = _completedPomodoros % _pomodorosUntilLongBreak == 0;
              _remainingSeconds = (_isLongBreak ? _longBreakDuration : _shortBreakDuration) * 60;
            });
            print('Work session completed. Completed Pomodoros: $_completedPomodoros, Starting Break. Remaining: $_remainingSeconds, IsLongBreak: $_isLongBreak');
            _updateTaskPomodoros(addSessionTime: true); // Update Firestore on session completion, adding session time
            _sessionElapsedSeconds = 0; // Reset session elapsed time after saving
            if (_autoStartBreaks) {
              _startTimer();
            }
          } else {
            // Break completed
            setState(() {
              _isBreak = false;
              _remainingSeconds = _workDuration * 60;
            });
            print('Break completed. Starting Work. Remaining: $_remainingSeconds');
            // No need to add session time on break completion
            // _updateTaskPomodoros(addSessionTime: false);
            if (_autoStartPomodoros) {
              _startTimer();
            }
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _isRunning = false; // Set isRunning here
    print('Timer paused. Remaining: $_remainingSeconds, Session Elapsed: $_sessionElapsedSeconds, Total Elapsed: ${_totalTaskElapsedTime + _sessionElapsedSeconds}, IsBreak: $_isBreak');
    // Update total elapsed time with current session time when paused during a work session
    if (!_isBreak && _sessionElapsedSeconds > 0) {
      _updateTaskPomodoros(addSessionTime: true);
      _sessionElapsedSeconds = 0; // Reset session elapsed time after saving on pause
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _isRunning = false; // Set isRunning here
    print('Timer reset. Remaining: $_remainingSeconds, Session Elapsed: $_sessionElapsedSeconds, Total Elapsed: ${_totalTaskElapsedTime + _sessionElapsedSeconds}, IsBreak: $_isBreak');
    // Update total elapsed time with current session time when reset during a work session
     if (!_isBreak && _sessionElapsedSeconds > 0) {
       _updateTaskPomodoros(addSessionTime: true);
     }
    setState(() {
      _isBreak = false;
      _isLongBreak = false; // Reset long break state
      _remainingSeconds = _workDuration * 60;
      _sessionElapsedSeconds = 0; // Reset session elapsed time on reset
      // Note: _totalTaskElapsedTime is NOT reset here, it accumulates across sessions
    });
    // No need to save settings on a simple reset, only on apply/default
    // _updateTaskPomodoros();
  }

  // Helper to format seconds into HH:MM:SS
  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

   // Helper to format seconds into MM:SS
  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCustomizationDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pomodoro Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Work Duration
                ListTile(
                  title: const Text('Work Duration'),
                  subtitle: Text('$_workDuration minutes'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_workDuration > 1) {
                            setState(() => _workDuration--);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => _workDuration++);
                        },
                      ),
                    ],
                  ),
                ),
                // Short Break Duration
                ListTile(
                  title: const Text('Short Break'),
                  subtitle: Text('$_shortBreakDuration minutes'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_shortBreakDuration > 1) {
                            setState(() => _shortBreakDuration--);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => _shortBreakDuration++);
                        },
                      ),
                    ],
                  ),
                ),
                // Long Break Duration
                ListTile(
                  title: const Text('Long Break'),
                  subtitle: Text('$_longBreakDuration minutes'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_longBreakDuration > 1) {
                            setState(() => _longBreakDuration--);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => _longBreakDuration++);
                        },
                      ),
                    ],
                  ),
                ),
                // Pomodoros until long break
                ListTile(
                  title: const Text('Pomodoros until long break'),
                  subtitle: Text('$_pomodorosUntilLongBreak'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (_pomodorosUntilLongBreak > 1) {
                            setState(() => _pomodorosUntilLongBreak--);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() => _pomodorosUntilLongBreak++);
                        },
                      ),
                    ],
                  ),
                ),
                // Auto-start settings
                SwitchListTile(
                  title: const Text('Auto-start breaks'),
                  value: _autoStartBreaks,
                  onChanged: (value) {
                    setState(() => _autoStartBreaks = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-start pomodoros'),
                  value: _autoStartPomodoros,
                  onChanged: (value) {
                    setState(() => _autoStartPomodoros = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                this.setState(() {
                  _remainingSeconds = _workDuration * 60;
                  // Save updated settings when applied
                  _updateTaskPomodoros();
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _setDefaultDuration() {
    setState(() {
      _workDuration = 25;
      _shortBreakDuration = 5;
      _longBreakDuration = 15;
      _pomodorosUntilLongBreak = 4;
      _autoStartBreaks = true;
      _autoStartPomodoros = true;
      _remainingSeconds = _workDuration * 60;
      _sessionElapsedSeconds = 0; // Reset session elapsed time when defaulting
       // Note: _totalTaskElapsedTime is NOT reset here
    });
    // Save default settings
    _updateTaskPomodoros(addSessionTime: false); // Don't add session time when defaulting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showCustomizationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _setDefaultDuration,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isBreak 
                ? _isLongBreak 
                  ? 'Long Break' 
                  : 'Short Break'
                : 'Work Time',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _formatTime(_remainingSeconds),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _isRunning = !_isRunning;
                      if (_isRunning) {
                        _startTimer();
                      } else {
                        _pauseTimer();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: _resetTimer,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Completed Pomodoros: $_completedPomodoros',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Elapsed Time for Task: ${_formatDuration(_totalTaskElapsedTime)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Next long break after ${_pomodorosUntilLongBreak - (_completedPomodoros % _pomodorosUntilLongBreak)} pomodoros',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
} 