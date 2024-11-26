import 'package:http/http.dart' as http;
import 'dart:convert';

class ProdutosController {
  Future<List<dynamic>> fetchProdutos(String uid) async {
    final response = await http.get(Uri.parse('https://order-sync-three.vercel.app/$uid/produtos'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar produtos');
    }
  }
}
