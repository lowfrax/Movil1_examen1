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

class _DoctorCaseDetailState extends State<DoctorCaseDetail> with SingleTickerProviderStateMixin {
  final SupabaseDataService _data = SupabaseDataService();
  final TextEditingController _msg = TextEditingController();
  List<Map<String, dynamic>> _chat = [];
  List<Medicamento> _medicamentos = [];
  bool _loading = true;
  bool _loadingMedicamentos = false;
  late TabController _tabController;
  String? _nombreCaso;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msg.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final caso = await _data.getCasoById(widget.idCaso);
    _chat = await _data.getChatGeneralByCaso(widget.idCaso);
    await _loadMedicamentos();
    setState(() {
      _nombreCaso = caso?.nombreCaso;
      _loading = false;
    });
  }

  Future<void> _loadMedicamentos() async {
    setState(() => _loadingMedicamentos = true);
    _medicamentos = await _data.getMedicamentosByCaso(widget.idCaso);
    setState(() => _loadingMedicamentos = false);
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
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre *')),              
              TextField(controller: presc, decoration: const InputDecoration(labelText: 'Prescripción'), maxLines: 3),
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
              if (mounted) Navigator.pop(ctx);
              await _loadMedicamentos();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMedicamento(Medicamento medicamento) async {
    final TextEditingController nombre = TextEditingController(text: medicamento.nombreMedicamento);
    final TextEditingController presc = TextEditingController(text: medicamento.prescripcion ?? '');
    final TextEditingController urlWeb = TextEditingController(text: medicamento.urlWeb ?? '');
    final TextEditingController urlDrive = TextEditingController(text: medicamento.urlDrive ?? '');
    final TextEditingController urlImg = TextEditingController(text: medicamento.urlImage ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar medicamento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre *')),              
              TextField(controller: presc, decoration: const InputDecoration(labelText: 'Prescripción'), maxLines: 3),
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
              await _data.actualizarMedicamento(
                idMedicamento: medicamento.id,
                nombreMedicamento: nombre.text.trim(),
                prescripcion: presc.text.trim().isEmpty ? null : presc.text.trim(),
                urlWeb: urlWeb.text.trim().isEmpty ? null : urlWeb.text.trim(),
                urlDrive: urlDrive.text.trim().isEmpty ? null : urlDrive.text.trim(),
                urlImage: urlImg.text.trim().isEmpty ? null : urlImg.text.trim(),
              );
              if (mounted) Navigator.pop(ctx);
              await _loadMedicamentos();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedicamento(Medicamento medicamento) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text('¿Estás seguro de eliminar "${medicamento.nombreMedicamento}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _data.eliminarMedicamento(medicamento.id);
      await _loadMedicamentos();
    }
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _chat.isEmpty
                  ? const Center(child: Text('No hay mensajes aún.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _chat.length,
                      itemBuilder: (ctx, i) {
                        final m = _chat[i];
                        final type = (m['type'] ?? '').toString().toLowerCase();
                        Color color;
                        if (type == 'doctor') {
                          color = Colors.blue.shade100;
                        } else if (type == 'ia') {
                          color = Colors.green.shade100;
                        } else {
                          color = Colors.grey.shade200;
                        }
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
          ]),
        ),
      ],
    );
  }

  Widget _buildMedicamentosTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medicamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addMedicamento,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMedicamentos
              ? const Center(child: CircularProgressIndicator())
              : _medicamentos.isEmpty
                  ? const Center(child: Text('No hay medicamentos asignados.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _medicamentos.length,
                      itemBuilder: (ctx, i) {
                        final medic = _medicamentos[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        medic.nombreMedicamento,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _editMedicamento(medic),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteMedicamento(medic),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (medic.prescripcion != null && medic.prescripcion!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('Prescripción: ${medic.prescripcion}', style: TextStyle(color: Colors.grey[700])),
                                ],
                                if (medic.urlWeb != null && medic.urlWeb!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {},
                                    child: Text('Web: ${medic.urlWeb}', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                  ),
                                ],
                                if (medic.urlDrive != null && medic.urlDrive!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {},
                                    child: Text('Drive: ${medic.urlDrive}', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                  ),
                                ],
                                if (medic.urlImage != null && medic.urlImage!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {},
                                    child: Text('Imagen: ${medic.urlImage}', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                  ),
                                ],
                                if (medic.createdAt != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Creado: ${_formatDate(medic.createdAt!)}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nombreCaso ?? 'Caso #${widget.idCaso}'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.medication), text: 'Medicamentos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildMedicamentosTab(),
        ],
      ),
    );
  }
}


