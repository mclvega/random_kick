
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database.dart';
import 'dart:math';

Widget buildBackground({required Widget child}) {
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/background.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      color: Colors.black.withOpacity(0.45),
      child: child,
    ),
  );
}

Widget miniGoalGrid(String direction) {
  const cells = [
    ['Arriba izquierda', 'Arriba centro', 'Arriba derecha'],
    ['Medio izquierda',  'Centro',        'Medio derecha'],
    ['Abajo izquierda',  'Abajo centro',  'Abajo derecha'],
  ];
  return SizedBox(
    width: 36,
    height: 24,
    child: Column(
      children: List.generate(3, (row) {
        return Expanded(
          child: Row(
            children: List.generate(3, (col) {
              final isSelected = cells[row][col] == direction;
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.yellowAccent.withOpacity(0.9)
                        : Colors.white.withOpacity(0.15),
                    border: Border.all(color: Colors.white38, width: 0.3),
                  ),
                  child: isSelected
                      ? const Center(child: Icon(Icons.sports_soccer, color: Colors.black, size: 7))
                      : null,
                ),
              );
            }),
          ),
        );
      }),
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Kick',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const LaunchScreen(),
    );
  }
}

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  String? _direction;
  String? _shotType;
  List<Penalty> _lastPenalties = [];

  final List<String> directions = [
    'Arriba izquierda',
    'Arriba centro',
    'Arriba derecha',
    'Medio izquierda',
    'Centro',
    'Medio derecha',
    'Abajo izquierda',
    'Abajo centro',
    'Abajo derecha',
  ];

  final List<String> shotTypes = [
    'Fuerte',
    'Colocado',
    'Globito',
  ];

  @override
  void initState() {
    super.initState();
    _loadLastPenalties();
  }

  Future<void> _loadLastPenalties() async {
    final all = await DatabaseHelper().getPenalties();
    setState(() {
      _lastPenalties = all.reversed.take(5).toList();
    });
  }

  Widget _resultBall(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveResult(String result) async {
    await DatabaseHelper().insertPenalty(
      Penalty(
        date: DateTime.now(),
        direction: _direction!,
        shotType: _shotType!,
        result: result,
      ),
    );
    setState(() {
      _direction = null;
      _shotType = null;
    });
    await _loadLastPenalties();
  }

  Widget _buildGoalGrid(String direction, String shotType) {
    const double gridWidth = 350;
    const double gridHeight = 200;
    const cells = [
      ['Arriba izquierda', 'Arriba centro', 'Arriba derecha'],
      ['Medio izquierda',  'Centro',        'Medio derecha'],
      ['Abajo izquierda',  'Abajo centro',  'Abajo derecha'],
    ];
    return SizedBox(
      width: gridWidth,
      height: gridHeight,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: List.generate(3, (row) {
            return Expanded(
              child: Row(
                children: List.generate(3, (col) {
                  final cell = cells[row][col];
                  final isSelected = cell == direction;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.yellowAccent.withOpacity(0.85)
                            : Colors.white.withOpacity(0.08),
                        border: Border.all(color: Colors.white30, width: 0.5),
                      ),
                      child: isSelected
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sports_soccer, color: Colors.black, size: 24),
                                  const SizedBox(height: 2),
                                  Text(
                                    shotType,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _launch() {
    final random = Random();
    final dir = directions[random.nextInt(directions.length)];

    final isAbajo = dir.startsWith('Abajo');
    final isCentro = dir == 'Centro';

    final available = shotTypes.where((s) {
      if (s == 'Globito' && isAbajo) return false;
      if (s == 'Colocado' && isCentro) return false;
      return true;
    }).toList();

    setState(() {
      _direction = dir;
      _shotType = available[random.nextInt(available.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBackground(
        child: Stack(
          children: [
            // Título arriba
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'RANDOM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 10,
                            shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                          ),
                        ),
                        Text(
                          'KICK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            height: 0.9,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(2, 3)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Contenido central (siempre centrado)
            Align(
              alignment: const Alignment(0, -0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_direction == null)
                    const Text('Presiona Patear para lanzar un penal',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  if (_direction != null) ...[
                    _buildGoalGrid(_direction!, _shotType!),
                    const SizedBox(height: 24),
                    const Text('¿Cuál fue el resultado?',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _resultBall('Gol', Colors.green, () => _saveResult('gol')),
                          _resultBall('Atajado', Colors.red, () => _saveResult('atajado')),
                          _resultBall('Palo', Colors.orange, () => _saveResult('palo')),
                          _resultBall('Fuera', Colors.grey, () => _saveResult('fuera')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() { _direction = null; _shotType = null; }),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ),
                  ],
                  if (_direction == null) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _launch,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Colors.white, Color(0xFFCCCCCC)],
                            center: Alignment(-0.3, -0.3),
                            radius: 0.9,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(4, 6)),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sports_soccer, color: Colors.black87, size: 36),
                              SizedBox(height: 4),
                              Text(
                                'PATEAR',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Lista de últimos penales anclada abajo
            if (_lastPenalties.isNotEmpty)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(color: Colors.white24, indent: 24, endIndent: 24),
                    const Text('Últimos penales',
                        style: TextStyle(color: Colors.white, fontSize: 24)),
                    const SizedBox(height: 6),
                    ..._lastPenalties.map((p) {
                      final fecha = '${p.date.year}/${p.date.month}/${p.date.day} ${p.date.hour.toString().padLeft(2, '0')}:${p.date.minute.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              p.result == 'gol' ? Icons.sports_soccer : Icons.sports_soccer,
                              color: p.result == 'gol' ? Colors.greenAccent : Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            miniGoalGrid(p.direction),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.shotType,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              p.result,
                              style: TextStyle(
                                color: p.result == 'gol' ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fecha,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        ).then((_) => _loadLastPenalties());
                      },
                      icon: const Icon(Icons.history, color: Colors.white),
                      label: const Text('Historial completo', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Penalty>> _penalties;

  @override
  void initState() {
    super.initState();
    _penalties = DatabaseHelper().getPenalties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBackground(
        child: FutureBuilder<List<Penalty>>(
          future: _penalties,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final penalties = (snapshot.data ?? []).reversed.toList();
            return Column(
              children: [
                SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BackButton(color: Colors.white),
                      if (penalties.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Limpiar lista'),
                                content: const Text('¿Eliminar todos los penales registrados?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await DatabaseHelper().deleteAll();
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          label: const Text('Limpiar lista', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                ),
                if (penalties.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No hay penales registrados.',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                if (penalties.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: penalties.length,
                      itemBuilder: (context, index) {
                        final p = penalties[index];
                        final fecha = '${p.date.day}/${p.date.month}/${p.date.year} ${p.date.hour.toString().padLeft(2, '0')}:${p.date.minute.toString().padLeft(2, '0')}';
                        return Card(
                          color: Colors.black54,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: InkWell(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar penal'),
                                  content: const Text('¿Eliminar este registro?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                                  ],
                                ),
                              );
                              if (confirm == true && p.id != null) {
                                await DatabaseHelper().deletePenalty(p.id!);
                                setState(() {
                                  _penalties = DatabaseHelper().getPenalties();
                                });
                              }
                            },
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sports_soccer,
                                    color: p.result == 'gol' ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  miniGoalGrid(p.direction),
                                ],
                              ),
                              title: Text('${p.shotType}  •  ${p.result}',
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(fecha,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String direction;
  final String shotType;

  const ResultScreen({super.key, required this.direction, required this.shotType});

  Future<void> _saveResult(BuildContext context, String result) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.insertPenalty(
      Penalty(
        date: DateTime.now(),
        direction: direction,
        shotType: shotType,
        result: result,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Dirección: $direction',
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Tipo de tiro: $shotType',
                  style: const TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 20),
              const Text('¿Cuál fue el resultado?',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _saveResult(context, 'gol'),
                    child: const Text('Gol'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _saveResult(context, 'atajado'),
                    child: const Text('Atajado'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _saveResult(context, 'palo'),
                    child: const Text('Palo'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _saveResult(context, 'fuera'),
                    child: const Text('Fuera'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
