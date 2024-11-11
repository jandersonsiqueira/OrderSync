import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CadastroCategoriasPage extends StatefulWidget {
  const CadastroCategoriasPage({Key? key}) : super(key: key);

  @override
  State<CadastroCategoriasPage> createState() => _CadastroCategoriasPageState();
}

class _CadastroCategoriasPageState extends State<CadastroCategoriasPage> {
  List<dynamic> _categorias = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  Future<void> _fetchCategorias() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await http.get(
        Uri.parse('https://ordersync.onrender.com/categorias'),
      );

      if (response.statusCode == 200) {
        List<dynamic> categorias = json.decode(response.body);
        setState(() {
          _categorias = categorias;
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar categorias');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao buscar categorias: $e');
    }
  }

  Future<void> _showCategoriaForm({Map<String, dynamic>? categoria}) async {
    final TextEditingController _nomeController = TextEditingController(
      text: categoria != null ? categoria['nm_categoria'] : '',
    );

    bool isEditing = categoria != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Editar Categoria' : 'Nova Categoria',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Categoria',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_nomeController.text.isEmpty) return;
                  setState(() {
                    _isProcessing = true;
                  });

                  _showLoadingIndicator();

                  if (isEditing) {
                    await _updateCategoria(categoria!['cd_categoria'], _nomeController.text);
                  } else {
                    await _addCategoria(_nomeController.text);
                  }

                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  setState(() {
                    _isProcessing = false;
                  });
                },
                child: Text(isEditing ? 'Atualizar' : 'Adicionar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _addCategoria(String nome) async {
    try {
      final response = await http.post(
        Uri.parse('https://ordersync.onrender.com/categorias'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nm_categoria': nome}),
      );

      if (response.statusCode == 201) {
        _fetchCategorias();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria adicionada com sucesso')),
        );
      } else {
        _showErrorDialog('Falha ao adicionar categoria');
      }
    } catch (e) {
      _showErrorDialog('Erro ao adicionar categoria: $e');
    }
  }

  Future<void> _updateCategoria(int id, String nome) async {
    try {
      final response = await http.put(
        Uri.parse('https://ordersync.onrender.com/categorias/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nm_categoria': nome}),
      );

      if (response.statusCode == 200) {
        _fetchCategorias();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria atualizada com sucesso')),
        );
      } else {
        _showErrorDialog('Falha ao atualizar categoria');
      }
    } catch (e) {
      _showErrorDialog('Erro ao atualizar categoria: $e');
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
        title: const Text('Cadastro de Categorias'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
          ? const Center(child: Text('Nenhuma categoria encontrada.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final categoria = _categorias[index];
          return _buildCategoriaCard(categoria);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoriaForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoriaCard(dynamic categoria) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            categoria['cd_categoria'].toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          categoria['nm_categoria'] ?? 'Categoria sem nome',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showCategoriaForm(categoria: categoria),
        ),
      ),
    );
  }
}