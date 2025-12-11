import 'package:flutter/material.dart';
import 'package:nde_email/utils/const/consts.dart';

class CoustomContainer extends StatefulWidget {
  final Color color;
  // final double width;
  // final double height;
  final IconData iconsData;

  final String texxt;
  final Color txtcolor;

  final Function() onpressed;
  final BorderRadius? borderRadius;

  const CoustomContainer(
      {super.key,
      required this.color,
      required this.iconsData,
      required this.onpressed,
      required this.texxt,
      // required this.width,
      // required this.height,
      required this.txtcolor,
      this.borderRadius});

  @override
  State<CoustomContainer> createState() => _ButtonState();
}

class _ButtonState extends State<CoustomContainer> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onpressed,
      child: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.iconsData,
                color: chatColor,
              ),
              Text(
                widget.texxt,
                style: TextStyle(
                    color: widget.txtcolor,
                    fontWeight: FontWeight.w300,
                    fontSize: 15),
              ),
            ],
          )),
    );
  }
}
