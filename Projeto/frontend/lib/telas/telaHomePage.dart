// ==============================================================================
// TELA HOME PAGE (LANDING PAGE - ANTES DO LOGIN)
// ==============================================================================
// Função: Página inicial pública do sistema - primeiro contato do visitante
// 
// Funcionalidades:
// - Barra de navegação com nome do site e botões de Login/Cadastro
// - Imagem de destaque com texto overlay
// - Visualização pública de eventos disponíveis (sem autenticação)
// - Busca de eventos (endpoint público: /api/bff/events/search)
// - Cards de eventos com informações básicas
// - Navegação para tela de login
// - Navegação para tela de cadastro
// - Provider (HomePageData): gerencia estado global do usuário e eventos
// 
// Componentes:
// - HomePageData: ChangeNotifier com dados do usuário e eventos
// - MyApp: Widget raiz da aplicação
// - HomeScreen: Página inicial com lista de eventos
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'auth.dart';
import 'dart:convert';
import 'telaLogin.dart'; // corrigido caminho relativo
import 'telaPesquisarEvento.dart'; // SearchEventScreen
import 'telaCriacaoEvento.dart'; // CreateEventScreen

// 1. DATA_MODEL
class HomePageData extends ChangeNotifier {
  final String siteName;
  final List<String> navLinks;
  String userName;
  String userAvatarUrl;
  String mainImageUrl;
  String mainImageOverlayText;
  List<Map<String, dynamic>> events = []; // Adicionado para eventos dinâmicos
  Map<String, dynamic> user = {}; // Armazena usuário logado (id, name, email, etc.)

  HomePageData()
      : siteName = 'Organizador de Eventos',
        navLinks = const ['Procurar evento', 'Gerenciar eventos'],
        userName = 'Usuário 982',
        userAvatarUrl =
            'https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg',
        mainImageUrl =
            'https://i.imgur.com/xNdRovc.jpeg',
        mainImageOverlayText = '';

  void setUser(dynamic user) {
    if (user is Map<String, dynamic>) {
      this.user = user;
      userName = user['name'] ?? userName;
      if (user.containsKey('avatarUrl')) {
        userAvatarUrl = user['avatarUrl'];
      }
    }
    notifyListeners();
  }

  void setEvents(List<Map<String, dynamic>> newEvents) {
    events = newEvents;
    notifyListeners();
  }
}

// 2. O Widget Raiz (Root Widget)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomePageData>(
      create: (BuildContext context) => HomePageData(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'Custom UI App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

// 3. Homepage sem login
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      final eventsData = jsonDecode(response.body) as List;
      Provider.of<HomePageData>(context, listen: false).setEvents(eventsData.map((e) => e as Map<String, dynamic>).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomePageData homePageData = Provider.of<HomePageData>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _TopNavigationBar(homePageData: homePageData),
            _UserProfileSection(homePageData: homePageData),
            _MainContentCard(homePageData: homePageData),
            const _ActionButtonsSection(),
          ],
        ),
      ),
    );
  }
}

// 4. Widget: Barra de Navegação Superior
class _TopNavigationBar extends StatelessWidget {
  final HomePageData homePageData;

  const _TopNavigationBar({required this.homePageData});

  @override
  Widget build(BuildContext context) {
    // Verificar se há usuário logado
    final bool isLoggedIn = homePageData.user != null && homePageData.user.isNotEmpty;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              homePageData.siteName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            // Mostrar ícone de usuário se logado, senão mostrar botão de menu
            if (isLoggedIn)
              Row(
                children: [
                  Text(
                    homePageData.user['name'] ?? homePageData.user['email'] ?? 'Usuário',
                    style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                ],
              )
            else
              IconButton(
                icon: const Icon(Icons.more_vert, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Outros widgets ajustados para usar homePageData.events em vez de hardcode, ex.: em _MainContentCard
// Por exemplo, substituir hardcoded cards por ListView de homePageData.events

// Seção de perfil do usuário
class _UserProfileSection extends StatelessWidget {
  final HomePageData homePageData;
  const _UserProfileSection({required this.homePageData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(homePageData.userAvatarUrl),
            radius: 32,
          ),
            const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(homePageData.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Bem-vindo de volta!'),
            ],
          )
        ],
      ),
    );
  }
}

// Card principal com eventos listados dinamicamente
class _MainContentCard extends StatelessWidget {
  final HomePageData homePageData;
  const _MainContentCard({required this.homePageData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Eventos em Destaque', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final e in homePageData.events)
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (e['imageUrl'] != null)
                    Image.network(
                      e['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['event_name'] ?? 'Sem nome', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(e['description'] ?? 'Sem descrição'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (homePageData.events.isEmpty)
            const Text('Nenhum evento encontrado.'),
        ],
      ),
    );
  }
}

// Seção de botões de ação simples
class _ActionButtonsSection extends StatelessWidget {
  const _ActionButtonsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchEventScreen()),
              );
            },
            child: const Text('Explorar'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateEventScreen()),
              );
            },
            child: const Text('Criar Evento'),
          ),
        ],
      ),
    );
  }
}
