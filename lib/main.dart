import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const QuizApp());

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日本城郭検定対策',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8D6E63),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const TopPage(),
    );
  }
}

// --- トップ画面：級の選択 ---
class TopPage extends StatefulWidget {
  const TopPage({super.key});

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  final AudioPlayer _bgmPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playStartSound(); // 画面が開いた瞬間に再生
  }

  void _playStartSound() async {
    try {
      // assets/sounds/top_sound.mp3 を再生
      await _bgmPlayer.play(AssetSource('sounds/top_sound.mp3'));
    } catch (e) {
      debugPrint("BGM再生エラー: $e");
    }
  }

  @override
  void dispose() {
    _bgmPlayer.dispose(); // 画面を閉じるときにメモリを解放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('assets/images/top_banner.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    '日本城郭検定対策',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text('挑戦する級を選んでください', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              _buildLevelButton(context, '4'),
              _buildLevelButton(context, '3'),
              _buildLevelButton(context, '2'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(BuildContext context, String level) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontSize: 20),
          ),
          onPressed: () {
            _bgmPlayer.stop(); // 画面遷移時に音を止める
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LevelSelectionPage(level: level),
              ),
            );
          },
          child: Text('$level級に挑戦'),
        ),
      ),
    );
  }
}

//セット選択画面：級に応じてボタンを動的に増やす
class LevelSelectionPage extends StatefulWidget {
  final String level;
  const LevelSelectionPage({super.key, required this.level});

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  int _totalSets = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _countSets();
  }

  Future<void> _countSets() async {
    try {
      final rawData = await rootBundle.loadString('assets/data/quiz_data.csv');
      List<List<dynamic>> listData = const CsvToListConverter().convert(
        rawData,
      );

      Set<String> setNumbers = {};
      for (var i = 1; i < listData.length; i++) {
        var row = listData[i];
        if (row.length > 2 && row[1].toString().trim() == widget.level) {
          setNumbers.add(row[2].toString().trim());
        }
      }
      setState(() {
        _totalSets = setNumbers.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAndStart(BuildContext context, String setNumber) async {
    try {
      final rawData = await rootBundle.loadString('assets/data/quiz_data.csv');
      List<List<dynamic>> listData = const CsvToListConverter().convert(
        rawData,
      );

      List<Map<String, dynamic>> questions = [];
      for (var i = 1; i < listData.length; i++) {
        var row = listData[i];
        if (row.length < 10) continue;

        String rowLevel = row[1].toString().trim();
        String rowSet = row[2].toString().trim();

        if (rowLevel == widget.level && rowSet == setNumber) {
          questions.add({
            'id': row[0].toString().trim(),
            'q': row[3].toString(),
            'choices': [
              row[4].toString(),
              row[5].toString(),
              row[6].toString(),
              row[7].toString(),
            ],
            'answer': int.tryParse(row[8].toString().trim()) ?? 0,
            'ext': row[9].toString(),
          });
          if (questions.length == 10) break;
        }
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizPage(level: widget.level, questions: questions),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.level}級 セット選択')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _totalSets,
              itemBuilder: (context, index) {
                String setNum = (index + 1).toString();
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text(
                      '過去問セット $setNum (10問)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _loadAndStart(context, setNum),
                  ),
                );
              },
            ),
    );
  }
}

// --- クイズ画面 ---
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
  int _score = 0;

  // 音を鳴らす
  // 音を鳴らす装置の準備
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 音を鳴らす関数（シンプル版）
  void _playSound(bool isCorrect) async {
    try {
      String fileName = isCorrect ? 'correct.mp3' : 'incorrect.mp3';
      await _audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // 再生エラー時のみログを出す（通常は不要）
    }
  }

  void _next() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('クイズ終了！', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.questions.length}問中'),
            Text(
              '$_score 問正解',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // QuizPage
              },
              child: const Text('セット選択に戻る'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(body: const Center(child: Text('問題がありません')));
    }

    final q = widget.questions[_currentIndex];
    bool isCorrect = _selectedAnswer == q['answer'];
    String imagePath = 'assets/images/${q['id']}.jpg';

    return Scaffold(
      appBar: AppBar(title: Text('${widget.level}級 第${_currentIndex + 1}問')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FutureBuilder(
              future: rootBundle
                  .load(imagePath)
                  .catchError((_) => throw 'Ignore'),
              builder: (context, snapshot) {
                if (snapshot.hasData && !snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(
                      imagePath,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
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
                        setState(() {
                          _selectedAnswer = i;
                          bool correct = (i == q['answer']);

                          if (correct) {
                            _score++;
                          }
                          _playSound(correct);
                        });
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
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _next, child: const Text('次へ')),
            ],
          ],
        ),
      ),
    );
  }
}
