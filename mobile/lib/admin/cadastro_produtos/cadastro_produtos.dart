import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CadastroProdutosPage extends StatefulWidget {
  const CadastroProdutosPage({Key? key}) : super(key: key);

  @override
  State<CadastroProdutosPage> createState() => _CadastroProdutosPageState();
}

class _CadastroProdutosPageState extends State<CadastroProdutosPage> {
  List<dynamic> _produtos = [];
  List<dynamic> _categorias = [];
  bool _isLoading = true;
  String _pesquisa = '';

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
    _fetchProdutos();
  }

  Future<void> _fetchProdutos() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await http.get(
        Uri.parse('https://ordersync.onrender.com/produtos'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _produtos = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar produtos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao buscar produtos: $e');
    }
  }

  Future<void> _fetchCategorias() async {
    try {
      final response = await http.get(
        Uri.parse('https://ordersync.onrender.com/categorias'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _categorias = json.decode(response.body);
        });
      } else {
        throw Exception('Falha ao carregar categorias');
      }
    } catch (e) {
      _showErrorDialog('Erro ao buscar categorias: $e');
    }
  }

  void _showProdutoForm({Map<String, dynamic>? produto}) async {
    final TextEditingController _nomeController = TextEditingController(
      text: produto?['nm_produto'] ?? '',
    );
    final TextEditingController _precoCustoController = TextEditingController(
      text: produto?['pr_custo']?.toString() ?? '',
    );
    final TextEditingController _precoVendaController = TextEditingController(
      text: produto?['pr_venda']?.toString() ?? '',
    );

    int? categoriaSelecionada = produto?['cd_categoria'];
    bool isEditing = produto != null;

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
                isEditing ? 'Editar Produto' : 'Novo Produto',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: categoriaSelecionada,
                dropdownColor: Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map<DropdownMenuItem<int>>((categoria) {
                  return DropdownMenuItem<int>(
                    value: categoria['cd_categoria'],
                    child: Text(categoria['nm_categoria']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    categoriaSelecionada = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _precoCustoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço de Custo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _precoVendaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço de Venda',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (isEditing) {
                    _updateProduto(
                      produto!['cd_produto'],
                      _nomeController.text,
                      categoriaSelecionada,
                      double.tryParse(_precoCustoController.text) ?? 0.0,
                      double.tryParse(_precoVendaController.text) ?? 0.0,
                    );
                  } else {
                    _createProduto(
                      _nomeController.text,
                      categoriaSelecionada,
                      double.tryParse(_precoCustoController.text) ?? 0.0,
                      double.tryParse(_precoVendaController.text) ?? 0.0,
                    );
                  }
                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'Atualizar' : 'Adicionar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createProduto(
      String nome,
      int? categoriaId,
      double precoCusto,
      double precoVenda,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('https://ordersync.onrender.com/produtos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nm_produto': nome,
          'cd_categoria': categoriaId,
          'pr_custo': precoCusto,
          'pr_venda': precoVenda,
        }),
      );

      if (response.statusCode == 201) {
        _fetchProdutos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto adicionado com sucesso'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorDialog('Falha ao adicionar produto');
      }
    } catch (e) {
      _showErrorDialog('Erro ao adicionar produto: $e');
    }
  }


  Future<void> _updateProduto(
      int id,
      String nome,
      int? categoriaId,
      double precoCusto,
      double precoVenda,
      ) async {
    try {
      final response = await http.put(
        Uri.parse('https://ordersync.onrender.com/produtos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nm_produto': nome,
          'cd_categoria': categoriaId,
          'pr_custo': precoCusto,
          'pr_venda': precoVenda,
        }),
      );

      if (response.statusCode == 200) {
        _fetchProdutos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto atualizado com sucesso'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorDialog('Falha ao atualizar produto');
      }
    } catch (e) {
      _showErrorDialog('Erro ao atualizar produto: $e');
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
        title: const Text('Cadastro de Produtos'),
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
              decoration: InputDecoration(
                labelText: 'Pesquisar produto',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _produtos.isEmpty
                ? const Center(child: Text('Nenhum produto encontrado.'))
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final produto = _produtos[index];
                if (_pesquisa.isEmpty || produto['nm_produto']
                    .toLowerCase()
                    .contains(_pesquisa.toLowerCase()) ||
                    produto['cd_produto'].toString().contains(_pesquisa)) {
                  return _buildProdutoCard(produto);
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProdutoForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProdutoCard(dynamic produto) {
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
            produto['cd_produto'].toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          produto['nm_produto'] ?? 'Produto sem nome',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Preço: R\$ ${produto['pr_venda']?.toStringAsFixed(2) ?? '0.00'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showProdutoForm(produto: produto),
        ),
      ),
    );
  }
}
