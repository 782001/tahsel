abstract class MainLayoutState {}

class MainLayoutInitial extends MainLayoutState {}

class MainLayoutChangeBottomNavIndex extends MainLayoutState {
  final int index;

  MainLayoutChangeBottomNavIndex(this.index);
}
