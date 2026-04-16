import 'package:flutter/material.dart';
import 'app_theme.dart';

const _heroImage =
    'https://vibeadria.com/wp-content/uploads/2025/09/pexels-george-milton-7014337.jpg';

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const imageHeight = 280.0;
    const overlap = 28.0;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(
        children: [
          // ── Fixed hero image ──────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: imageHeight,
            child: Image.network(
              _heroImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: imageHeight,
                color: context.surfaceLight,
                child: Center(
                  child: Icon(Icons.image_outlined,
                      color: context.textMuted, size: 48),
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: imageHeight - overlap),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.bg,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageTitle('Marketing'),
                      const SizedBox(height: 16),

                      _contentCard(context, [
                        _richInline(context, [
                          const _Tp('Vibe Adria', bold: true),
                          const _Tp(
                            ' je regionalna digitalna platforma posvećena muzici, događajima, sportu, putovanjima, savremenom načinu života i ljudima koji kreiraju dobar vibe – kako u realnom, tako i u digitalnom svijetu. Naš sadržaj svakodnevno inspiriše hiljade čitalaca i pratilaca širom regiona, okupljajući zajednicu mladih, aktivnih i informisanih ljudi koji znaju šta žele – i šta vole da dijele.',
                          ),
                        ]),
                      ]),

                      const SizedBox(height: 24),
                      _SectionHeading('Zašto da se oglašavate na Vibe Adria?'),
                      const SizedBox(height: 10),
                      _contentCard(context, [
                        _Body('Zato što ne nudimo samo prostor – nudimo pažnju.'),
                        const SizedBox(height: 14),
                        _Body('Naš sadržaj je pažljivo kreiran, dizajniran da bude relevantan, svjež i vizuelno prepoznatljiv. Ako želite da se vaš brend, proizvod, destinacija ili događaj pojavi u tom kontekstu – na pravom ste mjestu.'),
                        const SizedBox(height: 14),
                        _Body('Kroz storytelling, autentične vizuale i ciljano pozicioniranje, vaš brend postaje dio Vibe univerzuma – bez šuma, klikbejta i prenaglašene reklame.'),
                      ]),

                      const SizedBox(height: 24),
                      _SectionHeading('Publika Vibe Adria magazina:'),
                      const SizedBox(height: 10),
                      _audienceCard(context,
                        Icons.people_rounded,
                        'Mladi i urbani ljudi iz cijelog regiona',
                        '18–45',
                      ),
                      const SizedBox(height: 8),
                      _audienceCard(context,
                        Icons.travel_explore_rounded,
                        'Ljubitelji putovanja, muzike, festivala i moderne pop kulture',
                        'Lifestyle',
                      ),
                      const SizedBox(height: 8),
                      _audienceCard(context,
                        Icons.trending_up_rounded,
                        'Pratioci trendova u digitalu, modi, gastronomiji i lifestyle-u',
                        'Trend',
                      ),
                      const SizedBox(height: 8),
                      _audienceCard(context,
                        Icons.star_outline_rounded,
                        'Kupci koji cijene autentične preporuke i inspirativne priče',
                        'Premium',
                      ),

                      const SizedBox(height: 24),
                      _SectionHeading('Oblasti oglašavanja i saradnje'),
                      const SizedBox(height: 10),
                      _contentCard(context, [
                        _Body('Naš marketing tim nudi fleksibilne mogućnosti promocije, uz kreativan i strateški pristup oglašavanju:'),
                        const SizedBox(height: 14),
                        _bulletList(context, [
                          'Brendirani sadržaji (native članci, preporuke, intervjui)',
                          'Banneri i display oglasi na ključnim pozicijama sajta',
                          'Video formati (intervjui, reportaže, kratke kampanje)',
                          'Reklamne kampanje na društvenim mrežama',
                          'Newsletter partnerstva',
                          'Festivalski specijali i branded editorijali',
                          'Putopisne rute i tematski vodiči sa vašim brendom u fokusu',
                        ]),
                      ]),

                      const SizedBox(height: 24),
                      _SectionHeading('Pridružite se Vibe partnerima'),
                      const SizedBox(height: 10),
                      _contentCard(context, [
                        _Body('Ako želite da vaš sadržaj bude predstavljen u kreativnom i relevantnom okruženju, a pri tom ostane vjeran tonu i vrijednostima vašeg brenda – kontaktirajte nas i osmislićemo zajedno sadržaj, koji će publika zaista željeti da vidi, pročita i podijeli.'),
                        const SizedBox(height: 16),
                        _Body('Vidimo se tamo gdje se dobar sadržaj sreće sa dobrom energijom.'),
                      ]),

                      const SizedBox(height: 20),
                      const _ContactCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating app bar ───────────────────────────────
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, color: kOrange, size: 16),
                        SizedBox(width: 4),
                        Text(
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

Widget _contentCard(BuildContext context, List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget _audienceCard(BuildContext context, IconData icon, String label, String tag) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kOrange.withValues(alpha: 0.2), width: 0.6),
            ),
            child: Icon(icon, color: kOrange, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kOrange.withValues(alpha: 0.3)),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                  color: kOrange, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _bulletList(BuildContext context, List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: kOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: context.textBody, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ))
        .toList(),
  );
}

class _Tp {
  final String text;
  final bool bold;
  const _Tp(this.text, {this.bold = false});
}

Widget _richInline(BuildContext context, List<_Tp> parts) {
  return RichText(
    text: TextSpan(
      style: TextStyle(color: context.textBody, fontSize: 15, height: 1.65),
      children: parts
          .map((p) => TextSpan(
                text: p.text,
                style: TextStyle(
                  color: p.bold ? context.textPrimary : null,
                  fontWeight: p.bold ? FontWeight.w700 : FontWeight.normal,
                ),
              ))
          .toList(),
    ),
  );
}

class _PageTitle extends StatelessWidget {
  final String title;
  const _PageTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: context.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
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
      style: TextStyle(
        color: context.textBody,
        fontSize: 15,
        height: 1.65,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kOrange.withValues(alpha: 0.18),
            kOrange.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: kOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Kontaktirajte nas',
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Za sve upite vezane za oglašavanje, sponzorstvo i saradnju:',
            style: TextStyle(color: context.textBody, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 14),
          _emailChip('marketing@vibeadria.com'),
        ],
      ),
    );
  }

  Widget _emailChip(String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_outline_rounded, color: kOrange, size: 16),
          const SizedBox(width: 8),
          Text(
            email,
            style: const TextStyle(
                color: kOrange, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
