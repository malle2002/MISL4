import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerPage extends StatefulWidget {
  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng _pickedLocation = LatLng(41.9981, 21.4254);

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: EventController(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Pick Location"),
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _pickedLocation,
            zoom: 15,
          ),
          onTap: (LatLng location) {
            setState(() {
              _pickedLocation = location;
            });
          },
          markers: {
            Marker(
              markerId: MarkerId("picked_location"),
              position: _pickedLocation,
            ),
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context, _pickedLocation);
          },
          child: Icon(Icons.check),
        ),
      )
    );
  }
}
