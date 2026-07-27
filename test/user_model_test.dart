import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:self_study/models/user_model.dart';
import 'package:self_study/services/local_user_store.dart';

void main() {
  test('user profile data survives local serialization', () {
    final user = UserModel(
      id: 'user-1',
      email: 'student@example.com',
      name: 'Student',
      profileImageBase64: 'aW1hZ2UtYnl0ZXM=',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final restored = UserModel.fromFirestore(user.toFirestore());

    expect(restored.id, user.id);
    expect(restored.email, user.email);
    expect(restored.name, user.name);
    expect(restored.profileImageBase64, user.profileImageBase64);
  });

  test('cached profile can be restored and is removed on logout', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalUserStore();
    final user = UserModel(
      id: 'offline-user',
      email: 'student@example.com',
      name: 'Offline Student',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    await store.save(user);
    expect((await store.read(user.id))?.name, 'Offline Student');

    await store.clear(user.id);
    expect(await store.read(user.id), isNull);
  });
}
