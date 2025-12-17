import 'package:fitbud/utils/enums.dart';
import 'package:get/get.dart';

class PremiumPlanController extends GetxController {
  int? selectedPlanIndex;
  PlanStatus status = PlanStatus.none;
  PaymentMethod? paymentMethod;
  String? orderId;

  /// ✅ DERIVED PREMIUM STATE
  bool get hasPremium => status == PlanStatus.active;

  // Check if the current card is selected
  bool isSelected(int index) => selectedPlanIndex == index;

  // Check if other cards should be disabled
  bool isDisabled(int index) {
    if (selectedPlanIndex == null) return false;
    return selectedPlanIndex != index;
  }

  // Set plan as pending with payment method and order ID
  void setPending({
    required int index,
    required PaymentMethod method,
    required String order,
  }) {
    selectedPlanIndex = index;
    paymentMethod = method;
    orderId = order;
    status = PlanStatus.pending;
    update();
  }

  // Set plan as active (Card payment case)
  void setActive(int index) {
    selectedPlanIndex = index;
    status = PlanStatus.active;
    paymentMethod = null;
    orderId = null;
    update();
  }

  // Reset previous plan if switching
  void switchPlan({
    required int index,
    PaymentMethod? method,
    String? order,
    PlanStatus newStatus = PlanStatus.pending,
  }) {
    selectedPlanIndex = index;
    status = newStatus;
    paymentMethod = method;
    orderId = order;
    update();
  }

  // Reset all selections (optional)
  void resetPlans() {
    selectedPlanIndex = null;
    status = PlanStatus.none;
    paymentMethod = null;
    orderId = null;
    update();
  }
}
