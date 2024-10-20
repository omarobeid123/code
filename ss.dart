import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(ColorMatchGame());
}

class ColorMatchGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Color Match Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isSoundOn = true;
  String _language = 'English';
  Color _topColor = Color(0xFF1F3B73);
  Color _bottomColor = Color(0xFF0A0A2A);

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadColors();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundOn = prefs.getBool('isSoundOn') ?? true;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _loadColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int topColorInt = prefs.getInt('topColor') ?? 0xFF1F3B73;
    int bottomColorInt = prefs.getInt('bottomColor') ?? 0xFF0A0A2A;

    setState(() {
      _topColor = Color(topColorInt);
      _bottomColor = Color(bottomColorInt);
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isSoundOn', _isSoundOn);
    prefs.setString('language', _language);
  }

  final Map<String, Map<String, String>> _localizedStrings = {
    'English': {
      'title': 'Color Match Game',
      'start': 'Start Game',
      'settings': 'Settings',
      'sound': 'Sound',
      'match': 'Match the color!',
      'gameOver': 'Game Over',
      'score': 'Score',
      'highScore': 'High Score',
      'level': 'Level',
      'playAgain': 'Play Again',
      'back': 'Back',
      'storeBackgrounds': 'Store Backgrounds',
    },
    'العربية': {
      'title': 'لعبة مطابقة الألوان',
      'start': 'ابدأ اللعبة',
      'settings': 'الإعدادات',
      'sound': 'الصوت',
      'match': 'طابق اللون!',
      'gameOver': 'انتهت اللعبة',
      'score': 'النتيجة',
      'highScore': 'أعلى نتيجة',
      'level': 'المستوى',
      'playAgain': 'العب مرة أخرى',
      'back': 'رجوع',
      'storeBackgrounds': 'متجر الخلفيات',
    },
    '中文': {
      'title': '颜色匹配游戏',
      'start': '开始游戏',
      'settings': '设置',
      'sound': '声音',
      'match': '匹配颜色！',
      'gameOver': '游戏结束',
      'score': '得分',
      'highScore': '最高分',
      'level': '等级',
      'playAgain': '再玩一次',
      'back': '返回',
      'storeBackgrounds': '商店背景',
    },
  };

  String _translate(String key) {
    return _localizedStrings[_language]?[key] ?? key;
  }

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ColorGameScreen(isSoundOn: _isSoundOn, language: _language),
      ),
    );
  }

  void _toggleSound(bool? value) {
    setState(() {
      _isSoundOn = value ?? true;
      _saveSettings();
    });
  }

  void _changeLanguage(String? lang) {
    setState(() {
      _language = lang ?? 'English';
      _saveSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_topColor, _bottomColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_translate('title'),
                  style: TextStyle(fontSize: 30, color: Colors.white)),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child:
                    Text(_translate('start'), style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              Text(_translate('settings'),
                  style: TextStyle(fontSize: 24, color: Colors.white)),
              SwitchListTile(
                title: Text(_translate('sound'),
                    style: TextStyle(color: Colors.white)),
                value: _isSoundOn,
                onChanged: _toggleSound,
              ),
              DropdownButton<String>(
                value: _language,
                items: <String>['English', 'العربية', '中文'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: _changeLanguage,
                dropdownColor: Color(0xFF1F3B73),
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorGameScreen extends StatefulWidget {
  final bool isSoundOn;
  final String language;

  ColorGameScreen({required this.isSoundOn, required this.language});

  @override
  _ColorGameScreenState createState() => _ColorGameScreenState();
}

class _ColorGameScreenState extends State<ColorGameScreen>
    with TickerProviderStateMixin {
  Color targetColor = Colors.white;
  List<Color> colorOptions = [];
  int score = 0;
  int level = 1;
  double difficulty = 3.0;
  bool isGameOver = false;
  AnimationController? _controller;
  int highScore = 0;
  int colorCount = 4;
  int attempts = 0;
  AudioPlayer audioPlayer = AudioPlayer();
  Color _topColor = Color(0xFF1F3B73);
  Color _bottomColor = Color(0xFF0A0A2A);

  @override
  void initState() {
    super.initState();
    _loadColors();
    generateNewColors();
    startTimer();
  }

  Future<void> _loadColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int topColorInt = prefs.getInt('topColor') ?? 0xFF1F3B73;
    int bottomColorInt = prefs.getInt('bottomColor') ?? 0xFF0A0A2A;

    setState(() {
      _topColor = Color(topColorInt);
      _bottomColor = Color(bottomColorInt);
    });
  }

  void generateNewColors() {
    Random random = Random();
    targetColor = Color.fromRGBO(
        random.nextInt(256), random.nextInt(256), random.nextInt(256), 1);
    colorOptions = List.generate(colorCount, (index) {
      return Color.fromRGBO(
          random.nextInt(256), random.nextInt(256), random.nextInt(256), 1);
    });
    int correctIndex = random.nextInt(colorCount);
    colorOptions[correctIndex] = targetColor;
  }

  void startTimer() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: difficulty.toInt()),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            isGameOver = true;
          });
        }
      });
    _controller?.forward();
  }

  void playSound(String soundPath) async {
    if (widget.isSoundOn) {
      await audioPlayer.setSource(AssetSource(soundPath));
      await audioPlayer.resume();
    }
  }

  void selectColor(Color selectedColor) {
    playSound('sounds/select.wav');

    if (!isGameOver && selectedColor == targetColor) {
      setState(() {
        score++;
        attempts++;

        if (colorCount < 20 && score % 5 == 0) {
          colorCount = min(colorCount + 4, 20);
          playSound('sounds/success.mp3');
        }

        if (attempts >= 20) {
          difficulty = max(1.0, difficulty - 0.5);
        }

        if (score % 5 == 0) {
          level++;
        }

        _controller?.reset();
        generateNewColors();
        startTimer();
      });
    } else {
      setState(() {
        isGameOver = true;
        if (score > highScore) {
          highScore = score;
        }
      });
    }
  }

  void resetGame() {
    setState(() {
      score = 0;
      level = 1;
      difficulty = 3.0;
      isGameOver = false;
      attempts = 0;
      colorCount = 4;
      generateNewColors();
      _controller?.reset();
      startTimer();
    });
  }

  void backToStart() {
    Navigator.pop(context);
  }

  void goToStoreBackgrounds() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BackgroundsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_topColor, _bottomColor],
          ),
        ),
        child: isGameOver
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.language == 'العربية'
                          ? 'انتهت اللعبة'
                          : (widget.language == '中文' ? '游戏结束' : 'Game Over'),
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      '${widget.language == 'العربية' ? 'النتيجة' : (widget.language == '中文' ? '得分' : 'Score')}: $score',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    Text(
                      '${widget.language == 'العربية' ? 'أعلى نتيجة' : (widget.language == '中文' ? '最高分' : 'High Score')}: $highScore',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    Text(
                      '${widget.language == 'العربية' ? 'المستوى' : (widget.language == '中文' ? '等级' : 'Level')}: $level',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: resetGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(widget.language == 'العربية'
                          ? 'العب مرة أخرى'
                          : (widget.language == '中文' ? '再玩一次' : 'Play Again')),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: goToStoreBackgrounds,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(widget.language == 'العربية'
                          ? 'متجر الخلفيات'
                          : (widget.language == '中文'
                              ? '商店背景'
                              : 'Store Backgrounds')),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: backToStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(widget.language == 'العربية'
                          ? 'رجوع'
                          : (widget.language == '中文' ? '返回' : 'Back')),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  Text(
                    widget.language == 'العربية'
                        ? 'طابق اللون!'
                        : (widget.language == '中文'
                            ? '匹配颜色！'
                            : 'Match the color!'),
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          value: _controller?.value,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: targetColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: colorCount,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => selectColor(colorOptions[index]),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorOptions[index],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            margin: EdgeInsets.all(8),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    audioPlayer.dispose();
    super.dispose();
  }
}

class BackgroundsScreen extends StatefulWidget {
  @override
  _BackgroundsScreenState createState() => _BackgroundsScreenState();
}

class _BackgroundsScreenState extends State<BackgroundsScreen> {
  Color _topColor = Color(0xFFFFFFFF);
  Color _bottomColor = Color(0xFFFFFFFF);
  Color _appBarTextColor = Colors.black;
  Color _backButtonColor = Colors.black;

  final List<String> images = [
    'assets/image1.png',
    'assets/image2.png',
    'assets/image3.png',
    'assets/image4.png',
    'assets/image5.png',
    'assets/image6.png',
  ];

  final List<String> scores = [
    'Use',
    'Score 17',
    'Score 25',
    'Score 30',
    'Score 40',
    'Score 45',
  ];

  @override
  void initState() {
    super.initState();
    _loadColors();
    _loadTextColors();
  }

  void _loadColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int topColorInt = prefs.getInt('topColor') ?? 0xFFFFFFFF;
    int bottomColorInt = prefs.getInt('bottomColor') ?? 0xFFFFFFFF;

    setState(() {
      _topColor = Color(topColorInt);
      _bottomColor = Color(bottomColorInt);
    });
  }

  void _loadTextColors() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int appBarTextColorInt =
        prefs.getInt('appBarTextColor') ?? Colors.black.value;
    int backButtonColorInt =
        prefs.getInt('backButtonColor') ?? Colors.black.value;

    setState(() {
      _appBarTextColor = Color(appBarTextColorInt);
      _backButtonColor = Color(backButtonColorInt);
    });
  }

  void _saveColors(Color topColor, Color bottomColor) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('topColor', topColor.value);
    await prefs.setInt('bottomColor', bottomColor.value);
  }

  void _saveTextColors(Color appBarTextColor, Color backButtonColor) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appBarTextColor', appBarTextColor.value);
    await prefs.setInt('backButtonColor', backButtonColor.value);
  }

  void _changeBackgroundColor(String score) {
    Color newTopColor;
    Color newBottomColor = Color(0xFF0A0A2A);
    Color newTextColor;

    switch (score) {
      case 'Score 17':
        newTopColor = Color(0xFF1F3B73);
        newTextColor = Colors.white;
        break;
      case 'Score 25':
        newTopColor = Color(0xFF661F73);
        newTextColor = Colors.white;
        break;
      case 'Score 30':
        newTopColor = Color(0xFF731F3E);
        newTextColor = Colors.white;
        break;
      case 'Score 40':
        newTopColor = Color(0xFF73511F);
        newTextColor = Colors.white;
        break;
      case 'Score 45':
        newTopColor = Color(0xFF1F7334);
        newTextColor = Colors.white;
        break;
      default:
        newTopColor = Color(0xFFFFFFFF);
        newBottomColor = Color(0xFFFFFFFF);
        newTextColor = Colors.black;
    }

    setState(() {
      _topColor = newTopColor;
      _bottomColor = newBottomColor;
      _appBarTextColor = newTextColor;
      _backButtonColor = newTextColor;
    });

    _saveColors(newTopColor, newBottomColor);
    _saveTextColors(_appBarTextColor, _backButtonColor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _topColor,
        title: Text(
          'Backgrounds Store',
          style: TextStyle(color: _appBarTextColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _backButtonColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_topColor, _bottomColor],
          ),
        ),
        child: ListView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.all(10),
              child: ListTile(
                leading: Image.asset(images[index]),
                title: Text(scores[index]),
                onTap: () {
                  _changeBackgroundColor(scores[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
