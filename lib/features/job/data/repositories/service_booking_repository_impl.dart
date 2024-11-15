// service_booking_repository_impl.dart

import 'package:movemate_staff/features/job/data/model/queries/booking_queries.dart';
import 'package:movemate_staff/features/job/data/model/request/booking_requesst.dart';
import 'package:movemate_staff/features/job/data/model/request/reviewer_status_request.dart';
import 'package:movemate_staff/features/job/data/model/request/reviewer_time_request.dart';
import 'package:movemate_staff/features/job/data/model/response/booking_response.dart';
import 'package:movemate_staff/features/job/data/model/response/house_type_obj_response.dart';
import 'package:movemate_staff/features/job/data/model/response/house_type_response.dart';
import 'package:movemate_staff/features/job/data/model/response/services_fee_system_response.dart';
import 'package:movemate_staff/features/job/data/model/response/services_package_response.dart';
import 'package:movemate_staff/features/job/data/model/response/services_response.dart';
import 'package:movemate_staff/features/job/data/model/response/update_booking_response.dart';
import 'package:movemate_staff/features/job/data/remotes/booking_source.dart';
import 'package:movemate_staff/features/job/domain/repositories/service_booking_repository.dart';
import 'package:movemate_staff/models/request/paging_model.dart';
import 'package:movemate_staff/models/response/success_model.dart';
import 'package:movemate_staff/utils/commons/functions/shared_preference_utils.dart';
import 'package:movemate_staff/utils/constants/api_constant.dart';
import 'package:movemate_staff/utils/resources/remote_base_repository.dart';

class BookingRepositoryImpl extends RemoteBaseRepository
    implements BookingRepository {
  final bool addDelay;
  final BookingSource _bookingSource;

  BookingRepositoryImpl(this._bookingSource, {this.addDelay = true});

  @override
  Future<HouseTypeResponse> getHouseTypes({
    required PagingModel request,
    required String accessToken,
  }) async {
    return getDataOf(
      request: () =>
          _bookingSource.getHouseTypes(APIConstants.contentType, accessToken),
    );
  }

  @override
  Future<HouseTypeObjResponse> getHouseDetails({
    required String accessToken,
    required int id,
  }) async {
    print("repo log $id");
    return getDataOf(
      request: () => _bookingSource.getHouseDetails(
        APIConstants.contentType,
        accessToken,
        id,
      ),
    );
  }

  @override
  Future<ServicesResponse> getVehicle({
    required PagingModel request,
    required String accessToken,
  }) async {
    return getDataOf(
      request: () =>
          _bookingSource.getVehicle(APIConstants.contentType, accessToken),
    );
  }

  // Services Fee System Methods
  @override
  Future<ServicesFeeSystemResponse> getFeeSystems({
    required PagingModel request,
    required String accessToken,
  }) async {
    return getDataOf(
      request: () =>
          _bookingSource.getFeeSystems(APIConstants.contentType, accessToken),
    );
  }

  // Services Package Methods
  @override
  Future<ServicesPackageResponse> getServicesPackage({
    required PagingModel request,
    required String accessToken,
  }) async {
    return getDataOf(
      request: () => _bookingSource.getServicesPackage(
        APIConstants.contentType,
        accessToken,
      ),
    );
  }

  @override
  Future<UpdateBookingResponse> postBookingservice({
    required BookingUpdateRequest request,
    required String accessToken,
    required int id,
  }) {
    return getDataOf(
      request: () => _bookingSource.postBookingservice(
          request, APIConstants.contentType, accessToken, id),
    );
  }

  @override
  Future<BookingResponse> getBookingDetails({
    required String accessToken,
    required int id,
  }) async {
    return getDataOf(
      request: () => _bookingSource.getBookingDetails(
          APIConstants.contentType, accessToken, id),
    );
  }

  @override
  Future<BookingResponse> getBookings({
    required String accessToken,
    required PagingModel request,
  }) async {
    final user = await SharedPreferencesUtils.getInstance('user_token');
    final bookingQueries = BookingQueries(
      page: request.pageNumber,
      perPage: request.pageSize,
      userId: user!.id,
      IsReviewOnl: request.isReviewOnline,
    );

    return getDataOf(
      request: () => _bookingSource.getBookings(
          APIConstants.contentType, accessToken, bookingQueries),
    );
  }

  @override
  Future<BookingResponse> getBookingsDriver({
    required String accessToken,
    required PagingModel request,
  }) async {
    final bookingQueries = BookingQueries(
      page: request.pageNumber,
      perPage: request.pageSize,
    );

    return getDataOf(
      request: () => _bookingSource.getBookings(
          APIConstants.contentType, accessToken, bookingQueries),
    );
  }

  @override
  Future<BookingResponse> postValuationBooking({
    required BookingRequest request,
    required String accessToken,
  }) {
    return getDataOf(
      request: () => _bookingSource.postValuationBooking(
        request,
        APIConstants.contentType,
        accessToken,
      ),
    );
  }

  //reviewer state
  @override
  Future<SuccessModel> updateStateReviewer({
    required String accessToken,
    ReviewerStatusRequest? request,
    required int id,
  }) async {
    return getDataOf(
      request: () => _bookingSource.updateStateReviewer(
          APIConstants.contentType, accessToken, request, id),
    );
  }

  @override
  Future<SuccessModel> updateCreateScheduleReview({
    required String accessToken,
    required ReviewerTimeRequest request,
    required int id,
  }) async {
    print("repo log ${request.toJson()}");
    print("repo log $id");

    return getDataOf(
      request: () => _bookingSource.updateCreateScheduleReview(
          APIConstants.contentType, accessToken, request, id),
    );
  }
}
