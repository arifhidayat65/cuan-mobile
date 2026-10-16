import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/backup_service.dart';
import '../../../core/theme/ledger_theme.dart';
import '../../../core/widgets/gradient_avatar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';
import '../bloc/theme_cubit.dart';

/// Settings — professional startup-grade preferences screen.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _backingUp = false;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadProfile();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LedgerTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar?',
            style: LedgerTheme.displaySerif(22)),
        content: Text(
          'Kamu harus login lagi untuk mengakses datamu.',
          style: LedgerTheme.bodyMedium.copyWith(color: LedgerTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: LedgerTheme.rose),
            child: Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      // AuthBloc unregisters the push token (while still authed), signs out,
      // and AuthGate routes back to the login page.
      context.read<AuthBloc>().add(const AuthLogoutRequested());
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LedgerTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ubah kata sandi',
            style: LedgerTheme.displaySerif(22)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi lama',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi baru (min 8)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      final ok = await context.read<SettingsCubit>().changePassword(
            oldCtrl.text,
            newCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Kata sandi berhasil diubah'
              : 'Gagal — cek kata sandi lamamu'),
          backgroundColor: ok ? LedgerTheme.teal : LedgerTheme.rose,
        ),
      );
    }
    oldCtrl.dispose();
    newCtrl.dispose();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: LedgerTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Bantuan',
            style: LedgerTheme.displaySerif(22)),
        content: Text(
          'Butuh bantuan?\n\n'
          '• Chat dengan Cuan AI di tab Asisten untuk mencatat transaksi otomatis.\n'
          '• Atur budget bulanan di tab Budget agar pengeluaran terkendali.\n'
          '• Hubungi: support@cuan.app',
          style: LedgerTheme.bodyMedium.copyWith(
            color: LedgerTheme.muted,
            height: 1.5,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedgerTheme.bg,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: LedgerTheme.displaySerif(26),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Profile card — brand hero gradient, no glow.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LedgerTheme.heroGradient,
                  borderRadius:
                      BorderRadius.circular(LedgerTheme.radiusCard),
                  border: Border.all(
                    color: LedgerTheme.teal.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          state.userName.isNotEmpty
                              ? state.userName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.loading
                                ? 'Memuat…'
                                : state.userName.isEmpty
                                    ? 'Pengguna Cuan'
                                    : state.userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.userEmail,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Tampilan'),
              BlocBuilder<ThemeCubit, bool>(
                builder: (context, isDark) => _tile(
                  icon: isDark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  title: 'Mode gelap',
                  subtitle: isDark ? 'Aktif' : 'Nonaktif (mode terang)',
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: LedgerTheme.accent,
                    onChanged: (_) => context.read<ThemeCubit>().toggle(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Notifikasi'),
              _tile(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi push',
                subtitle: 'Info budget & pengingat transaksi',
                trailing: Switch(
                  value: state.notificationsEnabled,
                  activeThumbColor: LedgerTheme.accent,
                  onChanged: (v) =>
                      context.read<SettingsCubit>().toggleNotifications(v),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Keamanan'),
              if (state.biometricAvailable)
                _tile(
                  icon: Icons.fingerprint_outlined,
                  title: 'Kunci biometrik',
                  subtitle: 'Buka app dengan sidik jari / wajah',
                  trailing: Switch(
                    value: state.biometricEnabled,
                    activeThumbColor: LedgerTheme.accent,
                    onChanged: (v) async {
                      final ok = await context
                          .read<SettingsCubit>()
                          .toggleBiometric(v);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verifikasi biometrik gagal'),
                            backgroundColor: LedgerTheme.rose,
                          ),
                        );
                      }
                    },
                  ),
                ),
              _tile(
                icon: Icons.lock_outline,
                title: 'Ubah kata sandi',
                subtitle: 'Perbarui kata sandi akunmu',
                onTap: _changePassword,
              ),
              const SizedBox(height: 12),
              _tile(
                icon: Icons.backup_outlined,
                title: 'Backup data',
                subtitle: 'Unduh semua data sebagai JSON',
                trailing: _backingUp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LedgerTheme.accent,
                        ),
                      )
                    : null,
                onTap: () => _backupData(context),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Tentang'),
              _tile(
                icon: Icons.info_outline,
                title: 'Tentang Cuan',
                subtitle: 'Versi 1.0.0',
                onTap: () => _showAbout(context),
              ),
              _tile(
                icon: Icons.help_outline,
                title: 'Bantuan',
                subtitle: 'Pusat bantuan & kontak',
                onTap: _showHelp,
              ),
              const SizedBox(height: 24),
              // Logout — destructive, full width.
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout, color: LedgerTheme.rose),
                  label: Text(
                    'Keluar',
                    style: TextStyle(
                      color: LedgerTheme.rose,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: LedgerTheme.rose.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  Widget _sectionTitle(String t) => Padding(
        padding: EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          t.toUpperCase(),
          style: LedgerTheme.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: LedgerTheme.surface,
        borderRadius: BorderRadius.circular(LedgerTheme.radiusTile),
        border: Border.all(color: LedgerTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: GradientAvatar.solid(
          icon: icon,
          iconColor: LedgerTheme.accent,
          size: 42,
          iconSize: 21,
          radius: LedgerTheme.radiusAvatar,
        ),
        title: Text(
          title,
          style: LedgerTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: LedgerTheme.caption,
        ),
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right, color: LedgerTheme.muted)
                : null),
      ),
    );
  }

  Future<void> _backupData(BuildContext context) async {
    if (_backingUp) return;
    setState(() => _backingUp = true);
    try {
      final result = await BackupService().backup();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup tersimpan: ${result.fileName}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } on BackupException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: LedgerTheme.rose,
        ),
      );
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LedgerTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LedgerTheme.accentGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'C',
                  style: LedgerTheme.displaySerif(
                    36,
                    color:
                        LedgerTheme.foregroundFor(LedgerTheme.accentGradient),
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cuan',
              style: LedgerTheme.headlineMedium.copyWith(fontSize: 22),
            ),
            Text(
              'Versi 1.0.0',
              style: LedgerTheme.caption.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Catat uang masuk & keluar dengan bantuan AI.\nUangmu tetap milikmu.',
              textAlign: TextAlign.center,
              style: LedgerTheme.bodyMedium
                  .copyWith(color: LedgerTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 Cuan',
              style: LedgerTheme.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LedgerTheme.accent,
              foregroundColor: LedgerTheme.onAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              showLicensePage(
                context: context,
                applicationName: 'Cuan',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Cuan',
              );
            },
            child: const Text('Lisensi'),
          ),
        ],
      ),
    );
  }
}
