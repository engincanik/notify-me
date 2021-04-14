import 'package:flutter/material.dart';
import 'package:notify_me/data/option_data.dart';

void main() {
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify Me',
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Notify Me',
          ),
        ),
        body: SafeArea(
          child: ListView(
            children: conditions.map((condition) {
              return Row(
                children: [
                  Switch(
                    value: condition.isActive,
                    onChanged: (value) {
                      setState(() {
                        condition.isActive = value;
                      });
                    },
                  ),
                  Text(condition.name)
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
