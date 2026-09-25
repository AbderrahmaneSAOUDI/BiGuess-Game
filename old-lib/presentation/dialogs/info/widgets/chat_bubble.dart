import 'package:flutter/material.dart';

/// Simulated 2-player dialogue question exchange bubble
class ChatBubble extends StatelessWidget {
  final String speaker;
  final String question;
  final String response;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.speaker,
    required this.question,
    required this.response,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: accentColor,
            child: Text(
              isUser ? 'P1' : 'P2',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  question,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              response,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
