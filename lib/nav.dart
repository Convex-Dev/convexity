import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void push(BuildContext context, Widget Function(BuildContext) builder) =>
    Navigator.push(context, MaterialPageRoute(builder: builder));
