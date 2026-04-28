import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/role.dart';
import '../services/app_state.dart';
import 'dashboards/admin_dashboard.dart';
import 'dashboards/doctor_dashboard.dart';
import 'dashboards/pharmacist_dashboard.dart';
import 'dashboards/student_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  ImageProvider<Object>? _profileImageProvider(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return MemoryImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5B5CE2), Color(0xFF7A5CF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          '${user.profile.role.label} Dashboard',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Profile'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            _profileImageProvider(user.profile.profilePhotoBytes),
                        child: user.profile.profilePhotoBytes == null
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Name: ${user.profile.fullName}\n'
                        'Email: ${user.email}\n'
                        'Phone: ${user.profile.phone}\n'
                        'Department: ${user.profile.department}\n'
                        'Role: ${user.profile.role.label}',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.account_circle, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: context.read<AppState>().logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: switch (user.profile.role) {
        UserRole.admin => const AdminDashboard(),
        UserRole.doctor => const DoctorDashboard(),
        UserRole.student => const StudentDashboard(),
        UserRole.pharmacist => const PharmacistDashboard(),
      },
    );
  }
}
