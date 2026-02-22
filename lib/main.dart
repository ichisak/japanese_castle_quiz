import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

void main() => runApp(const QuizApp());

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日本城郭検定対策',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const TopPage(),
    );
  }
}

class TopPage extends StatelessWidget {
  const TopPage({super.key});

  Future<void> _loadAndStart(BuildContext context, String level) async {
    try {
      final rawData = await rootBundle.loadString('assets/data/quiz_data.csv');
      List<List<dynamic>> listData = const CsvToListConverter().convert(
        rawData,
      );

      List<Map<String, dynamic>> questions = [];
      for (var i = 1; i < listData.length; i++) {
        //CSV構成: id[0], level[1], question[2], choice1[3], choice2[4], choice3[5], choice4[6], answer[7], exp[8]
        var row = listData[i];
        if (row.length < 9) continue; // 列が足りない行はスキップ

        String csvLevel = row[1].toString().trim();
        if (csvLevel == level) {
          questions.add({
            'q': row[2].toString(),
            'choices': [
              row[3].toString(),
              row[4].toString(),
              row[5].toString(),
              row[6].toString(),
            ],
            'answer': int.tryParse(row[7].toString()) ?? 0,
            'ext': row[8].toString(),
          });
        }
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPage(level: level, questions: questions),
          ),
        );
      }
    } catch (e) {
      print("❌ 重大なエラーが発生しました: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日本城郭検定対策')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('挑戦する級を選んでください', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadAndStart(context, '4'),
              child: const Text('4級に挑戦'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _loadAndStart(context, '3'),
              child: const Text('3級に挑戦'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _loadAndStart(context, '2'),
              child: const Text('2級に挑戦'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String level;
  final List<Map<String, dynamic>> questions;
  const QuizPage({super.key, required this.level, required this.questions});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentIndex = 0;
  int? _selectedAnswer;

  void _next() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.level)),
        body: const Center(child: Text('問題が準備中です。')),
      );
    }

    final q = widget.questions[_currentIndex];
    bool isCorrect = _selectedAnswer == q['answer'];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.level}級問題')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              q['q'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAnswer == i
                          ? (i == q['answer']
                                ? Colors.green[200]
                                : Colors.red[200])
                          : null,
                    ),
                    onPressed: () {
                      if (_selectedAnswer == null) {
                        setState(() => _selectedAnswer = i);
                      }
                    },
                    child: Text(q['choices'][i]),
                  ),
                ),
              ),
            ),
            if (_selectedAnswer != null) ...[
              const SizedBox(height: 20),
              Text(
                isCorrect ? '⭕ 正解！' : '❌ 不正解...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(q['ext']),
              const Spacer(),
              ElevatedButton(onPressed: _next, child: const Text('次へ')),
            ],
          ],
        ),
      ),
    );
  }
}
