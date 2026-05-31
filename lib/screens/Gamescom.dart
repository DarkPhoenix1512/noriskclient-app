import 'package:flutter/material.dart';
import 'package:noriskclient/config/Colors.dart';
import 'package:noriskclient/main.dart';
import 'package:noriskclient/screens/mcreal/ImageViewer.dart';
import 'package:noriskclient/utils/NoRiskApi.dart';
import 'package:noriskclient/widgets/NoRiskBackButton.dart';
import 'package:noriskclient/widgets/NoRiskButton.dart';
import 'package:noriskclient/widgets/NoRiskContainer.dart';
import 'package:noriskclient/widgets/NoRiskText.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Gamescom extends StatefulWidget {
  const Gamescom({super.key});

  @override
  State<Gamescom> createState() => GamescomState();
}

class Timeslot {
  final DateTime start;
  final DateTime end;
  final String locationName;
  final double latitude;
  final double longitude;
  Timeslot({
    required this.start,
    required this.end,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });
}

class GamescomState extends State<Gamescom> {
  List<Timeslot> timeslots = [];

  void openMaps(Timeslot slot) async {
    final lat = slot.latitude;
    final lng = slot.longitude;
    final label = Uri.encodeComponent(slot.locationName);
    String url;
    if (isIOS) {
      url = 'maps://?ll=$lat,$lng&q=$label';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label';
    }
    await launchUrlString(url);
  }

  void showQr(BuildContext context) {
    final username = cache['usernames']?[getUserData['uuid']];
    if (!username) return;
    showDialog(
      context: context,
      barrierColor: Color.fromARGB(220, 0, 0, 0),
      builder: (_) =>
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: MediaQuery.of(context).size.width / 1.5,
          child: Column(children: [
            QrImageView(
              data: 'NRC-GAMESCOM-2026-$username',
              foregroundColor: NoRiskClientColors.text,
              embeddedImage: AssetImage('lib/assets/app/flash.png'),
              embeddedImageStyle:
                  QrEmbeddedImageStyle(color: NoRiskClientColors.blue),
            ),
          ]),
        ),
      ]),
    );
  }

  bool isActive(Timeslot slot) {
    final now = DateTime.now();
    return now.isAfter(slot.start) && now.isBefore(slot.end);
  }

  bool isUpcoming(Timeslot slot) {
    final now = DateTime.now();
    return now.isBefore(slot.start);
  }

  bool isPassed(Timeslot slot) {
    final now = DateTime.now();
    return now.isAfter(slot.end);
  }

  Timeslot? getActiveSlot() {
    for (final slot in timeslots) {
      if (isActive(slot)) return slot;
    }
    return null;
  }

  int getNextEventIndex() {
    final now = DateTime.now();
    for (int i = 0; i < timeslots.length; i++) {
      if (timeslots[i].start.isAfter(now) ||
          (timeslots[i].start.isBefore(now) && timeslots[i].end.isAfter(now))) {
        return i;
      }
    }
    return -1;
  }

  @override
  void initState() {
    loadEvents();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activeSlot = getActiveSlot();
    final int nextIdx = getNextEventIndex();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: NoRiskClientColors.background,
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 95,
                bottom:
                    (isAndroid ? MediaQuery.of(context).viewPadding.bottom : 0),
                left: 10,
                right: 10,
              ),
              child: RefreshIndicator(
                onRefresh: () async => loadEvents(),
                child: ListView.separated(
                  itemCount: timeslots.where((slot) => !isPassed(slot)).length,
                  separatorBuilder: (_, __) => SizedBox(height: 20),
                  itemBuilder: (context, idx) {
                    final slot = timeslots[idx];
                    final bool isNext = idx == nextIdx;
                    final Color bgColor =
                        isNext ? NoRiskClientColors.blue : Colors.white;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: idx == timeslots.length - 1 ? 50 : 0),
                      child: NoRiskContainer(
                        color: bgColor,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Stack(children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                NoRiskText(
                                  slot.locationName.toLowerCase(),
                                  spaceTop: false,
                                  spaceBottom: false,
                                  style: TextStyle(
                                      fontSize: 26,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                NoRiskText(
                                  '${slot.start.day.toString().padLeft(2, '0')}.${slot.start.month.toString().padLeft(2, '0')}.${slot.start.year}',
                                  spaceTop: false,
                                  spaceBottom: false,
                                  style: TextStyle(
                                      fontSize: 28,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                NoRiskText(
                                  '${slot.start.hour.toString().padLeft(2, '0')}:${slot.start.minute.toString().padLeft(2, '0')} - '
                                  '${slot.end.hour.toString().padLeft(2, '0')}:${slot.end.minute.toString().padLeft(2, '0')}',
                                  spaceTop: false,
                                  spaceBottom: false,
                                  style: TextStyle(
                                      fontSize: 44,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (!isPassed(slot)) ...[
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                ImageViewer(
                                                    image: Image.network(
                                                        'https://cdn.norisk.gg/backend-resources/${slot.locationName.toLowerCase().replaceAll(' ', '_')}.png')))),
                                    child: Image.network(
                                        'https://cdn.norisk.gg/backend-resources/${slot.locationName.toLowerCase().replaceAll(' ', '_')}.png'),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      NoRiskButton(
                                        onTap: () => openMaps(slot),
                                        color: bgColor,
                                        child: Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: NoRiskText(
                                              'Show Location'.toLowerCase(),
                                              spaceTop: false,
                                              spaceBottom: false,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color:
                                                      NoRiskClientColors.text)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (isActive(slot) &&
                                          getUserData['uuid'] != null)
                                        NoRiskButton(
                                          onTap: () => showQr(context),
                                          color: bgColor,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: NoRiskText(
                                                'Show QR Code'.toLowerCase(),
                                                spaceTop: false,
                                                spaceBottom: false,
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    color: NoRiskClientColors
                                                        .text)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                            if (isActive(slot))
                              Align(
                                alignment: Alignment.topRight,
                                child: PulsingSquare(
                                    color: NoRiskClientColors.blue),
                              ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Stack(
                children: [
                  if (getUserData['uuid'] == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7.5),
                          child: NoRiskBackButton(),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      NoRiskText('gamescom',
                          spaceTop: false,
                          spaceBottom: false,
                          style: const TextStyle(
                              color: NoRiskClientColors.text,
                              fontSize: 50,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void loadEvents() async {
    var res = await NoRiskApi().getGamescomEvents();

    if (res == null) {
      setState(() {
        timeslots = [];
      });
      return;
    }

    List<Timeslot> _timeslots = [];
    for (var slot in res) {
      var newSlot = Timeslot(
          start: DateTime.fromMillisecondsSinceEpoch(slot['start']),
          end: DateTime.fromMillisecondsSinceEpoch(slot['end']),
          locationName: slot['locationName'],
          latitude: slot['latitude'],
          longitude: slot['longitude']);

      if (isPassed(newSlot)) continue;

      _timeslots.add(newSlot);
    }

    setState(() {
      timeslots = _timeslots;
    });
  }
}

class PulsingSquare extends StatefulWidget {
  final Color color;
  const PulsingSquare({Key? key, required this.color}) : super(key: key);
  @override
  State<PulsingSquare> createState() => _PulsingSquareState();
}

class _PulsingSquareState extends State<PulsingSquare>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: widget.color,
        ),
      ),
    );
  }
}
