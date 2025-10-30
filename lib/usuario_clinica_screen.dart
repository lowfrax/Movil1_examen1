import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:medinova/services/webhook_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:medinova/p3_theme.dart';
import 'package:medinova/widgets/p3_pattern.dart';
import 'dart:convert';
import 'models/caso.dart';
// import 'models/perfil.dart';
// import 'models/medicamento.dart';
import 'services/supabase_data_service.dart';

class UsuarioClinicaScreen extends StatefulWidget {
  const UsuarioClinicaScreen({super.key});

  @override
  State<UsuarioClinicaScreen> createState() => _UsuarioClinicaScreenState();
}

class _UsuarioClinicaScreenState extends State<UsuarioClinicaScreen> {
  final supabase = Supabase.instance.client;
  final WebhookService _webhookService = WebhookService();
  final SupabaseDataService _dataService = SupabaseDataService();
  final TextEditingController _messageController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _chatHistory = [];
  bool _showHistory = false;
  File? _selectedFile;
  bool _isUploadingFile = false;
  String _fileResponse = '';
  List<Map<String, dynamic>> _chatGeneral = [];
  bool _showChatGeneral = false;
  List<Caso> _casos = [];
  int? _selectedCasoId;
  String _searchCaso = '';
  bool _isLoadingCasos = false;
  int get _countTotal => _casos.length;
  int get _countPendientes => _casos.where((c) => c.estadoCaso.toLowerCase() == 'pendiente').length;
  int get _countAnalizando => _casos.where((c) => c.estadoCaso.toLowerCase() == 'analizando').length;
  int get _countFinalizados => _casos.where((c) => c.estadoCaso.toLowerCase() == 'finalizado').length;

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
    await _loadCasos();
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

  Future<void> _loadChatGeneral() async {
    if (_selectedCasoId != null) {
      final general = await _dataService.getChatGeneralByCaso(_selectedCasoId!);
      setState(() {
        _chatGeneral = general;
      });
    } else {
      setState(() => _chatGeneral = []);
    }
  }

  Future<void> _loadCasos() async {
    setState(() => _isLoadingCasos = true);
    final perfil = await _dataService.getCurrentPerfil();
    if (perfil == null) return;
    final casos = await _dataService.listarCasosPorUsuario(perfil.id, filtroNombre: _searchCaso);
    setState(() {
      _casos = casos;
      if (_selectedCasoId != null && !_casos.any((c) => c.id == _selectedCasoId)) {
        _selectedCasoId = null;
      }
      _isLoadingCasos = false;
    });
    await _loadChatGeneral();
  }

  Color _statusBorder(String estado) {
    switch (estado.toLowerCase()) {
      case 'finalizado':
        return Colors.green.shade400;
      case 'analizando':
        return Colors.blue.shade400;
      case 'pendiente':
      default:
        return Colors.orange.shade400;
    }
  }

  Color _statusFill(String estado) => _statusBorder(estado).withOpacity(0.12);

  Widget _resumeTile({required String title, required int count, required Color color}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: color))
        ],
      ),
    );
  }

  Widget _buildCasoCard(Caso caso) {
    return GestureDetector(
      onTap: () async {
        setState(() => _selectedCasoId = caso.id);
        await _loadChatGeneral();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _statusFill(caso.estadoCaso),
          border: Border.all(color: _statusBorder(caso.estadoCaso).withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusBorder(caso.estadoCaso).withOpacity(0.1),
                border: Border.all(color: _statusBorder(caso.estadoCaso)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                caso.estadoCaso.toUpperCase(),
                style: TextStyle(color: _statusBorder(caso.estadoCaso), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(caso.nombreCaso, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('ID #${caso.id} • Doctor: ${caso.idDoctor}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ]),
            ),
            if (_selectedCasoId == caso.id) Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_selectedCasoId == null) {
      setState(() {
        _response = 'Seleccione o cree un caso para continuar.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _response = '';
    });
    final userMessage = _messageController.text;
    final telefono = _userProfile?['telefono'] ?? '';
    try {
      await _webhookService.insertChatGeneralUser(
        message: userMessage,
        idCaso: _selectedCasoId!,
      );
      final result = await _webhookService.sendMessage(
        message: userMessage,
        email: _userProfile?['email'] ?? '',
        telefono: telefono,
        idCaso: _selectedCasoId,
      );
      setState(() {
        _response = result['success']
            ? 'Mensaje enviado exitosamente!\nRespuesta: ${result['response']}'
            : 'Error: ${result['error'] ?? result['response']}';
        _isLoading = false;
      });
      if (result['success']) {
        _messageController.clear();
        String iaText = '';
        final iaResponseBody = result['response'];
        try {
          final decoded = json.decode(iaResponseBody);
          iaText = decoded['ia_response'] ?? decoded['response'] ?? '';
          if (iaText.isEmpty && decoded is Map) iaText = (decoded['message'] ?? '').toString();
        } catch (_) {
          iaText = iaResponseBody.toString();
        }
        if (iaText.trim().isNotEmpty) {
          await _webhookService.insertChatGeneralIA(
            message: iaText,
            idCaso: _selectedCasoId!,
          );
        }
        await _loadChatGeneral();
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

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileResponse = '';
        });
      }
    } catch (e) {
      setState(() {
        _fileResponse = 'Error al seleccionar archivo: $e';
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      setState(() {
        _fileResponse = 'Por favor selecciona un archivo primero';
      });
      return;
    }
    if (_selectedCasoId == null) {
      setState(() {
        _fileResponse = 'Seleccione o cree un caso antes de subir archivos';
      });
      return;
    }

    setState(() {
      _isUploadingFile = true;
      _fileResponse = '';
    });

    try {
      final result = await _webhookService.uploadFile(
        file: _selectedFile!,
        email: _userProfile?['email'] ?? '',
        telefono: _userProfile?['telefono'] ?? '',
        idCaso: _selectedCasoId,
      );

      setState(() {
        _fileResponse = result['success']
            ? 'Archivo subido exitosamente!\nRespuesta: ${result['response']}'
            : 'Error: ${result['error'] ?? result['response']}';
        _isUploadingFile = false;
      });

      if (result['success']) {
        setState(() {
          _selectedFile = null;
        });
      }
    } catch (e) {
      setState(() {
        _fileResponse = 'Error: $e';
        _isUploadingFile = false;
      });
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
          Container(decoration: p3BackgroundGradient()),
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

              // Sección de Casos: selector + nuevo + buscador
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: p3PanelDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('Resumen de Casos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _resumeTile(title: 'Casos\nTotales', count: _countTotal, color: Colors.green),
                          const SizedBox(width: 8),
                          _resumeTile(title: 'Pendientes', count: _countPendientes, color: Colors.orange),
                          const SizedBox(width: 8),
                          _resumeTile(title: 'En Proceso', count: _countAnalizando, color: Colors.blue),
                          const SizedBox(width: 8),
                          _resumeTile(title: 'Finalizados', count: _countFinalizados, color: Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedCasoId,
                            hint: const Text('Seleccionar caso'),
                            items: _casos
                                .map((c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.nombreCaso),
                                    ))
                                .toList(),
                            onChanged: (v) async {
                              setState(() => _selectedCasoId = v);
                              await _loadChatGeneral();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar caso...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) async {
                        _searchCaso = v;
                        await _loadCasos();
                      },
                    ),
                      const SizedBox(height: 12),
                      if (_isLoadingCasos)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      else ...[
                        for (final c in _casos) ...[
                          const SizedBox(height: 8),
                          _buildCasoCard(c),
                        ],
                        if (_casos.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('No hay casos disponibles.'),
                          ),
                      ],
                  ],
                ),
              ),

                // Sección de Chat con n8n
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: p3PanelDecoration(context),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: P3DiagonalPattern(
                          spacing: 20,
                          strokeWidth: 1.2,
                          opacity: 0.05,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.chat,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 24,
                              ),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(Icons.send),
                              label: Text(
                                _isLoading ? 'Enviando...' : 'Enviar Mensaje',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
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
                                    ? Colors.red.withOpacity(0.08)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.tertiary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _response.contains('Error')
                                      ? Colors.red.withOpacity(0.25)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.tertiary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _response,
                                style: TextStyle(
                                  color: _response.contains('Error')
                                      ? Colors.red[700]
                                      : Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Sección de Subida de Archivos (sincronizada)
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: p3PanelDecoration(context),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: P3DiagonalPattern(
                          spacing: 20,
                          strokeWidth: 1.2,
                          opacity: 0.05,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Subir Archivos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Selecciona un archivo PDF o Word para enviar:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _selectFile,
                                  icon: Icon(Icons.folder_open),
                                  label: Text('Seleccionar Archivo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSecondary,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isUploadingFile
                                      ? null
                                      : _uploadFile,
                                  icon: _isUploadingFile
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Icon(Icons.upload),
                                  label: Text(
                                    _isUploadingFile ? 'Subiendo...' : 'Subir',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedFile != null) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.tertiary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.tertiary.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedFile!.path.split('/').last,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFile = null;
                                        _fileResponse = '';
                                      });
                                    },
                                    icon: Icon(Icons.close, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_fileResponse.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _fileResponse.contains('Error')
                                    ? Colors.red.withOpacity(0.08)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.tertiary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _fileResponse.contains('Error')
                                      ? Colors.red.withOpacity(0.25)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.tertiary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _fileResponse,
                                style: TextStyle(
                                  color: _fileResponse.contains('Error')
                                      ? Colors.red[700]
                                      : Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Sección de Historial de Mensajes
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: p3PanelDecoration(context),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: P3DiagonalPattern(
                          spacing: 20,
                          strokeWidth: 1.2,
                          opacity: 0.05,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Historial de Mensajes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Actualizar',
                                    onPressed: _loadChatHistory,
                                    icon: Icon(Icons.refresh),
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
                                    label: Text(
                                      _showHistory ? 'Ocultar' : 'Ver',
                                    ),
                                  ),
                                ],
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
                                    final String type = (message['type'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    final bool isAi = type == 'ai';
                                    final bg = isAi
                                        ? Theme.of(context).colorScheme.primary
                                              .withOpacity(0.12)
                                        : Theme.of(context).colorScheme.tertiary
                                              .withOpacity(0.12);
                                    final border = isAi
                                        ? Theme.of(context).colorScheme.primary
                                              .withOpacity(0.35)
                                        : Theme.of(context).colorScheme.tertiary
                                              .withOpacity(0.35);
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAi ? 'IA' : 'Tú',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            message['message'] ?? '',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          if ((message['created_at'] ?? '')
                                              .toString()
                                              .isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              'Enviado: ${_formatDate(message['created_at'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: p3PanelDecoration(context),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: P3DiagonalPattern(
                          spacing: 20,
                          strokeWidth: 1.2,
                          opacity: 0.05,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.forum,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Chat general',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Actualizar',
                                    onPressed: _loadChatGeneral,
                                    icon: Icon(Icons.refresh),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _showChatGeneral = !_showChatGeneral;
                                      });
                                    },
                                    icon: Icon(
                                      _showChatGeneral
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                    ),
                                    label: Text(
                                      _showChatGeneral ? 'Ocultar' : 'Ver',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_showChatGeneral) ...[
                            SizedBox(height: 16),
                            if (_chatGeneral.isEmpty)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'No hay mensajes en el chat general',
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
                                  itemCount: _chatGeneral.length,
                                  itemBuilder: (context, idx) {
                                    final m = _chatGeneral[idx];
                                    final isAI =
                                        (m['type']?.toString().toLowerCase() ==
                                        'ia');
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isAI
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.12)
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                                  .withOpacity(0.12),
                                        border: Border.all(
                                          color: isAI
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.35)
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                    .withOpacity(0.35),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAI ? 'IA' : 'Tú',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            (m['message'] ?? '').toString(),
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          if ((m['created_at'] ?? '')
                                              .toString()
                                              .isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              'Fecha: ' +
                                                  (m['created_at'] ?? ''),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Funcionalidades disponibles
                Container(
                  padding: EdgeInsets.all(24),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: p3PanelDecoration(context),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: P3DiagonalPattern(
                          spacing: 20,
                          strokeWidth: 1.2,
                          opacity: 0.05,
                        ),
                      ),
                      Column(
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
                            leading: Icon(
                              Icons.schedule,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text('Gestionar citas médicas'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.people,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text('Administrar pacientes'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.assignment,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text('Registros médicos'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.inventory,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            title: Text('Inventario de medicamentos'),
                          ),
                        ],
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
