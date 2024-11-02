import 'package:flutter/material.dart';

class ProdutosView extends StatelessWidget {
  final List<dynamic> produtos;
  final String? categoriaSelecionada;
  final String pesquisa;
  final Map<String, dynamic> carrinho;
  final Function(Map<String, dynamic>, int) adicionarQtdCarrinho;
  final Function(String) onPesquisaChanged;

  ProdutosView({
    required this.produtos,
    required this.categoriaSelecionada,
    required this.pesquisa,
    required this.carrinho,
    required this.adicionarQtdCarrinho,
    required this.onPesquisaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final produtosFiltrados = categoriaSelecionada == '0'
        ? produtos
        : produtos.where((produto) => produto['cd_categoria'] == int.parse(categoriaSelecionada!)).toList();

    final produtosPesquisados = produtosFiltrados.where((produto) {
      final nomeProduto = produto['nm_produto'].toLowerCase();
      final codigoProduto = produto['cd_produto'].toString();
      return nomeProduto.contains(pesquisa.toLowerCase()) || codigoProduto.contains(pesquisa);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: onPesquisaChanged,
            decoration: InputDecoration(
              labelText: 'Pesquisar produto',
              border: OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: produtosPesquisados.isEmpty
              ? const Center(child: Text('Nenhum produto encontrado'))
              : ListView.builder(
            itemCount: produtosPesquisados.length,
            itemBuilder: (context, index) {
              final produto = produtosPesquisados[index];
              final String codigoProduto = produto['cd_produto'].toString();
              final int quantidade = carrinho.containsKey(codigoProduto)
                  ? carrinho[codigoProduto]['quantidade']
                  : 0;
              final double subtotal = produto['pr_venda'] * quantidade;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 15,
                            child: Text(
                              codigoProduto,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              produto['nm_produto'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'R\$ ${produto['pr_venda']}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal: R\$ ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (quantidade > 0) {
                                    adicionarQtdCarrinho(produto, -1);
                                  }
                                },
                              ),
                              Text(
                                '$quantidade',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  adicionarQtdCarrinho(produto, 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}