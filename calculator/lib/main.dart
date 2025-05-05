import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0D0D0D),
      ),
      home: CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        try {
          String processedExpression = _expression
              .replaceAll('x', '*')
              .replaceAll('÷', '/')
              .replaceAllMapped(
                RegExp(r'(\d)(\()'),
                (match) => '${match.group(1)}*(',
              )
              .replaceAllMapped(
                RegExp(r'\)(\d)'),
                (match) => ')*${match.group(1)}',
              )
              .replaceAllMapped(
                RegExp(r'\)(\()'),
                (match) => ')*(',
              );

          ShuntingYardParser p = ShuntingYardParser();
          Expression exp = p.parse(processedExpression);
          ContextModel cm = ContextModel();
          double evalResult = exp.evaluate(EvaluationType.REAL, cm);

          // Smart precision formatting
          if (evalResult % 1 == 0) {
            _result = evalResult.toStringAsFixed(1);
          } else {
            _result = evalResult
                .toStringAsFixed(6)
                .replaceFirst(RegExp(r'0+$'), '')
                .replaceFirst(RegExp(r'\.$'), '');
          }
        } catch (e) {
          _result = 'Error';
        }
      } else {
        _expression += value;
      }

      // Auto-scroll after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Widget buildButton(String text, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: color ?? Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color != null ? color.withAlpha((255 * 0.4).toInt()) : Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              onTap: () => _onButtonPressed(text),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha((255 * 0.9).toInt()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final operatorColor = Color(0xFF00B0FF);
    final specialColor = Color(0xFF444444);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calculator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: ListView(
                controller: _scrollController,
                reverse: true,
                physics: BouncingScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Text(
                      _result,
                      style: TextStyle(
                        fontSize: 42,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Row(children: ['C', '⌫', '(', ')'].map((e) => buildButton(e, color: specialColor)).toList()),
                Row(children: ['7', '8', '9', '÷'].map((e) => buildButton(e, color: e == '÷' ? operatorColor : null)).toList()),
                Row(children: ['4', '5', '6', 'x'].map((e) => buildButton(e, color: e == 'x' ? operatorColor : null)).toList()),
                Row(children: ['1', '2', '3', '-'].map((e) => buildButton(e, color: e == '-' ? operatorColor : null)).toList()),
                Row(children: ['0', '.', '=', '+'].map((e) {
                  return buildButton(
                    e,
                    color: (e == '=' || e == '+') ? operatorColor : null,
                  );
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
