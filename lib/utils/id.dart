import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

int newNotificationId() =>
    DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
