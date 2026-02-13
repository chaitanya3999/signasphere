import 'package:flutter_riverpod/flutter_riverpod.dart';

final navBarVisibilityProvider = StateNotifierProvider<NavBarVisibilityController, bool>((ref) {
  return NavBarVisibilityController();
});

class NavBarVisibilityController extends StateNotifier<bool> {
  NavBarVisibilityController() : super(true);

  void show() => state = true;
  void hide() => state = false;
  void toggle() => state = !state;
}
