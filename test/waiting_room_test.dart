import 'dart:async';

import 'package:clinica_plus/data/repositories/waiting_room_repository.dart';
import 'package:clinica_plus/models/appointment_status.dart';
import 'package:clinica_plus/models/queue_status.dart';
import 'package:clinica_plus/providers/waiting_room_provider.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 11, 2, 9, 0);

QueueStatus _status(AppointmentStatus status, {int ahead = 0, DateTime? estimated}) =>
    QueueStatus(
      status: status,
      startsAt: DateTime(2026, 11, 2, 9, 10),
      peopleAhead: ahead,
      estimatedStart: estimated,
      specialtyName: 'Pediatría',
      doctorName: 'Dr. Gómez',
      siteName: 'Sede Principal',
    );

class FakeWaitingRoomRepository implements WaitingRoomRepository {
  final List<QueueStatus> responses = [];
  int fetchCount = 0;
  final StreamController<void> realtime = StreamController<void>.broadcast();
  bool realtimeCancelled = false;

  @override
  Future<QueueStatus> fetchQueueStatus(int appointmentId) async {
    final index = fetchCount < responses.length ? fetchCount : responses.length - 1;
    fetchCount++;
    return responses[index];
  }

  @override
  Stream<void> watchAppointment(int appointmentId) {
    realtimeCancelled = false;
    final controller = StreamController<void>();
    final subscription = realtime.stream.listen(controller.add);
    controller.onCancel = () {
      realtimeCancelled = true;
      subscription.cancel();
    };
    return controller.stream;
  }
}

void main() {
  group('QueueStatus', () {
    test('lee la fila del servidor', () {
      final status = QueueStatus.fromJson(const {
        'status': 'checked_in',
        'starts_at': '2026-11-02T14:10:00+00:00',
        'people_ahead': 2,
        'estimated_start': '2026-11-02T15:20:00+00:00',
        'specialty_name': 'Pediatría',
        'doctor_name': 'Dr. Gómez',
        'site_name': 'Sede Principal',
      });
      expect(status.isWaitingInRoom, isTrue);
      expect(status.peopleAhead, 2);
      expect(status.estimatedStart!.toUtc(), DateTime.utc(2026, 11, 2, 15, 20));
    });

    test('minutos estimados nunca negativos', () {
      final late = _status(AppointmentStatus.checkedIn, estimated: _now.subtract(const Duration(minutes: 5)));
      final soon = _status(AppointmentStatus.checkedIn, estimated: _now.add(const Duration(minutes: 70)));
      expect(late.minutesUntilEstimated(_now), 0);
      expect(soon.minutesUntilEstimated(_now), 70);
      expect(_status(AppointmentStatus.inProgress).minutesUntilEstimated(_now), isNull);
    });
  });

  group('WaitingRoomProvider', () {
    late FakeWaitingRoomRepository repository;
    late WaitingRoomProvider provider;

    setUp(() {
      repository = FakeWaitingRoomRepository();
      provider = WaitingRoomProvider(
        repository,
        pollInterval: const Duration(hours: 1), // el sondeo no interfiere
        clock: () => _now,
      );
    });

    tearDown(() => provider.dispose());

    test('un evento en tiempo real refresca el estado', () async {
      repository.responses.addAll([
        _status(AppointmentStatus.checkedIn, ahead: 2),
        _status(AppointmentStatus.checkedIn, ahead: 1),
      ]);
      await provider.start(922);
      expect(provider.status?.peopleAhead, 2);

      repository.realtime.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.status?.peopleAhead, 1);
    });

    test('avisa una sola vez cuando llega el turno', () async {
      repository.responses.addAll([
        _status(AppointmentStatus.checkedIn, ahead: 1),
        _status(AppointmentStatus.inProgress),
      ]);
      await provider.start(922);
      expect(provider.consumeTurnArrived(), isFalse);
      await provider.refresh();
      expect(provider.consumeTurnArrived(), isTrue);
      expect(provider.consumeTurnArrived(), isFalse);
    });

    test('stop cierra el canal en tiempo real', () async {
      repository.responses.add(_status(AppointmentStatus.checkedIn));
      await provider.start(922);
      provider.stop();
      await Future<void>.delayed(Duration.zero);
      expect(repository.realtimeCancelled, isTrue);
    });

    test('el sondeo periódico actualiza la fila', () async {
      final polling = WaitingRoomProvider(
        repository,
        pollInterval: const Duration(milliseconds: 20),
        clock: () => _now,
      );
      repository.responses.addAll([
        _status(AppointmentStatus.checkedIn, ahead: 3),
        _status(AppointmentStatus.checkedIn, ahead: 2),
      ]);
      await polling.start(922);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(polling.status?.peopleAhead, 2);
      polling.dispose();
    });
  });
}
