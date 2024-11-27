import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../variaveis_globais.dart';

class CadastroMesasPage extends StatefulWidget {
  const CadastroMesasPage({Key? key}) : super(key: key);

  @override
  State<CadastroMesasPage> createState() => _CadastroMesasPageState();
}

class _CadastroMesasPageState extends State<CadastroMesasPage> {
  List<dynamic> _mesas = [];
  bool _isLoading = true;
  String _pesquisa = '';
  String? uid;

  final TextEditingController _numeroMesaController = TextEditingController();
  final TextEditingController _quantidadeMesasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCacheUid();
  }

  Future<void> _fetchCacheUid() async {
    String? cachedUid = await VariaveisGlobais.getUidFromCache();
    setState(() {
      uid = cachedUid;
    });

    if (uid != null) {
      _fetchMesas();
    }
  }

  Future<void> _fetchMesas() async {
    try {
      final response = await http.get(Uri.parse('$LINK_BASE/$uid/mesas'));

      if (response.statusCode == 200) {
        setState(() {
          _mesas = json.decode(response.body);
          _mesas.sort((a, b) => a['numero_mesa'].compareTo(b['numero_mesa']));
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

  Future<void> _addMesa(String numeroMesa) async {
    try {
      final response = await http.post(
        Uri.parse('$LINK_BASE/$uid/mesas'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({'numero_mesa': numeroMesa}),
      );

      if (response.statusCode == 201) {
        _fetchMesas();
        Navigator.pop(context);
      } else {
        _showErrorDialog('Erro ao adicionar mesa: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('Erro ao adicionar mesa: $e');
    }
  }

  Future<void> _addMesasEmLote(int quantidade) async {
    try {
      // Calcula o número inicial com base na última mesa
      int numeroInicial = _mesas.isNotEmpty
          ? _mesas.map((mesa) => int.tryParse(mesa['numero_mesa'].toString() ?? '0') ?? 0).reduce((a, b) => a > b ? a : b) + 1
          : 1;

      List<Map<String, dynamic>> mesas = List.generate(
        quantidade,
            (index) => {'numero_mesa': (numeroInicial + index).toString()},
      );

      final response = await http.post(
        Uri.parse('$LINK_BASE/$uid/mesas'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(mesas),
      );

      if (response.statusCode == 201) {
        _fetchMesas(); // Atualiza a lista de mesas
        Navigator.pop(context);
      } else {
        _showErrorDialog('Erro ao adicionar mesas em lote: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('Erro ao adicionar mesas em lote: $e');
    }
  }

  void _showAddMesaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Mesa'),
        content: TextField(
          controller: _numeroMesaController,
          decoration: const InputDecoration(labelText: 'Número da Mesa'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              String numeroMesa = _numeroMesaController.text.trim();
              if (numeroMesa.isEmpty) {
                _showErrorDialog('Por favor, insira um número para a mesa.');
                return;
              }

              // Verifica se a mesa já existe
              bool mesaExiste = _mesas.any((mesa) => mesa['numero_mesa'] == numeroMesa);

              if (mesaExiste) {
                _showErrorDialog('Essa mesa já existe!');
              } else {
                _addMesa(numeroMesa);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showAddMesasEmLoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Mesas em Lote'),
        content: TextField(
          controller: _quantidadeMesasController,
          decoration: const InputDecoration(labelText: 'Quantidade de Mesas'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (_quantidadeMesasController.text.isNotEmpty) {
                int? quantidade = int.tryParse(_quantidadeMesasController.text);
                if (quantidade != null && quantidade > 0) {
                  _addMesasEmLote(quantidade);
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
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
              itemCount: _mesas.length,
              itemBuilder: (context, index) {
                final mesa = _mesas[index];
                if (_pesquisa.isEmpty || mesa['numero_mesa'].toString().contains(_pesquisa)) {
                  return _buildMesaCard(mesa);
                }
                return Container();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'addMesa',
            onPressed: _showAddMesaDialog,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'addMesasEmLote',
            onPressed: _showAddMesasEmLoteDialog,
            child: const Icon(Icons.add_to_photos),
          ),
        ],
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
