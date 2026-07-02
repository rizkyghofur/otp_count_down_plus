## [2.0.0] - Upgrade to Dart 3, Null Safety, and Feature Enhancements

* Forked from `otp_count_down` to `otp_count_down_plus`.
* Upgraded SDK constraints to support Dart 3 (`sdk: ">=2.17.0 <4.0.0"`).
* Migrated to sound null safety.
* Added **Stream support** (`countDownStream` and `remainingTimeStream`).
* Added **Timer Controls** (`pause()`, `resume()`, and `restart()`).
* Added **Custom Formatter** (`formatter`) and **Custom Interval** (`interval`).
* Added **Background Time Sync** via absolute system time & `WidgetsBindingObserver`.
* Added **Cooldown Backoff support** (`restartWithBackoff()`) with custom or linear strategies.
* Added **Persistence Hook** (`onTick` callback) returning remaining milliseconds.
* Added **Milestone Callbacks** (`milestones` map) to trigger events at specific durations.
* Added immediate timer invocation to improve UI/UX responsiveness.
* Upgraded the example app to modern Android V2 embedding and iOS configuration.
* Added comprehensive unit tests.

## [1.0.6] - initial release.

- FIXED minor bugs
- Added Licence

## [1.0.5] - initial release.

- Added README

## [1.0.4] - initial release.

- Added example

## [1.0.3] - initial release.

- Added onFinish callback

## [1.0.2] - initial release.

- Improved stability

## [1.0.1] - initial release.

- Added option for cancelling timer.

## [1.0.0] - initial release.
