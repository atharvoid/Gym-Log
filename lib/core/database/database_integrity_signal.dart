import 'package:flutter/foundation.dart';

/// Broadcasts a post-launch database integrity failure to the widget tree.
///
/// Launch-time corruption is carried by `BootstrapResult.databaseCorrupted`,
/// because it is known before `runApp` and can be passed straight into the
/// widget. Deferred corruption — found by the background `PRAGMA quick_check`
/// that runs after the first frame — has no such channel: by the time it is
/// known, the tree is already built.
///
/// This is a plain [ValueNotifier] rather than a Riverpod provider on purpose.
/// `Bootstrap` runs outside the provider scope and must not depend on it;
/// giving bootstrap a container reference just to publish one boolean would
/// couple startup to the state layer for no benefit.
///
/// Set once, by [Bootstrap]. Watched by `GymLogApp`. Never reset at runtime —
/// recovery from corruption is a relaunch, not a state transition.
final ValueNotifier<bool> databaseIntegrityFailed = ValueNotifier<bool>(false);
