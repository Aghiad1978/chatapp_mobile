import 'package:chatapp/Theme/app_colors.dart';
import 'package:flutter/material.dart';

class StyledTextfield extends StatelessWidget {
  const StyledTextfield({
    super.key,
    required this.controller,
    required this.title,
    required this.textInput,
    this.prefix,
  });

  final String title;
  final TextEditingController controller;
  final TextInputType textInput;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: TextField(
        maxLines: null,
        controller: controller,
        decoration: InputDecoration(
          label: Text(title),
          labelStyle: TextStyle(
            color: const Color.fromARGB(255, 226, 226, 226),
          ),
          prefixText: prefix,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white),
            // borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.writtingColor),
          ),
        ),
        style: TextStyle(color: AppColors.writtingColor),
        keyboardType: textInput,
      ),
    );
  }
}
