import 'package:meta/meta.dart';
import 'convex.dart' as convex;

@immutable
class Message {
  final String subject;
  final convex.Address from;

  Message({
    required this.subject,
    required this.from,
  });
}
