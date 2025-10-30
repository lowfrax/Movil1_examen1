import 'package:flutter/material.dart';
import 'services/supabase_data_service.dart';
// import 'services/webhook_service.dart';
import 'models/medicamento.dart';

class DoctorCaseDetail extends StatefulWidget {
  final int idCaso;
  final int idDoctor;
  const DoctorCaseDetail({super.key, required this.idCaso, required this.idDoctor});

  @override
  State<DoctorCaseDetail> createState() => _DoctorCaseDetailState();
}

class _DoctorCaseDetailState extends State<DoctorCaseDetail> {
  final SupabaseDataService _data = SupabaseDataService();
  final TextEditingController _msg = TextEditingController();
  List<Map<String, dynamic>> _chat = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _chat = await _data.getChatGeneralByCaso(widget.idCaso);
    setState(() => _loading = false);
  }

  Future<void> _send() async {
    if (_msg.text.trim().isEmpty) return;
    final text = _msg.text.trim();
    _msg.clear();
    await _data.insertChat(idCaso: widget.idCaso, message: text, type: 'doctor');
    // opcionalmente notificar por webhook si aplica
    await _load();
  }

  Future<void> _addMedicamento() async {
    final TextEditingController nombre = TextEditingController();
    final TextEditingController presc = TextEditingController();
    final TextEditingController urlWeb = TextEditingController();
    final TextEditingController urlDrive = TextEditingController();
    final TextEditingController urlImg = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo medicamento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),              
              TextField(controller: presc, decoration: const InputDecoration(labelText: 'Prescripción')),
              TextField(controller: urlWeb, decoration: const InputDecoration(labelText: 'URL web')),
              TextField(controller: urlDrive, decoration: const InputDecoration(labelText: 'URL drive')),
              TextField(controller: urlImg, decoration: const InputDecoration(labelText: 'URL imagen')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombre.text.trim().isEmpty) return;
              await _data.crearMedicamento(
                // type doctor, id_doctor actual
                // el modelo permite nulos, pero aquí completamos
                // ignore: prefer_const_constructors
                Medicamento(
                  id: 0,
                  nombreMedicamento: nombre.text.trim(),
                  idCaso: widget.idCaso,
                  prescripcion: presc.text.trim().isEmpty ? null : presc.text.trim(),
                  urlWeb: urlWeb.text.trim().isEmpty ? null : urlWeb.text.trim(),
                  urlDrive: urlDrive.text.trim().isEmpty ? null : urlDrive.text.trim(),
                  type: 'doctor',
                  idDoctor: widget.idDoctor,
                  urlImage: urlImg.text.trim().isEmpty ? null : urlImg.text.trim(),
                  createdAt: null,
                ),
              );
              // //
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Caso #${widget.idCaso}')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _chat.length,
                    itemBuilder: (ctx, i) {
                      final m = _chat[i];
                      final type = (m['type'] ?? '').toString().toLowerCase();
                      Color color;
                      if (type == 'doctor') color = Colors.blue.shade100; else if (type == 'ia') color = Colors.green.shade100; else color = Colors.grey.shade200;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                        child: Text((m['message'] ?? '').toString()),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: TextField(controller: _msg, decoration: const InputDecoration(hintText: 'Escribe un mensaje'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _send, child: const Text('Enviar')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _addMedicamento, child: const Text('Medicamento')),
            ]),
          ),
        ],
      ),
    );
  }
}


