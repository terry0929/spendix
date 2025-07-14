// 帳務分析頁面分析（Flutter, iOS風格）
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
//import 'personality_analysis_page.dart'; // ⬅️ 新增這行
import 'personality_analysis_page_updated.dart';


class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  DateTime _selectedMonth = DateTime(2025, 3);
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final allTxns = await DatabaseHelper().getAllTransactions();
    setState(() {
      _transactions = allTxns.where((txn) =>
      txn.date.year == _selectedMonth.year && txn.date.month == _selectedMonth.month
      ).toList();
    });
  }

  void _selectPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadTransactions();
  }

  void _selectNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final incomeTxns = _transactions.where((e) => !e.isExpense).toList();
    final expenseTxns = _transactions.where((e) => e.isExpense).toList();
    final incomeTotal = incomeTxns.fold(0.0, (sum, e) => sum + e.amount);
    final expenseTotal = expenseTxns.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text('帳務分析', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFFFCF8F5)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: _selectPreviousMonth, icon: const Icon(Icons.chevron_left)),
                    Text(
                      '${_selectedMonth.year}年${_selectedMonth.month}月',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(onPressed: _selectNextMonth, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummary(incomeTotal, expenseTotal),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPieChartSection(title: '支出分析', isExpense: true, txns: expenseTxns),
                  const SizedBox(height: 16),
                  _buildPieChartSection(title: '收入分析', isExpense: false, txns: incomeTxns, incomeColors: true),
                  const SizedBox(height: 16),
                  _buildSpendingTrend(expenseTxns),
                  const SizedBox(height: 16),
                  _buildNavigationCard(
                    icon: Icons.person_search,
                    title: '消費人格分析',
                    description: '查看您的消費型人格',
                    // onTap: () => Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const PersonalityAnalysisPage()),
                    // ),

                    // onTap: () => Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => PersonalityAnalysisPage(selectedMonth: _selectedMonth)),
                    // ),
                    onTap: () {
                      final total = expenseTxns.fold(0.0, (sum, txn) => sum + txn.amount);
                      if (total == 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ 本月份沒有支出資料，請先記帳後再分析')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PersonalityAnalysisPage(selectedMonth: _selectedMonth)),
                      );
                    },

                  ),
                  const SizedBox(height: 16),
                  _buildPlaceholder(title: '儲蓄進度分析（待實作）'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(double income, double expense) {
    final balance = income - expense;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem('總支出', expense, Colors.red),
        _buildSummaryItem('總收入', income, Colors.green),
        _buildSummaryItem('結餘', balance, Colors.brown),
      ],
    );
  }

  Widget _buildSummaryItem(String title, double value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text('\$${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPieChartSection({required String title, required bool isExpense, required List<TransactionModel> txns, bool incomeColors = false}) {
    final Map<String, double> categorySums = {};
    for (final txn in txns) {
      categorySums[txn.category] = (categorySums[txn.category] ?? 0) + txn.amount;
    }
    final total = categorySums.values.fold(0.0, (a, b) => a + b);
    final iconMap = {
      'Food': Icons.fastfood,
      'Transport': Icons.directions_car,
      'Entertainment': Icons.movie,
      'Grocery': Icons.shopping_cart,
      'Others': Icons.more_horiz,
      '薪資': Icons.attach_money,
      '投資': Icons.trending_up,
      '獎金': Icons.card_giftcard,
      '其他': Icons.account_balance_wallet,
    };
    final colors = incomeColors
        ? [Colors.teal, Colors.teal[300]!, Colors.cyan, Colors.blueGrey, Colors.lightBlueAccent]
        : Colors.primaries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: categorySums.entries.map((e) {
                final percent = (e.value / total) * 100;
                return PieChartSectionData(
                  color: colors[categorySums.keys.toList().indexOf(e.key) % colors.length],
                  value: e.value,
                  title: '${percent.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: categorySums.entries.map((e) {
            final percent = (e.value / total) * 100;
            return ListTile(
              leading: Icon(iconMap[e.key] ?? Icons.category, color: colors[categorySums.keys.toList().indexOf(e.key) % colors.length]),
              title: Text(e.key),
              trailing: Text('\$${e.value.toStringAsFixed(0)}  |  ${percent.toStringAsFixed(1)}%'),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildSpendingTrend(List<TransactionModel> txns) {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final numWeeks = ((daysInMonth + 6) / 7).floor();
    final weeklyTotals = List<double>.filled(numWeeks, 0);
    for (var txn in txns) {
      final weekIndex = ((txn.date.day - 1) / 7).floor();
      if (weekIndex >= 0 && weekIndex < numWeeks) {
        weeklyTotals[weekIndex] += txn.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('每週支出趨勢圖（單位：元）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              maxY: (weeklyTotals.reduce((a, b) => a > b ? a : b)) * 1.2,
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final weekNames = List.generate(weeklyTotals.length, (i) => '第${i + 1}週');
                      if (value < 0 || value >= weeklyTotals.length) return const SizedBox.shrink();
                      return Text(weekNames[value.toInt()], style: const TextStyle(fontSize: 12));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 48),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(weeklyTotals.length, (i) => FlSpot(i.toDouble(), weeklyTotals[i])),
                  isCurved: true,
                  color: Colors.orange,
                  dotData: FlDotData(show: true),
                  barWidth: 3,
                )
              ],
              gridData: FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.black87, width: 1),
                  bottom: BorderSide(color: Colors.black87, width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder({required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Center(child: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54))),
    );
  }

  Widget _buildNavigationCard({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, size: 30, color: Colors.brown[600]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
