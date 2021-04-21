import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huawei_push/local_notification/attributes.dart';
import 'package:huawei_push/local_notification/importance.dart';
import 'package:huawei_push/push.dart';
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
  String selectedDay;
  String selectedWeather;
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
      defineWeatherBarrier(
          _weatherResponse.hourlyWeather[0].weatherId, weather);
    });
  }

  void getTimeCategories(String day) async {
    _timeCategoriesResponse = await AwarenessCaptureClient.getTimeCategories();
    setState(() {
      defineTimeBarrier(day);
    });
  }

  void defineTimeBarrier(String day) {
    List<String> _notificationInfo = [timeStr, selectedDay];
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
      case 'Saturday':
        dayOfWeekCode = TimeBarrier.SaturdayCode;
        break;
      case 'Sunday':
        dayOfWeekCode = TimeBarrier.SundayCode;
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
    addBarrier(timeBarrier, [timeStr, day]);
  }

  void defineWeatherBarrier(int weatherCode, String selectedWeather) {
    List<String> notificationInfo = ['Weather Notification'];
    switch (weatherCode) {
      case WeatherId.Sunny:
        notificationInfo.add(weathers[0]);
        break;
      case WeatherId.Rain:
        notificationInfo.add(weathers[1]);
        break;
      case WeatherId.Snow:
        notificationInfo.add(weathers[2]);
        break;
      default:
        notificationInfo.add('Normal');
        break;
    }
    if (notificationInfo[1] == selectedWeather) {
      sendLocalNotificaton(notificationInfo);
    }
  }

  Future<void> addBarrier(
      AwarenessBarrier awarenessBarrier, List<String> notInfo) async {
    bool status = await AwarenessBarrierClient.updateBarriers(
      barrier: awarenessBarrier,
    );
    if (status) {
      print('BarrierAdded');
      subscription =
          AwarenessBarrierClient.onBarrierStatusStream.listen((event) {
        if (mounted) {
          if (event.presentStatus == BarrierStatus.True) {
            sendLocalNotificaton(notInfo);
          } else {
            print('BarrierStatus: False');
          }

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

  sendLocalNotificaton(List<String> notificationInfo) async {
    if (notificationInfo[1] != selectedDay) notificationInfo[1] = selectedDay;
    try {
      Map<String, dynamic> localNotification = {
        HMSLocalNotificationAttr.TITLE: notificationInfo[0],
        HMSLocalNotificationAttr.MESSAGE: notificationInfo[1],
        HMSLocalNotificationAttr.TICKER: "OptionalTicker",
        HMSLocalNotificationAttr.TAG: "push-tag",
        HMSLocalNotificationAttr.SUB_TEXT: 'Notifiy Me',
        HMSLocalNotificationAttr.SMALL_ICON: 'ic_notification',
        HMSLocalNotificationAttr.IMPORTANCE: Importance.MAX,
        HMSLocalNotificationAttr.COLOR: "white",
        HMSLocalNotificationAttr.VIBRATE: true,
        HMSLocalNotificationAttr.VIBRATE_DURATION: 1000.0,
        HMSLocalNotificationAttr.ONGOING: false,
        HMSLocalNotificationAttr.DONT_NOTIFY_IN_FOREGROUND: false,
        HMSLocalNotificationAttr.AUTO_CANCEL: false,
        HMSLocalNotificationAttr.INVOKE_APP: false,
      };
      Map<String, dynamic> response =
          await Push.localNotification(localNotification);
      print("Pushed a local notification: " + response.toString());
    } catch (e) {
      print('Error: ${e.toString()}');
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
                          icon: condition.name == timeStr
                              ? Icon(Icons.calendar_today)
                              : Icon(Icons.wb_sunny_rounded),
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
                            setState(() {
                              selectedValue = value;
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
                            if (condition.isActive && selectedValue != null) {
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
