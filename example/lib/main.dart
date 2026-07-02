import 'package:flutter/material.dart';
import 'package:otp_count_down_plus/otp_count_down_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTP Count Down Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late OTPCountDown _otpCountDown;
  final int _otpTimeInMS = 1000 * 30; // 30 seconds for quick testing
  String _milestoneMessage = "No milestones reached yet";
  bool _enableHaptics = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountDown();
  }

  void _startCountDown() {
    _otpCountDown = OTPCountDown.startOTPTimer(
      timeInMS: _otpTimeInMS,
      enableHaptics: _enableHaptics,
      onFinish: () {
        debugPrint("Count down finished!");
      },
      milestones: {
        15000: () {
          setState(() {
            _milestoneMessage = "Halfway mark: 15 seconds remaining!";
          });
        },
        5000: () {
          setState(() {
            _milestoneMessage = "Crucial: Only 5 seconds left!";
          });
        },
      },
    );
  }

  void _handleResend() async {
    setState(() {
      _isLoading = true;
    });
    debugPrint("Resending OTP... Simulating API call");
    await Future.delayed(const Duration(seconds: 2));

    _otpCountDown.restartWithBackoff(
      baseDuration: const Duration(seconds: 30),
    );

    setState(() {
      _isLoading = false;
      _milestoneMessage = "Resent. Backoff multiplier applied!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("OTP Count Down Plus"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "Remaining Time (StreamBuilder):",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                StreamBuilder<String>(
                  stream: _otpCountDown.countDownStream,
                  initialData: "00:30",
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? "00:00",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: MediaQuery.of(context).size.height * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),
                Text(
                  _milestoneMessage,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                SwitchListTile(
                  title: const Text("Enable Haptic Feedback (Ticking)"),
                  value: _enableHaptics,
                  onChanged: (val) {
                    setState(() {
                      _enableHaptics = val;
                      _otpCountDown.dispose();
                      _startCountDown();
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _otpCountDown.pause();
                        setState(() {});
                      },
                      child: const Text("Pause"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _otpCountDown.resume();
                        setState(() {});
                      },
                      child: const Text("Resume"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _otpCountDown.restart(_otpTimeInMS);
                        setState(() {
                          _milestoneMessage = "Timer restarted";
                        });
                      },
                      child: const Text("Restart"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Timer State: ${_otpCountDown.isPaused ? 'PAUSED' : _otpCountDown.isRunning ? 'RUNNING' : 'STOPPED'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Text(
                  "Attempts: ${_otpCountDown.attemptCount}",
                  style: const TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 30),
                const Text(
                  "User Designed Custom Button UI:",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                StreamBuilder<String>(
                  stream: _otpCountDown.countDownStream,
                  builder: (context, snapshot) {
                    final formattedTime = snapshot.data ?? "00:00";
                    final bool isTimeUp = _otpCountDown.remainingTimeInMS <= 0;
                    final bool isDisabled = !isTimeUp || _isLoading;

                    return ElevatedButton(
                      onPressed: isDisabled ? null : _handleResend,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isTimeUp ? "Kirim Ulang Kode OTP" : "Kirim ulang dalam $formattedTime"),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpCountDown.dispose();
    super.dispose();
  }
}
