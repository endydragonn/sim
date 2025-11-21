// ==============================================================================
// TELA DE CADASTRO DE USUÁRIO
// ==============================================================================
// Função: Registro de novos usuários no sistema
// 
// Funcionalidades:
// - Formulário de cadastro com nome, email, senha e confirmação
// - Validações de campos (nome não vazio, email válido, senha mínima 6 caracteres)
// - Verificação de senha igual à confirmação
// - Criação de usuário via API (/api/bff/users)
// - Hash de senha com BCrypt no backend
// - SnackBars para feedback de sucesso/erro
// - Tratamento de erros (email duplicado, dados inválidos, erro de conexão)
// - Navegação para tela de login após cadastro bem-sucedido
// - Link para voltar à tela de login
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../helpers/date_input_formatter.dart';
import 'package:flutter/services.dart';
import 'telaPrincipal.dart'; // Assumindo import para MainScreen
import 'telaLogin.dart'; // Para LoginScreen
import 'auth.dart'; // ApiAuth
import 'modals.dart'; // Modais

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedBirthdate;
  
  // Mensagens de erro para cada campo
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _birthdateError;
  String? _passwordError;
  String? _confirmPasswordError;

  Future<void> _register() async {
    // Limpar erros anteriores
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _birthdateError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    // Validações com mensagens inline
    bool hasError = false;

    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Por favor, preencha seu nome completo.');
      hasError = true;
    }

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() => _emailError = 'Insira um e-mail válido.');
      hasError = true;
    }

    if (_phoneController.text.isEmpty) {
      setState(() => _phoneError = 'Por favor, insira seu telefone.');
      hasError = true;
    } else if (_phoneController.text.length < 10) {
      setState(() => _phoneError = 'Telefone deve ter pelo menos 10 dígitos.');
      hasError = true;
    }

    if (_selectedBirthdate == null) {
      setState(() => _birthdateError = 'Por favor, selecione sua data de nascimento.');
      hasError = true;
    }

    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      setState(() => _passwordError = 'A senha deve ter pelo menos 6 caracteres.');
      hasError = true;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'As senhas digitadas não coincidem.');
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'birthdate': _selectedBirthdate!.toIso8601String().split('T')[0], // Formato YYYY-MM-DD
        'password': _passwordController.text,
      };

      final response = await http.post(
        Uri.parse('/api/bff/users'),
        headers: ApiAuth.jsonHeaders(),
        body: jsonEncode(userData),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        // Cadastro bem-sucedido
        if (!mounted) return;
        AppModals.showRegisterSuccess(
          context,
          onOk: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        );
      } else if (response.statusCode == 400) {
        // Erro de validação (ex: email já cadastrado)
        if (!mounted) return;
        String errorMsg = 'Verifique se o email já está cadastrado.';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['message'] ?? errorMsg;
        } catch (_) {}
        
        setState(() {
          _emailError = errorMsg;
        });
      } else {
        // Erro genérico do servidor
        if (!mounted) return;
        AppModals.showRegisterError(
          context,
          'Erro no servidor (código ${response.statusCode}). Tente novamente mais tarde.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      AppModals.showConnectionError(context);
    }
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    
    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        _birthdateError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Cadastro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20.0),
            const Text(
              'Cadastro',
              style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20.0),

            const Text('Nome completo'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Seu nome completo',
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              onChanged: (value) {
                if (_nameError != null && value.isNotEmpty) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 20.0),

            const Text('Email'),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'seuemail@example.com',
                border: const OutlineInputBorder(),
                errorText: _emailError,
              ),
              onChanged: (value) {
                if (_emailError != null && value.contains('@')) {
                  setState(() => _emailError = null);
                }
              },
            ),
            const SizedBox(height: 20.0),

            const Text('Telefone'),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: '(00) 00000-0000',
                border: const OutlineInputBorder(),
                errorText: _phoneError,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                if (_phoneError != null && value.length >= 10) {
                  setState(() => _phoneError = null);
                }
              },
            ),
            const SizedBox(height: 20.0),

            const Text('Data de Nascimento'),
            TextField(
              controller: _birthdateController,
              decoration: InputDecoration(
                hintText: 'DD/MM/AAAA',
                border: const OutlineInputBorder(),
                errorText: _birthdateError,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectBirthdate,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                DateInputFormatter(),
              ],
              onChanged: (value) {
                if (_birthdateError != null && value.length >= 10) {
                  setState(() => _birthdateError = null);
                }
                // Atualiza _selectedBirthdate se possível
                try {
                  if (value.length == 10) {
                    final parts = value.split('/');
                    final day = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final year = int.parse(parts[2]);
                    _selectedBirthdate = DateTime(year, month, day);
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: 20.0),

            const Text('Senha'),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Senha',
                border: const OutlineInputBorder(),
                errorText: _passwordError,
              ),
              onChanged: (value) {
                if (_passwordError != null && value.length >= 6) {
                  setState(() => _passwordError = null);
                }
              },
            ),
            const SizedBox(height: 20.0),

            const Text('Confirmar senha'),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirme sua senha',
                border: const OutlineInputBorder(),
                errorText: _confirmPasswordError,
              ),
              onChanged: (value) {
                if (_confirmPasswordError != null && value == _passwordController.text) {
                  setState(() => _confirmPasswordError = null);
                }
              },
            ),
            const SizedBox(height: 20.0),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text('Completar cadastro'),
              ),
            ),
            const SizedBox(height: 10.0),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                'Já tem uma conta? Faça login',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}