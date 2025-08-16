import 'package:flutter/material.dart';
import '../services/gemini_ai_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FintechChatbotScreen extends StatefulWidget {
  const FintechChatbotScreen({super.key});

  @override
  State<FintechChatbotScreen> createState() => _FintechChatbotScreenState();
}

class _FintechChatbotScreenState extends State<FintechChatbotScreen> {
  Map<String, dynamic>? _profileData;
  bool _loadingProfile = true;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('financial_profile')
          .doc('profile')
          .get();
      if (profileDoc.exists) {
        setState(() {
          _profileData = profileDoc.data();
        });
      }
    }
    setState(() {
      _loadingProfile = false;
    });
  }

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  String? _error;

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;
    setState(() {
      _loading = true;
      _messages.add({'role': 'user', 'text': userMessage});
      _controller.clear();
      _error = null;
    });
    try {
      String aiResponse;
      if (_profileData != null) {
        aiResponse = await GeminiAIService.generateChatbotResponseWithProfile(
          userMessage,
          _profileData!,
        );
      } else {
        aiResponse = await GeminiAIService.generateChatbotResponse(userMessage);
      }
      setState(() {
        _messages.add({'role': 'ai', 'text': aiResponse});
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fintech AI Chatbot'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue[100] : Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText:
                                'Ask your fintech question... (You can reference your financial profile)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _loading ? null : _sendMessage,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
