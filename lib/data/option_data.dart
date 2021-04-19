import 'package:notify_me/models/condition_info.dart';

List<ConditionInfo> conditions = [
  ConditionInfo('Time', false),
  ConditionInfo('Weather', false)
];

const List<String> days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

List<String> weathers = ['Sunny', 'Rain', 'Snow'];

const String timeStr = 'Time';
const String weatherStr = 'Weather';
const String selectedDayStr = 'selectedDay';
const String selectedWeatherStr = 'selectedWeather';
