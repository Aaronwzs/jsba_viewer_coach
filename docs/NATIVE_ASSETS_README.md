Native Assets (Android / iOS)
=================================

Note: Android resource directories (android/app/src/main/res/*) only accept certain
file types (png, xml, etc). Do not place plain text README files in those directories.

Current instructions
- Android native launch image location (place the PNG here):
  android/app/src/main/res/drawable-nodpi/launch_image.png

- iOS LaunchImage imageset location:
  ios/Runner/Assets.xcassets/LaunchImage.imageset/

What I did in this branch
- Copied the project's master: assets/images/jsba_logo.png into
  android/app/src/main/res/drawable-nodpi/launch_image.png and into the
  iOS LaunchImage imageset.

If you need to add notes about these files, put them in docs/ (not inside res/).
