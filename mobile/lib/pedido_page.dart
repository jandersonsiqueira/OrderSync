import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:order_sync/carrinho_pedido_page.dart';
import 'package:order_sync/produtos_view.dart';
import 'dart:convert';
import 'fechamento_pedido_page.dart';
import 'categorias_view.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
    _fetchProdutos();
    _carregarCarrinhoCache();
  }

  Future<void> _fetchCategorias() async {
    final response = await http.get(Uri.parse('http://192.168.0.6:5000/categorias'));
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
    final response = await http.get(Uri.parse('http://192.168.0.6:5000/produtos'));
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
          title: Text('Pedido - Mesa ${widget.mesaId}'),
        ),
        body: Column(
          children: [
            Expanded(
              child: categoriaSelecionada == null ? _buildCategoriasView() : _buildProdutosView(),
            ),
            _buildCarrinhoResumo(),
          ],
        ),
      ),
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
