// ==============================================================================
// UTILITÁRIO DE SNACKBARS (NOTIFICAÇÕES)
// ==============================================================================
// Função: Exibir mensagens de feedback visual para o usuário
// 
// Tipos de SnackBars:
// - showError(): Vermelho - Erros gerais
// - showSuccess(): Verde - Ações bem-sucedidas (com callback opcional)
// - showInfo(): Azul - Mensagens informativas
// 
// SnackBars Específicos:
// - showLoginError(): Erro de autenticação (email/senha incorretos)
// - showLoginSuccess(): Login bem-sucedido com nome do usuário
// - showRegisterSuccess(): Cadastro realizado com sucesso
// - showRegisterError(): Falha no cadastro (email duplicado, etc.)
// - showConnectionError(): Erro de conexão com servidor
// 
// Características:
// - Aparecem na parte inferior (floating)
// - Desaparecem automaticamente (3-4 segundos)
// - Não bloqueiam a interface do usuário
// - Ícones e cores distintivas para cada tipo
// ==============================================================================

import 'package:flutter/material.dart';

class AppModals {
  // SnackBar de erro genérico
  static void showError(BuildContext context, String title, String message, {VoidCallback? onOk}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: onOk != null
            ? SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: onOk,
              )
            : null,
      ),
    ).closed.then((_) {
      if (onOk != null) {
        onOk();
      }
    });
  }

  // SnackBar de sucesso genérico
  static void showSuccess(BuildContext context, String title, String message,
      {VoidCallback? onOk}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    // Executar callback após um pequeno delay se fornecido
    if (onOk != null) {
      Future.delayed(const Duration(milliseconds: 500), onOk);
    }
  }

  // SnackBar específico: Erro de Login (usuário/senha incorretos)
  static void showLoginError(BuildContext context) {
    showError(
      context,
      'Erro de Autenticação',
      'Email ou senha incorretos. Verifique suas credenciais.',
    );
  }

  // SnackBar específico: Login bem-sucedido
  static void showLoginSuccess(BuildContext context, String userName,
      {VoidCallback? onOk}) {
    showSuccess(
      context,
      'Acesso Confirmado',
      'Bem-vindo(a), $userName!',
      onOk: onOk,
    );
  }

  // SnackBar específico: Cadastro bem-sucedido
  static void showRegisterSuccess(BuildContext context, {VoidCallback? onOk}) {
    showSuccess(
      context,
      'Cadastro Realizado',
      'Sua conta foi criada com sucesso!',
      onOk: onOk,
    );
  }

  // SnackBar específico: Erro no cadastro
  static void showRegisterError(BuildContext context, String? errorMessage) {
    showError(
      context,
      'Erro no Cadastro',
      errorMessage ?? 'Não foi possível criar sua conta. Verifique os dados.',
    );
  }

  // SnackBar de erro de conexão
  static void showConnectionError(BuildContext context) {
    showError(
      context,
      'Erro de Conexão',
      'Não foi possível conectar ao servidor. Verifique sua conexão.',
    );
  }

  // SnackBar de informação (azul)
  static void showInfo(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
