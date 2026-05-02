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
  String? _selectedIssueMedicine;
  final _stockCtrl = TextEditingController();
  final _issueQtyCtrl = TextEditingController();
  
  final _refillMedicineNameCtrl = TextEditingController();
  final _refillQtyCtrl = TextEditingController();
  final _requestMsgCtrl = TextEditingController();

  @override
  void dispose() {
    _medicineCtrl.dispose();
    _stockCtrl.dispose();
    _issueQtyCtrl.dispose();
    _refillMedicineNameCtrl.dispose();
    _refillQtyCtrl.dispose();
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
          const SectionTitle('Issue Medicine to Student'),
          DropdownButtonFormField<String>(
            initialValue: _selectedIssueMedicine,
            decoration: const InputDecoration(
              labelText: 'Medicine Name',
              border: OutlineInputBorder(),
            ),
            items: state.medicines.map((medicine) {
              return DropdownMenuItem<String>(
                value: medicine.name,
                child: Text(medicine.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIssueMedicine = value;
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _issueQtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Issue Quantity(For Patient)'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final medicineName = _selectedIssueMedicine ?? '';
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
              if (msg.toLowerCase().contains('success')) {
                _issueQtyCtrl.clear();
              }
            },
            child: const Text('Issue Medicine'),
          ),

          const SizedBox(height: 14),
          const SectionTitle('Request Refill from Admin'),
          TextField(
            controller: _refillMedicineNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Medicine Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _refillQtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Refill Quantity Needed'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _requestMsgCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Message for Admin'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final medicineName = _refillMedicineNameCtrl.text.trim();
              final qty = int.tryParse(_refillQtyCtrl.text);
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
                _refillMedicineNameCtrl.clear();
                _refillQtyCtrl.clear();
                _requestMsgCtrl.clear();
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Refill Request to Admin'),
          ),
          const SizedBox(height: 14),
          const SectionTitle('My Refill Requests'),
          if (state.medicineRequests.isEmpty)
            const Text('No refill requests sent.'),
          ...state.medicineRequests.map(
            (req) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (req.status == 'Provided' ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                  child: Icon(
                    req.status == 'Provided' ? Icons.check_circle : Icons.pending,
                    color: req.status == 'Provided' ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text('${req.medicineName} - Qty ${req.requestedQty}'),
                subtitle: Text('Status: ${req.status}\nMessage: ${req.message}'),
                trailing: Text(
                  req.requestedAt.day.toString() + '/' + req.requestedAt.month.toString() + '/' + req.requestedAt.year.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
