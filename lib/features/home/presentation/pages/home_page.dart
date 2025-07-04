import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../bloc/home_bloc.dart';
import '../../../projects/presentation/widgets/projects_overview_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(LoadHomeDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Brain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(RouteConstants.settings);
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(RefreshHomeDataEvent());
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HomeError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is HomeLoaded) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyFocus(state.dailyFocus),
                    _buildProjectsList(state.projects),
                    _buildGoalsList(state.goals),
                  ],
                ),
              );
            }

            return const Center(child: Text('No data available'));
          },
        ),
      ),
      bottomAppBar: _buildBottomAppBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return UserAccountsDrawerHeader(
                  accountName: Text(state.name ?? 'User'),
                  accountEmail: Text(state.email),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: state.photoUrl != null
                        ? NetworkImage(state.photoUrl!)
                        : null,
                    child: state.photoUrl == null
                        ? Text(
                            (state.name?.isNotEmpty == true)
                                ? state.name![0].toUpperCase()
                                : state.email[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                );
              } else {
                return const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Second Brain',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: true,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Projects & Tasks'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.projectList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Pomodoro Timer'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.pomodoro);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.dashboard);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Journal'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.journal);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb),
            title: const Text('Knowledge'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.knowledge);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Goals'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.goals);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Calendar'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.calendar);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RouteConstants.settings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(AuthLogoutEvent());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyFocus(Map<String, dynamic> dailyFocus) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            dailyFocus['greeting'] ?? 'Hello',
            style: Theme.of(context).textTheme.headlineMedium,
              ),
          const SizedBox(height: 8),
                  Text(
            dailyFocus['message'] ?? 'Make it count!',
            style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
    );
  }

  Widget _buildProjectsList(List<Map<String, dynamic>> projects) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ListTile(
          title: Text(project['title'] ?? ''),
          subtitle: Text(project['description'] ?? ''),
          onTap: () {
            // Navigate to project details
          },
        );
      },
    );
  }

  Widget _buildGoalsList(List<Map<String, dynamic>> goals) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return ListTile(
          title: Text(goal['title'] ?? ''),
          subtitle: Text(goal['description'] ?? ''),
          onTap: () {
            context.read<GoalBloc>().add(LoadGoalDetailsEvent(goal['id'] as String));
          },
        );
      },
    );
  }

  Widget _buildTodaysFocus(List<Map<String, dynamic>> topGoals) {
    if (topGoals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Focus',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'You haven\'t set any goals yet. Add goals to track your progress.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Add Goals',
                onPressed: () {
                  Navigator.of(context).pushNamed(RouteConstants.goals);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Focus',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteConstants.goals);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...topGoals.map((goal) => _buildGoalItem(goal)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal) {
    final String title = goal['title'] as String? ?? 'Untitled Goal';
    final String? deadline = goal['deadline'] as String?;
    final String timeFrame = goal['timeFrame'] as String? ?? '';
    final String priority = goal['priority'] as String? ?? 'medium';
    final double? progress = goal['progress'] as double?;

    Color priorityColor;
    if (priority == 'high') {
      priorityColor = Colors.red;
    } else if (priority == 'medium') {
      priorityColor = Colors.orange;
    } else {
      priorityColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          // Navigate to goal details
          context.read<GoalBloc>().add(LoadGoalDetailsEvent(goal['id'] as String));
          Navigator.of(context).pushNamed(RouteConstants.goals);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (timeFrame.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        timeFrame,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toInt()}% complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (deadline != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Due: ${DateFormat('MMM d, yyyy').format(DateTime.parse(deadline))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDeadlineSoon(deadline) ? Colors.red : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedTasks(List<Map<String, dynamic>> suggestedTasks) {
    if (suggestedTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.task_alt, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Suggested Tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'You have no pending tasks. Create a new task to get started.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: 'Add Task',
                onPressed: () {
                  Navigator.of(context).pushNamed(RouteConstants.projectList);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.task_alt, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested Tasks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(RouteConstants.projectList);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...suggestedTasks.map((task) => _buildTaskItem(task)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final String title = task['title'] as String? ?? 'Untitled Task';
    final bool isCompleted = task['isCompleted'] as bool? ?? false;
    final String? dueDate = task['dueDate'] as String?;
    final String priority = task['priority'] as String? ?? 'medium';
    final String? projectName = task['projectName'] as String?;
    final String? projectColor = task['projectColor'] as String?;

    Color priorityColor;
    if (priority == 'high') {
      priorityColor = Colors.red;
    } else if (priority == 'medium') {
      priorityColor = Colors.orange;
    } else {
      priorityColor = Colors.green;
    }

    Color? projectColorValue;
    if (projectColor != null) {
      final colorValue = int.tryParse(projectColor.replaceAll('#', '0xFF'));
      if (colorValue != null) {
        projectColorValue = Color(colorValue);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          // Navigate to task details
          Navigator.of(context).pushNamed(
            RouteConstants.taskDetail,
            arguments: {'taskId': task['id']},
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Checkbox(
                value: isCompleted,
                activeColor: Colors.green,
                onChanged: (bool? value) {
                  // Update task completion status
                  if (value != null) {
                    context.read<ProjectBloc>().add(
                          UpdateTaskEvent(
                            task['id'] as String,
                            {'isCompleted': value},
                          ),
                        );
                    
                    // Refresh home data after updating task
                    Future.delayed(const Duration(milliseconds: 300), () {
                      context.read<HomeBloc>().add(RefreshHomeDataEvent());
                    });
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                    if (projectName != null || dueDate != null)
                      Row(
                        children: [
                          if (projectName != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: projectColorValue?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                projectName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: projectColorValue ?? Colors.blue,
                                ),
                              ),
                            ),
                          ],
                          if (dueDate != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: _isDeadlineSoon(dueDate) ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              DateFormat('MMM d').format(DateTime.parse(dueDate)),
                              style: TextStyle(
                                fontSize: 10,
                                color: _isDeadlineSoon(dueDate) ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (task['completedPomodoros'] != null && (task['completedPomodoros'] as int) > 0) 
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${task['completedPomodoros']} Pomodoros completed',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuote(Map<String, dynamic> dailyFocus) {
    final quotes = dailyFocus['motivationalQuotes'] as List<dynamic>?;
    if (quotes == null || quotes.isEmpty) return const SizedBox.shrink();

    final quote = quotes[0] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_quote, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Daily Inspiration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              quote,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating <= 2.0) {
      return Colors.red;
    } else if (rating <= 3.5) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getRatingIcon(double rating) {
    if (rating <= 2.0) {
      return Icons.sentiment_dissatisfied;
    } else if (rating <= 3.5) {
      return Icons.sentiment_neutral;
    } else {
      return Icons.sentiment_satisfied;
    }
  }

  bool _isDeadlineSoon(String deadlineStr) {
    final deadline = DateTime.parse(deadlineStr);
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Handle tap
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CalendarPage(),
                ),
              );
            },
          ),
          const Expanded(child: SizedBox()),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<ProjectBloc>().add(LoadProjectsEvent());
              Navigator.of(context).pushNamed(RouteConstants.projectList);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle tap
            },
          ),
        ],
      ),
    );
  }
}
