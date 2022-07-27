import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:async';

import 'package:rjwada/utils/utils.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? image;
  final picker = ImagePicker();

  _selectImage(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Create a Post'),
            children: [
              SimpleDialogOption(
                padding: const EdgeInsets.all(8),
                child: const Text("Take a Photo"),
                onPressed: (() async {
                  Navigator.of(context).pop();
                  final file =
                      await picker.pickImage(source: ImageSource.camera);
                  if (file != null) {
                    setState(() {
                      image = File(file.path);
                    });
                  } else {
                    log('Please Take A Photo');
                    showSnackBar(context, "Take A Images");
                  }
                }),
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(8),
                child: const Text("Choose from Photo"),
                onPressed: (() async {
                  Navigator.of(context).pop();

                  final file =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      image = File(file.path);
                    });
                  } else {
                    log("Please choose a image");
                    showSnackBar(context, "Please Choose Images");
                  }
                }),
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(8),
                child: const Text("Cancel"),
                onPressed: (() {
                  Navigator.of(context).pop();
                }),
              ),
            ],
          );
        });
  }

  var res;
  bool _isLoading = true;
  bool _progress = false;
  var _total = 100;
  var current = 4;
  Future<dynamic> sendForm(
      String url, Map<String, dynamic> data, Map<String, File> files) async {
    setState(() {
      _isLoading = true;
      _progress = true;
    });
    try {
      Map<String, MultipartFile> fileMap = {};
      for (MapEntry fileEntry in files.entries) {
        File file = fileEntry.value;
        String fileName = basename(file.path);
        fileMap[fileEntry.key] = MultipartFile(
          file.openRead(),
          await file.length(),
          filename: fileName,
        );
      }
      data.addAll(fileMap);
      var formData = FormData.fromMap(data);
      Dio dio = Dio();
      var response = await dio.post(url, data: formData,
          onSendProgress: (int sent, int total) {
        log('$sent $total');
        _total = total;
        current = sent;
      }, options: Options(contentType: 'multipart/form-data'));

      setState(() {
        _progress = false;
        _isLoading = false;
      });

      res = response.data;
    } catch (e) {
      log(e.toString());
    }
    log(res.toString());
    return res;
  }

  @override
  Widget build(BuildContext context) {
    String url = 'https://aws143.arnavgoyal4.repl.co/upload';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "Upload Image",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Stack(
                  children: [
                    image != null
                        ? CircleAvatar(
                            radius: 64,
                            backgroundImage: FileImage(image!),
                            backgroundColor: Colors.lightGreen,
                          )
                        : const CircleAvatar(
                            radius: 64,
                            backgroundImage: NetworkImage(
                                'https://i.stack.imgur.com/l60Hf.png'),
                            backgroundColor: Colors.red,
                          ),
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: IconButton(
                        onPressed: () {
                          _selectImage(context);
                        },
                        icon: const Icon(Icons.add_a_photo),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 50,
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () async {
                      res = await sendForm(url, {}, {'files[]': image!});
                    },
                    child: _progress
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Upload",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 20),
                          ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 45,
                ),
                // showSnackBar(context, res['message'] ?? "Error"),
                Card(
                  color: Colors.lightGreenAccent,
                  elevation: 0.6,
                  child: Container(
                    margin: EdgeInsets.all(5),
                    height: MediaQuery.of(context).size.height / 3,
                    width: 500,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        opacity: 0.9,
                        fit: BoxFit.cover,
                        image: _isLoading
                            ? NetworkImage(
                                'https://img.freepik.com/free-vector/design-inspiration-concept-illustration_114360-3957.jpg?w=826&t=st=1658939627~exp=1658940227~hmac=10ce6f6f7054f5541c2f5295ea77788ff380682dd3653a3b659de94f63785008',
                              )
                            : NetworkImage(res['url']),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),

                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  child: _progress
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Text(res?['message'] ?? "no images"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
