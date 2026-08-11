import '../../../mvvm/base_view_model.dart';

abstract class SampleProductViewModelInput {}

abstract class SampleProductViewModelOutput {}

abstract class SampleProductViewModelType extends AppBaseViewModel
    implements SampleProductViewModelInput, SampleProductViewModelOutput {}

class SampleProductViewModel extends SampleProductViewModelType {}
