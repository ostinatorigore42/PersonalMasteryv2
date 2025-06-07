import 'package:flutter/material.dart';
import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_mastery/widgets/pomodoro_daily_calendar_view.dart';
import '../../../pomodoro/domain/repositories/pomodoro_repository.dart';
import '../../../projects/domain/repositories/project_repository.dart';
import '../../../projects/data/models/task_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _weekStart;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  static const int _startHour = 0;
  static const int _endHour = 24;
  static const double _hourHeight = 90.0;

  final PomodoroRepository _pomodoroRepository = GetIt.instance.get<PomodoroRepository>();
  final ProjectRepository _projectRepository = GetIt.instance.get<ProjectRepository>();
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = now;
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('DEBUG: CalendarPage authStateChanges user: \\${user?.uid}');
      if (user != null) {
        _fetchSessionsForDate(_selectedDay);
      } else {
        setState(() {
          _events = [];
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _goToPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _selectedDay = _weekStart;
    });
    _fetchSessionsForDate(_selectedDay);
  }

  void _goToNextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _selectedDay = _weekStart;
    });
    _fetchSessionsForDate(_selectedDay);
  }

  Future<void> _fetchSessionsForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG: _fetchSessionsForDate user: \\${user?.uid}');
    if (user == null) {
      print('WARNING: User not authenticated. Skipping session fetch.');
      setState(() {
        _isLoading = false;
        _events = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _events = [];
    });

    try {
      // Fetch all sessions for the selected day, regardless of isCompleted
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      print('DEBUG: Fetching sessions for user: \\${user.uid} from Firestore');
      final sessions = await _pomodoroRepository.getPomodoroSessionsForDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      print('DEBUG: Fetched \\${sessions.length} sessions for date: $date');

      List<Map<String, dynamic>> dayEvents = [];
      for (var session in sessions) {
        try {
          final taskId = session['taskId'] as String?;
          final projectId = session['projectId'] as String?;
          final startTimeRaw = session['startTime'];
          final endTimeRaw = session['endTime'];
          if (taskId == null || startTimeRaw == null || endTimeRaw == null) {
            print('WARNING: Skipping session due to missing taskId/startTime/endTime: $session');
            continue;
          }
          // Robustly parse startTime and endTime
          DateTime startTime;
          DateTime endTime;
          if (startTimeRaw is Timestamp) {
            startTime = startTimeRaw.toDate();
          } else if (startTimeRaw is DateTime) {
            startTime = startTimeRaw;
          } else if (startTimeRaw is String) {
            startTime = DateTime.parse(startTimeRaw);
          } else {
            print('WARNING: Unrecognized startTime type: \\${startTimeRaw.runtimeType}');
            continue;
          }
          if (endTimeRaw is Timestamp) {
            endTime = endTimeRaw.toDate();
          } else if (endTimeRaw is DateTime) {
            endTime = endTimeRaw;
          } else if (endTimeRaw is String) {
            endTime = DateTime.parse(endTimeRaw);
          } else {
            print('WARNING: Unrecognized endTime type: \\${endTimeRaw.runtimeType}');
            continue;
          }
          // Get task details using the project repository
          final task = await _projectRepository.getTask(taskId);
          String title = session['taskTitle'] as String? ?? 'Unknown Task';
          String? projectColor = session['projectColor'] as String?;
          if (task != null && task['title'] != null) {
            title = task['title'] as String;
            if (task['projectColor'] != null) {
              projectColor = task['projectColor'] as String;
            } else if (task['color'] != null) {
              projectColor = task['color'] as String;
            }
          } else {
            print('WARNING: Task not found for session, using fallback title: $session');
          }
          // Parse color
          Color color = Colors.blueAccent;
          if (projectColor != null && projectColor.isNotEmpty) {
            try {
              color = Color(int.parse(projectColor.replaceAll('#', '0xFF')));
            } catch (e) {
              print('WARNING: Could not parse projectColor: $projectColor');
            }
          } else if (session['isOrganic'] == false) {
            color = Colors.orangeAccent;
          }
          dayEvents.add({
            'startTime': startTime,
            'endTime': endTime,
            'title': title,
            'isOrganic': session['isOrganic'] ?? true, // fallback to true if not present
            'color': color,
          });
        } catch (e) {
          print('Error processing session: $e');
          continue;
        }
      }
      print('DEBUG: FINAL mapped dayEvents: ' + dayEvents.map((e) => e.toString()).join(', '));

      if (mounted) {
        setState(() {
          _events = dayEvents;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Error fetching sessions: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTimeGrid(List<Map<String, dynamic>> sessions) {
    final now = DateTime.now();
    final startHour = _startHour;
    final endHour = _endHour;
    final hourHeight = _hourHeight;
    final timeSlots = List.generate(endHour - startHour, (i) => startHour + i);
    final totalHeight = hourHeight * (endHour - startHour);

    // Helper to get current time position
    double? getCurrentTimePosition() {
      if (_selectedDay.year == now.year && _selectedDay.month == now.month && _selectedDay.day == now.day) {
        final minutesSinceStart = (now.hour - startHour) * 60 + now.minute;
        return minutesSinceStart * (hourHeight / 60) + 24; // 24px offset for first item
      }
      return null;
    }
    final currentTimePosition = getCurrentTimePosition();

    // Helper to get session block position and height
    List<Widget> buildSessionBlocks() {
      List<Widget> blocks = [];
      for (final session in sessions) {
        debugPrint('BUILDING SESSION BLOCK: \\${session.toString()}');
        final start = (session['startTime'] as DateTime);
        final end = (session['endTime'] as DateTime);
        final title = session['title'] as String? ?? 'Session';
        final isOrganic = session['isOrganic'] == true;
        final color = session['color'] as Color? ?? (isOrganic ? Colors.blueAccent : Colors.orangeAccent);
        final startMinutes = (start.hour - startHour) * 60 + start.minute;
        final endMinutes = (end.hour - startHour) * 60 + end.minute;
        final top = startMinutes * (hourHeight / 60);
        final minHeight = 4.0; // allow very short blocks
        final height = ((endMinutes - startMinutes) * (hourHeight / 60)).clamp(minHeight, double.infinity);
        final showFullContent = height >= 40.0;
        debugPrint('Session block height: ' + height.toString());
        blocks.add(Positioned(
          left: 64,
          right: 16,
          top: top,
          height: height,
          child: GestureDetector(
            onTap: () {
              _showEditSessionDialog(context, session);
            },
            child: Tooltip(
              message: '$title\n${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
                '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
              waitDuration: const Duration(milliseconds: 400),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                margin: EdgeInsets.zero,
                alignment: Alignment.topLeft,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double titleFontSize = 14;
                    const double timeFontSize = 12;
                    const double verticalPadding = 8;
                    final double twoLinesHeight = titleFontSize + timeFontSize + verticalPadding + 2; // 2 for SizedBox
                    final double oneLineHeight = titleFontSize + verticalPadding / 2;
                    if (constraints.maxHeight >= twoLinesHeight + 8) { // Add a little extra buffer
                      // Show both title and time range, left-aligned in a centered/wide block
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                              '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
                              '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    } else if (constraints.maxHeight >= oneLineHeight) {
                      // Show only title, left-aligned in a centered/wide block
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                    } else {
                      // Show minimal indicator (colored bar)
                      return Container(
                        width: double.infinity,
                        height: constraints.maxHeight,
                        color: Colors.transparent,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ));
      }
      return blocks;
    }

    return SingleChildScrollView(
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Time grid lines and labels
            ...List.generate(timeSlots.length, (i) {
              final hour = timeSlots[i];
              return Positioned(
                top: i * hourHeight,
                left: 0,
                right: 0,
                height: hourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.only(top: 0),
                          child: Transform.translate(
                            offset: Offset(0, -8),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white12,
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Session blocks
            ...buildSessionBlocks(),
            // Current time red line
            if (currentTimePosition != null)
              Positioned(
                left: 56,
                right: 24,
                top: currentTimePosition,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23232B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23232B),
        elevation: 0,
        title: const Text('Calendar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week selector with left/right buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _goToPreviousWeek,
                ),
                Expanded(
                  child: SizedBox(
                    height: 90,
                    child: Row(
                      children: List.generate(7, (index) {
                        final day = _weekStart.add(Duration(days: index));
                        final isSelected = _selectedDay.year == day.year && _selectedDay.month == day.month && _selectedDay.day == day.day;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _selectedDay = day;
                                });
                                _fetchSessionsForDate(day);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [Color(0xFFFF9800), Color(0xFFD32F2F)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : const Color(0xFF2C2C36),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFF9800).withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected ? Colors.white : const Color(0xFFB0B0B0),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      day.day.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFFEEEEEE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _goToNextWeek,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Text(
              '${_monthName(_selectedDay.month)} ${_selectedDay.day}, ${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][_selectedDay.weekday - 1]}',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _buildTimeGrid(_events)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _showManualSessionDialog(context);
        },
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<List<Map<String, dynamic>>> _fetchProjectsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchTasksFromFirestore(String projectId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _showManualSessionDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String? selectedTaskId;
    String? selectedProjectId;
    DateTime? startTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 8, 0);
    DateTime? endTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 9, 0);
    bool isOrganic = true;
    List<Map<String, dynamic>> tasks = [];
    List<Map<String, dynamic>> projects = [];
    final uuid = Uuid();
    try {
      projects = await _fetchProjectsFromFirestore();
      if (projects.isNotEmpty) {
        selectedProjectId = projects.first['id'] as String?;
        if (selectedProjectId != null) {
          tasks = await _fetchTasksFromFirestore(selectedProjectId);
          if (tasks.isNotEmpty) {
            selectedTaskId = tasks.first['id'] as String?;
          }
        }
      }
    } catch (e) {
      print('Error fetching projects/tasks from Firestore: $e');
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final projectItems = projects.map((proj) => proj['id'] as String?).where((id) => id != null).toList();
            final taskItems = tasks.map((task) => task['id'] as String?).where((id) => id != null).toList();
            if (selectedProjectId != null && !projectItems.contains(selectedProjectId)) {
              selectedProjectId = projectItems.isNotEmpty ? projectItems.first : null;
            }
            if (selectedTaskId != null && !taskItems.contains(selectedTaskId)) {
              selectedTaskId = taskItems.isNotEmpty ? taskItems.first : null;
            }
            final noProjects = projects.isEmpty;
            final noTasks = tasks.isEmpty;
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C36),
              title: const Text('Log Manual Session', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (noProjects)
                      const Text('No projects found. Please create a project first.', style: TextStyle(color: Colors.white70)),
                    if (!noProjects)
                      DropdownButtonFormField<String>(
                        value: selectedProjectId,
                        dropdownColor: const Color(0xFF23232B),
                        decoration: const InputDecoration(labelText: 'Project', labelStyle: TextStyle(color: Colors.white70)),
                        items: projects.map((proj) => DropdownMenuItem(
                          value: proj['id'] as String?,
                          child: Text((proj['name'] as String?) ?? (proj['title'] as String?) ?? 'Untitled', style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: projects.isEmpty ? null : (val) async {
                          setState(() {
                            selectedProjectId = val;
                            selectedTaskId = null;
                          });
                          if (val != null) {
                            final t = await _fetchTasksFromFirestore(val);
                            setState(() {
                              tasks = t;
                              selectedTaskId = (tasks.isNotEmpty) ? tasks.first['id'] as String? : null;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    if (noTasks && !noProjects)
                      const Text('No tasks found for this project. Please create a task first.', style: TextStyle(color: Colors.white70)),
                    if (!noTasks && !noProjects)
                      DropdownButtonFormField<String>(
                        value: selectedTaskId,
                        dropdownColor: const Color(0xFF23232B),
                        decoration: const InputDecoration(labelText: 'Task', labelStyle: TextStyle(color: Colors.white70)),
                        items: tasks.map((task) => DropdownMenuItem(
                          value: task['id'] as String?,
                          child: Text((task['title'] as String?) ?? 'Untitled', style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: tasks.isEmpty ? null : (val) => setState(() => selectedTaskId = val),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: noProjects || noTasks ? null : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startTime!),
                              );
                              if (picked != null) {
                                setState(() {
                                  startTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, picked.hour, picked.minute);
                                });
                              }
                            },
                            child: Text('Start: ${startTime != null ? startTime!.hour.toString().padLeft(2, '0') + ':' + startTime!.minute.toString().padLeft(2, '0') : '--:--'}', style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: noProjects || noTasks ? null : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(endTime!),
                              );
                              if (picked != null) {
                                setState(() {
                                  endTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, picked.hour, picked.minute);
                                });
                              }
                            },
                            child: Text('End: ${endTime != null ? endTime!.hour.toString().padLeft(2, '0') + ':' + endTime!.minute.toString().padLeft(2, '0') : '--:--'}', style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: isOrganic,
                          onChanged: noProjects || noTasks ? null : (val) => setState(() => isOrganic = val ?? true),
                          activeColor: Colors.blueAccent,
                        ),
                        const Text('Organic (not force-stopped)', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: noProjects || noTasks || selectedTaskId == null || startTime == null || endTime == null || startTime!.isAfter(endTime!)
                      ? null
                      : () async {
                    try {
                      final sessionId = uuid.v4();
                      // Find the selected project's color
                      String? selectedProjectColor;
                      if (selectedProjectId != null) {
                        final project = projects.firstWhere(
                          (proj) => proj['id'] == selectedProjectId,
                          orElse: () => <String, dynamic>{},
                        );
                        if (project != null && project['color'] != null) {
                          selectedProjectColor = project['color'] as String?;
                        }
                      }
                      final sessionData = {
                        'taskId': selectedTaskId,
                        'projectId': selectedProjectId,
                        'startTime': Timestamp.fromDate(startTime!),
                        'endTime': Timestamp.fromDate(endTime!),
                        'isOrganic': isOrganic,
                        'isCompleted': true,
                        'durationMinutes': endTime!.difference(startTime!).inMinutes,
                        'createdManually': true,
                        if (selectedProjectColor != null) 'projectColor': selectedProjectColor,
                      };
                      // Write to flat collection with sessionId as doc ID
                      await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('pomodoroSessions')
                        .doc(sessionId)
                        .set(sessionData);
                      // Write to legacy subcollection with sessionId as doc ID
                      await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('projects')
                        .doc(selectedProjectId)
                        .collection('tasks')
                        .doc(selectedTaskId)
                        .collection('sessions')
                        .doc(sessionId)
                        .set(sessionData);
                      // Update task's completedPomodoros and pomodoroSessionIds and elapsedTime
                      if (selectedTaskId != null) {
                        final taskDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('projects')
                          .doc(selectedProjectId)
                          .collection('tasks')
                          .doc(selectedTaskId)
                          .get();
                        if (taskDoc.exists) {
                          final task = taskDoc.data()!;
                          final pomodoroSessionIds = (task['pomodoroSessionIds'] as List<dynamic>?)?.cast<String>() ?? [];
                          final prevElapsed = (task['elapsedTime'] as int?) ?? 0;
                          final sessionSeconds = endTime!.difference(startTime!).inSeconds;
                          if (!pomodoroSessionIds.contains(sessionId)) {
                            await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('projects')
                              .doc(selectedProjectId)
                              .collection('tasks')
                              .doc(selectedTaskId)
                              .update({
                                'pomodoroSessionIds': [...pomodoroSessionIds, sessionId],
                                'completedPomodoros': (task['completedPomodoros'] as int? ?? 0) + 1,
                                'elapsedTime': prevElapsed + sessionSeconds,
                                'updatedAt': DateTime.now().toIso8601String(),
                              });
                          }
                        }
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session logged successfully!')));
                        _fetchSessionsForDate(_selectedDay);
                      }
                    } catch (e) {
                      print('Error logging manual session: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to log session.')));
                      }
                    }
                  },
                  child: const Text('Log'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditSessionDialog(BuildContext context, Map<String, dynamic> session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String? selectedProjectId = session['projectId'] as String?;
    String? selectedTaskId = session['taskId'] as String?;
    DateTime? startTime = (session['startTime'] as DateTime?);
    DateTime? endTime = (session['endTime'] as DateTime?);
    bool isOrganic = session['isOrganic'] == true;
    List<Map<String, dynamic>> projects = [];
    List<Map<String, dynamic>> tasks = [];
    try {
      projects = await _fetchProjectsFromFirestore();
      if (selectedProjectId != null) {
        tasks = await _fetchTasksFromFirestore(selectedProjectId);
      }
    } catch (e) {
      print('Error fetching projects/tasks for edit: $e');
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final projectItems = projects.map((proj) => proj['id'] as String?).where((id) => id != null).toList();
            final taskItems = tasks.map((task) => task['id'] as String?).where((id) => id != null).toList();
            if (selectedProjectId != null && !projectItems.contains(selectedProjectId)) {
              selectedProjectId = projectItems.isNotEmpty ? projectItems.first : null;
            }
            if (selectedTaskId != null && !taskItems.contains(selectedTaskId)) {
              selectedTaskId = taskItems.isNotEmpty ? taskItems.first : null;
            }
            final noProjects = projects.isEmpty;
            final noTasks = tasks.isEmpty;
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C36),
              title: const Text('Edit Session', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (noProjects)
                      const Text('No projects found.', style: TextStyle(color: Colors.white70)),
                    if (!noProjects)
                      DropdownButtonFormField<String>(
                        value: selectedProjectId,
                        dropdownColor: const Color(0xFF23232B),
                        decoration: const InputDecoration(labelText: 'Project', labelStyle: TextStyle(color: Colors.white70)),
                        items: projects.map((proj) => DropdownMenuItem(
                          value: proj['id'] as String?,
                          child: Text((proj['name'] as String?) ?? (proj['title'] as String?) ?? 'Untitled', style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: projects.isEmpty ? null : (val) async {
                          setState(() {
                            selectedProjectId = val;
                            selectedTaskId = null;
                          });
                          if (val != null) {
                            final t = await _fetchTasksFromFirestore(val);
                            setState(() {
                              tasks = t;
                              selectedTaskId = (tasks.isNotEmpty) ? tasks.first['id'] as String? : null;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    if (noTasks && !noProjects)
                      const Text('No tasks found for this project.', style: TextStyle(color: Colors.white70)),
                    if (!noTasks && !noProjects)
                      DropdownButtonFormField<String>(
                        value: selectedTaskId,
                        dropdownColor: const Color(0xFF23232B),
                        decoration: const InputDecoration(labelText: 'Task', labelStyle: TextStyle(color: Colors.white70)),
                        items: tasks.map((task) => DropdownMenuItem(
                          value: task['id'] as String?,
                          child: Text((task['title'] as String?) ?? 'Untitled', style: const TextStyle(color: Colors.white)),
                        )).toList(),
                        onChanged: tasks.isEmpty ? null : (val) => setState(() => selectedTaskId = val),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: noProjects || noTasks ? null : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startTime!),
                              );
                              if (picked != null) {
                                setState(() {
                                  startTime = DateTime(startTime!.year, startTime!.month, startTime!.day, picked.hour, picked.minute);
                                });
                              }
                            },
                            child: Text('Start: ${startTime != null ? startTime!.hour.toString().padLeft(2, '0') + ':' + startTime!.minute.toString().padLeft(2, '0') : '--:--'}', style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: noProjects || noTasks ? null : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(endTime!),
                              );
                              if (picked != null) {
                                setState(() {
                                  endTime = DateTime(endTime!.year, endTime!.month, endTime!.day, picked.hour, picked.minute);
                                });
                              }
                            },
                            child: Text('End: ${endTime != null ? endTime!.hour.toString().padLeft(2, '0') + ':' + endTime!.minute.toString().padLeft(2, '0') : '--:--'}', style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: isOrganic,
                          onChanged: noProjects || noTasks ? null : (val) => setState(() => isOrganic = val ?? true),
                          activeColor: Colors.blueAccent,
                        ),
                        const Text('Organic (not force-stopped)', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () async {
                    // Delete session from both collections
                    try {
                      // Remove from flat collection
                      await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('pomodoroSessions')
                        .doc(session['id'] ?? session['sessionId'])
                        .delete();
                      // Remove from legacy subcollection
                      if (selectedProjectId != null && selectedTaskId != null) {
                        await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('projects')
                          .doc(selectedProjectId)
                          .collection('tasks')
                          .doc(selectedTaskId)
                          .collection('sessions')
                          .doc(session['id'] ?? session['sessionId'])
                          .delete();
                        // Update task stats (decrement completedPomodoros, subtract elapsedTime, remove sessionId)
                        final taskDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('projects')
                          .doc(selectedProjectId)
                          .collection('tasks')
                          .doc(selectedTaskId)
                          .get();
                        if (taskDoc.exists) {
                          final task = taskDoc.data()!;
                          final pomodoroSessionIds = (task['pomodoroSessionIds'] as List<dynamic>?)?.cast<String>() ?? [];
                          final completedPomodoros = (task['completedPomodoros'] as int? ?? 1) - 1;
                          final prevElapsed = (task['elapsedTime'] as int?) ?? 0;
                          final sessionSeconds = endTime!.difference(startTime!).inSeconds;
                          await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('projects')
                            .doc(selectedProjectId)
                            .collection('tasks')
                            .doc(selectedTaskId)
                            .update({
                              'pomodoroSessionIds': pomodoroSessionIds.where((id) => id != (session['id'] ?? session['sessionId'])).toList(),
                              'completedPomodoros': completedPomodoros < 0 ? 0 : completedPomodoros,
                              'elapsedTime': prevElapsed - sessionSeconds < 0 ? 0 : prevElapsed - sessionSeconds,
                              'updatedAt': DateTime.now().toIso8601String(),
                            });
                        }
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted.')));
                        _fetchSessionsForDate(_selectedDay);
                      }
                    } catch (e) {
                      print('Error deleting session: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete session.')));
                      }
                    }
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: noProjects || noTasks || selectedTaskId == null || startTime == null || endTime == null || startTime!.isAfter(endTime!)
                      ? null
                      : () async {
                    try {
                      final sessionId = session['id'] ?? session['sessionId'];
                      final sessionData = {
                        'taskId': selectedTaskId,
                        'projectId': selectedProjectId,
                        'startTime': Timestamp.fromDate(startTime!),
                        'endTime': Timestamp.fromDate(endTime!),
                        'isOrganic': isOrganic,
                        'isCompleted': true,
                        'durationMinutes': endTime!.difference(startTime!).inMinutes,
                        'createdManually': session['createdManually'] ?? true,
                        'id': sessionId,
                      };
                      // Update flat collection
                      await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('pomodoroSessions')
                        .doc(sessionId)
                        .set(sessionData);
                      // Update legacy subcollection
                      await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('projects')
                        .doc(selectedProjectId)
                        .collection('tasks')
                        .doc(selectedTaskId)
                        .collection('sessions')
                        .doc(sessionId)
                        .set(sessionData);
                      // Update task's completedPomodoros and pomodoroSessionIds and elapsedTime
                      if (selectedTaskId != null) {
                        final taskDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('projects')
                          .doc(selectedProjectId)
                          .collection('tasks')
                          .doc(selectedTaskId)
                          .get();
                        if (taskDoc.exists) {
                          final task = taskDoc.data()!;
                          final pomodoroSessionIds = (task['pomodoroSessionIds'] as List<dynamic>?)?.cast<String>() ?? [];
                          final prevElapsed = (task['elapsedTime'] as int?) ?? 0;
                          final sessionSeconds = endTime!.difference(startTime!).inSeconds;
                          if (!pomodoroSessionIds.contains(sessionId)) {
                            await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('projects')
                              .doc(selectedProjectId)
                              .collection('tasks')
                              .doc(selectedTaskId)
                              .update({
                                'pomodoroSessionIds': [...pomodoroSessionIds, sessionId],
                                'completedPomodoros': (task['completedPomodoros'] as int? ?? 0) + 1,
                                'elapsedTime': prevElapsed + sessionSeconds,
                                'updatedAt': DateTime.now().toIso8601String(),
                              });
                          } else {
                            // If already present, just update elapsedTime if needed
                            await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('projects')
                              .doc(selectedProjectId)
                              .collection('tasks')
                              .doc(selectedTaskId)
                              .update({
                                'elapsedTime': prevElapsed + sessionSeconds,
                                'updatedAt': DateTime.now().toIso8601String(),
                              });
                          }
                        }
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session updated.')));
                        _fetchSessionsForDate(_selectedDay);
                      }
                    } catch (e) {
                      print('Error updating session: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update session.')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 