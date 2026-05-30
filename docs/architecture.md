## Architecture Rules

### Project Architecture:

* lib/api: put api logic here
* lib/model: put data structure/model here
* lib/pages: put complete page here
* lib/widget: put small,reuseable widget here,NEVER put page here
* lib/provider:put provider for state management here

### State Management

Use Provider only.

Do not introduce:

* Bloc
* GetX
* Riverpod

### Networking

All external APIs must be accessed through services.

Example:

lib/services/
direction_service.dart
elevation_service.dart

Do not call APIs directly inside widgets.



### UI

Widgets should only display data.

Business logic belongs to controllers/services.

---