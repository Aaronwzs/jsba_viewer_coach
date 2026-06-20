import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class ImageCropHelper {
  /// Crops an image from [sourcePath] and returns the cropped result.
  /// Works on both native and web.
  static Future<CroppedFile?> cropImage({
    required String sourcePath,
    required BuildContext context,
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        IOSUiSettings(
          title: '',
          aspectRatioLockEnabled: false,
          aspectRatioPickerButtonHidden: true,
          rotateButtonsHidden: true,
          rotateClockwiseButtonHidden: true,
          resetButtonHidden: true,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          hidesNavigationBar: true,
        ),
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          lockAspectRatio: false,
          hideBottomControls: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        WebUiSettings(context: context),
      ],
    );

    return croppedFile;
  }
}
