import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../widgets/section_title.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _studentCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _reportCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _prescriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _studentCtrl.dispose();
    _diagnosisCtrl.dispose();
    _reportCtrl.dispose();
    _symptomsCtrl.dispose();
    _prescriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final doctor = state.currentUser!.profile.fullName;
    final doctorAppointments = state.appointments
        .where((a) => a.doctorName == doctor)
        .toList();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFEFFBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Doctor Workspace',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1F36)),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Appointment Requests'),
          if (doctorAppointments.isEmpty) const Text('No appointment requests yet.'),
          ...doctorAppointments.map(
            (a) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.studentName} - ${a.status}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('Issue: ${a.issue}'),
                    Text('Booked: ${a.date.day}/${a.date.month}/${a.date.year}'),
                    Text(
                      a.deadline == null
                          ? 'Deadline: Not set'
                          : 'Deadline: ${a.deadline!.day}/${a.deadline!.month}/${a.deadline!.year}',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: a.status == 'Accepted'
                              ? null
                              : () async {
                                  await context.read<AppState>().acceptAppointment(a);
                                },
                          child: const Text('Accept'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked == null || !context.mounted) return;
                            await context.read<AppState>().setAppointmentDeadline(a, picked);
                          },
                          child: const Text('Set Deadline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SectionTitle('View / Add Diagnosis'),
          TextField(
            controller: _studentCtrl,
            decoration: const InputDecoration(labelText: 'Student Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _diagnosisCtrl,
            decoration: const InputDecoration(labelText: 'Diagnosis Notes'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              if (_studentCtrl.text.isEmpty || _diagnosisCtrl.text.isEmpty) return;
              await context.read<AppState>().addDiagnosis(
                    studentName: _studentCtrl.text,
                    notes: _diagnosisCtrl.text,
                    doctorName: doctor,
                  );
              _diagnosisCtrl.clear();
            },
            child: const Text('Add Diagnosis'),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Generate Professional Report / Prescribe'),
          TextField(
            controller: _symptomsCtrl,
            decoration: const InputDecoration(labelText: 'Symptoms'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reportCtrl,
            decoration: const InputDecoration(labelText: 'Report Summary / Findings'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _prescriptionCtrl,
            decoration: const InputDecoration(labelText: 'Prescription / Advice'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              if (_studentCtrl.text.isEmpty || _reportCtrl.text.isEmpty) return;
              await context.read<AppState>().addOrUpdateReport(
                    studentName: _studentCtrl.text,
                    summary: _reportCtrl.text,
                    updatedBy: doctor,
                    symptoms: _symptomsCtrl.text,
                    diagnosis: _diagnosisCtrl.text,
                    prescription: _prescriptionCtrl.text,
                    followUpDate: DateTime.now().add(const Duration(days: 7)), // Default 1 week
                  );
              _reportCtrl.clear();
              _symptomsCtrl.clear();
              _prescriptionCtrl.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated!')));
            },
            child: const Text('Generate PDF Report'),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Current Diagnoses'),
          if (state.diagnoses.isEmpty) const Text('No diagnosis records available.'),
          ...state.diagnoses.map(
            (d) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDFF6FF),
                  child: Icon(Icons.note_alt, color: Color(0xFF0284C7)),
                ),
                title: Text(d.studentName),
                subtitle: Text('${d.notes}\nBy: ${d.doctorName}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
