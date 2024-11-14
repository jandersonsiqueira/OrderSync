import 'package:flutter/material.dart';
import 'package:order_sync/vendas/vendas_page.dart';
import 'admin/admin_page.dart';
import 'home_page/home_page.dart';
import 'mesas/mesas_page/mesas_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrderSync',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.teal.shade300,
        cardColor: Colors.white,
        shadowColor: Colors.black54,
        canvasColor: Colors.black,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal.shade700,
        cardColor: Colors.grey[850],
        shadowColor: Colors.black,
        canvasColor: Colors.white,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
      routes: {
        '/mesas_page': (context) => MesasPage(),
        '/vendas_page': (context) => VendasPage(),
        '/admin_page': (context) => const AdminPage(),
      },
    );
  }
}