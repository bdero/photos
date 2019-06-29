import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scoped_model/scoped_model.dart';

import '../model/photo_card_producer.dart';
import '../model/photo_cards.dart';
import '../model/photos_library_api_model.dart';

class PhotosHome extends StatefulWidget {
  PhotosHome({
    Key key,
    @required this.montageBuilder,
    @required this.producerBuilder,
  })  : assert(montageBuilder != null),
        assert(producerBuilder != null),
        super(key: key);

  @override
  _PhotosHomeState createState() => _PhotosHomeState();

  final PhotoMontageBuilder montageBuilder;
  final PhotoCardProducerBuilder producerBuilder;
}

class _PhotosHomeState extends State<PhotosHome> {
  PhotoMontage montage;
  PhotoCardProducer producer;

  @override
  void initState() {
    super.initState();
    PhotosLibraryApiModel model = ScopedModel.of<PhotosLibraryApiModel>(context);
    montage = widget.montageBuilder();
    producer = widget.producerBuilder(model, montage)..start();
  }

  @override
  void dispose() {
    producer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<PhotoMontage>(
      model: montage,
      child: _PhotosCascade(),
    );
  }
}

class _PhotosCascade extends StatelessWidget {
  _PhotosCascade({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PhotoMontage>(
      builder: (BuildContext context, Widget child, PhotoMontage montage) {
        return Stack(
          children: montage.cards.map<Widget>((PhotoCard card) {
            return FLoatingPhoto(
              card: card,
            );
          }).toList(),
        );
      },
    );
  }
}

class FLoatingPhoto extends StatefulWidget {
  FLoatingPhoto({
    Key key,
    @required this.card,
  })  : assert(card != null),
        super(key: key);

  final PhotoCard card;

  @override
  _FLoatingPhotoState createState() => _FLoatingPhotoState();
}

class _FLoatingPhotoState extends State<FLoatingPhoto> with SingleTickerProviderStateMixin {
  Ticker ticker;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    ticker
      ..stop()
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FLoatingPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO: do something?
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Positioned(
      child: SizedBox(
        width: widget.card.column.width * screenSize.width,
        height: widget.card.column.width * screenSize.width,
        child: Image.memory(
          widget.card.photo.bytes,
          scale: widget.card.photo.scale,
        ),
      ),
      left: screenSize.width * widget.card.column.left,
      top: screenSize.height - widget.card.top,
    );
  }

  void _tick(Duration elapsed) {
    setState(() {
      widget.card.nextFrame();
      double screenHeight = MediaQuery.of(context).size.height;
      if (widget.card.bottom > screenHeight) {
        widget.card.dispose();
      }
    });
  }
}

class PeriodicSpinner extends StatefulWidget {
  PeriodicSpinner({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _PeriodicSpinnerState createState() => _PeriodicSpinnerState();
}

class _PeriodicSpinnerState extends State<PeriodicSpinner> with TickerProviderStateMixin {
  AnimationController controller;
  Animation<double> angleAnimation;
  Animation<double> transformAnimation;
  Timer timer;
  double angle;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    angleAnimation = controller.drive(
        Tween<double>(begin: 0, end: 2 * math.pi).chain(CurveTween(curve: Curves.easeInOutCubic)));
    transformAnimation = controller.drive(Tween<double>());
    timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      controller.forward().then((void _) {
        controller.reset();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.rotationY(angleAnimation.value),
      child: widget.child,
    );
  }
}
