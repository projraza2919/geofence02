import 'dart:async';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_geofencing/easy_geofencing.dart';
import 'package:easy_geofencing/enums/geofence_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String userId='User Id';
  double lat=0.0;
  double long=0.0;
  bool isIn=false;
  bool isSwitched = false;
  var textValue = 'Switch is OFF';
  String time="";
  TextEditingController number=TextEditingController();
  void toggleSwitch(bool value) {

    if(isSwitched == false)
    {
      setState(() {
        isSwitched = true;
        textValue = 'Switch Button is ON';
      });
      print('Switch Button is ON');
    }
    else
    {
      setState(() {
        isSwitched = false;
        textValue = 'Switch Button is OFF';
      });
      print('Switch Button is OFF');
    }
  }

  getLoc()async{
    EasyGeofencing.startGeofenceService(
        pointedLatitude: '12.9612170',
        pointedLongitude: '77.6501340',
        //22.546071, 88.287981
        //22.54889415822827, 88.28767289724146
        //22.545860199403187, 88.28645759276466
        radiusMeter: '100',
        //22.547906864476225, 88.2874014934167
        //22.39391957960549, 88.40290784110435
        //12.9258520, 77.7318710
        eventPeriodInSeconds: 5
    );
  }
  setLoc()async{
    StreamSubscription<GeofenceStatus> geofenceStatusStream = EasyGeofencing.getGeofenceStream()!.listen(
            (GeofenceStatus status) {
          print(status);
          if(status==GeofenceStatus.exit){
            //print('exited');
            setState(() {
              isIn=false;
            });
          }else{
            //print('not exited');
            setState(() {
              isIn=true;
            });
          }

          setState(() {
            //stat=status.toString();
          });
        });
    geofenceStatusStream.resume();
  }
  checkGeo()async{
    var status = await Permission.location.status;
    if(status.isGranted){
      getLoc();
    }else{
      await Permission.location.request();
    }
  }

  login()async{
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) async {
      if (user == null){
        //TODO To register Page
        setState(() {
          currentPage='login';
        });
      } else {
        var number=user.phoneNumber;
        FirebaseFirestore.instance
            .collection('Profile')
            .where('number', isEqualTo: user.phoneNumber)
            .get()
            .then((QuerySnapshot querySnapshot) {
          if(querySnapshot.docs.isEmpty){
            //TODO Create Profile
            setState(() {
              currentPage='register';
            });
          }else{
            querySnapshot.docs.forEach((doc) async{
              //print(doc["first_name"]);
              //var update=doc["update"];
              if(doc['status']=='admin'){
                setState(() {
                  currentPage='admin';
                  userName=doc['name'];
                  userId=doc['userid'];
                });
              }else{
                setState(() {
                  currentPage='home';
                  userName=doc['name'];
                  userId=doc['userid'];
                });
              }
            });
          }
        }).onError((error, stackTrace) {
          //TODO do error management

          print(error);
        });

      }
    });
  }
  accountInit()async{
    final prefs = await SharedPreferences.getInstance();
    FirebaseFirestore.instance
        .collection('Profile')
        .where('status', isEqualTo: 'admin')
        .get()
        .then((QuerySnapshot querySnapshot) {
      if(querySnapshot.docs.isEmpty){
        //TODO Show AlertBox

      }else{
        querySnapshot.docs.forEach((doc) async{
          //print(doc["first_name"]);
          await prefs.setString('latitude', doc['latitude']);
          await prefs.setString('longitude', doc['longitude']);
        });
      }
    }).onError((error, stackTrace) {
      //TODO do error management

      print(error);
    });

    var status = await Permission.location.status;
// You can can also directly ask the permission about its status.
    if (status.isGranted) {
      login();
      // The OS restricts access, for example because of parental controls.
    }else{
      showDialog<void>(
        context: context,
        // barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Permission Required'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text('You must give access to proceed with the app'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Give access'),
                onPressed: () async{
                  if (await Permission.location.request().isGranted) {
                    login();
                  }
                  if (await Permission.location.request().isPermanentlyDenied) {
                    openAppSettings();
                  }
                },
              ),
            ],
          );
        },
      );
    }

    /*FirebaseFirestore.instance
        .collection('data')
        .add({'text': 'data added through app'});*/

  }

  sendOtp(String otp)async{

  }

  @override
  void initState() {
    // TODO: implement initState
    checkGeo();
    getLoc();
    setLoc();
    currentPage='home';
    super.initState();
    Timer mytimer = Timer.periodic(Duration(seconds: 5), (timer) {
      DateTime timenow = DateTime.now();  //get current date and time
      time = timenow.hour.toString() + ":" + timenow.minute.toString() + ":" + timenow.second.toString();
      setState(() {

      });

      //setLoc();
      //mytimer.cancel() //to terminate this timer
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget showPage=Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
              'assets/splash.gif'),
          fit: BoxFit.fill,
        ),
      ),
    );
    if(currentPage=='home'){
      setState(() {
        showPage=Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              SizedBox(height: 60,),
              Container(
                margin: EdgeInsets.only(left: 30,top: 30,right: 10),
                width: MediaQuery.of(context).size.width,
                child: Text('Welcome $userName',style: GoogleFonts.roboto(
                    fontSize: 30,
                    color: Color.fromRGBO(97, 116, 136, 1)
                ),),
              ),
              Container(
                margin: EdgeInsets.only(left: 30,top: 30,right: 10),
                width: MediaQuery.of(context).size.width,
                child: Text('You Are currently ${isIn? 'Inside' : 'Outside'} the Area',style: GoogleFonts.roboto(
                    fontSize: 20,

                    color: Color.fromRGBO(97, 116, 136, 1)
                ),),
              ),
            ],
          ),
        );
      });
    }
    if(currentPage=='login'){
      setState(() {
        showPage=SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6)
                      )
                  ),
                  child: Container(
                    height: 47,
                    width: MediaQuery.of(context).size.width*0.70,
                    color: Color.fromRGBO(236, 236, 236, 1),
                    child: Row(
                      children: [
                        Container(
                          height: 47,
                          width: 47,
                          alignment: Alignment.center,
                          child: Icon(Icons.smartphone,size: 25,color: Colors.grey,),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width*0.70-55,
                          child: const TextField (
                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter Mobile number'
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                InkWell(
                  onTap: (){
                    //LogReg

                  },
                  child: Card(
                    color: const Color.fromRGBO(28, 179, 189, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.0), //<-- SEE HERE
                    ),
                    elevation: 2,
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width*0.70-10,
                      height: 36,
                      child: Text('LOGIN',style: GoogleFonts.roboto(fontSize: 13,fontWeight: FontWeight.bold,color: Colors.white),),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
    if(currentPage=='otp'){
      setState(() {
        showPage=SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OtpTextField(

                  filled: true,
                  fillColor: Colors.white,
                  focusedBorderColor: Colors.white,
                  numberOfFields: 6,
                  borderColor: Colors.white,
                  //set to true to show as box or false to show as dash
                  showFieldAsBox: true,
                  //runs when a code is typed in
                  onCodeChanged: (String code) {
                    //handle validation or checks here
                  },
                  //runs when every textfield is filled
                  onSubmit: (String verificationCode){
                    //LawyerDocument

                  }, // end onSubmit
                ),
                SizedBox(height: 10,),
                InkWell(
                  onTap: (){
                    //LogReg

                  },
                  child: Card(
                    color: const Color.fromRGBO(28, 179, 189, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.0), //<-- SEE HERE
                    ),
                    elevation: 2,
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width*0.70-10,
                      height: 36,
                      child: Text('VERIFY OTP',style: GoogleFonts.roboto(fontSize: 13,fontWeight: FontWeight.bold,color: Colors.white),),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
    if(currentPage=='register'){
      setState(() {
        showPage=SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6)
                      )
                  ),
                  child: Container(
                    height: 47,
                    width: MediaQuery.of(context).size.width*0.70,
                    color: Color.fromRGBO(236, 236, 236, 1),
                    child: Row(
                      children: [
                        Container(
                          height: 47,
                          width: 47,
                          alignment: Alignment.center,
                          child: Icon(Icons.person,size: 25,color: Colors.grey,),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width*0.70-55,
                          child: const TextField (
                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter Name'
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6)
                      )
                  ),
                  child: Container(
                    height: 47,
                    width: MediaQuery.of(context).size.width*0.70,
                    color: Color.fromRGBO(236, 236, 236, 1),
                    child: Row(
                      children: [
                        Container(
                          height: 47,
                          width: 47,
                          alignment: Alignment.center,
                          child: Icon(Icons.numbers,size: 25,color: Colors.grey,),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width*0.70-55,
                          child: const TextField (
                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter User ID'
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                InkWell(
                  onTap: (){
                    //LogReg

                  },
                  child: Card(
                    color: const Color.fromRGBO(28, 179, 189, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.0), //<-- SEE HERE
                    ),
                    elevation: 2,
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width*0.70-10,
                      height: 36,
                      child: Text('REGISTER',style: GoogleFonts.roboto(fontSize: 13,fontWeight: FontWeight.bold,color: Colors.white),),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
    if(currentPage=='admin'){
      setState(() {
        showPage=Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              SizedBox(height: 60,),
              Container(
                margin: EdgeInsets.only(left: 30,top: 30,right: 10),
                width: MediaQuery.of(context).size.width,
                child: Text('Hello Admin',style: GoogleFonts.roboto(
                    fontSize: 30,
                    color: Color.fromRGBO(97, 116, 136, 1)
                ),),
              ),
              Container(
                height: MediaQuery.of(context).size.height-140,
                width: MediaQuery.of(context).size.width,
                child: SafeArea(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: <Widget>[
                        ButtonsTabBar(
                          contentPadding: EdgeInsets.only(left: 45,right: 45,top: 5,bottom: 5),
                          backgroundColor: const Color.fromRGBO(28, 179, 189, 1),
                          unselectedBackgroundColor: Colors.white,
                          unselectedLabelStyle: TextStyle(color: Colors.grey),
                          labelStyle:
                          TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          tabs: [
                            Tab(
                              text: "Live Status",
                            ),
                            Tab(
                              text: "User List",
                            ),


                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: <Widget>[
                              ListView.builder(
                                  itemCount: 5,
                                  itemBuilder: (BuildContext context, int index) {
                                    return ListTile(

                                      trailing: const Icon(Icons.circle,color: Colors.red,size: 15,),
                                      title: Text("User Name $index"),
                                      subtitle: Text("User ID $index"),
                                    );
                                  }),
                              ListView.builder(
                                  itemCount: 5,
                                  itemBuilder: (BuildContext context, int index) {
                                    return ListTile(

                                      trailing: Switch(
                                        onChanged: toggleSwitch,
                                        value: isSwitched,
                                        activeColor: Colors.white70,
                                        activeTrackColor: Colors.green,
                                        inactiveThumbColor: Colors.white70,
                                        inactiveTrackColor: Colors.red,
                                      ) ,
                                      title: Text("User Name $index"),
                                      subtitle: Text("User ID $index"),
                                    );
                                  }),


                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }
    return Scaffold(

      body: showPage, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
