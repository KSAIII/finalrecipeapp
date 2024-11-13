import 'package:flutter/material.dart';
import 'package:recipie_app/homepage.dart';

class RouteGenerator{
Route<dynamic> generateRoute(RouteSettings settings) {
switch (settings.name){
  case '/':
    return MaterialPageRoute(builder: (_)=> const Homepage());
    default:
    return _errorRoute();
}

}
static Route<dynamic> _errorRoute() {
  return MaterialPageRoute(builder: (_){

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: const Center(
        child: Text('ERROR'),
      ),
    );
  });
}

}