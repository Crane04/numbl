import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const NumblApp());
}

class NumblApp extends StatelessWidget {
  const NumblApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Numbl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        fontFamily: 'monospace',
      ),
      home: const GameScreen(),
    );
  }
}

enum GuessResult { higher, lower, correct, none }

class GuessEntry {
  final int number;
  final GuessResult result;
  const GuessEntry(this.number, this.result);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int maxGuesses = 5;
  static const int minNum = 1;
  static const int maxNum = 50;

  late int _secret;
  final List<GuessEntry> _guesses = [];
  final TextEditingController _controller = TextEditingController();
  bool _gameOver = false;
  bool _won = false;
  String _message = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _startGame();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _secret = Random().nextInt(maxNum) + minNum;
      _guesses.clear();
      _gameOver = false;
      _won = false;
      _message = 'Guess a number between $minNum and $maxNum';
      _controller.clear();
    });
  }

  void _submitGuess() {
    final input = int.tryParse(_controller.text.trim());

    if (input == null || input < minNum || input > maxNum) {
      _shakeController.forward(from: 0);
      setState(() => _message = 'Enter a number between $minNum and $maxNum');
      return;
    }

    final remaining = maxGuesses - _guesses.length;
    if (remaining <= 0 || _gameOver) return;

    GuessResult result;
    String msg;

    if (input == _secret) {
      result = GuessResult.correct;
      msg = 'You got it! 🎉';
      setState(() {
        _won = true;
        _gameOver = true;
      });
    } else if (input < _secret) {
      result = GuessResult.higher;
      msg = 'Go higher ↑';
    } else {
      result = GuessResult.lower;
      msg = 'Go lower ↓';
    }

    setState(() {
      _guesses.add(GuessEntry(input, result));
      _message = msg;
      _controller.clear();

      if (!_won && _guesses.length >= maxGuesses) {
        _gameOver = true;
        _message = 'The number was $_secret';
      }
    });
  }

  int get _guessesLeft => maxGuesses - _guesses.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildAttemptDots(),
              const SizedBox(height: 32),
              _buildGuessList(),
              const Spacer(),
              _buildMessage(),
              const SizedBox(height: 16),
              if (!_gameOver) _buildInput(),
              if (_gameOver) _buildPlayAgain(),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'NUMBL',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Color(0xFF6C63FF),
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Guess the number · 1 to $maxNum',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B6B78),
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAttemptDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxGuesses, (i) {
        Color color;
        if (i < _guesses.length) {
          final r = _guesses[i].result;
          color = r == GuessResult.correct
              ? const Color(0xFF3ECF8E)
              : const Color(0xFFF56565);
        } else {
          color = const Color(0xFF2A2A36);
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildGuessList() {
    if (_guesses.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 64,
              color: Color(0xFF2A2A36),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        reverse: true,
        itemCount: _guesses.length,
        itemBuilder: (context, i) {
          final entry = _guesses[_guesses.length - 1 - i];
          final isLatest = i == 0;

          Color color;
          String arrow;
          if (entry.result == GuessResult.correct) {
            color = const Color(0xFF3ECF8E);
            arrow = '✓';
          } else if (entry.result == GuessResult.higher) {
            color = const Color(0xFFF5A623);
            arrow = '↑ higher';
          } else {
            color = const Color(0xFFF5A623);
            arrow = '↓ lower';
          }

          return AnimatedOpacity(
            opacity: isLatest ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isLatest ? const Color(0xFF1A1A24) : const Color(0xFF141418),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLatest ? color.withOpacity(0.4) : const Color(0xFF1E1E28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.number.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    arrow,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessage() {
    return Text(
      _message,
      style: TextStyle(
        fontSize: 16,
        color: _won
            ? const Color(0xFF3ECF8E)
            : _gameOver
                ? const Color(0xFFF56565)
                : const Color(0xFFE8E6DF),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInput() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = sin(_shakeAnimation.value * pi * 6) * 8;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A36)),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8E6DF),
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  hintText: _guessesLeft > 0 ? '$_guessesLeft left' : '',
                  hintStyle: const TextStyle(color: Color(0xFF3A3A44), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) => _submitGuess(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _submitGuess,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayAgain() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _won ? const Color(0xFF3ECF8E) : const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _won ? 'PLAY AGAIN' : 'TRY AGAIN',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Text(
      'Built with Ferome · ferome.dev',
      style: TextStyle(fontSize: 10, color: Color(0xFF3A3A44)),
      textAlign: TextAlign.center,
    );
  }
}
