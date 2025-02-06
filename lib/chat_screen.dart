import 'package:flutter/material.dart';
import 'gemini_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import 'model/sleep_data.dart';

final authorizationEndpoint =
    Uri.parse('https://api.prod.whoop.com/oauth/oauth2/auth');
final tokenEndpoint =
    Uri.parse('https://api.prod.whoop.com/oauth/oauth2/token');

// Client identifier and secret (replace these with your own)
const identifier = '4202e0e4-595d-45ed-846e-8dde6d5abcf5';
const secret =
    'a20f3df7a87451fe23dd382ab6b241a010b6246b88b45ffe79c5e4b5f7e37140';

// Redirect URL (custom scheme)
final redirectUrl = Uri.parse('my.test.app://callback');

// Credentials file

// SharedPreferences keys
const String credentialsKey = 'oauth_credentials';
const String showWhoopDialogKey = 'show_whoop_dialog';
const String lastFetchDateKey = 'last_fetch_date';
Future<oauth2.Client?> createClient(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final storedCredentials = prefs.getString(credentialsKey);
  final showDialogs = prefs.getBool(showWhoopDialogKey) ?? true;
  if (storedCredentials != null) {
    try {
      final credentialsMap = jsonDecode(storedCredentials);
      final credentials = oauth2.Credentials.fromJson(credentialsMap);
      return oauth2.Client(credentials,
          identifier: identifier, secret: secret, httpClient: http.Client());
    } catch (e) {
      print('Failed to load credentials: $e');
      // Handle the error or remove invalid credentials from storage
      await prefs.remove(credentialsKey);
    }
  } else if (showDialogs) {
    final grant = oauth2.AuthorizationCodeGrant(
      identifier,
      authorizationEndpoint,
      tokenEndpoint,
      secret: secret,
      httpClient: http.Client(),
      onCredentialsRefreshed: (credentials) async {
        await prefs.setString(credentialsKey, jsonEncode(credentials.toJson()));
      },
      basicAuth: false,
    );

    final authorizationUrl = grant.getAuthorizationUrl(
      redirectUrl,
      scopes: ['read:sleep'],
      state: generateRandomState(),
    );

    final responseUrl =
        await navigateToAuthorization(context, authorizationUrl);

    final client =
        await grant.handleAuthorizationResponse(responseUrl.queryParameters);
    await prefs.setString(
        credentialsKey, jsonEncode(client.credentials.toJson()));

    return client;
  }
}

String generateRandomState([int length = 16]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._~';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

Future<Uri> navigateToAuthorization(
    BuildContext context, Uri authorizationUrl) async {
  final completer = Completer<Uri>();

  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(authorizationUrl)
              ..setNavigationDelegate(
                NavigationDelegate(onNavigationRequest: (request) {
                  if (request.url.startsWith(redirectUrl.toString())) {
                    completer.complete(Uri.parse(request.url));
                    Navigator.of(context).pop(); // Close the web view
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                }),
              ))),
  ));

  return completer.future;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final GeminiService geminiService = GeminiService();
  TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];

  void sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": userMessage});
    });

    _controller.clear();

    try {
      String response = await geminiService.generateText(userMessage);
      setState(() {
        messages.add({"sender": "bot", "text": response});
      });
    } catch (e) {
      setState(() {
        messages
            .add({"sender": "bot", "text": "Error: Failed to fetch response."});
      });
    }
  }

  SleepData? sleepData;
  Future<void> checkWhoopOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final showDialogs = prefs.getBool(showWhoopDialogKey) ?? true;
    final hasCredentials = prefs.containsKey(credentialsKey);

    if (showDialogs && !hasCredentials) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('WHOOP Watch'),
            content: Text(
                'Do you own a WHOOP watch? You can log in to access your sleep data.'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () async {
                  await prefs.setBool(showWhoopDialogKey, false);
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (shouldLogin == true) {
        await getData();
      }
    } else {
      await getData();
    }
  }

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchDate = prefs.getString(lastFetchDateKey);

    // Check if data was fetched today
    final today = DateTime.now();
    final lastFetch =
        lastFetchDate != null ? DateTime.parse(lastFetchDate) : null;

    if (lastFetch != null &&
        lastFetch.year == today.year &&
        lastFetch.month == today.month &&
        lastFetch.day == today.day) {
      print('Data has already been fetched today.');
      return;
    }
    var client = await createClient(context);
    if (client != null) {
      var response = await client.read(
          Uri.parse('https://api.prod.whoop.com/developer/v1/activity/sleep'));

      print(response);
      setState(() {
        sleepData = SleepData.fromJson(response);
        _controller = TextEditingController(
            text:
                'this is my whoop watch data to my sleep ${sleepData?.formatForGemini()} advice me how to sleep');
        sendMessage();
      });
      // Save the current date as the last fetch date
      await prefs.setString(lastFetchDateKey, today.toIso8601String());
    }
  }

  @override
  void initState() {
    checkWhoopOwnership();

    super.initState();
  }

  void firetTest() async {}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Whoop Watch with Gemini')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isUser = message["sender"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(
                          color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
