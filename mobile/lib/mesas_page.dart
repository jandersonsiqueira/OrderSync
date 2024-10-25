import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'pedido_page.dart';

class MesasPage extends StatefulWidget {
  const MesasPage({Key? key}) : super(key: key);

  @override
  _MesasPageState createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  List<dynamic> mesas = [];
  List<dynamic> mesasLivres = [];
  List<dynamic> mesasAndamento = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMesas();
  }

  Future<void> _fetchMesas() async {
    final response = await http.get(Uri.parse('http://192.168.0.6:5000/mesas'));
    if (response.statusCode == 200) {
      setState(() {
        mesas = json.decode(response.body);
        _filterMesas();
      });
    } else {
      throw Exception('Falha ao carregar mesas');
    }
  }

  void _filterMesas() {
    mesasLivres = mesas.where((mesa) => mesa['status'] == 'livre').toList();
    mesasAndamento = mesas.where((mesa) => mesa['status'] == 'andamento').toList();
  }

  Future<void> _abrirMesa(String mesaId) async {
    final response = await http.put(
      Uri.parse('http://192.168.0.6:5000/mesas/$mesaId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'status': 'andamento',
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        mesasLivres.removeWhere((mesa) => mesa['numero_mesa'].toString() == mesaId);
        mesasAndamento.add({
          "numero_mesa": mesaId,
          "status": "andamento",
          "observacao": "",
        });
      });
    } else {
      throw Exception('Falha ao abrir mesa');
    }
  }

  void _searchMesas(String query) {
    setState(() {
      searchQuery = query;
      if (query.isNotEmpty) {
        mesasLivres = mesasLivres
            .where((mesa) => mesa['numero_mesa'].toString().contains(query))
            .toList();
        mesasAndamento = mesasAndamento
            .where((mesa) => mesa['numero_mesa'].toString().contains(query))
            .toList();
      } else {
        _filterMesas();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Pesquisar por número da mesa...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchMesas,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMesaSection('Mesas em Andamento', mesasAndamento, true),
            _buildMesaSection('Mesas Livres', mesasLivres, false),
          ],
        ),
      ),
    );
  }

  Widget _buildMesaSection(String title, List<dynamic> mesas, bool isAndamento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: mesas.length,
          itemBuilder: (context, index) {
            final mesa = mesas[index];
            return GestureDetector(
              onTap: () {
                if (!isAndamento) {
                  _abrirMesa(mesa['numero_mesa'].toString());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PedidoPage(mesaId: mesa['numero_mesa'].toString()),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: isAndamento ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isAndamento)
                    Text(
                      'ABRIR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      mesa['numero_mesa'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
