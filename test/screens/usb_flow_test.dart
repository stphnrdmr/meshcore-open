import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshcore_open/connector/meshcore_connector.dart';
import 'package:meshcore_open/l10n/app_localizations.dart';
import 'package:meshcore_open/screens/connection_choice_screen.dart';
import 'package:meshcore_open/screens/usb_screen.dart';
import 'package:meshcore_open/utils/platform_info.dart';

class _FakeMeshCoreConnector extends MeshCoreConnector {
  _FakeMeshCoreConnector({
    this.initialState = MeshCoreConnectionState.disconnected,
    List<String>? ports,
  }) : _ports = ports ?? <String>[];

  final MeshCoreConnectionState initialState;
  final List<String> _ports;

  String? requestPortLabel;
  int connectUsbCalls = 0;
  String? lastConnectPortName;
  String? fakeActiveUsbPort;
  bool fakeUsbTransportConnected = false;

  @override
  MeshCoreConnectionState get state => initialState;

  @override
  String? get activeUsbPort => fakeActiveUsbPort;

  @override
  bool get isUsbTransportConnected => fakeUsbTransportConnected;

  @override
  Future<List<String>> listUsbPorts() async => List<String>.from(_ports);

  @override
  Future<void> connectUsb({
    required String portName,
    int baudRate = 115200,
  }) async {
    connectUsbCalls += 1;
    lastConnectPortName = portName;
  }

  @override
  void setUsbRequestPortLabel(String label) {
    requestPortLabel = label;
  }
}

Widget _buildTestApp({
  required MeshCoreConnector connector,
  required Widget child,
}) {
  return ChangeNotifierProvider<MeshCoreConnector>.value(
    value: connector,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('UsbScreen passes localized chooser label to connector', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(connector: connector, child: const UsbScreen()),
    );
    await tester.pumpAndSettle();

    expect(connector.requestPortLabel, 'Select a USB device');
  });

  testWidgets(
    'UsbScreen does not call connectUsb when connector is not disconnected',
    (tester) async {
      final connector = _FakeMeshCoreConnector(
        initialState: MeshCoreConnectionState.connected,
        ports: <String>['COM6 - USB Serial Device (COM6)'],
      );

      await tester.pumpWidget(
        _buildTestApp(connector: connector, child: const UsbScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
      await tester.pump();

      expect(connector.connectUsbCalls, 0);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('ConnectionChoiceScreen USB button reflects platform support', (
    tester,
  ) async {
    final connector = _FakeMeshCoreConnector();

    await tester.pumpWidget(
      _buildTestApp(
        connector: connector,
        child: const ConnectionChoiceScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final usbButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'USB'),
    );

    if (PlatformInfo.supportsUsbSerial) {
      expect(usbButton.onPressed, isNotNull);
    } else {
      expect(usbButton.onPressed, isNull);
    }
  });
}
