import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/notes/index.dart';

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
      context.read<CategoriesProvider>().loadFromBackend();
      context.read<NotesProvider>().loadNotes();
    });
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
                    Expanded(
                      child: notesProvider.isLoading
                          ? const _LoadingState()
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
          onPressed: () => showNewNoteSheet(context),
          backgroundColor: _kPrimary,
          tooltip: 'Nueva nota',
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.username});
  final String username;
  static const _kBg = Color(0xFF1A1F4D);
  static const _kPrimary = Color(0xFFFF5856);
  @override
  Widget build(BuildContext context) {
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
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Tus notas organizadas',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13)),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
                tooltip: 'Notificaciones',
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBg, width: 1.5),
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                    order.map((g) => _options.firstWhere((o) => o.$1 == g).$3).join(' -> '),
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
                          : '${folder.children.length} carpetas - ${folder.totalNotes} notas',
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
    return Container(
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
            Text(_formatTime(note.createdAt),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10.5)),
          ],
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
          const Text('Sin notas aqui todavia',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Pulsa el microfono para crear la primera',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
        ],
      ),
    );
  }
}
