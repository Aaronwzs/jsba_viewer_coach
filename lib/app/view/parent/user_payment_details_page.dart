import 'package:auto_route/auto_route.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jsba_app/app/model/training_model.dart';
import 'package:jsba_app/app/model/user_payment_model.dart';
import 'package:jsba_app/app/service/storage_service.dart';
import 'package:jsba_app/app/viewmodel/billing_view_model.dart';
import 'package:jsba_app/app/assets/theme/app_theme.dart';

@RoutePage()
class UserPaymentDetailsPage extends StatefulWidget {
  final String id;

  const UserPaymentDetailsPage({super.key, @PathParam('id') required this.id});

  @override
  State<UserPaymentDetailsPage> createState() => _UserPaymentDetailsPageState();
}

class _UserPaymentDetailsPageState extends State<UserPaymentDetailsPage> {
  UserPaymentModel? _payment;
  List<TrainingModel> _sessions = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayment();
    });
  }

  Future<void> _loadPayment() async {
    setState(() => _isLoading = true);
    final billingVM = context.read<BillingViewModel>();
    // Prefer the already-loaded list entry, otherwise fetch directly so a
    // deep link / notification navigation still resolves the record.
    UserPaymentModel? payment;
    try {
      payment = billingVM.userPayments.firstWhere((p) => p.id == widget.id);
    } catch (_) {
      payment = await billingVM.getUserPaymentById(widget.id);
    }
    if (!mounted) {
      return;
    }
    List<TrainingModel> sessions = [];
    if (payment != null) {
      try {
        sessions = await billingVM.getSessionsForPayment(payment);
      } catch (_) {
        sessions = [];
      }
    }
    if (!mounted) return;
    setState(() {
      _payment = payment;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  /// The three-tier status of a payment:
  /// - 'notUploaded': no proof attached yet
  /// - 'pending': proof uploaded, awaiting admin approval
  /// - 'approved' / 'rejected': decision made by admin
  String _effectiveStatus(UserPaymentModel payment) {
    if (payment.uploadProof == null) return 'notUploaded';
    return payment.paymentStatus;
  }

  @override
  Widget build(BuildContext context) {
    if (_payment == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Payment',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Payment not found')),
      );
    }

    final payment = _payment!;
    final status = _effectiveStatus(payment);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSessionsSection(payment),
          const SizedBox(height: 16),
          _buildPricingBreakdown(payment),
          const SizedBox(height: 16),
          _buildUploadSection(payment, status),
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNotesCard(payment),
          ],
          if (payment.paymentStatus == 'approved' &&
              payment.approvedAt != null) ...[
            const SizedBox(height: 16),
            _buildApprovedCard(payment),
          ],
          if (payment.paymentStatus == 'rejected') ...[
            const SizedBox(height: 16),
            _buildRejectedCard(payment),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionsSection(UserPaymentModel payment) {
    final sessions = _sessions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Training Sessions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sessions.length}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              Text(
                'No training sessions linked to this payment.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              )
            else
              ...sessions.map((t) => _buildSessionCard(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(TrainingModel training) {
    final classTypeLabel = training.classType.toUpperCase();
    final classTypeColor = switch (training.classType) {
      'private' => Colors.purple,
      'group' => Colors.deepOrange,
      'skill' => Colors.teal,
      'physical' => Colors.indigo,
      _ => AppTheme.primaryColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: classTypeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  training.className,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d, yyyy').format(training.date)} · '
                  '${training.startTime} (${training.durationMinutes} min)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: classTypeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              classTypeLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: classTypeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(UserPaymentModel payment) {
    final subtotal = payment.subtotal > 0 ? payment.subtotal : payment.totalAmt;
    final discountTotal = payment.discounts.fold<double>(
      0,
      (sum, d) => sum + d.amount,
    );
    final total = payment.totalAmt > 0 ? payment.totalAmt : payment.amount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 14)),
                Text(
                  '${payment.currency} ${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (discountTotal > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '- ${payment.currency} ${discountTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              ...payment.discounts.map((d) {
                final name = d.promotionName ?? d.configType;
                return Padding(
                  padding: const EdgeInsets.only(top: 2, left: 8),
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                );
              }),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${payment.currency} ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection(UserPaymentModel payment, String status) {
    final hasProof = payment.uploadProof != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Proof',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (hasProof) ...[
              ..._buildReferenceProofs(
                payment.uploadProof != null ? [payment.uploadProof!] : [],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: status == 'pending'
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: status == 'pending'
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'pending'
                          ? Icons.hourglass_top
                          : Icons.verified,
                      size: 18,
                      color: status == 'pending'
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status == 'pending'
                            ? 'Proof uploaded — awaiting admin approval'
                            : 'Proof received and approved',
                        style: TextStyle(
                          fontSize: 13,
                          color: status == 'pending'
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No proof uploaded yet. Upload a screenshot of your payment.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isUploading ? null : () => _onUploadPressed(payment),
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  hasProof ? 'Re-upload Proof' : 'Upload Proof',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onUploadPressed(UserPaymentModel payment) async {
    // If a proof image already exists, confirm the user wants to replace it.
    if (payment.uploadProof != null) {
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update existing proof?'),
          content: const Text(
            'You already have an image uploaded. Do you want to update it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (shouldUpdate != true) return;
      if (!mounted) return;

      // Second confirmation before proceeding with the re-upload.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace proof?'),
          content: const Text(
            'Your current proof will be replaced by the new image you choose. '
            'Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }

    await _pickAndUpload(payment);
  }

  Future<void> _pickAndUpload(UserPaymentModel payment) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (!mounted) return;

    final billingVM = context.read<BillingViewModel>();
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() => _isUploading = true);
    try {
      final url = await StorageService().uploadImage(
        bytes,
        fileName: 'payment_${payment.id}.jpg',
      );
      final success = await billingVM.uploadUserPaymentProof(
        paymentId: payment.id,
        url: url,
      );
      if (!mounted) return;
      if (success) {
        final updated = billingVM.userPayments
            .firstWhere((p) => p.id == payment.id,
                orElse: () => payment);
        setState(() => _payment = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof uploaded — awaiting approval'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(billingVM.error ?? 'Failed to upload proof'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }




  Widget _buildNotesCard(UserPaymentModel payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(payment.notes!, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedCard(UserPaymentModel payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Approved',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Approved on ${DateFormat('MMM d, yyyy').format(payment.approvedAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedCard(UserPaymentModel payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel, color: Colors.red.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Payment Rejected',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${payment.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Please submit a new payment with correct details.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    final path = Uri.tryParse(lower)?.path ?? lower;
    if (path.endsWith('.pdf')) return false;
    return lower.contains('ik.imagekit.io') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  String _fileNameFromUrl(String url) {
    try {
      return url.split('/').last;
    } catch (_) {
      return url;
    }
  }

  List<Widget> _buildReferenceProofs(List<String> urls) {
    return urls.map((url) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: _isImageUrl(url)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFileRefTile(url);
                  },
                ),
              )
            : _buildFileRefTile(url),
      );
    }).toList();
  }

  Widget _buildFileRefTile(String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
            const SizedBox(width: 6),
            Text(
              _fileNameFromUrl(url),
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 14, color: Colors.blue.shade400),
          ],
        ),
      ),
    );
  }

}
