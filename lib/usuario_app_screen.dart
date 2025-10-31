import 'package:flutter/material.dart';
import 'package:medinova/sound_helper.dart';
import 'package:medinova/music_control_widget.dart';
// import 'package:medinova/services/webhook_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medinova/p3_theme.dart';
// import 'package:medinova/widgets/p3_pattern.dart';
// import 'dart:io';
import 'models/caso.dart';
import 'models/perfil.dart';
// import 'models/medicamento.dart';
import 'services/supabase_data_service.dart';
import 'user_case_detail_screen.dart';

class UsuarioAppScreen extends StatefulWidget {
  const UsuarioAppScreen({super.key});

  @override
  State<UsuarioAppScreen> createState() => _UsuarioAppScreenState();
}

class _UsuarioAppScreenState extends State<UsuarioAppScreen> {
  final supabase = Supabase.instance.client;
  // final WebhookService _webhookService = WebhookService();
  final SupabaseDataService _dataService = SupabaseDataService();
  // Campos eliminados de interacción directa (chat/archivos)

  // Variables para subida de archivos
  // Eliminado: selección de archivos en pantalla principal

  // Eliminado: chat general en pantalla principal

  // Casos y selección
  List<Caso> _casos = [];
  int? _selectedCasoId;
  String _searchCaso = '';
  bool _isLoadingCasos = false;
  Map<int, String> _doctoresNombres = {}; // Mapa para almacenar ID -> Nombre

  int get _countTotal => _casos.length;
  int get _countPendientes =>
      _casos.where((c) => c.estadoCaso.toLowerCase() == 'pendiente').length;
  int get _countAnalizando =>
      _casos.where((c) => c.estadoCaso.toLowerCase() == 'analizando').length;
  int get _countFinalizados =>
      _casos.where((c) => c.estadoCaso.toLowerCase() == 'finalizado').length;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    await _loadCasos();
  }

  // Eliminado: historial en pantalla de detalle

  // Eliminado: chat general en pantalla principal

  Future<void> _loadCasos() async {
    setState(() => _isLoadingCasos = true);
    final perfil = await _dataService.getCurrentPerfil();
    if (perfil == null) return;
    final casos = await _dataService.listarCasosPorUsuario(
      perfil.id,
      filtroNombre: _searchCaso,
    );
    // Cargar nombres de doctores
    final Set<int> doctoresIds = casos.map((c) => c.idDoctor).toSet();
    final Map<int, String> nombresMap = {};
    for (final doctorId in doctoresIds) {
      final doctorPerfil = await _dataService.getPerfilById(doctorId);
      if (doctorPerfil != null) {
        nombresMap[doctorId] = doctorPerfil.nombre;
      }
    }
    setState(() {
      _casos = casos;
      _doctoresNombres = nombresMap;
      if (_selectedCasoId != null &&
          !_casos.any((c) => c.id == _selectedCasoId)) {
        _selectedCasoId = null;
      }
      _isLoadingCasos = false;
    });
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

  Color _statusFill(String estado) {
    final base = _statusBorder(estado);
    return base.withOpacity(0.12);
  }

  Widget _resumeTile({
    required String title,
    required int count,
    required Color color,
  }) {
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
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _editarCaso(Caso caso) async {
    final TextEditingController ctrl = TextEditingController(
      text: caso.nombreCaso,
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nombre del caso'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nombre del caso'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await _dataService.actualizarCaso(
                idCaso: caso.id,
                nombre: ctrl.text.trim(),
              );
              Navigator.pop(ctx);
              await _loadCasos();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reasignarDoctor(Caso caso) async {
    final doctores = await _dataService.getDoctores();
    int? doctorId = caso.idDoctor;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reasignar doctor'),
        content: DropdownButtonFormField<int>(
          value: doctorId,
          items: doctores
              .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)))
              .toList(),
          onChanged: (v) => doctorId = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (doctorId == null) return;
              await _dataService.actualizarCaso(
                idCaso: caso.id,
                idDoctor: doctorId,
              );
              Navigator.pop(ctx);
              await _loadCasos();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCaso(Caso caso) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar caso'),
        content: const Text('¿Deseas eliminar este caso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _dataService.eliminarLogicoCaso(caso.id);
      await _loadCasos();
    }
  }

  Widget _buildCasoCard(Caso caso) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserCaseDetailScreen(idCaso: caso.id),
          ),
        );
      },
      onLongPress: () async {
        await showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Editar nombre'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editarCaso(caso);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_search),
                  title: const Text('Reasignar doctor'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _reasignarDoctor(caso);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Eliminar'),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(ctx);
                    _eliminarCaso(caso);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _statusFill(caso.estadoCaso),
          border: Border.all(
            color: _statusBorder(caso.estadoCaso).withOpacity(0.35),
          ),
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
                style: TextStyle(
                  color: _statusBorder(caso.estadoCaso),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caso.nombreCaso,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID #${caso.id} • Doctor: ${_doctoresNombres[caso.idDoctor] ?? 'ID ${caso.idDoctor}'}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_selectedCasoId == caso.id)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  // Eliminado: envío de mensajes en pantalla principal

  // Eliminado: selección de archivos en pantalla principal

  // Eliminado: subida de archivos en pantalla principal

  // Eliminado: formateo de fecha solo usado en histórico

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
                    .map(
                      (d) => DropdownMenuItem<Perfil>(
                        value: d,
                        child: Text(d.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (v) => selectedDoctor = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty || selectedDoctor == null)
                  return;
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
                      Center(
                        child: Text(
                          'Resumen de Casos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _resumeTile(
                              title: 'Casos\nTotales',
                              count: _countTotal,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _resumeTile(
                              title: 'Pendientes',
                              count: _countPendientes,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            _resumeTile(
                              title: 'En Proceso',
                              count: _countAnalizando,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _resumeTile(
                              title: 'Finalizados',
                              count: _countFinalizados,
                              color: Colors.green,
                            ),
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
                                  .map(
                                    (c) => DropdownMenuItem<int>(
                                      value: c.id,
                                      child: Text(c.nombreCaso),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) async {
                                setState(() => _selectedCasoId = v);
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
                      const SizedBox(height: 12),
                      if (_isLoadingCasos)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        )
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
                            child: const Text(
                              'No hay casos. Crea tu primer caso.',
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 0),

                SizedBox(height: 0),

                SizedBox(height: 0),

                SizedBox(height: 32),
                // Historial Chat General (eliminado visual, ahora en detalle)
                SizedBox(height: 0),

                SizedBox(height: 24),

                SizedBox(height: 24),
              ],
            ),
          ),
          const MusicControlWidget(),
        ],
      ),
    );
  }
}
