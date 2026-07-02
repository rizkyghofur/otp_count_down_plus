import 'package:flutter_test/flutter_test.dart';
import 'package:otp_count_down_plus/otp_count_down_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('OTPCountDown formats time correctly, ticks, and finishes', () async {
    final List<String> captures = [];
    bool finished = false;

    final otp = OTPCountDown.startOTPTimer(
      timeInMS: 3000,
      currentCountDown: (countDown) {
        captures.add(countDown);
      },
      onFinish: () {
        finished = true;
      },
    );

    // Initial value is emitted immediately
    expect(captures, ['00:03']);

    // Wait for the periodic timer ticks (3 seconds total)
    await Future.delayed(const Duration(milliseconds: 3500));

    expect(captures, ['00:03', '00:02', '00:01', '00:00']);
    expect(finished, isTrue);

    otp.dispose();
  });

  test('OTPCountDown supports custom formatter and interval', () async {
    final List<String> captures = [];

    final otp = OTPCountDown.startOTPTimer(
      timeInMS: 1500,
      interval: const Duration(milliseconds: 500),
      formatter: (ms) => '${ms}ms',
      currentCountDown: (countDown) {
        captures.add(countDown);
      },
    );

    // Initial value is emitted immediately
    expect(captures, ['1500ms']);

    // Wait 1.7 seconds to get all ticks (0.5s, 1.0s, 1.5s)
    await Future.delayed(const Duration(milliseconds: 1700));

    expect(captures, ['1500ms', '1000ms', '500ms', '0ms']);
    otp.dispose();
  });

  test('OTPCountDown works with Streams', () async {
    final otp = OTPCountDown.startOTPTimer(
      timeInMS: 2000,
      interval: const Duration(milliseconds: 500),
    );

    final stringTicks = await otp.countDownStream.take(4).toList();
    expect(stringTicks, ['00:01', '00:01', '00:00', '00:00']);

    otp.dispose();
  });

  test('OTPCountDown supports pause, resume, and restart', () async {
    final List<String> captures = [];

    final otp = OTPCountDown.startOTPTimer(
      timeInMS: 4000,
      currentCountDown: (countDown) {
        captures.add(countDown);
      },
    );

    // Wait 1.2s -> should have captured '00:04' (initial), '00:03' (1s)
    await Future.delayed(const Duration(milliseconds: 1200));
    expect(captures, ['00:04', '00:03']);

    // Pause the timer
    otp.pause();
    expect(otp.isPaused, isTrue);

    // Wait another 1.5s -> captures should not change
    await Future.delayed(const Duration(milliseconds: 1500));
    expect(captures, ['00:04', '00:03']);

    // Resume the timer
    otp.resume();
    expect(otp.isPaused, isFalse);

    // Wait 1.2s -> should capture '00:02'
    await Future.delayed(const Duration(milliseconds: 1200));
    expect(captures, ['00:04', '00:03', '00:02']);

    // Restart the timer to 2s
    otp.restart(2000);
    expect(captures.last, '00:02'); // restarts emits immediately
    // Wait 2.2s -> should complete the new 2s countdown
    await Future.delayed(const Duration(milliseconds: 2200));

    // Check that we got '00:02', '00:01', '00:00' from the restart
    expect(captures.sublist(captures.length - 3), ['00:02', '00:01', '00:00']);

    otp.dispose();
  });

  test('OTPCountDown triggers milestone callbacks and onTick persistence callback', () async {
    final List<int> ticks = [];
    final List<String> milestoneTriggers = [];

    final otp = OTPCountDown.startOTPTimer(
      timeInMS: 3000,
      onTick: (ms) {
        ticks.add(ms);
      },
      milestones: {
        2000: () => milestoneTriggers.add('2s_left'),
        1000: () => milestoneTriggers.add('1s_left'),
      },
    );

    // Let it run for 3.2 seconds
    await Future.delayed(const Duration(milliseconds: 3200));

    expect(ticks.isNotEmpty, isTrue);
    // Verified that it called our onTick hook with decaying millisecond values
    expect(ticks.first, 3000);
    expect(ticks.last, 0);

    // Verified that milestones triggered exactly once and at correct times
    expect(milestoneTriggers, ['2s_left', '1s_left']);

    otp.dispose();
  });

  test('OTPCountDown supports restartWithBackoff', () {
    final otp = OTPCountDown.startOTPTimer(timeInMS: 1000);
    expect(otp.attemptCount, 0);

    // Default linear backoff: attempt 1 -> 1 * 2s = 2s
    otp.restartWithBackoff(baseDuration: const Duration(seconds: 2));
    expect(otp.attemptCount, 1);
    expect(otp.remainingTimeInMS, 2000);

    // Custom backoff: attempt 2 -> 2^2 * 1s = 4s
    otp.restartWithBackoff(
      baseDuration: const Duration(seconds: 1),
      customStrategy: (attempt) => Duration(seconds: attempt * attempt),
    );
    expect(otp.attemptCount, 2);
    expect(otp.remainingTimeInMS, 4000);

    otp.dispose();
  });
}
