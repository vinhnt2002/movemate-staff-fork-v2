import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:auto_route/auto_route.dart';
import 'package:movemate_staff/configs/routes/app_router.dart';
import 'package:movemate_staff/features/drivers/presentation/controllers/driver_controller/driver_controller.dart';
import 'package:movemate_staff/features/job/domain/entities/booking_response_entity/booking_response_entity.dart';
import 'package:movemate_staff/hooks/use_fetch.dart';
import 'package:movemate_staff/models/request/paging_model.dart';

@RoutePage()
class PorterScreen extends HookConsumerWidget {
  const PorterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverControllerProvider);
    final selectedDate = useState(DateTime.now());
    final fetchResult = useFetch<BookingResponseEntity>(
      function: (model, context) => ref
          .read(driverControllerProvider.notifier)
          .getBookingsByDriver(model, context),
      initialPagingModel: PagingModel(),
      context: context,
    );

    final jobs = _getJobsFromBookingResponseEntity(
        fetchResult.items, selectedDate.value);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch trình công việc',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Week View (Horizontal Scroll)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = DateTime.now().add(Duration(days: index));
                final isSelected = DateFormat.yMd().format(day) ==
                    DateFormat.yMd().format(selectedDate.value);
                return GestureDetector(
                  onTap: () {
                    selectedDate.value = day;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: Colors.orange.shade200,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.E().format(day),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DateFormat.d().format(day),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final startTime =
                    DateFormat('MM/dd/yyyy HH:mm:ss').parse(job.bookingAt);
                final endTime = startTime.add(
                  Duration(
                      minutes: int.parse(job.estimatedDeliveryTime ?? '0')),
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Indicator and Timeline Line
                    Column(
                      children: [
                        Text(
                          DateFormat.Hm().format(startTime),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        if (index < jobs.length - 1)
                          Container(
                            height: 80,
                            width: 2,
                            color: Colors.orange.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Job Card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.router
                              .push(PorterDetailScreenRoute(job: job));
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: job.status == 'Đã vận chuyển'
                                    ? [
                                        Colors.green.shade700,
                                        Colors.green.shade400
                                      ]
                                    : [
                                        Colors.orange.shade700,
                                        Colors.orange.shade400
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      job.id.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: job.status == 'Đã vận chuyển'
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        job.status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.white70, size: 18),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${DateFormat.Hm().format(startTime)} - ${DateFormat.Hm().format(endTime)}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.white70, size: 18),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        job.pickupAddress,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.flag,
                                        color: Colors.white70, size: 18),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        job.deliveryAddress,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  List<BookingResponseEntity> _getJobsFromBookingResponseEntity(
      List<BookingResponseEntity> bookingResponseEntities,
      DateTime selectedDate) {
    return bookingResponseEntities
        .where((entity) =>
            DateFormat('MM/dd/yyyy').parse(entity.bookingAt).day ==
                selectedDate.day &&
            DateFormat('MM/dd/yyyy').parse(entity.bookingAt).month ==
                selectedDate.month &&
            DateFormat('MM/dd/yyyy').parse(entity.bookingAt).year ==
                selectedDate.year)
        .toList();
  }
}
