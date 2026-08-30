import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Guest-side request detail with status timeline + chat with staff.
class RequestDetailScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final store = context.watch<HotelStore>();
    final theme = Theme.of(context);
    final r = store.requestById(widget.requestId);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.error_outline, message: l.noResults),
      );
    }
    final room = store.roomById(r.roomId);
    final service = r.serviceId == null ? null : store.firstWhereOrNull(store.services, (s) => s.id == r.serviceId);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('${l.requestNo} ${r.id}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(r.category.icon, color: r.status.color),
                                const SizedBox(width: 8),
                                Expanded(child: Text(r.title, style: theme.textTheme.headlineSmall)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                StatusChip(label: r.status.label, color: r.status.color),
                                StatusChip(
                                  label: '${l.roomLabel} ${room?.number ?? ""}',
                                  color: theme.colorScheme.primary,
                                ),
                                if (r.priority == RequestPriority.urgent)
                                  const StatusChip(label: 'Urgent', color: Color(0xFFC62828)),
                                if (r.assignedTo != null)
                                  StatusChip(label: r.assignedTo!, color: const Color(0xFF00838F)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(r.description, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            Text(
                              l.isArabic
                                  ? 'أُنشئ ${Fmt.dateTime(r.createdAt)}'
                                  : 'Created ${Fmt.dateTime(r.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            if (service != null) ...[
                              const SizedBox(height: 6),
                              Text('${l.category}: ${l.isArabic ? service.category.labelAr : service.category.label}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l.isArabic ? 'المحادثة' : 'Conversation',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (r.messages.isEmpty)
                      EmptyState(icon: Icons.chat_bubble_outline, message: l.isArabic ? 'لا رسائل بعد' : 'No messages yet')
                    else
                      ...r.messages.map((m) => _MsgBubble(m: m)),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: l.isArabic ? 'اكتب رسالة...' : 'Type a message...',
                        prefixIcon: const Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    if (_msgCtrl.text.trim().isEmpty) return;
    final store = context.read<HotelStore>();
    final app = context.read<AppState>();
    final l = L10n.of(context);
    final stay = store.currentStayForGuest(app.guestId ?? '');
    store.addRequestMessage(
      widget.requestId,
      RequestMessage(
        id: 'm${DateTime.now().millisecondsSinceEpoch}',
        authorId: stay?.guestId ?? 'guest',
        fromStaff: false,
        text: _msgCtrl.text.trim(),
        at: DateTime.now(),
      ),
    );
    _msgCtrl.clear();
    // Simulate staff auto-ack for new requests
    final r = store.requestById(widget.requestId);
    if (r != null && r.status == RequestStatus.newRequest) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        store.addRequestMessage(
          widget.requestId,
          RequestMessage(
            id: 'm${DateTime.now().millisecondsSinceEpoch + 1}',
            authorId: 'u2',
            fromStaff: true,
            text: l.isArabic ? 'شكراً لك، استلمنا طلبك ونعمل عليه.' : 'Thank you, we received your request and are on it.',
            at: DateTime.now(),
          ),
        );
        store.updateRequestStatus(widget.requestId, RequestStatus.acknowledged, assignedTo: 'Reception — Layla');
      });
    }
  }
}

class _MsgBubble extends StatelessWidget {
  final RequestMessage m;
  const _MsgBubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = !m.fromStaff;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
        decoration: BoxDecoration(
          color: mine
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(mine ? 12 : 2),
            bottomRight: Radius.circular(mine ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                color: mine ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              Fmt.time(m.at),
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
