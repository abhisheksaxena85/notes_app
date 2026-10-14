import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/viewmodel/auth/login/login_state.dart';
import 'package:notes_app/viewmodel/auth/login/login_viewmodel.dart';
import 'package:notes_app/viewmodel/auth/register/register_state.dart';
import 'package:notes_app/viewmodel/auth/register/register_viewmodel.dart';
import 'package:notes_app/viewmodel/home/home_state.dart';
import 'package:notes_app/viewmodel/home/home_viewmodel.dart';
import 'package:notes_app/viewmodel/note_details/note_details_state.dart';
import 'package:notes_app/viewmodel/note_details/note_details_viewmodel.dart';
import 'package:notes_app/viewmodel/profile/profile_state.dart';
import 'package:notes_app/viewmodel/profile/profile_viewmodel.dart';

final homeController = AsyncNotifierProvider<HomeViewmodel, HomeState>(
  HomeViewmodel.new,
);

final profileController = AsyncNotifierProvider<ProfileViewmodel, ProfileState>(
  ProfileViewmodel.new,
);

final loginController = AsyncNotifierProvider<LoginViewmodel, LoginState>(
  LoginViewmodel.new,
);

final registerController =
    AsyncNotifierProvider<RegisterViewmodel, RegisterState>(
  RegisterViewmodel.new,
);

final noteDetailsController =
    AsyncNotifierProvider<NoteDetailsViewmodel, NoteDetailsState>(
  NoteDetailsViewmodel.new,
);

