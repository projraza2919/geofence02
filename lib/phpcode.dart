import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:platform_device_id/platform_device_id.dart';
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
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_iot/wifi_iot.dart';

/*void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PhpPage());
}
class PhpPage extends StatelessWidget {
  const PhpPage({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofence',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyPhpPage(title: 'Geofence'),
    );
  }
}
*/



class MyPhpPage extends StatefulWidget {
  const MyPhpPage({super.key, required this.title,required this.platitude,required this.plongitude,required this.pradius});
  final String title;
  final String platitude;
  final String plongitude;
  final String pradius;
  @override
  State<MyPhpPage> createState() => _MyPhpPage();
}

class _MyPhpPage extends State<MyPhpPage> {

  bool showSplash=true;
  String currentPage='init';
  String previousPage='init';
  String userName='User Name';
  String contactNum='';
  String verId='';
  String userId='User Id';
  String errorLine='';
  String errorLine2='';
  String adminDocId='';
  String userDocId='';
  String latString='';
  String longString='';
  String radiusString='';
  double lat=0.0;
  double long=0.0;
  bool isIn=false;
  bool isSwitched = false;
  var textValue = 'Switch is OFF';
  String? deviceId;
  List userList = [];
  TextEditingController number=TextEditingController();
  TextEditingController userNameController=TextEditingController();
  TextEditingController userIdController=TextEditingController();
  TextEditingController emailController=TextEditingController();
  TextEditingController designationController=TextEditingController();
  TextEditingController departmentController=TextEditingController();
  TextEditingController contactController=TextEditingController();
  TextEditingController longController=TextEditingController();
  TextEditingController latController=TextEditingController();
  TextEditingController radiusController=TextEditingController();
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
    //print(lat+'-test');
    print(widget.platitude+'-test');
    print(widget.plongitude+'-test');
    EasyGeofencing.startGeofenceService(
        //pointedLatitude: latString,
        pointedLatitude: latString,
        //pointedLongitude: longString,
        pointedLongitude: longString,
        //22.546071, 88.287981
        radiusMeter: radiusString,
        eventPeriodInSeconds: 5
    );
    setLoc();
  }
  setLoc()async{
    //getLoc();
    BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
    StreamSubscription<GeofenceStatus> geofenceStatusStream = EasyGeofencing.getGeofenceStream()!.listen(
            (GeofenceStatus status) async {
          print(status);
          deviceId = await PlatformDeviceId.getDeviceId;
          if(status==GeofenceStatus.exit){
            print('exited-67687678');

            var url = Uri.parse("https://thundersmm.com/geofence/api/uninstall_check.php");
            var response = await http.post(url, body: jsonEncode({'device': deviceId}));
            print('Response status: ${response.statusCode}');
            print('Response body: ${response.body}');
            if(isIn==true){
              var url = Uri.parse("https://thundersmm.com/geofence/api/update_fence.php");
              var response = await http.post(url, body: jsonEncode({'device': deviceId,'fence':'o'}));
              print('Response status: ${response.statusCode}');
              print('Response body: ${response.body}');
              setState(() {
                isIn=false;
              });
            }
          }else{
            print('not exited');
            if(isIn==false){
              deviceId = await PlatformDeviceId.getDeviceId;
              var url = Uri.parse("https://thundersmm.com/geofence/api/update_fence.php");
              var response = await http.post(url, body: jsonEncode({'device': deviceId,'fence':'i'}));
              print('Response status: ${response.statusCode}');
              print('Response body: ${response.body}');
              setState(() {
                isIn=true;
              });
            }
            WiFiForIoTPlugin.isEnabled().then((val) async {
              print(val);
             await WiFiForIoTPlugin.disconnect;
              WiFiForIoTPlugin.setEnabled(false);
            });
            //await WifiConnector.connectToWifi(ssid: 'ssid', password: 'password');
            //await WiFiForIoTPlugin.disconnect();
            //setState(() async{  });
            //await WiFiForIoTPlugin.findAndConnect('ssid');
             //WiFiForIoTPlugin.setEnabled(false);
            //var benable=_bluetoothState.isEnabled;
            //if (benable)
            await FlutterBluetoothSerial.instance.requestDisable();
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

    }else{
      await Permission.location.request();
    }
  }
initLocation()async{
  final prefs = await SharedPreferences.getInstance();
  var url2 = Uri.parse("https://thundersmm.com/geofence/api/get_location.php");
  var response2 = await http.post(url2, body: jsonEncode({'device': 'deviceId'}));
  print('Response status: ${response2.statusCode}');
  print('Response body: ${response2.body}');

  if(response2.statusCode==200){
    var res2=jsonDecode(response2.body);
    //print(res2['location']['latitude']);
    //print("this is it");
    prefs.setString('latitude', res2['location']['latitude']);
    prefs.setString('longitude', res2['location']['longitude']);
    prefs.setString('radius', res2['location']['radius']);
    setState(() {
      latString=res2['location']['latitude'];
      longString=res2['location']['longitude'];
      radiusString=res2['location']['radius'];
    });

  }else{
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('fatal Error Occurred'),
    ));
  }
}
  login()async{

    deviceId = await PlatformDeviceId.getDeviceId;
    var url = Uri.parse("https://thundersmm.com/geofence/api/auth/login.php");
    var response = await http.post(url, body: jsonEncode({'device': deviceId}));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if(response.statusCode==200){
      checkGeo();
      var res=jsonDecode(response.body);
      if(res['status']==true){
        var url2 = Uri.parse("https://thundersmm.com/geofence/api/get_location.php");
        var response2 = await http.post(url2, body: jsonEncode({'device': deviceId}));
        print('Response status: ${response2.statusCode}');
        print('Response body: ${response2.body}');
        if(response2.statusCode==200){
          var res2=jsonDecode(response2.body);
          if(res['account']=='admin'){

            setState(() {
              latString=res2['location']['latitude'];
              longString=res2['location']['longitude'];
              radiusString=res2['location']['radius'];
              currentPage='admin';
              userName=res['name'];
              showSplash=false;
            });
          }else{
            setState(() {
              latString=res2['location']['latitude'];
              longString=res2['location']['longitude'];
              radiusString=res2['location']['radius'];
              currentPage='home';
              userName=res['name'];
              showSplash=false;
            });
          }

        }else{
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('fatal Error Occurred'),
          ));
        }

      }else{
        if(res['account']!='blank'){
          if(res['userverified']==true){
            if(res['adminverified']==true){

            }else{
              setState(() {
                currentPage='error';
                showSplash=false;
                errorLine='Please wait, Admin will verify your account';
              });
            }
          }else{

            setState(() {
              currentPage='error';
              showSplash=false;
              errorLine='Please verify your account';
            });
          }
        }else{
          setState(() {
            currentPage='register';
            showSplash=false;
          });
        }

      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unexpected error Occurred'),
      ));
    }
  }
  registerCheck(String num)async{
    FirebaseFirestore.instance
        .collection('Profile')
        .where('number', isEqualTo: num)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if(querySnapshot.docs.isEmpty){
        //TODO Show AlertBox
        setState(() {
          contactNum=num;
          currentPage='register';
        });
      }else{
        querySnapshot.docs.forEach((doc) async{
          setState(() {
            userName=doc['name'];
            userId=doc['userid'];
            currentPage='home';
          });
        });
      }
    }).onError((error, stackTrace) {
      //TODO do error management

      print(error);
    });
  }

  sendOtp(String otp)async{

  }
  getProfile()async{
    if(currentPage=='admin'){
      setState(() {
        userList=[];
      });
      FirebaseFirestore.instance
          .collection('Profile')
          .where('status', isEqualTo: 'user')
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) async{
          userList.add({
            'name':doc['name'],
            'userid':doc['userid'],
            'number':doc['number'],
            'fence':doc['fence'],
          });

        });
      }).onError((error, stackTrace) {
        //TODO do error management
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("error Occurred"),
        ));
        print(error);
      });

      setState(() {

      });
    }
  }
  timeLoop()async{
    String time='';
    Timer mytimer = Timer.periodic(Duration(seconds: 5), (timer) {
      DateTime timenow = DateTime.now();  //get current date and time
      //time = timenow.hour.toString() + ":" + timenow.minute.toString() + ":" + timenow.second.toString();
      //getLoc();
      getProfile();
      setState(() {

      });
      //print(time);
      //setLoc();
      //mytimer.cancel() //to terminate this timer
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      latString=widget.platitude;
      longString=widget.plongitude;
      radiusString=widget.pradius;
    });
    super.initState();
    Timer(const Duration(seconds: 2), (){
      //initLocation();
      login();
    }
    );
    //timeLoop();
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
      //setLoc();
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
                          child: TextField (
                            controller: userNameController,
                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter Name*'
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
                          child: TextField (
                            controller: userIdController,
                            maxLength: 8,
                            keyboardType: TextInputType.number,
                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                counter: Offstage(),
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter User ID*'
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
                          child: Icon(Icons.mail,size: 25,color: Colors.grey,),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width*0.70-55,
                          child: TextField (
                            controller: emailController,

                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter Email*'
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
                          child: Icon(Icons.leaderboard,size: 25,color: Colors.grey,),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width*0.70-55,
                          child: TextField (
                            controller: designationController,

                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter Designation*'
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
                          child: Icon(Icons.countertops,size: 25,color: Colors.grey,),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width*0.70-55,
                          child: TextField (
                            controller: departmentController,

                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                hintText: 'Enter Department*'
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
                          child: Icon(Icons.phone,size: 25,color: Colors.grey,),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width*0.70-55,
                          child: TextField (
                            controller: contactController,
                            maxLength: 10,

                            cursorColor: Color.fromRGBO(28, 179, 189, 0),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                counter: Offstage(),
                                hintText: 'Enter Contact*'
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
                    var url = Uri.parse("https://thundersmm.com/geofence/api/auth/register.php");
                    var designation=designationController.text;
                    var department=departmentController.text;
                    var contact=contactController.text;
                    if(designation.length<1){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Enter your Designation'),
                      ));
                      return;
                    }
                    if(department.length<1){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Enter your Department'),
                      ));
                      return;
                    }
                    if(contact.length<1){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Enter your Contact'),
                      ));
                      return;
                    }
                    if(userIdController.text.length<1){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Enter your Name'),
                      ));
                      return;
                    }
                    if(userIdController.text.length<1){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Enter your UserId'),
                      ));
                      return;
                    }
                    if(emailController.text.length<1){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Enter your Email'),
                      ));
                      return;
                    }
                    var response = await http.post(url, body: jsonEncode({
                      'device': deviceId,
                      'name': userNameController.text,
                      'userid': userIdController.text,
                      'email': emailController.text,
                      'department': department,
                      'designation': designation,
                      'contact': contact,
                    }));
                    print('Response status: ${response.statusCode}');
                    print('Response body: ${response.body}');

                    if(response.statusCode==200){
                      var res=jsonDecode(response.body);
                      if(res['status']==true){
                        setState(() {

                          errorLine='Open Email and do verify your Account';
                          currentPage='error';
                        });
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(res['msg']),
                        ));
                      }
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('fatal error Occurred, Please contact Admin'),
                      ));
                    }
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
      getProfile();
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
                child: Center(
                  child: TextButton(
                    onPressed: () async{
                      var url = 'https://thundersmm.com/geofence/index.php?uid=gg54564hghahhgs234567hsgfshhhpps545644564';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url),mode: LaunchMode.inAppWebView);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: Text('Visit Admin'),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }
    if(currentPage=='error'){
      getProfile();
      setState(() {
        showPage=Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Text(errorLine,style: GoogleFonts.roboto(
                fontSize: 30,
                color: Color.fromRGBO(97, 116, 136, 1)
            ),
            ),
          ),
        );
      });
    }
    return Scaffold(

      body: showPage, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
