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
  String selectedDay = 'Monday';
  String selectedWeather = 'Sun';
  String selectedValue = '';
  StreamSubscription<dynamic> subscription;
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

  void captureWeatherByDevice(String weather) async {
    WeatherResponse weatherResponse =
        await AwarenessCaptureClient.getWeatherByDevice();
    setState(() {
      print('Hourly: ${weatherResponse.hourlyWeather[0].weatherId}');
    });
  }

  void getTimeCategories(String day) async {
    TimeCategoriesResponse timeCategoriesResponse =
        await AwarenessCaptureClient.getTimeCategories();
    _timeCategoriesResponse = timeCategoriesResponse;
    setState(() {
      print(timeCategoriesResponse.timeCategories.toString());
      defineTimeBarrier(day);
    });
  }

  void defineTimeBarrier(String day) {
    int dayOfWeekCode = 0;
    switch (day) {
      case 'Monday':
        dayOfWeekCode = TimeBarrier.MondayCode;
        break;
      case 'Tuesday':
        dayOfWeekCode = TimeBarrier.TuesdayCode;
        break;
      case 'Wednesday':
        dayOfWeekCode = TimeBarrier.WednesdayCode;
        break;
      case 'Thursday':
        dayOfWeekCode = TimeBarrier.ThursdayCode;
        break;
      case 'Friday':
        dayOfWeekCode = TimeBarrier.FridayCode;
        break;
      default:
        dayOfWeekCode = TimeBarrier.MondayCode;
        break;
    }
    if (_timeCategoriesResponse != null) {
      AwarenessBarrier timeBarrier = TimeBarrier.duringPeriodOfWeek(
        barrierLabel: 'Day of the Week',
        dayOfWeek: dayOfWeekCode,
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
      subscription =
          AwarenessBarrierClient.onBarrierStatusStream.listen((event) {
        if (mounted) {
          // * Push notificaiton
          setState(() {
            print(event.barrierLabel +
                ' Status: ' +
                event.presentStatus.toString());
          });
        }
      }, onError: (error) {
        print(error.toString());
      });
      subscription.onDone(() {
        print('Subscription is done');
      });
    }
  }

  void returnSelectedConditionInfo(String conditionName, String selectedVal) {
    switch (conditionName) {
      case 'Time':
        getTimeCategories(selectedVal);
        break;
      case 'Weather':
        captureWeatherByDevice(selectedVal);
        break;
      default:
        print('Default: $conditionName');
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
                                });
                              },
                            ),
                          ],
                        ),
                        DropdownButton(
                          value: condition.name == 'Time'
                              ? selectedDay
                              : selectedWeather,
                          icon: Icon(Icons.calendar_today),
                          items: condition.name == 'Time'
                              ? days.map(
                                  (String val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  },
                                ).toList()
                              : weathers.map(
                                  (String val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  },
                                ).toList(),
                          onChanged: (value) {
                            selectedValue = value;
                            setState(() {
                              condition.name == 'Time'
                                  ? selectedDay = value
                                  : selectedWeather = value;
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (condition.isActive) {
                              returnSelectedConditionInfo(
                                  condition.name, selectedValue);
                            } else {
                              subscription.cancel();
                            }
                          },
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
