import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/medicamento.dart';
import 'services/supabase_data_service.dart';
import 'services/webhook_service.dart';
import 'p3_theme.dart';

class UserCaseDetailScreen extends StatefulWidget {
  final int idCaso;
  const UserCaseDetailScreen({super.key, required this.idCaso});

  @override
  State<UserCaseDetailScreen> createState() => _UserCaseDetailScreenState();
}

class _UserCaseDetailScreenState extends State<UserCaseDetailScreen> {
  // final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseDataService _dataService = SupabaseDataService();
  final WebhookService _webhookService = WebhookService();

  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;
  String _response = '';

  List<Map<String, dynamic>> _chatGeneral = [];
  List<Medicamento> _medicamentos = [];
  bool _loading = true;

  File? _selectedFile;
  bool _uploading = false;
  String _fileResponse = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    _chatGeneral = await _dataService.getChatGeneralByCaso(widget.idCaso);
    _medicamentos = await _dataService.getMedicamentosByCaso(widget.idCaso);
    setState(() => _loading = false);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final profile = await _dataService.getCurrentPerfil();
    final telefono = (profile?.telefono ?? '').toString();
    final email = (profile?.email ?? '').toString();
    final text = _messageController.text.trim();
    try {
      await _webhookService.insertChatGeneralUser(message: text, idCaso: widget.idCaso);
      final result = await _webhookService.sendMessage(
        message: text,
        email: email,
        telefono: telefono,
        idCaso: widget.idCaso,
      );
      String iaText = '';
      if (result['success'] == true) {
        _messageController.clear();
        final iaResponseBody = result['response'];
        try {
          final decoded = json.decode(iaResponseBody);
          iaText = decoded['ia_response'] ?? decoded['response'] ?? '';
          if (iaText.isEmpty && decoded is Map) iaText = (decoded['message'] ?? '').toString();
        } catch (_) {
          iaText = iaResponseBody.toString();
        }
        if (iaText.trim().isNotEmpty) {
          await _webhookService.insertChatGeneralIA(message: iaText, idCaso: widget.idCaso);
        }
        setState(() => _response = 'Mensaje enviado');
      } else {
        setState(() => _response = 'Error: ${result['error'] ?? result['response']}');
      }
    } catch (e) {
      setState(() => _response = 'Error: $e');
    } finally {
      setState(() => _sending = false);
      await _loadAll();
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
      if (result != null) setState(() => _selectedFile = File(result.files.single.path!));
    } catch (e) {
      setState(() => _fileResponse = 'Error: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      setState(() => _fileResponse = 'Selecciona un archivo primero');
      return;
    }
    setState(() { _uploading = true; _fileResponse = ''; });
    final profile = await _dataService.getCurrentPerfil();
    try {
      final res = await _webhookService.uploadFile(
        file: _selectedFile!,
        email: (profile?.email ?? '').toString(),
        telefono: (profile?.telefono ?? '').toString(),
        idCaso: widget.idCaso,
      );
      setState(() {
        _fileResponse = res['success'] == true ? 'Archivo subido' : 'Error: ${res['error'] ?? res['response']}';
        _selectedFile = null;
      });
    } catch (e) {
      setState(() => _fileResponse = 'Error: $e');
    } finally {
      setState(() => _uploading = false);
      await _loadAll();
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _medicamentoCard(Medicamento m) {
    final type = (m.type).toLowerCase();
    final color = type == 'doctor' ? Colors.blue : Colors.green;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  if (m.urlImage != null && m.urlImage!.isNotEmpty)
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(m.urlImage!, height: 80, width: 80, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(m.nombreMedicamento, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 12),
                _badge(type.toUpperCase(), color),
                const SizedBox(height: 12),
                if (m.prescripcion != null && m.prescripcion!.isNotEmpty) Text('Prescripción:\n${m.prescripcion!}'),
                if (m.urlWeb != null && m.urlWeb!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Web: ${m.urlWeb!}')),
                if (m.urlDrive != null && m.urlDrive!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Drive: ${m.urlDrive!}')),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6))]),
        child: Row(children: [
          if (m.urlImage != null && m.urlImage!.isNotEmpty)
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(m.urlImage!, height: 64, width: 64, fit: BoxFit.cover)),
          if (m.urlImage != null && m.urlImage!.isNotEmpty) const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            Text(m.nombreMedicamento, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _badge(type.toUpperCase(), color),
            const SizedBox(height: 12),
          ])),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Caso #${widget.idCaso}'), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
      body: Stack(children: [
        Container(decoration: p3BackgroundGradient()),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Chat con asistente
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: p3PanelDecoration(context),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Chat con Asistente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(controller: _messageController, minLines: 1, maxLines: 3, decoration: const InputDecoration(prefixIcon: Icon(Icons.message), hintText: 'Escribe tu mensaje ...')),
                      const SizedBox(height: 12),
                      Row(children: [
                        ElevatedButton.icon(onPressed: _sending ? null : _sendMessage, icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send), label: Text(_sending ? 'Enviando...' : 'Enviar')),
                        const SizedBox(width: 12),
                        if (_response.isNotEmpty) Expanded(child: Text(_response)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Subir archivos
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: p3PanelDecoration(context),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Subir Archivos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(children: [
                        OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file), label: const Text('Seleccionar')),
                        const SizedBox(width: 12),
                        ElevatedButton(onPressed: _uploading ? null : _uploadFile, child: Text(_uploading ? 'Subiendo...' : 'Subir')),
                      ]),
                      if (_selectedFile != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_selectedFile!.path.split('/').last)),
                      if (_fileResponse.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_fileResponse)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Historial/Chat general
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: p3PanelDecoration(context),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Historial y Chat General', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_chatGeneral.isEmpty)
                        const Text('No hay mensajes')
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _chatGeneral.length,
                          itemBuilder: (ctx, i) {
                            final m = _chatGeneral[i];
                            final type = (m['type'] ?? '').toString().toLowerCase();
                            Color c = Colors.grey.shade200;
                            if (type == 'ia') c = Colors.green.shade100; else if (type == 'doctor') c = Colors.blue.shade100; else if (type == 'user') c = Colors.purple.shade100;
                            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)), child: Text((m['message'] ?? '').toString()));
                          },
                        ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Medicamentos
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: p3PanelDecoration(context),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Medicamentos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (_medicamentos.isEmpty)
                        const Text('No hay medicamentos asignados')
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _medicamentos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _medicamentoCard(_medicamentos[i]),
                        ),
                    ]),
                  ),
                ]),
              ),
      ]),
    );
  }
}


