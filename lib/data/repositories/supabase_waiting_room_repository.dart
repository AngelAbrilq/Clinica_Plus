import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/queue_status.dart';
import '../../utils/app_exception.dart';
import '../services/supabase_error_mapper.dart';
import 'waiting_room_repository.dart';

class SupabaseWaitingRoomRepository implements WaitingRoomRepository {
  SupabaseWaitingRoomRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<QueueStatus> fetchQueueStatus(int appointmentId) =>
      SupabaseErrorMapper.guard(() async {
        final rows = await _client.rpc<List<dynamic>>(
          'get_my_queue_status',
          params: {'p_appointment_id': appointmentId},
        );
        if (rows.isEmpty) throw const AppException('La cita no existe');
        return QueueStatus.fromJson(rows.first as Map<String, dynamic>);
      });

  /// Realtime respeta la RLS: el paciente solo recibe eventos de SU cita.
  /// Los cambios de otros pacientes (que la fila avanzó) llegan por el
  /// sondeo periódico del provider.
  @override
  Stream<void> watchAppointment(int appointmentId) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('waiting-room-$appointmentId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'appointments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: appointmentId,
              ),
              callback: (_) {
                if (!controller.isClosed) controller.add(null);
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final current = channel;
        if (current != null) await _client.removeChannel(current);
      },
    );
    return controller.stream;
  }
}
