import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:logging/logging.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late TextEditingController controller;
  late FocusNode focusNode;
  final List<String> inputTags = [];
  String response = '';

  // Initialize the logger
  final Logger _logger = Logger('Homepage');

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    focusNode = FocusNode();

    // Set up logging configuration
    Logger.root.level = Level.ALL; // This will log all messages
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                const Text(
                  'Find the best recipe for cooking!',
                  maxLines: 3,
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Flexible(
                      child: TextFormField(
                        autofocus: true,
                        autocorrect: true,
                        focusNode: focusNode,
                        controller: controller,
                        onFieldSubmitted: (value) {
                          setState(() {
                            inputTags.add(value);
                            controller.clear();
                            focusNode.requestFocus();
                          });
                          _logger.info('Input tags updated: $inputTags');
                        },
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5.5),
                              bottomLeft: Radius.circular(5.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          labelText: "Enter the ingredients you have ....",
                          labelStyle: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.green,
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              inputTags.add(controller.text);
                              controller.clear();
                              focusNode.requestFocus();
                            });
                            _logger.info('Input tags updated: $inputTags');
                          },
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Wrap(
                    children: [
                      for (int i = 0; i < inputTags.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Chip(
                            backgroundColor: Color(
                              (math.Random().nextDouble() * 0xFFFFFF).toInt(),
                            ).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.5),
                            ),
                            onDeleted: () {
                              setState(() {
                                inputTags.removeAt(i); // Remove by index
                                _logger.info(
                                    'Input tags updated after deletion: $inputTags');
                              });
                            },
                            label: Text(inputTags[i]),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          response,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            response = 'Thinking....'; // Set loading state
                          });

                          try {
                            // Create a prompt from the input tags
                            String prompt = inputTags.join(', '); // Join tags as a single string

                            // Make API request
                            final apiResponse = await http.post(
                              Uri.parse('https://api.openai.com/v1/chat/completions'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer ${dotenv.env['token']}', // Securely loading the API key
                              },
                              body: json.encode({
                                'model': 'gpt-3.5-turbo',  // Use GPT-3.5 for chat-based completions
                                'messages': [
                                  {'role': 'user', 'content': prompt},  // Send prompt as a message
                                ],
                                'max_tokens': 500,
                                'temperature': 0.7,  // Adjust creativity/randomness
                                'top_p': 1,
                              }),
                            );

                            if (apiResponse.statusCode == 200) {
                              // Successfully got a response
                              var data = json.decode(apiResponse.body);
                              var recipe = data['choices'][0]['message']['content'];  // AI-generated recipe
                              
                              _logger.info('Response from AI: $recipe');
                              setState(() {
                                response = recipe;  // Display the AI recipe
                              });
                            } else {
                              // Handle failed response (non-200 status)
                              var errorData = json.decode(apiResponse.body);
                              String errorMessage = errorData['error'] != null
                                  ? errorData['error']['message']
                                  : 'Unknown error occurred';
                              
                              _logger.severe('Failed response: $errorMessage');
                              setState(() {
                                response = 'Error: $errorMessage';  // Display specific error message
                              });
                            }
                          } catch (e) {
                            // Catch any exceptions and display them
                            setState(() {
                              response = 'An error occurred: $e';
                            });
                            _logger.severe('Error during API call: $e');
                          }
                        },
                        child: const Text(
                          'Create Recipe',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
