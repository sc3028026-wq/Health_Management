import 'dart:typed_data';

import 'role.dart';

class UserProfile {
  UserProfile({
    required this.fullName,
    required this.phone,
    required this.department,
    required this.role,
    this.profilePhotoBytes,
  });

  final String fullName;
  final String phone;
  final String department;
  final UserRole role;
  final Uint8List? profilePhotoBytes;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'department': department,
        'role': role.name,
        'profilePhotoBytes': profilePhotoBytes,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        department: json['department'] as String,
        role: UserRole.values.firstWhere((e) => e.name == json['role']),
        profilePhotoBytes: json['profilePhotoBytes'] != null
            ? Uint8List.fromList((json['profilePhotoBytes'] as List).cast<int>())
            : null,
      );
}

class AppUser {
  AppUser({
    this.id,
    required this.email,
    required this.password,
    required this.profile,
  });

  final int? id;
  final String email;
  String password;
  final UserProfile profile;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'profile': profile.toJson(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int?,
        email: json['email'] as String,
        password: json['password'] as String,
        profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      );
}

class Appointment {
  Appointment({
    this.id,
    required this.studentName,
    required this.doctorName,
    required this.date,
    required this.issue,
    this.status = 'Pending',
    this.deadline,
  });

  final int? id;
  final String studentName;
  final String doctorName;
  final DateTime date;
  final String issue;
  String status;
  DateTime? deadline;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentName': studentName,
        'doctorName': doctorName,
        'date': date.toIso8601String(),
        'issue': issue,
        'status': status,
        'deadline': deadline?.toIso8601String(),
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as int?,
        studentName: json['studentName'] as String,
        doctorName: json['doctorName'] as String,
        date: DateTime.parse(json['date'] as String),
        issue: json['issue'] as String,
        status: json['status'] as String? ?? 'Pending',
        deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      );
}

class Diagnosis {
  Diagnosis({
    this.id,
    required this.studentName,
    required this.notes,
    required this.doctorName,
  });

  final int? id;
  final String studentName;
  final String notes;
  final String doctorName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentName': studentName,
        'notes': notes,
        'doctorName': doctorName,
      };

  factory Diagnosis.fromJson(Map<String, dynamic> json) => Diagnosis(
        id: json['id'] as int?,
        studentName: json['studentName'] as String,
        notes: json['notes'] as String,
        doctorName: json['doctorName'] as String,
      );
}

class MedicalReport {
  MedicalReport({
    this.id,
    required this.studentName,
    required this.summary,
    required this.updatedBy,
    required this.date,
  });

  final int? id;
  final String studentName;
  final String summary;
  final String updatedBy;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentName': studentName,
        'summary': summary,
        'updatedBy': updatedBy,
        'date': date.toIso8601String(),
      };

  factory MedicalReport.fromJson(Map<String, dynamic> json) => MedicalReport(
        id: json['id'] as int?,
        studentName: json['studentName'] as String,
        summary: json['summary'] as String,
        updatedBy: json['updatedBy'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

class MedicineItem {
  MedicineItem({
    this.id,
    required this.name,
    required this.stock,
  });

  final int? id;
  final String name;
  int stock;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stock': stock,
      };

  factory MedicineItem.fromJson(Map<String, dynamic> json) => MedicineItem(
        id: json['id'] as int?,
        name: json['name'] as String,
        stock: json['stock'] as int,
      );
}

class MedicineRequest {
  MedicineRequest({
    this.id,
    required this.medicineName,
    required this.requestedQty,
    required this.message,
    required this.requestedBy,
    required this.requestedAt,
    this.status = 'Pending',
    this.providedAt,
  });

  int? id;
  final String medicineName;
  final int requestedQty;
  final String message;
  final String requestedBy;
  final DateTime requestedAt;
  String status;
  DateTime? providedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineName': medicineName,
        'requestedQty': requestedQty,
        'message': message,
        'requestedBy': requestedBy,
        'requestedAt': requestedAt.toIso8601String(),
        'status': status,
        'providedAt': providedAt?.toIso8601String(),
      };

  factory MedicineRequest.fromJson(Map<String, dynamic> json) => MedicineRequest(
        id: json['id'] as int?,
        medicineName: json['medicineName'] as String,
        requestedQty: json['requestedQty'] as int,
        message: json['message'] as String,
        requestedBy: json['requestedBy'] as String,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        status: json['status'] as String? ?? 'Pending',
        providedAt: json['providedAt'] != null ? DateTime.parse(json['providedAt'] as String) : null,
      );
}

class ActivityRecord {
  ActivityRecord({
    required this.title,
    required this.details,
    required this.actor,
    required this.createdAt,
  });

  final String title;
  final String details;
  final String actor;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'title': title,
        'details': details,
        'actor': actor,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActivityRecord.fromJson(Map<String, dynamic> json) => ActivityRecord(
        title: json['title'] as String,
        details: json['details'] as String,
        actor: json['actor'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
