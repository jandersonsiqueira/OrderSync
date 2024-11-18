import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../variaveis_globais.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        await VariaveisGlobais.saveUidToCache(uid);

        await createAdminDatabase(uid);
        Navigator.pop(context);
      } else {
        _showError('Erro ao criar usuário. Tente novamente.');
      }
    } catch (e) {
      _showError('Erro ao cadastrar: $e');
    }
  }


  Future<void> createAdminDatabase(String token) async {
    final response = await http.post(
      Uri.parse('http://10.0.0.31:5000/create-admin'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'token': token,
      }),
    );

    if (response.statusCode == 201) {
      // Sucesso ao criar base de dados
      print('Base de dados criada com sucesso!');
    } else {
      // Erro ao criar base de dados
      print('Erro ao criar base de dados: ${response.body}');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}