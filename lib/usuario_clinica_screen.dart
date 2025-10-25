import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:medinova/services/webhook_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioClinicaScreen extends StatefulWidget {
  const UsuarioClinicaScreen({super.key});

  @override
  State<UsuarioClinicaScreen> createState() => _UsuarioClinicaScreenState();
}

class _UsuarioClinicaScreenState extends State<UsuarioClinicaScreen> {
  final supabase = Supabase.instance.client;
  final WebhookService _webhookService = WebhookService();
  final TextEditingController _messageController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _chatHistory = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _webhookService.getUserProfile();
    setState(() {
      _userProfile = profile;
    });

    // Cargar historial de chat si tenemos el teléfono
    if (profile != null && profile['telefono'] != null) {
      await _loadChatHistory();
    }
  }

  Future<void> _loadChatHistory() async {
    if (_userProfile?['telefono'] != null) {
      final history = await _webhookService.getChatHistory(
        _userProfile!['telefono'],
      );
      setState(() {
        _chatHistory = history;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final result = await _webhookService.sendMessage(
        message: _messageController.text,
        email: _userProfile?['email'] ?? '',
        telefono: _userProfile?['telefono'] ?? '',
      );

      setState(() {
        _response = result['success']
            ? 'Mensaje enviado exitosamente!\nRespuesta: ${result['response']}'
            : 'Error: ${result['error'] ?? result['response']}';
        _isLoading = false;
      });

      if (result['success']) {
        _messageController.clear();
        // Recargar historial después de enviar mensaje
        await _loadChatHistory();
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Fecha no disponible';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha no válida';
    }
  }

  Future<void> _signOut() async {
    await SoundHelper.playSelectSound();
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuario Clínica'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _signOut, icon: Icon(Icons.logout))],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 40),
                Icon(Icons.local_hospital, size: 100, color: Colors.white),
                SizedBox(height: 32),
                Text(
                  'Bienvenido Usuario Clínica',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Has iniciado sesión como Usuario de Clínica',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // Sección de Chat con n8n
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.chat, color: Colors.blue, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Chat con Asistente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Escribe tu mensaje',
                          hintText: 'Escribe aquí tu consulta...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.message),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _sendMessage,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.send),
                          label: Text(
                            _isLoading ? 'Enviando...' : 'Enviar Mensaje',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_response.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _response.contains('Error')
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _response.contains('Error')
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _response,
                            style: TextStyle(
                              color: _response.contains('Error')
                                  ? Colors.red[700]
                                  : Colors.green[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Sección de Historial de Mensajes
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.orange,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Historial de Mensajes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showHistory = !_showHistory;
                              });
                            },
                            icon: Icon(
                              _showHistory
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            label: Text(_showHistory ? 'Ocultar' : 'Ver'),
                          ),
                        ],
                      ),
                      if (_showHistory) ...[
                        SizedBox(height: 16),
                        if (_chatHistory.isEmpty)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'No hay mensajes en el historial',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            child: ListView.builder(
                              itemCount: _chatHistory.length,
                              itemBuilder: (context, index) {
                                final message = _chatHistory[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['message'] ?? '',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Enviado: ${_formatDate(message['created_at'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Funcionalidades disponibles
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Funcionalidades disponibles:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.schedule, color: Colors.green),
                        title: Text('Gestionar citas médicas'),
                      ),
                      ListTile(
                        leading: Icon(Icons.people, color: Colors.blue),
                        title: Text('Administrar pacientes'),
                      ),
                      ListTile(
                        leading: Icon(Icons.assignment, color: Colors.orange),
                        title: Text('Registros médicos'),
                      ),
                      ListTile(
                        leading: Icon(Icons.inventory, color: Colors.purple),
                        title: Text('Inventario de medicamentos'),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
          const MusicControlWidget(),
        ],
      ),
    );
  }
}
