import 'package:meta/meta.dart';
import 'convex.dart' as convex;

@immutable
class Message {
  final String subject;
  final convex.Address from;
  final int? amount;
  final String? text;

  Message({
    required this.subject,
    required this.from,
    this.text,
    this.amount,
  });
}
