import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../widgets/section_title.dart';

class PharmacistDashboard extends StatefulWidget {
  const PharmacistDashboard({super.key});

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  final _medicineCtrl = TextEditingController();
  final _issueMedicineCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _issueQtyCtrl = TextEditingController();
  final _requestMsgCtrl = TextEditingController();

  @override
  void dispose() {
    _medicineCtrl.dispose();
    _issueMedicineCtrl.dispose();
    _stockCtrl.dispose();
    _issueQtyCtrl.dispose();
    _requestMsgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pharmacistName = state.currentUser?.profile.fullName ?? 'Pharmacist';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFF1FFF8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pharmacist Panel',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1A1F36)),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Manage Medicine Inventory'),
          TextField(
            controller: _medicineCtrl,
            decoration: const InputDecoration(labelText: 'Medicine Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _stockCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock Quantity'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(_stockCtrl.text);
              if (_medicineCtrl.text.isEmpty || qty == null) return;
              await context.read<AppState>().addMedicine(_medicineCtrl.text, qty);
              _stockCtrl.clear();
            },
            child: const Text('Add Medicine'),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Inventory Stock'),
          ...state.medicines.map(
            (m) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (m.stock <= 20 ? Colors.red : Colors.green).withValues(alpha: 0.15),
                  child: Icon(Icons.medication, color: m.stock <= 20 ? Colors.red : Colors.green),
                ),
                title: Text(m.name),
                subtitle: Text('Stock: ${m.stock}${m.stock <= 20 ? ' (Low stock)' : ''}'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Issue Medicine + Notify Admin'),
          TextField(
            controller: _issueMedicineCtrl,
            decoration: const InputDecoration(labelText: 'Medicine Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _issueQtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Issue Quantity'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _requestMsgCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message for Admin (if stock refill is needed)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final medicineName = _issueMedicineCtrl.text.trim();
              final qty = int.tryParse(_issueQtyCtrl.text);
              if (medicineName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter medicine name.')),
                );
                return;
              }
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid issue quantity.')),
                );
                return;
              }
              final msg = await context.read<AppState>().issueMedicine(
                    name: medicineName,
                    qty: qty,
                  );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            },
            child: const Text('Issue Medicine'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final medicineName = _issueMedicineCtrl.text.trim();
              final qty = int.tryParse(_issueQtyCtrl.text);
              final adminMessage = _requestMsgCtrl.text.trim();
              if (medicineName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter medicine name.')),
                );
                return;
              }
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid refill quantity.')),
                );
                return;
              }
              if (adminMessage.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter message for admin.')),
                );
                return;
              }
              final msg = await context.read<AppState>().createMedicineRequest(
                    medicineName: medicineName,
                    requestedQty: qty,
                    message: adminMessage,
                    requestedBy: pharmacistName,
                  );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              if (msg.toLowerCase().contains('saved') ||
                  msg.toLowerCase().contains('successfully')) {
                _requestMsgCtrl.clear();
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Refill Request to Admin'),
          ),
        ],
      ),
    );
  }
}
