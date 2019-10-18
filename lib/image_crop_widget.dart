// Copyright 2019 Florian Bauer. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

library image_crop_widget;

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageCrop extends StatefulWidget {
  final ui.Image image;
  final BoxFit fit;
  final Alignment alignment;

  final Color overlayColor;
  final Color handleColor;

  ImageCrop({Key key,
    this.image,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.overlayColor = Colors.white,
    this.handleColor = Colors.white,})
      : assert(image != null),
        super(key: key);

  @override
  ImageCropState createState() => ImageCropState();
}

class ImageCropState extends State<ImageCrop> {

  double _handleSize = 64;

  /// Rotates the image clockwise by 90 degree.
  /// Completes when the rotation is done.
  Future<void> rotateImage() async {
    var pictureRecorder = ui.PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    canvas.rotate(pi / 2);
    canvas.translate(-0, -_state.image.height.toDouble());
    canvas.drawImage(_state.image, Offset.zero, Paint());

    final image = await pictureRecorder
        .endRecording()
        .toImage(_state.image.height, _state.image.width);

    setState(() {
      _state.image = image;
    });
  }

  /// Crops the image to the currently marked area.
  /// Returns a new [ui.Image].
  Future<ui.Image> cropImage() async {
    final yOffset =
        (_state.widgetSize.height - _state.fittedImageSize.destination.height) /
            2.0;
    final xOffset =
        (_state.widgetSize.width - _state.fittedImageSize.destination.width) /
            2.0;
    final fittedCropRect = Rect.fromCenter(
      center: Offset(
        _state.cropRect.center.dx - xOffset,
        _state.cropRect.center.dy - yOffset,
      ),
      width: _state.cropRect.width,
      height: _state.cropRect.height,
    );

    final scale =
        _state.imageSize.width / _state.fittedImageSize.destination.width;
    final imageCropRect = Rect.fromLTRB(
        fittedCropRect.left * scale,
        fittedCropRect.top * scale,
        fittedCropRect.right * scale,
        fittedCropRect.bottom * scale);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(
      _state.image,
      Offset(-imageCropRect.left, -imageCropRect.top),
      Paint(),
    );

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(
      imageCropRect.width.toInt(),
      imageCropRect.height.toInt(),
    );

    return croppedImage;
  }

  _SharedCropState _state = _SharedCropState();

  @override
  void initState() {
    super.initState();
    _state.image = widget.image;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: GestureDetector(
        child: CustomPaint(
          painter: _ImagePainter(_state, alignment: widget.alignment, fit: widget.fit),
          foregroundPainter: _OverlayPainter(_state, overlayColor: widget.overlayColor, handleColor: widget.handleColor),
        ),
        onPanDown: (event) {
          _onUpdate(event.globalPosition);
        },
        onPanStart: (event) {
          _onUpdate(event.globalPosition);
        },
        onPanUpdate: (event) {
          _onUpdate(event.globalPosition);
        },
        onPanEnd: (event) {
          setState(() {
            _state.lastTouchPosition = null;
            _state.touchPosition = null;
          });
        },
        onPanCancel: () {
          setState(() {
            _state.lastTouchPosition = null;
            _state.touchPosition = null;
          });
        },
        onDoubleTap: () => cropImage(),
      ),
    );
  }

  void _onUpdate(Offset globalPosition) {
    final RenderBox renderBox = context.findRenderObject();
    _state.lastTouchPosition = _state.touchPosition;
    _state.touchPosition = renderBox.globalToLocal(globalPosition);

    _updateCorners();
    setState(() {});
  }


  Rect _topLeft;
  void _updateCorners() {
    if (_state.topLeft == null ||
        _state.topLeft.center != _state.cropRect.topLeft) {
      _state.topLeft = Rect.fromCenter(
          center: _state.cropRect.topLeft, width: _handleSize, height: _handleSize);
    }

    if (_state.topRight == null ||
        _state.topRight.center != _state.cropRect.topRight) {
      _state.topRight = Rect.fromCenter(
          center: _state.cropRect.topRight, width: _handleSize, height: _handleSize);
    }

    if (_state.bottomLeft == null ||
        _state.bottomLeft.center != _state.cropRect.bottomLeft) {
      _state.bottomLeft = Rect.fromCenter(
          center: _state.cropRect.bottomLeft, width: _handleSize, height: _handleSize);
    }

    if (_state.bottomRight == null ||
        _state.bottomRight.center != _state.cropRect.bottomRight) {
      _state.bottomRight = Rect.fromCenter(
          center: _state.cropRect.bottomRight, width: _handleSize, height: _handleSize);
    }

    if (_state.lastTouchPosition == null && _state.touchPosition != null) {
      _state.topLeftActive = _state.topLeft.contains(_state.touchPosition);
      _state.topRightActive = _state.topRight.contains(_state.touchPosition);
      _state.bottomLeftActive =
          _state.bottomLeft.contains(_state.touchPosition);
      _state.bottomRightActive =
          _state.bottomRight.contains(_state.touchPosition);
    }

    if (_state.touchPosition != null) {
      if (_state.topLeftActive) {
        _state.topLeft = Rect.fromLTRB(
          max(
            _state.touchPosition.dx,
            _state.horizontalSpacing,
          ),
          max(
            _state.touchPosition.dy,
            _state.verticalSpacing,
          ),
          _state.cropRect.right,
          _state.cropRect.bottom,
        );
//
//        _state.cropRect = Rect.fromLTRB(
//          min(
//            max(
//              _state.touchPosition.dx,
//              _state.horizontalSpacing,
//            ),
//            _state.cropRect.right - _handleSize * 2,
//          ),
//          min(
//            max(
//              _state.touchPosition.dy,
//              _state.verticalSpacing,
//            ),
//            _state.cropRect.bottom - _handleSize * 2,
//          ),
//          _state.cropRect.right,
//          _state.cropRect.bottom,
//        );
      } else if (_state.topRightActive) {
        _state.cropRect = Rect.fromLTRB(
          _state.cropRect.left,
          min(
            max(
              _state.touchPosition.dy,
              _state.verticalSpacing,
            ),
            _state.cropRect.bottom - _handleSize * 2,
          ),
          max(
            min(
              _state.touchPosition.dx,
              _state.widgetSize.width - _state.horizontalSpacing,
            ),
            _state.cropRect.left + _handleSize * 2,
          ),
          _state.cropRect.bottom,
        );
      } else if (_state.bottomLeftActive) {
        _state.cropRect = Rect.fromLTRB(
          min(
            max(
              _state.touchPosition.dx,
              _state.horizontalSpacing,
            ),
            _state.cropRect.right - _handleSize * 2,
          ),
          _state.cropRect.top,
          _state.cropRect.right,
          max(
            min(
              _state.touchPosition.dy,
              _state.widgetSize.height - _state.verticalSpacing,
            ),
            _state.cropRect.top + _handleSize * 2,
          ),
        );
      } else if (_state.bottomRightActive) {
        _state.cropRect = Rect.fromLTRB(
          _state.cropRect.left,
          _state.cropRect.top,
          max(
            min(
              _state.touchPosition.dx,
              _state.widgetSize.width - _state.horizontalSpacing,
            ),
            _state.cropRect.left + _handleSize * 2,
          ),
          max(
            min(
              _state.touchPosition.dy,
              _state.widgetSize.height - _state.verticalSpacing,
            ),
            _state.cropRect.top + _handleSize * 2,
          ),
        );
      }
    }
  }
}

class _SharedCropState {
  ui.Image image;

  Offset touchPosition;
  Offset lastTouchPosition;
  Rect cropRect;

  Size widgetSize;
  Size imageSize;
  FittedSizes fittedImageSize;
  double horizontalSpacing;
  double verticalSpacing;

  Rect topLeft;
  Rect topRight;
  Rect bottomLeft;
  Rect bottomRight;
  bool topLeftActive = false;
  bool topRightActive = false;
  bool bottomLeftActive = false;
  bool bottomRightActive = false;
}

class _ImagePainter extends CustomPainter {
  final _SharedCropState state;
  final BoxFit fit;
  final Alignment alignment;
  final ui.Image image;

  _ImagePainter(this.state, {this.fit = BoxFit.cover, this.alignment = Alignment.center}) : image = state.image;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final displayRect = Rect.fromLTWH(0.0, 0.0, size.width, size.height);
    state.widgetSize = size;
    paintImage(
        canvas: canvas,
        image: state.image,
        rect: displayRect,
        fit: fit,
        alignment: alignment
    );
    state.imageSize = Size(
      state.image.width.toDouble(),
      state.image.height.toDouble(),
    );
    state.fittedImageSize = applyBoxFit(
      fit,
      state.imageSize,
      size,
    );
    state.horizontalSpacing =
        (state.widgetSize.width - state.fittedImageSize.destination.width) / 2;
    state.verticalSpacing =
        (state.widgetSize.height - state.fittedImageSize.destination.height) /
            2;
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    return image != oldDelegate.image;
  }
}

class _OverlayPainter extends CustomPainter {
  final _SharedCropState _state;
  final Rect _cropRect;

  final Color overlayColor;
  final Color handleColor;

  _OverlayPainter(this._state, {this.overlayColor, this.handleColor}) : _cropRect = _state.cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    if (_state.cropRect == null) {
      _state.cropRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 100,
          height: 100);
    }

    final paintBackground = Paint();
    paintBackground.color = overlayColor ?? Colors.white30;
    paintBackground.style = PaintingStyle.fill;
//    canvas.drawRect(_state.cropRect, paintBackground);
    Path path = new Path()..moveTo(_state.cropRect.topLeft.dx, _state.cropRect.topLeft.dy);
    path.lineTo(_state.cropRect.topRight.dx, _state.cropRect.topRight.dy);
    path.lineTo(_state.cropRect.bottomRight.dx, _state.cropRect.bottomRight.dy);
    path.lineTo(_state.cropRect.bottomLeft.dx, _state.cropRect.bottomLeft.dy);
    canvas.drawPath(path, paintBackground);

    final points = <Offset>[
      _state.cropRect.topLeft,
      _state.cropRect.topRight,
      _state.cropRect.bottomLeft,
      _state.cropRect.bottomRight
    ];
    final paintCorner = Paint()
      ..strokeWidth = 30.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.yellow;
    canvas.drawPoints(ui.PointMode.points, points, paintCorner);
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) {
    return _cropRect != oldDelegate._cropRect;
  }
}
