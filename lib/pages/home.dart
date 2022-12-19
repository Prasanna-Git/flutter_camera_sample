import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'package:camera_pic/pages/camera.dart';

import 'package:image_picker/image_picker.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ImagePicker _picker = ImagePicker();
  List<String> _locations = [
    'October',
    'November',
    'December',
    'January'
  ]; // Option 2
  late String _selectedLocation = _locations.first;
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  late final tmp;
  late final screenH;
  late final screenW;

  late final previewH;
  late final previewW;
  late final screenRatio;
  late final previewRatio;

  PickedFile? pickedImage;
  late File imageFile;
  bool _load = false;

// Obtain a list of the available cameras on the device.

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      startCamera();

      var tmp = MediaQuery.of(context).size;

      screenH = math.max(tmp.height, tmp.width);
      screenW = math.min(tmp.height, tmp.width);

      tmp = cameraController!.value.previewSize!;

      previewH = math.max(tmp.height, tmp.width);
      previewW = math.min(tmp.height, tmp.width);
      screenRatio = screenH / screenW;
      previewRatio = previewH / previewW;
    });
    // TODO: implement initState
  }

  void startCamera() async {
    cameras = await availableCameras();

    cameraController = CameraController(cameras[0], ResolutionPreset.ultraHigh);
    await cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((e) {
      print(e);
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  _openCamera(BuildContext context) async {
    final image = await cameraController.takePicture();
    this.setState(() {
      imageFile = (File(image.path)) as File;
      _load = false;
    });
    Navigator.of(context).pop();
  }

  _openGallery(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    this.setState(() {
      imageFile = File(pickedFile!.path);
      _load = false;
    });
  }

  Future<void> _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Please select an option"),
            content: SingleChildScrollView(
                child: ListBody(
              children: [
                GestureDetector(
                  child: Text("Gallery"),
                  onTap: () {
                    _openGallery(context);
                  },
                ),
                Padding(padding: EdgeInsets.all(10.0)),
                GestureDetector(
                  child: Text("Camera"),
                  onTap: () {
                    _openCamera(context);
                  },
                )
              ],
            )),
          );
        });
  }

  String _getCurrentMonth() {
    final f = _locations.elementAt(0);
    return f.toString();
  }

  Widget _imageView() {
    if (imageFile == null) {
      return Text("No Image");
    } else {
      return Image.file(
        imageFile,
        width: 400,
        height: 300,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    late GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.supervised_user_circle_rounded,
                          color: Colors.blue,
                        ),
                        DropdownButton(
                          hint: const Text(
                              'Please choose a location'), // Not necessary for Option 1
                          value: _locations[0],
                          onChanged: (val) => setState(
                              () => _selectedLocation = val.toString()),
                          items: _locations.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              key: UniqueKey(),
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        Icon(
                          Icons.notifications_on_rounded,
                          color: Colors.blue,
                        ),
                      ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                          child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Positioned(
                                      bottom: 100,
                                      left:
                                          0, //0 is starting at left, use it to give left-margin
                                      right:
                                          0, //0 is ending at right, use it to give right-margin
                                      child: Container(child: TextField())),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 50),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                                onPressed: () {
                                                  // the form is invalid.
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    _showChoiceDialog(context);
                                                  }
                                                },
                                                child:
                                                    const Text("Take Picture")),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            ElevatedButton(
                                                onPressed: () {
                                                  // the form is invalid.
                                                  if (_formKey.currentState!
                                                      .validate()) {}
                                                },
                                                child:
                                                    const Text("Upload Photo")),
                                          ])),
                                ],
                              )))
                    ],
                  ),
                  Row(children: [
                    Container(
                      child: _load == true
                          ? Container(
                              height: 200,
                              width: 200,
                              child: Column(
                                children: <Widget>[_imageView()],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Text("No Image")),
                            ),
                    ),
                  ]),
                ],
              )),
        ));
  }
}
