import 'package:http/http.dart' as http;
import 'dart:convert';

class ProdutosController {
  Future<List<dynamic>> fetchProdutos() async {
    final response = await http.get(Uri.parse('https://ordersync.onrender.com/produtos'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar produtos');
    }
  }
}
