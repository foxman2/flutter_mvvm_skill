import '../../../mvvm/base_view_model.dart';

/// 示例预览页接受的用户动作；当前为空，供后续示例扩展。
abstract class SampleProductViewModelInput {}

/// 示例预览页对外状态；当前为空，供后续示例扩展。
abstract class SampleProductViewModelOutput {}

/// 示例预览页 ViewModel 的完整页面契约。
abstract class SampleProductViewModelType extends AppBaseViewModel
    implements SampleProductViewModelInput, SampleProductViewModelOutput {}

/// Product Preview 静态示例使用的 ViewModel。
class SampleProductViewModel extends SampleProductViewModelType {}
