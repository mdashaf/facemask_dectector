import 'package:camera/camera.dart';
import 'package:facemask_dectector/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
{
  late CameraImage imgCamera;
  late CameraController cameraController;
  bool isWorking = false;
  String result="";

  initCamera()
  {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value)
    {
      if(!mounted)
      {
        return;
      }

      setState(() {
        cameraController.startImageStream((imageFromStream) =>
        {
          if(!isWorking)
          {
            isWorking = true,
            imgCamera = imageFromStream,
            runModelOnFrame(),

          }
        });
      });
    });
  }
  loadModel() async
  {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",

    );
  }

  runModelOnFrame() async
  {
    if(imgCamera != null)
    {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera.planes.map((plane)
        {
          return plane.bytes;
        }).toList(),
        imageHeight: imgCamera.height,
        imageWidth: imgCamera.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.1,
        asynch: true,
      );
      result = "";



      recognitions?.forEach((response)
      {
        result += response["label"] + "\n";
      });

      setState(() {
        result;
      });

      isWorking = false;

    }
  }

  @override
  void initState() {

    super.initState();

    initCamera();
    loadModel();

  }


  @override
  Widget build(BuildContext context)
  {
    Size size =MediaQuery.of(context).size;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: Text(
                  result,
                  style: TextStyle(
                    backgroundColor: Colors.black54,
                    fontSize: 30,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Positioned(
                top: 0,
                left: 0,
                width: size.width,
                height: size.height-100,
                child: (!cameraController.value.isInitialized)
                    ? Container()
                    : AspectRatio(
                        aspectRatio: cameraController.value.aspectRatio,
                  child: CameraPreview(cameraController),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

