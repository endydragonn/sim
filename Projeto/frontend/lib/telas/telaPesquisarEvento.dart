// ==============================================================================
// TELA DE PESQUISA DE EVENTOS
// ==============================================================================
// Função: Buscar e filtrar eventos disponíveis no sistema
// 
// Funcionalidades:
// - Campo de busca com pesquisa em tempo real
// - Busca via API (/api/bff/events/search?term={query})
// - Exibição de resultados em cards
// - Informações exibidas: nome, data, local, tipo (EAD/Presencial)
// - Navegação para detalhes do evento ao clicar
// - Estados: loading, lista vazia, erro de conexão
// - Debounce na busca para evitar requisições excessivas
// - Filtros por tipo (EAD/Presencial) e ordenação por data
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'package:intl/intl.dart';
import 'telaInscricaoEvento.dart';

class SearchEventScreen extends StatefulWidget {
  const SearchEventScreen({super.key});

  @override
  State<SearchEventScreen> createState() => _SearchEventScreenState();
}

class _SearchEventScreenState extends State<SearchEventScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'Todos';
  String _selectedSort = 'Data (Mais próximo)';
  List<Map<String, dynamic>> _allEvents = [];
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadAllEvents();
  }

  Future<void> _checkAuthentication() async {
    // Usar o utilitário ApiAuth para checar token
    if (ApiAuth.token == null || ApiAuth.token!.isEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usar ApiAuth para fornecer headers com Authorization se houver token
      final headers = ApiAuth.jsonHeaders();
      // Busca todos os eventos (termo vazio retorna todos)
      final response = await http.get(
        Uri.parse('/api/bff/events/search?term='),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _allEvents = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
          _isInitialLoad = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar eventos: ${response.statusCode}';
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: $e';
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    String searchTerm = _searchController.text.toLowerCase();
    
    List<Map<String, dynamic>> filtered = _allEvents.where((event) {
      // Filtro de busca por texto
      bool matchesSearch = searchTerm.isEmpty ||
          (event['event_name']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
          (event['description']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
          (event['address']?.toString().toLowerCase().contains(searchTerm) ?? false);
      
      // Filtro por tipo (EAD/Presencial)
      bool matchesType = _selectedType == 'Todos' ||
          (_selectedType == 'EAD' && event['ead'] == true) ||
          (_selectedType == 'Presencial' && event['ead'] == false);
      
      return matchesSearch && matchesType;
    }).toList();

    // Ordenação
    if (_selectedSort == 'Data (Mais próximo)') {
      filtered.sort((a, b) {
        DateTime? dateA = _parseEventDate(a['event_date']);
        DateTime? dateB = _parseEventDate(b['event_date']);
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });
    } else if (_selectedSort == 'Data (Mais distante)') {
      filtered.sort((a, b) {
        DateTime? dateA = _parseEventDate(a['event_date']);
        DateTime? dateB = _parseEventDate(b['event_date']);
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });
    } else if (_selectedSort == 'Nome (A-Z)') {
      filtered.sort((a, b) => 
        (a['event_name'] ?? '').toString().compareTo((b['event_name'] ?? '').toString())
      );
    }

    return filtered;
  }

  DateTime? _parseEventDate(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return null;
    }
  }

  String _formatEventDate(dynamic dateStr) {
    DateTime? date = _parseEventDate(dateStr);
    if (date == null) return 'Data não disponível';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _getFilteredEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Procurar Evento'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Campo de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome, descrição ou local...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16.0),
            
            // Filtros
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: <String>['Todos', 'EAD', 'Presencial']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedType = newValue!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: InputDecoration(
                      labelText: 'Ordenar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: <String>[
                      'Data (Mais próximo)',
                      'Data (Mais distante)',
                      'Nome (A-Z)'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSort = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Contador de resultados
            Text(
              '${filteredEvents.length} evento(s) encontrado(s)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8.0),
            
            // Lista de eventos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAllEvents,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        )
                      : filteredEvents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isInitialLoad ? Icons.event_busy : Icons.search_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isInitialLoad
                                        ? 'Nenhum evento disponível'
                                        : 'Nenhum evento encontrado com os filtros selecionados',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = filteredEvents[index];
                                final eventId = event['event_id'];
                                final isEAD = event['ead'] == true;
                                
                                return Card(
                                  elevation: 2.0,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EventRegistrationScreen(
                                            eventId: eventId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Imagem do evento
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8.0),
                                            child: eventId != null
                                                ? Image.network(
                                                    '/api/bff/events/$eventId/image',
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 80,
                                                        height: 80,
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons.event,
                                                          size: 40,
                                                          color: Colors.grey,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.event,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          
                                          // Informações do evento
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  event['event_name'] ?? 'Sem nome',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatEventDate(event['event_date']),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isEAD ? Icons.computer : Icons.location_on,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        isEAD 
                                                            ? 'Evento Online (EAD)'
                                                            : event['address'] ?? 'Local não informado',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey[600],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (event['description'] != null && 
                                                    event['description'].toString().isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    event['description'],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isEAD ? Colors.blue[50] : Colors.green[50],
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        isEAD ? 'EAD' : 'Presencial',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: isEAD ? Colors.blue[700] : Colors.green[700],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (event['quant'] != null)
                                                      Text(
                                                        '${event['quant']} vagas',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Ícone de navegação
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
