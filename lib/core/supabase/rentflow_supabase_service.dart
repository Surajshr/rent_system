import 'package:intl/intl.dart';
import 'package:rent_system/core/errors/app_exception.dart';
import 'package:rent_system/core/network/network_info.dart';
import 'package:rent_system/features/auth/domain/user_role.dart';
import 'package:rent_system/features/owner/domain/entities/owner_models.dart';
import 'package:rent_system/features/renter/domain/entities/renter_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Row in [profiles] (backed by Supabase).
class ProfileRow {
  const ProfileRow({
    required this.id,
    required this.displayName,
    required this.role,
    this.phone,
    this.email,
  });

  final String id;
  final String displayName;
  final UserRole role;
  final String? phone;
  final String? email;

  UserRole get userRole => role;
}

/// Summary for the renter "Pay rent" screen and payment recording.
class PayRentInvoiceSummary {
  const PayRentInvoiceSummary({
    required this.billId,
    required this.paymentId,
    required this.propertyName,
    required this.amount,
    required this.dueLabel,
    required this.billNumber,
    required this.landlordName,
  });

  final String billId;
  final String paymentId;
  final String propertyName;
  final double amount;
  final String dueLabel;

  /// Human-readable bill number from [bills.bill_number].
  final String billNumber;
  final String landlordName;
}

/// Loaded lease + dashboard figures for a renter profile.
class RenterLeaseSummary {
  const RenterLeaseSummary.empty()
    : hasLease = false,
      propertyName = '',
      landlordName = '',
      landlordPhone = '',
      landlordEmail = '',
      currentAmount = 0,
      dueLabel = '',
      daysRemaining = 0,
      isPaid = false,
      nextPaymentDate = '',
      nextPaymentAmount = 0,
      lastPaidDate = '',
      lastPaidAmount = 0,
      lastBillRef = '',
      annualTotal = 0,
      annualPaid = 0,
      annualRemaining = 0,
      primaryBillId = null,
      primaryPaymentId = null;

  const RenterLeaseSummary({
    required this.hasLease,
    required this.propertyName,
    required this.landlordName,
    required this.landlordPhone,
    required this.landlordEmail,
    required this.currentAmount,
    required this.dueLabel,
    required this.daysRemaining,
    required this.isPaid,
    required this.nextPaymentDate,
    required this.nextPaymentAmount,
    required this.lastPaidDate,
    required this.lastPaidAmount,
    required this.lastBillRef,
    required this.annualTotal,
    required this.annualPaid,
    required this.annualRemaining,
    required this.primaryBillId,
    required this.primaryPaymentId,
  });

  final bool hasLease;
  final String propertyName;
  final String landlordName;
  final String landlordPhone;
  final String landlordEmail;
  final double currentAmount;
  final String dueLabel;
  final int daysRemaining;
  final bool isPaid;
  final String nextPaymentDate;
  final double nextPaymentAmount;
  final String lastPaidDate;
  final double lastPaidAmount;
  final String lastBillRef;
  final double annualTotal;
  final double annualPaid;
  final double annualRemaining;
  final String? primaryBillId;
  final String? primaryPaymentId;
}

/// One listed Storage file and a URL string for Flutter image widgets.
class StorageImageRef {
  const StorageImageRef({
    required this.name,
    required this.objectPath,
    required this.url,
  });

  /// File name in this listing (typically the last segment of [objectPath]).
  final String name;

  /// Full object path within the bucket.
  final String objectPath;

  /// Usable with Flutter `Image.network` or similar.
  final String url;
}

/// Pending cash payment that requires owner verification.
class CashVerificationRow {
  const CashVerificationRow({
    required this.paymentId,
    required this.propertyName,
    required this.tenantName,
    required this.amount,
    required this.billRef,
    required this.requestedOn,
  });

  final String paymentId;
  final String propertyName;
  final String tenantName;
  final double amount;
  final String billRef;
  final String requestedOn;
}

/// Reads and writes RentFlow tables via the Supabase client (RLS applies).
///
/// Apply [supabase/migrations/001_rentflow_schema.sql] in the Supabase SQL editor
/// before using the app against a new project.
///
/// **Storage** — same project URL/key as [Supabase.initialize] in `bootstrap.dart`.
///
/// See the [Storage quickstart](https://supabase.com/docs/guides/storage/quickstart)
/// (create bucket, upload paths, objects policies). Use only
/// `SupabaseClient.storage.from(bucketId)` in Dart (no S3 endpoint in the app).
///
/// Default Postgres tables live in `supabase/migrations/001_rentflow_schema.sql`.
class RentflowSupabaseService {
  RentflowSupabaseService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Override via `--dart-define=RENTFLOW_STORAGE_BUCKET=my-bucket`
  /// when the default bucket name is not used.
  static const String kRentflowStorageBucketDefault = String.fromEnvironment(
    'RENTFLOW_STORAGE_BUCKET',
    defaultValue: 'rentflow-public',
  );

  /// Bucket for payment QR images (owner dashboard gallery).
  /// Override with `--dart-define=RENTFLOW_QR_BUCKET=…`.
  static const String kQrCodesBucket = String.fromEnvironment(
    'RENTFLOW_QR_BUCKET',
    defaultValue: 'qr_codes',
  );

  /// Path prefix inside [kQrCodesBucket] (e.g. `payment_qr/`).
  /// Override with `--dart-define=RENTFLOW_PAYMENT_QR_FOLDER=…`.
  static const String kPaymentQrFolder = String.fromEnvironment(
    'RENTFLOW_PAYMENT_QR_FOLDER',
    defaultValue: 'payment_qr',
  );

  static final RegExp _imageFileSuffix = RegExp(
    r'\.(png|jpg|jpeg|gif|webp|svg)$',
    caseSensitive: false,
  );

  static AppException _wrap(Object e, [String? fallback]) {
    if (e is AppException) return e;
    if (NetworkInfo.isNetworkError(e)) {
      return const AppException(NetworkInfo.offlineMessage, code: 'offline');
    }
    if (e is AuthException) {
      return AppException(
        e.message.isNotEmpty ? e.message : 'Authentication failed.',
      );
    }
    if (e is PostgrestException) {
      return AppException(
        e.message.isNotEmpty ? e.message : (fallback ?? 'Request failed'),
      );
    }
    if (e is StorageException) {
      return AppException(
        e.message.isNotEmpty
            ? e.message
            : (fallback ?? 'Storage request failed'),
      );
    }
    return AppException(fallback ?? 'Something went wrong. Please try again.');
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('MMM d, y').format(d.toLocal());
  }

  String _fmtMonthDay(DateTime? d) {
    if (d == null) return '';
    return DateFormat('MMMM d, y').format(d.toLocal());
  }

  UserRole _parseRole(String? r) =>
      r == 'renter' ? UserRole.renter : UserRole.owner;

  TenantPayStatus _parseTenantPay(String? s) {
    switch (s) {
      case 'paid':
        return TenantPayStatus.paid;
      case 'overdue':
        return TenantPayStatus.overdue;
      default:
        return TenantPayStatus.due;
    }
  }

  PaymentStatus _parsePaymentStatus(String? s) {
    switch (s) {
      case 'paid':
        return PaymentStatus.paid;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  RenterBillStatus _parseBillStatus(String? s) {
    switch (s) {
      case 'paid':
        return RenterBillStatus.paid;
      case 'overdue':
        return RenterBillStatus.overdue;
      default:
        return RenterBillStatus.pending;
    }
  }

  Future<ProfileRow?> fetchProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return ProfileRow(
        id: row['id'] as String,
        displayName: row['display_name'] as String? ?? '',
        role: _parseRole(row['role'] as String?),
        phone: row['phone'] as String?,
        email: row['email'] as String?,
      );
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load profile');
    }
  }

  /// Upserts a profile via the [setup_my_profile] security-definer RPC.
  ///
  /// Passes [userId] explicitly because [auth.uid()] can return null
  /// immediately after signup before the JWT propagates.  The SQL function
  /// still validates ownership when [auth.uid()] IS available.
  Future<void> upsertProfileFromSignup({
    required String userId,
    required String displayName,
    required UserRole role,
    required String phone,
    required String email,
  }) async {
    try {
      await _client.rpc(
        'setup_my_profile',
        params: {
          'p_user_id': userId,
          'p_display_name': displayName,
          'p_role': role.name,
          'p_phone': phone,
          'p_email': email,
        },
      );
    } on Exception catch (e) {
      throw _wrap(e, 'Could not save profile');
    }
  }

  Future<double> sumTenantMonthlyRentForOwner(String ownerId) async {
    try {
      final rows = await _client
          .from('tenants')
          .select('monthly_rent')
          .eq('owner_id', ownerId);
      final list = rows as List<dynamic>;
      var sum = 0.0;
      for (final r in list) {
        final m = r as Map<String, dynamic>;
        sum += (m['monthly_rent'] as num?)?.toDouble() ?? 0;
      }
      return sum;
    } on Exception catch (e) {
      throw _wrap(e);
    }
  }

  Future<int> countTenantsCreatedSince(
    String ownerId,
    DateTime sinceUtc,
  ) async {
    try {
      final rows = await _client
          .from('tenants')
          .select('id')
          .eq('owner_id', ownerId)
          .gte('created_at', sinceUtc.toIso8601String());
      return (rows as List).length;
    } on Exception catch (e) {
      throw _wrap(e);
    }
  }

  Future<List<PropertyItem>> fetchOwnerProperties(String ownerId) async {
    try {
      final props = await _client
          .from('properties')
          .select('id, name, location, units_total, base_rent')
          .eq('owner_id', ownerId)
          .order('name');
      final tenants = await _client
          .from('tenants')
          .select('property_id')
          .eq('owner_id', ownerId);
      final counts = <String, int>{};
      for (final t in tenants as List<dynamic>) {
        final m = t as Map<String, dynamic>;
        final pid = m['property_id'] as String?;
        if (pid == null) continue;
        counts[pid] = (counts[pid] ?? 0) + 1;
      }
      final out = <PropertyItem>[];
      for (final r in props as List<dynamic>) {
        final m = r as Map<String, dynamic>;
        final id = m['id'] as String;
        out.add(
          PropertyItem(
            id: id,
            name: m['name'] as String? ?? '',
            location: m['location'] as String? ?? '',
            tenantsOccupied: counts[id] ?? 0,
            unitsTotal: (m['units_total'] as num?)?.toInt() ?? 1,
            baseRent: (m['base_rent'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
      return out;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load properties');
    }
  }

  Future<void> insertProperty({
    required String ownerId,
    required String name,
    required String location,
    required int unitsTotal,
    required double baseRent,
    String? address,
  }) async {
    try {
      await _client.from('properties').insert({
        'owner_id': ownerId,
        'name': name,
        'location': location,
        'units_total': unitsTotal,
        'base_rent': baseRent,
        if (address != null && address.isNotEmpty) 'address': address,
      });
    } on Exception catch (e) {
      throw _wrap(e, 'Could not add property');
    }
  }

  Future<List<TenantItem>> fetchOwnerTenants(String ownerId) async {
    try {
      final rows = await _client
          .from('tenants')
          .select('''
            id, property_id, name, unit, phone, email,
            monthly_rent, payment_status, renter_profile_id,
            properties ( name )
          ''')
          .eq('owner_id', ownerId)
          .order('name');
      final out = <TenantItem>[];
      for (final r in rows as List<dynamic>) {
        final m = r as Map<String, dynamic>;
        final prop = m['properties'];
        String propName = '';
        if (prop is Map<String, dynamic>) {
          propName = prop['name'] as String? ?? '';
        }
        out.add(
          TenantItem(
            id: m['id'] as String,
            propertyId: m['property_id'] as String? ?? '',
            name: m['name'] as String? ?? '',
            propertyName: propName,
            unit: m['unit'] as String? ?? '',
            phone: m['phone'] as String? ?? '',
            email: m['email'] as String? ?? '',
            rentAmount: (m['monthly_rent'] as num?)?.toDouble() ?? 0,
            status: _parseTenantPay(m['payment_status'] as String?),
            renterProfileId: m['renter_profile_id'] as String?,
          ),
        );
      }
      return out;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load tenants');
    }
  }

  Future<void> insertTenant({
    required String ownerId,
    required String propertyId,
    required String name,
    required String unit,
    required double monthlyRent,
    String phone = '',
    String email = '',
    DateTime? moveInDate,
  }) async {
    try {
      await _client.from('tenants').insert({
        'owner_id': ownerId,
        'property_id': propertyId,
        'name': name.trim(),
        'unit': unit.trim(),
        'monthly_rent': monthlyRent,
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (email.trim().isNotEmpty) 'email': email.trim(),
        if (moveInDate != null)
          'move_in_date': moveInDate.toIso8601String().split('T').first,
        'payment_status': 'due',
      });
    } on Exception catch (e) {
      throw _wrap(e, 'Could not add tenant');
    }
  }

  /// Links a renter account to a tenant row via the [link_renter_to_tenant]
  /// security-definer RPC.
  ///
  /// WHY RPC: The `profiles` RLS only lets a user read their own profile or
  /// their landlord's — an owner cannot query a stranger renter's profile
  /// directly.  The function bypasses RLS for the lookup while enforcing
  /// ownership inside Postgres.
  Future<void> linkRenterByEmail({
    required String tenantId,
    required String renterEmail,
  }) async {
    try {
      final result =
          await _client.rpc(
                'link_renter_to_tenant',
                params: {
                  'p_tenant_id': tenantId,
                  'p_renter_email': renterEmail.trim(),
                },
              )
              as Map<String, dynamic>;

      final error = result['error'] as String?;
      if (error != null && error.isNotEmpty) {
        throw AppException(error);
      }
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not link renter');
    }
  }

  Future<void> unlinkRenter(String tenantId) async {
    try {
      await _client
          .from('tenants')
          .update({'renter_profile_id': null})
          .eq('id', tenantId);
    } on Exception catch (e) {
      throw _wrap(e, 'Could not unlink renter');
    }
  }

  Future<void> updateTenant({
    required String tenantId,
    required String name,
    required String unit,
    required double monthlyRent,
    String phone = '',
    String email = '',
  }) async {
    try {
      await _client
          .from('tenants')
          .update({
            'name': name.trim(),
            'unit': unit.trim(),
            'monthly_rent': monthlyRent,
            'phone': phone.trim().isEmpty ? null : phone.trim(),
            'email': email.trim().isEmpty ? null : email.trim(),
          })
          .eq('id', tenantId);
    } on Exception catch (e) {
      throw _wrap(e, 'Could not update tenant');
    }
  }

  Future<List<PaymentRow>> fetchOwnerPayments(String ownerId) async {
    try {
      final rows = await _client
          .from('payments')
          .select('''
            id, amount, status, paid_at, created_at, transaction_ref,
            bills ( bill_number, due_date ),
            tenants ( name ),
            properties ( name )
          ''')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      final out = <PaymentRow>[];
      for (final r in rows as List<dynamic>) {
        final m = r as Map<String, dynamic>;
        final bill = m['bills'];
        final tenant = m['tenants'];
        final property = m['properties'];
        String billRef = '';
        String due = '';
        if (bill is Map<String, dynamic>) {
          billRef = bill['bill_number'] as String? ?? '';
          final dd = bill['due_date'];
          if (dd is String) {
            due = _fmtDate(DateTime.tryParse(dd));
          }
        }
        String tenantName = '';
        if (tenant is Map<String, dynamic>) {
          tenantName = tenant['name'] as String? ?? '';
        }
        String propertyName = '';
        if (property is Map<String, dynamic>) {
          propertyName = property['name'] as String? ?? '';
        }
        final paidAt = m['paid_at'];
        String? paidDate;
        if (paidAt is String) {
          final p = DateTime.tryParse(paidAt);
          paidDate = p != null ? _fmtDate(p) : null;
        }
        out.add(
          PaymentRow(
            id: m['id'] as String,
            propertyName: propertyName,
            tenantName: tenantName,
            amount: (m['amount'] as num?)?.toDouble() ?? 0,
            dueDate: due,
            status: _parsePaymentStatus(m['status'] as String?),
            billRef: billRef,
            paidDate: paidDate,
          ),
        );
      }
      return out;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load payments');
    }
  }

  Future<void> markOwnerPaymentPaid(String paymentId) async {
    try {
      final row = await _client
          .from('payments')
          .select('bill_id')
          .eq('id', paymentId)
          .maybeSingle();
      if (row == null) throw const AppException('Payment not found');
      final billId = row['bill_id'] as String;
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('payments')
          .update({
            'status': 'paid',
            'paid_at': now,
            'method': 'Manual',
          })
          .eq('id', paymentId);
      await _client.from('bills').update({'status': 'paid'}).eq('id', billId);
    } on Exception catch (e) {
      throw _wrap(e, 'Could not update payment');
    }
  }

  Future<List<CashVerificationRow>> fetchOwnerCashVerifications(
    String ownerId,
  ) async {
    try {
      final rows = await _client
          .from('payments')
          .select('''
            id, amount, created_at, method,
            bills ( bill_number, properties ( name ) ),
            tenants ( name ),
          ''')
          .eq('owner_id', ownerId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      final out = <CashVerificationRow>[];
      for (final r in rows as List<dynamic>) {
        final m = r as Map<String, dynamic>;
        final method = (m['method'] as String?)?.trim().toLowerCase() ?? '';
        if (method != 'cash') {
          continue;
        }
        final createdAt = m['created_at'] as String?;
        final bill = m['bills'] as Map<String, dynamic>?;
        final tenant = m['tenants'] as Map<String, dynamic>?;
        final property = bill?['properties'] as Map<String, dynamic>?;
        out.add(
          CashVerificationRow(
            paymentId: m['id'] as String,
            propertyName: property?['name'] as String? ?? '',
            tenantName: tenant?['name'] as String? ?? 'Tenant',
            amount: (m['amount'] as num?)?.toDouble() ?? 0,
            billRef: bill?['bill_number'] as String? ?? '',
            requestedOn: _fmtDate(DateTime.tryParse(createdAt ?? '')),
          ),
        );
      }
      return out;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load cash verification queue');
    }
  }

  Future<void> verifyCashPaymentReceived(String paymentId) async {
    try {
      final row = await _client
          .from('payments')
          .select('bill_id')
          .eq('id', paymentId)
          .eq('status', 'pending')
          .maybeSingle();
      if (row == null) throw const AppException('Cash payment not found');
      final billId = row['bill_id'] as String;
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('payments')
          .update({'status': 'paid', 'paid_at': now})
          .eq('id', paymentId);
      await _client.from('bills').update({'status': 'paid'}).eq('id', billId);
    } on Exception catch (e) {
      throw _wrap(e, 'Could not verify cash payment');
    }
  }

  Future<List<ActivityItem>> fetchRecentActivities(
    String ownerId, {
    int limit = 6,
  }) async {
    try {
      final rows = await _client
          .from('payments')
          .select('amount, status, created_at, paid_at, tenants ( name )')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false)
          .limit(limit);
      final out = <ActivityItem>[];
      for (final r in rows as List<dynamic>) {
        final m = r as Map<String, dynamic>;
        final tenant = m['tenants'];
        var name = 'Tenant';
        if (tenant is Map<String, dynamic>) {
          name = tenant['name'] as String? ?? name;
        }
        final status = m['status'] as String? ?? '';
        final title = status == 'paid' ? 'Rent received' : 'Payment update';
        final when = m['paid_at'] as String? ?? m['created_at'] as String?;
        final dt = DateTime.tryParse(when ?? '') ?? DateTime.now();
        out.add(
          ActivityItem(
            title: title,
            subtitle: name,
            amount: (m['amount'] as num?)?.toDouble() ?? 0,
            timeLabel: DateFormat('MMM d, h:mm a').format(dt.toLocal()),
          ),
        );
      }
      return out;
    } on Exception catch (e) {
      throw _wrap(e);
    }
  }

  Future<Map<String, dynamic>> fetchOwnerDashboardMetrics(
    String ownerId,
  ) async {
    try {
      final props = await _client
          .from('properties')
          .select('id')
          .eq('owner_id', ownerId);
      final tenants = await _client
          .from('tenants')
          .select('id')
          .eq('owner_id', ownerId);
      final payments = await _client
          .from('payments')
          .select('amount, status, paid_at')
          .eq('owner_id', ownerId);
      final now = DateTime.now();
      final startMonth = DateTime.utc(now.year, now.month, 1);
      var collected = 0.0;
      var pending = 0.0;
      var overdue = 0;
      for (final r in payments as List<dynamic>) {
        final m = r as Map<String, dynamic>;
        final amt = (m['amount'] as num?)?.toDouble() ?? 0;
        final st = m['status'] as String? ?? '';
        if (st == 'paid') {
          final paidAt = m['paid_at'] as String?;
          final p = paidAt != null ? DateTime.tryParse(paidAt)?.toUtc() : null;
          if (p != null && !p.isBefore(startMonth)) {
            collected += amt;
          }
        } else if (st == 'overdue') {
          overdue += 1;
          pending += amt;
        } else if (st == 'pending' || st == 'failed') {
          pending += amt;
        }
      }
      final newTenants = await countTenantsCreatedSince(ownerId, startMonth);
      return {
        'totalProperties': (props as List).length,
        'activeTenants': (tenants as List).length,
        'collectedThisMonth': collected,
        'pendingAmount': pending,
        'overdueCount': overdue,
        'newTenantsThisMonth': newTenants,
      };
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load dashboard');
    }
  }

  Future<String> createBillWithPayment({
    required String ownerId,
    required String tenantId,
    required String propertyId,
    required double totalAmount,
    required DateTime dueDate,
    required String notes,
    required Map<String, dynamic> lineItems,
  }) async {
    try {
      final billNumber =
          'RF-${DateTime.now().millisecondsSinceEpoch % 100000000}';
      final billRes = await _client
          .from('bills')
          .insert({
            'owner_id': ownerId,
            'tenant_id': tenantId,
            'property_id': propertyId,
            'bill_number': billNumber,
            'amount': totalAmount,
            'due_date': dueDate.toIso8601String().split('T').first,
            'status': 'pending',
            'notes': notes,
            'line_items': lineItems,
          })
          .select('id')
          .single();
      final billId = billRes['id'] as String;
      await _client.from('payments').insert({
        'bill_id': billId,
        'owner_id': ownerId,
        'tenant_id': tenantId,
        'amount': totalAmount,
        'status': 'pending',
      });
      return billNumber;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not create bill');
    }
  }

  Future<RenterBill?> fetchBillForRenter({
    required String renterProfileId,
    required String billId,
  }) async {
    try {
      final row = await _client
          .from('bills')
          .select()
          .eq('id', billId)
          .maybeSingle();
      if (row == null) return null;
      final tenantId = row['tenant_id'] as String;
      final tenant = await _client
          .from('tenants')
          .select('renter_profile_id')
          .eq('id', tenantId)
          .maybeSingle();
      if (tenant == null) return null;
      if ((tenant['renter_profile_id'] as String?) != renterProfileId)
        return null;
      return _mapBillRow(row);
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load bill');
    }
  }

  RenterBill _mapBillRow(Map<String, dynamic> row) {
    final created = row['created_at'] as String?;
    final due = row['due_date'] as String?;
    final line = row['line_items'];
    var base = (row['amount'] as num?)?.toDouble() ?? 0;
    final charges = <String, double>{};
    final deductions = <String, double>{};
    if (line is Map<String, dynamic>) {
      final br = line['base_rent'];
      if (br is num) base = br.toDouble();
      final ch = line['charges'];
      if (ch is List) {
        for (final e in ch) {
          if (e is Map<String, dynamic>) {
            final d = e['description'] as String? ?? 'Charge';
            final a = (e['amount'] as num?)?.toDouble() ?? 0;
            charges[d] = a;
          }
        }
      }
      final ded = line['deductions'];
      if (ded is List) {
        for (final e in ded) {
          if (e is Map<String, dynamic>) {
            final d = e['description'] as String? ?? 'Deduction';
            final a = (e['amount'] as num?)?.toDouble() ?? 0;
            deductions[d] = a;
          }
        }
      }
    }
    return RenterBill(
      id: row['id'] as String,
      generatedOn: _fmtDate(
        created != null ? DateTime.tryParse(created) : null,
      ),
      dueDate: due != null ? _fmtDate(DateTime.tryParse(due)) : '',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      status: _parseBillStatus(row['status'] as String?),
      baseRent: base,
      charges: charges,
      deductions: deductions,
    );
  }

  Future<List<RenterBill>> fetchRenterBills(String renterProfileId) async {
    try {
      final tenantRows = await _client
          .from('tenants')
          .select('id')
          .eq('renter_profile_id', renterProfileId);
      final ids = (tenantRows as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      if (ids.isEmpty) return [];
      final rows = await _client
          .from('bills')
          .select()
          .inFilter('tenant_id', ids)
          .order(
            'created_at',
            ascending: false,
          );
      return (rows as List<dynamic>)
          .map((r) => _mapBillRow(r as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load bills');
    }
  }

  Future<List<RenterPaymentHistoryItem>> fetchRenterPaymentHistory(
    String renterProfileId,
  ) async {
    try {
      final tenantRows = await _client
          .from('tenants')
          .select('id')
          .eq('renter_profile_id', renterProfileId);
      final ids = (tenantRows as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      if (ids.isEmpty) return [];
      final rows = await _client
          .from('payments')
          .select(
            'amount, status, paid_at, created_at, method, transaction_ref, bills ( bill_number )',
          )
          .inFilter('tenant_id', ids)
          .order('created_at', ascending: false);
      final out = <RenterPaymentHistoryItem>[];
      for (final r in rows as List<dynamic>) {
        final m = r as Map<String, dynamic>;
        final bill = m['bills'];
        var ref = '';
        if (bill is Map<String, dynamic>) {
          ref = bill['bill_number'] as String? ?? '';
        }
        final paidAt = m['paid_at'] as String?;
        final created = m['created_at'] as String?;
        out.add(
          RenterPaymentHistoryItem(
            billDate: _fmtDate(DateTime.tryParse(created ?? '')?.toLocal()),
            amount: (m['amount'] as num?)?.toDouble() ?? 0,
            status: m['status'] as String? ?? '',
            transactionId: m['transaction_ref'] as String? ?? '—',
            method: m['method'] as String? ?? '—',
            paidOn: paidAt != null ? _fmtDate(DateTime.tryParse(paidAt)) : '—',
            billRef: ref,
          ),
        );
      }
      return out;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load payment history');
    }
  }

  Future<RenterLeaseSummary> fetchRenterLeaseSummary(
    String renterProfileId,
  ) async {
    try {
      final tenant = await _client
          .from('tenants')
          .select(
            'id, owner_id, monthly_rent, property_id, properties ( name )',
          )
          .eq('renter_profile_id', renterProfileId)
          .limit(1)
          .maybeSingle();
      if (tenant == null) return const RenterLeaseSummary.empty();

      final tenantId = tenant['id'] as String;
      final ownerId = tenant['owner_id'] as String;
      final monthly = (tenant['monthly_rent'] as num?)?.toDouble() ?? 0;
      var propertyName = '';
      final prop = tenant['properties'];
      if (prop is Map<String, dynamic>) {
        propertyName = prop['name'] as String? ?? '';
      }

      final landlord = await _client
          .from('profiles')
          .select()
          .eq('id', ownerId)
          .maybeSingle();
      final landlordName = landlord?['display_name'] as String? ?? 'Landlord';
      final landlordPhone = landlord?['phone'] as String? ?? '';
      final landlordEmail = landlord?['email'] as String? ?? '';

      final bills = await _client
          .from('bills')
          .select('id, bill_number, amount, due_date, status, created_at')
          .eq('tenant_id', tenantId)
          .order('due_date', ascending: false);

      final payments = await _client
          .from('payments')
          .select('id, amount, status, paid_at, bill_id')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      final billList = bills as List<dynamic>;
      final payList = payments as List<dynamic>;

      Map<String, dynamic>? nextDueBill;
      for (final b in billList) {
        final m = b as Map<String, dynamic>;
        if ((m['status'] as String?) != 'paid') {
          nextDueBill = m;
          break;
        }
      }
      nextDueBill ??= billList.isNotEmpty
          ? billList.first as Map<String, dynamic>
          : null;

      String? primaryBillId;
      String? primaryPaymentId;
      double currentAmount = 0;
      var dueLabel = '';
      var daysRemaining = 0;
      var isPaid = true;
      if (nextDueBill != null) {
        primaryBillId = nextDueBill['id'] as String;
        currentAmount = (nextDueBill['amount'] as num?)?.toDouble() ?? 0;
        final dueStr = nextDueBill['due_date'] as String?;
        final due = dueStr != null ? DateTime.tryParse(dueStr) : null;
        if (due != null) {
          dueLabel = _fmtMonthDay(due);
          daysRemaining = due.difference(DateTime.now()).inDays;
        }
        final st = nextDueBill['status'] as String? ?? '';
        isPaid = st == 'paid';
        for (final p in payList) {
          final pm = p as Map<String, dynamic>;
          if ((pm['bill_id'] as String?) == primaryBillId &&
              (pm['status'] as String?) == 'pending') {
            primaryPaymentId = pm['id'] as String?;
            break;
          }
        }
      }

      Map<String, dynamic>? lastPaid;
      for (final p in payList) {
        final pm = p as Map<String, dynamic>;
        if ((pm['status'] as String?) == 'paid') {
          lastPaid = pm;
          break;
        }
      }

      var lastPaidDate = '';
      var lastPaidAmount = 0.0;
      var lastBillRef = '';
      if (lastPaid != null) {
        lastPaidAmount = (lastPaid['amount'] as num?)?.toDouble() ?? 0;
        final pt = lastPaid['paid_at'] as String?;
        lastPaidDate = pt != null ? _fmtMonthDay(DateTime.tryParse(pt)) : '';
        final bid = lastPaid['bill_id'] as String?;
        if (bid != null) {
          for (final b in billList) {
            final bm = b as Map<String, dynamic>;
            if ((bm['id'] as String?) == bid) {
              lastBillRef = bm['bill_number'] as String? ?? bid;
              break;
            }
          }
        }
      }

      final year = DateTime.now().year;
      var annualTotal = 0.0;
      var annualPaid = 0.0;
      for (final b in billList) {
        final bm = b as Map<String, dynamic>;
        final c = bm['created_at'] as String?;
        final cd = c != null ? DateTime.tryParse(c)?.toLocal() : null;
        if (cd != null && cd.year == year) {
          annualTotal += (bm['amount'] as num?)?.toDouble() ?? 0;
          if (bm['status'] == 'paid')
            annualPaid += (bm['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      if (annualTotal == 0) annualTotal = monthly * 12;
      final annualRemaining = (annualTotal - annualPaid)
          .clamp(0, double.infinity)
          .toDouble();

      Map<String, dynamic>? nextBillForSchedule;
      for (final b in billList.reversed) {
        final bm = b as Map<String, dynamic>;
        if ((bm['status'] as String?) != 'paid') {
          nextBillForSchedule = bm;
          break;
        }
      }
      nextBillForSchedule ??= billList.isNotEmpty
          ? billList.first as Map<String, dynamic>
          : null;
      var nextPaymentDate = '';
      var nextPaymentAmount = 0.0;
      if (nextBillForSchedule != null) {
        final ds = nextBillForSchedule['due_date'] as String?;
        nextPaymentDate = ds != null ? _fmtMonthDay(DateTime.tryParse(ds)) : '';
        nextPaymentAmount =
            (nextBillForSchedule['amount'] as num?)?.toDouble() ?? monthly;
      }

      return RenterLeaseSummary(
        hasLease: true,
        propertyName: propertyName,
        landlordName: landlordName,
        landlordPhone: landlordPhone,
        landlordEmail: landlordEmail,
        currentAmount: currentAmount,
        dueLabel: dueLabel,
        daysRemaining: daysRemaining,
        isPaid: isPaid,
        nextPaymentDate: nextPaymentDate,
        nextPaymentAmount: nextPaymentAmount,
        lastPaidDate: lastPaidDate,
        lastPaidAmount: lastPaidAmount,
        lastBillRef: lastBillRef,
        annualTotal: annualTotal,
        annualPaid: annualPaid,
        annualRemaining: annualRemaining,
        primaryBillId: primaryBillId,
        primaryPaymentId: primaryPaymentId,
      );
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load renter dashboard');
    }
  }

  Future<PayRentInvoiceSummary?> fetchPayRentSummary({
    required String renterProfileId,
    required String billId,
  }) async {
    final bill = await fetchBillForRenter(
      renterProfileId: renterProfileId,
      billId: billId,
    );
    if (bill == null) return null;
    try {
      final billRow = await _client
          .from('bills')
          .select('bill_number')
          .eq('id', billId)
          .maybeSingle();
      final billNumber = billRow?['bill_number'] as String? ?? billId;
      final pay = await _client
          .from('payments')
          .select('id')
          .eq('bill_id', billId)
          .eq('status', 'pending')
          .maybeSingle();
      if (pay == null) return null;
      final lease = await fetchRenterLeaseSummary(renterProfileId);
      return PayRentInvoiceSummary(
        billId: billId,
        paymentId: pay['id'] as String,
        propertyName: lease.propertyName,
        amount: bill.amount,
        dueLabel: bill.dueDate,
        billNumber: billNumber,
        landlordName: lease.landlordName,
      );
    } on Exception catch (e) {
      throw _wrap(e);
    }
  }

  /// Marks the payment and linked bill paid.
  /// Returns the new transaction reference.
  Future<String> recordRenterPayment({
    required String paymentId,
    required String methodLabel,
  }) async {
    try {
      final row = await _client
          .from('payments')
          .select('bill_id')
          .eq('id', paymentId)
          .maybeSingle();
      if (row == null) throw const AppException('Payment not found');
      final billId = row['bill_id'] as String;
      final ref = 'RF-${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().toUtc().toIso8601String();
      await _client
          .from('payments')
          .update({
            'status': 'paid',
            'paid_at': now,
            'method': methodLabel,
            'transaction_ref': ref,
          })
          .eq('id', paymentId);
      await _client.from('bills').update({'status': 'paid'}).eq('id', billId);
      return ref;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not record payment');
    }
  }

  /// Records a renter-side cash payment request without marking paid yet.
  /// Owner must verify from dashboard.
  Future<String> recordRenterCashSubmission({
    required String paymentId,
  }) async {
    try {
      final ref = 'CASH-${DateTime.now().millisecondsSinceEpoch}';
      final updated = await _client
          .from('payments')
          .update({'method': 'Cash', 'transaction_ref': ref})
          .eq('id', paymentId)
          .eq('status', 'pending')
          .select('id')
          .maybeSingle();
      if (updated == null) {
        throw const AppException(
          'Could not submit cash payment request. Payment is not pending.',
        );
      }
      return ref;
    } on Exception catch (e) {
      throw _wrap(e, 'Could not submit cash payment request');
    }
  }

  /// Normalizes folder prefix passed to `.list(path: …)`.
  ///
  /// Supabase treats this like a key prefix (no leading `/`; avoid a trailing `/`).
  String _normalizeStorageFolderPrefix(String folderPath) {
    final segments = folderPath.trim().split('/')
      ..removeWhere((s) => s.isEmpty);
    return segments.join('/');
  }

  /// Object key relative to the bucket: `payment_qr/logo.png`.
  ///
  /// [listedName] is [FileObject.name] from `.list` under [folderPrefix].
  String _bucketObjectKey(String folderPrefix, String listedName) {
    final name = listedName.trim();
    if (name.isEmpty || name.endsWith('/')) {
      return '';
    }
    final prefix = folderPrefix.trim();
    if (prefix.isEmpty) {
      return name;
    }
    // Avoid `prefix/prefix/file` if the API ever returns paths from bucket root.
    if (name.startsWith('$prefix/') || name == prefix) {
      return name;
    }
    return '$prefix/$name';
  }

  /// Lists image files via Storage `list`, then resolves URLs.
  ///
  /// Docs: Storage quickstart + Dart `storage-from-list`
  /// (`supabase.storage.from(bucket).list(path: folder, searchOptions: …)`).
  ///
  /// For private buckets, keep [useSignedUrls] true — `Image.network`
  /// loads URLs without auth headers.
  /// Set [useSignedUrls] false only when the bucket is public.
  Future<List<StorageImageRef>> fetchStorageImageFiles({
    String bucket = kRentflowStorageBucketDefault,
    String folderPath = 'images',
    bool useSignedUrls = true,
    int signedUrlExpiresSeconds = 3600,
    SearchOptions searchOptions = const SearchOptions(),
  }) async {
    try {
      final folder = _normalizeStorageFolderPrefix(folderPath);
      final storage = _client.storage.from(bucket);

      // `path`: folder inside the bucket; null/'' = list bucket root per SDK.
      final listPath = folder.isEmpty ? null : folder;

      final objects = await storage.list(
        path: listPath,
        searchOptions: searchOptions,
      );

      final imageObjects = <FileObject>[];
      for (final o in objects) {
        if (!_imageFileSuffix.hasMatch(o.name)) {
          continue;
        }
        if (_bucketObjectKey(folder, o.name).isEmpty) {
          continue;
        }
        imageObjects.add(o);
      }
      if (imageObjects.isEmpty) {
        return const [];
      }

      final keys = imageObjects
          .map((o) => _bucketObjectKey(folder, o.name))
          .toList(growable: false);

      if (useSignedUrls) {
        final signed = await storage.createSignedUrls(
          keys,
          signedUrlExpiresSeconds,
        );
        final out = <StorageImageRef>[];
        for (var i = 0; i < imageObjects.length; i++) {
          final key = keys[i];
          final url = i < signed.length ? signed[i].signedUrl : '';
          if (url.isEmpty) {
            continue;
          }
          out.add(
            StorageImageRef(
              name: imageObjects[i].name,
              objectPath: key,
              url: url,
            ),
          );
        }
        return out;
      }

      return [
        for (var i = 0; i < imageObjects.length; i++)
          StorageImageRef(
            name: imageObjects[i].name,
            objectPath: keys[i],
            url: storage.getPublicUrl(keys[i]),
          ),
      ];
    } on Exception catch (e) {
      throw _wrap(e, 'Could not load images');
    }
  }
}
