import 'package:flutter/material.dart';

class ScheduleModel {
  final String id;
  final String day; // Pazartesi, Salı...
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String courseName;
  final String location;

  ScheduleModel({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.courseName,
    required this.location,
  });
}