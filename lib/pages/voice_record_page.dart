import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';

class VoiceRecordPage extends StatefulWidget {
  const VoiceRecordPage({super.key});

  @override
  State<VoiceRecordPage> createState() => _VoiceRecordPageState();
}

class _VoiceRecordPageState extends State<VoiceRecordPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "";

  final TextEditingController itemController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String type = '';
  String category = '';

  final Map<String, List<String>> categories = {
    "餐飲": ["早餐", "午餐", "晚餐", "飲料", "麥當勞", "肯德基"],
    "交通": ["捷運", "公車", "高鐵", "火車", "加油"],
    "娛樂": ["電影", "唱歌", "遊戲", "KTV"],
    "雜貨": ["蝦皮", "全聯", "家樂福", "小北"],
    "薪資": ["薪水", "收入", "發薪"],
    "投資": ["股息", "投資"],
    "獎金": ["獎金", "紅包"],
    "其他": ["其他"]
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    final available = await _speech.initialize(
      onStatus: (val) => debugPrint('📡 狀態：$val'),
      onError: (val) => debugPrint('❌ 錯誤：$val'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: "zh_TW",
        onResult: (val) {
          debugPrint('🎤 認出：${val.recognizedWords}');
          setState(() {
            _recognizedText = val.recognizedWords;
          });
          _analyzeText(val.recognizedWords);
        },
      );
    } else {
      debugPrint("❌ 無法使用語音辨識功能");
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _analyzeText(String text) {
    debugPrint("🧠 分析語音：$text");

    for (var entry in categories.entries) {
      for (var kw in entry.value) {
        if (text.contains(kw)) {
          category = entry.key;
          type = ["薪資", "投資", "獎金"].contains(category) ? "收入" : "支出";
          itemController.text = kw;
          break;
        }
      }
      if (category.isNotEmpty) break;
    }

    final amountReg = RegExp(r'\d+');
    final amountMatch = amountReg.firstMatch(text);
    if (amountMatch != null) {
      amountController.text = amountMatch.group(0)!;
    }

    final dateReg = RegExp(r'(\d{1,2})[\/月](\d{1,2})');
    final dateMatch = dateReg.firstMatch(text);
    if (dateMatch != null) {
      final now = DateTime.now();
      dateController.text = "${now.year}-${dateMatch.group(1)}-${dateMatch.group(2)}";
    }
  }

  void _saveToDatabase() async {
    if (amountController.text.isEmpty || category.isEmpty) {
      debugPrint('⚠️ 資料不足，無法儲存');
      return;
    }

    final txn = TransactionModel(
      category: category,
      isExpense: type == "支出",
      amount: double.tryParse(amountController.text) ?? 0,
      note: noteController.text,
      date: dateController.text.isNotEmpty
          ? DateTime.tryParse(dateController.text) ?? DateTime.now()
          : DateTime.now(),
    );

    await DatabaseHelper().insertTransaction(txn);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 語音記帳已儲存！')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('語音記帳'),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isListening ? _stopListening : _startListening,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? '停止辨識' : '開始語音記帳'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[600],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: itemController,
              decoration: const InputDecoration(labelText: '項目'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: '金額'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: '日期'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: '備註'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveToDatabase,
              icon: const Icon(Icons.save),
              label: const Text('儲存記帳'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}