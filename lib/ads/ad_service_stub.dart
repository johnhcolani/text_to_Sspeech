class AdService {
  AdService._();

  static final AdService instance = AdService._();

  Future<bool> initialize() async => false;

  Future<bool> isPrivacyOptionsRequired() async => false;

  Future<String?> showPrivacyOptionsForm() async => null;
}
