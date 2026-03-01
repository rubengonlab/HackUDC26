import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/index.dart';
import '../../widgets/notes/index.dart';
import 'note_detail_screen.dart';
import 'pending_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _kBg = Color(0xFF1A1F4D);
  static const _kPrimary = Color(0xFFFF5856);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesProvider = context.read<NotesProvider>();
      context.read<CategoriesProvider>().loadFromBackend();
      notesProvider.loadNotes();
      notesProvider.loadFilterMetadata();

      // Configurar el handler para shares recibidos mientras la app está abierta
      ShareHandlerService.onSharedUrl = (url) {
        if (mounted) showSharedUrlSheet(context, url, onSaved: _onNoteSaved);
      };
      ShareHandlerService.onSharedImage = (file) {
        if (mounted) showSharedImageSheet(context, file, onSaved: _onNoteSaved);
      };
      ShareHandlerService.init();

      ShareHandlerService.getInitialSharedUrl().then((url) {
        if (url != null && mounted) showSharedUrlSheet(context, url, onSaved: _onNoteSaved);
      });
      ShareHandlerService.getInitialSharedImage().then((file) {
        if (file != null && mounted) showSharedImageSheet(context, file, onSaved: _onNoteSaved);
      });
    });
  }

  void _onNoteSaved(bool approved) {
    // Refrescar badge (con delay si no está aprobado, para esperar procesamiento IA)
    context.read<NotesProvider>().refreshPendingCount(withDelay: !approved);

    final snackBar = approved
        ? SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Guardado y clasificado',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF56C288),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            duration: const Duration(seconds: 3),
          )
        : SnackBar(
            content: const Row(children: [
              Icon(Icons.schedule_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Añadido · pendiente de revisar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF252B5C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            duration: const Duration(seconds: 3),
          );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Consumer2<AuthProvider, NotesProvider>(
        builder: (context, auth, notesProvider, _) {
          return Consumer<CategoriesProvider>(
            builder: (context, categoriesProvider, _) {
              final categories = categoriesProvider.getAllCategories();
              final folders = notesProvider.buildFolderTree(categories);
              final username = auth.currentUser?.username ?? '';
              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AppHeader(username: username),
                    _GroupingSelector(provider: notesProvider),
                    _ActiveFiltersBar(
                      provider: notesProvider,
                      categories: categories,
                    ),
                    Expanded(
                      child: notesProvider.isLoading
                          ? const _LoadingState()
                          : notesProvider.error != null
                              ? _ErrorState(
                                  message: notesProvider.error!,
                                  onRetry: () {
                                    notesProvider.loadNotes();
                                    notesProvider.loadFilterMetadata();
                                  },
                                )
                              : folders.isEmpty
                                  ? const _EmptyState()
                                  : _FolderGrid(folders: folders, depth: 0),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton(
          heroTag: 'new_note_fab',
          onPressed: () => showNewNoteSheet(context, onSaved: _onNoteSaved),
          backgroundColor: _kPrimary,
          tooltip: 'Nueva nota',
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de filtros activos con chips rápidos
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({required this.provider, required this.categories});
  final NotesProvider provider;
  final List<Category> categories;

  static const _kPrimary = Color(0xFFFF5856);

  static const _typeLabels = {
    'NOTE': '📝 Texto',
    'LINK': '🔗 Enlace',
    'AUDIO': '🎙️ Audio',
    'IMAGE': '🖼️ Imagen',
    'DOCUMENT': '📄 Doc',
  };

  static const _typeIcons = {
    'NOTE': Icons.sticky_note_2_outlined,
    'LINK': Icons.link_rounded,
    'AUDIO': Icons.mic_rounded,
    'IMAGE': Icons.image_outlined,
    'DOCUMENT': Icons.description_outlined,
  };

  String _dateLabel(String d) {
    try {
      final parts = d.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = today.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
      if (diff == 0) return 'Hoy';
      if (diff == 1) return 'Ayer';
      const m = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${dt.day} ${m[dt.month]}';
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = provider.hasActiveFilters;
    final types = provider.availableTypes;
    final days = provider.availableDays;

    // Si no hay metadatos ni filtros activos, no mostrar nada
    if (!hasFilters && types.isEmpty && days.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        children: [
          // Chip "Limpiar" si hay filtros activos
          if (hasFilters)
            _FilterChip(
              label: 'Limpiar filtros',
              icon: Icons.close_rounded,
              isActive: true,
              color: _kPrimary,
              onTap: provider.clearFilters,
            ),

          // Chips de tipo de archivo disponibles
          ...types.map((t) {
            final isActive = provider.activeFileType == t;
            return _FilterChip(
              label: _typeLabels[t] ?? t,
              icon: _typeIcons[t] ?? Icons.help_outline,
              isActive: isActive,
              color: const Color(0xFF4C9FE0),
              onTap: () => provider.setFileTypeFilter(isActive ? null : t),
            );
          }),

          // Chips de días disponibles
          ...days.take(10).map((d) {
            final isActive = provider.activeDate == d;
            return _FilterChip(
              label: _dateLabel(d),
              icon: Icons.calendar_today_rounded,
              isActive: isActive,
              color: const Color(0xFF56C288),
              onTap: () => provider.setDateFilter(isActive ? null : d),
            );
          }),

          // Chips de categorías (si hay backend categories)
          ...categories.take(6).map((cat) {
            final catIdInt = int.tryParse(cat.id);
            final isActive = catIdInt != null && provider.activeCategoryId == catIdInt;
            return _FilterChip(
              label: cat.name,
              icon: Icons.folder_outlined,
              isActive: isActive,
              color: _parseColor(cat.color),
              onTap: () => provider.setCategoryFilter(isActive ? null : catIdInt),
            );
          }),
        ],
      ),
    );
  }

  Color _parseColor(String c) {
    final hex = c.replaceAll('#', '');
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    return _kPrimary;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.85) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado de error con botón de reintentar
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  static const _kPrimary = Color(0xFFFF5856);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: _kPrimary),
            ),
            const SizedBox(height: 16),
            const Text('No se pudieron cargar las notas',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: campana reactiva vía NotesProvider.pendingCount
// ─────────────────────────────────────────────────────────────────────────────
class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.username});
  final String username;

  static const _kBg      = Color(0xFF1A1F4D);
  static const _kPrimary = Color(0xFFFF5856);

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.select<NotesProvider, int>((p) => p.pendingCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, $username',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Tus notas organizadas',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  final provider = context.read<NotesProvider>();
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const PendingScreen()))
                      .then((_) => provider.refreshPendingCount());
                },
                icon: Icon(
                  pendingCount > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                tooltip: 'Pendientes de aprobar',
              ),
              if (pendingCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                        color: _kPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBg, width: 1.5)),
                    child: Center(
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            icon: Icon(Icons.logout_rounded,
                color: Colors.white.withValues(alpha: 0.5), size: 22),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
    );
  }
}

class _GroupingSelector extends StatelessWidget {
  const _GroupingSelector({required this.provider});
  final NotesProvider provider;
  static const _kSurface = Color(0xFF252B5C);
  static const _kPrimary = Color(0xFFFF5856);
  static const _options = [
    (GroupBy.category, Icons.folder_outlined, 'Categoria'),
    (GroupBy.type, Icons.perm_media_outlined, 'Tipo'),
    (GroupBy.date, Icons.calendar_today_outlined, 'Fecha'),
  ];
  @override
  Widget build(BuildContext context) {
    final order = provider.groupingOrder;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text('Agrupar por',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
                const Spacer(),
                if (order.length > 1)
                  Text(
                    order.map((g) => _options.firstWhere((o) => o.$1 == g).$3).join(' → '),
                    style: TextStyle(
                        color: _kPrimary.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Row(
            children: _options.map((opt) {
              final groupBy = opt.$1;
              final icon = opt.$2;
              final label = opt.$3;
              final isActive = order.contains(groupBy);
              final position = order.indexOf(groupBy) + 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.toggleGrouping(groupBy),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isActive ? _kPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                size: 18,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(height: 4),
                            Text(label,
                                style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                          ],
                        ),
                        if (isActive && order.length > 1)
                          Positioned(
                            top: 0,
                            right: 8,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Center(
                                child: Text('$position',
                                    style: TextStyle(
                                        color: _kPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 3),
        ],
      ),
    );
  }
}

class _FolderGrid extends StatelessWidget {
  const _FolderGrid({required this.folders, required this.depth});
  final List<FolderNode> folders;
  final int depth;
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: folders.length,
      itemBuilder: (context, i) =>
          _FolderCard(folder: folders[i], depth: depth),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder, required this.depth});
  final FolderNode folder;
  final int depth;
  static const _kSurface = Color(0xFF252B5C);
  static const _kPrimary = Color(0xFFFF5856);
  Color get _accent => folder.color ?? _kPrimary;
  IconData get _icon {
    switch (folder.groupBy) {
      case GroupBy.category: return Icons.folder_rounded;
      case GroupBy.type: return Icons.perm_media_rounded;
      case GroupBy.date: return Icons.calendar_month_rounded;
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FolderDetailScreen(folder: folder, depth: depth),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: _accent.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon, color: _accent, size: 24),
              ),
              const Spacer(),
              Text(folder.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.3)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                      folder.isLeaf
                          ? Icons.sticky_note_2_outlined
                          : Icons.folder_open_outlined,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      folder.isLeaf
                          ? '${folder.totalNotes} ${folder.totalNotes == 1 ? 'nota' : 'notas'}'
                          : '${folder.children.length} carpetas · ${folder.totalNotes} notas',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _FolderDetailScreen extends StatelessWidget {
  const _FolderDetailScreen({required this.folder, required this.depth});
  final FolderNode folder;
  final int depth;
  static const _kBg = Color(0xFF1A1F4D);
  static const _kPrimary = Color(0xFFFF5856);
  Color get _accent => folder.color ?? _kPrimary;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(folder.label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      body: folder.isLeaf
          ? _NotesList(notes: folder.notes, accentColor: _accent)
          : _FolderGrid(folders: folder.children, depth: depth + 1),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({required this.notes, required this.accentColor});
  final List<Note> notes;
  final Color accentColor;
  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const _EmptyState();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) =>
          _NoteCard(note: notes[i], accentColor: accentColor),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.accentColor});
  final Note note;
  final Color accentColor;
  static const _kSurface = Color(0xFF252B5C);
  String _formatDuration(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  String _formatTime(DateTime d) {
    const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${months[d.month]}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NoteDetailScreen(note: note),
      )),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11)),
                child: Center(
                  child: Text(Note.typeEmoji(note.type),
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    if (note.type == NoteType.audio && note.durationSeconds != null)
                      Row(children: [
                        Icon(Icons.graphic_eq_rounded,
                            size: 13,
                            color: accentColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(_formatDuration(note.durationSeconds!),
                            style: TextStyle(
                                color: accentColor.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ])
                    else if (note.preview != null && note.preview!.isNotEmpty)
                      Text(note.preview!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatTime(note.createdAt),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10.5)),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: Colors.white.withValues(alpha: 0.2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  static const _kPrimary = Color(0xFFFF5856);
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: _kPrimary));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  static const _kPrimary = Color(0xFFFF5856);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.folder_off_outlined,
                size: 36, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          const Text('Sin notas aquí todavía',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Pulsa + para crear la primera nota',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
        ],
      ),
    );
  }
}
