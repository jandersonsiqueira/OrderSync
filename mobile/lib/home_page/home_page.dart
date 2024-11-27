import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../variaveis_globais.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int totalPedidosDia = 0;
  double totalVendasDia = 0;
  int totalPedidosMes = 0;
  double totalVendasMes = 0;
  List<BarChartGroupData> produtosChartData = [];
  List<BarChartGroupData> mesasChartData = [];
  Map<String, String> produtosMap = {};
  Map<String, String> mesasMap = {};
  List<String> produtosLegends = [];
  List<String> mesasLegends = [];
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

    if (uid != null) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    final pedidosUrl = '$LINK_BASE/$uid/pedidos/final';
    final produtosUrl = '$LINK_BASE/$uid/produtos';
    final mesasUrl = '$LINK_BASE/$uid/mesas';

    try {
      final pedidosResponse = await http.get(Uri.parse(pedidosUrl));
      final produtosResponse = await http.get(Uri.parse(produtosUrl));
      final mesasResponse = await http.get(Uri.parse(mesasUrl));

      final pedidos = jsonDecode(pedidosResponse.body);
      final produtos = jsonDecode(produtosResponse.body);
      final mesas = jsonDecode(mesasResponse.body);

      for (var produto in produtos) {
        produtosMap[produto['cd_produto'].toString()] = produto['nm_produto'];
      }

      for (var mesa in mesas) {
        mesasMap[mesa['cd_mesa'].toString()] = mesa['numero_mesa'].toString();
      }

      DateTime hoje = DateTime.now();
      int pedidosHoje = 0;
      double vendasHoje = 0;
      int pedidosMesAtual = 0;
      double vendasMesAtual = 0;
      Map<String, double> vendasProdutos = {};
      Map<String, double> vendasMesas = {};

      for (var pedido in pedidos) {
        final dataPedido = DateTime.parse(pedido['dt_emissao']);
        final valorPedido = (pedido['vr_pedido'] as num).toDouble();
        final itens = pedido['itens'];
        final mesa = pedido['numero_mesa'].toString();

        if (dataPedido.year == hoje.year && dataPedido.month == hoje.month) {
          pedidosMesAtual += 1;
          vendasMesAtual += valorPedido;
        }

        if (dataPedido.year == hoje.year &&
            dataPedido.month == hoje.month &&
            dataPedido.day == hoje.day) {
          pedidosHoje += 1;
          vendasHoje += valorPedido;
        }

        for (var item in itens) {
          String cdProduto = item['cd_produto'].toString(); // Conversão para string
          double valorItem = (item['pr_venda'] as num).toDouble() *
              (item['qt_item'] as num).toDouble();

          vendasProdutos.update(
            cdProduto,
                (value) => value + valorItem,
            ifAbsent: () => valorItem,
          );
        }

        vendasMesas.update(
          mesa,
              (value) => value + valorPedido,
          ifAbsent: () => valorPedido,
        );
      }

      List<MapEntry<String, double>> topProdutos =
      vendasProdutos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      List<MapEntry<String, double>> topMesas =
      vendasMesas.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        totalPedidosDia = pedidosHoje;
        totalVendasDia = vendasHoje;
        totalPedidosMes = pedidosMesAtual;
        totalVendasMes = vendasMesAtual;

        final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple];

        produtosChartData = topProdutos
            .take(5)
            .toList()
            .asMap()
            .map((i, e) => MapEntry(
          i,
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 20,
                color: colors[i % colors.length],
              ),
            ],
          ),
        ))
            .values
            .toList();

        produtosLegends = topProdutos
            .take(5)
            .map((e) => produtosMap[e.key] ?? 'Produto ${e.key}')
            .toList();

        mesasChartData = topMesas
            .take(5)
            .toList()
            .asMap()
            .map((i, e) => MapEntry(
          i,
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 20,
                color: colors[i % colors.length],
              ),
            ],
          ),
        ))
            .values
            .toList();

        mesasLegends = topMesas
            .take(5)
            .map((e) => mesasMap[e.key] ?? 'Mesa ${e.key}')
            .toList();
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OrderSync',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildVendasCard('Vendas do Dia', totalPedidosDia,
                  totalVendasDia.toStringAsFixed(2)),
              const SizedBox(height: 16),
              _buildVendasCard('Vendas do Mês', totalPedidosMes,
                  totalVendasMes.toStringAsFixed(2)),
              const SizedBox(height: 16),
              _buildBarChart('Top 5 Produtos mais vendidos (R\$)', produtosChartData, produtosLegends),
              const SizedBox(height: 16),
              _buildBarChart('Top 5 Mesas mais vendidos (R\$)', mesasChartData, mesasLegends),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 100.0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: _bottomNavigationBarButton(
                context,
                text: 'Mesas',
                icon: FontAwesomeIcons.table,
                onPressed: () {
                  Navigator.pushNamed(context, '/mesas_page');
                },
              ),
              ),
              Expanded(
                child: _bottomNavigationBarButton(
                context,
                text: 'Vendas',
                icon: FontAwesomeIcons.coins,
                onPressed: () {
                  Navigator.pushNamed(context, '/vendas_page');
                },
              ),
              ),
              Expanded(
                child: _bottomNavigationBarButton(
                context,
                text: 'Cardápio',
                icon: FontAwesomeIcons.bars,
                  onPressed: () {
                    // Ação para o botão "Cardápio"
                  },
                ),
              ),
              Expanded(
                child: _bottomNavigationBarButton(
                context,
                text: 'Admin',
                icon: FontAwesomeIcons.userShield,
                onPressed: () {
                  Navigator.pushNamed(context, '/admin_page');
                },
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendasCard(String title, int total, String valor) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedidos:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'R\$ $valor',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(String title, List<BarChartGroupData> data, List<String> legends) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: data,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                            return Text(
                              (value.toInt() + 1).toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barTouchData: BarTouchData(enabled: true),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Legenda
            Wrap(
              spacing: 10,
              children: List.generate(
                legends.length,
                    (index) => _buildLegend(colors[index % colors.length], legends[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  List<BarChartGroupData> generateBarChartData(List<double> values) {
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple];
    return List.generate(values.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values[index],
            color: colors[index % colors.length],
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _bottomNavigationBarButton(
      BuildContext context, {
        required String text,
        required IconData icon,
        required VoidCallback onPressed,
      }) {
    return Container(
      width: 82.0,
      height: 76.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.fromLTRB(4.0, 12.0, 4.0, 2.0),
          minimumSize: Size(40, 40),
          foregroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FaIcon(
              icon,
              size: 35,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: .85,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}