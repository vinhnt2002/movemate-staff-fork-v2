import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:movemate_staff/features/job/domain/entities/booking_response_entity/booking_response_entity.dart';
import 'package:movemate_staff/features/job/presentation/controllers/booking_controller/booking_controller.dart';
import 'package:movemate_staff/features/job/presentation/widgets/jobcard/job_card.dart';
import 'package:movemate_staff/hooks/use_fetch.dart';
import 'package:movemate_staff/models/request/paging_model.dart';
import 'package:movemate_staff/services/realtime_service/booking_status_realtime/booking_status_stream_provider.dart';
import 'package:movemate_staff/utils/commons/widgets/widgets_common_export.dart';
import 'package:movemate_staff/utils/constants/asset_constant.dart';
import 'package:movemate_staff/utils/enums/enums_export.dart';
import 'package:movemate_staff/utils/extensions/scroll_controller.dart';

@RoutePage()
class JobScreen extends HookConsumerWidget {
  final bool isReviewOnline;
  const JobScreen({
    super.key,
    required this.isReviewOnline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 4);
    final state = ref.watch(bookingControllerProvider);
    final size = MediaQuery.sizeOf(context);
    final scrollController = useScrollController();

    final fetchResult = useFetch<BookingResponseEntity>(
      function: (model, context) => ref
          .read(bookingControllerProvider.notifier)
          .getBookings(model, context),
      initialPagingModel: PagingModel(
        isReviewOnline: isReviewOnline,
      ),
      context: context,
    );

    List<String> tabs = [
      "Việc sắp tới",
      "Việc đã hoàn thành",
      "Tất cả",
      "Khác"
    ];

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).unfocus();
      });
      return null;
    }, []);
    final debounce = useRef<Timer?>(null);

    final statusAsync = ref.watch(orderStatusStreamProvider(
        fetchResult.items.map((e) => e.id).toString()));

    useEffect(() {
      scrollController.onScrollEndsListener(fetchResult.loadMore);
      statusAsync.whenData((status) {
        debounce.value?.cancel();
        debounce.value = Timer(const Duration(milliseconds: 300), () {
          fetchResult.refresh();
        });
      });

      return () {
        debounce.value?.cancel();
      };
    }, [statusAsync]);

    Widget buildTabContent(String tabName) {
      List<BookingResponseEntity> filteredBookings = [];

      switch (tabName) {
        case "Việc sắp tới":
          filteredBookings = fetchResult.items.where((booking) {
            final status = booking.status.toBookingTypeEnum();
            return [
              BookingStatusType.pending,
              BookingStatusType.assigned,
              BookingStatusType.approved,
              BookingStatusType.coming,
              BookingStatusType.waiting,
              BookingStatusType.inProgress,
            ].contains(status);
          }).toList();
          break;
        case "Việc đã hoàn thành":
          filteredBookings = fetchResult.items.where((booking) {
            final status = booking.status.toBookingTypeEnum();
            return status == BookingStatusType.reviewing;
          }).toList();
          break;
        case "Tất cả":
          filteredBookings = fetchResult.items.where((booking) {
            final status = booking.status.toBookingTypeEnum();
            return [
              BookingStatusType.pending,
              BookingStatusType.assigned,
              BookingStatusType.approved,
              BookingStatusType.coming,
              BookingStatusType.waiting,
              BookingStatusType.inProgress,
              BookingStatusType.reviewing,
              BookingStatusType.cancelled,
              BookingStatusType.refunded,
              BookingStatusType.depositing,
              BookingStatusType.reviewing,
              BookingStatusType.reviewed,
            ].contains(status);
          }).toList();
          break;
        default: // "Khác"
          filteredBookings = fetchResult.items.where((booking) {
            final status = booking.status.toBookingTypeEnum();
            return [
              BookingStatusType.cancelled,
              BookingStatusType.refunded,
              BookingStatusType.depositing,
              BookingStatusType.reviewing,
            ].contains(status);
          }).toList();
      }

      return Column(
        children: [
          SizedBox(height: size.height * 0.02),
          (state.isLoading && filteredBookings.isEmpty)
              ? const Center(
                  child: HomeShimmer(amount: 4),
                )
              : filteredBookings.isEmpty
                  ? const Align(
                      alignment: Alignment.topCenter,
                      child: EmptyBox(title: 'Không có dữ liệu'),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: filteredBookings.length + 1,
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AssetsConstants.defaultPadding - 10.0,
                        ),
                        itemBuilder: (_, index) {
                          if (index == filteredBookings.length) {
                            if (fetchResult.isFetchingData) {
                              return const CustomCircular();
                            }
                            return fetchResult.isLastPage
                                ? const NoMoreContent()
                                : Container();
                          }

                          return JobCard(
                            job: filteredBookings[index],
                            onCallback: fetchResult.refresh,
                          );
                        },
                      ),
                    ),
        ],
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        backgroundColor: AssetsConstants.mainColor,
        backButtonColor: AssetsConstants.whiteColor,
        title: "Công việc của tôi",
        iconFirst: Icons.refresh_rounded,
        iconSecond: Icons.filter_list_alt,
        onCallBackFirst: fetchResult.refresh,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: tabController,
              indicatorColor: Colors.orange,
              indicatorWeight: 2,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              tabs: tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: tabs.map((tab) => buildTabContent(tab)).toList(),
      ),
    );
  }
}
