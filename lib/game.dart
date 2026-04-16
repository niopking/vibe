import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'artikal.dart';
import 'models.dart';

const String _puzzleImageUrl =
    'https://vibeadria.com/wp-content/uploads/2026/04/Jelen-pivo-207-godina-Apatinske-pivare.png';
const int _cols = 5;
const int _rows = 4;
const int _pieceCount = _cols * _rows;
const ImageProvider _puzzleProvider = NetworkImage(_puzzleImageUrl);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<int> _positions;
  int _moves = 0;
  bool _solved = false;
  ui.Image? _image;
  double _imgAspect = _cols / _rows;

  Set<int> _dragPieces = const {};
  Offset _dragOffset = Offset.zero;
  double _currentTileW = 0;
  double _currentTileH = 0;

  @override
  void initState() {
    super.initState();
    _positions = List.generate(_pieceCount, (i) => i);
    _shuffle(initial: true);
    _loadImage();
  }

  void _loadImage() {
    final stream = _puzzleProvider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() {
          _image = info.image;
          _imgAspect = info.image.width / info.image.height;
        });
        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (!mounted) return;
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  void _shuffle({bool initial = false}) {
    final list = List.generate(_pieceCount, (i) => i);
    final rng = Random();
    do {
      list.shuffle(rng);
    } while (_isSolved(list) || _hasAnyGlue(list));
    if (initial) {
      _positions = list;
      return;
    }
    setState(() {
      _positions = list;
      _dragPieces = const {};
      _dragOffset = Offset.zero;
      _moves = 0;
      _solved = false;
    });
  }

  bool _isSolved(List<int> p) {
    for (int i = 0; i < p.length; i++) {
      if (p[i] != i) return false;
    }
    return true;
  }

  bool _hasAnyGlue(List<int> p) {
    for (int s = 0; s < _pieceCount; s++) {
      if ((s + 1) % _cols != 0) {
        final a = p[s];
        final b = p[s + 1];
        if (b == a + 1 && (a % _cols) != _cols - 1) return true;
      }
      if (s + _cols < _pieceCount) {
        final a = p[s];
        final b = p[s + _cols];
        if (b == a + _cols) return true;
      }
    }
    return false;
  }

  bool _isGluedRight(int slot) {
    if ((slot + 1) % _cols == 0) return false;
    final a = _positions[slot];
    final b = _positions[slot + 1];
    return b == a + 1 && (a % _cols) != _cols - 1;
  }

  bool _isGluedBottom(int slot) {
    if (slot + _cols >= _pieceCount) return false;
    final a = _positions[slot];
    final b = _positions[slot + _cols];
    return b == a + _cols;
  }

  int _countGlues() {
    int n = 0;
    for (int i = 0; i < _pieceCount; i++) {
      if (_isGluedRight(i)) n++;
      if (_isGluedBottom(i)) n++;
    }
    return n;
  }

  Set<int> _groupOfSlot(int slot) {
    final visited = <int>{slot};
    final stack = <int>[slot];
    while (stack.isNotEmpty) {
      final s = stack.removeLast();
      final r = s ~/ _cols;
      final c = s % _cols;
      if (c > 0 && _isGluedRight(s - 1) && visited.add(s - 1)) stack.add(s - 1);
      if (c < _cols - 1 && _isGluedRight(s) && visited.add(s + 1)) stack.add(s + 1);
      if (r > 0 && _isGluedBottom(s - _cols) && visited.add(s - _cols)) stack.add(s - _cols);
      if (r < _rows - 1 && _isGluedBottom(s) && visited.add(s + _cols)) stack.add(s + _cols);
    }
    return visited;
  }

  int _slotOfPiece(int piece) => _positions.indexOf(piece);

  void _onPanStart(DragStartDetails d) {
    if (_solved || _image == null) return;
    if (_currentTileW <= 0 || _currentTileH <= 0) return;
    final c = (d.localPosition.dx / _currentTileW).floor().clamp(0, _cols - 1);
    final r = (d.localPosition.dy / _currentTileH).floor().clamp(0, _rows - 1);
    final slot = r * _cols + c;
    final group = _groupOfSlot(slot);
    setState(() {
      _dragPieces = group.map((s) => _positions[s]).toSet();
      _dragOffset = Offset.zero;
    });
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragPieces.isEmpty) return;
    setState(() {
      _dragOffset += d.delta;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_dragPieces.isEmpty) {
      _resetDrag();
      return;
    }
    final sourceSlots = <int>{for (final p in _dragPieces) _slotOfPiece(p)};

    int minR = _rows, maxR = -1, minC = _cols, maxC = -1;
    for (final s in sourceSlots) {
      final r = s ~/ _cols;
      final c = s % _cols;
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
    }
    int dc = (_dragOffset.dx / _currentTileW).round();
    int dr = (_dragOffset.dy / _currentTileH).round();
    dr = dr.clamp(-minR, _rows - 1 - maxR);
    dc = dc.clamp(-minC, _cols - 1 - maxC);

    if (dc == 0 && dr == 0) {
      _resetDrag();
      return;
    }

    final targetSlots = <int>{
      for (final s in sourceSlots)
        (s ~/ _cols + dr) * _cols + (s % _cols + dc),
    };

    final gluesBefore = _countGlues();
    setState(() {
      final pieceAt = <int, int>{for (final s in sourceSlots) s: _positions[s]};
      final displacedPieces = <int>[];
      for (final t in targetSlots) {
        if (!sourceSlots.contains(t)) displacedPieces.add(_positions[t]);
      }
      final freedSlots = <int>[];
      for (final s in sourceSlots) {
        if (!targetSlots.contains(s)) freedSlots.add(s);
      }
      displacedPieces.sort();
      freedSlots.sort();
      for (final s in sourceSlots) {
        final newSlot = (s ~/ _cols + dr) * _cols + (s % _cols + dc);
        _positions[newSlot] = pieceAt[s]!;
      }
      for (int i = 0; i < freedSlots.length; i++) {
        _positions[freedSlots[i]] = displacedPieces[i];
      }
      _moves++;
      _dragPieces = const {};
      _dragOffset = Offset.zero;
      if (_isSolved(_positions)) {
        _solved = true;
        HapticFeedback.mediumImpact();
      }
    });
    if (!_solved && _countGlues() > gluesBefore) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPanCancel() => _resetDrag();

  void _resetDrag() {
    if (_dragPieces.isEmpty && _dragOffset == Offset.zero) return;
    setState(() {
      _dragPieces = const {};
      _dragOffset = Offset.zero;
    });
  }

  Future<void> _unlockArticle() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kOrange),
      ),
    );
    try {
      final articles = await fetchArticles();
      Article? match;
      for (final a in articles) {
        final url = a.imageUrl.toLowerCase();
        final title = a.title.toLowerCase();
        if (url.contains('jelen-pivo-207') ||
            url.contains('apatinsk') ||
            title.contains('jelen') ||
            title.contains('apatinsk')) {
          match = a;
          break;
        }
      }
      match ??= articles.isNotEmpty ? articles.first : null;
      if (!mounted) return;
      Navigator.pop(context);
      if (match != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArtikalScreen(article: match!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trenutno nema artikala.')),
        );
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  'Slagalica',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _PillButton(
                  icon: Icons.refresh_rounded,
                  label: 'Nova igra',
                  onTap: _shuffle,
                ),
              ],
            ),
          ),
          Container(height: 0.6, color: context.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Icon(
                  _solved ? Icons.lock_open_rounded : Icons.pan_tool_alt_rounded,
                  color: _solved ? kOrange : context.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _solved
                        ? 'Bravo! Slika je složena.'
                        : 'Povuci komade — spojeni se kreću zajedno.',
                    style: TextStyle(
                      color: _solved ? kOrange : context.textMuted,
                      fontSize: 13,
                      fontWeight:
                          _solved ? FontWeight.w600 : FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
                Text(
                  'Potezi: $_moves',
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final aspect = _imgAspect;
                  final maxW = constraints.maxWidth;
                  final maxH = constraints.maxHeight - 80;
                  double w = maxW;
                  double h = w / aspect;
                  if (h > maxH) {
                    h = maxH;
                    w = h * aspect;
                  }
                  final tileW = w / _cols;
                  final tileH = h / _rows;
                  _currentTileW = tileW;
                  _currentTileH = tileH;

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: w,
                          height: h,
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: context.border, width: 0.6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _image == null
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: kOrange, strokeWidth: 2.5),
                                )
                              : GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanStart: _onPanStart,
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  onPanCancel: _onPanCancel,
                                  child: Stack(
                                    children: [
                                      for (int piece = 0;
                                          piece < _pieceCount;
                                          piece++)
                                        if (!_dragPieces.contains(piece))
                                          _buildPiece(piece, tileW, tileH),
                                      for (int piece = 0;
                                          piece < _pieceCount;
                                          piece++)
                                        if (_dragPieces.contains(piece))
                                          _buildPiece(piece, tileW, tileH),
                                      if (_solved)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    kOrange.withValues(alpha: 0),
                                                    kOrange.withValues(
                                                        alpha: 0.18),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: _solved
                              ? ElevatedButton.icon(
                                  key: const ValueKey('unlock'),
                                  onPressed: _unlockArticle,
                                  icon: const Icon(Icons.lock_open_rounded),
                                  label: const Text('Otključaj artikal'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 28, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 0),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiece(int piece, double tileW, double tileH) {
    final slot = _slotOfPiece(piece);
    final r = slot ~/ _cols;
    final c = slot % _cols;
    final isDragged = _dragPieces.contains(piece);

    final glueL = c > 0 && _isGluedRight(slot - 1);
    final glueR = c < _cols - 1 && _isGluedRight(slot);
    final glueT = r > 0 && _isGluedBottom(slot - _cols);
    final glueB = r < _rows - 1 && _isGluedBottom(slot);
    final isGlued = glueL || glueR || glueT || glueB;

    Color edgeColor;
    double edgeWidth;
    if (isDragged) {
      edgeColor = kOrange;
      edgeWidth = 2.5;
    } else if (_solved) {
      edgeColor = Colors.transparent;
      edgeWidth = 0;
    } else if (isGlued) {
      edgeColor = kOrange.withValues(alpha: 0.95);
      edgeWidth = 1.6;
    } else {
      edgeColor = Colors.black.withValues(alpha: 0.20);
      edgeWidth = 0.5;
    }

    BorderSide side(bool glued) => glued && !isDragged
        ? BorderSide.none
        : BorderSide(color: edgeColor, width: edgeWidth);

    final left = c * tileW + (isDragged ? _dragOffset.dx : 0);
    final top = r * tileH + (isDragged ? _dragOffset.dy : 0);

    return AnimatedPositioned(
      key: ValueKey('piece_$piece'),
      duration: isDragged
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: tileW,
      height: tileH,
      child: IgnorePointer(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isDragged ? 1.05 : 1.0,
          curve: Curves.easeOut,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PuzzlePiecePainter(
                    image: _image!,
                    piece: piece,
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    border: Border(
                      top: side(glueT),
                      bottom: side(glueB),
                      left: side(glueL),
                      right: side(glueR),
                    ),
                    color: isDragged
                        ? kOrange.withValues(alpha: 0.22)
                        : (isGlued && !_solved
                            ? kOrange.withValues(alpha: 0.14)
                            : Colors.transparent),
                    boxShadow: isDragged
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PuzzlePiecePainter extends CustomPainter {
  final ui.Image image;
  final int piece;
  _PuzzlePiecePainter({required this.image, required this.piece});

  @override
  void paint(Canvas canvas, Size size) {
    final r = piece ~/ _cols;
    final c = piece % _cols;
    final srcW = image.width / _cols;
    final srcH = image.height / _rows;
    final src = Rect.fromLTWH(c * srcW, r * srcH, srcW, srcH);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _PuzzlePiecePainter old) =>
      old.image != image || old.piece != piece;
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.textPrimary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
