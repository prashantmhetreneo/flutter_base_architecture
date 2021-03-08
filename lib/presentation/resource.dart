import 'resource_state.dart';

class Resource<T> {
  ResourceState state;

  T data;
  String message;

  Resource();

  Resource.load({this.state = ResourceState.LOADING});

  Resource.success(
      {this.state = ResourceState.SUCCESS, this.data, this.message});

  Resource.error({this.state = ResourceState.ERROR, this.message});
}
