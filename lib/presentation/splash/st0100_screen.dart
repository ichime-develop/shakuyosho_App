import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/core/config/app_flags.dart';
import 'package:shakuyousho_app/core/utils/app_settings.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firebase_user_sync_service.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';

class St0100SplashScreen extends ConsumerStatefulWidget {
  const St0100SplashScreen({super.key});
  @override
  ConsumerState<St0100SplashScreen> createState() => _St0100SplashScreenState();
}

class _St0100SplashScreenState extends ConsumerState<St0100SplashScreen> {
  bool _didShowError = false;
  static const Color _titleBrown = Color(0xFF8B7E74);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (kUseFirebase) {
        final auth = firebase_auth.FirebaseAuth.instance;
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
        }

        final userRepo = ref.read(userRepositoryProvider);
        final myId = ref.read(currentUserIdProvider);
        final localUser = userRepo.getById(myId);
        final syncService = const FirebaseUserSyncService();
        final remoteUser = await syncService.fetchCurrentUser(
          fallbackAppUserId: myId,
          fallbackDisplayName: localUser?.displayName ?? 'あなた',
        );

        if (remoteUser != null) {
          final merged =
              (localUser ??
                      User(
                        id: myId,
                        displayName: remoteUser.displayName,
                        createdAt: DateTime.now(),
                      ))
                  .copyWith(
                    displayName: remoteUser.displayName,
                    myCode: remoteUser.myCode ?? localUser?.myCode,
                    avatarUrl: remoteUser.avatarUrl ?? localUser?.avatarUrl,
                  );
          userRepo.upsert(merged);
        } else if (localUser != null) {
          await syncService.syncCurrentUser(localUser);
        }
      }
      // TODO: 起動時の初期データ取得（Firebase移行時にここへ追加）
      final firstLaunch = isFirstLaunch();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      if (firstLaunch) {
        context.go('/st0200');
        return;
      }
      context.go('/to0100');
    } catch (e, st) {
      if (_didShowError) return;
      _didShowError = true;
      if (!mounted) return;
      final err = toAppError(e, st);
      await showAppErrorDialog(context: context, error: err);
    }
  }

  @override
  Widget build(BuildContext context) {
    const doodleBase = Color(0xFF948982);
    const softYellow = Color(0xFFF2D57A);
    const softGreen = Color(0xFF9DCEAA);
    const softPink = Color(0xFFF2A8BC);
    const softRed = Color(0xFFF58F8A);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.08),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          const Positioned(top: 28, left: -28, child: _TornMemo()),
          Positioned(
            top: 106,
            left: 130,
            child: Transform.rotate(
              angle: 0.18,
              child: Icon(
                Icons.attach_file,
                size: 64,
                color: doodleBase.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            top: 86,
            right: 48,
            child: _SunDoodle(
              color: softYellow.withValues(alpha: 0.95),
              lineColor: doodleBase.withValues(alpha: 0.75),
            ),
          ),
          Positioned(
            top: 238,
            right: 96,
            child: _CoinDoodle(color: softYellow.withValues(alpha: 0.9)),
          ),
          Positioned(
            top: 236,
            left: 8,
            child: Transform.rotate(
              angle: -0.18,
              child: _BillDoodle(color: softGreen.withValues(alpha: 0.55)),
            ),
          ),
          Positioned(
            top: 242,
            left: 0,
            right: 0,
            child: Text(
              '¥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: doodleBase.withValues(alpha: 0.9),
                height: 1,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: _CenterWordmark(
                color: _titleBrown,
                paperDotColor: softRed,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 220,
            child: Transform.rotate(
              angle: -0.75,
              child: _PencilDoodle(
                bodyColor: doodleBase.withValues(alpha: 0.3),
                tipColor: const Color(0xFFA9C1E8).withValues(alpha: 0.8),
                capColor: softPink.withValues(alpha: 0.95),
              ),
            ),
          ),
          Positioned(
            right: 48,
            bottom: 182,
            child: _FrogDoodle(
              base: softRed.withValues(alpha: 0.95),
              eye: doodleBase.withValues(alpha: 0.82),
            ),
          ),
          Positioned(
            left: 88,
            bottom: 124,
            child: _RibbonDoodle(
              pink: softPink.withValues(alpha: 0.9),
              yellow: softYellow.withValues(alpha: 0.96),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 110,
            child: _SplashProgress(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: Container(
                width: 170,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TornMemo extends StatelessWidget {
  const _TornMemo();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TornEdgeClipper(),
      child: Container(
        width: 300,
        height: 164,
        color: Colors.white.withValues(alpha: 0.55),
        padding: const EdgeInsets.only(top: 34, left: 34, right: 24),
        child: Column(
          children: [
            _line(),
            const SizedBox(height: 18),
            _line(),
            const SizedBox(height: 18),
            _line(),
          ],
        ),
      ),
    );
  }

  Widget _line() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFBBD2E9).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _TornEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 24);
    const step = 24.0;
    var x = size.width;
    var up = true;
    while (x > 0) {
      x -= step;
      p.lineTo(x.clamp(0, size.width), size.height + (up ? -4 : 4));
      up = !up;
    }
    p.lineTo(0, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SunDoodle extends StatelessWidget {
  const _SunDoodle({required this.color, required this.lineColor});

  final Color color;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(8, (i) {
            final angle = i * 3.14159 / 4;
            return Transform.rotate(
              angle: angle,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 8,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            );
          }),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.32),
              border: Border.all(color: color, width: 5),
            ),
          ),
          Positioned(top: 42, left: 38, child: _dot(lineColor)),
          Positioned(top: 42, right: 38, child: _dot(lineColor)),
          Positioned(
            bottom: 32,
            child: Transform.rotate(
              angle: 0.08,
              child: Container(
                width: 34,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: lineColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _CoinDoodle extends StatelessWidget {
  const _CoinDoodle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 5),
      ),
      alignment: Alignment.center,
      child: Text(
        '¥',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _BillDoodle extends StatelessWidget {
  const _BillDoodle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 4),
        color: color.withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final coinSize = (constraints.maxWidth * 0.30)
              .clamp(30.0, 40.0)
              .toDouble();
          final amountFont = (constraints.maxWidth * 0.18)
              .clamp(13.0, 18.0)
              .toDouble();
          final yenFont = (coinSize * 0.55).clamp(12.0, 18.0).toDouble();

          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '1000',
                      style: TextStyle(
                        color: color,
                        fontSize: amountFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: coinSize,
                height: coinSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '¥',
                  style: TextStyle(
                    color: color,
                    fontSize: yenFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '1000',
                      style: TextStyle(
                        color: color,
                        fontSize: amountFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SmallPaper extends StatelessWidget {
  const _SmallPaper({
    required this.dotColor,
  });

  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        width: 80,
        height: 116,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9DDE3), width: 3.5),
        ),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0, 0.35),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterWordmark extends StatelessWidget {
  const _CenterWordmark({
    required this.color,
    required this.paperDotColor,
  });

  final Color color;
  final Color paperDotColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(0.82, 1.0).toDouble();
    final titleFont = 72 * scale;
    final wordmarkWidth = (width * 0.86).clamp(260.0, 340.0).toDouble();

    return Center(
      child: SizedBox(
        width: wordmarkWidth,
        height: 150 * scale,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: 6 * scale,
              child: SizedBox(
                width: 56 * scale,
                height: 82 * scale,
                child: _SmallPaper(
                  dotColor: paperDotColor.withValues(alpha: 0.85),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 6 * scale),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'しゃくよーしょ',
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFont,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PencilDoodle extends StatelessWidget {
  const _PencilDoodle({
    required this.bodyColor,
    required this.tipColor,
    required this.capColor,
  });

  final Color bodyColor;
  final Color tipColor;
  final Color capColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 236,
      height: 34,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(left: 18, right: 22),
            decoration: BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: CustomPaint(
              size: const Size(22, 22),
              painter: _TrianglePainter(color: tipColor),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 26,
              height: 34,
              decoration: BoxDecoration(
                color: capColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FrogDoodle extends StatelessWidget {
  const _FrogDoodle({required this.base, required this.eye});

  final Color base;
  final Color eye;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 92,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(top: 8, left: 24, child: _eye(eye)),
          Positioned(top: 8, right: 24, child: _eye(eye)),
          Container(
            width: 94,
            height: 74,
            decoration: BoxDecoration(
              color: base.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: base, width: 5),
            ),
            alignment: const Alignment(0, 0.25),
            child: Text(
              '---',
              style: TextStyle(
                fontSize: 28,
                color: eye.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eye(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _RibbonDoodle extends StatelessWidget {
  const _RibbonDoodle({required this.pink, required this.yellow});

  final Color pink;
  final Color yellow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: const Alignment(-0.78, 0),
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: pink, width: 5),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.78, 0),
            child: Transform.rotate(
              angle: 0.22,
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: pink, width: 5),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: yellow),
          ),
        ],
      ),
    );
  }
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 250,
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.white.withValues(alpha: 0.5),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 154,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: const Color(0xFFAAD8B6),
            ),
          ),
        ),
      ),
    );
  }
}
