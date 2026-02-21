import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';

/// Landing/home screen combining Hero, Services, HowItWorks, Stats, Testimonials.
///
/// Adapted from the multi-section React landing page into a single
/// scrollable mobile screen. The laptop mockup is replaced with a
/// mobile-friendly hero section.
class LandingScreen extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LandingScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgWarm, Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('T', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: const TextSpan(
                        text: 'TeleMed',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        children: [
                          TextSpan(text: 'Care', style: TextStyle(color: AppColors.goldPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: onLogin,
                    child: Text(loc.translate('logIn')),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: onRegister,
                      child: Text(loc.translate('getStarted')),
                    ),
                  ),
                ],
              ),

              // ── Hero Section ───────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroSection(onRegister: onRegister),
              ),

              // ── Services Section ───────────────────────────────
              const SliverToBoxAdapter(child: _ServicesSection()),

              // ── How It Works Section ───────────────────────────
              const SliverToBoxAdapter(child: _HowItWorksSection()),

              // ── Stats Section ──────────────────────────────────
              const SliverToBoxAdapter(child: _StatsSection()),

              // ── Testimonials Section ───────────────────────────
              const SliverToBoxAdapter(child: _TestimonialsSection()),

              // ── Footer ─────────────────────────────────────────
              const SliverToBoxAdapter(child: _Footer()),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Section ───────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final VoidCallback onRegister;

  const _HeroSection({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Row(
            children: [
              Container(height: 2, width: 32, color: AppColors.goldPrimary),
              const SizedBox(width: 8),
              Text(
                'PREMIUM HEALTHCARE REDEFINED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // Heading
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Your Health,\n'),
                TextSpan(
                  text: 'elevated to Gold Standard.',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = AppColors.goldTextGradient.createShader(
                        const Rect.fromLTWH(0, 0, 300, 70),
                      ),
                  ),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(height: 1.15),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.05, end: 0),

          const SizedBox(height: 20),

          Text(
            'Connect with world-class specialists instantly. '
            'Experience AI-powered diagnostics and concierge medical care.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),

          Row(
            children: [
              AppButton(
                label: 'Book Priority Consult',
                variant: AppButtonVariant.primary,
                onPressed: onRegister,
              ),
            ],
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          // Trust bar
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: ['Generic Hospital', 'MediCross', 'HealthPlus', 'GlobalCare']
                .map(
                  (name) => Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                )
                .toList(),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}

// ── Services Section ───────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  static final _services = [
    _ServiceItem(icon: LucideIcons.stethoscope, title: 'General Consultation', desc: 'For the health needs of you and your family', gradient: [const Color(0xFF60A5FA), const Color(0xFF2563EB)]),
    _ServiceItem(icon: LucideIcons.baby, title: 'Pediatrics', desc: "Expert care for your child's health", gradient: [const Color(0xFFF472B6), const Color(0xFFDB2777)]),
    _ServiceItem(icon: LucideIcons.brain, title: 'Mental Health', desc: 'Speak with a therapist about your concerns', gradient: [const Color(0xFF2DD4BF), const Color(0xFF0D9488)]),
    _ServiceItem(icon: LucideIcons.sparkles, title: 'Dermatology', desc: 'Skin & wellness treatments', gradient: [const Color(0xFFFBBF24), const Color(0xFFD97706)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Our Services', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Expert care at your fingertips.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...List.generate(_services.length, (i) {
            final s = _services[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassPanel(
                borderColor: Colors.transparent,
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: s.gradient),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(s.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(s.desc, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 18, color: AppColors.goldDark),
                  ],
                ),
              ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.05, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String title;
  final String desc;
  final List<Color> gradient;
  const _ServiceItem({required this.icon, required this.title, required this.desc, required this.gradient});
}

// ── How It Works Section ───────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    ('Create Account', 'Sign up and complete your profile in minutes', Icons.person_add_outlined),
    ('Choose Specialist', 'Browse our network of certified doctors', Icons.medical_services_outlined),
    ('Book & Consult', 'Schedule and attend virtual consultations', Icons.videocam_outlined),
    ('Get Treatment', 'Receive prescriptions and follow-up care', Icons.healing_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How It Works', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          ...List.generate(_steps.length, (i) {
            final (title, desc, icon) = _steps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step number
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(desc, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(icon, size: 24, color: AppColors.goldPrimary),
                ],
              ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.03, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

// ── Stats Section ──────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  static const _stats = [
    ('50K+', 'Patients'),
    ('200+', 'Doctors'),
    ('98%', 'Satisfaction'),
    ('24/7', 'Availability'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_stats.length, (i) {
          final (value, label) = _stats[i];
          return Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.goldDark)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ).animate().fadeIn(delay: (i * 100).ms).scale(begin: const Offset(0.9, 0.9));
        }),
      ),
    );
  }
}

// ── Testimonials Section ───────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const _testimonials = [
    ('The AI diagnosis feature is incredible. It gave me accurate insights before my doctor visit.', 'Sarah M.', 'Patient'),
    ('Managing my clinic\'s queue remotely has been a game changer. The copilot is amazing.', 'Dr. Patel', 'Cardiologist'),
    ('I love the pharmacy delivery and prescription scanning features!', 'Ravi K.', 'Patient'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What Our Users Say', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          ..._testimonials.asMap().entries.map((entry) {
            final i = entry.key;
            final (quote, name, role) = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (s) => Icon(Icons.star, size: 16, color: AppColors.goldPrimary)),
                    ),
                    const SizedBox(height: 12),
                    Text(quote, style: const TextStyle(fontSize: 14, height: 1.5, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.goldLight,
                          child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.goldDark)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(role, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (i * 150).ms).slideY(begin: 0.05, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.textPrimary,
      child: Column(
        children: [
          RichText(
            text: const TextSpan(
              text: 'TeleMed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              children: [TextSpan(text: 'Care', style: TextStyle(color: AppColors.goldPrimary))],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2025 TeleMedCare. All rights reserved.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          const Text(
            'Premium Healthcare, Accessible Everywhere.',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
