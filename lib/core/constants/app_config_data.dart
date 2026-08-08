import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/selection_option.dart';

class AppConfigData {
  const AppConfigData._();

  static const List<SelectionOption> goalOptions = [
    SelectionOption(label: AppStrings.goalBetterEnergy, icon: AppIcons.zap),
    SelectionOption(label: AppStrings.goalLessBloating, icon: AppIcons.wind),
    SelectionOption(label: AppStrings.goalCleanerEating, icon: AppIcons.salad),
    SelectionOption(label: AppStrings.goalBetterSkin, icon: AppIcons.sparkles),
    SelectionOption(
      label: AppStrings.goalGymPerformance,
      icon: AppIcons.dumbbell,
    ),
    SelectionOption(
      label: AppStrings.goalControlCravings,
      icon: AppIcons.cookie,
    ),
    SelectionOption(label: AppStrings.goalBetterMood, icon: AppIcons.smile),
    SelectionOption(label: AppStrings.goalGutHealth, icon: AppIcons.activity),
    SelectionOption(
      label: AppStrings.goalHormoneBalance,
      icon: AppIcons.flower,
    ),
    SelectionOption(label: AppStrings.goalWeightBalance, icon: AppIcons.scale),
  ];

  static const List<SelectionOption> sensitivityOptions = [
    SelectionOption(label: AppStrings.sensitivityDairy, icon: AppIcons.milk),
    SelectionOption(label: AppStrings.sensitivityGluten, icon: AppIcons.wheat),
    SelectionOption(label: AppStrings.sensitivitySugar, icon: AppIcons.candy),
    SelectionOption(
      label: AppStrings.sensitivitySeedOils,
      icon: AppIcons.droplet,
    ),
    SelectionOption(
      label: AppStrings.sensitivityArtificialDyes,
      icon: AppIcons.palette,
    ),
    SelectionOption(label: AppStrings.sensitivityFastFood, icon: AppIcons.beef),
    SelectionOption(
      label: AppStrings.sensitivitySpicyFoods,
      icon: AppIcons.flame,
    ),
    SelectionOption(label: AppStrings.sensitivityPeanuts, icon: AppIcons.nut),
    SelectionOption(label: AppStrings.sensitivityTreeNuts, icon: AppIcons.nut),
    SelectionOption(
      label: AppStrings.sensitivityShellfish,
      icon: AppIcons.fish,
    ),
    SelectionOption(label: AppStrings.sensitivityEggs, icon: AppIcons.egg),
    SelectionOption(label: AppStrings.sensitivitySoy, icon: AppIcons.leaf),
    SelectionOption(label: AppStrings.sensitivityFish, icon: AppIcons.fish),
    SelectionOption(label: AppStrings.sensitivitySesame, icon: AppIcons.wheat),
    SelectionOption(
      label: AppStrings.sensitivityNotSure,
      icon: AppIcons.helpCircle,
    ),
  ];

  static const List<SelectionOption> lifestyleOptions = [
    SelectionOption(
      label: AppStrings.lifestyleLowEnergy,
      icon: AppIcons.batteryLow,
    ),
    SelectionOption(label: AppStrings.lifestyleStress, icon: AppIcons.brain),
    SelectionOption(label: AppStrings.lifestyleBloating, icon: AppIcons.wind),
    SelectionOption(label: AppStrings.lifestyleCravings, icon: AppIcons.cookie),
    SelectionOption(label: AppStrings.lifestyleEatCleaner, icon: AppIcons.leaf),
    SelectionOption(
      label: AppStrings.lifestyleHealingGut,
      icon: AppIcons.heartPulse,
    ),
    SelectionOption(label: AppStrings.lifestyleGym, icon: AppIcons.dumbbell),
    SelectionOption(
      label: AppStrings.lifestyleJustCurious,
      icon: AppIcons.search,
    ),
  ];

  static const List<String> cyclePhases = [
    AppStrings.phaseMenstrual,
    AppStrings.phaseFollicular,
    AppStrings.phaseOvulatory,
    AppStrings.phaseLuteal,
  ];
}
