import 'package:flutter/material.dart';

/// Reminds people that this is a public demo, where shared admin accounts can
/// see orders and addresses.
class DemoDataNotice extends StatelessWidget {
  const DemoDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This is a demo app. Please don’t enter real personal information.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
