import '../../../../core/utils/password_utils.dart';
import '../../../../domain/models/admin.dart';
import '../repositories/auth_repository.dart';

class GetAdminsUseCase {
  const GetAdminsUseCase(this._repository);

  final AuthRepository _repository;

  Future<List<Admin>> call() => _repository.getAdmins();
}

class GetAdminByUsernameUseCase {
  const GetAdminByUsernameUseCase(this._repository);

  final AuthRepository _repository;

  Future<Admin?> call(String username) =>
      _repository.getAdminByUsername(username.trim());
}

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Admin?> call({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) return null;

    final admin = await _repository.getAdminByUsername(normalizedUsername);
    if (admin == null || !PasswordUtils.verify(password, admin.passwordHash)) {
      return null;
    }

    if (!PasswordUtils.needsRehash(admin.passwordHash)) return admin;

    final updated = admin.copyWith(passwordHash: PasswordUtils.hash(password));
    await _repository.updateAdmin(updated);
    return updated;
  }
}

class CreateAdminUseCase {
  const CreateAdminUseCase(this._repository);

  final AuthRepository _repository;

  Future<Admin> call({
    required String username,
    required String password,
    UserRole role = UserRole.cashier,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.length < 3) {
      throw ArgumentError.value(username, 'username', 'Too short');
    }
    if (password.length < 4) {
      throw ArgumentError.value(password, 'password', 'Too short');
    }

    final admin = Admin(
      username: normalizedUsername,
      passwordHash: PasswordUtils.hash(password),
      role: role,
    );
    final id = await _repository.addAdmin(admin);
    return admin.copyWith(id: id);
  }
}

class UpdateAdminUseCase {
  const UpdateAdminUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(Admin admin) async {
    if (admin.id == null || admin.id! <= 0) {
      throw ArgumentError.value(admin.id, 'id', 'A saved admin is required');
    }
    if (admin.username.trim().isEmpty || admin.passwordHash.isEmpty) {
      throw ArgumentError('Admin credentials are incomplete');
    }
    await _repository.updateAdmin(admin);
  }
}

class DeleteAdminUseCase {
  const DeleteAdminUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive');
    return _repository.deleteAdmin(id);
  }
}

class ChangeAdminRoleUseCase {
  const ChangeAdminRoleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Admin> call({required Admin admin, required UserRole role}) async {
    if (admin.id == null || admin.id! <= 0) {
      throw ArgumentError.value(admin.id, 'id', 'A saved admin is required');
    }
    final updated = admin.copyWith(role: role);
    await _repository.updateAdmin(updated);
    return updated;
  }
}
