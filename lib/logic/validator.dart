import 'package:flutter/material.dart';

class Validator {
  static bool _validateEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  static String? validate(List<TextEditingController> controllers) {
    var emailValue = controllers[0].text;
    for (var controller in controllers) {
      if (controller.text.isEmpty) {
        return "All field must be filled";
      }
    }
    if (!_validateEmail(emailValue)) {
      return "Email is not valid";
    }
    return null;
  }
}
