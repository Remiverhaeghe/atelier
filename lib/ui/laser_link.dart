import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../logic/laser_frames.dart';

typedef LaserDevice = ({String id, String name});

/// Liaison avec un télémètre ; remplacée par une fausse dans les tests.
abstract interface class LaserLink {
  /// Télémètres à portée.
  Stream<LaserDevice> scan();

  /// Distances mesurées sur l'appareil, en millimètres, tant qu'on écoute.
  Stream<int> measures(String pDeviceId);
}

/// Bluetooth basse consommation du téléphone, après l'accord de l'utilisateur.
class BleLaserLink implements LaserLink {
  final _aBle = FlutterReactiveBle();

  Future<bool> _allowed() async {
    final vStatus = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      // Android 11 et avant : la recherche Bluetooth passe par la localisation
      Permission.locationWhenInUse,
    ].request();

    return vStatus[Permission.bluetoothConnect] != PermissionStatus.permanentlyDenied &&
        vStatus[Permission.bluetoothScan] != PermissionStatus.permanentlyDenied;
  }

  @override
  Stream<LaserDevice> scan() async* {
    if (!await _allowed()) {
      return;
    }
    final vSeen = <String>{};
    await for (final vDevice in _aBle.scanForDevices(withServices: const [])) {
      if (isLaserName(vDevice.name) && vSeen.add(vDevice.id)) {
        yield (id: vDevice.id, name: vDevice.name);
      }
    }
  }

  @override
  Stream<int> measures(String pDeviceId) {
    final vCharacteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(laserServiceUuid),
      characteristicId: Uuid.parse(laserCharacteristicUuid),
      deviceId: pDeviceId,
    );
    late final StreamController<int> rController;
    StreamSubscription<ConnectionStateUpdate>? vConnection;
    StreamSubscription<List<int>>? vFrames;
    rController = StreamController<int>(
      onListen: () {
        vConnection = _aBle.connectToDevice(id: pDeviceId).listen((pUpdate) async {
          if (pUpdate.connectionState != DeviceConnectionState.connected || vFrames != null) {
            return;
          }
          vFrames = _aBle.subscribeToCharacteristic(vCharacteristic).listen((pFrame) {
            final vMm = laserDistanceMm(pFrame);
            if (vMm != null) {
              rController.add(vMm);
            }
          }, onError: rController.addError);
          await _aBle.writeCharacteristicWithResponse(vCharacteristic, value: laserSyncCommand);
        }, onError: rController.addError);
      },
      onCancel: () async {
        await vFrames?.cancel();
        await vConnection?.cancel();
      },
    );

    return rController.stream;
  }
}
