class ReasonOption {
  final String id;
  final String option;
  final int displayOrder;

  ReasonOption({
    required this.id,
    required this.option,
    required this.displayOrder,
  });

  factory ReasonOption.fromMap(Map<String, dynamic> data, String documentId) {
    return ReasonOption(
      id: documentId,
      option: data['option'] ?? '',
      displayOrder: data['display_order'] ?? 0,
    );
  }
}
