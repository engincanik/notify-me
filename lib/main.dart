import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huawei_awareness/dataTypes/captureTypes/timeCategoriesResponse.dart';
import 'package:huawei_awareness/hmsAwarenessLibrary.dart';
import 'package:notify_me/data/option_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  WeatherResponse _weatherResponse;
  String selectedDay = 'Monday';
  String selectedWeather = 'Sunny';
  String selectedValue = '';
  StreamSubscription<dynamic> subscription;

  @override
  void initState() {
    super.initState();
    checkPermissions();
    getSwitchStates();
  }

  Future<void> saveSwitchStateByConditionName(
      String conditionName, bool isActive) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setBool(conditionName, isActive);
  }

  Future<void> saveSelectedValue(
      String conditionName, String selectedVal) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setString(conditionName, selectedVal);
  }

  Future<void> getSwitchStates() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.getBool(timeStr) != null
        ? conditions[0].isActive = sharedPrefs.getBool(timeStr)
        : conditions[0].isActive = false;
    sharedPrefs.getBool(weatherStr) != null
        ? conditions[1].isActive = sharedPrefs.getBool(weatherStr)
        : conditions[1].isActive = false;
    sharedPrefs.getString(selectedDayStr) != null
        ? selectedDay = sharedPrefs.getString(selectedDayStr)
        : selectedDay = 'Monday';
    sharedPrefs.getString(selectedWeatherStr) != null
        ? selectedWeather = sharedPrefs.getString(selectedWeatherStr)
        : selectedWeather = 'Sunny';
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
    _weatherResponse = await AwarenessCaptureClient.getWeatherByDevice();
    setState(() {
      defineWeatherBarrier(_weatherResponse.hourlyWeather[0].weatherId);
    });
  }

  void getTimeCategories(String day) async {
    _timeCategoriesResponse = await AwarenessCaptureClient.getTimeCategories();
    setState(() {
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
    AwarenessBarrier timeBarrier = TimeBarrier.duringPeriodOfWeek(
      barrierLabel: 'Day of the Week',
      dayOfWeek: dayOfWeekCode,
      startTimeOfSpecifiedDay: 0,
      stopTimeOfSpecifiedDay: 86400000,
      timeZoneId: 'Europe/Istanbul',
    );
    addBarrier(timeBarrier);
  }

  void defineWeatherBarrier(int weatherCode) {
    switch (weatherCode) {
      case WeatherId.Sunny:
        break;
      case WeatherId.Rain:
        break;
      case WeatherId.Snow:
        break;
      default:
        break;
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
      case timeStr:
        getTimeCategories(selectedVal);
        break;
      case weatherStr:
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
                                  saveSwitchStateByConditionName(
                                      condition.name, condition.isActive);
                                });
                              },
                            ),
                          ],
                        ),
                        DropdownButton(
                          value: condition.name == timeStr
                              ? selectedDay
                              : selectedWeather,
                          icon: Icon(Icons.calendar_today),
                          items: condition.name == timeStr
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
                              if (condition.name == timeStr) {
                                saveSelectedValue(selectedDayStr, value);
                                selectedDay = value;
                              } else {
                                saveSelectedValue(selectedWeatherStr, value);
                                selectedWeather = value;
                              }
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
