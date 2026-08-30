import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hotel_platform/core/app_state.dart';
import 'package:hotel_platform/core/utils/format.dart';
import 'package:hotel_platform/data/models.dart';
import 'package:hotel_platform/data/store.dart';
import 'package:hotel_platform/l10n/app_localizations.dart';
import 'package:hotel_platform/shared/widgets/common_widgets.dart';

/// Structured guest ↔ reception conversation (PLAN §19).
class ReceptionChatScreen extends StatefulWidget {
  const ReceptionChatScreen({super.key});

  @override
  State<ReceptionChatScreen> createState() => _ReceptionChatScreenState();
}

class _ReceptionChatScreenState extends State<ReceptionChatScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = context.watch<AppState>();
    final store = context.watch<HotelStore>();
    final stay = store.currentStayForGuest(app.guestId!)!;
    final existing = store.conversationForStay(stay.id);
    final conv =
        existing ??
        Conversation(
          id: 'CV${store.conversations.length + 1}',
          stayId: stay.id,
          guestId: stay.guestId,
        );
    if (existing == null) {
      store.conversations.add(conv);
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.support_agent, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.receptionChat,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l.isArabic ? 'متصل' : 'Online',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF2E7D32)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: conv.messages.isEmpty
                ? EmptyState(
                    icon: Icons.chat_bubble_outline,
                    message: l.isArabic
                        ? 'ابدأ المحادثة'
                        : 'Start the conversation',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: conv.messages.length,
                    itemBuilder: (c, i) {
                      final m = conv.messages[i];
                      final mine = !m.fromStaff;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withOpacity(0.08),
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
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Fmt.time(m.at),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mine
                                      ? Colors.white70
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: l.isArabic
                            ? 'اكتب رسالة...'
                            : 'Type a message...',
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
    if (_ctrl.text.trim().isEmpty) return;
    final store = context.read<HotelStore>();
    final app = context.read<AppState>();
    final stay = store.currentStayForGuest(app.guestId!)!;
    store.addConversationMessage(
      stay.id,
      RequestMessage(
        id: 'cm${DateTime.now().millisecondsSinceEpoch}',
        authorId: app.guestId!,
        fromStaff: false,
        text: _ctrl.text.trim(),
        at: DateTime.now(),
      ),
    );
    _ctrl.clear();
    // auto staff reply
    final l = L10n.of(context);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      store.addConversationMessage(
        stay.id,
        RequestMessage(
          id: 'cm${DateTime.now().millisecondsSinceEpoch + 1}',
          authorId: 'u2',
          fromStaff: true,
          text: l.isArabic
              ? 'بالتأكيد، سأساعدك في ذلك.'
              : 'Of course, I will help you with that.',
          at: DateTime.now(),
        ),
      );
    });
  }
}
