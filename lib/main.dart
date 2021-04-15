import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huawei_awareness/dataTypes/captureTypes/timeCategoriesResponse.dart';
import 'package:huawei_awareness/hmsAwarenessLibrary.dart';
import 'package:notify_me/data/option_data.dart';

void main() {
  runApp(HomePage());
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool locationPermission;
  bool permissions = false;
  TimeCategoriesResponse _timeCategoriesResponse;
  final Map<String, bool> options = {'time': false, 'weather': false};

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  void checkPermissions() async {
    locationPermission = await AwarenessUtilsClient.hasLocationPermission();
    if (locationPermission) {
      setState(() {
        permissions = true;
      });
    } else {
      locationPermission =
          await AwarenessUtilsClient.requestLocationPermission();
    }
  }

  void captureWeatherByDevice() async {
    WeatherResponse weatherResponse =
        await AwarenessCaptureClient.getWeatherByDevice();
    setState(() {
      print(weatherResponse.hourlyWeather.toString());
    });
  }

  void getTimeCategories() async {
    TimeCategoriesResponse timeCategoriesResponse =
        await AwarenessCaptureClient.getTimeCategories();
    _timeCategoriesResponse = timeCategoriesResponse;
    setState(() {
      print(timeCategoriesResponse.timeCategories.toString());
      defineTimeBarrier();
    });
  }

  void defineTimeBarrier() {
    if (_timeCategoriesResponse != null) {
      AwarenessBarrier timeBarrier = TimeBarrier.duringPeriodOfWeek(
        barrierLabel: 'Day of the Week',
        dayOfWeek: TimeBarrier.FridayCode,
        startTimeOfSpecifiedDay: 0,
        stopTimeOfSpecifiedDay: 86400000,
        timeZoneId: 'Europe/Istanbul',
      );
      addBarrier(timeBarrier);
    }
  }

  Future<void> addBarrier(AwarenessBarrier awarenessBarrier) async {
    bool status = await AwarenessBarrierClient.updateBarriers(
      barrier: awarenessBarrier,
    );
    if (status) {
      print('BarrierAdded');
      StreamSubscription<dynamic> subscription;
      subscription =
          AwarenessBarrierClient.onBarrierStatusStream.listen((event) {
        if (mounted) {
          setState(() {
            print(event.barrierLabel +
                ' Status: ' +
                event.presentStatus.toString());
          });
        }
      }, onError: (error) {
        print(error.toString());
      });
    }
  }

  void saveConditionsStatus() {
    //TODOWrite a saving function and save options
  }

  void returnSelectedConditionInfo(String conditionName) {
    switch (conditionName) {
      case 'Time':
        getTimeCategories();
        break;
      case 'Weather':
        print(conditionName);
        break;
      case 'Location':
        print(conditionName);
        break;
      default:
        print(conditionName);
        break;
    }
  }

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
          child: Expanded(
            child: ListView(
              children: conditions.map((condition) {
                return ExpansionTile(
                  title: Text(condition.name),
                  children: [
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text('Set a notification for ' + condition.name),
                            Switch(
                              activeColor: Colors.amber[400],
                              activeTrackColor: Colors.amber[200],
                              value: condition.isActive,
                              onChanged: (value) {
                                setState(() {
                                  condition.isActive = value;
                                  options[condition.name.toLowerCase()] = value;
                                  if (value) {
                                    returnSelectedConditionInfo(condition.name);
                                  }
                                  print(options);
                                });
                              },
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: Text('Save'),
                        )
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
