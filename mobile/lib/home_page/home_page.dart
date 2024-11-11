import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bem-vindo ao sistema!',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 100),
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
