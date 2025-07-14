//可動態抓當月月份
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';
import '../api/personality_predictor_debug.dart';
//import 'personality_analysis_render.dart';

class PersonalityAnalysisPage extends StatefulWidget {
  final DateTime selectedMonth;

  const PersonalityAnalysisPage({super.key, required this.selectedMonth});

  @override
  State<PersonalityAnalysisPage> createState() => _PersonalityAnalysisPageState();
}

class _PersonalityAnalysisPageState extends State<PersonalityAnalysisPage> {
  PersonalityResult? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analyzePersonalityFromSelectedMonth();
  }

  Future<void> _analyzePersonalityFromSelectedMonth() async {
    setState(() => _isLoading = true);

    final transactions = await DatabaseHelper().getAllTransactions();
    final targetTxns = transactions.where((txn) =>
      txn.date.year == widget.selectedMonth.year &&
      txn.date.month == widget.selectedMonth.month &&
      txn.isExpense).toList();

    final Map<String, double> sums = {
      'food': 0,
      'transport': 0,
      'entertainment': 0,
      'grocery': 0,
      'others': 0,
    };

    for (var txn in targetTxns) {
      final key = txn.category.toLowerCase();
      if (sums.containsKey(key)) {
        sums[key] = sums[key]! + txn.amount;
      } else {
        sums['others'] = sums['others']! + txn.amount;
      }
    }

    final api = PersonalityApiClient();
    final result = await api.predictPersonality(
      food: sums['food']!,
      transport: sums['transport']!,
      entertainment: sums['entertainment']!,
      grocery: sums['grocery']!,
      others: sums['others']!,
    );

    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        title: const Text('消費人格分析', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? const Center(child: Text('分析失敗，請稍後再試'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('你是：', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                      const SizedBox(height: 10),
                      Text(_result!.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown)),
                      const SizedBox(height: 30),
                      const Text('系統建議', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        _result!.suggestion,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
}
