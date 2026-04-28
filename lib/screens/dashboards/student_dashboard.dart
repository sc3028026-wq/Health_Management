import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../widgets/section_title.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _issueCtrl = TextEditingController();

  @override
  void dispose() {
    _issueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final student = state.currentUser!.profile.fullName;
    final selectedDoctor =
        state.doctors.isNotEmpty ? state.doctors.first.profile.fullName : '';
    final studentAppointments = state.appointments
        .where((a) => a.studentName == student)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final studentReports = state.reports
        .where((r) => r.studentName == student)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final studentHistory = state.activityRecords
        .where(
          (record) =>
              record.actor == student ||
              record.details.toLowerCase().contains(student.toLowerCase()),
        )
        .take(20)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Book Appointment'),
        TextFormField(
          initialValue: selectedDoctor,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Doctor Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _issueCtrl,
          decoration: const InputDecoration(
            labelText: 'Health Issue',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            if (selectedDoctor.isEmpty || _issueCtrl.text.isEmpty) return;
            await context.read<AppState>().addAppointment(
                  studentName: student,
                  doctorName: selectedDoctor,
                  date: DateTime.now(),
                  issue: _issueCtrl.text,
                );
            _issueCtrl.clear();
          },
          child: const Text('Book Appointment'),
        ),
        const Divider(height: 28),
        const SectionTitle('View Appointments'),
        if (studentAppointments.isEmpty) const Text('No appointments booked.'),
        ...studentAppointments.map(
          (a) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text('${a.doctorName} - ${a.status}'),
              subtitle: Text(
                'Issue: ${a.issue}\n'
                'Booked: ${a.date.day}/${a.date.month}/${a.date.year}'
                '${a.deadline != null ? '\nDeadline: ${a.deadline!.day}/${a.deadline!.month}/${a.deadline!.year}' : ''}',
              ),
            ),
          ),
        ),
        const Divider(height: 28),
        const SectionTitle('View / Download Reports'),
        if (studentReports.isEmpty) const Text('No reports added yet.'),
        ...studentReports.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(r.summary),
                  subtitle: Text(
                    'Updated by: ${r.updatedBy}\n'
                    'Date: ${r.date.day}/${r.date.month}/${r.date.year}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report downloaded successfully')),
                      );
                    },
                  ),
                ),
              ),
            ),
        const Divider(height: 28),
        const SectionTitle('Previous Activity History'),
        if (studentHistory.isEmpty) const Text('No previous activity found yet.'),
        ...studentHistory.map(
          (record) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(record.title),
              subtitle: Text(
                '${record.details}\n'
                'By: ${record.actor} | ${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
