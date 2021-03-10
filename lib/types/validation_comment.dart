class ValidationComment {
  /// Comment content.
  final String name;

  /// Moderator user's id.
  final String moderatorId;

  ValidationComment({
    this.name = '',
    this.moderatorId = '',
  });

  factory ValidationComment.empty() {
    return ValidationComment(
      name: '',
      moderatorId: '',
    );
  }

  factory ValidationComment.fromJSON(Map<String, dynamic> data) {
    if (data == null) {
      return ValidationComment.empty();
    }

    return ValidationComment(
      name: data['name'] ?? '',
      moderatorId: data['moderatorid'] ?? '',
    );
  }

  Map<String, dynamic> toJSON() {
    final Map<String, dynamic> data = Map();

    data['name'] = name;
    data['moderatorId'] = moderatorId;

    return data;
  }
}
