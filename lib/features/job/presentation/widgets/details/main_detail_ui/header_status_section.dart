// Flutter and external packages
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Routing
import 'package:movemate_staff/configs/routes/app_router.dart';
import 'package:movemate_staff/features/job/data/model/request/resource.dart';

// Data models and entities
import 'package:movemate_staff/features/job/data/model/request/reviewer_status_request.dart';
import 'package:movemate_staff/features/job/data/model/request/reviewer_time_request.dart';
import 'package:movemate_staff/features/job/domain/entities/booking_response_entity/booking_response_entity.dart';
import 'package:movemate_staff/features/job/domain/entities/image_data.dart';

// Controllers
import 'package:movemate_staff/features/job/presentation/controllers/reviewer_update_controller/reviewer_update_controller.dart';
import 'package:movemate_staff/features/job/presentation/providers/booking_provider.dart';

// Widgets
import 'package:movemate_staff/features/job/presentation/widgets/dialog_schedule/schedule_dialog.dart';
import 'package:movemate_staff/features/job/presentation/widgets/image_button/room_media_section.dart';
import 'package:movemate_staff/utils/commons/widgets/form_input/label_text.dart';

// Hooks
import 'package:movemate_staff/hooks/use_booking_status.dart';
import 'package:movemate_staff/hooks/use_fetch.dart';

// Services
import 'package:movemate_staff/services/realtime_service/booking_status_realtime/booking_status_stream_provider.dart';

// Constants
import 'package:movemate_staff/utils/constants/asset_constant.dart';

class BookingHeaderStatusSection extends HookConsumerWidget {
  final bool isReviewOnline;
  final BookingResponseEntity job;
  final FetchResult<BookingResponseEntity> fetchResult;

  const BookingHeaderStatusSection({
    super.key,
    required this.isReviewOnline,
    required this.job,
    required this.fetchResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingStreamProvider(job.id.toString()));
    final bookingStatus = useBookingStatus(bookingAsync.value, isReviewOnline);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusMessage(bookingStatus.statusMessage),
          const SizedBox(height: 12),
          _buildTimeline(context, bookingStatus, ref),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(String statusMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusMessage,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTimeline(
      BuildContext context, BookingStatusResult bookingStatus, WidgetRef ref) {
    final steps = isReviewOnline
        ? _buildOnlineReviewerSteps(bookingStatus, context, ref)
        : _buildOfflineReviewerSteps(bookingStatus, context, ref);

    return Wrap(
      spacing: 8,
      runSpacing: 16,
      children: _buildTimelineRows(steps),
    );
  }

  List<_TimelineStep> _buildOnlineReviewerSteps(
      BookingStatusResult status, BuildContext context, WidgetRef ref) {
    bool isStepCompleted(int currentStep, List<bool> conditions) {
      for (int i = currentStep; i < conditions.length; i++) {
        if (conditions[i]) return true;
      }
      return false;
    }

    final progressionStates = [
      status.canConfirmReview,
      status.canUpdateServices,
      status.canConfirmSuggestion,
      status.isReviewed,
      status.isWaitingPayment,
      status.isCompleted,
    ];

    return [
      _TimelineStep(
        title: 'Phân công',
        icon: Icons.assignment_ind,
        isActive: status.canConfirmReview,
        isCompleted: isStepCompleted(1, progressionStates),
        action: status.canConfirmReview ? 'Xác nhận' : null,
        onPressed: status.canConfirmReview
            ? () => _confirmReviewAssignment(context, ref)
            : null,
      ),
      _TimelineStep(
        title: 'Cập nhật đơn',
        icon: Icons.edit,
        isActive: status.canUpdateServices,
        isCompleted: isStepCompleted(2, progressionStates),
        action: status.canUpdateServices ? 'Cập nhật' : null,
        onPressed: status.canUpdateServices
            ? () => _navigateToServiceUpdate(context, ref)
            : null,
      ),
      _TimelineStep(
        title: 'Đề xuất',
        icon: Icons.description,
        isActive: status.canConfirmSuggestion,
        isCompleted: isStepCompleted(3, progressionStates),
        action: status.canConfirmSuggestion ? 'Hoàn thành' : null,
        onPressed: status.canConfirmSuggestion
            ? () => _completeProposal(context, ref)
            : null,
      ),
      _TimelineStep(
        title: 'Đã đánh giá xog',
        icon: Icons.rate_review,
        isActive: status.isReviewed,
        isCompleted: isStepCompleted(4, progressionStates),
      ),
      _TimelineStep(
        title: 'Chờ khách',
        icon: Icons.payment,
        isActive: status.isWaitingPayment,
        isCompleted: isStepCompleted(5, progressionStates),
      ),
      _TimelineStep(
        title: 'Hoàn tất',
        icon: Icons.check_circle,
        isActive: status.isCompleted,
        isCompleted: false,
      ),
    ];
  }

  List<_TimelineStep> _buildOfflineReviewerSteps(
      BookingStatusResult status, BuildContext context, WidgetRef ref) {
    bool isStepCompleted(int currentStep, List<bool> conditions) {
      for (int i = currentStep; i < conditions.length; i++) {
        if (conditions[i]) return true;
      }
      return false;
    }

    final progressionStates = [
      status.canCreateSchedule,
      status.isWaitingCustomer || status.isWaitingPayment,
      status.canConfirmMoving,
      status.isStaffEnroute,
      status.canUpdateServices,
      status.canConfirmSuggestion,
      status.isReviewed,
    ];

    return [
      _TimelineStep(
        title: 'Xếp lịch',
        icon: Icons.calendar_today,
        isActive: status.canCreateSchedule,
        isCompleted: isStepCompleted(1, progressionStates),
        action: status.canCreateSchedule ? 'Hẹn' : null,
        onPressed: status.canCreateSchedule
            ? () => _showScheduleDialog(context, ref)
            : null,
      ),
      _TimelineStep(
        title: 'Chờ khách',
        icon: Icons.people,
        isActive: status.isWaitingCustomer || status.isWaitingPayment,
        isCompleted: isStepCompleted(2, progressionStates),
      ),
      _TimelineStep(
        title: 'Di chuyển',
        icon: Icons.directions_car,
        isActive: status.canConfirmMoving,
        isCompleted: isStepCompleted(3, progressionStates),
        action: status.canConfirmMoving ? 'Bắt đầu' : null,
        onPressed:
            status.canConfirmMoving ? () => _confirmMoving(context, ref) : null,
      ),
      _TimelineStep(
        title: 'Đang đến',
        icon: Icons.near_me,
        isActive: status.isStaffEnroute,
        isCompleted: isStepCompleted(4, progressionStates),
        action: status.canConfirmArrival ? 'Đã tới' : null,
        onPressed: status.canConfirmArrival
            ? () => _confirmArrival(context, ref)
            : null,
      ),
      _TimelineStep(
        title: 'Cập nhật dịch vụ',
        icon: Icons.edit,
        isActive: status.canUpdateServices,
        isCompleted: isStepCompleted(5, progressionStates),
        action: status.canUpdateServices ? 'Cập nhật' : null,
        onPressed: status.canUpdateServices
            ? () => _navigateToServiceUpdate(context, ref)
            : null,
      ),
      _TimelineStep(
        title: 'Đề xuất',
        icon: Icons.description,
        isActive: status.canConfirmSuggestion,
        isCompleted: isStepCompleted(6, progressionStates),
        action: status.canConfirmSuggestion ? 'Hoàn thành' : null,
        onPressed: status.canConfirmSuggestion
            ? () => _completeProposal(context, ref)
            : null,
      ),
      _TimelineStep(
        title: 'Hoàn tất',
        icon: Icons.check_circle,
        isActive: status.isReviewed,
        isCompleted: false,
      ),
    ];
  }

  List<Widget> _buildTimelineRows(List<_TimelineStep> steps) {
    final rows = <Widget>[];
    const itemsPerRow = 4;

    for (var i = 0; i < steps.length; i += itemsPerRow) {
      final rowItems = steps.skip(i).take(itemsPerRow).toList();
      final isEvenRow = (i ~/ itemsPerRow) % 2 == 0;

      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ...rowItems
                .map((step) => Expanded(child: _buildTimelineItem(step))),
            if (rowItems.length < itemsPerRow)
              ...List.generate(
                  itemsPerRow - rowItems.length, (_) => const Spacer()),
          ],
        ),
      );

      if (i + itemsPerRow < steps.length) {
        rows.add(SizedBox(
          height: 20,
          child: CustomPaint(
              size: const Size(double.infinity, 20),
              painter: ZigzagConnectorPainter(isEvenRow: isEvenRow)),
        ));
      }
    }

    return rows;
  }

  Widget _buildTimelineItem(_TimelineStep step) {
    final color = step.isActive
        ? Colors.blue
        : step.isCompleted
            ? Colors.green
            : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: color.withOpacity(0.1)),
          child: Icon(step.isCompleted ? Icons.check : step.icon,
              color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(step.title,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
        if (step.action != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: step.onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: color.withOpacity(0.1),
            ),
            child: Text(step.action!,
                style: TextStyle(color: color, fontSize: 11)),
          ),
        ],
      ],
    );
  }

  void _showScheduleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ScheduleDialog(
        orderId: job.id.toString(),
        onDateTimeSelected: (DateTime selectedDateTime) async {
          await ref
              .read(reviewerUpdateControllerProvider.notifier)
              .updateCreateScheduleReview(
                request: ReviewerTimeRequest(reviewAt: selectedDateTime),
                id: job.id,
                context: context,
              );
          fetchResult.refresh();
        },
      ),
    );
  }

  void _confirmReviewAssignment(BuildContext context, WidgetRef ref) =>
      _confirmAction(
          context, ref, "Xác nhận đánh giá", "Xác nhận", job.id.toString());
  void _confirmMoving(BuildContext context, WidgetRef ref) => _confirmAction(
      context, ref, "Bắt đầu di chuyển", "Bắt đầu", job.id.toString());
  void _confirmArrival(BuildContext context, WidgetRef ref) => _confirmAction(
      context, ref, "Xác nhận đã tới", "Đã tới", job.id.toString());

  void _confirmAction(BuildContext context, WidgetRef ref, String title,
      String action, String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        backgroundColor: AssetsConstants.whiteColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const LabelText(
                content: "Đóng",
                size: 16,
                fontWeight: FontWeight.bold,
                color: AssetsConstants.blackColor),
          ),
          TextButton(
            onPressed: () async {
              print("log here go");
              await ref
                  .read(reviewerUpdateControllerProvider.notifier)
                  .updateReviewerStatus(id: job.id, context: context);
              fetchResult.refresh();
              Navigator.pop(context);
            },
            child: LabelText(
                content: action,
                size: 16,
                fontWeight: FontWeight.bold,
                color: AssetsConstants.primaryLight),
          ),
        ],
      ),
    );
  }

  void _navigateToServiceUpdate(BuildContext context, WidgetRef ref) {
    context.router.push(GenerateNewJobScreenRoute(job: job));
  }

  void _completeProposal(BuildContext context, WidgetRef ref) {
    final timeController = TextEditingController();
    final timeTypeNotifier = ValueNotifier<String>('hour');

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header với gradient background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AssetsConstants.primaryLighter,
                        AssetsConstants.primaryLighter.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Xác nhận đề suất',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Hoàn thành tiến trình đánh giá',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Type Selection
                      ValueListenableBuilder(
                        valueListenable: timeTypeNotifier,
                        builder: (context, timeType, child) => Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: ['hour', 'minute'].map((type) {
                              final selected = timeType == type;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    timeTypeNotifier.value = type;
                                    timeController.clear();
                                  },
                                  child: Container(
                                    height: 50,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AssetsConstants.primaryLighter
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        type == 'hour' ? 'Giờ' : 'Phút',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time Input Field with floating label
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: timeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Thời gian dự kiến',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText: timeTypeNotifier.value == 'hour'
                                ? 'Giờ'
                                : 'Phút',
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: AssetsConstants.primaryLighter,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Room Media Section with modern styling
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AssetsConstants.primaryLighter
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: AssetsConstants.primaryLighter,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Tải ảnh lên',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const RoomMediaSection(
                              roomTitle: '',
                              roomType: RoomType.livingRoom,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Modern Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Đóng",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final inputTime =
                                    double.tryParse(timeController.text);
                                if (inputTime == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.warning_rounded,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                                'Vui lòng nhập thời gian hợp lệ'),
                                          ],
                                        ),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final estimatedTime =
                                    timeTypeNotifier.value == 'minute'
                                        ? inputTime / 60
                                        : inputTime;

                                final images =
                                    ref.read(bookingProvider).livingRoomImages;

                                // convert list image with type ImageData => Resource
                                List<Resource> convertImage(
                                    List<ImageData>? images) {
                                  return images!
                                      .map((image) => Resource(
                                            type: 'IMG',
                                            resourceUrl: image.url,
                                            resourceCode: 'LIVING_ROOM',
                                          ))
                                      .toList();
                                }

                                final resourseListReq = convertImage(images);
                                await ref
                                    .read(reviewerUpdateControllerProvider
                                        .notifier)
                                    .updateReviewerStatus(
                                      id: job.id,
                                      context: context,
                                      request: ReviewerStatusRequest(
                                        estimatedDeliveryTime: estimatedTime,
                                        resourceList: resourseListReq,
                                      ),
                                    );
                                fetchResult.refresh();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AssetsConstants.primaryLighter,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Xác nhận",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

//
//
}

class _TimelineStep {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final String? action;
  final VoidCallback? onPressed;

  _TimelineStep({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
    this.action,
    this.onPressed,
  });
}

class ZigzagConnectorPainter extends CustomPainter {
  final bool isEvenRow;

  ZigzagConnectorPainter({required this.isEvenRow});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final segmentWidth = size.width / 4;

    if (isEvenRow) {
      path.moveTo(segmentWidth / 2, 0);
      path.lineTo(size.width - segmentWidth / 2, size.height);
    } else {
      path.moveTo(size.width - segmentWidth / 2, 0);
      path.lineTo(segmentWidth / 2, size.height);
    }

    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
