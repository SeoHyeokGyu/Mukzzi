import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as dom;

@JS('lottie.loadAnimation')
external JSObject _loadAnimation(JSObject config);

int _viewCounter = 0;

Widget buildLottieWebPlayer(String assetPath, double size) {
  return _LottieHtmlPlayer(assetPath: assetPath, size: size);
}

class _LottieHtmlPlayer extends StatefulWidget {
  final String assetPath;
  final double size;

  const _LottieHtmlPlayer({required this.assetPath, required this.size});

  @override
  State<_LottieHtmlPlayer> createState() => _LottieHtmlPlayerState();
}

class _LottieHtmlPlayerState extends State<_LottieHtmlPlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'lottie-player-${_viewCounter++}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = dom.document.createElement('div') as dom.HTMLElement;
      div.style.width = '100%';
      div.style.height = '100%';

      _loadAnimation({
        'container': div,
        'renderer': 'svg',
        'loop': true,
        'autoplay': true,
        'path': widget.assetPath,
      }.jsify() as JSObject);

      return div;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
