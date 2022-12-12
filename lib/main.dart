import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(
      home: GeoLocateIP(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

Map<String, dynamic> decode = {};

class GeoLocateIP extends StatefulWidget {
  const GeoLocateIP({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<GeoLocateIP> {
  final fieldText = TextEditingController();
  late GoogleMapController mapController;
  static const _marker = MarkerId('marker');
  final Set<Marker> _markers = {};
  var city = '';
  var country = '';
  var lat = 0.0; //39.7392;
  var lon = 0.0; //-104.9903;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _reset(String ipaddress) async {
    if (isIP4Valid(ipaddress)) {
      var string = await fetchIPGeolocation(ipaddress);
      decode = jsonDecode(string);
      city = decode['CityName'].toString();
      country = decode['CountryName'].toString();
      lat = decode['Latitude'];
      lon = decode['Longitude'];
      //mapController.hideMarkerInfoWindow(_marker);
      mapController.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(lat, lon),
        zoom: 12,
      )));
      setState(() {
        _markers.clear();
        _markers.add(Marker(
          markerId: _marker,
          position: LatLng(lat, lon),
          icon: BitmapDescriptor.defaultMarker,
        ));
      });
    } else {
      //we need to display a message to the usr
      gotoDetailsPage(context, 'Please enter a Valid IP address',
          const Icon(Icons.warning));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        appBar: AppBar(
          title: const Text('IPv4 Geolocator'),
          backgroundColor: Colors.blue[400],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  controller: fieldText,
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (text) {
                    fieldText.clear();
                    _reset(text);
                  },
                  autofocus: true,
                  decoration: InputDecoration(
                    focusColor: Colors.amber[300],
                    prefixIconColor: Colors.blue,
                    border: const OutlineInputBorder(),
                    hintText: 'Enter IPv4 Address (e.g. 88.88.88.88)',
                    prefixIcon: const Icon(Icons.login),
                  ),
                  // ignore: body_might_complete_normally_nullable
                  validator: (value) {
                    if (value == null ||
                        (value.length > 1 && value.length < 4)) {
                      return '';
                    } else if (value.isNotEmpty) {
                      bool ip4Valid = isIP4Valid(value);
                      return ip4Valid
                          ? null
                          : "Please enter a vaild IP4 Address";
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 120,
                child: Card(
                  shadowColor: Colors.blue,
                  elevation: 30,
                  child: Column(
                    children: [
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -4),
                        leading: const Icon(Icons.location_pin),
                        title: Text('City: $city'),
                        subtitle: Text('Country: $country'),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          TextButton(
                            child: Text('Latitude $lat'),
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: '$lat $lon'));
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            child: Text('Longitude $lon'),
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: '$lat $lon'));
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                initialCameraPosition: const CameraPosition(
                    target: LatLng(39.7392, -104.9903), zoom: 2.0),
                markers: _markers,
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomAppBar(),
      ),
    );
  }

  bool isIP4Valid(String value) {
    bool ip4Valid =
        RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$').hasMatch(value);
    return ip4Valid;
  }
}

class _BottomAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      //shape: shape,
      color: Colors.blue,
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Want to know more?',
              icon: const Icon(Icons.favorite),
              onPressed: () {
                gotoDetailsPage(
                    context,
                    'This product inludes includes GeoLite2 data created by MaxMind, available from https://www.maxmind.com \n\nApplication built using - Google Maps, Flutter, and Dart \n\nServer side deployed on - Google Kubernetes Engine (GKE) \n\nMany thanks to all! \n\nSource code is found on Github @ https://github.com/ericwarriner/ericonjava \n',
                    const Icon(Icons.message));
              },
            )
          ],
        ),
      ),
    );
  }
}

void gotoDetailsPage(BuildContext context, String message, Icon icon) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
        ),
        body: Center(
          child: Hero(
            tag: 'uniqueTag',
            child: Card(
              elevation: 20,
              color: Colors.blue,
              child: InkWell(
                child: SizedBox(
                    width: 200,
                    height: 330,
                    child: ListTile(
                      visualDensity: const VisualDensity(vertical: -4),
                      leading: icon,
                      iconColor: Colors.white,
                      title: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    )),
              ),
            ),
          ),
        ),
      );
    },
  ));
}

Future<String> fetchIPGeolocation(String ipaddress) async {
  final response =
      await http.get(Uri.parse('http://i.luv.software/ip/$ipaddress'));

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to Load');
  }
}
