import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/constants.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Reception manage a guest request (PLAN §17, §18).
class RequestManageScreen extends StatefulWidget {
  final String requestId;
  const RequestManageScreen({super.key, required this.requestId});

  @override
  State<RequestManageScreen> createState() => _RequestManageScreenState();
}

class _RequestManageScreenState extends State<RequestManageScreen> {
  final _assignCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _assignCtrl.dispose();
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
    final stay = store.stayById(r.stayId);
    final guest = store.guestById(r.guestId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('${l.requestNo} ${r.id}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
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
                                Expanded(
                                  child: Text(
                                    r.title,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                StatusChip(
                                  label: r.status.label,
                                  color: r.status.color,
                                ),
                                StatusChip(
                                  label: '${l.roomLabel} ${room?.number}',
                                  color: theme.colorScheme.primary,
                                ),
                                StatusChip(
                                  label: guest?.name ?? '',
                                  color: const Color(0xFF00838F),
                                ),
                                if (r.priority == RequestPriority.urgent)
                                  const StatusChip(
                                    label: 'Urgent',
                                    color: Color(0xFFC62828),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              r.description,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${l.isArabic ? "أُنشئ" : "Created"} ${Fmt.dateTime(r.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            if (r.assignedTo != null)
                              Text(
                                '${l.isArabic ? "مُسند إلى" : "Assigned"}: ${r.assignedTo}',
                                style: theme.textTheme.bodySmall,
                              ),
                            if (r.completedAt != null)
                              Text(
                                '${l.isArabic ? "أُنجز" : "Completed"} ${Fmt.dateTime(r.completedAt!)}',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.isArabic ? 'إجراءات' : 'Actions',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: Text(l.acknowledge),
                          avatar: const Icon(Icons.mark_email_read_outlined),
                          onPressed: r.status == RequestStatus.newRequest
                              ? () => store.updateRequestStatus(
                                  r.id,
                                  RequestStatus.acknowledged,
                                )
                              : null,
                        ),
                        ActionChip(
                          label: Text(l.assign),
                          avatar: const Icon(Icons.person_add_alt_1_outlined),
                          onPressed:
                              r.status == RequestStatus.acknowledged ||
                                  r.status == RequestStatus.newRequest
                              ? () => _assign(r)
                              : null,
                        ),
                        ActionChip(
                          label: Text(l.startProgress),
                          avatar: const Icon(Icons.play_arrow),
                          onPressed:
                              r.status == RequestStatus.acknowledged ||
                                  r.status == RequestStatus.assigned
                              ? () => store.updateRequestStatus(
                                  r.id,
                                  RequestStatus.inProgress,
                                )
                              : null,
                        ),
                        ActionChip(
                          label: Text(l.markComplete),
                          avatar: const Icon(Icons.check),
                          onPressed:
                              r.status != RequestStatus.completed &&
                                  r.status != RequestStatus.cancelled
                              ? () => store.updateRequestStatus(
                                  r.id,
                                  RequestStatus.completed,
                                )
                              : null,
                        ),
                        ActionChip(
                          label: Text(l.cancel),
                          avatar: const Icon(Icons.block),
                          onPressed:
                              r.status != RequestStatus.completed &&
                                  r.status != RequestStatus.cancelled
                              ? () => store.updateRequestStatus(
                                  r.id,
                                  RequestStatus.cancelled,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.isArabic ? 'المحادثة' : 'Conversation',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (r.messages.isEmpty)
                      EmptyState(
                        icon: Icons.chat_bubble_outline,
                        message: l.isArabic
                            ? 'لا رسائل بعد'
                            : 'No messages yet',
                      )
                    else
                      ...r.messages.map((m) {
                        final mine = m.fromStaff;
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.08,
                                    ),
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
                                    color: mine
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  Fmt.time(m.at),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: mine
                                        ? Colors.white70
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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
                        hintText: l.isArabic
                            ? 'رد على النزيل...'
                            : 'Reply to guest...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      if (_msgCtrl.text.trim().isEmpty) return;
                      store.addRequestMessage(
                        r.id,
                        RequestMessage(
                          id: 'm${DateTime.now().millisecondsSinceEpoch}',
                          authorId: 'u2',
                          fromStaff: true,
                          text: _msgCtrl.text.trim(),
                          at: DateTime.now(),
                        ),
                      );
                      _msgCtrl.clear();
                    },
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

  void _assign(GuestRequest r) {
    final store = context.read<HotelStore>();
    final l = L10n.of(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.assign),
        content: TextField(
          controller: _assignCtrl,
          decoration: InputDecoration(
            hintText: l.isArabic
                ? 'مثال: التنظيف - ليلى'
                : 'e.g. Housekeeping — Layla',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final who = _assignCtrl.text.trim().isEmpty
                  ? 'Unassigned'
                  : _assignCtrl.text.trim();
              store.updateRequestStatus(
                r.id,
                RequestStatus.assigned,
                assignedTo: who,
              );
              _assignCtrl.clear();
              Navigator.of(c).pop();
            },
            child: Text(l.assign),
          ),
        ],
      ),
    );
  }
}
