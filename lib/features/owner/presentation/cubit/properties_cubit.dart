import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_system/core/session/session_repository.dart';
import 'package:rent_system/core/supabase/rentflow_supabase_service.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';

enum PropertyFilter { all, occupied, vacant }

enum PropertySort { name, rent, tenants }

class PropertiesState extends Equatable {
  const PropertiesState({
    this.items = const [],
    this.filter = PropertyFilter.all,
    this.sort = PropertySort.name,
    this.loading = false,
  });

  final List<PropertyItem> items;
  final PropertyFilter filter;
  final PropertySort sort;
  final bool loading;

  PropertiesState copyWith({
    List<PropertyItem>? items,
    PropertyFilter? filter,
    PropertySort? sort,
    bool? loading,
  }) {
    return PropertiesState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [items, filter, sort, loading];
}

class PropertiesCubit extends Cubit<PropertiesState> {
  PropertiesCubit({
    required SessionRepository session,
    required RentflowSupabaseService db,
  })  : _session = session,
        _db = db,
        super(const PropertiesState(loading: true)) {
    load();
  }

  final SessionRepository _session;
  final RentflowSupabaseService _db;

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true));
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
      return;
    }
    try {
      final items = await _db.fetchOwnerProperties(uid);
      if (!isClosed) emit(state.copyWith(items: items, loading: false));
    } on Exception {
      if (!isClosed) emit(state.copyWith(items: [], loading: false));
    }
  }

  Future<void> addProperty({
    required String name,
    required String location,
    required int unitsTotal,
    required double baseRent,
    String? address,
  }) async {
    final uid = _session.readUser()?.userId ?? '';
    if (uid.isEmpty) return;
    await _db.insertProperty(
      ownerId: uid,
      name: name,
      location: location,
      unitsTotal: unitsTotal,
      baseRent: baseRent,
      address: address,
    );
    await load();
  }

  void setFilter(PropertyFilter f) => emit(state.copyWith(filter: f));

  void setSort(PropertySort s) => emit(state.copyWith(sort: s));

  List<PropertyItem> filteredSorted() {
    var list = List<PropertyItem>.of(state.items);
    switch (state.filter) {
      case PropertyFilter.occupied:
        list = list.where((p) => p.tenantsOccupied > 0).toList();
      case PropertyFilter.vacant:
        list = list.where((p) => p.isVacant).toList();
      case PropertyFilter.all:
        break;
    }
    switch (state.sort) {
      case PropertySort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case PropertySort.rent:
        list.sort((a, b) => b.baseRent.compareTo(a.baseRent));
      case PropertySort.tenants:
        list.sort((a, b) => b.tenantsOccupied.compareTo(a.tenantsOccupied));
    }
    return list;
  }
}
