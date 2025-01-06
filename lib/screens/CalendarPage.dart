import 'dart:math';

import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:lab4/main.dart';
import 'package:lab4/models/ExamEvent.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final EventController<ExamEvent> _eventController;

  @override
  void initState() {
    super.initState();
    _eventController = EventController<ExamEvent>();
  }

  void _updateEventController(List<ExamEvent> events) {
    _eventController.removeWhere((_) => true);
    for (var event in events) {
      print("Event date: ${event.dateTime}");
      _eventController.add(CalendarEventData<ExamEvent>(
          title: event.title,
          date: DateTime(
              event.dateTime.year, event.dateTime.month, event.dateTime.day,
              event.dateTime.hour, event.dateTime.minute),
          description: event.location,
          event: event,
          color: Color.fromRGBO(Random().nextInt(256), Random().nextInt(256),
              Random().nextInt(256), 1.0)
      ));
    }
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider<ExamEvent>(
      controller: _eventController,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Exam Schedule"),
          actions: [
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () {
                Navigator.pushNamed(context, '/map');
              },
              tooltip: 'View Map',
            ),
          ],
        ),
        body: Consumer<EventProvider>(
          builder: (context, eventProvider, child) {
            String formattedDate (DateTime date) => (
              DateFormat('yyyy-MM-dd HH:mm').format(date)
            );
            _updateEventController(eventProvider.events);
            return MonthView<ExamEvent>(
              onEventTap: (event, dateTime) {
                  print(event.startTime);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(event.title),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Date: ${formattedDate(dateTime)}"),
                            Text("Location: ${event.description}"),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final newEvent = await Navigator.pushNamed(context, '/add-event');
            if (newEvent != null && newEvent is ExamEvent) {
              Provider.of<EventProvider>(context, listen: false).addEvent(newEvent);

              setState(() {});
            }
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
