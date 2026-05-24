import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:flutter/material.dart';

Completer<AndroidMapRenderer?>? _initializedRendererCompleter;
Future<AndroidMapRenderer?>? _initializedRendererFuture;

/// Initializes map renderer to the `latest` renderer type for Android platform.
///
/// The renderer must be requested before creating GoogleMap instances,
/// as the renderer can be initialized only once per application context.
Future<AndroidMapRenderer?> initializeMapRenderer() async {
  if (_initializedRendererFuture != null) {
    return _initializedRendererFuture!;
  }

  final completer = Completer<AndroidMapRenderer?>();
  _initializedRendererCompleter = completer;
  _initializedRendererFuture = completer.future;

  WidgetsFlutterBinding.ensureInitialized();

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    try {
      final AndroidMapRenderer initializedRenderer = await mapsImplementation
          .initializeWithRenderer(AndroidMapRenderer.latest);
      if (!completer.isCompleted) {
        completer.complete(initializedRenderer);
      }
    } on PlatformException catch (error) {
      if (error.message?.contains('Renderer already initialized') == true) {
        if (!completer.isCompleted) {
          completer.complete(AndroidMapRenderer.latest);
        }
      } else {
        debugPrint('Map renderer initialization failed: $error');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    }
  } else {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }

  return completer.future;
}
