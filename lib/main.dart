import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lab4/models/ExamEvent.dart';
import 'package:lab4/screens/AddEventPage.dart';
import 'package:lab4/screens/CalendarPage.dart';
import 'package:lab4/screens/MapPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:workmanager/workmanager.dart';

class EventProvider with ChangeNotifier {
  late Box<ExamEvent> _eventBox;
  final List<ExamEvent> _events = [];

  List<ExamEvent> get events => _events;

  EventProvider() {
    _initializeEvents();
  }

  Future<void> _initializeEvents() async {
    _eventBox = await Hive.openBox<ExamEvent>('exam_events');
    _events.addAll(_eventBox.values);
    notifyListeners();

    for (var event in _events) {
      _registerGeofence(event);
    }
  }

  void removeEvent(ExamEvent event) {
    int index = _events.indexOf(event);
    if (index != -1) {
      _events.removeAt(index);
      _eventBox.deleteAt(index);
      bg.BackgroundGeolocation.removeGeofence(event.title);
      notifyListeners();
    }
  }

  void addEvent(ExamEvent event) {
    _events.add(event);
    _eventBox.add(event);
    notifyListeners();

    _registerGeofence(event);
  }

  void _registerGeofence(ExamEvent event) {
    bg.BackgroundGeolocation.addGeofence(bg.Geofence(
      identifier: event.title,
      radius: 100,
      latitude: event.latitude,
      longitude: event.longitude,
      notifyOnEntry: true,
      notifyOnExit: false,
      notifyOnDwell: false,
      extras: {"eventTitle": event.title, "eventLocation": event.location},
    )).then((bool success) {
      print('[addGeofence] success: $success');
    }).catchError((error) {
      print('[addGeofence] ERROR: $error');
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExamEventAdapter());

  await _checkAllPermissions();

  await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Color(0xFF9D50DD),
            ledColor: Colors.white
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group'
        )
      ],
      debug: true
  );

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
    if (event.action == "ENTER") {
      print("Geofence entered: ${event.identifier}");
      String? title = event.extras?["eventTitle"];
      String? location = event.extras?["eventLocation"];
      if (title != null && location != null) {
        _sendNotification(title, location);
      } else {
        print("Missing eventTitle or eventLocation in extras.");
      }
    } else {
      print("Geofence action: ${event.action}");
    }
  });

  bg.BackgroundGeolocation.ready(bg.Config(
    desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
    distanceFilter: 50.0,
    stopOnTerminate: false,
    startOnBoot: true,
    enableHeadless: true,
    debug: false,
    logLevel: bg.Config.LOG_LEVEL_OFF,
    geofenceProximityRadius: 100,
    geofenceInitialTriggerEntry: true,
  )).then((bg.State state) {
    if (!state.enabled) {
      bg.BackgroundGeolocation.start();
    }
  });

  bg.BackgroundGeolocation.registerHeadlessTask(backgroundGeofenceCallback);

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Workmanager().registerOneOffTask(
    "uniqueTaskName",
    "checkGeofenceTask",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Exam Schedule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => CalendarPage(),
        '/add-event': (context) => AddEventPage(),
        '/map': (context) => MapPage(Provider.of<EventProvider>(context).events),
      },
    );
  }
}

void _sendNotification(String title, String location) {
  print("Sending notification: $title at $location");
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'basic_channel',
      title: 'You are near an event!',
      body: '$title is scheduled at $location.',
    ),
  ).then((value) {
    print("Notification sent successfully");
  }).catchError((error) {
    print("Failed to send notification: $error");
  });
}


Future<void> _checkAllPermissions() async {
  LocationPermission locationPermission = await Geolocator.checkPermission();
  if (locationPermission == LocationPermission.denied) {
    locationPermission = await Geolocator.requestPermission();
  }

  if (locationPermission == LocationPermission.deniedForever) {
    print("Location permission is permanently denied.");
    return;
  }

  bool isNotificationAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isNotificationAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  var status = await Permission.locationAlways.status;
  if (status.isDenied) {
    await Permission.locationAlways.request();
  }
}

@pragma('vm:entry-point')
void backgroundGeofenceCallback(bg.HeadlessEvent headlessEvent) async {
  bg.GeofenceEvent geofenceEvent = headlessEvent.event;
  print("Background Geofence Callback Triggered: ${geofenceEvent.identifier}");
  if (geofenceEvent.action == "ENTER") {
    String? title = geofenceEvent.extras?["eventTitle"];
    String? location = geofenceEvent.extras?["eventLocation"];
    if (title != null && location != null) {
      print("Sending background notification for $title at $location");
      _sendNotification(title, location);
    } else {
      print("Missing eventTitle or eventLocation in extras.");
    }
  }
}


void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("WorkManager task executed: $task");
    if (task == "flutter_background_geolocation_geofence") {
      print("Executing geofence task.");
      await Hive.initFlutter();
      Hive.registerAdapter(ExamEventAdapter());
      if (inputData != null) {
        backgroundGeofenceCallback(inputData as bg.HeadlessEvent);
      }
    }
    return Future.value(true);
  });
}


