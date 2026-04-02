
class Endpoint {
  Endpoint._();

  static var apiBaseUrl =
      '';

  static const getCategoriesEndpoint = '/categories';
  static const getCategoryByIdEndpoint = '/categories';


  static const connectionTimeout = Duration(seconds: 40);
  static const receiveTimeout = Duration(seconds: 40);

}
