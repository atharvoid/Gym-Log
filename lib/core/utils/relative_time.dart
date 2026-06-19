/// Human "time ago" at day granularity. Shared by the routines list summary
/// and the routine card (previously duplicated, and divergent, in both).
String relativeDay(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays < 1) return 'today';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 14) return '1 week ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
  if (diff.inDays < 60) return '1 month ago';
  return '${(diff.inDays / 30).floor()} months ago';
}
