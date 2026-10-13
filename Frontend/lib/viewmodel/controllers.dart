import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/viewmodel/auth/login/login_state.dart';
import 'package:notes_app/viewmodel/auth/login/login_viewmodel.dart';
import 'package:notes_app/viewmodel/profile/profile_state.dart';
import 'package:notes_app/viewmodel/profile/profile_viewmodel.dart';

final profileController = AsyncNotifierProvider<ProfileViewmodel, ProfileState>(
  ProfileViewmodel.new,
);

final loginController = AsyncNotifierProvider<LoginViewmodel, LoginState>(
  LoginViewmodel.new,
);
