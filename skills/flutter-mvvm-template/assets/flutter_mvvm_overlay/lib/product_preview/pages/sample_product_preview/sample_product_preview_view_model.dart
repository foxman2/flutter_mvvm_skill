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
  String get mockContentDescription {
    return 'Use mock API services for data-driven previews, and mark those '
        'data-layer changes as pending dev review.';
  }
}
