import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../widgets/section_title.dart';
import '../pdf_viewer_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _issueCtrl = TextEditingController();
  String? _selectedDoctor;

  @override
  void dispose() {
    _issueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final student = state.currentUser!.profile.fullName;

    final studentAppointments = state.appointments
        .where((a) => a.studentName.trim() == student.trim())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final studentReports = state.reports
        .where((r) => r.studentName.trim() == student.trim())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (_selectedDoctor == null && state.doctors.isNotEmpty) {
      _selectedDoctor = state.doctors.first.profile.fullName;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Book Appointment'),
        DropdownButtonFormField<String>(
          initialValue: _selectedDoctor,
          decoration: const InputDecoration(
            labelText: 'Doctor Name',
            border: OutlineInputBorder(),
          ),
          items: state.doctors.map((doctor) {
            return DropdownMenuItem<String>(
              value: doctor.profile.fullName,
              child: Text(doctor.profile.fullName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDoctor = value;
            });
          },
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
            if (_selectedDoctor == null || _issueCtrl.text.isEmpty) return;
            await context.read<AppState>().addAppointment(
                  studentName: student,
                  doctorName: _selectedDoctor!,
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
        const SectionTitle('Current Diagnoses'),
        if (state.diagnoses.where((d) => d.studentName.trim() == student.trim()).isEmpty)
          const Text('No diagnoses found.'),
        ...state.diagnoses.where((d) => d.studentName.trim() == student.trim()).map(
          (d) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDFF6FF),
                child: Icon(Icons.note_alt, color: Color(0xFF0284C7)),
              ),
              title: Text('By: ${d.doctorName}'),
              subtitle: Text(d.notes),
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
                  trailing: r.pdfUrl != null
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('View PDF'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  pdfUrl: r.pdfUrl!,
                                  reportName: 'Report_${r.id}',
                                ),
                              ),
                            );
                          },
                        )
                      : const Text('Processing PDF...'),
                ),
              ),
            ),
      ],
    );
  }
}
