import '../../../mvvm/base_view_model.dart';

abstract class SampleProductViewModelInput {}

abstract class SampleProductViewModelOutput {
  String get mockContentDescription;
}

abstract class SampleProductViewModelType extends AppBaseViewModel
    implements SampleProductViewModelInput, SampleProductViewModelOutput {}

class SampleProductViewModel extends SampleProductViewModelType {
  @override
  String get mockContentDescription =>
      localStrings.productPreviewMockContentDescription;
}
