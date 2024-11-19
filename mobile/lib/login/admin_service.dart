import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  static Future<void> createAdminDatabase(String token) async {
    final response = await http.post(
      Uri.parse('https://ordersync.onrender.com/create-admin'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'token': token,
      }),
    );

    if (response.statusCode == 201) {
      // Sucesso ao criar base de dados
      print('Base de dados criada com sucesso!');
    } else {
      // Erro ao criar base de dados
      throw Exception('Erro ao criar base de dados: ${response.body}');
    }
  }
}
