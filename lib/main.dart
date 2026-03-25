import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/database_helper.dart';

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


class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Workouts\nCreate & Manage Plans', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      );
}

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Progress\nCharts & Statistics', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      );
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

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

          // Dark Mode Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dark Mode', style: TextStyle(fontSize: 20)),
              Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) => themeProvider.toggleTheme(),
                activeColor: Colors.blue,
              ),
            ],
          ),

          const Divider(height: 50),


          // Data Export Function
          const ListTile(
            leading: Icon(Icons.file_download_outlined),
            title: Text('Export Workout Data'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),

          // Biometric Login Switch
          const ListTile(
            leading: Icon(Icons.fingerprint),
            title: Text('Enable Biometric Login'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}