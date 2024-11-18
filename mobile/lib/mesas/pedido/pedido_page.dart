import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../home_page/home_page.dart';
import '../../variaveis_globais.dart';
import '../controller/categorias_controller.dart';
import '../controller/mesas_controller.dart';
import '../controller/produtos_controller.dart';
import '../pedido_parcial/pedidos_parciais_page.dart';
import '../view/categorias_view.dart';
import '../view/produtos_view.dart';
import 'carrinho_pedido_page.dart';
import 'fechamento_pedido_page.dart';

class PedidoPage extends StatefulWidget {
  final Map<String, dynamic> mesa;

  PedidoPage({required this.mesa});

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
  late String mesaId = widget.mesa['numero_mesa'].toString();
  late String mesaStatus = widget.mesa['status'].toString();
  final CategoriasController categoriasController = CategoriasController();
  final ProdutosController produtosController = ProdutosController();
  late final MesasController mesasController;
  late bool temPedidosParciais;
  late String uid;

  @override
  void initState() {
    super.initState();
    _fetchCacheUid();
    _carregarCarrinhoCache();
    _carregarObservacaoCache();
  }

  Future<void> _fetchCacheUid() async {
    String? cachedUid = await VariaveisGlobais.getUidFromCache();
    setState(() {
      uid = cachedUid!;
    });

    if (uid != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final categoriasData = await categoriasController.fetchCategorias(uid!);
      final produtosData = await produtosController.fetchProdutos(uid!);
      final mesaController = MesasController(
        uid: uid,
        mesaId: mesaId,
        context: context,
      );

      setState(() {
        categorias = categoriasData;
        produtos = produtosData;
        mesasController = mesaController;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
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
    prefs.setString('carrinho_${mesaId}', carrinhoEncoded);
  }

  Future<void> _carregarCarrinhoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final carrinhoEncoded = prefs.getString('carrinho_${mesaId}');
    if (carrinhoEncoded != null) {
      setState(() {
        carrinho = json.decode(carrinhoEncoded);
      });
    }
  }

  Future<void> _carregarObservacaoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final observacao = prefs.getString('observacao_${mesaId}');
    if (observacao != null) {
      _observacaoController.text = observacao;
    }
  }

  void _salvarObservacaoCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('observacao_${mesaId}', _observacaoController.text);
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

  void _finalizarAtendimento() async {
    temPedidosParciais = await mesasController.verificarPedidosParciais();

    if (!temPedidosParciais) {
      mesasController.showAlertaSemPedidosParciais();
      return;
    }

    String cdPedido = DateTime.now().toString().replaceAll('-', '').replaceAll(' ', '').replaceAll(':', '').replaceAll('.', '').substring(0, 14) + mesaId;
    String dtEmissao = DateTime.now().toIso8601String();

    final pedidoData = {
      "cd_pedido": cdPedido,
      "numero_mesa": mesaId,
      "dt_emissao": dtEmissao,
    };

    try {
      final response = await http.post(
        Uri.parse('https://ordersync.onrender.com/$uid/pedidos/final'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(pedidoData),
      );

      if (response.statusCode == 200) {
        setState(() {
          carrinho.clear();
          _observacaoController.clear();
          _salvarObservacaoCache();
        });
        String msgAlerta = 'Atendimento finalizado com sucesso!';
        _statusMesa(mesaId, 'livre', msgAlerta);
      } else {
        throw Exception('Falha ao finalizar atendimento');
      }
    } catch (e) {
      print('Erro ao finalizar atendimento: $e');
    }
  }

  Future<void> _statusMesa(String mesaId, String status, String msgAlerta) async {
    final response = await http.put(
      Uri.parse('https://ordersync.onrender.com/$uid/mesas/$mesaId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'status': '$status',
        'observacao': '',
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msgAlerta,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
            (Route<dynamic> route) => false,
      );
    } else {
      throw Exception('Falha ao mudar o status da mesa');
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
              'Pedido - Mesa ${mesaId}',
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
                    builder: (context) => PedidosParciaisPage(mesaId: mesaId),
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
            if (categoriaSelecionada != null)
              _buildCarrinhoResumo(),
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
              if (mesaStatus == 'andamento') ...[
              ListTile(
                leading: Icon(Icons.check),
                title: Text('Fechar Mesa'),
                onTap: () async {
                  temPedidosParciais = await mesasController.verificarPedidosParciais();
                  if (!temPedidosParciais) {
                    mesasController.showAlertaSemPedidosParciais();
                    return;
                  } else {
                    String msgAlerta = 'Mesa fechada, aguardando pagamento';
                    _statusMesa(mesaId, 'aguardando pagamento', msgAlerta);
                    Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text('Cancelar Mesa'),
                  onTap: () async {
                    temPedidosParciais = await mesasController.verificarPedidosParciais();
                    if (temPedidosParciais) {
                      mesasController.showAlertaComPedidosParciais();
                      return;
                    } else {
                      String msgAlerta = 'Mesa cancelada com sucesso';
                      _statusMesa(mesaId, 'livre', msgAlerta);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
              if (mesaStatus == 'aguardando pagamento') ...[
                ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Realizar Pagamento'),
                  onTap: () {
                    _finalizarAtendimento();
                    Navigator.pop(context);
                  },
                ),
              ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Reabrir Mesa'),
                onTap: () {
                  String msgAlerta = 'Mesa reaberta com sucesso';
                  _statusMesa(mesaId, 'andamento', msgAlerta);
                  Navigator.pop(context);
                  },
                ),
              ]
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
      statusMesa: mesaStatus,
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
              mesaId: mesaId,
            ),
          ),
        );
      } : () {},
    );
  }
}