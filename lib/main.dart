import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'pages/user_list_page.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database connection
  final databaseService = DatabaseService();
  bool connected = await databaseService.connect();
  
  if (kIsWeb) {
    if (connected) {
      print('Successfully connected to PostgreSQL via PostgREST');
      
      // Add a test user if the table is empty
      await databaseService.addTestUserIfEmpty();
    } else {
      print('Failed to connect to PostgreSQL via PostgREST');
      // You might want to show an error dialog or retry logic here
    }
  }
  
  runApp(UserManagementApp(databaseService: databaseService));
}

class UserManagementApp extends StatelessWidget {
  final DatabaseService databaseService;
  
  const UserManagementApp({
    super.key, 
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
          secondary: Colors.tealAccent,
        ),
        useMaterial3: true,
        cardTheme: const CardTheme(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
          secondary: Colors.tealAccent,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: UserListPage(databaseService: databaseService),
    );
  }
}
