import 'package:flutter/material.dart';

// Static utility class for component Widget builders
class Components {

  static Widget button(String text, {void Function()?onPressed}) {
    return ElevatedButton(
      child: Text(text),
      onPressed: onPressed,
    );
  }
}