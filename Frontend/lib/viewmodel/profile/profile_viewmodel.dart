import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/viewmodel/profile/profile_state.dart';

class ProfileViewmodel extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    return ProfileState();
  }
}
