import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CadastroMesasPage extends StatefulWidget {
  const CadastroMesasPage({Key? key}) : super(key: key);

  @override
  State<CadastroMesasPage> createState() => _CadastroMesasPageState();
}

class _CadastroMesasPageState extends State<CadastroMesasPage> {
  List<dynamic> _mesas = [];
  bool _isLoading = true;
  String _pesquisa = '';

  @override
  void initState() {
    super.initState();
    _fetchMesas();
  }

  Future<void> _fetchMesas() async {
    try {
      final response = await http.get(Uri.parse('https://ordersync.onrender.com/mesas'));

      if (response.statusCode == 200) {
        setState(() {
          _mesas = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar mesas');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao buscar mesas: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastro de Mesas',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _pesquisa = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Pesquisar mesa',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mesas.isEmpty
                ? const Center(child: Text('Nenhuma mesa encontrada.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _mesas.length,
              itemBuilder: (context, index) {
                final mesa = _mesas[index];
                if (_pesquisa.isEmpty ||
                    mesa['numero_mesa']
                        .toString()
                        .contains(_pesquisa)) {
                  return _buildMesaCard(mesa);
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação para adicionar nova mesa (deixe vazio por enquanto)
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMesaCard(dynamic mesa) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(
          Icons.table_bar,
          size: 40,
        ),
        title: Text(
          'Mesa ${mesa['numero_mesa']}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Ação para editar mesa (deixe vazio por enquanto)
              },
            ),
          ],
        ),
      ),
    );
  }
}
