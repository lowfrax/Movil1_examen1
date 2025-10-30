import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medinova/p3_theme.dart';
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
      final list = (rows as List).map((e) => Caso.fromMap(Map<String, dynamic>.from(e))).toList();
      _applyFilter(list);
    }
    setState(() => _loading = false);
  }

  void _applyFilter(List<Caso> all) {
    final filtered = all.where((c) => c.estadoCaso.toLowerCase() == _estado).toList();
    filtered.sort((a, b) => (a.createdAt ?? DateTime(1970)).compareTo(b.createdAt ?? DateTime(1970)));
    setState(() => _casos = filtered);
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
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Pendientes'), selected: _estado == 'pendiente', onSelected: (s) { setState(() => _estado = 'pendiente'); _load(); }),
            ChoiceChip(label: const Text('Analizando'), selected: _estado == 'analizando', onSelected: (s) { setState(() => _estado = 'analizando'); _load(); }),
            ChoiceChip(label: const Text('Finalizados'), selected: _estado == 'finalizado', onSelected: (s) { setState(() => _estado = 'finalizado'); _load(); }),
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
                        child: ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(c.nombreCaso),
                          subtitle: Text('#${c.id} • ${c.estadoCaso}'),
                          trailing: const Icon(Icons.chevron_right),
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
