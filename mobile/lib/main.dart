import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:order_sync/variaveis_globais.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vendas/vendas_page.dart';
import 'admin/admin_page.dart';
import 'home_page/home_page.dart';
import 'login/login_page.dart';
import 'mesas/mesas_page/mesas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final String? uid = await VariaveisGlobais.getUidFromCache();
  runApp(MyApp(initialRoute: uid != null ? '/home_page' : '/login_page'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

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
      initialRoute: initialRoute,
      routes: {
        '/login_page': (context) => const LoginPage(),
        '/home_page': (context) => const HomePage(),
        '/mesas_page': (context) => MesasPage(),
        '/vendas_page': (context) => VendasPage(),
        '/admin_page': (context) => const AdminPage(),
      },
    );
  }
}