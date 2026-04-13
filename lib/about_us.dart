import 'package:flutter/material.dart';

const _kOrange = Color(0xFFFF8200);
const _kDark = Color(0xFF161616);
const _kGrey = Color(0xFF2A2A2A);
const _kTextMuted = Color(0xFF888888);

const _heroImage =
    'https://vibeadria.com/wp-content/uploads/2025/08/Vibe-Adria-Wallpaper.png';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const imageHeight = 300.0;
    const overlap = 28.0;

    return Scaffold(
      backgroundColor: _kDark,
      body: Stack(
        children: [
          // ── Fixed hero image ──────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: imageHeight,
            child: Image.network(
              _heroImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: imageHeight,
                color: _kGrey,
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: _kTextMuted, size: 48),
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: imageHeight - overlap),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: _kDark,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PageTitle('O nama'),
                      const SizedBox(height: 16),

                      // ── Intro card ──────────────────────────────
                      _contentCard([
                        _richInline([
                          _Tp('Vibe Adria', bold: true, color: Colors.white),
                          _Tp(
                            ' je regionalni lifestyle online magazin koji donosi svjež pogled na muziku, putovanja, kulturu, stil, urbane fenomene i inspirativne ljude sa stavom. Pokrenut s idejom da postane platforma dobrih priča i autentičnih perspektiva, Vibe Adria svakodnevno traži, otkriva i dijeli sadržaj koji ima karakter.',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        const _Body(
                          'Naš pristup je jednostavan: iskreno, drugačije i s jasnim identitetom. U fokusu su priče koje pokreću, lokacije koje mame, zvukovi koji definišu generacije, ali i ljudi – jer vjerujemo da upravo oni stvaraju vibe svakog mjesta, trenutka i pokreta.',
                        ),
                        const SizedBox(height: 16),
                        const _Body(
                          'Kao medij, želimo da budemo relevantan, moderan i slobodan prostor koji povezuje publiku iz cijelog regiona. Pratimo šta se dešava, ali biramo kako to ispričamo – s dozom stava, estetike i urbanog senzibiliteta.',
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // ── B Creative Group card ───────────────────
                      _contentCard([
                        _richInline([
                          _Tp('Portal Vibe Adria je u vlasništvu kompanije '),
                          _Tp('B Creative Group d.o.o.',
                              bold: true, color: _kOrange),
                          _Tp(
                            ', specijalizovane za kreativne, medijske i digitalne komunikacije. Osnovani smo s ciljem da medij pretvorimo u iskustvo, a sadržaj u prostor gdje zajednica može da diše, razmišlja, osjeća i dijeli.',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        const _Body(
                          'Ako i ti osjećaš taj vibe – dobrodošao/la si da nam se javiš, predložiš temu ili budeš dio naše priče.',
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // ── Contact card ────────────────────────────
                      _contactCard([
                        _mailRow('Redakcija', 'redakcija@vibeadria.com'),
                        const SizedBox(height: 10),
                        _mailRow('Marketing & saradnje',
                            'marketing@vibeadria.com'),
                      ]),

                      const SizedBox(height: 20),

                      // ── Meta row ────────────────────────────────
                      _infoRow(Icons.verified_rounded, 'Verzija', '1.0.0'),
                      const SizedBox(height: 8),
                      _infoRow(Icons.copyright_rounded, 'Sva prava zadržana',
                          '© 2025 Vibe Adria'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating app bar ──────────────────────────────────────
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: _kOrange, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Vibe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _contentCard(List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget _contactCard(List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _kOrange.withValues(alpha: 0.16),
          _kOrange.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _kOrange.withValues(alpha: 0.28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.mail_outline_rounded, color: _kOrange, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Kontakt',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

Widget _mailRow(String label, String email) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              color: _kTextMuted, fontSize: 11, letterSpacing: 0.8)),
      const SizedBox(height: 3),
      Text(email,
          style: const TextStyle(
              color: _kOrange, fontSize: 14, fontWeight: FontWeight.w600)),
    ],
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: _kGrey,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: Row(
      children: [
        Icon(icon, color: _kOrange, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: _kTextMuted, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Tp {
  final String text;
  final bool bold;
  final Color? color;
  const _Tp(this.text, {this.bold = false, this.color});
}

Widget _richInline(List<_Tp> parts) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(
          color: Color(0xFFCCCCCC), fontSize: 15, height: 1.65),
      children: parts
          .map((p) => TextSpan(
                text: p.text,
                style: TextStyle(
                  color: p.color ?? const Color(0xFFCCCCCC),
                  fontWeight: p.bold ? FontWeight.w700 : FontWeight.normal,
                ),
              ))
          .toList(),
    ),
  );
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _PageTitle extends StatelessWidget {
  final String title;
  const _PageTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 15,
        height: 1.65,
      ),
    );
  }
}
