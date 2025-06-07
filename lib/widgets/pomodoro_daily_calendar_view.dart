import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../features/pomodoro/domain/repositories/pomodoro_repository.dart'; // Assuming this path
import '../../features/projects/domain/repositories/project_repository.dart'; // Assuming this path

class PomodoroDailyCalendarView extends StatefulWidget {
  const PomodoroDailyCalendarView({Key? key}) : super(key: key);

  @override
  _PomodoroDailyCalendarViewState createState() => _PomodoroDailyCalendarViewState();
}

class _PomodoroDailyCalendarViewState extends State<PomodoroDailyCalendarView> {
  late DateTime _selectedDay;
  // We'll need a structure to hold the events for the timeline.
  // A simple list of maps or custom event objects could work.
  List<Map<String, dynamic>> _completedSessions = [];
  bool _isLoading = false;

  final PomodoroRepository _pomodoroRepository = GetIt.instance.get<PomodoroRepository>();
  final ProjectRepository _projectRepository = GetIt.instance.get<ProjectRepository>();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _fetchCompletedSessions(_selectedDay);
  }

  Future<void> _fetchCompletedSessions(DateTime date) async {
    setState(() {
      _isLoading = true;
      _completedSessions = [];
    });

    try {
      // Fetch completed sessions for the selected date.
      // This will depend on the actual method signature in your PomodoroRepository.
      // I'll assume a method like getCompletedSessionsForDateRange.
      final sessions = await _pomodoroRepository.getPomodoroSessionsForDateRange(
          startDate: DateTime(date.year, date.month, date.day),
          endDate: DateTime(date.year, date.month, date.day, 23, 59, 59));

      List<Map<String, dynamic>> sessionData = [];
      for (var session in sessions) {
         // Assuming session object has fields like 'isCompleted', 'startTime', 'endTime', 'taskId', 'durationMinutes'
        if (session['isCompleted'] == true && session['startTime'] != null && session['endTime'] != null) {
           final task = await _projectRepository.getTask(session['taskId']); // Assuming getTask method
           String taskTitle = task?['title'] ?? 'Unknown Task';
           String? projectColorHex = task?['projectColor']; // Assuming project color is stored with task

           Color eventColor = Colors.blue; // Default color
           if (projectColorHex != null) {
              try {
                 eventColor = Color(int.parse(projectColorHex.replaceAll('#', '0xFF')));
              } catch (e) {
                 print('Error parsing project color: $e');
              }
           }

           sessionData.add({
              'start': DateTime.parse(session['startTime']),
              'end': DateTime.parse(session['endTime']),
              'title': taskTitle,
              'duration': session['durationMinutes'],
              'color': eventColor,
           });
        }
      }

      setState(() {
        _completedSessions = sessionData;
        _isLoading = false;
      });

    } catch (e) {
      print('Error fetching completed sessions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to build the horizontal date selector
  Widget _buildDateSelector() {
     // This is a simplified placeholder. We'll need to build this out
     // to match the image style with days and dates.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        '${_selectedDay.month}/${_selectedDay.day}, ${_selectedDay.weekday == DateTime.monday ? 'Mon' : _selectedDay.weekday == DateTime.tuesday ? 'Tue' : _selectedDay.weekday == DateTime.wednesday ? 'Wed' : _selectedDay.weekday == DateTime.thursday ? 'Thu' : _selectedDay.weekday == DateTime.friday ? 'Fri' : _selectedDay.weekday == DateTime.saturday ? 'Sat' : 'Sun'}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper to build the daily timeline
  Widget _buildTimeline() {
     // This will be the main area showing hours and events.
     // We can use a ListView with custom painting or a package if suitable.
    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedSessions.isEmpty
              ? const Center(child: Text('No completed sessions for this day.'))
              : ListView.builder(
                  itemCount: 24, // Representing 24 hours
                  itemBuilder: (context, index) {
                    final hour = index; // 0-23
                    // TODO: Implement drawing hour markers and positioning session events
                    return Container(
                       height: 60.0, // Height per hour, adjust as needed
                       decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[800]!))
                       ),
                       child: Stack(
                          children: [
                             Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Text(
                                   '${hour.toString().padLeft(2, '0')}:00',
                                   style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                             ),
                             // TODO: Position completed sessions within this hour slot
                             // Placeholder for future session events
                             const SizedBox(),
                          ],
                       )
                    );
                  },
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // This container can define the size and styling of the popup
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black87, // Dark background color
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make the column take minimum space
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16.0),
          // TODO: Add the actual horizontal date selector matching the image
          _buildTimeline(),
        ],
      ),
    );
  }
} 