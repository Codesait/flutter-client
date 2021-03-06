import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/product/product_screen.dart';
import 'package:invoiceninja_flutter/ui/product/view/product_view.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/redux/product/product_actions.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/ui/app/snackbar_row.dart';

class ProductViewScreen extends StatelessWidget {
  const ProductViewScreen({Key key}) : super(key: key);

  static const String route = '/product/view';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ProductViewVM>(
      distinct: true,
      converter: (Store<AppState> store) {
        return ProductViewVM.fromStore(store);
      },
      builder: (context, vm) {
        return ProductView(
          viewModel: vm,
        );
      },
    );
  }
}

class ProductViewVM {
  ProductViewVM({
    @required this.product,
    @required this.company,
    @required this.onEntityAction,
    @required this.onEditPressed,
    @required this.onBackPressed,
    @required this.isSaving,
    @required this.isLoading,
    @required this.isDirty,
    @required this.onRefreshed,
  });

  factory ProductViewVM.fromStore(Store<AppState> store) {
    final state = store.state;
    final product = state.productState.map[state.productUIState.selectedId] ??
        ProductEntity(id: state.productUIState.selectedId);

    /*
    Future<Null> _handleRefresh(BuildContext context, bool loadActivities) {
      final completer = snackBarCompleter(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(LoadProduct(
          completer: completer,
          productId: product.id,
          loadActivities: loadActivities));
      return completer.future;
    }
    */

    return ProductViewVM(
      isSaving: state.isSaving,
      isLoading: state.isLoading,
      isDirty: product.isNew,
      product: product,
      company: state.selectedCompany,
      onEditPressed: (BuildContext context) {
        final Completer<ProductEntity> completer = Completer<ProductEntity>();
        store.dispatch(EditProduct(
            product: product, context: context, completer: completer));
        completer.future.then((product) {
          Scaffold.of(context).showSnackBar(SnackBar(
              content: SnackBarRow(
            message: AppLocalization.of(context).updatedProduct,
          )));
        });
      },
      onRefreshed: null,
      /*
      onRefreshed: (context, loadActivities) =>
          _handleRefresh(context, loadActivities),
          */
      onBackPressed: () {
        if (state.uiState.currentRoute.contains(ProductScreen.route)) {
          store.dispatch(UpdateCurrentRoute(ProductScreen.route));
        }
      },
      onEntityAction: (BuildContext context, EntityAction action) =>
          handleProductAction(context, product, action),
    );
  }

  final ProductEntity product;
  final CompanyEntity company;
  final Function(BuildContext, EntityAction) onEntityAction;
  final Function(BuildContext) onEditPressed;
  final Function onBackPressed;
  final Function(BuildContext, bool) onRefreshed;
  final bool isSaving;
  final bool isLoading;
  final bool isDirty;

  @override
  bool operator ==(dynamic other) =>
      product == other.product && company == other.company;

  @override
  int get hashCode => product.hashCode ^ company.hashCode;
}
