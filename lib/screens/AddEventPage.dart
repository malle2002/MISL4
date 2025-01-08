import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lab4/models/ExamEvent.dart';
import 'package:lab4/screens/LocationPickerPage.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../util/utils.dart';

class AddEventPage extends StatefulWidget {
  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = "";
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  LatLng? _selectedLocation;

  void _selectDateAndTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  void _selectLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: EventController(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Add Event"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: "Title"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a title";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _title = value!;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      _selectedDate == null
                          ? "No date chosen!"
                          : "Date: ${_selectedDate!.toLocal()}".split(' ')[0],
                    ),
                    SizedBox(width: 8),
                    Text(
                      _selectedTime == null
                          ? "No time chosen!"
                          : "Time: ${_selectedTime!.format(context)}",
                    ),
                    TextButton(
                      onPressed: () => _selectDateAndTime(context),
                      child: Text("Select Date and Time"),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _selectedLocation == null
                    ? Text("No location chosen!")
                    : Text(
                    "Location: (${_selectedLocation!.latitude}, ${_selectedLocation!.longitude})"),
                TextButton(
                  onPressed: () async {
                    final LatLng? location = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerPage(),
                      ),
                    );
                    if (location != null) {
                      _selectLocation(location);
                    }
                  },
                  child: Text("Select Location"),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      if (_selectedDate == null ||
                          _selectedLocation == null ||
                          _selectedTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Please select date, time, and location"),
                          ),
                        );
                        return;
                      }
                      final eventDateTime = DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day,
                        _selectedTime!.hour,
                        _selectedTime!.minute,
                      );

                      final event = ExamEvent(
                        title: _title,
                        dateTime: eventDateTime,
                        location:
                        "(${_selectedLocation!.latitude}, ${_selectedLocation!.longitude})",
                        latitude: _selectedLocation!.latitude,
                        longitude: _selectedLocation!.longitude,
                      );

                      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
                      if (!isAllowed) {
                        await AwesomeNotifications().requestPermissionToSendNotifications();
                        isAllowed = await AwesomeNotifications().isNotificationAllowed();
                        if (!isAllowed) {
                          handlePermissionDenial(context, "Notifications");
                          return;
                        }
                      }

                      Provider.of<EventProvider>(context, listen: false)
                          .addEvent(event);
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Add Event"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
