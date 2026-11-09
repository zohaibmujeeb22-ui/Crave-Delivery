sealed class StartupState {
  const StartupState();
}

class StartupInitial extends StartupState {
  const StartupInitial();
}

class NavigateToOnboarding extends StartupState {
  const NavigateToOnboarding();
}

class NavigateToAuth extends StartupState {
  const NavigateToAuth();
}

class NavigateToCustomerHome extends StartupState {
  const NavigateToCustomerHome();
}

class NavigateToRestaurantDashboard extends StartupState {
  const NavigateToRestaurantDashboard();
}

class NavigateToProfileCompletion extends StartupState {
  const NavigateToProfileCompletion();
}

class StartupError extends StartupState {
  final String message;
  const StartupError(this.message);
}
