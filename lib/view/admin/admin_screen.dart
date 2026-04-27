import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/main.dart';
import 'package:spendify/widgets/toast/custom_toast.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String _filter = 'All';

  static const _filters = ['All', 'open', 'in_progress', 'resolved', 'closed'];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await supabaseC
          .from('support_messages')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _tickets = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      CustomToast.errorToast('Error', 'Failed to load tickets');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _tickets;
    return _tickets.where((t) => (t['status'] ?? 'open') == _filter).toList();
  }

  static const _statuses = ['open', 'in_progress', 'resolved', 'closed'];

  static const _statusColors = {
    'open': Color(0xFF3B82F6),
    'in_progress': Color(0xFFF59E0B),
    'resolved': Color(0xFF22C55E),
    'closed': Color(0xFF71717A),
  };

  Future<void> _reply(Map<String, dynamic> ticket) async {
    final replyCtrl = TextEditingController(text: ticket['admin_reply'] ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedStatus = ticket['status'] ?? 'open';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColor.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reply to ${ticket['email'] ?? 'User'}',
                  style: TextStyle(
                    color: isDark ? AppColor.textPrimary : const Color(0xFF09090B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 4),
              Text(ticket['subject'] ?? '',
                  style: TextStyle(color: isDark ? AppColor.textSecondary : const Color(0xFF71717A), fontSize: 13)),
              const SizedBox(height: 16),

              // Status picker
              Text('Status', style: TextStyle(color: isDark ? AppColor.textSecondary : const Color(0xFF71717A), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _statuses.map((s) {
                  final selected = s == selectedStatus;
                  final color = _statusColors[s]!;
                  return GestureDetector(
                    onTap: () => setLocal(() => selectedStatus = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.15) : (isDark ? AppColor.darkSurface : const Color(0xFFF4F4F5)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? color : Colors.transparent),
                      ),
                      child: Text(
                        s.replaceAll('_', ' '),
                        style: TextStyle(
                          color: selected ? color : (isDark ? AppColor.textSecondary : const Color(0xFF71717A)),
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Reply field
              TextField(
                controller: replyCtrl,
                maxLines: 4,
                autofocus: false,
                style: TextStyle(color: isDark ? AppColor.textPrimary : const Color(0xFF09090B), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write your reply… (optional)',
                  hintStyle: TextStyle(color: isDark ? AppColor.textTertiary : const Color(0xFF9A9890), fontSize: 13),
                  filled: true,
                  fillColor: isDark ? AppColor.darkSurface : const Color(0xFFF6F5F3),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final update = <String, dynamic>{
        'status': selectedStatus,
      };
      if (replyCtrl.text.trim().isNotEmpty) {
        update['admin_reply'] = replyCtrl.text.trim();
        update['replied_at'] = DateTime.now().toIso8601String();
      }
      await supabaseC.from('support_messages').update(update).eq('id', ticket['id']);
      CustomToast.successToast('Saved', 'Ticket updated');
      _fetch();
    } catch (e) {
      debugPrint('Admin update error: $e');
      CustomToast.errorToast('Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF9F9F9);
    final border = isDark ? AppColor.darkBorder : const Color(0xFFE4E4E7);

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
        title: Text('Support Tickets', style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsLight.arrowClockwise, color: textMuted, size: 20),
            onPressed: _fetch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppColor.primary : (isDark ? AppColor.darkSurface : const Color(0xFFF4F4F5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      f.replaceAll('_', ' '),
                      style: TextStyle(
                        color: selected ? Colors.white : textMuted,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(child: Text('No tickets', style: TextStyle(color: textMuted)))
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = _filtered[i];
                            final replied = t['admin_reply'] != null;
                            final date = t['created_at'] != null
                                ? DateFormat('d MMM, h:mm a').format(DateTime.parse(t['created_at']).toLocal())
                                : '';

                            return GestureDetector(
                              onTap: () => _reply(t),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(t['subject'] ?? 'No subject',
                                              style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        const SizedBox(width: 8),
                                        Builder(builder: (_) {
                                          final status = t['status'] ?? 'open';
                                          final color = _statusColors[status] ?? const Color(0xFF3B82F6);
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
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(t['email'] ?? '', style: TextStyle(color: AppColor.primary, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Text(t['message'] ?? '',
                                        style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    if (replied) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColor.primary.withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            PhosphorIcon(PhosphorIconsLight.arrowBendUpLeft,
                                                size: 14, color: AppColor.primary),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(t['admin_reply'],
                                                  style: TextStyle(color: textPrimary, fontSize: 12, height: 1.4),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColor.darkSurface : const Color(0xFFF4F4F5),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(t['category'] ?? '',
                                              style: TextStyle(color: textMuted, fontSize: 11)),
                                        ),
                                        const Spacer(),
                                        Text(date, style: TextStyle(color: textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
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
}
