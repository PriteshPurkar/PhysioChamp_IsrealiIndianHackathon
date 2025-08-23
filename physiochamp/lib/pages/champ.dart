// lib/pages/champ.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChampPage extends StatefulWidget {
  const ChampPage({super.key});

  @override
  State<ChampPage> createState() => _ChampPageState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}

class _ChampPageState extends State<ChampPage> {
  static const String baseUrl = "http://10.171.28.25:8080";
  static const String chatPath = "/api/champ/chat"; // adjust if no url_prefix
  static const int userId = 1;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text: "Hi! I’m Champ 🤖\nHow can I help you with your gait, balance, or routines today?",
      isUser: false,
    ),
  ];

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _callChatEndpoint(text);
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: "Sorry, I couldn’t reach Champ right now.\n$e",
          isUser: false,
        ));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<String> _callChatEndpoint(String question) async {
    final uri = Uri.parse("$baseUrl$chatPath");
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({"user_id": userId, "question": question});

    final resp = await http.post(uri, headers: headers, body: body).timeout(
      const Duration(seconds: 30),
      onTimeout: () => http.Response('{"error":"Request timed out"}', 504),
    );

    if (resp.statusCode >= 300) {
      // Bubble up raw body for debugging
      throw "HTTP ${resp.statusCode}: ${resp.body}";
    }

    final data = _safeJson(resp.body);

    // Server-declared error
    final err = (data["error"] is String) ? (data["error"] as String) : null;
    if (err != null && err.trim().isNotEmpty) {
      throw err;
    }

    // Plan branch
    if (data["plan"] != null && data["plan"] is Map<String, dynamic>) {
      return _formatPlanForChat(data["plan"]);
    }

    // Text answers
    final candidates = [
      data["answer"],
      data["insights"],
      data["recommendations"],
      data["text"],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c;
    }

    // Friendly fallback
    return "I’m here, but didn’t receive a message to show. Please try again.";
  }

  Map<String, dynamic> _safeJson(String s) {
    try {
      final obj = jsonDecode(s);
      if (obj is Map<String, dynamic>) return obj;
      return {"raw": obj};
    } catch (_) {
      return {"raw": s};
    }
  }

  String _formatPlanForChat(Map<String, dynamic> plan) {
    final buf = StringBuffer();
    final summary = plan["summary"] ?? "Personal plan";
    final safety = plan["safety"] ?? "Exercise within comfort; stop if pain or dizziness.";
    final progression = plan["progression"] ?? "";

    buf.writeln("Plan: $summary");
    final wp = plan["weekly_plan"];
    if (wp is List) {
      for (final day in wp) {
        final d = day is Map<String, dynamic> ? day : {};
        final dayNum = d["day"] ?? "?";
        final focus = d["focus"] ?? "session";
        buf.writeln("\nDay $dayNum — $focus");
        final ex = d["exercises"];
        if (ex is List && ex.isNotEmpty) {
          for (final e in ex) {
            final em = e is Map<String, dynamic> ? e : {};
            final name = em["name"] ?? "Exercise";
            final sets = em["sets"]?.toString() ?? "";
            final reps = em["reps"]?.toString() ?? "";
            final notes = em["notes"] ?? "";
            final line = "- $name${sets.isNotEmpty ? " x$sets" : ""}${reps.isNotEmpty ? " ($reps)" : ""}${notes.isNotEmpty ? ": $notes" : ""}";
            buf.writeln(line);
          }
        } else {
          buf.writeln("- Rest / active recovery");
        }
      }
    }
    if (progression.toString().trim().isNotEmpty) {
      buf.writeln("\nProgression: $progression");
    }
    buf.writeln("Safety: $safety");
    return buf.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F9B8E), Color(0xFF0E7C7B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _GlassBar(
                child: Row(
                  children: const [
                    Icon(Icons.smart_toy_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Champ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: _Bubble(text: m.text, isUser: m.isUser),
                      );
                    },
                  ),
                ),
              ),
              _GlassInput(
                controller: _controller,
                sending: _sending,
                onSend: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? Colors.white : Colors.black.withOpacity(0.12);
    final fg = isUser ? Colors.black87 : Colors.white;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: isUser
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
            border: isUser ? Border.all(color: Colors.white.withOpacity(0.6), width: 0.4) : null,
          ),
          child: Text(text, style: TextStyle(color: fg, fontSize: 15.5, height: 1.35)),
        ),
      ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  final Widget child;
  const _GlassBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.8)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _GlassInput({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Message Champ...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: sending ? null : onSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: sending ? Colors.white24 : Colors.tealAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: sending
                            ? null
                            : [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Icon(
                        sending ? Icons.hourglass_bottom : Icons.arrow_upward_rounded,
                        color: sending ? Colors.white70 : Colors.black87,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}