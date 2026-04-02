import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeState extends Equatable {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class ThemeInitial extends ThemeState {
  const ThemeInitial(super.themeMode);
}

class ThemeChanged extends ThemeState {
  const ThemeChanged(super.themeMode);
}
