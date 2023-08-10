import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var controller = TextEditingController();
  Uint8List? data;
  VideoPlayerController? videoController;
  var uuidType = "v1 (time-based)";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    videoController = VideoPlayerController.networkUrl(Uri.parse("http://10.0.2.2:8487/video/0"))
      ..initialize()
      ..addListener(() {
        setState(() {});
      })
      ..play();
    setState(() {});
    Timer(Duration(milliseconds: 100), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var uuid = const Uuid();
            if (uuidType.contains("v1")) {
              controller.text = uuid.v1();
            } else if (uuidType.contains("v4")) {
              controller.text = uuid.v4();
            } else if (uuidType.contains("v5")) {
              controller.text = uuid.v5(Uuid.NAMESPACE_DNS, controller.text);
            } else if (uuidType.contains("URL")) {
              await launchUrl(Uri.parse(controller.text));
            }
          },
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PopupMenuButton(
                  onSelected: (value) {
                    uuidType = value;
                    setState(() {});
                  },
                  offset: Offset(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem(
                        value: "v1 (time-based)",
                        child: Text("v1 (time-based)"),
                      ),
                      const PopupMenuItem(
                        value: "v4 (random)",
                        child: Text("v4 (random)"),
                      ),
                      const PopupMenuItem(
                        value: "v5 (namespace-name-sha1-based)",
                        child: Text("v5 (namespace-name-sha1-based)"),
                      ),
                      const PopupMenuItem(
                        value: "Launch URL",
                        child: Text("Launch URL"),
                      ),
                    ];
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(uuidType),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                  ),
                ),
                Column(
                  children: [
                    videoController == null
                        ? Container()
                        : AspectRatio(
                            aspectRatio: videoController!.value.aspectRatio,
                            child: VideoPlayer(videoController!),
                          ),
                    Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              if (videoController!.value.isPlaying) {
                                videoController!.pause();
                              } else {
                                videoController!.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow)),
                        Spacer(),
                        IconButton(
                            onPressed: () {
                              videoController!.value.volume == 0 ? videoController!.setVolume(1) : videoController!.setVolume(0);
                              setState(() {});
                            },
                            icon: Icon(videoController!.value.volume == 0 ? Icons.volume_off : Icons.volume_up)),
                        InkWell(
                          child: const Icon(Icons.speed),
                          onTapDown: (_) {
                            videoController!.setPlaybackSpeed(2.0);
                          },
                          onTapUp: (_) {
                            videoController!.setPlaybackSpeed(1.0);
                          },
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              var zxing = Zxing();
                              var result = zxing.encodeBarcode(contents: controller.text, params: EncodeParams());
                              try {
                                var imgImg = img.Image.fromBytes(100, 100, result.data!);
                                data = Uint8List.fromList(img.encodeJpg(imgImg));
                              } catch (ex) {}
                            },
                            child: const Text("Create")),
                        ElevatedButton(
                            onPressed: () async {
                              var picker = ImagePicker();
                              var image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
                              var zxing = Zxing();
                              try {
                                var result = await zxing.readBarcodeImagePath(image!);
                                print(result.text);
                              } catch (ex) {}
                            },
                            child: const Text("Read")),
                        ElevatedButton(
                            onPressed: () async {
                              if (data != null) {
                                if (await Permission.storage.isGranted) {
                                  print(await ImageGallerySaver.saveImage(data!, quality: 100));
                                } else {
                                  await Permission.storage.request();
                                  print("ss");
                                }
                              }
                            },
                            child: const Text("Save")),
                      ],
                    ),
                    if (data != null) Image.memory(data!)
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
//4294967295
