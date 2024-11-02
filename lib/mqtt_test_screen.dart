import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttTestScreen extends StatefulWidget {
  @override
  _MqttTestScreenState createState() => _MqttTestScreenState();
}

class _MqttTestScreenState extends State<MqttTestScreen> {
  final client = MqttServerClient(
      'tf-elb-nlb-6fc8af3869cb4d58.elb.sa-east-1.amazonaws.com', '');

  String connectionStatus = 'Disconnected';
  String sentMessageStatus = '';
  bool isConnecting = false;
  bool isSendingMessage = false;

  // List to store received messages with timestamps
  List<Map<String, String>> receivedMessages = [];

  final TextEditingController topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setupMqttClient();
  }

  Future<void> setupMqttClient() async {
    setState(() {
      isConnecting = true;
      connectionStatus = 'Connecting...';
    });

    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.onUnsubscribed = onUnsubscribed;
    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient')
        .keepAliveFor(60)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Connection failed: $e');
      setState(() {
        connectionStatus = 'Connection failed';
        isConnecting = false;
      });
      client.disconnect();
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      setState(() {
        // Add message with timestamp to the list
        receivedMessages.add({
          'time': DateTime.now().toLocal().toString(),
          'message': message,
        });
      });
    });
  }

  void onConnected() {
    setState(() {
      connectionStatus = 'Connected';
      isConnecting = false;
    });
    // Subscribe to a default topic or keep it empty
  }

  void onDisconnected() {
    setState(() {
      connectionStatus = 'Disconnected';
    });
  }

  void onSubscribed(String topic) {
    setState(() {
      connectionStatus = 'Subscribed to $topic';
    });
  }

  void onSubscribeFail(String topic) {
    setState(() {
      connectionStatus = 'Failed to subscribe $topic';
    });
  }

  void onUnsubscribed(String? topic) {
    setState(() {
      connectionStatus = 'Unsubscribed from $topic';
    });
  }

  void sendTestMessage() async {
    setState(() {
      isSendingMessage = true;
    });
    final builder = MqttClientPayloadBuilder();
    builder.addString('I am testing from fiverr');
    client.publishMessage('testMe', MqttQos.atMostOnce, builder.payload!);
    setState(() {
      sentMessageStatus = 'Sent message to "testMe" topic';
      isSendingMessage = false;
    });
  }

  void disconnectClient() {
    client.disconnect();
  }

  void subscribeToTopic() {
    final topic = topicController.text.trim();
    if (topic.isNotEmpty) {
      client.subscribe(topic, MqttQos.atMostOnce);
      topicController.clear(); // Clear the input field after subscribing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MQTT Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connectionStatus == 'Connected'
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: connectionStatus == 'Connected'
                      ? Colors.green
                      : Colors.red,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text(
                  'Connection Status: \n$connectionStatus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isConnecting)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            SizedBox(height: 20),
            // Input field for subscribing to a topic
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Enter Topic to Subscribe',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isConnecting ? null : subscribeToTopic,
              child: Text('Subscribe'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed:
                  isConnecting || isSendingMessage ? null : sendTestMessage,
              icon: Icon(Icons.send),
              label: Text('Send Test Message'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            if (isSendingMessage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (sentMessageStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  sentMessageStatus,
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Received Messages:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: receivedMessages.length,
                itemBuilder: (context, index) {
                  final message = receivedMessages[index];
                  return ListTile(
                    title: Text(message['message']!),
                    subtitle: Text('Time: ${message['time']}'),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: disconnectClient,
              icon: Icon(Icons.exit_to_app),
              label: Text('Disconnect'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
