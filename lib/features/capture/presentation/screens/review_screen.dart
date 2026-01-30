import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/extraction_result.dart';
import '../../../../shared/models/subscription.dart';
import '../providers/capture_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String imageData;
  final String filename;
  final String mimeType;

  const ReviewScreen({
    super.key,
    required this.imageData,
    required this.filename,
    required this.mimeType,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _billingEntityController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _renewalTermsController;
  late TextEditingController _cancellationPolicyController;

  BillingCycle _billingCycle = BillingCycle.monthly;
  String _currency = 'USD';
  DateTime? _nextChargeDate;
  DateTime? _startDate;
  DateTime? _cancellationDeadline;

  bool _isProcessing = true;
  bool _isSaving = false;
  String? _error;
  ExtractionResult? _extraction;
  String? _subscriptionId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _billingEntityController = TextEditingController();
    _paymentMethodController = TextEditingController();
    _renewalTermsController = TextEditingController();
    _cancellationPolicyController = TextEditingController();

    // Delay processing until after widget tree is built to avoid Riverpod state modification error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _billingEntityController.dispose();
    _paymentMethodController.dispose();
    _renewalTermsController.dispose();
    _cancellationPolicyController.dispose();
    super.dispose();
  }

  Future<void> _processImage() async {
    final notifier = ref.read(captureNotifierProvider.notifier);

    final response = await notifier.processImage(
      imageBase64: widget.imageData,
      filename: widget.filename,
      mimeType: widget.mimeType,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      if (response.success && response.extraction != null) {
        _extraction = response.extraction;
        _subscriptionId = response.subscription?.id;
        _populateForm(response.extraction!);
      } else {
        _error = response.error ?? 'Failed to extract data';
      }
    });
  }

  void _populateForm(ExtractionResult extraction) {
    _nameController.text = extraction.subscriptionName;
    _amountController.text = extraction.amount.toString();
    _billingEntityController.text = extraction.billingEntity ?? '';
    _paymentMethodController.text = extraction.paymentMethod ?? '';
    _renewalTermsController.text = extraction.renewalTerms ?? '';
    _cancellationPolicyController.text = extraction.cancellationPolicy ?? '';
    _billingCycle = extraction.billingCycle;
    _currency = extraction.currency;
    _nextChargeDate = extraction.nextChargeDate;
    _startDate = extraction.startDate;
    _cancellationDeadline = extraction.cancellationDeadline;
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final extraction = ExtractionResult(
      subscriptionName: _nameController.text.trim(),
      billingEntity: _billingEntityController.text.trim().isEmpty
          ? null
          : _billingEntityController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      currency: _currency,
      billingCycle: _billingCycle,
      startDate: _startDate,
      nextChargeDate: _nextChargeDate,
      paymentMethod: _paymentMethodController.text.trim().isEmpty
          ? null
          : _paymentMethodController.text.trim(),
      renewalTerms: _renewalTermsController.text.trim().isEmpty
          ? null
          : _renewalTermsController.text.trim(),
      cancellationPolicy: _cancellationPolicyController.text.trim().isEmpty
          ? null
          : _cancellationPolicyController.text.trim(),
      cancellationDeadline: _cancellationDeadline,
      confidenceScore: _extraction?.confidenceScore ?? 1.0,
      rawText: _extraction?.rawText ?? '',
    );

    final notifier = ref.read(captureNotifierProvider.notifier);
    final result = await notifier.saveWithEdits(extraction);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      notifier.reset();
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save subscription'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('review_screen'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Details'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(captureNotifierProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: _isProcessing
          ? _buildProcessingState()
          : _error != null
              ? _buildErrorState()
              : _buildForm(),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Receipt preview
          Container(
            width: 150,
            height: 200,
            margin: const EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: MemoryImage(base64Decode(widget.imageData)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Analyzing receipt...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is extracting subscription details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This may take 15-30 seconds for complex receipts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isTimeout = _error?.toLowerCase().contains('timeout') ?? false;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTimeout ? Icons.timer_off_outlined : Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              isTimeout ? 'Request Timed Out' : 'Extraction Failed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isTimeout) ...[
              const SizedBox(height: 16),
              Text(
                'Tip: Try using a clearer image or a simpler receipt format',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt thumbnail
            GestureDetector(
              onTap: () => _showFullImage(),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      child: Image.memory(
                        base64Decode(widget.imageData),
                        width: 90,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receipt Image',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view full size',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          _buildConfidenceBadge(),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Subscription name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subscription Name *',
                hintText: 'e.g., Netflix, Spotify',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the subscription name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Amount and currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      prefixText: '\$ ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _currency = value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Billing cycle
            DropdownButtonFormField<BillingCycle>(
              value: _billingCycle,
              decoration: const InputDecoration(
                labelText: 'Billing Cycle',
              ),
              items: BillingCycle.values.map((cycle) {
                return DropdownMenuItem(
                  value: cycle,
                  child: Text(cycle.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _billingCycle = value);
              },
            ),

            const SizedBox(height: 16),

            // Next charge date
            _buildDateField(
              label: 'Next Charge Date',
              value: _nextChargeDate,
              onChanged: (date) => setState(() => _nextChargeDate = date),
            ),

            const SizedBox(height: 16),

            // Billing entity
            TextFormField(
              controller: _billingEntityController,
              decoration: const InputDecoration(
                labelText: 'Billing Entity',
                hintText: 'Company name',
              ),
            ),

            const SizedBox(height: 16),

            // Payment method
            TextFormField(
              controller: _paymentMethodController,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                hintText: 'e.g., Visa ****1234',
              ),
            ),

            const SizedBox(height: 24),

            // Expandable section for more fields
            ExpansionTile(
              title: const Text('Additional Details'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDateField(
                  label: 'Start Date',
                  value: _startDate,
                  onChanged: (date) => setState(() => _startDate = date),
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'Cancellation Deadline',
                  value: _cancellationDeadline,
                  onChanged: (date) =>
                      setState(() => _cancellationDeadline = date),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _renewalTermsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Renewal Terms',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cancellationPolicyController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Cancellation Policy',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              key: const Key('confirm_button'),
              onPressed: _isSaving ? null : _saveSubscription,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Subscription'),
            ),

            const SizedBox(height: 16),

            // Retake button
            OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      ref.read(captureNotifierProvider.notifier).reset();
                      context.pop();
                    },
              child: const Text('Retake Photo'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final score = _extraction?.confidenceScore ?? 0;
    final isHigh = score >= 0.8;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isHigh ? AppColors.success : AppColors.warning).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHigh ? Icons.verified : Icons.info_outline,
            size: 14,
            color: isHigh ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isHigh ? 'High confidence' : 'Review recommended',
            style: TextStyle(
              fontSize: 12,
              color: isHigh ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  surface: AppColors.surface,
                ),
              ),
              child: child!,
            );
          },
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          value != null
              ? DateFormat('MMM d, yyyy').format(value)
              : 'Select date',
          style: TextStyle(
            color: value != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showFullImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.memory(
                base64Decode(widget.imageData),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
