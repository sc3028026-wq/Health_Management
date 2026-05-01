import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../widgets/section_title.dart';
import '../pdf_viewer_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Widget _infoTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchMedicineRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFEEF2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Admin Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1F36)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricCard(
                title: 'Students',
                value: '${state.students.length}',
                icon: Icons.school,
                colors: const [Color(0xFF5B5CE2), Color(0xFF7A5CF0)],
              ),
              const SizedBox(width: 10),
              _metricCard(
                title: 'Doctors',
                value: '${state.doctors.length}',
                icon: Icons.medical_services,
                colors: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
              ),
              const SizedBox(width: 10),
              _metricCard(
                title: 'Requests',
                value: '${state.medicineRequests.length}',
                icon: Icons.local_shipping,
                colors: const [Color(0xFF10B981), Color(0xFF059669)],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionTitle('Manage Students'),
          ...state.students.map(
            (s) => _infoTile(
              icon: Icons.school,
              color: const Color(0xFF5B5CE2),
              title: s.profile.fullName,
              subtitle: '${s.email} | ${s.profile.department}',
            ),
          ),
          const SizedBox(height: 6),
          const SectionTitle('Manage Doctors'),
          ...state.doctors.map(
            (d) => _infoTile(
              icon: Icons.medical_services,
              color: const Color(0xFF0EA5E9),
              title: d.profile.fullName,
              subtitle: '${d.email} | ${d.profile.department}',
            ),
          ),
          const SizedBox(height: 6),
          const SectionTitle('Manage Pharmacists'),
          ...state.pharmacists.map(
            (p) => _infoTile(
              icon: Icons.local_pharmacy,
              color: const Color(0xFF16A34A),
              title: p.profile.fullName,
              subtitle: '${p.email} | ${p.profile.department}',
            ),
          ),
          const SizedBox(height: 8),
          const SectionTitle('Medicine Refill Requests'),
          if (state.medicineRequests.isEmpty)
            const Text('No medicine requests from pharmacist.'),
          ...state.medicineRequests.map(
            (request) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (request.status == 'Provided' ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    request.status == 'Provided' ? Icons.check_circle : Icons.pending,
                    color: request.status == 'Provided' ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text('${request.medicineName} - Qty ${request.requestedQty}'),
                subtitle: Text(
                  'By: ${request.requestedBy}\n'
                  'Message: ${request.message}\n'
                  'Status: ${request.status}',
                ),
                trailing: request.status == 'Provided'
                    ? const Text('Done')
                    : ElevatedButton(
                        onPressed: () async {
                          await context.read<AppState>().provideMedicineRequest(request);
                        },
                        child: const Text('Provide'),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SectionTitle('System Activity Records'),
          if (state.activityRecords.isEmpty) const Text('No activity records yet.'),
          ...state.activityRecords.take(25).map(
            (record) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.history, color: Color(0xFF5B5CE2)),
                ),
                title: Text(record.title),
                subtitle: Text(
                  '${record.details}\n'
                  'By: ${record.actor} | ${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SectionTitle('View Reports'),
          if (state.reports.isEmpty) const Text('No reports added yet.'),
          ...state.reports.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FE),
                  child: Icon(Icons.description_outlined, color: Color(0xFF5B5CE2)),
                ),
                title: Text(r.studentName),
                subtitle: Text('${r.summary}\nDate: ${r.date.day}/${r.date.month}/${r.date.year}'),
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
                                reportName: 'Report_${r.id}_${r.studentName}',
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
      ),
    );
  }
}
