import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/Theme/theme1.dart';
import 'package:chatapp/models/friend_table.dart';
import 'package:chatapp/logic/validator.dart';
import 'package:chatapp/requests/register.dart';
import 'package:chatapp/screens/main_screen.dart';
import 'package:chatapp/widgets/styled_filledbtn.dart';
import 'package:chatapp/widgets/styled_snackbar.dart';
import 'package:chatapp/widgets/styled_textfield.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  final TextEditingController userNameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController mobileNumberController = TextEditingController();

  final TextEditingController countryCodeController = TextEditingController();

  Future<Map<String, dynamic>> registerPress() async {
    try {
      setState(() {
        _isLoading = true;
      });
      String? resultValidation = Validator.validate([
        emailController,
        userNameController,
        mobileNumberController,
        countryCodeController,
      ]);
      if (resultValidation != null) {
        setState(() {
          _isLoading = false;
        });
        return {"success": false, "message": resultValidation};
      }
      bool resultRegisteration = await Register.registerUser(
        userName: userNameController.text,
        email: emailController.text,
        code: countryCodeController.text,
        mobile: mobileNumberController.text,
      );
      setState(() {
        _isLoading = false;
      });
      if (resultRegisteration) {
        return {"success": true, "message": "Registerd Successfully"};
      } else {
        return {"success": false, "message": "Registerd Failed"};
      }
    } catch (e) {
      print("Current ERROR:$e");
      setState(() {
        _isLoading = false;
      });
      return {"success": false, "message": "error unable to register the user"};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text("Crypto Chat", style: theme1.textTheme.displayMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StyledTextfield(
              controller: userNameController,
              title: "Username",
              textInput: TextInputType.name,
            ),
            StyledTextfield(
              controller: emailController,
              title: "Email",
              textInput: TextInputType.emailAddress,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 2,
                  child: StyledTextfield(
                    controller: countryCodeController,
                    title: "Code",
                    textInput: TextInputType.number,
                    prefix: "+",
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  flex: 5,
                  child: StyledTextfield(
                    controller: mobileNumberController,
                    title: "Mobile",
                    textInput: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: !_isLoading
                  ? StyledFilledbtn(
                      onPressed: () async {
                        Map<String, dynamic> result = await registerPress();
                        if (!mounted) return;
                        if (result["success"]) {
                          await FriendTable.getPossibleFriendsFromServer();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => MainScreen(),
                            ),
                          );
                          StyledSnackbar.showSnackbar(
                            context,
                            result["message"],
                            3,
                          );
                        } else {
                          StyledSnackbar.showSnackbar(
                            context,
                            result["message"],
                            5,
                          );
                        }
                      },
                      child: Text("Register"),
                    )
                  : StyledFilledbtn(
                      onPressed: () {},
                      child: CircularProgressIndicator(
                        color: AppColors.writtingColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
