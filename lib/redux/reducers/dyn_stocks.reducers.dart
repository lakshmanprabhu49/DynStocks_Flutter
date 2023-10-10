import 'package:dynstocks/redux/actions/dyn_stocks.actions.dart';
import 'package:dynstocks/redux/state/dyn_stocks.state.dart';

DynStocksState dynStocksReducer(DynStocksState state, dynamic action) {
  if (action is GetAllDynStocksAction) {
    return DynStocksState.updatedState(
      loading: true,
      loaded: false,
      loadFailed: false,
      created: state.created,
      creating: state.creating,
      createFailed: false,
      updating: state.updating,
      updated: state.updated,
      updateFailed: false,
      deleting: state.deleting,
      deleted: state.deleted,
      deleteFailed: false,
      data: state.data,
    );
  }
  if (action is GetAllDynStocksSuccessAction) {
    return DynStocksState.updatedState(
        loading: false,
        loaded: true,
        loadFailed: false,
        created: state.created,
        creating: state.creating,
        createFailed: false,
        updating: state.updating,
        updated: state.updated,
        updateFailed: false,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: false,
        data: action.allDynStocks,
        error: null);
  }
  if (action is GetAllDynStocksFailAction) {
    return DynStocksState.updatedState(
        loading: false,
        loaded: false,
        loadFailed: true,
        created: state.created,
        creating: state.creating,
        createFailed: false,
        updating: state.updating,
        updated: state.updated,
        updateFailed: false,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: false,
        data: List.empty(),
        error: action.error);
  }
  if (action is CreateDynStockAction) {
    return DynStocksState.updatedState(
      loading: state.loading,
      loaded: state.loaded,
      loadFailed: false,
      creating: true,
      created: false,
      createFailed: false,
      updating: state.updating,
      updated: state.updated,
      updateFailed: false,
      deleting: state.deleting,
      deleted: state.deleted,
      deleteFailed: false,
      data: state.data,
    );
  }
  if (action is CreateDynStockSuccessAction) {
    return DynStocksState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: false,
        creating: false,
        created: true,
        createFailed: false,
        updating: state.updating,
        updated: state.updated,
        updateFailed: false,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: false,
        data: List.from([...state.data, action.dynStock]),
        error: null);
  }
  if (action is CreateDynStockFailAction) {
    return DynStocksState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: false,
        creating: false,
        created: false,
        createFailed: true,
        updating: state.updating,
        updated: state.updated,
        updateFailed: false,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: false,
        data: List.empty(),
        error: action.error);
  }
  if (action is UpdateDynStockAction) {
    return DynStocksState.updatedState(
      loading: state.loading,
      loaded: state.loaded,
      loadFailed: false,
      created: state.created,
      creating: state.creating,
      createFailed: false,
      updating: true,
      updated: false,
      updateFailed: false,
      deleting: state.deleting,
      deleted: state.deleted,
      deleteFailed: false,
      data: state.data,
    );
  }
  if (action is UpdateDynStockSuccessAction) {
    return DynStocksState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: false,
        created: state.created,
        creating: state.creating,
        createFailed: false,
        updating: false,
        updated: true,
        updateFailed: false,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: false,
        data: state.data.map((item) {
          if (item.dynStockId == action.dynStock.dynStockId) {
            return action.dynStock;
          } else {
            return item;
          }
        }).toList(),
        error: null);
  }
  if (action is UpdateDynStockFailAction) {
    return DynStocksState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: false,
        created: state.created,
        creating: state.creating,
        createFailed: false,
        updating: false,
        updated: false,
        updateFailed: true,
        deleting: state.deleting,
        deleted: state.deleted,
        deleteFailed: false,
        data: List.empty(),
        error: action.error);
  }
  if (action is DeleteDynStockAction) {
    return DynStocksState.updatedState(
      loading: state.loading,
      loaded: state.loaded,
      loadFailed: false,
      created: state.created,
      creating: state.creating,
      createFailed: false,
      updating: state.updating,
      updated: state.updated,
      updateFailed: false,
      deleting: true,
      deleted: false,
      deleteFailed: false,
      data: state.data,
    );
  }
  if (action is DeleteDynStockSuccessAction) {
    return DynStocksState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: false,
        created: state.created,
        creating: state.creating,
        createFailed: false,
        updating: false,
        updated: true,
        updateFailed: true,
        deleting: false,
        deleted: true,
        deleteFailed: false,
        data: state.data.where((item) {
          return (item.dynStockId != action.dynStockId);
        }).toList(),
        error: null);
  }
  if (action is DeleteDynStockFailAction) {
    return DynStocksState.updatedState(
        loading: state.loading,
        loaded: state.loaded,
        loadFailed: false,
        created: state.created,
        creating: state.creating,
        createFailed: false,
        updating: state.updating,
        updated: state.updated,
        updateFailed: false,
        deleting: false,
        deleted: false,
        deleteFailed: true,
        data: List.empty(),
        error: action.error);
  }

  return state;
}
