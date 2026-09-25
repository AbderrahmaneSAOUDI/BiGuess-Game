import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/rule_step_card.dart';

/// How to Play Tab view explaining game rules and question exchange
class HowToPlayTab extends StatelessWidget {
  const HowToPlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 20.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Hero Intro Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2-Player Guessing Game',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ask clever Yes/No questions to deduce your mystery character before your rival does!',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Step-by-Step Guide
            Text(
              'Step-by-Step Gameplay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            RuleStepCard(
              stepNumber: 1,
              title: 'Pick a Category & Tap Start',
              icon: Icons.touch_app_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),

            RuleStepCard(
              stepNumber: 2,
              title: 'Show Screen & Hide From Yourself',
              icon: Icons.screen_rotation_rounded,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 8),

            RuleStepCard(
              stepNumber: 3,
              title: 'Take Turns Asking Yes/No Questions',
              icon: Icons.question_answer_rounded,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 8),

            RuleStepCard(
              stepNumber: 4,
              title: 'Eliminate & Deduce',
              icon: Icons.psychology_rounded,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 8),

            RuleStepCard(
              stepNumber: 5,
              title: 'Guess Correctly & Win the Round!',
              icon: Icons.emoji_events_rounded,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 32),

            // Example Duel Simulation
            Text(
              'Example Question Exchange',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: const Column(
                children: [
                  ChatBubble(
                    speaker: 'Player 1',
                    question: 'Does my character possess Titan shifting powers?',
                    response: '✅ YES',
                    isUser: true,
                  ),
                  SizedBox(height: 10),
                  ChatBubble(
                    speaker: 'Player 2',
                    question: 'Is my character part of the Scout Regiment?  ',
                    response: '❌ NO',
                    isUser: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
