import '../../../mvvm/base_view_model.dart';

abstract class SampleProductPreviewViewModelInput {}

abstract class SampleProductPreviewViewModelOutput {
  String get mockContentDescription;
}

abstract class SampleProductPreviewViewModelType extends AppBaseViewModel
    implements
        SampleProductPreviewViewModelInput,
        SampleProductPreviewViewModelOutput {}

class SampleProductPreviewViewModel extends SampleProductPreviewViewModelType {
  @override
  String get mockContentDescription =>
      localStrings.productPreviewMockContentDescription;
}
