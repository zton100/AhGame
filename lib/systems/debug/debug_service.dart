class DebugService {
  const DebugService({required this.isEnabled});

  final bool isEnabled;

  Map<String, Object?> toJson() {
    return {'isEnabled': isEnabled};
  }
}
