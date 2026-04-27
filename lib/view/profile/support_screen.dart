import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedCategory = 'General Help';
  bool _isLoading = false;
  List<Map<String, dynamic>> _myTickets = [];
  bool _ticketsLoading = true;

  static const _categories = [
    'General Help',
    'Bug Report',
    'Feature Request',
    'Billing',
    'Other',
  ];

  static const _categoryIcons = {
    'General Help': PhosphorIconsLight.question,
    'Bug Report': PhosphorIconsLight.bug,
    'Feature Request': PhosphorIconsLight.lightbulb,
    'Billing': PhosphorIconsLight.creditCard,
    'Other': PhosphorIconsLight.chatDots,
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchMyTickets();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteTicket(String id) async {
    try {
      await Supabase.instance.client.from('support_messages').delete().eq('id', id);
      CustomToast.successToast('Deleted', 'Ticket removed');
      _fetchMyTickets();
    } catch (e) {
      CustomToast.errorToast('Error', 'Failed to delete ticket');
    }
  }

  Future<void> _fetchMyTickets() async {
    setState(() => _ticketsLoading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      final res = await Supabase.instance.client
          .from('support_messages')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      if (mounted) setState(() => _myTickets = List<Map<String, dynamic>>.from(res));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _ticketsLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final ctrl = Get.find<HomeController>();
      await Supabase.instance.client.from('support_messages').insert({
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        'email': ctrl.userEmail.value,
        'category': _selectedCategory,
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
      });
      if (mounted) {
        CustomToast.successToast('Sent!', 'We\'ll get back to you shortly');
        _subjectCtrl.clear();
        _messageCtrl.clear();
        await _fetchMyTickets();
        _tabCtrl.animateTo(1);
      }
    } catch (e) {
      CustomToast.errorToast('Error', 'Failed to send. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final surface = isDark ? AppColor.darkSurface : const Color(0xFFF6F5F3);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE8E6E2);
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF1A1916);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF6B6960);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsLight.arrowLeft, color: textPrimary, size: 22),
          onPressed: () => Get.back(),
        ),
        title: Text('Help & Support', style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColor.primary,
          unselectedLabelColor: textMuted,
          indicatorColor: AppColor.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'New Ticket'), Tab(text: 'My Tickets')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab 1: Submit form ──────────────────────────
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [

            // ── Hero header ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColor.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: PhosphorIcon(PhosphorIconsLight.headset, color: Colors.white, size: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('We\'re here to help', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text('Expect a reply within 24 hours', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Category picker ───────────────────────────
            Text('Category', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            _CategoryPicker(
              categories: _categories,
              icons: _categoryIcons,
              selected: _selectedCategory,
              isDark: isDark,
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),

            const SizedBox(height: 20),

            // ── Subject ───────────────────────────────────
            Text('Subject', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectCtrl,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: _inputDecoration(
                hint: 'Brief description of your issue',
                isDark: isDark,
                surface: surface,
                border: border,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // ── Message ───────────────────────────────────
            Text('Message', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageCtrl,
              style: TextStyle(color: textPrimary, fontSize: 14),
              maxLines: 6,
              decoration: _inputDecoration(
                hint: 'Describe your issue in detail…',
                isDark: isDark,
                surface: surface,
                border: border,
              ),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Please provide more detail (min 10 chars)' : null,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 28),

            // ── Submit button ─────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColor.primary.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(PhosphorIconsLight.paperPlaneTilt, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Send Message', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Footer note ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(PhosphorIconsLight.lock, size: 13, color: textMuted),
                const SizedBox(width: 5),
                Text('Your message is private and secure', style: TextStyle(color: textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),

          // ── Tab 2: My Tickets ───────────────────────────
          _ticketsLoading
              ? const Center(child: CircularProgressIndicator())
              : _myTickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(PhosphorIconsLight.chatDots, size: 40, color: textMuted),
                          const SizedBox(height: 12),
                          Text('No tickets yet', style: TextStyle(color: textMuted, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Submit a message and we\'ll reply here', style: TextStyle(color: textMuted, fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMyTickets,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        itemCount: _myTickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final t = _myTickets[i];
                          final replied = t['admin_reply'] != null;
                          final date = t['created_at'] != null
                              ? DateFormat('d MMM, h:mm a').format(DateTime.parse(t['created_at']).toLocal())
                              : '';
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColor.darkCard : const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(t['subject'] ?? '',
                                          style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Builder(builder: (_) {
                                      final status = t['status'] ?? 'open';
                                      const colors = {
                                        'open': Color(0xFF3B82F6),
                                        'in_progress': Color(0xFFF59E0B),
                                        'resolved': Color(0xFF22C55E),
                                        'closed': Color(0xFF71717A),
                                      };
                                      final color = colors[status] ?? const Color(0xFF3B82F6);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.replaceAll('_', ' '),
                                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    }),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _deleteTicket(t['id'].toString()),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: PhosphorIcon(PhosphorIconsLight.trash, size: 16, color: AppColor.expense),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(t['message'] ?? '',
                                    style: TextStyle(color: textMuted, fontSize: 13, height: 1.4)),
                                if (replied) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary.withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            PhosphorIcon(PhosphorIconsLight.arrowBendUpLeft, size: 13, color: AppColor.primary),
                                            const SizedBox(width: 5),
                                            Text('Reply from Spendify',
                                                style: TextStyle(color: AppColor.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(t['admin_reply'],
                                            style: TextStyle(color: textPrimary, fontSize: 13, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(date, style: TextStyle(color: textMuted, fontSize: 11)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    required Color surface,
    required Color border,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? AppColor.textTertiary : const Color(0xFF9A9890), fontSize: 13),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColor.expense),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColor.expense, width: 1.5),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final Map<String, PhosphorIconData> icons;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({
    required this.categories,
    required this.icons,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColor.primary.withValues(alpha: 0.12) : (isDark ? AppColor.darkSurface : const Color(0xFFF6F5F3)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColor.primary : (isDark ? AppColor.darkBorder : const Color(0xFFE8E6E2)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  icons[cat]!,
                  size: 14,
                  color: isSelected ? AppColor.primary : (isDark ? AppColor.textSecondary : const Color(0xFF6B6960)),
                ),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? AppColor.primary : (isDark ? AppColor.textSecondary : const Color(0xFF6B6960)),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
