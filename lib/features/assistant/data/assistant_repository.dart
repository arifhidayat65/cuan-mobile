import '../../../core/api/cuan_api.dart';

/// Assistant data layer — AI chat endpoint.
class AssistantRepository {
  Future<Map<String, dynamic>> chat(String message) => api.chat(message);
}
