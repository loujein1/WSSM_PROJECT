import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import './widgets/sidebar_widget.dart';

class AdminPanelScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AdminPanelScreen({super.key, this.user});

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      // Fetch real users from MongoDB through Nest.js API
      final result = await AdminService.getAllUsers();
      
      if (result['success']) {
        setState(() {
          // Convert the API response to a List<Map<String, dynamic>>
          if (result['users'] is List) {
            users = List<Map<String, dynamic>>.from(
              result['users'].map((user) => user is Map ? 
                Map<String, dynamic>.from(user) : 
                {"id": user['_id'] ?? '', "username": user['username'] ?? '', "email": user['email'] ?? '', "role": user['role'] ?? 'user'}
              )
            );
          } else {
            users = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Failed to load users: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(String userId, String currentRole) async {
    // Toggle between 'user' and 'admin' roles
    String newRole = currentRole == 'admin' ? 'user' : 'admin';
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final result = await AdminService.updateUserRole(userId, newRole);
      
      if (result['success']) {
        // Refresh the user list
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User role updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating user role: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete User"),
        content: Text("Are you sure you want to delete this user? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final result = await AdminService.deleteUser(userId);
      
      if (result['success']) {
        // Refresh the user list
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting user: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: "Refresh user list",
          ),
        ],
      ),
      drawer: SidebarWidget(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "User Management",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (isLoading)
                  Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (hasError)
              Container(
                padding: EdgeInsets.all(10),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(child: Text(errorMessage, style: TextStyle(color: Colors.red))),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadUsers,
                      tooltip: "Try again",
                    ),
                  ],
                ),
              ),
            if (hasError) SizedBox(height: 20),
            Expanded(
              child: isLoading && users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final userId = user["id"] ?? user["_id"] ?? '';
                            final username = user["username"] ?? 'Unknown';
                            final email = user["email"] ?? 'No email';
                            final role = user["role"] ?? 'user';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?'),
                                ),
                                title: Text(username),
                                subtitle: Text(email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(
                                        role,
                                        style: TextStyle(
                                          color: role == "admin" ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      backgroundColor: role == "admin" ? Colors.red : Colors.grey[300],
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.swap_horiz),
                                      tooltip: role == "admin" ? "Demote to User" : "Promote to Admin",
                                      onPressed: () => _updateUserRole(userId, role),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      tooltip: "Delete User",
                                      onPressed: () => _deleteUser(userId),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Show user details
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("User Details"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("ID: $userId"),
                                          SizedBox(height: 8),
                                          Text("Username: $username"),
                                          SizedBox(height: 8),
                                          Text("Email: $email"),
                                          SizedBox(height: 8),
                                          Text("Role: $role"),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text("Close"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
} 