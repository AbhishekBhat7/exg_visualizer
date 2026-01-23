import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ErrorHandler {
  static String handleError(dynamic error,
      [http.Response? response, Map<int, String>? customMessages]) {
    if (response != null && response.body.isNotEmpty) {
      try {
        final responseBody = json.decode(response.body);
        if (responseBody is Map && responseBody.containsKey('error')) {
          return responseBody['error'] ?? 'An unexpected error occurred.';
        } else if (responseBody is Map && responseBody.containsKey('message')) {
          return responseBody['message'] ?? 'An unexpected error occurred.';
        }
      } catch (e) {}
    }

    if (response != null && customMessages != null) {
      if (customMessages.containsKey(response.statusCode)) {
        return customMessages[response.statusCode]!;
      }
    }

    if (error is SocketException) {
      return 'Network error: Unable to connect. Please check your internet connection.';
    } else if (error is HttpException) {
      return 'Network error: Device offline or airplane mode detected.';
    } else if (error is TimeoutException) {
      return 'Request timed out: Server took too long to respond.';
    }

    if (response != null) {
      switch (response.statusCode) {
        case 400:
          return 'Invalid request: Please check your input and try again.';
        case 401:
          return 'Authentication failed: Invalid or missing credentials.';
        case 403:
          return 'Permission denied: You do not have access to this resource.';
        case 404:
          return 'Resource not found: The requested endpoint does not exist.';
        case 500:
          return 'Server error: An unexpected issue occurred on the server.';
        case 502:
          return 'Bad Gateway: Server gateway issue detected.';
        case 503:
          return 'Service Unavailable: Server is temporarily down.';
        case 504:
          return 'Gateway Timeout: Server gateway took too long to respond.';
      }
    }

    if (error is FormatException) {
      return 'Data error: Received malformed or unexpected data format.';
    }

    if (error.toString().contains('timeout')) {
      return 'Timeout: Request or response took too long to process.';
    }

    if (error.toString().toLowerCase().contains('token expired')) {
      return 'Session expired: Please log in again.';
    } else if (error.toString().toLowerCase().contains('invalid credentials')) {
      return 'Authentication error: Invalid credentials provided.';
    } else if (error.toString().toLowerCase().contains('permission')) {
      return 'Authorization error: Insufficient permissions.';
    }

    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
