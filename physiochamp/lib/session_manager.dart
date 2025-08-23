import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const String baseUrl = 'http://10.171.28.60:5000';

  bool isSessionActive = false;
  int? currentSessionId;
  int sessionSeconds = 0;
  Timer? _timer;

  bool? get isRunning => null;

  /// Start a new session
  Future<void> startSession() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/start_session'),
          headers: {"Content-Type": "application/json"});
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        currentSessionId = decoded['session_id'];
        isSessionActive = true;
        sessionSeconds = 0;

        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          sessionSeconds++;
          notifyListeners();
        });

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error starting session: $e");
    }
  }

  /// Stop the active session
  Future<void> stopSession() async {
    try {
      if (currentSessionId != null) {
        await http.post(
          Uri.parse('$baseUrl/stop_session'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({"session_id": currentSessionId}),
        );
      }
    } catch (e) {
      debugPrint("Error stopping session: $e");
    }

    isSessionActive = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// Attach UI to listen for changes
  void attachListener(VoidCallback listener) => addListener(listener);
  void detachListener(VoidCallback listener) => removeListener(listener);
}
