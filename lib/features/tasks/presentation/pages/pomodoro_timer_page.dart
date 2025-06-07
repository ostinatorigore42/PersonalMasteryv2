import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../models/task.dart';
import '../../../../core/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get_it/get_it.dart';
import '../../../pomodoro/domain/repositories/pomodoro_repository.dart';

/// A page that implements the Pomodoro timer functionality for a specific task.
/// This is the main timer interface where users can:
/// - Start/pause/reset the timer
/// - Track completed pomodoros
/// - Customize timer settings
/// - Edit task details
/// - View elapsed time
class PomodoroTimerPage extends StatefulWidget {
  final String projectId;
  final String projectName;
  final Task task;
  final bool autostart;

  const PomodoroTimerPage({
    Key? key,
    required this.projectId,
    required this.projectName,
    required this.task,
    this.autostart = false,
  }) : super(key: key);

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  // Timer state variables
  bool _isRunning = false;
  Timer? _timer;
  int _remainingSeconds = 25 * 60; // Time left in the current session (work or break)
  int _completedPomodoros = 0;
  bool _isBreak = false;
  bool _isLongBreak = false;
  int _pomodorosUntilLongBreak = 4;
  int _sessionElapsedSeconds = 0; // Elapsed time in the current work session
  int _totalTaskElapsedTime = 0; // Total elapsed time for the task (loaded from task + session time)

  // Timer settings - these can be customized per task
  int _workDuration = 25; // minutes
  int _shortBreakDuration = 5; // minutes
  int _longBreakDuration = 15; // minutes
  bool _autoStartBreaks = true;
  bool _autoStartPomodoros = true;

  late final FirebaseService _firebaseService;
  late AudioPlayer _audioPlayer;

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
    _audioPlayer = AudioPlayer();

    // Start timer automatically if autostart is true
    if (widget.autostart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }

    print('PomodoroTimerPage initState: task: ${widget.task.title}, initial total elapsed time: ${_totalTaskElapsedTime}, initial completed pomodoros: ${widget.task.completedPomodoros}, workDuration: $_workDuration, shortBreakDuration: $_shortBreakDuration, longBreakDuration: $_longBreakDuration, pomodorosUntilLongBreak: $_pomodorosUntilLongBreak, autoStartBreaks: $_autoStartBreaks, autoStartPomodoros: $_autoStartPomodoros');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    // Save any accumulated session elapsed time before disposing if the timer was running
    if (_isRunning && !_isBreak && _sessionElapsedSeconds > 0) {
      _updateTaskPomodoros(addSessionTime: true);
    }
    super.dispose();
  }

  /// Updates the task's pomodoro data in Firestore
  /// [addSessionTime] determines whether to add the current session's elapsed time
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

  /// Starts the timer and handles the countdown logic
  void _startTimer() {
    _timer?.cancel();
    print('Timer started. Remaining seconds: $_remainingSeconds, Session Elapsed: $_sessionElapsedSeconds');
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          if (!_isBreak) {
            _sessionElapsedSeconds++;
            print('Task: ${widget.task.title}, Timer ticking. Remaining: $_remainingSeconds, Session Elapsed: $_sessionElapsedSeconds, Total Elapsed: ${_totalTaskElapsedTime + _sessionElapsedSeconds}, IsBreak: $_isBreak');
          }
        });
      } else {
        _timer?.cancel();
        print('Timer finished. IsBreak: $_isBreak');
        if (!_isBreak) {
          _playWorkEndSound();
          setState(() {
            _completedPomodoros++;
            _isBreak = true;
            _isLongBreak = _completedPomodoros % _pomodorosUntilLongBreak == 0;
            _remainingSeconds = (_isLongBreak ? _longBreakDuration : _shortBreakDuration) * 60;
          });
          print('DEBUG: About to call startPomodoroSession');
          final pomodoroRepo = GetIt.instance.get<PomodoroRepository>();
          final sessionId = await pomodoroRepo.startPomodoroSession(
            taskId: widget.task.id,
            durationMinutes: _workDuration,
            projectId: widget.projectId,
          );
          print('DEBUG: Called startPomodoroSession, sessionId: $sessionId');
          await pomodoroRepo.completePomodoroSession(sessionId: sessionId);
          print('DEBUG: Called completePomodoroSession for sessionId: $sessionId');
          _updateTaskPomodoros(addSessionTime: true);
          setState(() {
            _sessionElapsedSeconds = 0;
          });
          if (_autoStartBreaks) {
            _startTimer();
          }
        } else {
          _playBreakEndSound();
          setState(() {
            _isBreak = false;
            _remainingSeconds = _workDuration * 60;
          });
          print('Break completed. Starting Work. Remaining: $_remainingSeconds');
          if (_autoStartPomodoros) {
            _startTimer();
          }
        }
      }
    });
  }

  /// Pauses the timer and saves the current session time
  void _pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    print('Timer paused. Remaining: $_remainingSeconds, Session Elapsed: $_sessionElapsedSeconds, Total Elapsed: ${_totalTaskElapsedTime + _sessionElapsedSeconds}, IsBreak: $_isBreak');
    // Update total elapsed time with current session time when paused during a work session
    if (!_isBreak && _sessionElapsedSeconds > 0) {
      _updateTaskPomodoros(addSessionTime: true);
      _sessionElapsedSeconds = 0; // Reset session elapsed time after saving on pause
    }
  }

  /// Resets the timer to initial state
  void _resetTimer() {
    _timer?.cancel();
    _isRunning = false;
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

  /// Shows the timer customization dialog
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

  /// Resets timer settings to default values
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

  /// Shows the task editing dialog
  Future<void> _showEditTaskDialog() async {
    final TextEditingController titleController = TextEditingController(text: widget.task.title);
    DateTime? selectedDeadline = widget.task.dueDate;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Edit Task', style: TextStyle(color: Colors.black)),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                // Deadline Selection
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deadline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDeadline == null
                                  ? 'No deadline set'
                                  : DateFormat('MMM d, yyyy').format(selectedDeadline!),
                              style: TextStyle(
                                color: selectedDeadline == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDeadline ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Colors.blueAccent,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                      dialogBackgroundColor: Colors.white,
                                      textTheme: const TextTheme(
                                        bodyMedium: TextStyle(color: Colors.black87),
                                      ),
                                      buttonTheme: const ButtonThemeData(
                                        textTheme: ButtonTextTheme.primary,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                selectedDeadline = pickedDate;
                                (context as Element).markNeedsBuild();
                              }
                            },
                            icon: Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                            label: const Text('Select Date', style: TextStyle(color: Colors.blueAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final updatedTask = widget.task.copyWith(
                  title: titleController.text,
                  dueDate: selectedDeadline,
                );
                await _firebaseService.updateUserDocument(
                  'projects/${widget.projectId}/tasks',
                  widget.task.id,
                  updatedTask.toMap(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              final confirmDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmDelete == true) {
                await _firebaseService.deleteUserDocument(
                  'projects/${widget.projectId}/tasks',
                  widget.task.id,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Plays a sound to indicate the end of a work session.
  void _playWorkEndSound() async {
    print('Attempting to play work end sound via UrlSource'); // Updated print statement
    // Ensure your sound file is in assets/sounds/ and is a compatible format (e.g., .mp3 or .wav for web)
    // Check browser compatibility for audio formats if running on web.
    try {
      // Using UrlSource for better compatibility on web builds
      await _audioPlayer.play(UrlSource('assets/sounds/task_complete.wav')); // Corrected filename and extension
    } catch (e) {
      print('Error playing work end sound: $e');
    }
  }

  /// Plays a sound to indicate the end of a break session.
  void _playBreakEndSound() async {
    print('Attempting to play break end sound via UrlSource'); // Updated print statement
    // Ensure your sound file is in assets/sounds/ and is a compatible format (e.g., .mp3 or .wav for web)
    // Check browser compatibility for audio formats if running on web.
    try {
      // Using UrlSource for better compatibility on web builds
      await _audioPlayer.play(UrlSource('assets/sounds/break_complete.wav')); // Corrected filename and extension
    } catch (e) {
      print('Error playing break end sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        actions: [
          // Removed Settings and Restore buttons from AppBar
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Task Hub Buttons (Pomodoro Settings, Default, Edit Task)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pomodoro Settings Button (Clock Icon)
                IconButton(
                  icon: const Icon(Icons.timer, size: 32, color: Colors.black87),
                  onPressed: _showCustomizationDialog,
                ),
                const SizedBox(width: 24),
                // Default Button
                IconButton(
                  icon: const Icon(Icons.star, size: 32, color: Colors.black87),
                  onPressed: _setDefaultDuration,
                ),
                const SizedBox(width: 24),
                // Edit Task Button
                IconButton(
                  icon: const Icon(Icons.settings, size: 32, color: Colors.black87),
                  onPressed: _showEditTaskDialog,
                ),
              ],
            ),
            const SizedBox(height: 32), // Space between buttons and timer status
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
                  icon: Icon(_remainingSeconds == 0 ? Icons.play_arrow : (_isRunning ? Icons.pause : Icons.play_arrow)),
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