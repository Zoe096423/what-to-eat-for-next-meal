// Packages
import 'package:flutter/material.dart';
import 'package:const_date_time/const_date_time.dart'; // For const dateTime

// Global variables
enum RGB {R, G, B}
String dateFormat = 'yyyy-MM-dd HH:mm';
String dateFormatSec = 'yyyy-MM-dd HH:mm:ss';
const defaultDt = ConstDateTime.utc(2022, 10, 27);
DateTime localSelectedDate = DateTime.now();

ValueNotifier<String> selectedList = ValueNotifier('午晚餐');

final today = DateTime.now();
DateTime selectedDate = selectedDate = DateTime(today.year, today.month, today.day);