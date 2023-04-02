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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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
  String verId='';
  String userId='User Id';
  double lat=0.0;
  double long=0.0;
  bool isIn=false;
  bool isSwitched = false;
  var textValue = 'Switch is OFF';
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
    final prefs = await SharedPreferences.getInstance();
    final String? lat = prefs.getString('latitude');
    final String? long = prefs.getString('longitude');
    final String? radius = prefs.getString('radius');

    EasyGeofencing.startGeofenceService(
        pointedLatitude: lat,
        pointedLongitude: long,
        //22.546071, 88.287981
        radiusMeter: radius,
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
  }
  checkGeo()async{
    var status = await Permission.location.status;
    if(status.isGranted){
      getLoc();
      login();
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
          showDialog<void>(
            context: context,
            // barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Failed'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: const <Widget>[
                      Text('Failed to Connect Server'),
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
                ],
              );
            },
          );
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
          await prefs.setString('radius', doc['radius']);
          checkGeo();
        });
      }
    }).onError((error, stackTrace) {
      //TODO do error management

      print(error);
    });

    /* var status = await Permission.location.status;
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
    }*/

    /*FirebaseFirestore.instance
        .collection('data')
        .add({'text': 'data added through app'});*/

  }

  sendOtp(String otp)async{

  }
  getProfile()async{

  }
  timeLoop()async{
    String time='';
    Timer mytimer = Timer.periodic(Duration(seconds: 5), (timer) {
      DateTime timenow = DateTime.now();  //get current date and time
      time = timenow.hour.toString() + ":" + timenow.minute.toString() + ":" + timenow.second.toString();
      setState(() {

      });
      print(time);
      //setLoc();
      //mytimer.cancel() //to terminate this timer
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(const Duration(seconds: 5), (){
      setState(() {
        showSplash=false;
        currentPage='login';
      });
    }
    );
    timeLoop();
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
                          child: TextField (
                            controller: number,
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
                  onTap: ()async{
                    var temp=number.text;
                    await FirebaseAuth.instance.verifyPhoneNumber(
                      phoneNumber: '+91'+temp,
                      verificationCompleted: (PhoneAuthCredential credential) {
                        setState(() {
                          currentPage='home';
                        });
                      },
                      verificationFailed: (FirebaseAuthException e) {
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: Text(e.code),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: (){
                                      Navigator.of(context).pop();
                                    }, child: Card(
                                  color: Colors.blueAccent,
                                  child: Container(
                                    margin: const EdgeInsets.all(5),
                                    child: const Text('Back',style: TextStyle(color: Colors.white),),
                                  ),
                                )
                                )
                              ],
                            )
                        );
                      },
                      codeSent: (String verificationId, int? resendToken) {
                        setState(() {
                          verId=verificationId;
                          currentPage='otp';
                        });
                      },
                      timeout: const Duration(seconds: 60),
                      codeAutoRetrievalTimeout: (String verificationId) {},
                    );
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
                  onSubmit: (String verificationCode)async{
                    //LawyerDocument
                    FirebaseAuth auth = FirebaseAuth.instance;
                    PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verId, smsCode: verificationCode);
                    await auth.signInWithCredential(credential).then((value) {
                      if(value.user==null){
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: Text('Failed To Login with Otp'),
                              actions: <Widget>[
                                TextButton(
                                    onPressed: (){
                                      Navigator.of(context).pop();
                                    }, child: Card(
                                  color: Colors.blueAccent,
                                  child: Container(
                                    margin: const EdgeInsets.all(5),
                                    child: const Text('Back',style: TextStyle(color: Colors.white),),
                                  ),
                                )
                                )
                              ],
                            )
                        );
                      }else{
                        login();
                      }
                    });

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
