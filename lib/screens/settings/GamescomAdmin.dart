import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/widgets/NoRiskButton.dart';
import 'package:noriskclient/widgets/NoRiskContainer.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';
import 'package:noriskclient/screens/ScanQRCode.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/widgets/NoRiskBackButton.dart';

class GamescomAdmin extends StatefulWidget {
  const GamescomAdmin({super.key});

  @override
  State<GamescomAdmin> createState() => _GamescomAdminState();
}

class _GamescomAdminState extends State<GamescomAdmin> {
  String lastResponseMsg = "";
  String enteredUsername = '';
  final TextEditingController _controller = TextEditingController();

  void _scanQr() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScanQRCode(redeem: _redeem)),
    );
  }

  void _redeem(String username) async {
    var res = await NoRiskApi().redeemGamescom(username);
    if (res == null || res['error'] != null) {
      setState(() {
        lastResponseMsg = res?['error'] ?? 'Failed to redeem for $username!';
      });
      Fluttertoast.showToast(msg: lastResponseMsg, backgroundColor: Colors.red);
      return;
    } else {
      setState(() {
        lastResponseMsg = 'Redeemed for $username!';
      });
      Fluttertoast.showToast(
          msg: lastResponseMsg, backgroundColor: Colors.green);
    }
  }

  @override
  void initState() {
    _controller.addListener(() {
      setState(() {
        enteredUsername = _controller.text;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: NoRiskClientColors.background,
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7.5),
                      child: NoRiskBackButton(),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    NoRiskText('gamescom admin',
                        spaceTop: false,
                        spaceBottom: false,
                        style: const TextStyle(
                            color: NoRiskClientColors.text,
                            fontSize: 40,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NoRiskButton(
                onTap: _scanQr,
                child: NoRiskText(
                  'scan qr code',
                  style:
                      TextStyle(fontSize: 25, color: NoRiskClientColors.text),
                ),
              ),
              SizedBox(height: 35),
              NoRiskContainer(
                child: TextField(
                  controller: _controller,
                  style:
                      TextStyle(color: NoRiskClientColors.text, fontSize: 30),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.only(left: 16, right: 16, bottom: 7.5),
                    hintText: 'username',
                    hintStyle: TextStyle(
                        color: NoRiskClientColors.text.withOpacity(0.5),
                        fontFamily: 'SmallCapsMC'),
                  ),
                ),
              ),
              SizedBox(height: 10),
              NoRiskButton(
                onTap: enteredUsername.isEmpty
                    ? () {}
                    : () => _redeem(enteredUsername),
                child: NoRiskText(
                  'redeem manually',
                  style:
                      TextStyle(fontSize: 25, color: NoRiskClientColors.text),
                ),
              ),
              const SizedBox(height: 20),
              NoRiskText(lastResponseMsg,
                  style:
                      TextStyle(fontSize: 25, color: NoRiskClientColors.text),
                  textAlign: TextAlign.center)
            ],
          ),
        ]),
      ),
    );
  }
}
