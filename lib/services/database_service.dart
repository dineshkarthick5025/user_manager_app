import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import '../models/user.dart';

class DatabaseService {
  late PostgreSQLConnection _connection;
  bool isConnected = false;
  
  // PostgREST API URL - update this to match your PostgREST server
  final String _apiUrl = 'http://localhost:3000';
  
  Future<bool> connect() async {
    try {
      if (kIsWeb) {
        // For web, check if PostgREST is accessible
        final response = await http.get(Uri.parse('$_apiUrl/users?limit=1'));
        isConnected = response.statusCode == 200;
        return isConnected;
      } else {
        // For desktop/mobile, use direct PostgreSQL connection
        _connection = PostgreSQLConnection(
          "localhost",
          5432,
          "user_management",
          username: "postgres",
          password: "admin",
        );
        
        await _connection.open();
        isConnected = true;
        
        // Create table if not exists
        await _connection.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            age INTEGER NOT NULL
          )
        ''');
        
        return true;
      }
    } catch (e) {
      isConnected = false;
      print('Database connection error: $e');
      return false;
    }
  }

  bool checkConnection() {
    return isConnected;
  }
  
  Future<List<User>> getUsers() async {
    if (kIsWeb) {
      // Use PostgREST for web
      try {
        print('Fetching users from PostgREST...');
        final response = await http.get(
          Uri.parse('$_apiUrl/users?order=id.asc'),
          headers: {'Accept': 'application/json'},
        );
        
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          if (response.body.isEmpty) {
            print('Response body is empty, returning empty list');
            return [];
          }
          
          final List<dynamic> data = json.decode(response.body);
          print('Parsed data: $data');
          
          return data.map((item) => User(
            id: item['id'],
            name: item['name'],
            email: item['email'],
            phone: item['phone'],
            role: item['role'],
          )).toList();
        } else {
          throw Exception('Failed to load users: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching users: $e');
        rethrow;
      }
    } else {
      // Use direct PostgreSQL for non-web
      final results = await _connection.query('SELECT * FROM users ORDER BY id');
      return results.map((row) {
        return User(
          id: row[0] as int,
          name: row[1] as String,
          email: row[2] as String,
          phone: row[3] as String?,
          role: row[4] as String?,
        );
      }).toList();
    }
  }

  Future<User> addUser(User user) async {
    if (kIsWeb) {
      // Use PostgREST for web
      final response = await http.post(
        Uri.parse('$_apiUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: json.encode({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'role': user.role,
        }),
      );
      
      if (response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body);
        return user.copyWith(id: data[0]['id']);
      } else {
        throw Exception('Failed to add user: ${response.statusCode}');
      }
    } else {
      // Use direct PostgreSQL for non-web
      final results = await _connection.query(
        'INSERT INTO users (name, email, phone, role) VALUES (@name, @email, @phone, @role) RETURNING id',
        substitutionValues: {
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'role': user.role,
        },
      );
      
      return user.copyWith(id: results[0][0] as int);
    }
  }

  Future<void> updateUser(User user) async {
    if (kIsWeb) {
      // Use PostgREST for web
      final response = await http.patch(
        Uri.parse('$_apiUrl/users?id=eq.${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'role': user.role,
        }),
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } else {
      // Use direct PostgreSQL for non-web
      await _connection.execute(
        'UPDATE users SET name = @name, email = @email, phone = @phone, role = @role WHERE id = @id',
        substitutionValues: {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'role': user.role,
        },
      );
    }
  }

  Future<void> addTestUserIfEmpty() async {
    try {
      final users = await getUsers();
      
      if (users.isEmpty) {
        print('No users found, adding test user');
        await addUser(User(
          name: 'Test User',
          email: 'test@example.com',
          phone: '1234567890',
          role: 'User',
        ));
        print('Test user added successfully');
      } else {
        print('Users already exist, not adding test user');
      }
    } catch (e) {
      print('Error adding test user: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    if (kIsWeb) {
      // Use PostgREST for web
      final response = await http.delete(
        Uri.parse('$_apiUrl/users?id=eq.$id'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } else {
      // Use direct PostgreSQL for non-web
      await _connection.execute(
        'DELETE FROM users WHERE id = @id',
        substitutionValues: {'id': id},
      );
    }
  }
}



