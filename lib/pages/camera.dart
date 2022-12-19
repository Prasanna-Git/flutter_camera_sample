import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:http_parser/http_parser.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String imagePath1 = "";

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    var result;
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          // If the Future is complete, display the preview.
                          return CameraPreview(_controller);
                        } else {
                          // Otherwise, display a loading indicator.
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                    Flexible(
                        child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Positioned(
                                    bottom: 75,
                                    left:
                                        0, //0 is starting at left, use it to give left-margin
                                    right:
                                        0, //0 is ending at right, use it to give right-margin
                                    child: Container(child: TextField())),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 25),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                              onPressed: () async {
                                                // Take the Picture in a try / catch block. If anything goes wrong,
                                                // catch the error.
                                                try {
                                                  // Ensure that the camera is initialized.
                                                  await _initializeControllerFuture;
                                                  await _controller
                                                      .setFlashMode(
                                                          FlashMode.off);
                                                  // Attempt to take a picture and get the file `image`
                                                  // where it was saved.
                                                  final image =
                                                      await _controller
                                                          .takePicture();

                                                  if (!mounted) return;

                                                  // If the picture was taken, display it on a new screen.
                                                  final result =
                                                      await Navigator.of(
                                                              context)
                                                          .push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DisplayPictureScreen(
                                                        // Pass the automatically generated path to
                                                        // the DisplayPictureScreen widget.
                                                        imagePath: image.path,
                                                      ),
                                                    ),
                                                  );
                                                  if (result != null) {
                                                    print("gggggggg");
                                                    print(result);
                                                    imagePath1 = result;
                                                  }
                                                } catch (e) {
                                                  // If an error occurs, log the error to the console.
                                                  print(e);
                                                }

                                                setState(() {
                                                  imagePath1 = result;
                                                });
                                              },
                                              child:
                                                  const Text("Take Picture")),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          ElevatedButton(
                                              onPressed: () async {
                                                print("object");
                                                //imagePath1 =
                                                //  '/data/user/0/com.example.camera_pic/cache/CAP8136754538872562232.jpg';
                                                print(imagePath1);

                                                http.MultipartRequest request =
                                                    http.MultipartRequest(
                                                  'POST',
                                                  Uri.parse(
                                                      'http://192.168.84.57:5000/upload'),
                                                );

                                                request.files.add(
                                                  new http.MultipartFile.fromBytes(
                                                      "file",
                                                      File(imagePath1)
                                                          .readAsBytesSync(),
                                                      filename: "Photo.jpg",
                                                      contentType:
                                                          new MediaType(
                                                              "image", "jpg")),
                                                );
                                                Map<String, String> headers = {
                                                  "Content-Type":
                                                      "application/json"
                                                };
                                                request.headers.addAll(headers);
                                                http.StreamedResponse r =
                                                    await request.send();
                                                print(r.statusCode);
                                                print(await r.stream
                                                    .transform(utf8.decoder)
                                                    .join());
                                                // the form is invalid.
                                                /* var url = Uri.https(
                                                    '6245-103-176-10-189.ngrok.io',
                                                    '/',
                                                    {'q': '{http}'});

                                                // Await the http get response, then decode the json-formatted response.
                                                var response =
                                                    await http.post(url);
                                                if (response.statusCode ==
                                                    200) {
                                                  var jsonResponse = convert
                                                          .jsonDecode(
                                                              response.body)
                                                      as Map<String, dynamic>;
                                                  var itemCount = jsonResponse[
                                                      'totalItems'];
                                                  print(
                                                      'Number of books about http: $itemCount.');
                                                } else {
                                                  print(
                                                      'Request failed with status: ${response.statusCode}.');
                                                }*/
                                              },
                                              child:
                                                  const Text("Upload Photo")),
                                          Text(imagePath1)
                                        ])),
                              ],
                            )))
                  ]))),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[Image.file(File(imagePath))])),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context, imagePath);
          },
          child: Icon(Icons.check)),
    );
  }
}
