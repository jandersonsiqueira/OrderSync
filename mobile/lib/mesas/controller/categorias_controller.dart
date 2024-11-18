import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoriasController {

  Future<List<dynamic>> fetchCategorias(String uid) async {
    final response = await http.get(Uri.parse('https://ordersync.onrender.com/$uid/categorias'));

    if (response.statusCode == 200) {
      List<dynamic> categorias = json.decode(response.body);
      categorias.add({
        "cd_categoria": 0,
        "nm_categoria": "Todos os Produtos"
      });
      return categorias;
    } else {
      throw Exception('Falha ao carregar categorias');
    }
  }
}
