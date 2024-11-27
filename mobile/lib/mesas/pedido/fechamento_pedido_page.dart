import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../variaveis_globais.dart';

class FechamentoPedidoPage extends StatefulWidget {
  final Map<String, dynamic> carrinho;
  final String mesaId;

  const FechamentoPedidoPage({Key? key, required this.carrinho, required this.mesaId}) : super(key: key);

  @override
  _FechamentoPedidoPageState createState() => _FechamentoPedidoPageState();
}

class _FechamentoPedidoPageState extends State<FechamentoPedidoPage> {

  bool isLoading = false;
  String? uid;

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
  }

  Future<void> finalizarPedido(BuildContext context) async {
    setState(() {
      isLoading = true; // Inicia o carregamento
    });

    final double totalPedido = widget.carrinho.values
        .map((item) => item['produto']['pr_venda'] * item['quantidade'])
        .reduce((value, element) => value + element);

    String cdPedido = DateTime.now().toString().replaceAll('-', '').replaceAll(' ', '').replaceAll(':', '').replaceAll('.', '').substring(0, 17) + widget.mesaId;
    String dtEmissao = DateTime.now().toIso8601String();

    final pedidoData = {
      'cd_pedido': cdPedido,
      'numero_mesa': widget.mesaId,
      'dt_emissao': dtEmissao,
      'vr_pedido': totalPedido,
      'itens': widget.carrinho.values.map((item) {
        return {
          'cd_pedido': cdPedido,
          'cd_produto': item['produto']['cd_produto'],
          'pr_venda': item['produto']['pr_venda'],
          'qt_item': item['quantidade'],
          'observacao': item['observacao'],
        };
      }).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse('$LINK_BASE/$uid/pedidos/parcial'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(pedidoData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pedido finalizado com sucesso!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _limparCarrinhoCache();
        Navigator.popUntil(context, ModalRoute.withName('/mesas_page'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao finalizar o pedido: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _removerItem(String cdProduto) {
      setState(() {
      widget.carrinho.remove(cdProduto);
      });
    _salvarCarrinhoCache();
  }

  void _limparCarrinhoCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('carrinho_${widget.mesaId}');
    }

  void _salvarCarrinhoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final carrinhoEncoded = json.encode(widget.carrinho);
    prefs.setString('carrinho_${widget.mesaId}', carrinhoEncoded);
  }

  void _editarItem(BuildContext context, String cdProduto, int quantidadeAtual, String observacaoAtual) {
    TextEditingController quantidadeController = TextEditingController(text: quantidadeAtual.toString());
    TextEditingController observacaoController = TextEditingController(text: observacaoAtual);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            'Editar Produto',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: observacaoController,
                  decoration: InputDecoration(
                    labelText: 'Observação',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  widget.carrinho[cdProduto]['quantidade'] = int.parse(quantidadeController.text);
                  widget.carrinho[cdProduto]['observacao'] = observacaoController.text;
                });
                _salvarCarrinhoCache();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).canvasColor,
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              child: Text('Salvar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).canvasColor,
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPedido = widget.carrinho.isNotEmpty
        ? widget.carrinho.values
        .map((item) => item['produto']['pr_venda'] * item['quantidade'])
        .reduce((value, element) => value + element)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resumo do Pedido - Mesa ${widget.mesaId}',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.carrinho.length,
                  itemBuilder: (context, index) {
                    final produto = widget.carrinho.values.elementAt(index)['produto'];
                    final quantidade = widget.carrinho.values.elementAt(index)['quantidade'];
                    final totalProduto = produto['pr_venda'] * quantidade;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          produto['cd_produto'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(produto['nm_produto']),
                      subtitle: Text('Quantidade: $quantidade'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'R\$ $totalProduto',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removerItem(produto['cd_produto'].toString());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Produto removido do carrinho.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      onTap: () => _editarItem(
                        context,
                        produto['cd_produto'].toString(),
                        quantidade,
                        widget.carrinho[produto['cd_produto'].toString()]['observacao'] ?? '',
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total do Pedido: R\$ $totalPedido',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: isLoading && uid != null ? null : () => finalizarPedido(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Finalizar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
