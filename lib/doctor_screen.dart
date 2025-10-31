import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medinova/p3_theme.dart';
// import 'widgets/p3_pattern.dart';
import 'models/caso.dart';
import 'services/supabase_data_service.dart';
import 'doctor_case_detail.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final supabase = Supabase.instance.client;
  final SupabaseDataService _data = SupabaseDataService();
  List<Caso> _casos = [];
  List<Caso> _allCasos = [];
  String _estado = 'pendiente';
  bool _loading = true;
  int? _doctorId;

  Future<void> _signOut() async {
    await SoundHelper.playSelectSound();
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final perfil = await _data.getCurrentPerfil();
    _doctorId = perfil?.id;
    if (_doctorId != null) {
      final rows = await Supabase.instance.client
          .from('casos')
          .select('*')
          .eq('id_doctor', _doctorId!)
          .neq('deleted', 1);
      _allCasos = (rows as List).map((e) => Caso.fromMap(Map<String, dynamic>.from(e))).toList();
      _applyFilter(_allCasos);
    }
    setState(() => _loading = false);
  }

  void _applyFilter(List<Caso> all) {
    final filtered = all.where((c) => c.estadoCaso.toLowerCase() == _estado).toList();
    filtered.sort((a, b) => (a.createdAt ?? DateTime(1970)).compareTo(b.createdAt ?? DateTime(1970)));
    setState(() => _casos = filtered);
  }

  int get _countTotal => _allCasos.length;
  int get _countPendientes => _allCasos.where((c) => c.estadoCaso.toLowerCase() == 'pendiente').length;
  int get _countAnalizando => _allCasos.where((c) => c.estadoCaso.toLowerCase() == 'analizando').length;
  int get _countFinalizados => _allCasos.where((c) => c.estadoCaso.toLowerCase() == 'finalizado').length;

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

  Future<void> _updateEstado(Caso caso) async {
    final estados = ['pendiente', 'analizando', 'finalizado'];
    String sel = caso.estadoCaso;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualizar estado'),
        content: DropdownButtonFormField<String>(
          value: sel,
          items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
          onChanged: (v) => sel = v ?? sel,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _data.actualizarEstadoCaso(idCaso: caso.id, estado: sel);
              Navigator.pop(ctx);
              await _load();
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Casos del Doctor'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _signOut, icon: const Icon(Icons.logout))],
      ),
      body: Stack(children: [
        Container(decoration: p3BackgroundGradient()),
        Column(children: [
          const SizedBox(height: 12),
          // Resumen de Casos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              const SizedBox(width: 12),
              _resumeTile(title: 'Casos\nTotales', count: _countTotal, color: Colors.green),
              const SizedBox(width: 8),
              _resumeTile(title: 'Pendientes', count: _countPendientes, color: Colors.orange),
              const SizedBox(width: 8),
              _resumeTile(title: 'En Proceso', count: _countAnalizando, color: Colors.blue),
              const SizedBox(width: 8),
              _resumeTile(title: 'Finalizados', count: _countFinalizados, color: Colors.green),
              const SizedBox(width: 12),
            ]),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Pendientes'), selected: _estado == 'pendiente', onSelected: (s) { setState(() => _estado = 'pendiente'); _applyFilter(_allCasos); }),
            ChoiceChip(label: const Text('Analizando'), selected: _estado == 'analizando', onSelected: (s) { setState(() => _estado = 'analizando'); _applyFilter(_allCasos); }),
            ChoiceChip(label: const Text('Finalizados'), selected: _estado == 'finalizado', onSelected: (s) { setState(() => _estado = 'finalizado'); _applyFilter(_allCasos); }),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _casos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final c = _casos[i];
                      return GestureDetector(
                        onLongPress: () => _updateEstado(c),
                        onTap: () {
                          if (_doctorId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DoctorCaseDetail(idCaso: c.id, idDoctor: _doctorId!),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _statusFill(c.estadoCaso),
                            border: Border.all(color: _statusBorder(c.estadoCaso).withOpacity(0.35)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusBorder(c.estadoCaso).withOpacity(0.1),
                                border: Border.all(color: _statusBorder(c.estadoCaso)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(c.estadoCaso.toUpperCase(), style: TextStyle(color: _statusBorder(c.estadoCaso), fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.nombreCaso, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('#${c.id}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                            ])),
                            const Icon(Icons.chevron_right),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
        const MusicControlWidget(),
      ]),
    );
  }
}
