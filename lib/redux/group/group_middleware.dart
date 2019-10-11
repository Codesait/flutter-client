import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:invoiceninja_flutter/data/models/group_model.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';
import 'package:invoiceninja_flutter/redux/app/app_middleware.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/group/group_screen.dart';
import 'package:invoiceninja_flutter/ui/group/edit/group_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/group/view/group_view_vm.dart';
import 'package:invoiceninja_flutter/redux/group/group_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/data/repositories/group_repository.dart';

List<Middleware<AppState>> createStoreGroupsMiddleware([
  GroupRepository repository = const GroupRepository(),
]) {
  final viewGroupList = _viewGroupList();
  final viewGroup = _viewGroup();
  final editGroup = _editGroup();
  final loadGroups = _loadGroups(repository);
  final loadGroup = _loadGroup(repository);
  final saveGroup = _saveGroup(repository);
  final archiveGroup = _archiveGroup(repository);
  final deleteGroup = _deleteGroup(repository);
  final restoreGroup = _restoreGroup(repository);

  return [
    TypedMiddleware<AppState, ViewGroupList>(viewGroupList),
    TypedMiddleware<AppState, ViewGroup>(viewGroup),
    TypedMiddleware<AppState, EditGroup>(editGroup),
    TypedMiddleware<AppState, LoadGroups>(loadGroups),
    TypedMiddleware<AppState, LoadGroup>(loadGroup),
    TypedMiddleware<AppState, SaveGroupRequest>(saveGroup),
    TypedMiddleware<AppState, ArchiveGroupRequest>(archiveGroup),
    TypedMiddleware<AppState, DeleteGroupRequest>(deleteGroup),
    TypedMiddleware<AppState, RestoreGroupRequest>(restoreGroup),
  ];
}

Middleware<AppState> _editGroup() {
  return (Store<AppState> store, dynamic dynamicAction,
      NextDispatcher next) async {
    final action = dynamicAction as EditGroup;

    if (!action.force && hasChanges(
        store: store, context: action.context, action: action)) {
      return;
    }

    next(action);

    store.dispatch(UpdateCurrentRoute(GroupEditScreen.route));

    if (isMobile(action.context)) {
      final group =
          await Navigator.of(action.context).pushNamed(GroupEditScreen.route);

      if (action.completer != null && group != null) {
        action.completer.complete(group);
      }
    }
  };
}

Middleware<AppState> _viewGroup() {
  return (Store<AppState> store, dynamic dynamicAction,
      NextDispatcher next) async {
    final action = dynamicAction as ViewGroup;

    if (!action.force && hasChanges(
        store: store, context: action.context, action: action)) {
      return;
    }

    next(action);

    store.dispatch(UpdateCurrentRoute(GroupViewScreen.route));

    if (isMobile(action.context)) {
      Navigator.of(action.context).pushNamed(GroupViewScreen.route);
    }
  };
}

Middleware<AppState> _viewGroupList() {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ViewGroupList;

    if (!action.force && hasChanges(
        store: store, context: action.context, action: action)) {
      return;
    }

    next(action);

    if (store.state.groupState.isStale) {
      store.dispatch(LoadGroups());
    }

    store.dispatch(UpdateCurrentRoute(GroupSettingsScreen.route));

    if (isMobile(action.context)) {
      Navigator.of(action.context).pushNamedAndRemoveUntil(
          GroupSettingsScreen.route, (Route<dynamic> route) => false);
    }
  };
}

Middleware<AppState> _archiveGroup(GroupRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ArchiveGroupRequest;
    final origGroup = store.state.groupState.map[action.groupId];
    repository
        .saveData(store.state.credentials, origGroup, EntityAction.archive)
        .then((GroupEntity group) {
      store.dispatch(ArchiveGroupSuccess(group));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(ArchiveGroupFailure(origGroup));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _deleteGroup(GroupRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as DeleteGroupRequest;
    final origGroup = store.state.groupState.map[action.groupId];
    repository
        .saveData(store.state.credentials, origGroup, EntityAction.delete)
        .then((GroupEntity group) {
      store.dispatch(DeleteGroupSuccess(group));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(DeleteGroupFailure(origGroup));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _restoreGroup(GroupRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as RestoreGroupRequest;
    final origGroup = store.state.groupState.map[action.groupId];
    repository
        .saveData(store.state.credentials, origGroup, EntityAction.restore)
        .then((GroupEntity group) {
      store.dispatch(RestoreGroupSuccess(group));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(RestoreGroupFailure(origGroup));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _saveGroup(GroupRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as SaveGroupRequest;
    repository
        .saveData(store.state.credentials, action.group)
        .then((GroupEntity group) {
      if (action.group.isNew) {
        store.dispatch(AddGroupSuccess(group));
      } else {
        store.dispatch(SaveGroupSuccess(group));
      }
      action.completer.complete();
    }).catchError((Object error) {
      print(error);
      store.dispatch(SaveGroupFailure(error));
      action.completer.completeError(error);
    });

    next(action);
  };
}

Middleware<AppState> _loadGroup(GroupRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as LoadGroup;
    final AppState state = store.state;

    if (state.isLoading) {
      next(action);
      return;
    }

    store.dispatch(LoadGroupRequest());
    repository.loadItem(state.credentials, action.groupId).then((group) {
      store.dispatch(LoadGroupSuccess(group));

      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(LoadGroupFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _loadGroups(GroupRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as LoadGroups;
    final AppState state = store.state;

    if (!state.groupState.isStale && !action.force) {
      next(action);
      return;
    }

    if (state.isLoading) {
      next(action);
      return;
    }

    final int updatedAt = (state.groupState.lastUpdated / 1000).round();

    store.dispatch(LoadGroupsRequest());
    repository.loadList(state.credentials, updatedAt).then((data) {
      store.dispatch(LoadGroupsSuccess(data));

      if (action.completer != null) {
        action.completer.complete(null);
      }
      /*
      if (state.productState.isStale) {
        store.dispatch(LoadProducts());
      }
      */
    }).catchError((Object error) {
      print(error);
      store.dispatch(LoadGroupsFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}