import 'dart:async';
import 'dart:convert';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_geofencing/easy_geofencing.dart';
import 'package:easy_geofencing/enums/geofence_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:geofence/phpcode.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofence',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Geofence'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool showSplash=true;
  String currentPage='init';
  String previousPage='init';
  String userName='User Name';
  String contactNum='';
  String verId='';
  String userId='User Id';
  String adminDocId='';
  String userDocId='';
  double lat=0.0;
  double long=0.0;
  bool isIn=false;
  bool isSwitched = false;
  initMain()async{
    final prefs = await SharedPreferences.getInstance();
    if(await prefs.getInt('counter')==null){
      await prefs.setInt('counter', 0);
    }
    var url2 = Uri.parse("https://thundersmm.com/geofence/api/get_location.php");
    var response2 = await http.post(url2, body: jsonEncode({'device': 'deviceId'}));
    print('Response status: ${response2.statusCode}');
    print('Response body: ${response2.body}');

    if(response2.statusCode==200){
      var res2=jsonDecode(response2.body);
      print(res2['location']['latitude']);
      //print("this is it");
      prefs.setString('latitude', res2['location']['latitude']);
      prefs.setString('longitude', res2['location']['longitude']);
      prefs.setString('radius', res2['location']['radius']);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  MyPhpPage(title: 'Geofence', platitude: res2['location']['latitude'], plongitude: res2['location']['longitude'], pradius: res2['location']['radius'],)),
      );

    }else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('fatal Error Occurred'),
      ));
    }
  }
 @override
  void initState() {
   initMain();
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(),
    );
  }

}
