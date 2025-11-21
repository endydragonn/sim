// ==============================================================================
// TELA DE EDIÇÃO DE EVENTO
// ==============================================================================
// Função: Editar informações de um evento criado pelo usuário
// 
// Funcionalidades:
// - Formulário pré-preenchido com dados do evento
// - Campos editáveis: título, data, local, descrição, capacidade, etc.
// - Atualização via API (/api/bff/events/{eventId}) com método PUT
// - Validações de campos
// - Confirmação antes de salvar alterações
// - Opção de cancelar edição
// - SnackBars para feedback de sucesso/erro
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'auth.dart';
import 'dart:convert';
import 'telaHomePage.dart';
import 'telaGerenciarEventos.dart';
import 'modals.dart';
import '../helpers/date_input_formatter.dart';
import 'package:flutter/services.dart';

class EditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _buyLimitController = TextEditingController();
  
  bool _hasChanges = false;
  bool _isEAD = false;
  String _paymentType = 'Gratuito';

  @override
  void initState() {
    super.initState();
    _loadEventData();
    // Verificar autenticação ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    final user = Provider.of<HomePageData>(context, listen: false).user;

    // Se não estiver logado, redirecionar para tela principal
    if (user == null || user.isEmpty || user['user_id'] == null) {
      AppModals.showError(
        context,
        'Autenticação Necessária',
        'Você precisa estar logado para editar eventos.',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
          );
        },
      );
      return;
    }

    // Verificar se o usuário é o criador do evento
    if (widget.event['creator_id'] != user['user_id']) {
      AppModals.showError(
        context,
        'Acesso Negado',
        'Você só pode editar eventos criados por você.',
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
          );
        },
      );
    }
  }

  void _loadEventData() {
    _titleController.text = widget.event['event_name'] ?? '';
    _descriptionController.text = widget.event['description'] ?? '';
    _locationController.text = widget.event['address'] ?? '';
    _isEAD = widget.event['is_EAD'] ?? false;
    
    // Formatar data de ISO para DD/MM/AAAA
    if (widget.event['event_date'] != null) {
      final dateStr = widget.event['event_date'].toString();
      try {
        final date = DateTime.parse(dateStr);
        _dateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        _dateController.text = '';
      }
    }
    
    // Formatar buy_time_limit
    if (widget.event['buy_time_limit'] != null) {
      final dateStr = widget.event['buy_time_limit'].toString();
      try {
        final date = DateTime.parse(dateStr);
        _buyLimitController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } catch (e) {
        _buyLimitController.text = '';
      }
    }
    
    if (widget.event['lot_quantity'] != null) {
      _capacityController.text = widget.event['lot_quantity'].toString();
    }
    
    if (widget.event['price'] != null && widget.event['price'] > 0) {
      _paymentType = 'Pago';
      _priceController.text = widget.event['price'].toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _buyLimitController.dispose();
    super.dispose();
  }

  Future<void> _confirmEdit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final user = Provider.of<HomePageData>(context, listen: false).user;

      if (user == null || user['user_id'] == null) {
        AppModals.showError(
          context,
          'Erro de Autenticação',
          'Usuário não encontrado. Faça login novamente.',
        );
        return;
      }

      // Converter data do formato DD/MM/AAAA para ISO 8601
      String formattedDate;
      String buyTimeLimit;
      try {
        final dateParts = _dateController.text.split('/');
        if (dateParts.length != 3) {
          throw FormatException('Data inválida');
        }
        final day = dateParts[0].padLeft(2, '0');
        final month = dateParts[1].padLeft(2, '0');
        final year = dateParts[2];
        formattedDate = '$year-$month-${day}T09:00:00';
        
        if (_buyLimitController.text.isNotEmpty) {
          final buyParts = _buyLimitController.text.split('/');
          if (buyParts.length != 3) {
            throw FormatException('Data limite inválida');
          }
          final buyDay = buyParts[0].padLeft(2, '0');
          final buyMonth = buyParts[1].padLeft(2, '0');
          final buyYear = buyParts[2];
          buyTimeLimit = '$buyYear-$buyMonth-${buyDay}T23:59:59';
        } else {
          final dayBefore = int.parse(day) - 1;
          buyTimeLimit = '$year-$month-${dayBefore.toString().padLeft(2, '0')}T23:59:59';
        }
      } catch (e) {
        AppModals.showError(
          context,
          'Data Inválida',
          'Por favor, insira as datas no formato DD/MM/AAAA',
        );
        return;
      }

      final eventData = {
        'event_id': widget.event['event_id'],
        'event_name': _titleController.text,
        'event_date': formattedDate,
        'buy_time_limit': buyTimeLimit,
        'address': _isEAD ? null : _locationController.text,
        'description': _descriptionController.text,
        'is_EAD': _isEAD,
        'creator_id': user['user_id'],
        'quantity': widget.event['quantity'] ?? 0,
        'lot_quantity': _isEAD ? null : (_capacityController.text.isNotEmpty ? int.tryParse(_capacityController.text) : null),
        'price': _paymentType == 'Gratuito' ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0),
        'presenters': widget.event['presenters'] ?? [],
      };

      print('📤 Atualizando evento ${widget.event['event_id']}: ${jsonEncode(eventData)}');

      try {
        final response = await http.put(
          Uri.parse('/api/bff/events/${widget.event['event_id']}'),
          headers: ApiAuth.jsonHeaders(),
          body: jsonEncode(eventData),
        );

        print('📥 Resposta: ${response.statusCode}');
        if (response.statusCode >= 400) {
          print('❌ Erro: ${response.body}');
        }

        if (!mounted) return;

        if (response.statusCode == 200) {
          AppModals.showSuccess(
            context,
            'Evento Atualizado',
            'As alterações foram salvas com sucesso!',
            onOk: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
              );
            },
          );
        } else if (response.statusCode == 400) {
          String errorMsg = 'Verifique os dados do evento e tente novamente.';
          try {
            errorMsg = response.body;
          } catch (e) {}
          AppModals.showError(
            context,
            'Dados Inválidos',
            errorMsg,
          );
        } else {
          AppModals.showError(
            context,
            'Erro ao Atualizar',
            'Ocorreu um erro (${response.statusCode}). Tente novamente.',
          );
        }
      } catch (e) {
        if (!mounted) return;
        AppModals.showConnectionError(context);
      }
    }
  }

  void _cancelEdit(BuildContext context) {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Alterações não salvas'),
            content: const Text('Você tem alterações não salvas. Deseja sair mesmo assim?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar a editar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
                  );
                },
                child: const Text('Sair'),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Evento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _cancelEdit(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() => _hasChanges = true),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Título do Evento',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Workshop de Flutter',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Título é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                const Text('Data do Evento', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    hintText: 'DD/MM/AAAA',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Data é obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                CheckboxListTile(
                  title: const Text('Evento EAD (Online)'),
                  subtitle: const Text('Vagas ilimitadas, insira o link da reunião no campo de local'),
                  value: _isEAD,
                  onChanged: (bool? value) {
                    setState(() {
                      _isEAD = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 10.0),

                Text(
                  _isEAD ? 'Link da Reunião (Opcional)' : 'Local do Evento', 
                  style: const TextStyle(fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: _isEAD 
                        ? 'Ex: https://meet.google.com/abc-defg-hij' 
                        : 'Ex: Av. Paulista, 1000',
                    border: const OutlineInputBorder(),
                    helperText: _isEAD 
                        ? 'Insira o link do Google Meet, Zoom, Teams, etc.' 
                        : null,
                  ),
                  validator: (value) {
                    if (!_isEAD && (value == null || value.isEmpty)) {
                      return 'Local é obrigatório para eventos presenciais';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                if (!_isEAD) ...[
                  const Text('Capacidade (Vagas)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20.0),
                ],

                const Text('Data Limite de Inscrição (opcional)', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _buyLimitController,
                  decoration: const InputDecoration(
                    hintText: 'DD/MM/AAAA (padrão: 1 dia antes do evento)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                    DateInputFormatter(),
                  ],
                ),
                const SizedBox(height: 20.0),

                const Text('Descrição', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Descrição do evento',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Descrição é obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                const Text('Tipo de Pagamento', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<String>(
                  value: _paymentType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Gratuito', child: Text('Gratuito')),
                    DropdownMenuItem(value: 'Pago', child: Text('Pago')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _paymentType = newValue ?? 'Gratuito';
                    });
                  },
                ),
                const SizedBox(height: 20.0),

                if (_paymentType == 'Pago') ...[
                  const Text('Preço do Ingresso (R\$)', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 50.00',
                      border: OutlineInputBorder(),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_paymentType == 'Pago' && (value == null || value.isEmpty)) {
                        return 'Preço é obrigatório para eventos pagos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                ],

                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmEdit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Salvar Alterações'),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelEdit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
