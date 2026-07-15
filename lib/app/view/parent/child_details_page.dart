import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/viewmodel/player_detail_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class ChildDetailsPage extends StatefulWidget {
  final String id;

  const ChildDetailsPage({super.key, @PathParam('id') required this.id});

  @override
  State<ChildDetailsPage> createState() => _ChildDetailsPageState();
}

class _ChildDetailsPageState extends State<ChildDetailsPage> {
  final _playerService = PlayerService();
  PlayerModel? _player;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    _player = await _playerService.getPlayerById(widget.id);
    if (_player != null && mounted) {
      await context
          .read<PlayerDetailViewModel>()
          .loadPlayerPricing(_player!.categoryId);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricingVM = context.watch<PlayerDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _player?.name ?? 'Child Details',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: _player == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPlayerInfoCard(_player!),
                const SizedBox(height: 16),
                _buildPricingCard(pricingVM),
              ],
            ),
    );
  }

  Widget _buildPlayerInfoCard(PlayerModel player) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage:
                      player.imageUrl != null ? NetworkImage(player.imageUrl!) : null,
                  child: player.imageUrl == null
                      ? Text(
                          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level: ${player.level}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.cake, 'Age', '${player.computedAge} years'),
            _buildInfoRow(Icons.category, 'Category', player.categoryName ?? 'Not assigned'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PlayerDetailViewModel pricingVM) {
    final category = pricingVM.category;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Pricing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (category == null)
              Text(
                'No pricing information available',
                style: TextStyle(color: Colors.grey[600]),
              )
            else ...[
              _buildPriceRow('Group Session', category.groupPrice),
              const SizedBox(height: 8),
              _buildPriceRow('Private Session', category.privatePrice),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          'RM ${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}
