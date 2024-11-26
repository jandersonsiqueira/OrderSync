import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class MesasController {
  final String uid;
  final String mesaId;
  final BuildContext context;

  MesasController({
    required this.uid,
    required this.mesaId,
    required this.context,
  });

  Future<bool> _temPedidosParciais() async {
    final response = await http.get(
      Uri.parse('https://order-sync-three.vercel.app/$uid/pedidos/parcial?numero_mesa=$mesaId'),
    );

    if (response.statusCode == 200) {
      final pedidosParciais = json.decode(response.body);
      return pedidosParciais.isNotEmpty;
    } else {
      throw Exception('Falha ao verificar pedidos parciais');
    }
  }

  Future<bool> verificarPedidosParciais() async {
    try {
      return await _temPedidosParciais();
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  void showAlertaSemPedidosParciais() {
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

  void showAlertaComPedidosParciais() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pedidos Parciais'),
          content: Text('Existe pedidos parciais para esta mesa.'),
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
}
