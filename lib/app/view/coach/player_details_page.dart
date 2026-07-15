import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/player_model.dart';
import 'package:jsba_app/app/model/promotion_pricing_model.dart';
import 'package:jsba_app/app/service/player_service.dart';
import 'package:jsba_app/app/viewmodel/player_detail_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class PlayerDetailsPage extends StatefulWidget {
  final String id;

  const PlayerDetailsPage({super.key, @PathParam('id') required this.id});

  @override
  State<PlayerDetailsPage> createState() => _PlayerDetailsPageState();
}

class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
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
          _player?.name ?? 'Player Details',
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
                const SizedBox(height: 16),
                if (pricingVM.promotions.isNotEmpty)
                  _buildPromotionsCard(pricingVM.promotions),
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
            _buildInfoRow(Icons.phone, 'Phone', player.phone),
            _buildInfoRow(
              Icons.category,
              'Category',
              player.categoryName ?? 'Not assigned',
            ),
            _buildInfoRow(
              Icons.circle,
              'Status',
              player.isActive == true ? 'Active' : 'Inactive',
            ),
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
              'Pricing',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (category == null)
              Text(
                'No pricing category assigned',
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

  Widget _buildPromotionsCard(List<PromotionPricingModel> promotions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Promotions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...promotions.map((promo) => _buildPromotionTile(promo)),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionTile(PromotionPricingModel promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promo.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (promo.description != null && promo.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              promo.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPromoChip('${promo.sessionsCount} sessions'),
              const SizedBox(width: 8),
              if (promo.freeSessions > 0)
                _buildPromoChip('${promo.freeSessions} free'),
              const SizedBox(width: 8),
              _buildPromoChip(_formatDiscount(promo)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDiscount(PromotionPricingModel promo) {
    switch (promo.discountType) {
      case 'percentage':
        return '${promo.discountValue.toStringAsFixed(0)}% off';
      case 'fixed':
        return 'RM ${promo.discountValue.toStringAsFixed(0)} off';
      case 'bundle':
        return 'Bundle deal';
      default:
        return promo.discountType;
    }
  }
}
