import 'package:canteen_food_ordering_app_v3/screens/cartPage.dart';
import 'package:canteen_food_ordering_app_v3/screens/homePage.dart';
import 'package:canteen_food_ordering_app_v3/screens/profilePage.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class NavigationBarPage extends StatefulWidget {
  int selectedIndex;
  NavigationBarPage({super.key, required this.selectedIndex});
  @override
  NavigationBarPageState createState() => NavigationBarPageState();
}

class NavigationBarPageState extends State<NavigationBarPage> {
  final List<Widget> _children = [
    ProfilePage(),
    HomePage(),
    CartPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _children[widget.selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        color: const Color.fromRGBO(255, 63, 111, 1),
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: const Color.fromRGBO(255, 63, 111, 1),
        height: 50,
        index: widget.selectedIndex,
        onTap: (index) {
          setState(() {
            widget.selectedIndex = index;
          });
        },
        items: const <Widget>[
          Icon(
            Icons.account_circle,
            size: 26,
            color: Colors.white,
          ),
          Icon(
            Icons.home,
            size: 26,
            color: Colors.white,
          ),
          Icon(
            Icons.add_shopping_cart,
            size: 26,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
