import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/feedback_bloc.dart';
import '../bloc/feedback_event.dart';
import '../bloc/feedback_state.dart';
import '../models/feedback_submission.dart';
import '../repositories/feedback_repository.dart';

Future<bool?> showFeedbackBottomSheet(
  BuildContext context, {
  FeedbackContextType contextType = FeedbackContextType.general,
  String? contextId,
  String? contextTitle,
}) {
  final repo = context.read<FeedbackRepository>();
  String? prefillEmail;
  try {
    prefillEmail = context.read<AuthBloc>().state.user?.email;
  } catch (_) {}

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return BlocProvider(
        create: (_) => FeedbackBloc(repository: repo)
          ..add(FeedbackReset(
            contextType: contextType,
            contextId: contextId,
            contextTitle: contextTitle,
            contactEmail: prefillEmail,
          )),
        child: FeedbackBottomSheet(
          contextType: contextType,
          contextTitle: contextTitle,
        ),
      );
    },
  );
}

class FeedbackBottomSheet extends StatefulWidget {
  final FeedbackContextType contextType;
  final String? contextTitle;

  const FeedbackBottomSheet({
    super.key,
    required this.contextType,
    this.contextTitle,
  });

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  late final TextEditingController _messageController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<FeedbackBloc>();
    _messageController = TextEditingController(text: bloc.state.submission.message);
    _emailController = TextEditingController(text: bloc.state.submission.contactEmail ?? '');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: BlocConsumer<FeedbackBloc, FeedbackState>(
              listener: (context, state) {
                // If needed, listener can react to states
              },
              builder: (context, state) {
                if (state.status == FeedbackStatus.success) {
                  return _buildSuccessView(context);
                }

                return _buildFormView(context, state);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      key: const Key('feedback_success_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF86EFAC), width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 44,
            color: Color(0xFF15803D),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Paldies par Tavu ziņojumu!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Mēs izskatīsim Tavu ieteikumu un nepieciešamības gadījumā atjaunosim informāciju.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            key: const Key('feedback_success_close_button'),
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
            ),
            child: const Text(
              'Aizvērt',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView(BuildContext context, FeedbackState state) {
    final bloc = context.read<FeedbackBloc>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Galvene ar aizvēršanas pogu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Ziņot par kļūdu vai labojumu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            IconButton(
              key: const Key('feedback_close_button'),
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),

        // Konteksta norāde
        if (widget.contextTitle != null && widget.contextTitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.contextType == FeedbackContextType.event
                      ? Icons.calendar_today_outlined
                      : Icons.place_outlined,
                  size: 14,
                  color: AppColors.primaryViolet,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${widget.contextType.label}: ${widget.contextTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Kategorijas izvēle
        const Text(
          'Ziņojuma veids',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FeedbackCategory.values.map((cat) {
            final isSelected = state.submission.category == cat;
            return ChoiceChip(
              key: Key('feedback_category_${cat.apiValue}'),
              label: Text(cat.label),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: const Color(0xFFF5F3FF),
              backgroundColor: AppColors.cardWhite,
              side: BorderSide(
                color: isSelected ? AppColors.primaryViolet : AppColors.borderSubtle,
                width: isSelected ? 1.5 : 1,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryViolet : AppColors.textSecondary,
              ),
              onSelected: (_) {
                bloc.add(FeedbackCategoryChanged(cat));
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Ziņojuma lauks
        const Text(
          'Komentārs vai apraksts *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('feedback_message_input'),
          controller: _messageController,
          maxLines: 4,
          onChanged: (val) => bloc.add(FeedbackMessageChanged(val)),
          decoration: InputDecoration(
            hintText: 'Aprakstiet, kas būtu jāprecizē vai kāda kļūda radās...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundLight,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              borderSide: const BorderSide(color: AppColors.primaryViolet, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // E-pasta lauks (neobligāts)
        const Text(
          'Tavs e-pasts (neobligāts saziņai)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('feedback_email_input'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (val) => bloc.add(FeedbackEmailChanged(val)),
          decoration: InputDecoration(
            hintText: 'piemers@epasts.lv',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              borderSide: const BorderSide(color: AppColors.primaryViolet, width: 1.5),
            ),
          ),
        ),

        // Kļūdas paziņojums
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Iesniegšanas poga
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            key: const Key('feedback_submit_button'),
            onPressed: state.status == FeedbackStatus.submitting
                ? null
                : () {
                    bloc.add(const FeedbackSubmitted());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryViolet,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
            ),
            child: state.status == FeedbackStatus.submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Nosūtīt ziņojumu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
