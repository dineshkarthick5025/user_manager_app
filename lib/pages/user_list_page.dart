import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'user_form_page.dart';
import 'user_statistics_page.dart';

class UserListPage extends StatefulWidget {
  final DatabaseService databaseService;
  
  const UserListPage({
    super.key, 
    required this.databaseService,
  });

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> with SingleTickerProviderStateMixin {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _sortField = 'name';
  bool _sortAscending = true;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  // Statistics
  int get _totalUsers => _users.length;
  int get _usersWithRole => _users.where((user) => user.role != null && user.role!.isNotEmpty).length;
  int get _usersWithPhone => _users.where((user) => user.phone != null && user.phone!.isNotEmpty).length;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadUsers();
    _searchController.addListener(_filterUsers);
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              (user.role?.toLowerCase().contains(query) ?? false) ||
              (user.phone?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      _sortUsers();
    });
  }

  void _sortUsers() {
    setState(() {
      _filteredUsers.sort((a, b) {
        dynamic valueA;
        dynamic valueB;
        
        switch (_sortField) {
          case 'name':
            valueA = a.name;
            valueB = b.name;
            break;
          case 'email':
            valueA = a.email;
            valueB = b.email;
            break;
          case 'role':
            valueA = a.role ?? '';
            valueB = b.role ?? '';
            break;
          default:
            valueA = a.name;
            valueB = b.name;
        }
        
        int comparison = valueA.compareTo(valueB);
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      print('Loading users...');
      final users = await widget.databaseService.getUsers();
      print('Loaded ${users.length} users');
      
      setState(() {
        _users = users;
        _filteredUsers = List.from(users);
        _sortUsers();
        _isLoading = false;
      });
      
      _animationController.forward(from: 0);
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchFocused 
            ? null
            : const Text('User Management'),
        leading: _isSearchFocused 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _searchFocusNode.unfocus();
                  setState(() {
                    _isSearchFocused = false;
                  });
                },
              )
            : null,
        actions: [
          // Statistics button
          if (!_isSearchFocused)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserStatisticsPage(
                      totalUsers: _totalUsers,
                      usersWithRole: _usersWithRole,
                      usersWithPhone: _usersWithPhone,
                    ),
                  ),
                );
              },
              tooltip: 'Statistics',
            ),
          
          // Add refresh button
          if (!_isSearchFocused)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
              tooltip: 'Refresh',
            ),
          
          // Add connection status indicator
          if (!_isSearchFocused)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.databaseService.checkConnection() ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.databaseService.checkConnection() ? 'Connected' : 'Disconnected'),
                  ],
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search users by name, email, role, or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                _filterUsers();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Statistics cards
          if (!_isSearchFocused && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.people,
                      title: 'Total Users',
                      value: _totalUsers.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.badge,
                      title: 'With Roles',
                      value: '$_usersWithRole / $_totalUsers',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.phone,
                      title: 'With Phone',
                      value: '$_usersWithPhone / $_totalUsers',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          
          // Sort controls
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Sort by:'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Name'),
                      selected: _sortField == 'name',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortField = 'name';
                            _sortUsers();
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Email'),
                      selected: _sortField == 'email',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortField = 'email';
                            _sortUsers();
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Role'),
                      selected: _sortField == 'role',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortField = 'role';
                            _sortUsers();
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                          _sortUsers();
                        });
                      },
                      tooltip: _sortAscending ? 'Ascending' : 'Descending',
                    ),
                  ],
                ),
              ),
            ),
          
          // Search results count
          if (_searchController.text.isNotEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Found ${_filteredUsers.length} results for "${_searchController.text}"',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Tablet/Desktop layout
                        return _buildGridView();
                      } else {
                        // Mobile layout
                        return _buildListView();
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = 0.5 + (_animationController.value * 0.5);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserFormPage(),
              ),
            );
            if (result == true) {
              await _loadUsers();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add User'),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return _filteredUsers.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              // Add animation with a simple FadeTransition
              return FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index / _filteredUsers.length * 0.7, 
                      (index + 1) / _filteredUsers.length * 0.7,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        if (user.phone != null) 
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 14),
                              const SizedBox(width: 4),
                              Text(user.phone!),
                            ],
                          ),
                        if (user.role != null) 
                          Chip(
                            label: Text(user.role!),
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editUser(user),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteUser(user.id!),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildGridView() {
    return _filteredUsers.isEmpty
        ? _buildEmptyState()
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              // Add animation with a simple FadeTransition
              return FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index / _filteredUsers.length * 0.7, 
                      (index + 1) / _filteredUsers.length * 0.7,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.email,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (user.phone != null) 
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                user.phone!,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        if (user.role != null) 
                          Chip(
                            label: Text(user.role!),
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editUser(user),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteUser(user.id!),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No users found'
                : 'No users match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _filterUsers();
              },
              child: const Text('Clear Search'),
            ),
        ],
      ),
    );
  }

  Future<void> _editUser(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormPage(user: user),
      ),
    );
    if (result == true) {
      await _loadUsers();
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.databaseService.deleteUser(id);
        await _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }
}

















