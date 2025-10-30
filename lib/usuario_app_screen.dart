import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:medinova/services/webhook_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medinova/p3_theme.dart';
import 'package:medinova/widgets/p3_pattern.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'models/caso.dart';
import 'models/perfil.dart';
// import 'models/medicamento.dart';
import 'services/supabase_data_service.dart';

class UsuarioAppScreen extends StatefulWidget {
  const UsuarioAppScreen({super.key});

  @override
  State<UsuarioAppScreen> createState() => _UsuarioAppScreenState();
}

class _UsuarioAppScreenState extends State<UsuarioAppScreen> {
  final supabase = Supabase.instance.client;
  final WebhookService _webhookService = WebhookService();
  final SupabaseDataService _dataService = SupabaseDataService();
  final TextEditingController _messageController = TextEditingController();
  String _response = '';
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _chatHistory = [];
  bool _showHistory = false;

  // Variables para subida de archivos
  File? _selectedFile;
  bool _isUploadingFile = false;
  String _fileResponse = '';

  List<Map<String, dynamic>> _chatGeneral = [];
  bool _showChatGeneral = false;

  // Casos y selección
  List<Caso> _casos = [];
  int? _selectedCasoId;
  String _searchCaso = '';

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

    if (profile != null) {
      await _loadCasos();
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

  Future<void> _loadChatGeneral() async {
    if (_selectedCasoId != null) {
      final general = await _dataService.getChatGeneralByCaso(_selectedCasoId!);
      setState(() {
        _chatGeneral = general;
      });
    } else {
      setState(() {
        _chatGeneral = [];
      });
    }
  }

  Future<void> _loadCasos() async {
    final perfil = await _dataService.getCurrentPerfil();
    if (perfil == null) return;
    final casos = await _dataService.listarCasosPorUsuario(perfil.id, filtroNombre: _searchCaso);
    setState(() {
      _casos = casos;
      if (_selectedCasoId != null && !_casos.any((c) => c.id == _selectedCasoId)) {
        _selectedCasoId = null;
      }
    });
    await _loadChatGeneral();
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
      // Guardar mensaje enviado (user) en chat_general por id_caso
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
        // Guardar respuesta IA si existe
        final iaResponseBody = result['response']; // Puede ser JSON o texto
        // Si es JSON parsea y saca texto de la IA (ajustar según webhook!)
        String iaText = '';
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

        // Recargar historiales
        await _loadChatGeneral();
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
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

  Future<void> _crearCasoDialog() async {
    final perfil = await _dataService.getCurrentPerfil();
    if (perfil == null) return;
    final doctores = await _dataService.getDoctores();
    final TextEditingController nombreCtrl = TextEditingController();
    Perfil? selectedDoctor;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Nuevo caso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(labelText: 'Nombre del caso'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Perfil>(
                decoration: const InputDecoration(labelText: 'Doctor'),
                items: doctores
                    .map((d) => DropdownMenuItem<Perfil>(
                          value: d,
                          child: Text(d.nombre),
                        ))
                    .toList(),
                onChanged: (v) => selectedDoctor = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty || selectedDoctor == null) return;
                final nuevo = await _dataService.crearCaso(
                  idUsuario: perfil.id,
                  idDoctor: selectedDoctor!.id,
                  nombre: nombreCtrl.text.trim(),
                );
                setState(() {
                  _selectedCasoId = nuevo.id;
                });
                Navigator.of(ctx).pop();
                await _loadCasos();
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuario App'),
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
                Icon(Icons.person, size: 100, color: Colors.white),
                SizedBox(height: 32),
                Text(
                  'Bienvenido Usuario App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Has iniciado sesión como Usuario de la Aplicación',
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
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _crearCasoDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo Caso'),
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

                // Sección de Subida de Archivos
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

                SizedBox(height: 24),

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
                // Historial Chat General
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
                              Icons.medical_services,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text('Consultar citas médicas'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text('Ver perfil personal'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.history,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text('Historial médico'),
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
