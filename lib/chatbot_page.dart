import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // {'role': 'user'/'bot', 'text': '...', 'timestamp': DateTime}

  // void _sendMessage() {
  //   final text = _controller.text.trim();
  //   if (text.isEmpty) return;
  //   final now = DateTime.now();
  //   setState(() {
  //     _messages.add({'role': 'user', 'text': text, 'timestamp': now});
  //     _messages.add({'role': 'bot', 'text': '（這裡將來顯示 AI 回覆）', 'timestamp': now});
  //     _controller.clear();
  //   });
  // }
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'timestamp': now});
      _controller.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('https://my-fintech-bot.onrender.com/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? '⚠️ AI 沒有回覆';
        setState(() {
          _messages.add({'role': 'bot', 'text': reply, 'timestamp': DateTime.now()});
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text': '❌ 伺服器錯誤 (${response.statusCode})',
            'timestamp': DateTime.now()
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'text': '❌ 無法連線到伺服器：$e',
          'timestamp': DateTime.now()
        });
      });
    }
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;
    final current = _messages[index]['timestamp'] as DateTime;
    final previous = _messages[index - 1]['timestamp'] as DateTime;
    return current.day != previous.day || current.month != previous.month || current.year != previous.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('AI ChatBot', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final timestamp = message['timestamp'] as DateTime;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_shouldShowDate(index))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            DateFormat.yMMMd().format(timestamp),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ),
                    Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.brown[300] : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isUser ? 12 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'] ?? '',
                                  style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.Hm().format(timestamp),
                                  style: TextStyle(
                                    color: isUser ? Colors.white70 : Colors.black54,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '輸入訊息...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.brown),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
