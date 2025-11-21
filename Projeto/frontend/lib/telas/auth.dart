// ==============================================================================
// UTILITÁRIO DE AUTENTICAÇÃO JWT
// ==============================================================================
// Função: Gerenciar token JWT e cabeçalhos de autenticação
// 
// Funcionalidades:
// - Armazenamento de token JWT (memória + localStorage via SharedPreferences)
// - initialize(): Carrega token salvo ao iniciar app
// - setToken(token, persist): Salva token (persistente se persist=true)
// - clearToken(): Remove token (logout)
// - jsonHeaders(): Retorna headers HTTP com Authorization Bearer
// 
// Comportamento:
// - Se "Lembrar de mim" = true: token persiste após refresh (localStorage)
// - Se "Lembrar de mim" = false: token apenas na sessão atual (memória)
// ==============================================================================

// Utilitário para JWT no frontend com persistência
import 'package:shared_preferences/shared_preferences.dart';

class ApiAuth {
  static String? _token;
  static const String _tokenKey = 'jwt_token';

  // Inicializar: carregar token salvo
  static Future<void> initialize() async {
    print('🚀 ApiAuth.initialize() - Iniciando...');
    final prefs = await SharedPreferences.getInstance();
    print('📦 SharedPreferences obtido');
    
    // Listar todas as chaves armazenadas
    final keys = prefs.getKeys();
    print('🔑 Chaves armazenadas: $keys');
    
    _token = prefs.getString(_tokenKey);
    print('🔑 ApiAuth.initialize() - Token carregado: ${_token != null ? "SIM (${_token!.length} caracteres, início: ${_token!.substring(0, _token!.length > 20 ? 20 : _token!.length)}...)" : "NÃO"}');
  }

  // Salvar token permanente (quando "Lembrar de mim" está marcado)
  static Future<void> setToken(String? token, {bool persist = true}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    
    print('💾 ApiAuth.setToken() - persist=$persist, token=${token != null ? "presente" : "null"}');
    
    if (persist) {
      // Salvar no localStorage para persistir após refresh
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_tokenKey, token);
        print('✅ Token salvo no localStorage com chave "$_tokenKey"');
        
        // Verificar se foi salvo
        final saved = prefs.getString(_tokenKey);
        print('🔍 Verificação: Token recuperado = ${saved != null ? "SIM" : "NÃO"}');
      } else {
        await prefs.remove(_tokenKey);
        print('🗑️ Token removido do localStorage');
      }
    } else {
      // Não salvar no localStorage - apenas na memória (sessão atual)
      await prefs.remove(_tokenKey);
      print('⚠️ Token NÃO persistente - removido do localStorage');
    }
  }

  // Limpar token (logout)
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🚪 ApiAuth.clearToken() - Token removido (logout)');
  }

  static String? get token => _token;

  static Map<String, String> jsonHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }
}
