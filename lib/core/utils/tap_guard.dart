/// Shared double-tap guard for navigation / "start" actions.
///
/// Returns true at most once per [window]; rapid re-taps inside the window are
/// ignored. Prevents the classic bug where a fast double-tap pushes a route
/// twice (or starts a workout twice). One global debounce is intentional —
/// you almost never want to fire two navigations within 600ms.
bool tapGuard({Duration window = const Duration(milliseconds: 600)}) {
  final now = DateTime.now();
  if (now.difference(_lastTap) < window) return false;
  _lastTap = now;
  return true;
}

DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
