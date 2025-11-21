// ==============================================================================
// TELA PRINCIPAL (DASHBOARD)
// ==============================================================================
// Função: Hub central após login - visualização e navegação para funcionalidades
// 
// Funcionalidades:
// - Exibição de eventos disponíveis (busca via API /api/bff/events/search)
// - Barra de navegação superior com nome do site
// - Menu do usuário (Avatar com opções):
//   • Gerenciar Eventos (criar e editar eventos do usuário)
//   • Editar Perfil
//   • Logout (limpa token JWT e dados do usuário)
// - Busca de eventos com preview de resultados
// - Navegação para tela de criação de evento
// - Navegação para tela de pesquisa de eventos
// - Cards de eventos com informações básicas
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'auth.dart';
import 'dart:convert';
import 'telaPesquisarEvento.dart';
import 'telaGerenciarEventos.dart'; // ManageEventsScreen
import 'telaInscricaoEvento.dart'; // EventRegistrationScreen
import 'telaHomePage.dart'; // HomeScreen & HomePageData
import 'telaEdicaoPerfil.dart';
import 'telaCriacaoEvento.dart';
import 'telaInscricaoEvento.dart'; // Importar tela de inscrição
import 'telaHomePage.dart'; // Para deslogar

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
  final response = await http.get(
    Uri.parse('/api/bff/events/search?term='),
    headers: ApiAuth.jsonHeaders(),
  );
    if (response.statusCode == 200) {
      setState(() {
        events = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomePageData homePageData = Provider.of<HomePageData>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              homePageData.siteName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            const SizedBox(width: 16.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchEventScreen()),
                );
              },
              child: const Text(
                'Procurar evento',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(width: 8.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
                );
              },
              child: const Text(
                'Gerenciar eventos',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'Editar Perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              } else if (value == 'Criar Evento') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEventScreen()),
                );
              } else if (value == 'Deslogar') {
                // Limpar token ao deslogar
                ApiAuth.clearToken();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Editar Perfil',
                child: Text('Editar Perfil'),
              ),
              const PopupMenuItem<String>(
                value: 'Criar Evento',
                child: Text('Criar Evento'),
              ),
              const PopupMenuItem<String>(
                value: 'Deslogar',
                child: Text('Deslogar'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(homePageData.userAvatarUrl),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Eventos em Destaque',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              ...events.map((event) => Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: <Widget>[
                    Image.network(
                      event['imageUrl'] ?? 'https://i.imgur.com/default.jpg',
                      height: 150.0,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                        Text(
                          event['event_name'],
                          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(event['description']),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () => _showEventDetails(context, event),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade100,
                                foregroundColor: Colors.purple.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              ),
                              child: const Text('saber mais'),
                            ),
                            const SizedBox(width: 8.0),
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 28),
                              onPressed: () {
                                // Ações adicionais
                              },
                            ),
                          ],
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event['event_name']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Descrição: ${event['description']}'),
                Text('Data do evento: ${event['event_date']}'),
                Text('Local do evento: ${event['address']}'),
                Text('Tipo de evento: ${event['type']}'),
                // Outros detalhes do BFF
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Voltar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventRegistrationScreen(event: event),
                  ),
                );
              },
              child: const Text('Inscrever-se'),
            ),
          ],
        );
      },
    );
  }
}
