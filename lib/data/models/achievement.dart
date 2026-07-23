import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'level_progress.dart';

/// A milestone badge derived purely from existing save data (stats +
/// progress) — nothing new to persist, so it can never get out of sync.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int Function(PlayerStats stats, int totalStars, int levelsCompleted)
  current;
  final int target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
  });
}

final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_steps',
    title: 'First Steps',
    description: 'Complete your first level.',
    icon: Icons.flag_rounded,
    color: PrismColors.green,
    current: (s, stars, lc) => lc,
    target: 1,
  ),
  Achievement(
    id: 'getting_started',
    title: 'Getting Started',
    description: 'Complete 5 levels.',
    icon: Icons.route_rounded,
    color: PrismColors.cyan,
    current: (s, stars, lc) => lc,
    target: 5,
  ),
  Achievement(
    id: 'halfway',
    title: 'Halfway There',
    description: 'Complete 20 levels.',
    icon: Icons.timeline_rounded,
    color: PrismColors.blue,
    current: (s, stars, lc) => lc,
    target: 20,
  ),
  Achievement(
    id: 'puzzle_master',
    title: 'Puzzle Master',
    description: 'Complete all 40 levels.',
    icon: Icons.emoji_events_rounded,
    color: PrismColors.amber,
    current: (s, stars, lc) => lc,
    target: 40,
  ),
  Achievement(
    id: 'crystal_collector',
    title: 'Crystal Collector',
    description: 'Collect 50 energy crystals.',
    icon: Icons.diamond_rounded,
    color: PrismColors.magenta,
    current: (s, stars, lc) => s.totalCrystals,
    target: 50,
  ),
  Achievement(
    id: 'crystal_hoarder',
    title: 'Crystal Hoarder',
    description: 'Collect 200 energy crystals.',
    icon: Icons.diamond_rounded,
    color: PrismColors.magenta,
    current: (s, stars, lc) => s.totalCrystals,
    target: 200,
  ),
  Achievement(
    id: 'star_gatherer',
    title: 'Star Gatherer',
    description: 'Earn 30 stars.',
    icon: Icons.star_rounded,
    color: PrismColors.amber,
    current: (s, stars, lc) => stars,
    target: 30,
  ),
  Achievement(
    id: 'constellation',
    title: 'Constellation',
    description: 'Earn 90 stars.',
    icon: Icons.auto_awesome_rounded,
    color: PrismColors.amber,
    current: (s, stars, lc) => stars,
    target: 90,
  ),
  Achievement(
    id: 'perfectionist',
    title: 'Perfectionist',
    description: 'Earn every star in the game.',
    icon: Icons.workspace_premium_rounded,
    color: PrismColors.amber,
    current: (s, stars, lc) => stars,
    target: 120,
  ),
  Achievement(
    id: 'magnetic_touch',
    title: 'Magnetic Touch',
    description: 'Trigger magnets 25 times.',
    icon: Icons.blur_circular_rounded,
    color: PrismColors.violet,
    current: (s, stars, lc) => s.magnetUses,
    target: 25,
  ),
  Achievement(
    id: 'sharp_shooter',
    title: 'Sharp Shooter',
    description: 'Win a level on your first attempt, 5 times.',
    icon: Icons.gps_fixed_rounded,
    color: PrismColors.cyan,
    current: (s, stars, lc) => s.perfectRuns,
    target: 5,
  ),
  Achievement(
    id: 'flawless',
    title: 'Flawless',
    description: 'Win a level on your first attempt, 20 times.',
    icon: Icons.verified_rounded,
    color: PrismColors.cyan,
    current: (s, stars, lc) => s.perfectRuns,
    target: 20,
  ),
  Achievement(
    id: 'persistent',
    title: 'Persistent',
    description: 'Make 100 attempts across all levels.',
    icon: Icons.replay_rounded,
    color: PrismColors.blue,
    current: (s, stars, lc) => s.totalAttempts,
    target: 100,
  ),
];
