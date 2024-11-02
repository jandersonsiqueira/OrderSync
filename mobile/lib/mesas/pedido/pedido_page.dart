import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../home_page/home_page.dart';
import '../pedido_parcial/pedidos_parciais_page.dart';
import '../view/categorias_view.dart';
import '../view/produtos_view.dart';
import 'carrinho_pedido_page.dart';
import 'fechamento_pedido_page.dart';

class PedidoPage extends StatefulWidget {
  final String mesaId;

  const PedidoPage({Key? key, required this.mesaId}) : super(key: key);

  @override
  _PedidoPageState createState() => _PedidoPageState();
}

class _PedidoPageState extends State<PedidoPage> {
  List<dynamic> categorias = [];
  List<dynamic> produtos = [];
  Map<String, dynamic> carrinho = {};
  String? categoriaSelecionada;
  String pesquisa = '';
  TextEditingController _observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
    _fetchProdutos();
    _carregarCarrinhoCache();
    _carregarObservacaoCache();
  }

  Future<void> _fetchCategorias() async {
    final response = await http.get(Uri.parse('https://ordersync.onrender.com/categorias'));
    if (response.statusCode == 200) {
      setState(() {
        categorias = json.decode(response.body);
        categorias.add({
          "cd_categoria": 0,
          "nm_categoria": "Todos os Produtos"
        });
      });
    } else {
      throw Exception('Falha ao carregar categorias');
    }
  }

  Future<void> _fetchProdutos() async {
    final response = await http.get(Uri.parse('https://ordersync.onrender.com/produtos'));
    if (response.statusCode == 200) {
      setState(() {
        produtos = json.decode(response.body);
      });
    } else {
      throw Exception('Falha ao carregar produtos');
    }
  }

  void _showProdutos(String categoriaId) {
    setState(() {
      categoriaSelecionada = categoriaId;
    });
  }

  void _showCategorias() {
    setState(() {
      categoriaSelecionada = null;
      pesquisa = '';
    });
  }

  void _salvarCarrinhoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final carrinhoEncoded = json.encode(carrinho);
    prefs.setString('carrinho_${widget.mesaId}', carrinhoEncoded);
  }

  Future<void> _carregarCarrinhoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final carrinhoEncoded = prefs.getString('carrinho_${widget.mesaId}');
    if (carrinhoEncoded != null) {
      setState(() {
        carrinho = json.decode(carrinhoEncoded);
      });
    }
  }

  Future<void> _carregarObservacaoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final observacao = prefs.getString('observacao_${widget.mesaId}');
    if (observacao != null) {
      _observacaoController.text = observacao;
    }
  }

  void _salvarObservacaoCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('observacao_${widget.mesaId}', _observacaoController.text);
  }

  void _adicionarQtdCarrinho(Map<String, dynamic> produto, int quantidade) {
    final codigoProduto = produto['cd_produto'].toString();

    setState(() {
      if (carrinho.containsKey(codigoProduto)) {
        carrinho[codigoProduto]['quantidade'] += quantidade;
      } else {
        carrinho[codigoProduto] = {
          'quantidade': quantidade,
          'produto': produto,
        };
      }

      if (carrinho[codigoProduto]['quantidade'] <= 0) {
        carrinho.remove(codigoProduto);
      }

      _salvarCarrinhoCache();
    });
  }


  void _removerDoCarrinho(dynamic produto) {
    setState(() {
      carrinho.remove(produto['cd_produto']);
    });
  }

  Future<bool> _temPedidosParciais() async {
    final response = await http.get(Uri.parse('https://ordersync.onrender.com/pedidos/parcial?numero_mesa=${widget.mesaId}'));

    if (response.statusCode == 200) {
      final pedidosParciais = json.decode(response.body);
      return pedidosParciais.isNotEmpty;
    } else {
      throw Exception('Falha ao verificar pedidos parciais');
    }
  }

  void _finalizarAtendimento() async {
    bool temPedidosParciais = await _temPedidosParciais();

    if (!temPedidosParciais) {
      _showAlertaSemPedidosParciais();
      return;
    }

    String cdPedido = DateTime.now().toString().replaceAll('-', '').replaceAll(' ', '').replaceAll(':', '').replaceAll('.', '').substring(0, 14) + widget.mesaId;
    String dtEmissao = DateTime.now().toIso8601String();

    final pedidoData = {
      "cd_pedido": cdPedido,
      "numero_mesa": widget.mesaId,
      "dt_emissao": dtEmissao,
    };

    try {
      final response = await http.post(
        Uri.parse('https://ordersync.onrender.com/pedidos/final'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(pedidoData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Atendimento finalizado com sucesso!',
              style: TextStyle(color: Theme.of(context).canvasColor),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          carrinho.clear();
          _observacaoController.clear();
          _salvarObservacaoCache();
        });
        _finalizarMesa(widget.mesaId);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (Route<dynamic> route) => false,
        );
      } else {
        throw Exception('Falha ao finalizar atendimento');
      }
    } catch (e) {
      print('Erro ao finalizar atendimento: $e');
    }
  }

  void _showAlertaSemPedidosParciais() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sem Pedidos Parciais'),
          content: Text('Não há pedidos parciais para esta mesa.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _finalizarMesa(String mesaId) async {
    final response = await http.put(
      Uri.parse('https://ordersync.onrender.com/mesas/$mesaId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'status': 'livre',
        'observacao': '',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao finalizar atendimento');
    }
  }

  int _getQuantidadeProdutos() {
    return carrinho.length;
  }

  double _getTotalCarrinho() {
    double total = 0.0;
    carrinho.forEach((key, item) {
      total += item['produto']['pr_venda'] * item['quantidade'];
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (categoriaSelecionada != null) {
          _showCategorias();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              'Pedido - Mesa ${widget.mesaId}',
              style: const TextStyle(
                color: Colors.white,
              )
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.point_of_sale_sharp),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PedidosParciaisPage(mesaId: widget.mesaId),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (categoriaSelecionada == null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _observacaoController,
                  decoration: InputDecoration(
                    labelText: 'Observação/Apelido da Mesa',
                    labelStyle: TextStyle(
                      color: Theme.of(context).canvasColor,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    prefixIcon: Icon(
                      Icons.note_alt_outlined,
                      color: Theme.of(context).canvasColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Theme.of(context).canvasColor!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Theme.of(context).canvasColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).canvasColor,
                  ),
                  onChanged: (value) {
                    _salvarObservacaoCache();
                  },
                ),
              ),
            Expanded(
              child: categoriaSelecionada == null ? _buildCategoriasView() : _buildProdutosView(),
            ),
            if (categoriaSelecionada != null) _buildCarrinhoResumo(),
          ],
        ),
        floatingActionButton: categoriaSelecionada == null
            ? _buildFloatingActionButton()
            : null,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showMenu(context);
      },
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(
        Icons.menu_sharp,
        color: Colors.white,
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.check),
                title: Text('Finalizar Atendimento'),
                onTap: () {
                  _finalizarAtendimento();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriasView() {
    return CategoriasView(
      categorias: categorias,
      onCategoriaTap: _showProdutos,
    );
  }

  Widget _buildProdutosView() {
    return ProdutosView(
      produtos: produtos,
      categoriaSelecionada: categoriaSelecionada,
      pesquisa: pesquisa,
      carrinho: carrinho,
      adicionarQtdCarrinho: _adicionarQtdCarrinho,
      onPesquisaChanged: (value) {
        setState(() {
          pesquisa = value;
        });
      },
    );
  }


  Widget _buildCarrinhoResumo() {
    return CarrinhoPedidoPage(
      subtotal: _getTotalCarrinho(),
      quantidadeProdutos: _getQuantidadeProdutos(),
      onTap: _getQuantidadeProdutos() > 0 ?
          () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FechamentoPedidoPage(
              carrinho: carrinho,
              mesaId: widget.mesaId,
            ),
          ),
        );
      } : () {},
    );
  }
}