import 'dart:io' as io;

import 'package:connectrpc/connect.dart' show HttpClient;
import 'package:connectrpc/io.dart' as connect_io;

/// The native HTTP client (mobile, desktop).
HttpClient createHttpClient() => connect_io.createHttpClient(io.HttpClient());
