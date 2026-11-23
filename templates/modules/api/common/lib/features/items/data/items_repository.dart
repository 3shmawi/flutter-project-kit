import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

/// Example of a feature talking to the REST API: the generated client
/// inside `guard()`, input checked before it leaves the device. Copy the
/// pattern for your endpoints, then delete this example (and `items` in
/// api/openapi.yaml). Screens: `./scripts/new_feature.sh <name>`.
class ItemsRepository {
  ItemsRepository([Api? api]) : _api = api;

  final Api? _api;

  Api get _client => _api ?? ApiClient.api;

  static const maxTitleLength = 200;

  Future<Result<List<Item>>> items({int limit = 20}) =>
      guard(() => _client.items.listItems(limit: limit.clamp(1, 100)));

  Future<Result<Item>> add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > maxTitleLength) {
      return Future.value(
        const Failed(ValidationFailure('title: 1–200 characters')),
      );
    }
    // Not retried: a retry after a lost response could create it twice.
    return guard(
      () => _client.items.createItem(body: NewItem(title: trimmed)),
      retries: 0,
    );
  }

  Future<Result<void>> remove(String id) =>
      guard(() => _client.items.deleteItem(id: id));
}
