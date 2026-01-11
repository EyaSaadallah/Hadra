import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageKitService {
  final String _uploadUrl = "https://upload.imagekit.io/api/v1/files/upload";
  final String _filesUrl = "https://api.imagekit.io/v1/files";

  /// Uploads an image and returns the URL.
  Future<String?> uploadImage(
    File imageFile,
    String fileName, {
    String folder = 'hadra/profiles',
  }) async {
    try {
      final privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';

      if (privateKey.isEmpty) {
        throw Exception("ImageKit credentials missing in .env");
      }

      final auth = base64Encode(utf8.encode("$privateKey:"));
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: fileName,
        ),
      );

      request.fields['fileName'] = fileName;
      request.fields['useUniqueFileName'] = 'true';
      request.fields['folder'] = folder;

      request.headers.addAll({'Authorization': 'Basic $auth'});

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);
        return jsonResponse['url'];
      } else {
        print("ImageKit Upload Error: $responseData");
        return null;
      }
    } catch (e) {
      print("ImageKit Service Exception: $e");
      return null;
    }
  }

  /// Deletes an image from ImageKit given its URL.
  Future<bool> deleteImageByUrl(String fileUrl) async {
    try {
      final privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';
      if (privateKey.isEmpty || fileUrl.isEmpty) return false;

      final auth = base64Encode(utf8.encode("$privateKey:"));

      // 1. Find the file by its path/name
      final fileId = await _searchFileIdByUrl(fileUrl);
      if (fileId == null) {
        print("ImageKit: Could not find fileId for URL: $fileUrl");
        return false;
      }

      // 2. Delete using the fileId
      final response = await http.delete(
        Uri.parse("$_filesUrl/$fileId"),
        headers: {'Authorization': 'Basic $auth'},
      );

      print("ImageKit Delete Status: ${response.statusCode}");
      return response.statusCode == 204;
    } catch (e) {
      print("ImageKit Delete Error: $e");
      return false;
    }
  }

  /// Searches for a fileId in ImageKit based on the URL.
  Future<String?> _searchFileIdByUrl(String fileUrl) async {
    try {
      final privateKey = dotenv.env['IMAGEKIT_PRIVATE_KEY'] ?? '';
      final auth = base64Encode(utf8.encode("$privateKey:"));

      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;

      // ImageKit URL structure check: usually ik.imagekit.io/<ID>/folder/file.jpg
      // Search API needs the path relative to the bucket ROOT.

      final hadraIndex = segments.indexOf('hadra');
      if (hadraIndex == -1) {
        // Fallback: If 'hadra' isn't in segments (maybe old structure),
        // try to search by the filename itself.
        final fileName = segments.last;
        print("Fallback searching for filename: $fileName");
        return await _fetchIdByName(fileName, auth);
      }

      // ImageKit path MUST starts with a leading slash and be exact.
      final relativePath = "/" + segments.sublist(hadraIndex).join('/');

      // Try searching by specific path
      String? fileId = await _fetchIdByPath(relativePath, auth);

      // If path search fails (sometimes ImageKit paths are weird with IDs), fallback to searching by name
      if (fileId == null) {
        print("Path search failed, trying name search for: ${segments.last}");
        fileId = await _fetchIdByName(segments.last, auth);
      }

      return fileId;
    } catch (e) {
      print("ImageKit Search Error: $e");
      return null;
    }
  }

  Future<String?> _fetchIdByPath(String path, String auth) async {
    print("Searching ImageKit for EXACT path: $path");
    final response = await http.get(
      Uri.parse("$_filesUrl?path=$path"),
      headers: {'Authorization': 'Basic $auth'},
    );

    if (response.statusCode == 200) {
      final List results = jsonDecode(response.body);
      if (results.isNotEmpty) {
        print("Found fileId by path: ${results[0]['fileId']}");
        return results[0]['fileId'];
      }
    } else {
      print("Search by path failed with status: ${response.statusCode}");
    }
    return null;
  }

  Future<String?> _fetchIdByName(String name, String auth) async {
    print("Searching ImageKit for name: $name");
    // Use the search API to find the file by name
    final response = await http.get(
      Uri.parse("$_filesUrl?name=$name"),
      headers: {'Authorization': 'Basic $auth'},
    );

    if (response.statusCode == 200) {
      final List results = jsonDecode(response.body);
      if (results.isNotEmpty) {
        print("Found fileId by name: ${results[0]['fileId']}");
        return results[0]['fileId'];
      }
    } else {
      print("Search by name failed with status: ${response.statusCode}");
    }
    return null;
  }
}
