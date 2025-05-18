import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/route_constants.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/goals/presentation/bloc/goal_bloc.dart';
import 'features/goals/presentation/pages/goals_page.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/journal/presentation/bloc/journal_bloc.dart';
import 'features/journal/presentation/pages/journal_page.dart';
import 'features/knowledge/presentation/bloc/knowledge_bloc.dart';
import 'features/knowledge/presentation/pages/flashcards_page.dart';
import 'features/knowledge/presentation/pages/knowledge_page.dart';
import 'features/knowledge/presentation/pages/principles_page.dart';
import 'features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'features/pomodoro/presentation/pages/pomodoro_page.dart';
import 'features/projects/presentation/bloc/project_bloc.dart';
import 'features/projects/presentation/pages/project_detail_page.dart';
import 'features/projects/presentation/pages/project_list_page.dart';
import 'features/projects/presentation/pages/task_detail_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class SecondBrainApp extends StatelessWidget {
  const SecondBrainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: GetIt.instance.get(),
          )..add(AuthCheckStatusEvent()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(
            homeRepository: GetIt.instance.get(),
          ),
        ),
        BlocProvider<ProjectBloc>(
          create: (context) => ProjectBloc(
            projectRepository: GetIt.instance.get(),
          ),
        ),
        BlocProvider<PomodoroBloc>(
          create: (context) => PomodoroBloc(
            pomodoroRepository: GetIt.instance.get(),
          ),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(
            dashboardRepository: GetIt.instance.get(),
          ),
        ),
        BlocProvider<JournalBloc>(
          create: (context) => JournalBloc(
            journalRepository: GetIt.instance.get(),
          ),
        ),
        BlocProvider<KnowledgeBloc>(
          create: (context) => KnowledgeBloc(
            knowledgeRepository: GetIt.instance.get(),
          ),
        ),
        BlocProvider<GoalBloc>(
          create: (context) => GoalBloc(
            goalRepository: GetIt.instance.get(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Second Brain',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          brightness: Brightness.light,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          brightness: Brightness.dark,
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: RouteConstants.initial,
        routes: {
          RouteConstants.initial: (context) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return const HomePage();
                } else if (state is AuthUnauthenticated) {
                  return const LoginPage();
                } else {
                  // Show loading or splash screen
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            );
          },
          RouteConstants.login: (context) => const LoginPage(),
          RouteConstants.register: (context) => const RegisterPage(),
          RouteConstants.home: (context) => const HomePage(),
          RouteConstants.projectList: (context) => const ProjectListPage(),
          RouteConstants.projectDetail: (context) => const ProjectDetailPage(),
          RouteConstants.taskDetail: (context) => const TaskDetailPage(),
          RouteConstants.pomodoro: (context) => const PomodoroPage(),
          RouteConstants.dashboard: (context) => const DashboardPage(),
          RouteConstants.journal: (context) => const JournalPage(),
          RouteConstants.knowledge: (context) => const KnowledgePage(),
          RouteConstants.principles: (context) => const PrinciplesPage(),
          RouteConstants.flashcards: (context) => const FlashcardsPage(),
          RouteConstants.goals: (context) => const GoalsPage(),
          RouteConstants.settings: (context) => const SettingsPage(),
        },
      ),
    );
  }
}
