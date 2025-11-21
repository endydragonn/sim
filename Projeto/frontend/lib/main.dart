import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'telas/telaHomePage.dart';
import 'telas/telaPrincipal.dart'; // MainScreen
import 'telas/auth.dart';

void main() async {
  print('🏁 main() - Iniciando aplicação');
  WidgetsFlutterBinding.ensureInitialized();
  print('⚙️ WidgetsFlutterBinding inicializado');
  
  // Carregar token salvo antes de iniciar o app
  await ApiAuth.initialize();
  print('✅ ApiAuth.initialize() completo');
  print('🎫 Token atual: ${ApiAuth.token != null ? "PRESENTE" : "AUSENTE"}');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Recuperar dados do usuário se houver token
  Future<Map<String, dynamic>?> _loadUserFromToken() async {
    print('👤 _loadUserFromToken() - Verificando token...');
    print('🎫 Token disponível: ${ApiAuth.token != null ? "SIM (${ApiAuth.token!.length} chars)" : "NÃO"}');
    
    if (ApiAuth.token == null || ApiAuth.token!.isEmpty) {
      print('❌ Sem token - usuário não logado');
      return null;
    }

    try {
      print('📡 Chamando /api/bff/users/me para restaurar sessão...');
      
      final headers = ApiAuth.jsonHeaders();
      print('📋 Headers sendo enviados: $headers');
      print('🔑 Authorization header: ${headers['Authorization']}');
      
      // Tentar fazer uma requisição para obter os dados do usuário atual
      // Assumindo que existe um endpoint /api/bff/users/me
      final response = await http.get(
        Uri.parse('/api/bff/users/me'),
        headers: headers,
      );

      print('📥 Resposta /me: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('📄 Body da resposta: ${response.body}');
      }

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Sessão restaurada: ${userData['email']}');
        print('📋 Dados do usuário completos: $userData');
        print('🆔 user_id presente? ${userData['user_id'] != null ? "SIM (${userData['user_id']})" : "NÃO"}');
        return userData;
      } else {
        print('❌ Falha ao restaurar sessão: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao restaurar sessão: $e');
      // Se falhar, limpar o token inválido
      await ApiAuth.clearToken();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomePageData>(
      create: (_) => HomePageData(),
      child: MaterialApp(
        title: 'Organizador de Eventos',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: FutureBuilder<Map<String, dynamic>?>(
          future: _loadUserFromToken(),
          builder: (context, snapshot) {
            // Enquanto carrega, mostrar splash
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Se carregou usuário, restaurar no Provider e ir para MainScreen
            if (snapshot.hasData && snapshot.data != null) {
              print('🎯 Navegando para MainScreen com sessão restaurada');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<HomePageData>(context, listen: false)
                    .setUser(snapshot.data!);
              });
              // Retornar MainScreen se usuário foi restaurado
              return const MainScreen();
            }

            // Sem sessão válida, mostrar HomeScreen (que tem botão de login)
            print('🏠 Navegando para HomeScreen (sem sessão)');
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}

// A Home real está em telas/telaHomePage.dart (HomeScreen)
