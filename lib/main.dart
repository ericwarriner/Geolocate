import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show Response;

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
  late GoogleMapController? mapController;
  static const _marker = MarkerId('marker');
  final Set<Marker> _markers = {};
  var city = '';
  var country = '';
  var lat = 0.0; //39.7392;
  var lon = 0.0; //-104.9903;
  var ipaddress = '';
  bool detected = true;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _reset("");
  }

  void _reset(String possibleIp) async {
    var response = await fetchIPGeolocation(possibleIp);
    _parseResponseObject(response);

    mapController?.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
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
  }

  void _parseResponseObject(var response) {
    decode = jsonDecode(response);
    var potentialError = decode['error'].toString();
    if (potentialError == "error") {
      // ignore: use_build_context_synchronously
      gotoDetailsPage(context, 'Please enter a Valid IP address',
          const Icon(Icons.warning));
      return;
    }
    city = decode['CityName'].toString();
    if (city.isEmpty) {
      city = 'Unknown';
    }
    country = decode['CountryName'].toString();
    if (country.isEmpty) {
      country = 'Unknown';
    }
    lat = double.parse(decode['Latitude'].toString());
    lon = double.parse(decode['Longitude'].toString());
    if (detected) {
      ipaddress = 'This devices detected IP address is: ${decode['Ipaddress']}';
    } else {
      ipaddress = 'The searched IP address is: ${decode['Ipaddress']}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          mini: true,
          tooltip: "Geolocate This Device",
          hoverElevation: 50,
          onPressed: () {
            detected = true;
            _reset('');
          },
          child: const Icon(Icons.home),
        ),
        appBar: AppBar(
          title: const Text('IP v4/v6 Geolocator'),
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
                  //keyboardType: TextInputType.number,
                  onFieldSubmitted: (text) {
                    fieldText.clear();
                    _reset(text.trim());
                    detected = false;
                  },
                  autofocus: true,
                  decoration: InputDecoration(
                    focusColor: Colors.amber[300],
                    prefixIconColor: Colors.blue,
                    border: const OutlineInputBorder(),
                    hintText: 'Enter a IPv4/IP6 Addresses (88.88.88.88)',
                    prefixIcon: const Icon(Icons.login),
                  ),
                  // ignore: body_might_complete_normally_nullable
                  validator: (value) {
                    if (value == null ||
                        (value.length > 1 && value.length < 4)) {
                      return '';
                    } else if (value.isNotEmpty) {
                      bool ip4Valid = isIPValid(value);
                      return ip4Valid
                          ? null
                          : "Please enter a vaild IPv4/IPv6 Address";
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 170,
                child: Card(
                  shadowColor: Colors.blue,
                  elevation: 5,
                  child: Column(
                    children: [
                      Card(
                          elevation: 1,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: SizedBox(
                            height: 35,
                            child: Center(child: Text('$ipaddress')),
                          )),
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
                    'This product inludes includes GeoLite2 data created by MaxMind, available from https://www.maxmind.com \n\nApplication built using - Google Maps, Flutter, and Dart \n\nServer side deployed on - Google Kubernetes Engine (GKE) \n\nMany thanks to all! \n\nSource code is found on Github @ https://github.com/ericwarriner/Geolocate \n',
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
                child: SizedBox.expand(
                    //width: 200,
                    //height: 330,
                    child: ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  leading: icon,
                  iconColor: Colors.white,
                  title: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 20,
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
  Response? response;
  if (ipaddress.isEmpty) {
    response = await http.get(Uri.parse('https://i.luv.software/clientIP'));
  } else {
    if (isIPValid(ipaddress)) {
      response =
          await http.get(Uri.parse('https://i.luv.software/ip/$ipaddress'));
    } else {
      return '{"error":"error"}';
    }
  }

  if (response.statusCode == 200) {
    return response.body;
  } else {
    return '{"error":"error"}';
  }
}

bool isIPValid(String value) {
  // return true;
  if (RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$').hasMatch(value) ||
      RegExp(r'(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))')
          .hasMatch(value)) {
    return true;
  } else {
    return false;
  }
}
