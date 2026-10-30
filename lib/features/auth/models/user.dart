import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? termsAcceptedVersion;
  final String? createdAt;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.termsAcceptedVersion,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      termsAcceptedVersion: (json['terms_accepted_version'] ?? json['termsAcceptedVersion']) as String?,
      createdAt: (json['created_at'] ?? json['createdAt']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'terms_accepted_version': termsAcceptedVersion,
      'created_at': createdAt,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? termsAcceptedVersion,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      termsAcceptedVersion: termsAcceptedVersion ?? this.termsAcceptedVersion,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        termsAcceptedVersion,
        createdAt,
      ];
}
