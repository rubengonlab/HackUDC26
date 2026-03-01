/*
 * SPDX-FileCopyrightText: Copyright (c) 2026 Rubén González Laballós
 * SPDX-License-Identifier: MIT
 */
class User {
  final String username;
  final List<String> selectedCategoryIds;

  User({
    required this.username,
    this.selectedCategoryIds = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      selectedCategoryIds: List<String>.from(json['selectedCategoryIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'selectedCategoryIds': selectedCategoryIds,
    };
  }

  User copyWith({
    String? username,
    List<String>? selectedCategoryIds,
  }) {
    return User(
      username: username ?? this.username,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    );
  }
}

