import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialanxiteam_project1/models/workout_plan.dart';
import 'database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'services/biometric_service.dart';

bool _isAuthenticated = false;

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

//Theme Provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

//Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Fitness Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

//Main Screen with Bottom Tabs
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    WorkoutsTab(),
    ProgressTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: Colors.black, width: 2.0) // tottom black border
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black, width: 3.0), // top black border
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [                  // const tabs at the bottom
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Workouts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

//Const Contents of Each Tabs
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int _streak = 0;
  bool _hasCheckedInToday = false;
  List<String> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }


    // 加载打卡数据（streak + 今天是否已打卡 + 历史记录）
  Future<void> _loadData() async {
    final streak = await _dbHelper.getCurrentStreak();
    final history = await _dbHelper.getCheckInHistory();
    final today = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      _streak = streak;
      _history = history;
      _hasCheckedInToday = history.contains(today);
      _isLoading = false;
    });
  }


  Future<void> _handleCheckIn() async {
    final success = await _dbHelper.chekcInToday();


    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Check-in successful! Keep the streak going!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already checked in today!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 30),

        // Current Checkin Streak
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.deepOrange, width: 3),
          ),
          child: Column(
            children: [
              const Text(
                '🔥 Current Streak',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$_streak days',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 50),

        // Check-in Button
        ElevatedButton.icon(
          onPressed: _hasCheckedInToday ? null : _handleCheckIn,
          icon: const Icon(Icons.check_circle_outline, size: 32),
          label: Text(
            _hasCheckedInToday ? 'Already Checked In Today ✓' : 'Check-in Today',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
            backgroundColor: _hasCheckedInToday ? Colors.grey : Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        const SizedBox(height: 40),


        const Text(
          'Recent Check-ins',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),


        Expanded(
          child: _history.isEmpty
              ? const Center(child: Text('No check-in records yet.\nStart your streak today!'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.green),
                        title: Text(_history[index]),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

}




class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<WorkoutPlan> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final workouts = await _dbHelper.getAllWorkouts();
    setState(() {
      _workouts = workouts;
      _isLoading = false;
    });
  }


  Future<void> _addWorkout() async {
    final nameController = TextEditingController();
    final exercisesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Add New Workout Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Plan Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: exercisesController,
              decoration: const InputDecoration(labelText: 'Exercises (e.g. Push-ups, Squats)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final newPlan = WorkoutPlan(
                name: nameController.text.trim(),
                exercises: exercisesController.text.trim().isEmpty 
                    ? 'General Workout' 
                    : exercisesController.text.trim(),
                sets: 3,
                reps: 10,
                restTime: 60,
                createdAt: DateTime.now(),
              );

              await _dbHelper.insertWorkout(newPlan);
              Navigator.pop(dialogContext);
              _loadWorkouts();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout Plan Added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _workouts.isEmpty
          ? const Center(
              child: Text(
                'No workout plans yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _workouts.length,
              itemBuilder: (context, index) {
                final plan = _workouts[index];
                return ListTile(
                  title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${plan.exercises} • ${plan.sets} sets × ${plan.reps} reps'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _dbHelper.deleteWorkout(plan.id!);
                      _loadWorkouts();
                    },
                  ),
                  onLongPress: () async {
                    await _dbHelper.deleteWorkout(plan.id!);
                    _loadWorkouts();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWorkout,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Progress Tab

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<BarChartGroupData> _barGroups = [];
  bool _isLoading = true;
  int _totalThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    final history = await _dbHelper.getCheckInHistory();


    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      final date = now.subtract(Duration(days: index));
      final dateStr = date.toIso8601String().split('T')[0];
      final count = history.where((d) => d == dateStr).length;
      return {'day': _getDayName(date.weekday), 'count': count};
    }).reversed.toList();

    setState(() {
      _barGroups = last7Days.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: (data['count'] as num).toDouble(),
              color: Colors.blue,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        );
      }).toList();

      _totalThisWeek = last7Days.fold(0, (sum, item) => sum + (item['count'] as int));
      _isLoading = false;
    });
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Workout Progress',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total this week: $_totalThisWeek workouts',
            style: const TextStyle(fontSize: 18, color: Colors.blue),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 7,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(days[value.toInt()]);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _barGroups,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Keep going! Your consistency is building 🔥',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Tab
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    setState(() {
      _biometricEnabled = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final available = await BiometricService.isBiometricAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric is not available on this device')),
          );
        }
        return;
      }

      final success = await BiometricService.authenticate();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication failed')),
          );
        }
        return;
      }
    }

    setState(() {
      _biometricEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value 
              ? '✅ Biometric Login Enabled' 
              : 'Biometric Login Disabled'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),

          // Dark Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dark Mode', style: TextStyle(fontSize: 20)),
              Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) => themeProvider.toggleTheme(),
              ),
            ],
          ),

          const Divider(height: 50),

          // Biometric Login
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Colors.green, size: 32),
            title: const Text('Enable Biometric Login', style: TextStyle(fontSize: 18)),
            subtitle: const Text('Use Face ID or Fingerprint to unlock app'),
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),

          const Divider(height: 40),

          // Data Export
          ListTile(
            leading: const Icon(Icons.file_download_outlined, color: Colors.blue, size: 30),
            title: const Text('Export Workout Data', style: TextStyle(fontSize: 18)),
            subtitle: const Text('Save all plans as JSON file'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final workouts = await DatabaseHelper.instance.getAllWorkouts();
              final jsonString = jsonEncode(workouts.map((w) => w.toMap()).toList());

              final directory = await getApplicationDocumentsDirectory();
              final file = File('${directory.path}/fitness_backup_${DateTime.now().toIso8601String().split('T')[0]}.json');

              await file.writeAsString(jsonString);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data exported to: ${file.path}')),
                );
              }
            },
          ),

        ],
      ),
    );
  }
}