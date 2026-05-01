import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api_config.dart';
import '../models/app_models.dart';
import '../models/role.dart';

class AppState extends ChangeNotifier {





  bool _isRequesting = false;

  Future<http.Response> _requestWithRetry(Future<http.Response> Function() requestFn) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        final response = await requestFn().timeout(const Duration(seconds: 10));
        return response;
      } on SocketException {
        if (attempts == 2) throw Exception("Unable to reach server. Please check your internet connection.");
      } on TimeoutException {
        if (attempts == 2) throw Exception("Request timed out. Please try again.");
      } catch (e) {
        if (attempts == 2) rethrow;
      }
      attempts++;
      await Future.delayed(Duration(seconds: 1 * attempts)); // Backoff
    }
    throw Exception("Request failed.");
  }

  final List<AppUser> _users = [];
  final List<Appointment> appointments = [];
  final List<Diagnosis> diagnoses = [];
  final List<MedicalReport> reports = [];
  final List<MedicineRequest> medicineRequests = [];
  final List<ActivityRecord> activityRecords = [];
  final List<MedicineItem> medicines = [];

  AppUser? currentUser;
  String? _accessToken;
  String? _refreshToken;
  String? authError;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      try {
        final meResponse = await _requestWithRetry(() => http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/me/'),
          headers: _headers(auth: true),
        ));
        if (meResponse.statusCode == 200) {
          final meData = jsonDecode(meResponse.body) as Map<String, dynamic>;
          currentUser = _userFromApi(meData);
          await _syncCoreData();
        } else {
          _accessToken = null;
          _refreshToken = null;
          await _persistTokens();
        }
      } catch (_) {
        _accessToken = null;
        _refreshToken = null;
        await _persistTokens();
      }
    }
    notifyListeners();
  }



  List<AppUser> get doctors =>
      _users.where((u) => u.profile.role == UserRole.doctor).toList();
  List<AppUser> get students =>
      _users.where((u) => u.profile.role == UserRole.student).toList();
  List<AppUser> get pharmacists =>
      _users.where((u) => u.profile.role == UserRole.pharmacist).toList();

  UserRole _parseRole(String rawRole) {
    switch (rawRole.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'doctor':
        return UserRole.doctor;
      case 'pharmacist':
        return UserRole.pharmacist;
      default:
        return UserRole.student;
    }
  }

  AppUser _userFromApi(Map<String, dynamic> item) {
    return AppUser(
      id: item['id'] as int?,
      email: (item['email'] ?? '').toString(),
      password: '',
      profile: UserProfile(
        fullName: (item['full_name'] ?? '').toString(),
        phone: (item['phone'] ?? '').toString(),
        department: (item['department'] ?? '').toString(),
        role: _parseRole((item['role'] ?? 'student').toString()),
      ),
    );
  }

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<void> _persistTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken == null) {
      await prefs.remove('access_token');
    } else {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_refreshToken == null) {
      await prefs.remove('refresh_token');
    } else {
      await prefs.setString('refresh_token', _refreshToken!);
    }
  }

  Appointment _appointmentFromApi(Map<String, dynamic> item) {
    return Appointment(
      id: item['id'] as int?,
      studentName: (item['student_name'] ?? '').toString(),
      doctorName: (item['doctor_name'] ?? '').toString(),
      date: DateTime.parse(item['date'] as String),
      issue: (item['issue'] ?? '').toString(),
      status: (item['status'] ?? 'Pending').toString(),
      deadline: item['deadline'] != null ? DateTime.parse(item['deadline'] as String) : null,
    );
  }

  Diagnosis _diagnosisFromApi(Map<String, dynamic> item) {
    return Diagnosis(
      id: item['id'] as int?,
      studentName: (item['student_name'] ?? '').toString(),
      notes: (item['notes'] ?? '').toString(),
      doctorName: (item['doctor_name'] ?? '').toString(),
    );
  }

  MedicalReport _reportFromApi(Map<String, dynamic> item) {
    return MedicalReport.fromJson(item);
  }

  MedicineItem _medicineFromApi(Map<String, dynamic> item) {
    return MedicineItem(
      id: item['id'] as int?,
      name: (item['name'] ?? '').toString(),
      stock: (item['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _syncCoreData() async {
    await Future.wait([
      fetchUsers(),
      fetchAppointments(),
      fetchDiagnoses(),
      fetchReports(),
      fetchMedicines(),
      fetchMedicineRequests(),
    ]);
  }

  Future<bool> login(String email, String password) async {
    try {
      authError = null;
            final response = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/login/'),
        headers: _headers(),
        body: jsonEncode({'email': email.trim(), 'password': password.trim()}),
      ));
      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          authError = 'Invalid email or password';
        } else {
          authError = 'Login failed (${response.statusCode}). Check backend server.';
        }
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access']?.toString();
      _refreshToken = data['refresh']?.toString();
      currentUser = _userFromApi(data['user'] as Map<String, dynamic>);
      await _persistTokens();
      await _syncCoreData();
      notifyListeners();
      return true;
    } catch (_) {
      authError = 'Unable to reach backend. Set API_BASE_URL and ensure server is running.';
      return false;
    }
  }

  Future<void> fetchUsers() async {
    if (_accessToken == null) return;
    try {
      _users.clear();
      if (currentUser?.profile.role == UserRole.admin) {
        final response = await _requestWithRetry(() => http.get(
          Uri.parse('${ApiConfig.baseUrl}/users/'),
          headers: _headers(auth: true),
        ));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;
          _users.addAll(data.map((item) => _userFromApi(item as Map<String, dynamic>)));
        }
      }
      final doctorResponse = await _requestWithRetry(() => http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/doctors/'),
        headers: _headers(auth: true),
      ));
      if (doctorResponse.statusCode == 200) {
        final doctorsData = jsonDecode(doctorResponse.body) as List<dynamic>;
        for (final raw in doctorsData) {
          final doctor = _userFromApi(raw as Map<String, dynamic>);
          if (_users.every((u) => u.id != doctor.id)) _users.add(doctor);
        }
      }
      if (currentUser != null && _users.every((u) => u.id != currentUser!.id)) {
        _users.add(currentUser!);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> requestPasswordResetOtp({
    required String email,
  }) async {
    try {
      final response = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/password-reset/send-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      ));

      final data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully.',
          'sessionId': data['session_id'],
        };
      }

      return {
        'success': false,
        'message': data['error'] ?? data['detail'] ?? 'Unable to send OTP.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Unable to reach OTP service. Start backend server and try again.',
      };
    }
  }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String sessionId,
    required String otp,
  }) async {
    if (otp.trim().length != 6) return 'Enter valid 6-digit OTP.';

    try {
      final response = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/password-reset/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'session_id': sessionId,
          'otp': otp.trim(),
        }),
      ));

      final data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return data['message'] ?? 'OTP verified successfully.';
      }

      return data['error'] ?? data['detail'] ?? 'Invalid OTP.';
    } catch (_) {
      return 'Unable to verify OTP right now.';
    }
  }

  Future<String> resetPassword({
    required String email,
    required String sessionId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.length < 6) return 'Password must be at least 6 characters.';
    if (newPassword != confirmPassword) {
      return 'New password and confirm password must match.';
    }

    try {
      final response = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/password-reset/complete/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'session_id': sessionId,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      ));

      final data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return data['error'] ??
            data['detail'] ??
            data['confirm_password']?.toString() ??
            'Unable to reset password.';
      }
    } catch (_) {
      return 'Unable to complete password reset. Start backend server and try again.';
    }

    notifyListeners();
    return 'Password reset successful. Please login with new password.';
  }

  Future<String?> signup({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String department,
    required UserRole role,
    Uint8List? profilePhotoBytes,
  }) async {
    final _ = profilePhotoBytes;
    try {
      final response = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/signup/'),
        headers: _headers(),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'username': email.trim().toLowerCase(),
          'password': password,
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'department': department.trim(),
          'role': role.name,
        }),
      ));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 201) {
        return data.values.isNotEmpty ? data.values.first.toString() : 'Unable to signup.';
      }
      _accessToken = data['access']?.toString();
      _refreshToken = data['refresh']?.toString();
      currentUser = _userFromApi(data['user'] as Map<String, dynamic>);
      await _persistTokens();
      await _syncCoreData();
      notifyListeners();
      return null;
    } catch (_) {
      return 'Unable to connect to backend.';
    }
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        final resp = await _requestWithRetry(() => http.post(
          Uri.parse('${ApiConfig.baseUrl}/users/logout/'),
          headers: _headers(auth: true),
          body: jsonEncode({'refresh': _refreshToken}),
        ));
      }
    } catch (_) {}
    _accessToken = null;
    _refreshToken = null;
    await _persistTokens();
    currentUser = null;
    _users.clear();
    appointments.clear();
    diagnoses.clear();
    reports.clear();
    medicineRequests.clear();
    medicines.clear();
    notifyListeners();
  }

  Future<void> addAppointment({
    required String studentName,
    required String doctorName,
    required DateTime date,
    required String issue,
  }) async {
    if (_accessToken == null) return;
    final resp = await _requestWithRetry(() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments/'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'student_name': studentName,
        'doctor_name': doctorName,
        'date': date.toIso8601String(),
        'issue': issue,
      }),
    ));
    await fetchAppointments();
  }

  Future<void> acceptAppointment(Appointment appointment) async {
    if (appointment.id == null || _accessToken == null) return;
    final resp = await _requestWithRetry(() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments/${appointment.id}/accept/'),
      headers: _headers(auth: true),
    ));
    await fetchAppointments();
  }

  Future<void> setAppointmentDeadline(Appointment appointment, DateTime deadline) async {
    if (appointment.id == null || _accessToken == null) return;
    final resp = await _requestWithRetry(() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments/${appointment.id}/set_deadline/'),
      headers: _headers(auth: true),
      body: jsonEncode({'deadline': deadline.toIso8601String()}),
    ));
    await fetchAppointments();
  }

  Future<void> addDiagnosis({
    required String studentName,
    required String notes,
    required String doctorName,
  }) async {
    if (_accessToken == null) return;
    final resp = await _requestWithRetry(() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/diagnoses/'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'student_name': studentName,
        'notes': notes,
        'doctor_name': doctorName,
      }),
    ));
    await fetchDiagnoses();
  }

  Future<void> addOrUpdateReport({
    required String studentName,
    required String summary,
    required String updatedBy,
    String symptoms = '',
    String diagnosis = '',
    String prescription = '',
    DateTime? followUpDate,
  }) async {
    if (_accessToken == null) return;
    final resp = await _requestWithRetry(() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/reports/'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'student_name': studentName,
        'summary': summary,
        'updated_by': updatedBy,
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'prescription': prescription,
        if (followUpDate != null) 'follow_up_date': followUpDate.toIso8601String().split('T')[0],
      }),
    ));
    await fetchReports();
  }

  Future<void> addMedicine(String name, int stock) async {
    if (_accessToken == null) return;
    final resp = await _requestWithRetry(() => http.post(
      Uri.parse('${ApiConfig.baseUrl}/medicines/add_stock/'),
      headers: _headers(auth: true),
      body: jsonEncode({'name': name.trim(), 'stock': stock}),
    ));
    await fetchMedicines();
  }

  Future<String> issueMedicine({
    required String name,
    required int qty,
  }) async {
    if (_accessToken == null) return 'Please login first.';
    try {
      final response = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/medicines/issue/'),
        headers: _headers(auth: true),
        body: jsonEncode({'name': name.trim(), 'qty': qty}),
      ));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await fetchMedicines();
      return response.statusCode == 200
          ? (data['message'] ?? 'Medicine issued successfully.').toString()
          : (data['error'] ?? 'Unable to issue medicine.').toString();
    } catch (_) {
      return 'Unable to issue medicine.';
    }
  }

  Future<String> createMedicineRequest({
    required String medicineName,
    required int requestedQty,
    required String message,
    required String requestedBy,
  }) async {
    if (_accessToken == null) return 'Please login first.';
    try {
      final response = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/medicine-requests/notify_admin/'),
        headers: _headers(auth: true),
        body: jsonEncode({
          'medicine_name': medicineName.trim(),
          'requested_qty': requestedQty,
          'message': message.trim(),
        }),
      ));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await fetchMedicineRequests();
      if (response.statusCode == 200) {
        return 'Request sent to admin successfully.';
      }
      return (data['error'] ?? 'Unable to send request.').toString();
    } catch (_) {
      return 'Unable to send request to server.';
    }
  }

  Future<void> provideMedicineRequest(MedicineRequest request) async {
    if (request.id == null || _accessToken == null) return;
    try {
      final resp = await _requestWithRetry(() => http.post(
        Uri.parse('${ApiConfig.baseUrl}/medicine-requests/${request.id}/provide/'),
        headers: _headers(auth: true),
      ));
      await fetchMedicineRequests();
      await fetchMedicines();
    } catch (_) {}
  }

  Future<void> fetchMedicineRequests() async {
    if (_accessToken == null) return;
    try {
      final response = await _requestWithRetry(() => http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicine-requests/'),
        headers: _headers(auth: true),
      ));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final serverRequests = data
            .map(
              (item) => MedicineRequest(
                id: item['id'],
                medicineName: item['medicine_name'],
                requestedQty: item['requested_qty'],
                message: item['message'] ?? '',
                requestedBy: item['requested_by'] ?? '',
                requestedAt: DateTime.parse(item['requested_at']),
                status: item['status'] ?? 'Pending',
                providedAt: item['provided_at'] != null
                    ? DateTime.parse(item['provided_at'])
                    : null,
              ),
            )
            .toList();

        medicineRequests
          ..clear()
          ..addAll(serverRequests);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchAppointments() async {
    if (_accessToken == null) return;
    try {
      final response = await _requestWithRetry(() => http.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/'),
        headers: _headers(auth: true),
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        appointments
          ..clear()
          ..addAll(data.map((item) => _appointmentFromApi(item as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchDiagnoses() async {
    if (_accessToken == null) return;
    try {
      final response = await _requestWithRetry(() => http.get(
        Uri.parse('${ApiConfig.baseUrl}/diagnoses/'),
        headers: _headers(auth: true),
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        diagnoses
          ..clear()
          ..addAll(data.map((item) => _diagnosisFromApi(item as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchReports() async {
    if (_accessToken == null) return;
    try {
      final response = await _requestWithRetry(() => http.get(
        Uri.parse('${ApiConfig.baseUrl}/reports/'),
        headers: _headers(auth: true),
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        reports
          ..clear()
          ..addAll(data.map((item) => _reportFromApi(item as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchMedicines() async {
    if (_accessToken == null) return;
    try {
      final response = await _requestWithRetry(() => http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicines/'),
        headers: _headers(auth: true),
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        medicines
          ..clear()
          ..addAll(data.map((item) => _medicineFromApi(item as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }
}
