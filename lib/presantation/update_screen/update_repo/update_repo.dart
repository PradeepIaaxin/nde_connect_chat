
import 'package:nde_email/presantation/update_screen/update_repo/update_model.dart';

import '../../../utils/dio/dio.dart';

class AppUpdateRepository {
  final NetworkUtils _networkUtils = NetworkUtils();
  Future<AppUpdateModel?> fetchAppDetails(String appName) async {
    final response = await _networkUtils.request(
      endpoint: '/admin/v1/appDetails/$appName',
      method: HttpMethod.get,
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      return AppUpdateModel.fromJson(response.data);
    }
    return null;
  }
}
