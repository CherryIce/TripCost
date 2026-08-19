// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CurrenciesTable extends Currencies
    with TableInfo<$CurrenciesTable, Currency> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numericCodeMeta = const VerificationMeta(
    'numericCode',
  );
  @override
  late final GeneratedColumn<String> numericCode = GeneratedColumn<String>(
    'numeric_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minorUnitsMeta = const VerificationMeta(
    'minorUnits',
  );
  @override
  late final GeneratedColumn<int> minorUnits = GeneratedColumn<int>(
    'minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodesJsonMeta = const VerificationMeta(
    'countryCodesJson',
  );
  @override
  late final GeneratedColumn<String> countryCodesJson = GeneratedColumn<String>(
    'country_codes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    numericCode,
    name,
    symbol,
    minorUnits,
    countryCodesJson,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Currency> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('numeric_code')) {
      context.handle(
        _numericCodeMeta,
        numericCode.isAcceptableOrUnknown(
          data['numeric_code']!,
          _numericCodeMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('minor_units')) {
      context.handle(
        _minorUnitsMeta,
        minorUnits.isAcceptableOrUnknown(data['minor_units']!, _minorUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_minorUnitsMeta);
    }
    if (data.containsKey('country_codes_json')) {
      context.handle(
        _countryCodesJsonMeta,
        countryCodesJson.isAcceptableOrUnknown(
          data['country_codes_json']!,
          _countryCodesJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  Currency map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Currency(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      numericCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numeric_code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      minorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minor_units'],
      )!,
      countryCodesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_codes_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CurrenciesTable createAlias(String alias) {
    return $CurrenciesTable(attachedDatabase, alias);
  }
}

class Currency extends DataClass implements Insertable<Currency> {
  final String code;
  final String? numericCode;
  final String name;
  final String symbol;
  final int minorUnits;
  final String countryCodesJson;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Currency({
    required this.code,
    this.numericCode,
    required this.name,
    required this.symbol,
    required this.minorUnits,
    required this.countryCodesJson,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || numericCode != null) {
      map['numeric_code'] = Variable<String>(numericCode);
    }
    map['name'] = Variable<String>(name);
    map['symbol'] = Variable<String>(symbol);
    map['minor_units'] = Variable<int>(minorUnits);
    map['country_codes_json'] = Variable<String>(countryCodesJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CurrenciesCompanion toCompanion(bool nullToAbsent) {
    return CurrenciesCompanion(
      code: Value(code),
      numericCode: numericCode == null && nullToAbsent
          ? const Value.absent()
          : Value(numericCode),
      name: Value(name),
      symbol: Value(symbol),
      minorUnits: Value(minorUnits),
      countryCodesJson: Value(countryCodesJson),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Currency.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Currency(
      code: serializer.fromJson<String>(json['code']),
      numericCode: serializer.fromJson<String?>(json['numericCode']),
      name: serializer.fromJson<String>(json['name']),
      symbol: serializer.fromJson<String>(json['symbol']),
      minorUnits: serializer.fromJson<int>(json['minorUnits']),
      countryCodesJson: serializer.fromJson<String>(json['countryCodesJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'numericCode': serializer.toJson<String?>(numericCode),
      'name': serializer.toJson<String>(name),
      'symbol': serializer.toJson<String>(symbol),
      'minorUnits': serializer.toJson<int>(minorUnits),
      'countryCodesJson': serializer.toJson<String>(countryCodesJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Currency copyWith({
    String? code,
    Value<String?> numericCode = const Value.absent(),
    String? name,
    String? symbol,
    int? minorUnits,
    String? countryCodesJson,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Currency(
    code: code ?? this.code,
    numericCode: numericCode.present ? numericCode.value : this.numericCode,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    minorUnits: minorUnits ?? this.minorUnits,
    countryCodesJson: countryCodesJson ?? this.countryCodesJson,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Currency copyWithCompanion(CurrenciesCompanion data) {
    return Currency(
      code: data.code.present ? data.code.value : this.code,
      numericCode: data.numericCode.present
          ? data.numericCode.value
          : this.numericCode,
      name: data.name.present ? data.name.value : this.name,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      minorUnits: data.minorUnits.present
          ? data.minorUnits.value
          : this.minorUnits,
      countryCodesJson: data.countryCodesJson.present
          ? data.countryCodesJson.value
          : this.countryCodesJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Currency(')
          ..write('code: $code, ')
          ..write('numericCode: $numericCode, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('countryCodesJson: $countryCodesJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    code,
    numericCode,
    name,
    symbol,
    minorUnits,
    countryCodesJson,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Currency &&
          other.code == this.code &&
          other.numericCode == this.numericCode &&
          other.name == this.name &&
          other.symbol == this.symbol &&
          other.minorUnits == this.minorUnits &&
          other.countryCodesJson == this.countryCodesJson &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CurrenciesCompanion extends UpdateCompanion<Currency> {
  final Value<String> code;
  final Value<String?> numericCode;
  final Value<String> name;
  final Value<String> symbol;
  final Value<int> minorUnits;
  final Value<String> countryCodesJson;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CurrenciesCompanion({
    this.code = const Value.absent(),
    this.numericCode = const Value.absent(),
    this.name = const Value.absent(),
    this.symbol = const Value.absent(),
    this.minorUnits = const Value.absent(),
    this.countryCodesJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrenciesCompanion.insert({
    required String code,
    this.numericCode = const Value.absent(),
    required String name,
    required String symbol,
    required int minorUnits,
    this.countryCodesJson = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       symbol = Value(symbol),
       minorUnits = Value(minorUnits),
       updatedAt = Value(updatedAt);
  static Insertable<Currency> custom({
    Expression<String>? code,
    Expression<String>? numericCode,
    Expression<String>? name,
    Expression<String>? symbol,
    Expression<int>? minorUnits,
    Expression<String>? countryCodesJson,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (numericCode != null) 'numeric_code': numericCode,
      if (name != null) 'name': name,
      if (symbol != null) 'symbol': symbol,
      if (minorUnits != null) 'minor_units': minorUnits,
      if (countryCodesJson != null) 'country_codes_json': countryCodesJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrenciesCompanion copyWith({
    Value<String>? code,
    Value<String?>? numericCode,
    Value<String>? name,
    Value<String>? symbol,
    Value<int>? minorUnits,
    Value<String>? countryCodesJson,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CurrenciesCompanion(
      code: code ?? this.code,
      numericCode: numericCode ?? this.numericCode,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      minorUnits: minorUnits ?? this.minorUnits,
      countryCodesJson: countryCodesJson ?? this.countryCodesJson,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (numericCode.present) {
      map['numeric_code'] = Variable<String>(numericCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (minorUnits.present) {
      map['minor_units'] = Variable<int>(minorUnits.value);
    }
    if (countryCodesJson.present) {
      map['country_codes_json'] = Variable<String>(countryCodesJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrenciesCompanion(')
          ..write('code: $code, ')
          ..write('numericCode: $numericCode, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('minorUnits: $minorUnits, ')
          ..write('countryCodesJson: $countryCodesJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RateSnapshotsTable extends RateSnapshots
    with TableInfo<$RateSnapshotsTable, RateSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RateSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _quoteCurrencyMeta = const VerificationMeta(
    'quoteCurrency',
  );
  @override
  late final GeneratedColumn<String> quoteCurrency = GeneratedColumn<String>(
    'quote_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<String> rate = GeneratedColumn<String>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTimestampMeta = const VerificationMeta(
    'sourceTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> sourceTimestamp =
      GeneratedColumn<DateTime>(
        'source_timestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCachedMeta = const VerificationMeta(
    'isCached',
  );
  @override
  late final GeneratedColumn<bool> isCached = GeneratedColumn<bool>(
    'is_cached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    baseCurrency,
    quoteCurrency,
    rate,
    sourceType,
    sourceName,
    sourceTimestamp,
    fetchedAt,
    isCached,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rate_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<RateSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    if (data.containsKey('quote_currency')) {
      context.handle(
        _quoteCurrencyMeta,
        quoteCurrency.isAcceptableOrUnknown(
          data['quote_currency']!,
          _quoteCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quoteCurrencyMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('source_timestamp')) {
      context.handle(
        _sourceTimestampMeta,
        sourceTimestamp.isAcceptableOrUnknown(
          data['source_timestamp']!,
          _sourceTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceTimestampMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('is_cached')) {
      context.handle(
        _isCachedMeta,
        isCached.isAcceptableOrUnknown(data['is_cached']!, _isCachedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RateSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RateSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      quoteCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_currency'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      sourceTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_timestamp'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      isCached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cached'],
      )!,
    );
  }

  @override
  $RateSnapshotsTable createAlias(String alias) {
    return $RateSnapshotsTable(attachedDatabase, alias);
  }
}

class RateSnapshot extends DataClass implements Insertable<RateSnapshot> {
  final String id;
  final int syncVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String baseCurrency;
  final String quoteCurrency;
  final String rate;
  final String sourceType;
  final String sourceName;
  final DateTime sourceTimestamp;
  final DateTime fetchedAt;
  final bool isCached;
  const RateSnapshot({
    required this.id,
    required this.syncVersion,
    required this.updatedAt,
    this.deletedAt,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.sourceType,
    required this.sourceName,
    required this.sourceTimestamp,
    required this.fetchedAt,
    required this.isCached,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_version'] = Variable<int>(syncVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['base_currency'] = Variable<String>(baseCurrency);
    map['quote_currency'] = Variable<String>(quoteCurrency);
    map['rate'] = Variable<String>(rate);
    map['source_type'] = Variable<String>(sourceType);
    map['source_name'] = Variable<String>(sourceName);
    map['source_timestamp'] = Variable<DateTime>(sourceTimestamp);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['is_cached'] = Variable<bool>(isCached);
    return map;
  }

  RateSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return RateSnapshotsCompanion(
      id: Value(id),
      syncVersion: Value(syncVersion),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      baseCurrency: Value(baseCurrency),
      quoteCurrency: Value(quoteCurrency),
      rate: Value(rate),
      sourceType: Value(sourceType),
      sourceName: Value(sourceName),
      sourceTimestamp: Value(sourceTimestamp),
      fetchedAt: Value(fetchedAt),
      isCached: Value(isCached),
    );
  }

  factory RateSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RateSnapshot(
      id: serializer.fromJson<String>(json['id']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      quoteCurrency: serializer.fromJson<String>(json['quoteCurrency']),
      rate: serializer.fromJson<String>(json['rate']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      sourceTimestamp: serializer.fromJson<DateTime>(json['sourceTimestamp']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      isCached: serializer.fromJson<bool>(json['isCached']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'quoteCurrency': serializer.toJson<String>(quoteCurrency),
      'rate': serializer.toJson<String>(rate),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceName': serializer.toJson<String>(sourceName),
      'sourceTimestamp': serializer.toJson<DateTime>(sourceTimestamp),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'isCached': serializer.toJson<bool>(isCached),
    };
  }

  RateSnapshot copyWith({
    String? id,
    int? syncVersion,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? baseCurrency,
    String? quoteCurrency,
    String? rate,
    String? sourceType,
    String? sourceName,
    DateTime? sourceTimestamp,
    DateTime? fetchedAt,
    bool? isCached,
  }) => RateSnapshot(
    id: id ?? this.id,
    syncVersion: syncVersion ?? this.syncVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    quoteCurrency: quoteCurrency ?? this.quoteCurrency,
    rate: rate ?? this.rate,
    sourceType: sourceType ?? this.sourceType,
    sourceName: sourceName ?? this.sourceName,
    sourceTimestamp: sourceTimestamp ?? this.sourceTimestamp,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    isCached: isCached ?? this.isCached,
  );
  RateSnapshot copyWithCompanion(RateSnapshotsCompanion data) {
    return RateSnapshot(
      id: data.id.present ? data.id.value : this.id,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      quoteCurrency: data.quoteCurrency.present
          ? data.quoteCurrency.value
          : this.quoteCurrency,
      rate: data.rate.present ? data.rate.value : this.rate,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      sourceTimestamp: data.sourceTimestamp.present
          ? data.sourceTimestamp.value
          : this.sourceTimestamp,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      isCached: data.isCached.present ? data.isCached.value : this.isCached,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RateSnapshot(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('quoteCurrency: $quoteCurrency, ')
          ..write('rate: $rate, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceTimestamp: $sourceTimestamp, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('isCached: $isCached')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    baseCurrency,
    quoteCurrency,
    rate,
    sourceType,
    sourceName,
    sourceTimestamp,
    fetchedAt,
    isCached,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RateSnapshot &&
          other.id == this.id &&
          other.syncVersion == this.syncVersion &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.baseCurrency == this.baseCurrency &&
          other.quoteCurrency == this.quoteCurrency &&
          other.rate == this.rate &&
          other.sourceType == this.sourceType &&
          other.sourceName == this.sourceName &&
          other.sourceTimestamp == this.sourceTimestamp &&
          other.fetchedAt == this.fetchedAt &&
          other.isCached == this.isCached);
}

class RateSnapshotsCompanion extends UpdateCompanion<RateSnapshot> {
  final Value<String> id;
  final Value<int> syncVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> baseCurrency;
  final Value<String> quoteCurrency;
  final Value<String> rate;
  final Value<String> sourceType;
  final Value<String> sourceName;
  final Value<DateTime> sourceTimestamp;
  final Value<DateTime> fetchedAt;
  final Value<bool> isCached;
  final Value<int> rowid;
  const RateSnapshotsCompanion({
    this.id = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.quoteCurrency = const Value.absent(),
    this.rate = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.sourceTimestamp = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.isCached = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RateSnapshotsCompanion.insert({
    required String id,
    this.syncVersion = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String baseCurrency,
    required String quoteCurrency,
    required String rate,
    required String sourceType,
    required String sourceName,
    required DateTime sourceTimestamp,
    required DateTime fetchedAt,
    this.isCached = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       baseCurrency = Value(baseCurrency),
       quoteCurrency = Value(quoteCurrency),
       rate = Value(rate),
       sourceType = Value(sourceType),
       sourceName = Value(sourceName),
       sourceTimestamp = Value(sourceTimestamp),
       fetchedAt = Value(fetchedAt);
  static Insertable<RateSnapshot> custom({
    Expression<String>? id,
    Expression<int>? syncVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? baseCurrency,
    Expression<String>? quoteCurrency,
    Expression<String>? rate,
    Expression<String>? sourceType,
    Expression<String>? sourceName,
    Expression<DateTime>? sourceTimestamp,
    Expression<DateTime>? fetchedAt,
    Expression<bool>? isCached,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (quoteCurrency != null) 'quote_currency': quoteCurrency,
      if (rate != null) 'rate': rate,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceName != null) 'source_name': sourceName,
      if (sourceTimestamp != null) 'source_timestamp': sourceTimestamp,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (isCached != null) 'is_cached': isCached,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RateSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<int>? syncVersion,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? baseCurrency,
    Value<String>? quoteCurrency,
    Value<String>? rate,
    Value<String>? sourceType,
    Value<String>? sourceName,
    Value<DateTime>? sourceTimestamp,
    Value<DateTime>? fetchedAt,
    Value<bool>? isCached,
    Value<int>? rowid,
  }) {
    return RateSnapshotsCompanion(
      id: id ?? this.id,
      syncVersion: syncVersion ?? this.syncVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      quoteCurrency: quoteCurrency ?? this.quoteCurrency,
      rate: rate ?? this.rate,
      sourceType: sourceType ?? this.sourceType,
      sourceName: sourceName ?? this.sourceName,
      sourceTimestamp: sourceTimestamp ?? this.sourceTimestamp,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isCached: isCached ?? this.isCached,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (quoteCurrency.present) {
      map['quote_currency'] = Variable<String>(quoteCurrency.value);
    }
    if (rate.present) {
      map['rate'] = Variable<String>(rate.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (sourceTimestamp.present) {
      map['source_timestamp'] = Variable<DateTime>(sourceTimestamp.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (isCached.present) {
      map['is_cached'] = Variable<bool>(isCached.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RateSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('quoteCurrency: $quoteCurrency, ')
          ..write('rate: $rate, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceTimestamp: $sourceTimestamp, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('isCached: $isCached, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTable extends PaymentMethods
    with TableInfo<$PaymentMethodsTable, PaymentMethod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _networkMeta = const VerificationMeta(
    'network',
  );
  @override
  late final GeneratedColumn<String> network = GeneratedColumn<String>(
    'network',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billingCurrencyMeta = const VerificationMeta(
    'billingCurrency',
  );
  @override
  late final GeneratedColumn<String> billingCurrency = GeneratedColumn<String>(
    'billing_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _foreignFeePercentMeta = const VerificationMeta(
    'foreignFeePercent',
  );
  @override
  late final GeneratedColumn<String> foreignFeePercent =
      GeneratedColumn<String>(
        'foreign_fee_percent',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _crossBorderFeePercentMeta =
      const VerificationMeta('crossBorderFeePercent');
  @override
  late final GeneratedColumn<String> crossBorderFeePercent =
      GeneratedColumn<String>(
        'cross_border_fee_percent',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _rateMarkupPercentMeta = const VerificationMeta(
    'rateMarkupPercent',
  );
  @override
  late final GeneratedColumn<String> rateMarkupPercent =
      GeneratedColumn<String>(
        'rate_markup_percent',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fixedFeeMeta = const VerificationMeta(
    'fixedFee',
  );
  @override
  late final GeneratedColumn<String> fixedFee = GeneratedColumn<String>(
    'fixed_fee',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashbackPercentMeta = const VerificationMeta(
    'cashbackPercent',
  );
  @override
  late final GeneratedColumn<String> cashbackPercent = GeneratedColumn<String>(
    'cashback_percent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minimumFeeMeta = const VerificationMeta(
    'minimumFee',
  );
  @override
  late final GeneratedColumn<String> minimumFee = GeneratedColumn<String>(
    'minimum_fee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maximumFeeMeta = const VerificationMeta(
    'maximumFee',
  );
  @override
  late final GeneratedColumn<String> maximumFee = GeneratedColumn<String>(
    'maximum_fee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashExchangeRateMeta = const VerificationMeta(
    'cashExchangeRate',
  );
  @override
  late final GeneratedColumn<String> cashExchangeRate = GeneratedColumn<String>(
    'cash_exchange_rate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supportedTxnTypesJsonMeta =
      const VerificationMeta('supportedTxnTypesJson');
  @override
  late final GeneratedColumn<String> supportedTxnTypesJson =
      GeneratedColumn<String>(
        'supported_txn_types_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveFrom =
      GeneratedColumn<DateTime>(
        'effective_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastVerifiedAtMeta = const VerificationMeta(
    'lastVerifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastVerifiedAt =
      GeneratedColumn<DateTime>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    name,
    type,
    network,
    billingCurrency,
    foreignFeePercent,
    crossBorderFeePercent,
    rateMarkupPercent,
    fixedFee,
    cashbackPercent,
    minimumFee,
    maximumFee,
    cashExchangeRate,
    supportedTxnTypesJson,
    sourceUrl,
    effectiveFrom,
    lastVerifiedAt,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentMethod> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('network')) {
      context.handle(
        _networkMeta,
        network.isAcceptableOrUnknown(data['network']!, _networkMeta),
      );
    } else if (isInserting) {
      context.missing(_networkMeta);
    }
    if (data.containsKey('billing_currency')) {
      context.handle(
        _billingCurrencyMeta,
        billingCurrency.isAcceptableOrUnknown(
          data['billing_currency']!,
          _billingCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_billingCurrencyMeta);
    }
    if (data.containsKey('foreign_fee_percent')) {
      context.handle(
        _foreignFeePercentMeta,
        foreignFeePercent.isAcceptableOrUnknown(
          data['foreign_fee_percent']!,
          _foreignFeePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foreignFeePercentMeta);
    }
    if (data.containsKey('cross_border_fee_percent')) {
      context.handle(
        _crossBorderFeePercentMeta,
        crossBorderFeePercent.isAcceptableOrUnknown(
          data['cross_border_fee_percent']!,
          _crossBorderFeePercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_crossBorderFeePercentMeta);
    }
    if (data.containsKey('rate_markup_percent')) {
      context.handle(
        _rateMarkupPercentMeta,
        rateMarkupPercent.isAcceptableOrUnknown(
          data['rate_markup_percent']!,
          _rateMarkupPercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rateMarkupPercentMeta);
    }
    if (data.containsKey('fixed_fee')) {
      context.handle(
        _fixedFeeMeta,
        fixedFee.isAcceptableOrUnknown(data['fixed_fee']!, _fixedFeeMeta),
      );
    } else if (isInserting) {
      context.missing(_fixedFeeMeta);
    }
    if (data.containsKey('cashback_percent')) {
      context.handle(
        _cashbackPercentMeta,
        cashbackPercent.isAcceptableOrUnknown(
          data['cashback_percent']!,
          _cashbackPercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashbackPercentMeta);
    }
    if (data.containsKey('minimum_fee')) {
      context.handle(
        _minimumFeeMeta,
        minimumFee.isAcceptableOrUnknown(data['minimum_fee']!, _minimumFeeMeta),
      );
    }
    if (data.containsKey('maximum_fee')) {
      context.handle(
        _maximumFeeMeta,
        maximumFee.isAcceptableOrUnknown(data['maximum_fee']!, _maximumFeeMeta),
      );
    }
    if (data.containsKey('cash_exchange_rate')) {
      context.handle(
        _cashExchangeRateMeta,
        cashExchangeRate.isAcceptableOrUnknown(
          data['cash_exchange_rate']!,
          _cashExchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('supported_txn_types_json')) {
      context.handle(
        _supportedTxnTypesJsonMeta,
        supportedTxnTypesJson.isAcceptableOrUnknown(
          data['supported_txn_types_json']!,
          _supportedTxnTypesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_supportedTxnTypesJsonMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
        _lastVerifiedAtMeta,
        lastVerifiedAt.isAcceptableOrUnknown(
          data['last_verified_at']!,
          _lastVerifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethod(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      network: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network'],
      )!,
      billingCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_currency'],
      )!,
      foreignFeePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foreign_fee_percent'],
      )!,
      crossBorderFeePercent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cross_border_fee_percent'],
      )!,
      rateMarkupPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_markup_percent'],
      )!,
      fixedFee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_fee'],
      )!,
      cashbackPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashback_percent'],
      )!,
      minimumFee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}minimum_fee'],
      ),
      maximumFee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}maximum_fee'],
      ),
      cashExchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cash_exchange_rate'],
      ),
      supportedTxnTypesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supported_txn_types_json'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_from'],
      ),
      lastVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_verified_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PaymentMethodsTable createAlias(String alias) {
    return $PaymentMethodsTable(attachedDatabase, alias);
  }
}

class PaymentMethod extends DataClass implements Insertable<PaymentMethod> {
  final String id;
  final int syncVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;
  final String type;
  final String network;
  final String billingCurrency;
  final String foreignFeePercent;
  final String crossBorderFeePercent;
  final String rateMarkupPercent;
  final String fixedFee;
  final String cashbackPercent;
  final String? minimumFee;
  final String? maximumFee;
  final String? cashExchangeRate;
  final String supportedTxnTypesJson;
  final String? sourceUrl;
  final DateTime? effectiveFrom;
  final DateTime? lastVerifiedAt;
  final String? notes;
  final DateTime createdAt;
  const PaymentMethod({
    required this.id,
    required this.syncVersion,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.type,
    required this.network,
    required this.billingCurrency,
    required this.foreignFeePercent,
    required this.crossBorderFeePercent,
    required this.rateMarkupPercent,
    required this.fixedFee,
    required this.cashbackPercent,
    this.minimumFee,
    this.maximumFee,
    this.cashExchangeRate,
    required this.supportedTxnTypesJson,
    this.sourceUrl,
    this.effectiveFrom,
    this.lastVerifiedAt,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_version'] = Variable<int>(syncVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['network'] = Variable<String>(network);
    map['billing_currency'] = Variable<String>(billingCurrency);
    map['foreign_fee_percent'] = Variable<String>(foreignFeePercent);
    map['cross_border_fee_percent'] = Variable<String>(crossBorderFeePercent);
    map['rate_markup_percent'] = Variable<String>(rateMarkupPercent);
    map['fixed_fee'] = Variable<String>(fixedFee);
    map['cashback_percent'] = Variable<String>(cashbackPercent);
    if (!nullToAbsent || minimumFee != null) {
      map['minimum_fee'] = Variable<String>(minimumFee);
    }
    if (!nullToAbsent || maximumFee != null) {
      map['maximum_fee'] = Variable<String>(maximumFee);
    }
    if (!nullToAbsent || cashExchangeRate != null) {
      map['cash_exchange_rate'] = Variable<String>(cashExchangeRate);
    }
    map['supported_txn_types_json'] = Variable<String>(supportedTxnTypesJson);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || effectiveFrom != null) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom);
    }
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsCompanion(
      id: Value(id),
      syncVersion: Value(syncVersion),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      type: Value(type),
      network: Value(network),
      billingCurrency: Value(billingCurrency),
      foreignFeePercent: Value(foreignFeePercent),
      crossBorderFeePercent: Value(crossBorderFeePercent),
      rateMarkupPercent: Value(rateMarkupPercent),
      fixedFee: Value(fixedFee),
      cashbackPercent: Value(cashbackPercent),
      minimumFee: minimumFee == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumFee),
      maximumFee: maximumFee == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumFee),
      cashExchangeRate: cashExchangeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(cashExchangeRate),
      supportedTxnTypesJson: Value(supportedTxnTypesJson),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      effectiveFrom: effectiveFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveFrom),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PaymentMethod.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethod(
      id: serializer.fromJson<String>(json['id']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      network: serializer.fromJson<String>(json['network']),
      billingCurrency: serializer.fromJson<String>(json['billingCurrency']),
      foreignFeePercent: serializer.fromJson<String>(json['foreignFeePercent']),
      crossBorderFeePercent: serializer.fromJson<String>(
        json['crossBorderFeePercent'],
      ),
      rateMarkupPercent: serializer.fromJson<String>(json['rateMarkupPercent']),
      fixedFee: serializer.fromJson<String>(json['fixedFee']),
      cashbackPercent: serializer.fromJson<String>(json['cashbackPercent']),
      minimumFee: serializer.fromJson<String?>(json['minimumFee']),
      maximumFee: serializer.fromJson<String?>(json['maximumFee']),
      cashExchangeRate: serializer.fromJson<String?>(json['cashExchangeRate']),
      supportedTxnTypesJson: serializer.fromJson<String>(
        json['supportedTxnTypesJson'],
      ),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      effectiveFrom: serializer.fromJson<DateTime?>(json['effectiveFrom']),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'network': serializer.toJson<String>(network),
      'billingCurrency': serializer.toJson<String>(billingCurrency),
      'foreignFeePercent': serializer.toJson<String>(foreignFeePercent),
      'crossBorderFeePercent': serializer.toJson<String>(crossBorderFeePercent),
      'rateMarkupPercent': serializer.toJson<String>(rateMarkupPercent),
      'fixedFee': serializer.toJson<String>(fixedFee),
      'cashbackPercent': serializer.toJson<String>(cashbackPercent),
      'minimumFee': serializer.toJson<String?>(minimumFee),
      'maximumFee': serializer.toJson<String?>(maximumFee),
      'cashExchangeRate': serializer.toJson<String?>(cashExchangeRate),
      'supportedTxnTypesJson': serializer.toJson<String>(supportedTxnTypesJson),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'effectiveFrom': serializer.toJson<DateTime?>(effectiveFrom),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PaymentMethod copyWith({
    String? id,
    int? syncVersion,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? type,
    String? network,
    String? billingCurrency,
    String? foreignFeePercent,
    String? crossBorderFeePercent,
    String? rateMarkupPercent,
    String? fixedFee,
    String? cashbackPercent,
    Value<String?> minimumFee = const Value.absent(),
    Value<String?> maximumFee = const Value.absent(),
    Value<String?> cashExchangeRate = const Value.absent(),
    String? supportedTxnTypesJson,
    Value<String?> sourceUrl = const Value.absent(),
    Value<DateTime?> effectiveFrom = const Value.absent(),
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => PaymentMethod(
    id: id ?? this.id,
    syncVersion: syncVersion ?? this.syncVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    type: type ?? this.type,
    network: network ?? this.network,
    billingCurrency: billingCurrency ?? this.billingCurrency,
    foreignFeePercent: foreignFeePercent ?? this.foreignFeePercent,
    crossBorderFeePercent: crossBorderFeePercent ?? this.crossBorderFeePercent,
    rateMarkupPercent: rateMarkupPercent ?? this.rateMarkupPercent,
    fixedFee: fixedFee ?? this.fixedFee,
    cashbackPercent: cashbackPercent ?? this.cashbackPercent,
    minimumFee: minimumFee.present ? minimumFee.value : this.minimumFee,
    maximumFee: maximumFee.present ? maximumFee.value : this.maximumFee,
    cashExchangeRate: cashExchangeRate.present
        ? cashExchangeRate.value
        : this.cashExchangeRate,
    supportedTxnTypesJson: supportedTxnTypesJson ?? this.supportedTxnTypesJson,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    effectiveFrom: effectiveFrom.present
        ? effectiveFrom.value
        : this.effectiveFrom,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  PaymentMethod copyWithCompanion(PaymentMethodsCompanion data) {
    return PaymentMethod(
      id: data.id.present ? data.id.value : this.id,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      network: data.network.present ? data.network.value : this.network,
      billingCurrency: data.billingCurrency.present
          ? data.billingCurrency.value
          : this.billingCurrency,
      foreignFeePercent: data.foreignFeePercent.present
          ? data.foreignFeePercent.value
          : this.foreignFeePercent,
      crossBorderFeePercent: data.crossBorderFeePercent.present
          ? data.crossBorderFeePercent.value
          : this.crossBorderFeePercent,
      rateMarkupPercent: data.rateMarkupPercent.present
          ? data.rateMarkupPercent.value
          : this.rateMarkupPercent,
      fixedFee: data.fixedFee.present ? data.fixedFee.value : this.fixedFee,
      cashbackPercent: data.cashbackPercent.present
          ? data.cashbackPercent.value
          : this.cashbackPercent,
      minimumFee: data.minimumFee.present
          ? data.minimumFee.value
          : this.minimumFee,
      maximumFee: data.maximumFee.present
          ? data.maximumFee.value
          : this.maximumFee,
      cashExchangeRate: data.cashExchangeRate.present
          ? data.cashExchangeRate.value
          : this.cashExchangeRate,
      supportedTxnTypesJson: data.supportedTxnTypesJson.present
          ? data.supportedTxnTypesJson.value
          : this.supportedTxnTypesJson,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethod(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('network: $network, ')
          ..write('billingCurrency: $billingCurrency, ')
          ..write('foreignFeePercent: $foreignFeePercent, ')
          ..write('crossBorderFeePercent: $crossBorderFeePercent, ')
          ..write('rateMarkupPercent: $rateMarkupPercent, ')
          ..write('fixedFee: $fixedFee, ')
          ..write('cashbackPercent: $cashbackPercent, ')
          ..write('minimumFee: $minimumFee, ')
          ..write('maximumFee: $maximumFee, ')
          ..write('cashExchangeRate: $cashExchangeRate, ')
          ..write('supportedTxnTypesJson: $supportedTxnTypesJson, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    name,
    type,
    network,
    billingCurrency,
    foreignFeePercent,
    crossBorderFeePercent,
    rateMarkupPercent,
    fixedFee,
    cashbackPercent,
    minimumFee,
    maximumFee,
    cashExchangeRate,
    supportedTxnTypesJson,
    sourceUrl,
    effectiveFrom,
    lastVerifiedAt,
    notes,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethod &&
          other.id == this.id &&
          other.syncVersion == this.syncVersion &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.type == this.type &&
          other.network == this.network &&
          other.billingCurrency == this.billingCurrency &&
          other.foreignFeePercent == this.foreignFeePercent &&
          other.crossBorderFeePercent == this.crossBorderFeePercent &&
          other.rateMarkupPercent == this.rateMarkupPercent &&
          other.fixedFee == this.fixedFee &&
          other.cashbackPercent == this.cashbackPercent &&
          other.minimumFee == this.minimumFee &&
          other.maximumFee == this.maximumFee &&
          other.cashExchangeRate == this.cashExchangeRate &&
          other.supportedTxnTypesJson == this.supportedTxnTypesJson &&
          other.sourceUrl == this.sourceUrl &&
          other.effectiveFrom == this.effectiveFrom &&
          other.lastVerifiedAt == this.lastVerifiedAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PaymentMethodsCompanion extends UpdateCompanion<PaymentMethod> {
  final Value<String> id;
  final Value<int> syncVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> type;
  final Value<String> network;
  final Value<String> billingCurrency;
  final Value<String> foreignFeePercent;
  final Value<String> crossBorderFeePercent;
  final Value<String> rateMarkupPercent;
  final Value<String> fixedFee;
  final Value<String> cashbackPercent;
  final Value<String?> minimumFee;
  final Value<String?> maximumFee;
  final Value<String?> cashExchangeRate;
  final Value<String> supportedTxnTypesJson;
  final Value<String?> sourceUrl;
  final Value<DateTime?> effectiveFrom;
  final Value<DateTime?> lastVerifiedAt;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.network = const Value.absent(),
    this.billingCurrency = const Value.absent(),
    this.foreignFeePercent = const Value.absent(),
    this.crossBorderFeePercent = const Value.absent(),
    this.rateMarkupPercent = const Value.absent(),
    this.fixedFee = const Value.absent(),
    this.cashbackPercent = const Value.absent(),
    this.minimumFee = const Value.absent(),
    this.maximumFee = const Value.absent(),
    this.cashExchangeRate = const Value.absent(),
    this.supportedTxnTypesJson = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentMethodsCompanion.insert({
    required String id,
    this.syncVersion = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required String type,
    required String network,
    required String billingCurrency,
    required String foreignFeePercent,
    required String crossBorderFeePercent,
    required String rateMarkupPercent,
    required String fixedFee,
    required String cashbackPercent,
    this.minimumFee = const Value.absent(),
    this.maximumFee = const Value.absent(),
    this.cashExchangeRate = const Value.absent(),
    required String supportedTxnTypesJson,
    this.sourceUrl = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       name = Value(name),
       type = Value(type),
       network = Value(network),
       billingCurrency = Value(billingCurrency),
       foreignFeePercent = Value(foreignFeePercent),
       crossBorderFeePercent = Value(crossBorderFeePercent),
       rateMarkupPercent = Value(rateMarkupPercent),
       fixedFee = Value(fixedFee),
       cashbackPercent = Value(cashbackPercent),
       supportedTxnTypesJson = Value(supportedTxnTypesJson),
       createdAt = Value(createdAt);
  static Insertable<PaymentMethod> custom({
    Expression<String>? id,
    Expression<int>? syncVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? network,
    Expression<String>? billingCurrency,
    Expression<String>? foreignFeePercent,
    Expression<String>? crossBorderFeePercent,
    Expression<String>? rateMarkupPercent,
    Expression<String>? fixedFee,
    Expression<String>? cashbackPercent,
    Expression<String>? minimumFee,
    Expression<String>? maximumFee,
    Expression<String>? cashExchangeRate,
    Expression<String>? supportedTxnTypesJson,
    Expression<String>? sourceUrl,
    Expression<DateTime>? effectiveFrom,
    Expression<DateTime>? lastVerifiedAt,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (network != null) 'network': network,
      if (billingCurrency != null) 'billing_currency': billingCurrency,
      if (foreignFeePercent != null) 'foreign_fee_percent': foreignFeePercent,
      if (crossBorderFeePercent != null)
        'cross_border_fee_percent': crossBorderFeePercent,
      if (rateMarkupPercent != null) 'rate_markup_percent': rateMarkupPercent,
      if (fixedFee != null) 'fixed_fee': fixedFee,
      if (cashbackPercent != null) 'cashback_percent': cashbackPercent,
      if (minimumFee != null) 'minimum_fee': minimumFee,
      if (maximumFee != null) 'maximum_fee': maximumFee,
      if (cashExchangeRate != null) 'cash_exchange_rate': cashExchangeRate,
      if (supportedTxnTypesJson != null)
        'supported_txn_types_json': supportedTxnTypesJson,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentMethodsCompanion copyWith({
    Value<String>? id,
    Value<int>? syncVersion,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? type,
    Value<String>? network,
    Value<String>? billingCurrency,
    Value<String>? foreignFeePercent,
    Value<String>? crossBorderFeePercent,
    Value<String>? rateMarkupPercent,
    Value<String>? fixedFee,
    Value<String>? cashbackPercent,
    Value<String?>? minimumFee,
    Value<String?>? maximumFee,
    Value<String?>? cashExchangeRate,
    Value<String>? supportedTxnTypesJson,
    Value<String?>? sourceUrl,
    Value<DateTime?>? effectiveFrom,
    Value<DateTime?>? lastVerifiedAt,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PaymentMethodsCompanion(
      id: id ?? this.id,
      syncVersion: syncVersion ?? this.syncVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      type: type ?? this.type,
      network: network ?? this.network,
      billingCurrency: billingCurrency ?? this.billingCurrency,
      foreignFeePercent: foreignFeePercent ?? this.foreignFeePercent,
      crossBorderFeePercent:
          crossBorderFeePercent ?? this.crossBorderFeePercent,
      rateMarkupPercent: rateMarkupPercent ?? this.rateMarkupPercent,
      fixedFee: fixedFee ?? this.fixedFee,
      cashbackPercent: cashbackPercent ?? this.cashbackPercent,
      minimumFee: minimumFee ?? this.minimumFee,
      maximumFee: maximumFee ?? this.maximumFee,
      cashExchangeRate: cashExchangeRate ?? this.cashExchangeRate,
      supportedTxnTypesJson:
          supportedTxnTypesJson ?? this.supportedTxnTypesJson,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (network.present) {
      map['network'] = Variable<String>(network.value);
    }
    if (billingCurrency.present) {
      map['billing_currency'] = Variable<String>(billingCurrency.value);
    }
    if (foreignFeePercent.present) {
      map['foreign_fee_percent'] = Variable<String>(foreignFeePercent.value);
    }
    if (crossBorderFeePercent.present) {
      map['cross_border_fee_percent'] = Variable<String>(
        crossBorderFeePercent.value,
      );
    }
    if (rateMarkupPercent.present) {
      map['rate_markup_percent'] = Variable<String>(rateMarkupPercent.value);
    }
    if (fixedFee.present) {
      map['fixed_fee'] = Variable<String>(fixedFee.value);
    }
    if (cashbackPercent.present) {
      map['cashback_percent'] = Variable<String>(cashbackPercent.value);
    }
    if (minimumFee.present) {
      map['minimum_fee'] = Variable<String>(minimumFee.value);
    }
    if (maximumFee.present) {
      map['maximum_fee'] = Variable<String>(maximumFee.value);
    }
    if (cashExchangeRate.present) {
      map['cash_exchange_rate'] = Variable<String>(cashExchangeRate.value);
    }
    if (supportedTxnTypesJson.present) {
      map['supported_txn_types_json'] = Variable<String>(
        supportedTxnTypesJson.value,
      );
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('network: $network, ')
          ..write('billingCurrency: $billingCurrency, ')
          ..write('foreignFeePercent: $foreignFeePercent, ')
          ..write('crossBorderFeePercent: $crossBorderFeePercent, ')
          ..write('rateMarkupPercent: $rateMarkupPercent, ')
          ..write('fixedFee: $fixedFee, ')
          ..write('cashbackPercent: $cashbackPercent, ')
          ..write('minimumFee: $minimumFee, ')
          ..write('maximumFee: $maximumFee, ')
          ..write('cashExchangeRate: $cashExchangeRate, ')
          ..write('supportedTxnTypesJson: $supportedTxnTypesJson, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationCodesJsonMeta =
      const VerificationMeta('destinationCodesJson');
  @override
  late final GeneratedColumn<String> destinationCodesJson =
      GeneratedColumn<String>(
        'destination_codes_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeCurrencyMeta = const VerificationMeta(
    'homeCurrency',
  );
  @override
  late final GeneratedColumn<String> homeCurrency = GeneratedColumn<String>(
    'home_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _localCurrenciesJsonMeta =
      const VerificationMeta('localCurrenciesJson');
  @override
  late final GeneratedColumn<String> localCurrenciesJson =
      GeneratedColumn<String>(
        'local_currencies_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalBudgetMeta = const VerificationMeta(
    'totalBudget',
  );
  @override
  late final GeneratedColumn<String> totalBudget = GeneratedColumn<String>(
    'total_budget',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _participantCountMeta = const VerificationMeta(
    'participantCount',
  );
  @override
  late final GeneratedColumn<int> participantCount = GeneratedColumn<int>(
    'participant_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _defaultPaymentMethodIdMeta =
      const VerificationMeta('defaultPaymentMethodId');
  @override
  late final GeneratedColumn<String> defaultPaymentMethodId =
      GeneratedColumn<String>(
        'default_payment_method_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES payment_methods (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _offlinePackUpdatedAtMeta =
      const VerificationMeta('offlinePackUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> offlinePackUpdatedAt =
      GeneratedColumn<DateTime>(
        'offline_pack_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    name,
    destinationCodesJson,
    startDate,
    endDate,
    homeCurrency,
    localCurrenciesJson,
    totalBudget,
    participantCount,
    defaultPaymentMethodId,
    offlinePackUpdatedAt,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('destination_codes_json')) {
      context.handle(
        _destinationCodesJsonMeta,
        destinationCodesJson.isAcceptableOrUnknown(
          data['destination_codes_json']!,
          _destinationCodesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationCodesJsonMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('home_currency')) {
      context.handle(
        _homeCurrencyMeta,
        homeCurrency.isAcceptableOrUnknown(
          data['home_currency']!,
          _homeCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_homeCurrencyMeta);
    }
    if (data.containsKey('local_currencies_json')) {
      context.handle(
        _localCurrenciesJsonMeta,
        localCurrenciesJson.isAcceptableOrUnknown(
          data['local_currencies_json']!,
          _localCurrenciesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localCurrenciesJsonMeta);
    }
    if (data.containsKey('total_budget')) {
      context.handle(
        _totalBudgetMeta,
        totalBudget.isAcceptableOrUnknown(
          data['total_budget']!,
          _totalBudgetMeta,
        ),
      );
    }
    if (data.containsKey('participant_count')) {
      context.handle(
        _participantCountMeta,
        participantCount.isAcceptableOrUnknown(
          data['participant_count']!,
          _participantCountMeta,
        ),
      );
    }
    if (data.containsKey('default_payment_method_id')) {
      context.handle(
        _defaultPaymentMethodIdMeta,
        defaultPaymentMethodId.isAcceptableOrUnknown(
          data['default_payment_method_id']!,
          _defaultPaymentMethodIdMeta,
        ),
      );
    }
    if (data.containsKey('offline_pack_updated_at')) {
      context.handle(
        _offlinePackUpdatedAtMeta,
        offlinePackUpdatedAt.isAcceptableOrUnknown(
          data['offline_pack_updated_at']!,
          _offlinePackUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      destinationCodesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_codes_json'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      homeCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_currency'],
      )!,
      localCurrenciesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_currencies_json'],
      )!,
      totalBudget: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}total_budget'],
      ),
      participantCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}participant_count'],
      )!,
      defaultPaymentMethodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_payment_method_id'],
      ),
      offlinePackUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}offline_pack_updated_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final String id;
  final int syncVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;
  final String destinationCodesJson;
  final DateTime startDate;
  final DateTime endDate;
  final String homeCurrency;
  final String localCurrenciesJson;
  final String? totalBudget;
  final int participantCount;
  final String? defaultPaymentMethodId;
  final DateTime? offlinePackUpdatedAt;
  final String status;
  final DateTime createdAt;
  const Trip({
    required this.id,
    required this.syncVersion,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.destinationCodesJson,
    required this.startDate,
    required this.endDate,
    required this.homeCurrency,
    required this.localCurrenciesJson,
    this.totalBudget,
    required this.participantCount,
    this.defaultPaymentMethodId,
    this.offlinePackUpdatedAt,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_version'] = Variable<int>(syncVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['destination_codes_json'] = Variable<String>(destinationCodesJson);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    map['home_currency'] = Variable<String>(homeCurrency);
    map['local_currencies_json'] = Variable<String>(localCurrenciesJson);
    if (!nullToAbsent || totalBudget != null) {
      map['total_budget'] = Variable<String>(totalBudget);
    }
    map['participant_count'] = Variable<int>(participantCount);
    if (!nullToAbsent || defaultPaymentMethodId != null) {
      map['default_payment_method_id'] = Variable<String>(
        defaultPaymentMethodId,
      );
    }
    if (!nullToAbsent || offlinePackUpdatedAt != null) {
      map['offline_pack_updated_at'] = Variable<DateTime>(offlinePackUpdatedAt);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      syncVersion: Value(syncVersion),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      destinationCodesJson: Value(destinationCodesJson),
      startDate: Value(startDate),
      endDate: Value(endDate),
      homeCurrency: Value(homeCurrency),
      localCurrenciesJson: Value(localCurrenciesJson),
      totalBudget: totalBudget == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBudget),
      participantCount: Value(participantCount),
      defaultPaymentMethodId: defaultPaymentMethodId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultPaymentMethodId),
      offlinePackUpdatedAt: offlinePackUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(offlinePackUpdatedAt),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<String>(json['id']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      destinationCodesJson: serializer.fromJson<String>(
        json['destinationCodesJson'],
      ),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      homeCurrency: serializer.fromJson<String>(json['homeCurrency']),
      localCurrenciesJson: serializer.fromJson<String>(
        json['localCurrenciesJson'],
      ),
      totalBudget: serializer.fromJson<String?>(json['totalBudget']),
      participantCount: serializer.fromJson<int>(json['participantCount']),
      defaultPaymentMethodId: serializer.fromJson<String?>(
        json['defaultPaymentMethodId'],
      ),
      offlinePackUpdatedAt: serializer.fromJson<DateTime?>(
        json['offlinePackUpdatedAt'],
      ),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'destinationCodesJson': serializer.toJson<String>(destinationCodesJson),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'homeCurrency': serializer.toJson<String>(homeCurrency),
      'localCurrenciesJson': serializer.toJson<String>(localCurrenciesJson),
      'totalBudget': serializer.toJson<String?>(totalBudget),
      'participantCount': serializer.toJson<int>(participantCount),
      'defaultPaymentMethodId': serializer.toJson<String?>(
        defaultPaymentMethodId,
      ),
      'offlinePackUpdatedAt': serializer.toJson<DateTime?>(
        offlinePackUpdatedAt,
      ),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Trip copyWith({
    String? id,
    int? syncVersion,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? destinationCodesJson,
    DateTime? startDate,
    DateTime? endDate,
    String? homeCurrency,
    String? localCurrenciesJson,
    Value<String?> totalBudget = const Value.absent(),
    int? participantCount,
    Value<String?> defaultPaymentMethodId = const Value.absent(),
    Value<DateTime?> offlinePackUpdatedAt = const Value.absent(),
    String? status,
    DateTime? createdAt,
  }) => Trip(
    id: id ?? this.id,
    syncVersion: syncVersion ?? this.syncVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    destinationCodesJson: destinationCodesJson ?? this.destinationCodesJson,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    homeCurrency: homeCurrency ?? this.homeCurrency,
    localCurrenciesJson: localCurrenciesJson ?? this.localCurrenciesJson,
    totalBudget: totalBudget.present ? totalBudget.value : this.totalBudget,
    participantCount: participantCount ?? this.participantCount,
    defaultPaymentMethodId: defaultPaymentMethodId.present
        ? defaultPaymentMethodId.value
        : this.defaultPaymentMethodId,
    offlinePackUpdatedAt: offlinePackUpdatedAt.present
        ? offlinePackUpdatedAt.value
        : this.offlinePackUpdatedAt,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      id: data.id.present ? data.id.value : this.id,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      destinationCodesJson: data.destinationCodesJson.present
          ? data.destinationCodesJson.value
          : this.destinationCodesJson,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      homeCurrency: data.homeCurrency.present
          ? data.homeCurrency.value
          : this.homeCurrency,
      localCurrenciesJson: data.localCurrenciesJson.present
          ? data.localCurrenciesJson.value
          : this.localCurrenciesJson,
      totalBudget: data.totalBudget.present
          ? data.totalBudget.value
          : this.totalBudget,
      participantCount: data.participantCount.present
          ? data.participantCount.value
          : this.participantCount,
      defaultPaymentMethodId: data.defaultPaymentMethodId.present
          ? data.defaultPaymentMethodId.value
          : this.defaultPaymentMethodId,
      offlinePackUpdatedAt: data.offlinePackUpdatedAt.present
          ? data.offlinePackUpdatedAt.value
          : this.offlinePackUpdatedAt,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('destinationCodesJson: $destinationCodesJson, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('localCurrenciesJson: $localCurrenciesJson, ')
          ..write('totalBudget: $totalBudget, ')
          ..write('participantCount: $participantCount, ')
          ..write('defaultPaymentMethodId: $defaultPaymentMethodId, ')
          ..write('offlinePackUpdatedAt: $offlinePackUpdatedAt, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    name,
    destinationCodesJson,
    startDate,
    endDate,
    homeCurrency,
    localCurrenciesJson,
    totalBudget,
    participantCount,
    defaultPaymentMethodId,
    offlinePackUpdatedAt,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.id == this.id &&
          other.syncVersion == this.syncVersion &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.destinationCodesJson == this.destinationCodesJson &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.homeCurrency == this.homeCurrency &&
          other.localCurrenciesJson == this.localCurrenciesJson &&
          other.totalBudget == this.totalBudget &&
          other.participantCount == this.participantCount &&
          other.defaultPaymentMethodId == this.defaultPaymentMethodId &&
          other.offlinePackUpdatedAt == this.offlinePackUpdatedAt &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<String> id;
  final Value<int> syncVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> destinationCodesJson;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String> homeCurrency;
  final Value<String> localCurrenciesJson;
  final Value<String?> totalBudget;
  final Value<int> participantCount;
  final Value<String?> defaultPaymentMethodId;
  final Value<DateTime?> offlinePackUpdatedAt;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.destinationCodesJson = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.homeCurrency = const Value.absent(),
    this.localCurrenciesJson = const Value.absent(),
    this.totalBudget = const Value.absent(),
    this.participantCount = const Value.absent(),
    this.defaultPaymentMethodId = const Value.absent(),
    this.offlinePackUpdatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    required String id,
    this.syncVersion = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required String destinationCodesJson,
    required DateTime startDate,
    required DateTime endDate,
    required String homeCurrency,
    required String localCurrenciesJson,
    this.totalBudget = const Value.absent(),
    this.participantCount = const Value.absent(),
    this.defaultPaymentMethodId = const Value.absent(),
    this.offlinePackUpdatedAt = const Value.absent(),
    required String status,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       name = Value(name),
       destinationCodesJson = Value(destinationCodesJson),
       startDate = Value(startDate),
       endDate = Value(endDate),
       homeCurrency = Value(homeCurrency),
       localCurrenciesJson = Value(localCurrenciesJson),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Trip> custom({
    Expression<String>? id,
    Expression<int>? syncVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? destinationCodesJson,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? homeCurrency,
    Expression<String>? localCurrenciesJson,
    Expression<String>? totalBudget,
    Expression<int>? participantCount,
    Expression<String>? defaultPaymentMethodId,
    Expression<DateTime>? offlinePackUpdatedAt,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (destinationCodesJson != null)
        'destination_codes_json': destinationCodesJson,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (homeCurrency != null) 'home_currency': homeCurrency,
      if (localCurrenciesJson != null)
        'local_currencies_json': localCurrenciesJson,
      if (totalBudget != null) 'total_budget': totalBudget,
      if (participantCount != null) 'participant_count': participantCount,
      if (defaultPaymentMethodId != null)
        'default_payment_method_id': defaultPaymentMethodId,
      if (offlinePackUpdatedAt != null)
        'offline_pack_updated_at': offlinePackUpdatedAt,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<String>? id,
    Value<int>? syncVersion,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? destinationCodesJson,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<String>? homeCurrency,
    Value<String>? localCurrenciesJson,
    Value<String?>? totalBudget,
    Value<int>? participantCount,
    Value<String?>? defaultPaymentMethodId,
    Value<DateTime?>? offlinePackUpdatedAt,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      syncVersion: syncVersion ?? this.syncVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      destinationCodesJson: destinationCodesJson ?? this.destinationCodesJson,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      localCurrenciesJson: localCurrenciesJson ?? this.localCurrenciesJson,
      totalBudget: totalBudget ?? this.totalBudget,
      participantCount: participantCount ?? this.participantCount,
      defaultPaymentMethodId:
          defaultPaymentMethodId ?? this.defaultPaymentMethodId,
      offlinePackUpdatedAt: offlinePackUpdatedAt ?? this.offlinePackUpdatedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (destinationCodesJson.present) {
      map['destination_codes_json'] = Variable<String>(
        destinationCodesJson.value,
      );
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (homeCurrency.present) {
      map['home_currency'] = Variable<String>(homeCurrency.value);
    }
    if (localCurrenciesJson.present) {
      map['local_currencies_json'] = Variable<String>(
        localCurrenciesJson.value,
      );
    }
    if (totalBudget.present) {
      map['total_budget'] = Variable<String>(totalBudget.value);
    }
    if (participantCount.present) {
      map['participant_count'] = Variable<int>(participantCount.value);
    }
    if (defaultPaymentMethodId.present) {
      map['default_payment_method_id'] = Variable<String>(
        defaultPaymentMethodId.value,
      );
    }
    if (offlinePackUpdatedAt.present) {
      map['offline_pack_updated_at'] = Variable<DateTime>(
        offlinePackUpdatedAt.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('destinationCodesJson: $destinationCodesJson, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('localCurrenciesJson: $localCurrenciesJson, ')
          ..write('totalBudget: $totalBudget, ')
          ..write('participantCount: $participantCount, ')
          ..write('defaultPaymentMethodId: $defaultPaymentMethodId, ')
          ..write('offlinePackUpdatedAt: $offlinePackUpdatedAt, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionAmountMeta = const VerificationMeta(
    'transactionAmount',
  );
  @override
  late final GeneratedColumn<String> transactionAmount =
      GeneratedColumn<String>(
        'transaction_amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _transactionCurrencyMeta =
      const VerificationMeta('transactionCurrency');
  @override
  late final GeneratedColumn<String> transactionCurrency =
      GeneratedColumn<String>(
        'transaction_currency',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES currencies (code) ON DELETE RESTRICT',
        ),
      );
  static const VerificationMeta _referenceAmountMeta = const VerificationMeta(
    'referenceAmount',
  );
  @override
  late final GeneratedColumn<String> referenceAmount = GeneratedColumn<String>(
    'reference_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeCurrencyMeta = const VerificationMeta(
    'homeCurrency',
  );
  @override
  late final GeneratedColumn<String> homeCurrency = GeneratedColumn<String>(
    'home_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _estimatedFinalAmountMeta =
      const VerificationMeta('estimatedFinalAmount');
  @override
  late final GeneratedColumn<String> estimatedFinalAmount =
      GeneratedColumn<String>(
        'estimated_final_amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _actualFinalAmountMeta = const VerificationMeta(
    'actualFinalAmount',
  );
  @override
  late final GeneratedColumn<String> actualFinalAmount =
      GeneratedColumn<String>(
        'actual_final_amount',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _paymentMethodIdMeta = const VerificationMeta(
    'paymentMethodId',
  );
  @override
  late final GeneratedColumn<String> paymentMethodId = GeneratedColumn<String>(
    'payment_method_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES payment_methods (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _paymentRuleSnapshotJsonMeta =
      const VerificationMeta('paymentRuleSnapshotJson');
  @override
  late final GeneratedColumn<String> paymentRuleSnapshotJson =
      GeneratedColumn<String>(
        'payment_rule_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _rateSnapshotIdMeta = const VerificationMeta(
    'rateSnapshotId',
  );
  @override
  late final GeneratedColumn<String> rateSnapshotId = GeneratedColumn<String>(
    'rate_snapshot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rate_snapshots (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _rateSnapshotJsonMeta = const VerificationMeta(
    'rateSnapshotJson',
  );
  @override
  late final GeneratedColumn<String> rateSnapshotJson = GeneratedColumn<String>(
    'rate_snapshot_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<String> taxAmount = GeneratedColumn<String>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipAmountMeta = const VerificationMeta(
    'tipAmount',
  );
  @override
  late final GeneratedColumn<String> tipAmount = GeneratedColumn<String>(
    'tip_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountAmountMeta = const VerificationMeta(
    'discountAmount',
  );
  @override
  late final GeneratedColumn<String> discountAmount = GeneratedColumn<String>(
    'discount_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantCountMeta = const VerificationMeta(
    'participantCount',
  );
  @override
  late final GeneratedColumn<int> participantCount = GeneratedColumn<int>(
    'participant_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptLocalPathMeta = const VerificationMeta(
    'receiptLocalPath',
  );
  @override
  late final GeneratedColumn<String> receiptLocalPath = GeneratedColumn<String>(
    'receipt_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _budgetIncludedMeta = const VerificationMeta(
    'budgetIncluded',
  );
  @override
  late final GeneratedColumn<bool> budgetIncluded = GeneratedColumn<bool>(
    'budget_included',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("budget_included" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryTypeMeta = const VerificationMeta(
    'entryType',
  );
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
    'entry_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('purchase'),
  );
  static const VerificationMeta _relatedExpenseIdMeta = const VerificationMeta(
    'relatedExpenseId',
  );
  @override
  late final GeneratedColumn<String> relatedExpenseId = GeneratedColumn<String>(
    'related_expense_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    tripId,
    title,
    category,
    transactionAmount,
    transactionCurrency,
    referenceAmount,
    homeCurrency,
    estimatedFinalAmount,
    actualFinalAmount,
    paymentMethodId,
    paymentRuleSnapshotJson,
    rateSnapshotId,
    rateSnapshotJson,
    taxAmount,
    tipAmount,
    discountAmount,
    participantCount,
    occurredAt,
    receiptLocalPath,
    notes,
    budgetIncluded,
    status,
    entryType,
    relatedExpenseId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('transaction_amount')) {
      context.handle(
        _transactionAmountMeta,
        transactionAmount.isAcceptableOrUnknown(
          data['transaction_amount']!,
          _transactionAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionAmountMeta);
    }
    if (data.containsKey('transaction_currency')) {
      context.handle(
        _transactionCurrencyMeta,
        transactionCurrency.isAcceptableOrUnknown(
          data['transaction_currency']!,
          _transactionCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionCurrencyMeta);
    }
    if (data.containsKey('reference_amount')) {
      context.handle(
        _referenceAmountMeta,
        referenceAmount.isAcceptableOrUnknown(
          data['reference_amount']!,
          _referenceAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceAmountMeta);
    }
    if (data.containsKey('home_currency')) {
      context.handle(
        _homeCurrencyMeta,
        homeCurrency.isAcceptableOrUnknown(
          data['home_currency']!,
          _homeCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_homeCurrencyMeta);
    }
    if (data.containsKey('estimated_final_amount')) {
      context.handle(
        _estimatedFinalAmountMeta,
        estimatedFinalAmount.isAcceptableOrUnknown(
          data['estimated_final_amount']!,
          _estimatedFinalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_estimatedFinalAmountMeta);
    }
    if (data.containsKey('actual_final_amount')) {
      context.handle(
        _actualFinalAmountMeta,
        actualFinalAmount.isAcceptableOrUnknown(
          data['actual_final_amount']!,
          _actualFinalAmountMeta,
        ),
      );
    }
    if (data.containsKey('payment_method_id')) {
      context.handle(
        _paymentMethodIdMeta,
        paymentMethodId.isAcceptableOrUnknown(
          data['payment_method_id']!,
          _paymentMethodIdMeta,
        ),
      );
    }
    if (data.containsKey('payment_rule_snapshot_json')) {
      context.handle(
        _paymentRuleSnapshotJsonMeta,
        paymentRuleSnapshotJson.isAcceptableOrUnknown(
          data['payment_rule_snapshot_json']!,
          _paymentRuleSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentRuleSnapshotJsonMeta);
    }
    if (data.containsKey('rate_snapshot_id')) {
      context.handle(
        _rateSnapshotIdMeta,
        rateSnapshotId.isAcceptableOrUnknown(
          data['rate_snapshot_id']!,
          _rateSnapshotIdMeta,
        ),
      );
    }
    if (data.containsKey('rate_snapshot_json')) {
      context.handle(
        _rateSnapshotJsonMeta,
        rateSnapshotJson.isAcceptableOrUnknown(
          data['rate_snapshot_json']!,
          _rateSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rateSnapshotJsonMeta);
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_taxAmountMeta);
    }
    if (data.containsKey('tip_amount')) {
      context.handle(
        _tipAmountMeta,
        tipAmount.isAcceptableOrUnknown(data['tip_amount']!, _tipAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_tipAmountMeta);
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
        _discountAmountMeta,
        discountAmount.isAcceptableOrUnknown(
          data['discount_amount']!,
          _discountAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountAmountMeta);
    }
    if (data.containsKey('participant_count')) {
      context.handle(
        _participantCountMeta,
        participantCount.isAcceptableOrUnknown(
          data['participant_count']!,
          _participantCountMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('receipt_local_path')) {
      context.handle(
        _receiptLocalPathMeta,
        receiptLocalPath.isAcceptableOrUnknown(
          data['receipt_local_path']!,
          _receiptLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('budget_included')) {
      context.handle(
        _budgetIncludedMeta,
        budgetIncluded.isAcceptableOrUnknown(
          data['budget_included']!,
          _budgetIncludedMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('entry_type')) {
      context.handle(
        _entryTypeMeta,
        entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta),
      );
    }
    if (data.containsKey('related_expense_id')) {
      context.handle(
        _relatedExpenseIdMeta,
        relatedExpenseId.isAcceptableOrUnknown(
          data['related_expense_id']!,
          _relatedExpenseIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      transactionAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_amount'],
      )!,
      transactionCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_currency'],
      )!,
      referenceAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_amount'],
      )!,
      homeCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_currency'],
      )!,
      estimatedFinalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimated_final_amount'],
      )!,
      actualFinalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_final_amount'],
      ),
      paymentMethodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_id'],
      ),
      paymentRuleSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_rule_snapshot_json'],
      )!,
      rateSnapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_snapshot_id'],
      ),
      rateSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_snapshot_json'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_amount'],
      )!,
      tipAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tip_amount'],
      )!,
      discountAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_amount'],
      )!,
      participantCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}participant_count'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      receiptLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_local_path'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      budgetIncluded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}budget_included'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      entryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_type'],
      )!,
      relatedExpenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_expense_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final int syncVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? tripId;
  final String title;
  final String category;
  final String transactionAmount;
  final String transactionCurrency;
  final String referenceAmount;
  final String homeCurrency;
  final String estimatedFinalAmount;
  final String? actualFinalAmount;
  final String? paymentMethodId;
  final String paymentRuleSnapshotJson;
  final String? rateSnapshotId;
  final String rateSnapshotJson;
  final String taxAmount;
  final String tipAmount;
  final String discountAmount;
  final int participantCount;
  final DateTime occurredAt;
  final String? receiptLocalPath;
  final String? notes;
  final bool budgetIncluded;
  final String status;
  final String entryType;
  final String? relatedExpenseId;
  final DateTime createdAt;
  const Expense({
    required this.id,
    required this.syncVersion,
    required this.updatedAt,
    this.deletedAt,
    this.tripId,
    required this.title,
    required this.category,
    required this.transactionAmount,
    required this.transactionCurrency,
    required this.referenceAmount,
    required this.homeCurrency,
    required this.estimatedFinalAmount,
    this.actualFinalAmount,
    this.paymentMethodId,
    required this.paymentRuleSnapshotJson,
    this.rateSnapshotId,
    required this.rateSnapshotJson,
    required this.taxAmount,
    required this.tipAmount,
    required this.discountAmount,
    required this.participantCount,
    required this.occurredAt,
    this.receiptLocalPath,
    this.notes,
    required this.budgetIncluded,
    required this.status,
    required this.entryType,
    this.relatedExpenseId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_version'] = Variable<int>(syncVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['transaction_amount'] = Variable<String>(transactionAmount);
    map['transaction_currency'] = Variable<String>(transactionCurrency);
    map['reference_amount'] = Variable<String>(referenceAmount);
    map['home_currency'] = Variable<String>(homeCurrency);
    map['estimated_final_amount'] = Variable<String>(estimatedFinalAmount);
    if (!nullToAbsent || actualFinalAmount != null) {
      map['actual_final_amount'] = Variable<String>(actualFinalAmount);
    }
    if (!nullToAbsent || paymentMethodId != null) {
      map['payment_method_id'] = Variable<String>(paymentMethodId);
    }
    map['payment_rule_snapshot_json'] = Variable<String>(
      paymentRuleSnapshotJson,
    );
    if (!nullToAbsent || rateSnapshotId != null) {
      map['rate_snapshot_id'] = Variable<String>(rateSnapshotId);
    }
    map['rate_snapshot_json'] = Variable<String>(rateSnapshotJson);
    map['tax_amount'] = Variable<String>(taxAmount);
    map['tip_amount'] = Variable<String>(tipAmount);
    map['discount_amount'] = Variable<String>(discountAmount);
    map['participant_count'] = Variable<int>(participantCount);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || receiptLocalPath != null) {
      map['receipt_local_path'] = Variable<String>(receiptLocalPath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['budget_included'] = Variable<bool>(budgetIncluded);
    map['status'] = Variable<String>(status);
    map['entry_type'] = Variable<String>(entryType);
    if (!nullToAbsent || relatedExpenseId != null) {
      map['related_expense_id'] = Variable<String>(relatedExpenseId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      syncVersion: Value(syncVersion),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      title: Value(title),
      category: Value(category),
      transactionAmount: Value(transactionAmount),
      transactionCurrency: Value(transactionCurrency),
      referenceAmount: Value(referenceAmount),
      homeCurrency: Value(homeCurrency),
      estimatedFinalAmount: Value(estimatedFinalAmount),
      actualFinalAmount: actualFinalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(actualFinalAmount),
      paymentMethodId: paymentMethodId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodId),
      paymentRuleSnapshotJson: Value(paymentRuleSnapshotJson),
      rateSnapshotId: rateSnapshotId == null && nullToAbsent
          ? const Value.absent()
          : Value(rateSnapshotId),
      rateSnapshotJson: Value(rateSnapshotJson),
      taxAmount: Value(taxAmount),
      tipAmount: Value(tipAmount),
      discountAmount: Value(discountAmount),
      participantCount: Value(participantCount),
      occurredAt: Value(occurredAt),
      receiptLocalPath: receiptLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptLocalPath),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      budgetIncluded: Value(budgetIncluded),
      status: Value(status),
      entryType: Value(entryType),
      relatedExpenseId: relatedExpenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedExpenseId),
      createdAt: Value(createdAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      transactionAmount: serializer.fromJson<String>(json['transactionAmount']),
      transactionCurrency: serializer.fromJson<String>(
        json['transactionCurrency'],
      ),
      referenceAmount: serializer.fromJson<String>(json['referenceAmount']),
      homeCurrency: serializer.fromJson<String>(json['homeCurrency']),
      estimatedFinalAmount: serializer.fromJson<String>(
        json['estimatedFinalAmount'],
      ),
      actualFinalAmount: serializer.fromJson<String?>(
        json['actualFinalAmount'],
      ),
      paymentMethodId: serializer.fromJson<String?>(json['paymentMethodId']),
      paymentRuleSnapshotJson: serializer.fromJson<String>(
        json['paymentRuleSnapshotJson'],
      ),
      rateSnapshotId: serializer.fromJson<String?>(json['rateSnapshotId']),
      rateSnapshotJson: serializer.fromJson<String>(json['rateSnapshotJson']),
      taxAmount: serializer.fromJson<String>(json['taxAmount']),
      tipAmount: serializer.fromJson<String>(json['tipAmount']),
      discountAmount: serializer.fromJson<String>(json['discountAmount']),
      participantCount: serializer.fromJson<int>(json['participantCount']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      receiptLocalPath: serializer.fromJson<String?>(json['receiptLocalPath']),
      notes: serializer.fromJson<String?>(json['notes']),
      budgetIncluded: serializer.fromJson<bool>(json['budgetIncluded']),
      status: serializer.fromJson<String>(json['status']),
      entryType: serializer.fromJson<String>(json['entryType']),
      relatedExpenseId: serializer.fromJson<String?>(json['relatedExpenseId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'tripId': serializer.toJson<String?>(tripId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'transactionAmount': serializer.toJson<String>(transactionAmount),
      'transactionCurrency': serializer.toJson<String>(transactionCurrency),
      'referenceAmount': serializer.toJson<String>(referenceAmount),
      'homeCurrency': serializer.toJson<String>(homeCurrency),
      'estimatedFinalAmount': serializer.toJson<String>(estimatedFinalAmount),
      'actualFinalAmount': serializer.toJson<String?>(actualFinalAmount),
      'paymentMethodId': serializer.toJson<String?>(paymentMethodId),
      'paymentRuleSnapshotJson': serializer.toJson<String>(
        paymentRuleSnapshotJson,
      ),
      'rateSnapshotId': serializer.toJson<String?>(rateSnapshotId),
      'rateSnapshotJson': serializer.toJson<String>(rateSnapshotJson),
      'taxAmount': serializer.toJson<String>(taxAmount),
      'tipAmount': serializer.toJson<String>(tipAmount),
      'discountAmount': serializer.toJson<String>(discountAmount),
      'participantCount': serializer.toJson<int>(participantCount),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'receiptLocalPath': serializer.toJson<String?>(receiptLocalPath),
      'notes': serializer.toJson<String?>(notes),
      'budgetIncluded': serializer.toJson<bool>(budgetIncluded),
      'status': serializer.toJson<String>(status),
      'entryType': serializer.toJson<String>(entryType),
      'relatedExpenseId': serializer.toJson<String?>(relatedExpenseId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Expense copyWith({
    String? id,
    int? syncVersion,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> tripId = const Value.absent(),
    String? title,
    String? category,
    String? transactionAmount,
    String? transactionCurrency,
    String? referenceAmount,
    String? homeCurrency,
    String? estimatedFinalAmount,
    Value<String?> actualFinalAmount = const Value.absent(),
    Value<String?> paymentMethodId = const Value.absent(),
    String? paymentRuleSnapshotJson,
    Value<String?> rateSnapshotId = const Value.absent(),
    String? rateSnapshotJson,
    String? taxAmount,
    String? tipAmount,
    String? discountAmount,
    int? participantCount,
    DateTime? occurredAt,
    Value<String?> receiptLocalPath = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? budgetIncluded,
    String? status,
    String? entryType,
    Value<String?> relatedExpenseId = const Value.absent(),
    DateTime? createdAt,
  }) => Expense(
    id: id ?? this.id,
    syncVersion: syncVersion ?? this.syncVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    tripId: tripId.present ? tripId.value : this.tripId,
    title: title ?? this.title,
    category: category ?? this.category,
    transactionAmount: transactionAmount ?? this.transactionAmount,
    transactionCurrency: transactionCurrency ?? this.transactionCurrency,
    referenceAmount: referenceAmount ?? this.referenceAmount,
    homeCurrency: homeCurrency ?? this.homeCurrency,
    estimatedFinalAmount: estimatedFinalAmount ?? this.estimatedFinalAmount,
    actualFinalAmount: actualFinalAmount.present
        ? actualFinalAmount.value
        : this.actualFinalAmount,
    paymentMethodId: paymentMethodId.present
        ? paymentMethodId.value
        : this.paymentMethodId,
    paymentRuleSnapshotJson:
        paymentRuleSnapshotJson ?? this.paymentRuleSnapshotJson,
    rateSnapshotId: rateSnapshotId.present
        ? rateSnapshotId.value
        : this.rateSnapshotId,
    rateSnapshotJson: rateSnapshotJson ?? this.rateSnapshotJson,
    taxAmount: taxAmount ?? this.taxAmount,
    tipAmount: tipAmount ?? this.tipAmount,
    discountAmount: discountAmount ?? this.discountAmount,
    participantCount: participantCount ?? this.participantCount,
    occurredAt: occurredAt ?? this.occurredAt,
    receiptLocalPath: receiptLocalPath.present
        ? receiptLocalPath.value
        : this.receiptLocalPath,
    notes: notes.present ? notes.value : this.notes,
    budgetIncluded: budgetIncluded ?? this.budgetIncluded,
    status: status ?? this.status,
    entryType: entryType ?? this.entryType,
    relatedExpenseId: relatedExpenseId.present
        ? relatedExpenseId.value
        : this.relatedExpenseId,
    createdAt: createdAt ?? this.createdAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      transactionAmount: data.transactionAmount.present
          ? data.transactionAmount.value
          : this.transactionAmount,
      transactionCurrency: data.transactionCurrency.present
          ? data.transactionCurrency.value
          : this.transactionCurrency,
      referenceAmount: data.referenceAmount.present
          ? data.referenceAmount.value
          : this.referenceAmount,
      homeCurrency: data.homeCurrency.present
          ? data.homeCurrency.value
          : this.homeCurrency,
      estimatedFinalAmount: data.estimatedFinalAmount.present
          ? data.estimatedFinalAmount.value
          : this.estimatedFinalAmount,
      actualFinalAmount: data.actualFinalAmount.present
          ? data.actualFinalAmount.value
          : this.actualFinalAmount,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      paymentRuleSnapshotJson: data.paymentRuleSnapshotJson.present
          ? data.paymentRuleSnapshotJson.value
          : this.paymentRuleSnapshotJson,
      rateSnapshotId: data.rateSnapshotId.present
          ? data.rateSnapshotId.value
          : this.rateSnapshotId,
      rateSnapshotJson: data.rateSnapshotJson.present
          ? data.rateSnapshotJson.value
          : this.rateSnapshotJson,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      tipAmount: data.tipAmount.present ? data.tipAmount.value : this.tipAmount,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      participantCount: data.participantCount.present
          ? data.participantCount.value
          : this.participantCount,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      receiptLocalPath: data.receiptLocalPath.present
          ? data.receiptLocalPath.value
          : this.receiptLocalPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      budgetIncluded: data.budgetIncluded.present
          ? data.budgetIncluded.value
          : this.budgetIncluded,
      status: data.status.present ? data.status.value : this.status,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      relatedExpenseId: data.relatedExpenseId.present
          ? data.relatedExpenseId.value
          : this.relatedExpenseId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('tripId: $tripId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('transactionAmount: $transactionAmount, ')
          ..write('transactionCurrency: $transactionCurrency, ')
          ..write('referenceAmount: $referenceAmount, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('estimatedFinalAmount: $estimatedFinalAmount, ')
          ..write('actualFinalAmount: $actualFinalAmount, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('paymentRuleSnapshotJson: $paymentRuleSnapshotJson, ')
          ..write('rateSnapshotId: $rateSnapshotId, ')
          ..write('rateSnapshotJson: $rateSnapshotJson, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('tipAmount: $tipAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('participantCount: $participantCount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('receiptLocalPath: $receiptLocalPath, ')
          ..write('notes: $notes, ')
          ..write('budgetIncluded: $budgetIncluded, ')
          ..write('status: $status, ')
          ..write('entryType: $entryType, ')
          ..write('relatedExpenseId: $relatedExpenseId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    tripId,
    title,
    category,
    transactionAmount,
    transactionCurrency,
    referenceAmount,
    homeCurrency,
    estimatedFinalAmount,
    actualFinalAmount,
    paymentMethodId,
    paymentRuleSnapshotJson,
    rateSnapshotId,
    rateSnapshotJson,
    taxAmount,
    tipAmount,
    discountAmount,
    participantCount,
    occurredAt,
    receiptLocalPath,
    notes,
    budgetIncluded,
    status,
    entryType,
    relatedExpenseId,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.syncVersion == this.syncVersion &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.tripId == this.tripId &&
          other.title == this.title &&
          other.category == this.category &&
          other.transactionAmount == this.transactionAmount &&
          other.transactionCurrency == this.transactionCurrency &&
          other.referenceAmount == this.referenceAmount &&
          other.homeCurrency == this.homeCurrency &&
          other.estimatedFinalAmount == this.estimatedFinalAmount &&
          other.actualFinalAmount == this.actualFinalAmount &&
          other.paymentMethodId == this.paymentMethodId &&
          other.paymentRuleSnapshotJson == this.paymentRuleSnapshotJson &&
          other.rateSnapshotId == this.rateSnapshotId &&
          other.rateSnapshotJson == this.rateSnapshotJson &&
          other.taxAmount == this.taxAmount &&
          other.tipAmount == this.tipAmount &&
          other.discountAmount == this.discountAmount &&
          other.participantCount == this.participantCount &&
          other.occurredAt == this.occurredAt &&
          other.receiptLocalPath == this.receiptLocalPath &&
          other.notes == this.notes &&
          other.budgetIncluded == this.budgetIncluded &&
          other.status == this.status &&
          other.entryType == this.entryType &&
          other.relatedExpenseId == this.relatedExpenseId &&
          other.createdAt == this.createdAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<int> syncVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> tripId;
  final Value<String> title;
  final Value<String> category;
  final Value<String> transactionAmount;
  final Value<String> transactionCurrency;
  final Value<String> referenceAmount;
  final Value<String> homeCurrency;
  final Value<String> estimatedFinalAmount;
  final Value<String?> actualFinalAmount;
  final Value<String?> paymentMethodId;
  final Value<String> paymentRuleSnapshotJson;
  final Value<String?> rateSnapshotId;
  final Value<String> rateSnapshotJson;
  final Value<String> taxAmount;
  final Value<String> tipAmount;
  final Value<String> discountAmount;
  final Value<int> participantCount;
  final Value<DateTime> occurredAt;
  final Value<String?> receiptLocalPath;
  final Value<String?> notes;
  final Value<bool> budgetIncluded;
  final Value<String> status;
  final Value<String> entryType;
  final Value<String?> relatedExpenseId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.tripId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.transactionAmount = const Value.absent(),
    this.transactionCurrency = const Value.absent(),
    this.referenceAmount = const Value.absent(),
    this.homeCurrency = const Value.absent(),
    this.estimatedFinalAmount = const Value.absent(),
    this.actualFinalAmount = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.paymentRuleSnapshotJson = const Value.absent(),
    this.rateSnapshotId = const Value.absent(),
    this.rateSnapshotJson = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.tipAmount = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.participantCount = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.receiptLocalPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.budgetIncluded = const Value.absent(),
    this.status = const Value.absent(),
    this.entryType = const Value.absent(),
    this.relatedExpenseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    this.syncVersion = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.tripId = const Value.absent(),
    required String title,
    required String category,
    required String transactionAmount,
    required String transactionCurrency,
    required String referenceAmount,
    required String homeCurrency,
    required String estimatedFinalAmount,
    this.actualFinalAmount = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    required String paymentRuleSnapshotJson,
    this.rateSnapshotId = const Value.absent(),
    required String rateSnapshotJson,
    required String taxAmount,
    required String tipAmount,
    required String discountAmount,
    this.participantCount = const Value.absent(),
    required DateTime occurredAt,
    this.receiptLocalPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.budgetIncluded = const Value.absent(),
    required String status,
    this.entryType = const Value.absent(),
    this.relatedExpenseId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       title = Value(title),
       category = Value(category),
       transactionAmount = Value(transactionAmount),
       transactionCurrency = Value(transactionCurrency),
       referenceAmount = Value(referenceAmount),
       homeCurrency = Value(homeCurrency),
       estimatedFinalAmount = Value(estimatedFinalAmount),
       paymentRuleSnapshotJson = Value(paymentRuleSnapshotJson),
       rateSnapshotJson = Value(rateSnapshotJson),
       taxAmount = Value(taxAmount),
       tipAmount = Value(tipAmount),
       discountAmount = Value(discountAmount),
       occurredAt = Value(occurredAt),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<int>? syncVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? tripId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? transactionAmount,
    Expression<String>? transactionCurrency,
    Expression<String>? referenceAmount,
    Expression<String>? homeCurrency,
    Expression<String>? estimatedFinalAmount,
    Expression<String>? actualFinalAmount,
    Expression<String>? paymentMethodId,
    Expression<String>? paymentRuleSnapshotJson,
    Expression<String>? rateSnapshotId,
    Expression<String>? rateSnapshotJson,
    Expression<String>? taxAmount,
    Expression<String>? tipAmount,
    Expression<String>? discountAmount,
    Expression<int>? participantCount,
    Expression<DateTime>? occurredAt,
    Expression<String>? receiptLocalPath,
    Expression<String>? notes,
    Expression<bool>? budgetIncluded,
    Expression<String>? status,
    Expression<String>? entryType,
    Expression<String>? relatedExpenseId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (tripId != null) 'trip_id': tripId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (transactionAmount != null) 'transaction_amount': transactionAmount,
      if (transactionCurrency != null)
        'transaction_currency': transactionCurrency,
      if (referenceAmount != null) 'reference_amount': referenceAmount,
      if (homeCurrency != null) 'home_currency': homeCurrency,
      if (estimatedFinalAmount != null)
        'estimated_final_amount': estimatedFinalAmount,
      if (actualFinalAmount != null) 'actual_final_amount': actualFinalAmount,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (paymentRuleSnapshotJson != null)
        'payment_rule_snapshot_json': paymentRuleSnapshotJson,
      if (rateSnapshotId != null) 'rate_snapshot_id': rateSnapshotId,
      if (rateSnapshotJson != null) 'rate_snapshot_json': rateSnapshotJson,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (tipAmount != null) 'tip_amount': tipAmount,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (participantCount != null) 'participant_count': participantCount,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (receiptLocalPath != null) 'receipt_local_path': receiptLocalPath,
      if (notes != null) 'notes': notes,
      if (budgetIncluded != null) 'budget_included': budgetIncluded,
      if (status != null) 'status': status,
      if (entryType != null) 'entry_type': entryType,
      if (relatedExpenseId != null) 'related_expense_id': relatedExpenseId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<int>? syncVersion,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? tripId,
    Value<String>? title,
    Value<String>? category,
    Value<String>? transactionAmount,
    Value<String>? transactionCurrency,
    Value<String>? referenceAmount,
    Value<String>? homeCurrency,
    Value<String>? estimatedFinalAmount,
    Value<String?>? actualFinalAmount,
    Value<String?>? paymentMethodId,
    Value<String>? paymentRuleSnapshotJson,
    Value<String?>? rateSnapshotId,
    Value<String>? rateSnapshotJson,
    Value<String>? taxAmount,
    Value<String>? tipAmount,
    Value<String>? discountAmount,
    Value<int>? participantCount,
    Value<DateTime>? occurredAt,
    Value<String?>? receiptLocalPath,
    Value<String?>? notes,
    Value<bool>? budgetIncluded,
    Value<String>? status,
    Value<String>? entryType,
    Value<String?>? relatedExpenseId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      syncVersion: syncVersion ?? this.syncVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      category: category ?? this.category,
      transactionAmount: transactionAmount ?? this.transactionAmount,
      transactionCurrency: transactionCurrency ?? this.transactionCurrency,
      referenceAmount: referenceAmount ?? this.referenceAmount,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      estimatedFinalAmount: estimatedFinalAmount ?? this.estimatedFinalAmount,
      actualFinalAmount: actualFinalAmount ?? this.actualFinalAmount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentRuleSnapshotJson:
          paymentRuleSnapshotJson ?? this.paymentRuleSnapshotJson,
      rateSnapshotId: rateSnapshotId ?? this.rateSnapshotId,
      rateSnapshotJson: rateSnapshotJson ?? this.rateSnapshotJson,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      participantCount: participantCount ?? this.participantCount,
      occurredAt: occurredAt ?? this.occurredAt,
      receiptLocalPath: receiptLocalPath ?? this.receiptLocalPath,
      notes: notes ?? this.notes,
      budgetIncluded: budgetIncluded ?? this.budgetIncluded,
      status: status ?? this.status,
      entryType: entryType ?? this.entryType,
      relatedExpenseId: relatedExpenseId ?? this.relatedExpenseId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (transactionAmount.present) {
      map['transaction_amount'] = Variable<String>(transactionAmount.value);
    }
    if (transactionCurrency.present) {
      map['transaction_currency'] = Variable<String>(transactionCurrency.value);
    }
    if (referenceAmount.present) {
      map['reference_amount'] = Variable<String>(referenceAmount.value);
    }
    if (homeCurrency.present) {
      map['home_currency'] = Variable<String>(homeCurrency.value);
    }
    if (estimatedFinalAmount.present) {
      map['estimated_final_amount'] = Variable<String>(
        estimatedFinalAmount.value,
      );
    }
    if (actualFinalAmount.present) {
      map['actual_final_amount'] = Variable<String>(actualFinalAmount.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<String>(paymentMethodId.value);
    }
    if (paymentRuleSnapshotJson.present) {
      map['payment_rule_snapshot_json'] = Variable<String>(
        paymentRuleSnapshotJson.value,
      );
    }
    if (rateSnapshotId.present) {
      map['rate_snapshot_id'] = Variable<String>(rateSnapshotId.value);
    }
    if (rateSnapshotJson.present) {
      map['rate_snapshot_json'] = Variable<String>(rateSnapshotJson.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<String>(taxAmount.value);
    }
    if (tipAmount.present) {
      map['tip_amount'] = Variable<String>(tipAmount.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<String>(discountAmount.value);
    }
    if (participantCount.present) {
      map['participant_count'] = Variable<int>(participantCount.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (receiptLocalPath.present) {
      map['receipt_local_path'] = Variable<String>(receiptLocalPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (budgetIncluded.present) {
      map['budget_included'] = Variable<bool>(budgetIncluded.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (relatedExpenseId.present) {
      map['related_expense_id'] = Variable<String>(relatedExpenseId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('tripId: $tripId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('transactionAmount: $transactionAmount, ')
          ..write('transactionCurrency: $transactionCurrency, ')
          ..write('referenceAmount: $referenceAmount, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('estimatedFinalAmount: $estimatedFinalAmount, ')
          ..write('actualFinalAmount: $actualFinalAmount, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('paymentRuleSnapshotJson: $paymentRuleSnapshotJson, ')
          ..write('rateSnapshotId: $rateSnapshotId, ')
          ..write('rateSnapshotJson: $rateSnapshotJson, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('tipAmount: $tipAmount, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('participantCount: $participantCount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('receiptLocalPath: $receiptLocalPath, ')
          ..write('notes: $notes, ')
          ..write('budgetIncluded: $budgetIncluded, ')
          ..write('status: $status, ')
          ..write('entryType: $entryType, ')
          ..write('relatedExpenseId: $relatedExpenseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeeCalibrationsTable extends FeeCalibrations
    with TableInfo<$FeeCalibrationsTable, FeeCalibration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeeCalibrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodIdMeta = const VerificationMeta(
    'paymentMethodId',
  );
  @override
  late final GeneratedColumn<String> paymentMethodId = GeneratedColumn<String>(
    'payment_method_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES payment_methods (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _referenceAmountMeta = const VerificationMeta(
    'referenceAmount',
  );
  @override
  late final GeneratedColumn<String> referenceAmount = GeneratedColumn<String>(
    'reference_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualFinalAmountMeta = const VerificationMeta(
    'actualFinalAmount',
  );
  @override
  late final GeneratedColumn<String> actualFinalAmount =
      GeneratedColumn<String>(
        'actual_final_amount',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _effectiveMarkupPercentMeta =
      const VerificationMeta('effectiveMarkupPercent');
  @override
  late final GeneratedColumn<String> effectiveMarkupPercent =
      GeneratedColumn<String>(
        'effective_markup_percent',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _calculatedAtMeta = const VerificationMeta(
    'calculatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> calculatedAt = GeneratedColumn<DateTime>(
    'calculated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    paymentMethodId,
    expenseId,
    referenceAmount,
    actualFinalAmount,
    effectiveMarkupPercent,
    calculatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fee_calibrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeeCalibration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('payment_method_id')) {
      context.handle(
        _paymentMethodIdMeta,
        paymentMethodId.isAcceptableOrUnknown(
          data['payment_method_id']!,
          _paymentMethodIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodIdMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('reference_amount')) {
      context.handle(
        _referenceAmountMeta,
        referenceAmount.isAcceptableOrUnknown(
          data['reference_amount']!,
          _referenceAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_referenceAmountMeta);
    }
    if (data.containsKey('actual_final_amount')) {
      context.handle(
        _actualFinalAmountMeta,
        actualFinalAmount.isAcceptableOrUnknown(
          data['actual_final_amount']!,
          _actualFinalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualFinalAmountMeta);
    }
    if (data.containsKey('effective_markup_percent')) {
      context.handle(
        _effectiveMarkupPercentMeta,
        effectiveMarkupPercent.isAcceptableOrUnknown(
          data['effective_markup_percent']!,
          _effectiveMarkupPercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveMarkupPercentMeta);
    }
    if (data.containsKey('calculated_at')) {
      context.handle(
        _calculatedAtMeta,
        calculatedAt.isAcceptableOrUnknown(
          data['calculated_at']!,
          _calculatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeeCalibration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeeCalibration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      paymentMethodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method_id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      referenceAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_amount'],
      )!,
      actualFinalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_final_amount'],
      )!,
      effectiveMarkupPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_markup_percent'],
      )!,
      calculatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}calculated_at'],
      )!,
    );
  }

  @override
  $FeeCalibrationsTable createAlias(String alias) {
    return $FeeCalibrationsTable(attachedDatabase, alias);
  }
}

class FeeCalibration extends DataClass implements Insertable<FeeCalibration> {
  final String id;
  final int syncVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String paymentMethodId;
  final String expenseId;
  final String referenceAmount;
  final String actualFinalAmount;
  final String effectiveMarkupPercent;
  final DateTime calculatedAt;
  const FeeCalibration({
    required this.id,
    required this.syncVersion,
    required this.updatedAt,
    this.deletedAt,
    required this.paymentMethodId,
    required this.expenseId,
    required this.referenceAmount,
    required this.actualFinalAmount,
    required this.effectiveMarkupPercent,
    required this.calculatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_version'] = Variable<int>(syncVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['payment_method_id'] = Variable<String>(paymentMethodId);
    map['expense_id'] = Variable<String>(expenseId);
    map['reference_amount'] = Variable<String>(referenceAmount);
    map['actual_final_amount'] = Variable<String>(actualFinalAmount);
    map['effective_markup_percent'] = Variable<String>(effectiveMarkupPercent);
    map['calculated_at'] = Variable<DateTime>(calculatedAt);
    return map;
  }

  FeeCalibrationsCompanion toCompanion(bool nullToAbsent) {
    return FeeCalibrationsCompanion(
      id: Value(id),
      syncVersion: Value(syncVersion),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      paymentMethodId: Value(paymentMethodId),
      expenseId: Value(expenseId),
      referenceAmount: Value(referenceAmount),
      actualFinalAmount: Value(actualFinalAmount),
      effectiveMarkupPercent: Value(effectiveMarkupPercent),
      calculatedAt: Value(calculatedAt),
    );
  }

  factory FeeCalibration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeeCalibration(
      id: serializer.fromJson<String>(json['id']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      paymentMethodId: serializer.fromJson<String>(json['paymentMethodId']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      referenceAmount: serializer.fromJson<String>(json['referenceAmount']),
      actualFinalAmount: serializer.fromJson<String>(json['actualFinalAmount']),
      effectiveMarkupPercent: serializer.fromJson<String>(
        json['effectiveMarkupPercent'],
      ),
      calculatedAt: serializer.fromJson<DateTime>(json['calculatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'paymentMethodId': serializer.toJson<String>(paymentMethodId),
      'expenseId': serializer.toJson<String>(expenseId),
      'referenceAmount': serializer.toJson<String>(referenceAmount),
      'actualFinalAmount': serializer.toJson<String>(actualFinalAmount),
      'effectiveMarkupPercent': serializer.toJson<String>(
        effectiveMarkupPercent,
      ),
      'calculatedAt': serializer.toJson<DateTime>(calculatedAt),
    };
  }

  FeeCalibration copyWith({
    String? id,
    int? syncVersion,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? paymentMethodId,
    String? expenseId,
    String? referenceAmount,
    String? actualFinalAmount,
    String? effectiveMarkupPercent,
    DateTime? calculatedAt,
  }) => FeeCalibration(
    id: id ?? this.id,
    syncVersion: syncVersion ?? this.syncVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    expenseId: expenseId ?? this.expenseId,
    referenceAmount: referenceAmount ?? this.referenceAmount,
    actualFinalAmount: actualFinalAmount ?? this.actualFinalAmount,
    effectiveMarkupPercent:
        effectiveMarkupPercent ?? this.effectiveMarkupPercent,
    calculatedAt: calculatedAt ?? this.calculatedAt,
  );
  FeeCalibration copyWithCompanion(FeeCalibrationsCompanion data) {
    return FeeCalibration(
      id: data.id.present ? data.id.value : this.id,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      referenceAmount: data.referenceAmount.present
          ? data.referenceAmount.value
          : this.referenceAmount,
      actualFinalAmount: data.actualFinalAmount.present
          ? data.actualFinalAmount.value
          : this.actualFinalAmount,
      effectiveMarkupPercent: data.effectiveMarkupPercent.present
          ? data.effectiveMarkupPercent.value
          : this.effectiveMarkupPercent,
      calculatedAt: data.calculatedAt.present
          ? data.calculatedAt.value
          : this.calculatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeeCalibration(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('expenseId: $expenseId, ')
          ..write('referenceAmount: $referenceAmount, ')
          ..write('actualFinalAmount: $actualFinalAmount, ')
          ..write('effectiveMarkupPercent: $effectiveMarkupPercent, ')
          ..write('calculatedAt: $calculatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    paymentMethodId,
    expenseId,
    referenceAmount,
    actualFinalAmount,
    effectiveMarkupPercent,
    calculatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeeCalibration &&
          other.id == this.id &&
          other.syncVersion == this.syncVersion &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.paymentMethodId == this.paymentMethodId &&
          other.expenseId == this.expenseId &&
          other.referenceAmount == this.referenceAmount &&
          other.actualFinalAmount == this.actualFinalAmount &&
          other.effectiveMarkupPercent == this.effectiveMarkupPercent &&
          other.calculatedAt == this.calculatedAt);
}

class FeeCalibrationsCompanion extends UpdateCompanion<FeeCalibration> {
  final Value<String> id;
  final Value<int> syncVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> paymentMethodId;
  final Value<String> expenseId;
  final Value<String> referenceAmount;
  final Value<String> actualFinalAmount;
  final Value<String> effectiveMarkupPercent;
  final Value<DateTime> calculatedAt;
  final Value<int> rowid;
  const FeeCalibrationsCompanion({
    this.id = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.referenceAmount = const Value.absent(),
    this.actualFinalAmount = const Value.absent(),
    this.effectiveMarkupPercent = const Value.absent(),
    this.calculatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeeCalibrationsCompanion.insert({
    required String id,
    this.syncVersion = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String paymentMethodId,
    required String expenseId,
    required String referenceAmount,
    required String actualFinalAmount,
    required String effectiveMarkupPercent,
    required DateTime calculatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       paymentMethodId = Value(paymentMethodId),
       expenseId = Value(expenseId),
       referenceAmount = Value(referenceAmount),
       actualFinalAmount = Value(actualFinalAmount),
       effectiveMarkupPercent = Value(effectiveMarkupPercent),
       calculatedAt = Value(calculatedAt);
  static Insertable<FeeCalibration> custom({
    Expression<String>? id,
    Expression<int>? syncVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? paymentMethodId,
    Expression<String>? expenseId,
    Expression<String>? referenceAmount,
    Expression<String>? actualFinalAmount,
    Expression<String>? effectiveMarkupPercent,
    Expression<DateTime>? calculatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (expenseId != null) 'expense_id': expenseId,
      if (referenceAmount != null) 'reference_amount': referenceAmount,
      if (actualFinalAmount != null) 'actual_final_amount': actualFinalAmount,
      if (effectiveMarkupPercent != null)
        'effective_markup_percent': effectiveMarkupPercent,
      if (calculatedAt != null) 'calculated_at': calculatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeeCalibrationsCompanion copyWith({
    Value<String>? id,
    Value<int>? syncVersion,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? paymentMethodId,
    Value<String>? expenseId,
    Value<String>? referenceAmount,
    Value<String>? actualFinalAmount,
    Value<String>? effectiveMarkupPercent,
    Value<DateTime>? calculatedAt,
    Value<int>? rowid,
  }) {
    return FeeCalibrationsCompanion(
      id: id ?? this.id,
      syncVersion: syncVersion ?? this.syncVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      expenseId: expenseId ?? this.expenseId,
      referenceAmount: referenceAmount ?? this.referenceAmount,
      actualFinalAmount: actualFinalAmount ?? this.actualFinalAmount,
      effectiveMarkupPercent:
          effectiveMarkupPercent ?? this.effectiveMarkupPercent,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<String>(paymentMethodId.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (referenceAmount.present) {
      map['reference_amount'] = Variable<String>(referenceAmount.value);
    }
    if (actualFinalAmount.present) {
      map['actual_final_amount'] = Variable<String>(actualFinalAmount.value);
    }
    if (effectiveMarkupPercent.present) {
      map['effective_markup_percent'] = Variable<String>(
        effectiveMarkupPercent.value,
      );
    }
    if (calculatedAt.present) {
      map['calculated_at'] = Variable<DateTime>(calculatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeeCalibrationsCompanion(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('expenseId: $expenseId, ')
          ..write('referenceAmount: $referenceAmount, ')
          ..write('actualFinalAmount: $actualFinalAmount, ')
          ..write('effectiveMarkupPercent: $effectiveMarkupPercent, ')
          ..write('calculatedAt: $calculatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsRecordsTable extends UserSettingsRecords
    with TableInfo<$UserSettingsRecordsTable, UserSettingsRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultCurrencyMeta = const VerificationMeta(
    'defaultCurrency',
  );
  @override
  late final GeneratedColumn<String> defaultCurrency = GeneratedColumn<String>(
    'default_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _lastTransactionCurrencyMeta =
      const VerificationMeta('lastTransactionCurrency');
  @override
  late final GeneratedColumn<String> lastTransactionCurrency =
      GeneratedColumn<String>(
        'last_transaction_currency',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES currencies (code) ON DELETE RESTRICT',
        ),
      );
  static const VerificationMeta _favoriteCurrenciesJsonMeta =
      const VerificationMeta('favoriteCurrenciesJson');
  @override
  late final GeneratedColumn<String> favoriteCurrenciesJson =
      GeneratedColumn<String>(
        'favorite_currencies_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _languageModeMeta = const VerificationMeta(
    'languageMode',
  );
  @override
  late final GeneratedColumn<String> languageMode = GeneratedColumn<String>(
    'language_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshIntervalMinutesMeta =
      const VerificationMeta('refreshIntervalMinutes');
  @override
  late final GeneratedColumn<int> refreshIntervalMinutes = GeneratedColumn<int>(
    'refresh_interval_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wifiOnlyRefreshMeta = const VerificationMeta(
    'wifiOnlyRefresh',
  );
  @override
  late final GeneratedColumn<bool> wifiOnlyRefresh = GeneratedColumn<bool>(
    'wifi_only_refresh',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wifi_only_refresh" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncEnabledMeta = const VerificationMeta(
    'syncEnabled',
  );
  @override
  late final GeneratedColumn<bool> syncEnabled = GeneratedColumn<bool>(
    'sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    defaultCurrency,
    lastTransactionCurrency,
    favoriteCurrenciesJson,
    languageMode,
    refreshIntervalMinutes,
    wifiOnlyRefresh,
    syncEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('default_currency')) {
      context.handle(
        _defaultCurrencyMeta,
        defaultCurrency.isAcceptableOrUnknown(
          data['default_currency']!,
          _defaultCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultCurrencyMeta);
    }
    if (data.containsKey('last_transaction_currency')) {
      context.handle(
        _lastTransactionCurrencyMeta,
        lastTransactionCurrency.isAcceptableOrUnknown(
          data['last_transaction_currency']!,
          _lastTransactionCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('favorite_currencies_json')) {
      context.handle(
        _favoriteCurrenciesJsonMeta,
        favoriteCurrenciesJson.isAcceptableOrUnknown(
          data['favorite_currencies_json']!,
          _favoriteCurrenciesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_favoriteCurrenciesJsonMeta);
    }
    if (data.containsKey('language_mode')) {
      context.handle(
        _languageModeMeta,
        languageMode.isAcceptableOrUnknown(
          data['language_mode']!,
          _languageModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageModeMeta);
    }
    if (data.containsKey('refresh_interval_minutes')) {
      context.handle(
        _refreshIntervalMinutesMeta,
        refreshIntervalMinutes.isAcceptableOrUnknown(
          data['refresh_interval_minutes']!,
          _refreshIntervalMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshIntervalMinutesMeta);
    }
    if (data.containsKey('wifi_only_refresh')) {
      context.handle(
        _wifiOnlyRefreshMeta,
        wifiOnlyRefresh.isAcceptableOrUnknown(
          data['wifi_only_refresh']!,
          _wifiOnlyRefreshMeta,
        ),
      );
    }
    if (data.containsKey('sync_enabled')) {
      context.handle(
        _syncEnabledMeta,
        syncEnabled.isAcceptableOrUnknown(
          data['sync_enabled']!,
          _syncEnabledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      defaultCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_currency'],
      )!,
      lastTransactionCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_transaction_currency'],
      ),
      favoriteCurrenciesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favorite_currencies_json'],
      )!,
      languageMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_mode'],
      )!,
      refreshIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refresh_interval_minutes'],
      )!,
      wifiOnlyRefresh: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wifi_only_refresh'],
      )!,
      syncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_enabled'],
      )!,
    );
  }

  @override
  $UserSettingsRecordsTable createAlias(String alias) {
    return $UserSettingsRecordsTable(attachedDatabase, alias);
  }
}

class UserSettingsRecord extends DataClass
    implements Insertable<UserSettingsRecord> {
  final String id;
  final int syncVersion;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String defaultCurrency;
  final String? lastTransactionCurrency;
  final String favoriteCurrenciesJson;
  final String languageMode;
  final int refreshIntervalMinutes;
  final bool wifiOnlyRefresh;
  final bool syncEnabled;
  const UserSettingsRecord({
    required this.id,
    required this.syncVersion,
    required this.updatedAt,
    this.deletedAt,
    required this.defaultCurrency,
    this.lastTransactionCurrency,
    required this.favoriteCurrenciesJson,
    required this.languageMode,
    required this.refreshIntervalMinutes,
    required this.wifiOnlyRefresh,
    required this.syncEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_version'] = Variable<int>(syncVersion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['default_currency'] = Variable<String>(defaultCurrency);
    if (!nullToAbsent || lastTransactionCurrency != null) {
      map['last_transaction_currency'] = Variable<String>(
        lastTransactionCurrency,
      );
    }
    map['favorite_currencies_json'] = Variable<String>(favoriteCurrenciesJson);
    map['language_mode'] = Variable<String>(languageMode);
    map['refresh_interval_minutes'] = Variable<int>(refreshIntervalMinutes);
    map['wifi_only_refresh'] = Variable<bool>(wifiOnlyRefresh);
    map['sync_enabled'] = Variable<bool>(syncEnabled);
    return map;
  }

  UserSettingsRecordsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsRecordsCompanion(
      id: Value(id),
      syncVersion: Value(syncVersion),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      defaultCurrency: Value(defaultCurrency),
      lastTransactionCurrency: lastTransactionCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTransactionCurrency),
      favoriteCurrenciesJson: Value(favoriteCurrenciesJson),
      languageMode: Value(languageMode),
      refreshIntervalMinutes: Value(refreshIntervalMinutes),
      wifiOnlyRefresh: Value(wifiOnlyRefresh),
      syncEnabled: Value(syncEnabled),
    );
  }

  factory UserSettingsRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsRecord(
      id: serializer.fromJson<String>(json['id']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      defaultCurrency: serializer.fromJson<String>(json['defaultCurrency']),
      lastTransactionCurrency: serializer.fromJson<String?>(
        json['lastTransactionCurrency'],
      ),
      favoriteCurrenciesJson: serializer.fromJson<String>(
        json['favoriteCurrenciesJson'],
      ),
      languageMode: serializer.fromJson<String>(json['languageMode']),
      refreshIntervalMinutes: serializer.fromJson<int>(
        json['refreshIntervalMinutes'],
      ),
      wifiOnlyRefresh: serializer.fromJson<bool>(json['wifiOnlyRefresh']),
      syncEnabled: serializer.fromJson<bool>(json['syncEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'defaultCurrency': serializer.toJson<String>(defaultCurrency),
      'lastTransactionCurrency': serializer.toJson<String?>(
        lastTransactionCurrency,
      ),
      'favoriteCurrenciesJson': serializer.toJson<String>(
        favoriteCurrenciesJson,
      ),
      'languageMode': serializer.toJson<String>(languageMode),
      'refreshIntervalMinutes': serializer.toJson<int>(refreshIntervalMinutes),
      'wifiOnlyRefresh': serializer.toJson<bool>(wifiOnlyRefresh),
      'syncEnabled': serializer.toJson<bool>(syncEnabled),
    };
  }

  UserSettingsRecord copyWith({
    String? id,
    int? syncVersion,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? defaultCurrency,
    Value<String?> lastTransactionCurrency = const Value.absent(),
    String? favoriteCurrenciesJson,
    String? languageMode,
    int? refreshIntervalMinutes,
    bool? wifiOnlyRefresh,
    bool? syncEnabled,
  }) => UserSettingsRecord(
    id: id ?? this.id,
    syncVersion: syncVersion ?? this.syncVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    lastTransactionCurrency: lastTransactionCurrency.present
        ? lastTransactionCurrency.value
        : this.lastTransactionCurrency,
    favoriteCurrenciesJson:
        favoriteCurrenciesJson ?? this.favoriteCurrenciesJson,
    languageMode: languageMode ?? this.languageMode,
    refreshIntervalMinutes:
        refreshIntervalMinutes ?? this.refreshIntervalMinutes,
    wifiOnlyRefresh: wifiOnlyRefresh ?? this.wifiOnlyRefresh,
    syncEnabled: syncEnabled ?? this.syncEnabled,
  );
  UserSettingsRecord copyWithCompanion(UserSettingsRecordsCompanion data) {
    return UserSettingsRecord(
      id: data.id.present ? data.id.value : this.id,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      defaultCurrency: data.defaultCurrency.present
          ? data.defaultCurrency.value
          : this.defaultCurrency,
      lastTransactionCurrency: data.lastTransactionCurrency.present
          ? data.lastTransactionCurrency.value
          : this.lastTransactionCurrency,
      favoriteCurrenciesJson: data.favoriteCurrenciesJson.present
          ? data.favoriteCurrenciesJson.value
          : this.favoriteCurrenciesJson,
      languageMode: data.languageMode.present
          ? data.languageMode.value
          : this.languageMode,
      refreshIntervalMinutes: data.refreshIntervalMinutes.present
          ? data.refreshIntervalMinutes.value
          : this.refreshIntervalMinutes,
      wifiOnlyRefresh: data.wifiOnlyRefresh.present
          ? data.wifiOnlyRefresh.value
          : this.wifiOnlyRefresh,
      syncEnabled: data.syncEnabled.present
          ? data.syncEnabled.value
          : this.syncEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsRecord(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('lastTransactionCurrency: $lastTransactionCurrency, ')
          ..write('favoriteCurrenciesJson: $favoriteCurrenciesJson, ')
          ..write('languageMode: $languageMode, ')
          ..write('refreshIntervalMinutes: $refreshIntervalMinutes, ')
          ..write('wifiOnlyRefresh: $wifiOnlyRefresh, ')
          ..write('syncEnabled: $syncEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncVersion,
    updatedAt,
    deletedAt,
    defaultCurrency,
    lastTransactionCurrency,
    favoriteCurrenciesJson,
    languageMode,
    refreshIntervalMinutes,
    wifiOnlyRefresh,
    syncEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsRecord &&
          other.id == this.id &&
          other.syncVersion == this.syncVersion &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.defaultCurrency == this.defaultCurrency &&
          other.lastTransactionCurrency == this.lastTransactionCurrency &&
          other.favoriteCurrenciesJson == this.favoriteCurrenciesJson &&
          other.languageMode == this.languageMode &&
          other.refreshIntervalMinutes == this.refreshIntervalMinutes &&
          other.wifiOnlyRefresh == this.wifiOnlyRefresh &&
          other.syncEnabled == this.syncEnabled);
}

class UserSettingsRecordsCompanion extends UpdateCompanion<UserSettingsRecord> {
  final Value<String> id;
  final Value<int> syncVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> defaultCurrency;
  final Value<String?> lastTransactionCurrency;
  final Value<String> favoriteCurrenciesJson;
  final Value<String> languageMode;
  final Value<int> refreshIntervalMinutes;
  final Value<bool> wifiOnlyRefresh;
  final Value<bool> syncEnabled;
  final Value<int> rowid;
  const UserSettingsRecordsCompanion({
    this.id = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.defaultCurrency = const Value.absent(),
    this.lastTransactionCurrency = const Value.absent(),
    this.favoriteCurrenciesJson = const Value.absent(),
    this.languageMode = const Value.absent(),
    this.refreshIntervalMinutes = const Value.absent(),
    this.wifiOnlyRefresh = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSettingsRecordsCompanion.insert({
    required String id,
    this.syncVersion = const Value.absent(),
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    required String defaultCurrency,
    this.lastTransactionCurrency = const Value.absent(),
    required String favoriteCurrenciesJson,
    required String languageMode,
    required int refreshIntervalMinutes,
    this.wifiOnlyRefresh = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       defaultCurrency = Value(defaultCurrency),
       favoriteCurrenciesJson = Value(favoriteCurrenciesJson),
       languageMode = Value(languageMode),
       refreshIntervalMinutes = Value(refreshIntervalMinutes);
  static Insertable<UserSettingsRecord> custom({
    Expression<String>? id,
    Expression<int>? syncVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? defaultCurrency,
    Expression<String>? lastTransactionCurrency,
    Expression<String>? favoriteCurrenciesJson,
    Expression<String>? languageMode,
    Expression<int>? refreshIntervalMinutes,
    Expression<bool>? wifiOnlyRefresh,
    Expression<bool>? syncEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (lastTransactionCurrency != null)
        'last_transaction_currency': lastTransactionCurrency,
      if (favoriteCurrenciesJson != null)
        'favorite_currencies_json': favoriteCurrenciesJson,
      if (languageMode != null) 'language_mode': languageMode,
      if (refreshIntervalMinutes != null)
        'refresh_interval_minutes': refreshIntervalMinutes,
      if (wifiOnlyRefresh != null) 'wifi_only_refresh': wifiOnlyRefresh,
      if (syncEnabled != null) 'sync_enabled': syncEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSettingsRecordsCompanion copyWith({
    Value<String>? id,
    Value<int>? syncVersion,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? defaultCurrency,
    Value<String?>? lastTransactionCurrency,
    Value<String>? favoriteCurrenciesJson,
    Value<String>? languageMode,
    Value<int>? refreshIntervalMinutes,
    Value<bool>? wifiOnlyRefresh,
    Value<bool>? syncEnabled,
    Value<int>? rowid,
  }) {
    return UserSettingsRecordsCompanion(
      id: id ?? this.id,
      syncVersion: syncVersion ?? this.syncVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      lastTransactionCurrency:
          lastTransactionCurrency ?? this.lastTransactionCurrency,
      favoriteCurrenciesJson:
          favoriteCurrenciesJson ?? this.favoriteCurrenciesJson,
      languageMode: languageMode ?? this.languageMode,
      refreshIntervalMinutes:
          refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      wifiOnlyRefresh: wifiOnlyRefresh ?? this.wifiOnlyRefresh,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (defaultCurrency.present) {
      map['default_currency'] = Variable<String>(defaultCurrency.value);
    }
    if (lastTransactionCurrency.present) {
      map['last_transaction_currency'] = Variable<String>(
        lastTransactionCurrency.value,
      );
    }
    if (favoriteCurrenciesJson.present) {
      map['favorite_currencies_json'] = Variable<String>(
        favoriteCurrenciesJson.value,
      );
    }
    if (languageMode.present) {
      map['language_mode'] = Variable<String>(languageMode.value);
    }
    if (refreshIntervalMinutes.present) {
      map['refresh_interval_minutes'] = Variable<int>(
        refreshIntervalMinutes.value,
      );
    }
    if (wifiOnlyRefresh.present) {
      map['wifi_only_refresh'] = Variable<bool>(wifiOnlyRefresh.value);
    }
    if (syncEnabled.present) {
      map['sync_enabled'] = Variable<bool>(syncEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsRecordsCompanion(')
          ..write('id: $id, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('lastTransactionCurrency: $lastTransactionCurrency, ')
          ..write('favoriteCurrenciesJson: $favoriteCurrenciesJson, ')
          ..write('languageMode: $languageMode, ')
          ..write('refreshIntervalMinutes: $refreshIntervalMinutes, ')
          ..write('wifiOnlyRefresh: $wifiOnlyRefresh, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataEntriesTable extends SyncMetadataEntries
    with TableInfo<$SyncMetadataEntriesTable, SyncMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changeIdMeta = const VerificationMeta(
    'changeId',
  );
  @override
  late final GeneratedColumn<String> changeId = GeneratedColumn<String>(
    'change_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedPayloadJsonMeta =
      const VerificationMeta('lastSyncedPayloadJson');
  @override
  late final GeneratedColumn<String> lastSyncedPayloadJson =
      GeneratedColumn<String>(
        'last_synced_payload_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    entityType,
    recordId,
    syncVersion,
    syncState,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    lastErrorCode,
    deviceId,
    changeId,
    lastSyncedPayloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncVersionMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('change_id')) {
      context.handle(
        _changeIdMeta,
        changeId.isAcceptableOrUnknown(data['change_id']!, _changeIdMeta),
      );
    }
    if (data.containsKey('last_synced_payload_json')) {
      context.handle(
        _lastSyncedPayloadJsonMeta,
        lastSyncedPayloadJson.isAcceptableOrUnknown(
          data['last_synced_payload_json']!,
          _lastSyncedPayloadJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, recordId};
  @override
  SyncMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataEntry(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      changeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_id'],
      ),
      lastSyncedPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_synced_payload_json'],
      ),
    );
  }

  @override
  $SyncMetadataEntriesTable createAlias(String alias) {
    return $SyncMetadataEntriesTable(attachedDatabase, alias);
  }
}

class SyncMetadataEntry extends DataClass
    implements Insertable<SyncMetadataEntry> {
  final String entityType;
  final String recordId;
  final int syncVersion;
  final String syncState;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastSyncedAt;
  final String? lastErrorCode;
  final String? deviceId;
  final String? changeId;
  final String? lastSyncedPayloadJson;
  const SyncMetadataEntry({
    required this.entityType,
    required this.recordId,
    required this.syncVersion,
    required this.syncState,
    required this.updatedAt,
    this.deletedAt,
    this.lastSyncedAt,
    this.lastErrorCode,
    this.deviceId,
    this.changeId,
    this.lastSyncedPayloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['record_id'] = Variable<String>(recordId);
    map['sync_version'] = Variable<int>(syncVersion);
    map['sync_state'] = Variable<String>(syncState);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || changeId != null) {
      map['change_id'] = Variable<String>(changeId);
    }
    if (!nullToAbsent || lastSyncedPayloadJson != null) {
      map['last_synced_payload_json'] = Variable<String>(lastSyncedPayloadJson);
    }
    return map;
  }

  SyncMetadataEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataEntriesCompanion(
      entityType: Value(entityType),
      recordId: Value(recordId),
      syncVersion: Value(syncVersion),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      changeId: changeId == null && nullToAbsent
          ? const Value.absent()
          : Value(changeId),
      lastSyncedPayloadJson: lastSyncedPayloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedPayloadJson),
    );
  }

  factory SyncMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataEntry(
      entityType: serializer.fromJson<String>(json['entityType']),
      recordId: serializer.fromJson<String>(json['recordId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      syncState: serializer.fromJson<String>(json['syncState']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      changeId: serializer.fromJson<String?>(json['changeId']),
      lastSyncedPayloadJson: serializer.fromJson<String?>(
        json['lastSyncedPayloadJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'recordId': serializer.toJson<String>(recordId),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'syncState': serializer.toJson<String>(syncState),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'deviceId': serializer.toJson<String?>(deviceId),
      'changeId': serializer.toJson<String?>(changeId),
      'lastSyncedPayloadJson': serializer.toJson<String?>(
        lastSyncedPayloadJson,
      ),
    };
  }

  SyncMetadataEntry copyWith({
    String? entityType,
    String? recordId,
    int? syncVersion,
    String? syncState,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<String?> deviceId = const Value.absent(),
    Value<String?> changeId = const Value.absent(),
    Value<String?> lastSyncedPayloadJson = const Value.absent(),
  }) => SyncMetadataEntry(
    entityType: entityType ?? this.entityType,
    recordId: recordId ?? this.recordId,
    syncVersion: syncVersion ?? this.syncVersion,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    changeId: changeId.present ? changeId.value : this.changeId,
    lastSyncedPayloadJson: lastSyncedPayloadJson.present
        ? lastSyncedPayloadJson.value
        : this.lastSyncedPayloadJson,
  );
  SyncMetadataEntry copyWithCompanion(SyncMetadataEntriesCompanion data) {
    return SyncMetadataEntry(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      changeId: data.changeId.present ? data.changeId.value : this.changeId,
      lastSyncedPayloadJson: data.lastSyncedPayloadJson.present
          ? data.lastSyncedPayloadJson.value
          : this.lastSyncedPayloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntry(')
          ..write('entityType: $entityType, ')
          ..write('recordId: $recordId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('deviceId: $deviceId, ')
          ..write('changeId: $changeId, ')
          ..write('lastSyncedPayloadJson: $lastSyncedPayloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entityType,
    recordId,
    syncVersion,
    syncState,
    updatedAt,
    deletedAt,
    lastSyncedAt,
    lastErrorCode,
    deviceId,
    changeId,
    lastSyncedPayloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataEntry &&
          other.entityType == this.entityType &&
          other.recordId == this.recordId &&
          other.syncVersion == this.syncVersion &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.deviceId == this.deviceId &&
          other.changeId == this.changeId &&
          other.lastSyncedPayloadJson == this.lastSyncedPayloadJson);
}

class SyncMetadataEntriesCompanion extends UpdateCompanion<SyncMetadataEntry> {
  final Value<String> entityType;
  final Value<String> recordId;
  final Value<int> syncVersion;
  final Value<String> syncState;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> lastErrorCode;
  final Value<String?> deviceId;
  final Value<String?> changeId;
  final Value<String?> lastSyncedPayloadJson;
  final Value<int> rowid;
  const SyncMetadataEntriesCompanion({
    this.entityType = const Value.absent(),
    this.recordId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.changeId = const Value.absent(),
    this.lastSyncedPayloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataEntriesCompanion.insert({
    required String entityType,
    required String recordId,
    required int syncVersion,
    required String syncState,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.changeId = const Value.absent(),
    this.lastSyncedPayloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       recordId = Value(recordId),
       syncVersion = Value(syncVersion),
       syncState = Value(syncState),
       updatedAt = Value(updatedAt);
  static Insertable<SyncMetadataEntry> custom({
    Expression<String>? entityType,
    Expression<String>? recordId,
    Expression<int>? syncVersion,
    Expression<String>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? lastErrorCode,
    Expression<String>? deviceId,
    Expression<String>? changeId,
    Expression<String>? lastSyncedPayloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (recordId != null) 'record_id': recordId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (deviceId != null) 'device_id': deviceId,
      if (changeId != null) 'change_id': changeId,
      if (lastSyncedPayloadJson != null)
        'last_synced_payload_json': lastSyncedPayloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataEntriesCompanion copyWith({
    Value<String>? entityType,
    Value<String>? recordId,
    Value<int>? syncVersion,
    Value<String>? syncState,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? lastErrorCode,
    Value<String?>? deviceId,
    Value<String?>? changeId,
    Value<String?>? lastSyncedPayloadJson,
    Value<int>? rowid,
  }) {
    return SyncMetadataEntriesCompanion(
      entityType: entityType ?? this.entityType,
      recordId: recordId ?? this.recordId,
      syncVersion: syncVersion ?? this.syncVersion,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      deviceId: deviceId ?? this.deviceId,
      changeId: changeId ?? this.changeId,
      lastSyncedPayloadJson:
          lastSyncedPayloadJson ?? this.lastSyncedPayloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (changeId.present) {
      map['change_id'] = Variable<String>(changeId.value);
    }
    if (lastSyncedPayloadJson.present) {
      map['last_synced_payload_json'] = Variable<String>(
        lastSyncedPayloadJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntriesCompanion(')
          ..write('entityType: $entityType, ')
          ..write('recordId: $recordId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('deviceId: $deviceId, ')
          ..write('changeId: $changeId, ')
          ..write('lastSyncedPayloadJson: $lastSyncedPayloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncRuntimeEntriesTable extends SyncRuntimeEntries
    with TableInfo<$SyncRuntimeEntriesTable, SyncRuntimeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRuntimeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountStateMeta = const VerificationMeta(
    'accountState',
  );
  @override
  late final GeneratedColumn<String> accountState = GeneratedColumn<String>(
    'account_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureCountMeta = const VerificationMeta(
    'failureCount',
  );
  @override
  late final GeneratedColumn<int> failureCount = GeneratedColumn<int>(
    'failure_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSuccessAtMeta = const VerificationMeta(
    'lastSuccessAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>(
        'last_success_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cursor,
    deviceId,
    accountState,
    phase,
    failureCount,
    lastAttemptAt,
    lastSuccessAt,
    nextRetryAt,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_runtime_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRuntimeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('account_state')) {
      context.handle(
        _accountStateMeta,
        accountState.isAcceptableOrUnknown(
          data['account_state']!,
          _accountStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountStateMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('failure_count')) {
      context.handle(
        _failureCountMeta,
        failureCount.isAcceptableOrUnknown(
          data['failure_count']!,
          _failureCountMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
        _lastSuccessAtMeta,
        lastSuccessAt.isAcceptableOrUnknown(
          data['last_success_at']!,
          _lastSuccessAtMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncRuntimeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRuntimeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      accountState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_state'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      failureCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failure_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastSuccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_success_at'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  $SyncRuntimeEntriesTable createAlias(String alias) {
    return $SyncRuntimeEntriesTable(attachedDatabase, alias);
  }
}

class SyncRuntimeEntry extends DataClass
    implements Insertable<SyncRuntimeEntry> {
  final String id;
  final String? cursor;
  final String deviceId;
  final String accountState;
  final String phase;
  final int failureCount;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final DateTime? nextRetryAt;
  final String? lastErrorCode;
  const SyncRuntimeEntry({
    required this.id,
    this.cursor,
    required this.deviceId,
    required this.accountState,
    required this.phase,
    required this.failureCount,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.nextRetryAt,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['account_state'] = Variable<String>(accountState);
    map['phase'] = Variable<String>(phase);
    map['failure_count'] = Variable<int>(failureCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  SyncRuntimeEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncRuntimeEntriesCompanion(
      id: Value(id),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      deviceId: Value(deviceId),
      accountState: Value(accountState),
      phase: Value(phase),
      failureCount: Value(failureCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory SyncRuntimeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRuntimeEntry(
      id: serializer.fromJson<String>(json['id']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      accountState: serializer.fromJson<String>(json['accountState']),
      phase: serializer.fromJson<String>(json['phase']),
      failureCount: serializer.fromJson<int>(json['failureCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cursor': serializer.toJson<String?>(cursor),
      'deviceId': serializer.toJson<String>(deviceId),
      'accountState': serializer.toJson<String>(accountState),
      'phase': serializer.toJson<String>(phase),
      'failureCount': serializer.toJson<int>(failureCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
    };
  }

  SyncRuntimeEntry copyWith({
    String? id,
    Value<String?> cursor = const Value.absent(),
    String? deviceId,
    String? accountState,
    String? phase,
    int? failureCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> lastSuccessAt = const Value.absent(),
    Value<DateTime?> nextRetryAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
  }) => SyncRuntimeEntry(
    id: id ?? this.id,
    cursor: cursor.present ? cursor.value : this.cursor,
    deviceId: deviceId ?? this.deviceId,
    accountState: accountState ?? this.accountState,
    phase: phase ?? this.phase,
    failureCount: failureCount ?? this.failureCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastSuccessAt: lastSuccessAt.present
        ? lastSuccessAt.value
        : this.lastSuccessAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  SyncRuntimeEntry copyWithCompanion(SyncRuntimeEntriesCompanion data) {
    return SyncRuntimeEntry(
      id: data.id.present ? data.id.value : this.id,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      accountState: data.accountState.present
          ? data.accountState.value
          : this.accountState,
      phase: data.phase.present ? data.phase.value : this.phase,
      failureCount: data.failureCount.present
          ? data.failureCount.value
          : this.failureCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRuntimeEntry(')
          ..write('id: $id, ')
          ..write('cursor: $cursor, ')
          ..write('deviceId: $deviceId, ')
          ..write('accountState: $accountState, ')
          ..write('phase: $phase, ')
          ..write('failureCount: $failureCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cursor,
    deviceId,
    accountState,
    phase,
    failureCount,
    lastAttemptAt,
    lastSuccessAt,
    nextRetryAt,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRuntimeEntry &&
          other.id == this.id &&
          other.cursor == this.cursor &&
          other.deviceId == this.deviceId &&
          other.accountState == this.accountState &&
          other.phase == this.phase &&
          other.failureCount == this.failureCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastErrorCode == this.lastErrorCode);
}

class SyncRuntimeEntriesCompanion extends UpdateCompanion<SyncRuntimeEntry> {
  final Value<String> id;
  final Value<String?> cursor;
  final Value<String> deviceId;
  final Value<String> accountState;
  final Value<String> phase;
  final Value<int> failureCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> lastSuccessAt;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastErrorCode;
  final Value<int> rowid;
  const SyncRuntimeEntriesCompanion({
    this.id = const Value.absent(),
    this.cursor = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.accountState = const Value.absent(),
    this.phase = const Value.absent(),
    this.failureCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRuntimeEntriesCompanion.insert({
    required String id,
    this.cursor = const Value.absent(),
    required String deviceId,
    required String accountState,
    required String phase,
    this.failureCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deviceId = Value(deviceId),
       accountState = Value(accountState),
       phase = Value(phase);
  static Insertable<SyncRuntimeEntry> custom({
    Expression<String>? id,
    Expression<String>? cursor,
    Expression<String>? deviceId,
    Expression<String>? accountState,
    Expression<String>? phase,
    Expression<int>? failureCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? lastSuccessAt,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastErrorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cursor != null) 'cursor': cursor,
      if (deviceId != null) 'device_id': deviceId,
      if (accountState != null) 'account_state': accountState,
      if (phase != null) 'phase': phase,
      if (failureCount != null) 'failure_count': failureCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRuntimeEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? cursor,
    Value<String>? deviceId,
    Value<String>? accountState,
    Value<String>? phase,
    Value<int>? failureCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? lastSuccessAt,
    Value<DateTime?>? nextRetryAt,
    Value<String?>? lastErrorCode,
    Value<int>? rowid,
  }) {
    return SyncRuntimeEntriesCompanion(
      id: id ?? this.id,
      cursor: cursor ?? this.cursor,
      deviceId: deviceId ?? this.deviceId,
      accountState: accountState ?? this.accountState,
      phase: phase ?? this.phase,
      failureCount: failureCount ?? this.failureCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (accountState.present) {
      map['account_state'] = Variable<String>(accountState.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (failureCount.present) {
      map['failure_count'] = Variable<int>(failureCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRuntimeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('cursor: $cursor, ')
          ..write('deviceId: $deviceId, ')
          ..write('accountState: $accountState, ')
          ..write('phase: $phase, ')
          ..write('failureCount: $failureCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictEntriesTable extends SyncConflictEntries
    with TableInfo<$SyncConflictEntriesTable, SyncConflictEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPayloadJsonMeta = const VerificationMeta(
    'localPayloadJson',
  );
  @override
  late final GeneratedColumn<String> localPayloadJson = GeneratedColumn<String>(
    'local_payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remotePayloadJsonMeta = const VerificationMeta(
    'remotePayloadJson',
  );
  @override
  late final GeneratedColumn<String> remotePayloadJson =
      GeneratedColumn<String>(
        'remote_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    recordId,
    fieldName,
    localPayloadJson,
    remotePayloadJson,
    detectedAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflict_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflictEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('local_payload_json')) {
      context.handle(
        _localPayloadJsonMeta,
        localPayloadJson.isAcceptableOrUnknown(
          data['local_payload_json']!,
          _localPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localPayloadJsonMeta);
    }
    if (data.containsKey('remote_payload_json')) {
      context.handle(
        _remotePayloadJsonMeta,
        remotePayloadJson.isAcceptableOrUnknown(
          data['remote_payload_json']!,
          _remotePayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remotePayloadJsonMeta);
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_detectedAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflictEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflictEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      localPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_payload_json'],
      )!,
      remotePayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_payload_json'],
      )!,
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $SyncConflictEntriesTable createAlias(String alias) {
    return $SyncConflictEntriesTable(attachedDatabase, alias);
  }
}

class SyncConflictEntry extends DataClass
    implements Insertable<SyncConflictEntry> {
  final String id;
  final String entityType;
  final String recordId;
  final String fieldName;
  final String localPayloadJson;
  final String remotePayloadJson;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  const SyncConflictEntry({
    required this.id,
    required this.entityType,
    required this.recordId,
    required this.fieldName,
    required this.localPayloadJson,
    required this.remotePayloadJson,
    required this.detectedAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['record_id'] = Variable<String>(recordId);
    map['field_name'] = Variable<String>(fieldName);
    map['local_payload_json'] = Variable<String>(localPayloadJson);
    map['remote_payload_json'] = Variable<String>(remotePayloadJson);
    map['detected_at'] = Variable<DateTime>(detectedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  SyncConflictEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictEntriesCompanion(
      id: Value(id),
      entityType: Value(entityType),
      recordId: Value(recordId),
      fieldName: Value(fieldName),
      localPayloadJson: Value(localPayloadJson),
      remotePayloadJson: Value(remotePayloadJson),
      detectedAt: Value(detectedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory SyncConflictEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflictEntry(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      recordId: serializer.fromJson<String>(json['recordId']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      localPayloadJson: serializer.fromJson<String>(json['localPayloadJson']),
      remotePayloadJson: serializer.fromJson<String>(json['remotePayloadJson']),
      detectedAt: serializer.fromJson<DateTime>(json['detectedAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'recordId': serializer.toJson<String>(recordId),
      'fieldName': serializer.toJson<String>(fieldName),
      'localPayloadJson': serializer.toJson<String>(localPayloadJson),
      'remotePayloadJson': serializer.toJson<String>(remotePayloadJson),
      'detectedAt': serializer.toJson<DateTime>(detectedAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  SyncConflictEntry copyWith({
    String? id,
    String? entityType,
    String? recordId,
    String? fieldName,
    String? localPayloadJson,
    String? remotePayloadJson,
    DateTime? detectedAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => SyncConflictEntry(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    recordId: recordId ?? this.recordId,
    fieldName: fieldName ?? this.fieldName,
    localPayloadJson: localPayloadJson ?? this.localPayloadJson,
    remotePayloadJson: remotePayloadJson ?? this.remotePayloadJson,
    detectedAt: detectedAt ?? this.detectedAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  SyncConflictEntry copyWithCompanion(SyncConflictEntriesCompanion data) {
    return SyncConflictEntry(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      localPayloadJson: data.localPayloadJson.present
          ? data.localPayloadJson.value
          : this.localPayloadJson,
      remotePayloadJson: data.remotePayloadJson.present
          ? data.remotePayloadJson.value
          : this.remotePayloadJson,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictEntry(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('recordId: $recordId, ')
          ..write('fieldName: $fieldName, ')
          ..write('localPayloadJson: $localPayloadJson, ')
          ..write('remotePayloadJson: $remotePayloadJson, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    recordId,
    fieldName,
    localPayloadJson,
    remotePayloadJson,
    detectedAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflictEntry &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.recordId == this.recordId &&
          other.fieldName == this.fieldName &&
          other.localPayloadJson == this.localPayloadJson &&
          other.remotePayloadJson == this.remotePayloadJson &&
          other.detectedAt == this.detectedAt &&
          other.resolvedAt == this.resolvedAt);
}

class SyncConflictEntriesCompanion extends UpdateCompanion<SyncConflictEntry> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> recordId;
  final Value<String> fieldName;
  final Value<String> localPayloadJson;
  final Value<String> remotePayloadJson;
  final Value<DateTime> detectedAt;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const SyncConflictEntriesCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.recordId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.localPayloadJson = const Value.absent(),
    this.remotePayloadJson = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictEntriesCompanion.insert({
    required String id,
    required String entityType,
    required String recordId,
    required String fieldName,
    required String localPayloadJson,
    required String remotePayloadJson,
    required DateTime detectedAt,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       recordId = Value(recordId),
       fieldName = Value(fieldName),
       localPayloadJson = Value(localPayloadJson),
       remotePayloadJson = Value(remotePayloadJson),
       detectedAt = Value(detectedAt);
  static Insertable<SyncConflictEntry> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? recordId,
    Expression<String>? fieldName,
    Expression<String>? localPayloadJson,
    Expression<String>? remotePayloadJson,
    Expression<DateTime>? detectedAt,
    Expression<DateTime>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (recordId != null) 'record_id': recordId,
      if (fieldName != null) 'field_name': fieldName,
      if (localPayloadJson != null) 'local_payload_json': localPayloadJson,
      if (remotePayloadJson != null) 'remote_payload_json': remotePayloadJson,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? recordId,
    Value<String>? fieldName,
    Value<String>? localPayloadJson,
    Value<String>? remotePayloadJson,
    Value<DateTime>? detectedAt,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return SyncConflictEntriesCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      recordId: recordId ?? this.recordId,
      fieldName: fieldName ?? this.fieldName,
      localPayloadJson: localPayloadJson ?? this.localPayloadJson,
      remotePayloadJson: remotePayloadJson ?? this.remotePayloadJson,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (localPayloadJson.present) {
      map['local_payload_json'] = Variable<String>(localPayloadJson.value);
    }
    if (remotePayloadJson.present) {
      map['remote_payload_json'] = Variable<String>(remotePayloadJson.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('recordId: $recordId, ')
          ..write('fieldName: $fieldName, ')
          ..write('localPayloadJson: $localPayloadJson, ')
          ..write('remotePayloadJson: $remotePayloadJson, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CurrenciesTable currencies = $CurrenciesTable(this);
  late final $RateSnapshotsTable rateSnapshots = $RateSnapshotsTable(this);
  late final $PaymentMethodsTable paymentMethods = $PaymentMethodsTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $FeeCalibrationsTable feeCalibrations = $FeeCalibrationsTable(
    this,
  );
  late final $UserSettingsRecordsTable userSettingsRecords =
      $UserSettingsRecordsTable(this);
  late final $SyncMetadataEntriesTable syncMetadataEntries =
      $SyncMetadataEntriesTable(this);
  late final $SyncRuntimeEntriesTable syncRuntimeEntries =
      $SyncRuntimeEntriesTable(this);
  late final $SyncConflictEntriesTable syncConflictEntries =
      $SyncConflictEntriesTable(this);
  late final CoreDao coreDao = CoreDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    currencies,
    rateSnapshots,
    paymentMethods,
    trips,
    expenses,
    feeCalibrations,
    userSettingsRecords,
    syncMetadataEntries,
    syncRuntimeEntries,
    syncConflictEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'payment_methods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('trips', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('expenses', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'payment_methods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('expenses', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'rate_snapshots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('expenses', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$CurrenciesTableCreateCompanionBuilder =
    CurrenciesCompanion Function({
      required String code,
      Value<String?> numericCode,
      required String name,
      required String symbol,
      required int minorUnits,
      Value<String> countryCodesJson,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CurrenciesTableUpdateCompanionBuilder =
    CurrenciesCompanion Function({
      Value<String> code,
      Value<String?> numericCode,
      Value<String> name,
      Value<String> symbol,
      Value<int> minorUnits,
      Value<String> countryCodesJson,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$CurrenciesTableReferences
    extends BaseReferences<_$AppDatabase, $CurrenciesTable, Currency> {
  $$CurrenciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RateSnapshotsTable, List<RateSnapshot>>
  _baseCurrencyRateSnapshotsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rateSnapshots,
        aliasName: $_aliasNameGenerator(
          db.currencies.code,
          db.rateSnapshots.baseCurrency,
        ),
      );

  $$RateSnapshotsTableProcessedTableManager get baseCurrencyRateSnapshots {
    final manager = $$RateSnapshotsTableTableManager($_db, $_db.rateSnapshots)
        .filter(
          (f) => f.baseCurrency.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _baseCurrencyRateSnapshotsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RateSnapshotsTable, List<RateSnapshot>>
  _quoteCurrencyRateSnapshotsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.rateSnapshots,
        aliasName: $_aliasNameGenerator(
          db.currencies.code,
          db.rateSnapshots.quoteCurrency,
        ),
      );

  $$RateSnapshotsTableProcessedTableManager get quoteCurrencyRateSnapshots {
    final manager = $$RateSnapshotsTableTableManager($_db, $_db.rateSnapshots)
        .filter(
          (f) => f.quoteCurrency.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _quoteCurrencyRateSnapshotsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentMethodsTable, List<PaymentMethod>>
  _paymentMethodsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.paymentMethods,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.paymentMethods.billingCurrency,
    ),
  );

  $$PaymentMethodsTableProcessedTableManager get paymentMethodsRefs {
    final manager = $$PaymentMethodsTableTableManager($_db, $_db.paymentMethods)
        .filter(
          (f) =>
              f.billingCurrency.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_paymentMethodsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TripsTable, List<Trip>> _tripsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.trips,
    aliasName: $_aliasNameGenerator(db.currencies.code, db.trips.homeCurrency),
  );

  $$TripsTableProcessedTableManager get tripsRefs {
    final manager = $$TripsTableTableManager($_db, $_db.trips).filter(
      (f) => f.homeCurrency.code.sqlEquals($_itemColumn<String>('code')!),
    );

    final cache = $_typedResult.readTableOrNull(_tripsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>>
  _transactionCurrencyExpensesTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.expenses,
        aliasName: $_aliasNameGenerator(
          db.currencies.code,
          db.expenses.transactionCurrency,
        ),
      );

  $$ExpensesTableProcessedTableManager get transactionCurrencyExpenses {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) =>
          f.transactionCurrency.code.sqlEquals($_itemColumn<String>('code')!),
    );

    final cache = $_typedResult.readTableOrNull(
      _transactionCurrencyExpensesTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>>
  _homeCurrencyExpensesTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.expenses.homeCurrency,
    ),
  );

  $$ExpensesTableProcessedTableManager get homeCurrencyExpenses {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) => f.homeCurrency.code.sqlEquals($_itemColumn<String>('code')!),
    );

    final cache = $_typedResult.readTableOrNull(
      _homeCurrencyExpensesTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $UserSettingsRecordsTable,
    List<UserSettingsRecord>
  >
  _userSettingsRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userSettingsRecords,
        aliasName: $_aliasNameGenerator(
          db.currencies.code,
          db.userSettingsRecords.defaultCurrency,
        ),
      );

  $$UserSettingsRecordsTableProcessedTableManager get userSettingsRecordsRefs {
    final manager =
        $$UserSettingsRecordsTableTableManager(
          $_db,
          $_db.userSettingsRecords,
        ).filter(
          (f) =>
              f.defaultCurrency.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _userSettingsRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $UserSettingsRecordsTable,
    List<UserSettingsRecord>
  >
  _lastTransactionCurrencySettingsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userSettingsRecords,
        aliasName: $_aliasNameGenerator(
          db.currencies.code,
          db.userSettingsRecords.lastTransactionCurrency,
        ),
      );

  $$UserSettingsRecordsTableProcessedTableManager
  get lastTransactionCurrencySettings {
    final manager =
        $$UserSettingsRecordsTableTableManager(
          $_db,
          $_db.userSettingsRecords,
        ).filter(
          (f) => f.lastTransactionCurrency.code.sqlEquals(
            $_itemColumn<String>('code')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _lastTransactionCurrencySettingsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CurrenciesTableFilterComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numericCode => $composableBuilder(
    column: $table.numericCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCodesJson => $composableBuilder(
    column: $table.countryCodesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> baseCurrencyRateSnapshots(
    Expression<bool> Function($$RateSnapshotsTableFilterComposer f) f,
  ) {
    final $$RateSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.rateSnapshots,
      getReferencedColumn: (t) => t.baseCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.rateSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> quoteCurrencyRateSnapshots(
    Expression<bool> Function($$RateSnapshotsTableFilterComposer f) f,
  ) {
    final $$RateSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.rateSnapshots,
      getReferencedColumn: (t) => t.quoteCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.rateSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentMethodsRefs(
    Expression<bool> Function($$PaymentMethodsTableFilterComposer f) f,
  ) {
    final $$PaymentMethodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.billingCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableFilterComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tripsRefs(
    Expression<bool> Function($$TripsTableFilterComposer f) f,
  ) {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.homeCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionCurrencyExpenses(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.transactionCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> homeCurrencyExpenses(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.homeCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userSettingsRecordsRefs(
    Expression<bool> Function($$UserSettingsRecordsTableFilterComposer f) f,
  ) {
    final $$UserSettingsRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.userSettingsRecords,
      getReferencedColumn: (t) => t.defaultCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserSettingsRecordsTableFilterComposer(
            $db: $db,
            $table: $db.userSettingsRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lastTransactionCurrencySettings(
    Expression<bool> Function($$UserSettingsRecordsTableFilterComposer f) f,
  ) {
    final $$UserSettingsRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.userSettingsRecords,
      getReferencedColumn: (t) => t.lastTransactionCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserSettingsRecordsTableFilterComposer(
            $db: $db,
            $table: $db.userSettingsRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numericCode => $composableBuilder(
    column: $table.numericCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCodesJson => $composableBuilder(
    column: $table.countryCodesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurrenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get numericCode => $composableBuilder(
    column: $table.numericCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<int> get minorUnits => $composableBuilder(
    column: $table.minorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countryCodesJson => $composableBuilder(
    column: $table.countryCodesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> baseCurrencyRateSnapshots<T extends Object>(
    Expression<T> Function($$RateSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$RateSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.rateSnapshots,
      getReferencedColumn: (t) => t.baseCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.rateSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> quoteCurrencyRateSnapshots<T extends Object>(
    Expression<T> Function($$RateSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$RateSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.rateSnapshots,
      getReferencedColumn: (t) => t.quoteCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.rateSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentMethodsRefs<T extends Object>(
    Expression<T> Function($$PaymentMethodsTableAnnotationComposer a) f,
  ) {
    final $$PaymentMethodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.billingCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tripsRefs<T extends Object>(
    Expression<T> Function($$TripsTableAnnotationComposer a) f,
  ) {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.homeCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionCurrencyExpenses<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.transactionCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> homeCurrencyExpenses<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.homeCurrency,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userSettingsRecordsRefs<T extends Object>(
    Expression<T> Function($$UserSettingsRecordsTableAnnotationComposer a) f,
  ) {
    final $$UserSettingsRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.code,
          referencedTable: $db.userSettingsRecords,
          getReferencedColumn: (t) => t.defaultCurrency,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserSettingsRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.userSettingsRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> lastTransactionCurrencySettings<T extends Object>(
    Expression<T> Function($$UserSettingsRecordsTableAnnotationComposer a) f,
  ) {
    final $$UserSettingsRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.code,
          referencedTable: $db.userSettingsRecords,
          getReferencedColumn: (t) => t.lastTransactionCurrency,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserSettingsRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.userSettingsRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CurrenciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CurrenciesTable,
          Currency,
          $$CurrenciesTableFilterComposer,
          $$CurrenciesTableOrderingComposer,
          $$CurrenciesTableAnnotationComposer,
          $$CurrenciesTableCreateCompanionBuilder,
          $$CurrenciesTableUpdateCompanionBuilder,
          (Currency, $$CurrenciesTableReferences),
          Currency,
          PrefetchHooks Function({
            bool baseCurrencyRateSnapshots,
            bool quoteCurrencyRateSnapshots,
            bool paymentMethodsRefs,
            bool tripsRefs,
            bool transactionCurrencyExpenses,
            bool homeCurrencyExpenses,
            bool userSettingsRecordsRefs,
            bool lastTransactionCurrencySettings,
          })
        > {
  $$CurrenciesTableTableManager(_$AppDatabase db, $CurrenciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String?> numericCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<int> minorUnits = const Value.absent(),
                Value<String> countryCodesJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion(
                code: code,
                numericCode: numericCode,
                name: name,
                symbol: symbol,
                minorUnits: minorUnits,
                countryCodesJson: countryCodesJson,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                Value<String?> numericCode = const Value.absent(),
                required String name,
                required String symbol,
                required int minorUnits,
                Value<String> countryCodesJson = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion.insert(
                code: code,
                numericCode: numericCode,
                name: name,
                symbol: symbol,
                minorUnits: minorUnits,
                countryCodesJson: countryCodesJson,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CurrenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                baseCurrencyRateSnapshots = false,
                quoteCurrencyRateSnapshots = false,
                paymentMethodsRefs = false,
                tripsRefs = false,
                transactionCurrencyExpenses = false,
                homeCurrencyExpenses = false,
                userSettingsRecordsRefs = false,
                lastTransactionCurrencySettings = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (baseCurrencyRateSnapshots) db.rateSnapshots,
                    if (quoteCurrencyRateSnapshots) db.rateSnapshots,
                    if (paymentMethodsRefs) db.paymentMethods,
                    if (tripsRefs) db.trips,
                    if (transactionCurrencyExpenses) db.expenses,
                    if (homeCurrencyExpenses) db.expenses,
                    if (userSettingsRecordsRefs) db.userSettingsRecords,
                    if (lastTransactionCurrencySettings) db.userSettingsRecords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (baseCurrencyRateSnapshots)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          RateSnapshot
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._baseCurrencyRateSnapshotsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).baseCurrencyRateSnapshots,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.baseCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (quoteCurrencyRateSnapshots)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          RateSnapshot
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._quoteCurrencyRateSnapshotsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).quoteCurrencyRateSnapshots,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.quoteCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (paymentMethodsRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          PaymentMethod
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._paymentMethodsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentMethodsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.billingCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (tripsRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          Trip
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._tripsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).tripsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.homeCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (transactionCurrencyExpenses)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._transactionCurrencyExpensesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionCurrencyExpenses,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (homeCurrencyExpenses)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._homeCurrencyExpensesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).homeCurrencyExpenses,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.homeCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (userSettingsRecordsRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          UserSettingsRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._userSettingsRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).userSettingsRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.defaultCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (lastTransactionCurrencySettings)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          UserSettingsRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._lastTransactionCurrencySettingsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).lastTransactionCurrencySettings,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lastTransactionCurrency == item.code,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CurrenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CurrenciesTable,
      Currency,
      $$CurrenciesTableFilterComposer,
      $$CurrenciesTableOrderingComposer,
      $$CurrenciesTableAnnotationComposer,
      $$CurrenciesTableCreateCompanionBuilder,
      $$CurrenciesTableUpdateCompanionBuilder,
      (Currency, $$CurrenciesTableReferences),
      Currency,
      PrefetchHooks Function({
        bool baseCurrencyRateSnapshots,
        bool quoteCurrencyRateSnapshots,
        bool paymentMethodsRefs,
        bool tripsRefs,
        bool transactionCurrencyExpenses,
        bool homeCurrencyExpenses,
        bool userSettingsRecordsRefs,
        bool lastTransactionCurrencySettings,
      })
    >;
typedef $$RateSnapshotsTableCreateCompanionBuilder =
    RateSnapshotsCompanion Function({
      required String id,
      Value<int> syncVersion,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String baseCurrency,
      required String quoteCurrency,
      required String rate,
      required String sourceType,
      required String sourceName,
      required DateTime sourceTimestamp,
      required DateTime fetchedAt,
      Value<bool> isCached,
      Value<int> rowid,
    });
typedef $$RateSnapshotsTableUpdateCompanionBuilder =
    RateSnapshotsCompanion Function({
      Value<String> id,
      Value<int> syncVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> baseCurrency,
      Value<String> quoteCurrency,
      Value<String> rate,
      Value<String> sourceType,
      Value<String> sourceName,
      Value<DateTime> sourceTimestamp,
      Value<DateTime> fetchedAt,
      Value<bool> isCached,
      Value<int> rowid,
    });

final class $$RateSnapshotsTableReferences
    extends BaseReferences<_$AppDatabase, $RateSnapshotsTable, RateSnapshot> {
  $$RateSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CurrenciesTable _baseCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.rateSnapshots.baseCurrency, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get baseCurrency {
    final $_column = $_itemColumn<String>('base_currency')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseCurrencyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _quoteCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.rateSnapshots.quoteCurrency,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get quoteCurrency {
    final $_column = $_itemColumn<String>('quote_currency')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_quoteCurrencyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(
      db.rateSnapshots.id,
      db.expenses.rateSnapshotId,
    ),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.rateSnapshotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RateSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $RateSnapshotsTable> {
  $$RateSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceTimestamp => $composableBuilder(
    column: $table.sourceTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCached => $composableBuilder(
    column: $table.isCached,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get baseCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get quoteCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quoteCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.rateSnapshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RateSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $RateSnapshotsTable> {
  $$RateSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceTimestamp => $composableBuilder(
    column: $table.sourceTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCached => $composableBuilder(
    column: $table.isCached,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get baseCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get quoteCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quoteCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RateSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RateSnapshotsTable> {
  $$RateSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceTimestamp => $composableBuilder(
    column: $table.sourceTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<bool> get isCached =>
      $composableBuilder(column: $table.isCached, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get baseCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get quoteCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.quoteCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.rateSnapshotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RateSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RateSnapshotsTable,
          RateSnapshot,
          $$RateSnapshotsTableFilterComposer,
          $$RateSnapshotsTableOrderingComposer,
          $$RateSnapshotsTableAnnotationComposer,
          $$RateSnapshotsTableCreateCompanionBuilder,
          $$RateSnapshotsTableUpdateCompanionBuilder,
          (RateSnapshot, $$RateSnapshotsTableReferences),
          RateSnapshot,
          PrefetchHooks Function({
            bool baseCurrency,
            bool quoteCurrency,
            bool expensesRefs,
          })
        > {
  $$RateSnapshotsTableTableManager(_$AppDatabase db, $RateSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RateSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RateSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RateSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> quoteCurrency = const Value.absent(),
                Value<String> rate = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<DateTime> sourceTimestamp = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<bool> isCached = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RateSnapshotsCompanion(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                baseCurrency: baseCurrency,
                quoteCurrency: quoteCurrency,
                rate: rate,
                sourceType: sourceType,
                sourceName: sourceName,
                sourceTimestamp: sourceTimestamp,
                fetchedAt: fetchedAt,
                isCached: isCached,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> syncVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String baseCurrency,
                required String quoteCurrency,
                required String rate,
                required String sourceType,
                required String sourceName,
                required DateTime sourceTimestamp,
                required DateTime fetchedAt,
                Value<bool> isCached = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RateSnapshotsCompanion.insert(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                baseCurrency: baseCurrency,
                quoteCurrency: quoteCurrency,
                rate: rate,
                sourceType: sourceType,
                sourceName: sourceName,
                sourceTimestamp: sourceTimestamp,
                fetchedAt: fetchedAt,
                isCached: isCached,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RateSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                baseCurrency = false,
                quoteCurrency = false,
                expensesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (expensesRefs) db.expenses],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (baseCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.baseCurrency,
                                    referencedTable:
                                        $$RateSnapshotsTableReferences
                                            ._baseCurrencyTable(db),
                                    referencedColumn:
                                        $$RateSnapshotsTableReferences
                                            ._baseCurrencyTable(db)
                                            .code,
                                  )
                                  as T;
                        }
                        if (quoteCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.quoteCurrency,
                                    referencedTable:
                                        $$RateSnapshotsTableReferences
                                            ._quoteCurrencyTable(db),
                                    referencedColumn:
                                        $$RateSnapshotsTableReferences
                                            ._quoteCurrencyTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          RateSnapshot,
                          $RateSnapshotsTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$RateSnapshotsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RateSnapshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rateSnapshotId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RateSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RateSnapshotsTable,
      RateSnapshot,
      $$RateSnapshotsTableFilterComposer,
      $$RateSnapshotsTableOrderingComposer,
      $$RateSnapshotsTableAnnotationComposer,
      $$RateSnapshotsTableCreateCompanionBuilder,
      $$RateSnapshotsTableUpdateCompanionBuilder,
      (RateSnapshot, $$RateSnapshotsTableReferences),
      RateSnapshot,
      PrefetchHooks Function({
        bool baseCurrency,
        bool quoteCurrency,
        bool expensesRefs,
      })
    >;
typedef $$PaymentMethodsTableCreateCompanionBuilder =
    PaymentMethodsCompanion Function({
      required String id,
      Value<int> syncVersion,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String name,
      required String type,
      required String network,
      required String billingCurrency,
      required String foreignFeePercent,
      required String crossBorderFeePercent,
      required String rateMarkupPercent,
      required String fixedFee,
      required String cashbackPercent,
      Value<String?> minimumFee,
      Value<String?> maximumFee,
      Value<String?> cashExchangeRate,
      required String supportedTxnTypesJson,
      Value<String?> sourceUrl,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> lastVerifiedAt,
      Value<String?> notes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PaymentMethodsTableUpdateCompanionBuilder =
    PaymentMethodsCompanion Function({
      Value<String> id,
      Value<int> syncVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<String> type,
      Value<String> network,
      Value<String> billingCurrency,
      Value<String> foreignFeePercent,
      Value<String> crossBorderFeePercent,
      Value<String> rateMarkupPercent,
      Value<String> fixedFee,
      Value<String> cashbackPercent,
      Value<String?> minimumFee,
      Value<String?> maximumFee,
      Value<String?> cashExchangeRate,
      Value<String> supportedTxnTypesJson,
      Value<String?> sourceUrl,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> lastVerifiedAt,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PaymentMethodsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentMethodsTable, PaymentMethod> {
  $$PaymentMethodsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CurrenciesTable _billingCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.paymentMethods.billingCurrency,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get billingCurrency {
    final $_column = $_itemColumn<String>('billing_currency')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billingCurrencyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TripsTable, List<Trip>> _tripsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.trips,
    aliasName: $_aliasNameGenerator(
      db.paymentMethods.id,
      db.trips.defaultPaymentMethodId,
    ),
  );

  $$TripsTableProcessedTableManager get tripsRefs {
    final manager = $$TripsTableTableManager($_db, $_db.trips).filter(
      (f) => f.defaultPaymentMethodId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_tripsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(
      db.paymentMethods.id,
      db.expenses.paymentMethodId,
    ),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) => f.paymentMethodId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FeeCalibrationsTable, List<FeeCalibration>>
  _feeCalibrationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.feeCalibrations,
    aliasName: $_aliasNameGenerator(
      db.paymentMethods.id,
      db.feeCalibrations.paymentMethodId,
    ),
  );

  $$FeeCalibrationsTableProcessedTableManager get feeCalibrationsRefs {
    final manager =
        $$FeeCalibrationsTableTableManager($_db, $_db.feeCalibrations).filter(
          (f) => f.paymentMethodId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _feeCalibrationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PaymentMethodsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get network => $composableBuilder(
    column: $table.network,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foreignFeePercent => $composableBuilder(
    column: $table.foreignFeePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crossBorderFeePercent => $composableBuilder(
    column: $table.crossBorderFeePercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rateMarkupPercent => $composableBuilder(
    column: $table.rateMarkupPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedFee => $composableBuilder(
    column: $table.fixedFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashbackPercent => $composableBuilder(
    column: $table.cashbackPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get minimumFee => $composableBuilder(
    column: $table.minimumFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maximumFee => $composableBuilder(
    column: $table.maximumFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashExchangeRate => $composableBuilder(
    column: $table.cashExchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportedTxnTypesJson => $composableBuilder(
    column: $table.supportedTxnTypesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get billingCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billingCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tripsRefs(
    Expression<bool> Function($$TripsTableFilterComposer f) f,
  ) {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.defaultPaymentMethodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.paymentMethodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> feeCalibrationsRefs(
    Expression<bool> Function($$FeeCalibrationsTableFilterComposer f) f,
  ) {
    final $$FeeCalibrationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feeCalibrations,
      getReferencedColumn: (t) => t.paymentMethodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeeCalibrationsTableFilterComposer(
            $db: $db,
            $table: $db.feeCalibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PaymentMethodsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get network => $composableBuilder(
    column: $table.network,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foreignFeePercent => $composableBuilder(
    column: $table.foreignFeePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crossBorderFeePercent => $composableBuilder(
    column: $table.crossBorderFeePercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateMarkupPercent => $composableBuilder(
    column: $table.rateMarkupPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedFee => $composableBuilder(
    column: $table.fixedFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashbackPercent => $composableBuilder(
    column: $table.cashbackPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get minimumFee => $composableBuilder(
    column: $table.minimumFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maximumFee => $composableBuilder(
    column: $table.maximumFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashExchangeRate => $composableBuilder(
    column: $table.cashExchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportedTxnTypesJson => $composableBuilder(
    column: $table.supportedTxnTypesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get billingCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billingCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentMethodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get network =>
      $composableBuilder(column: $table.network, builder: (column) => column);

  GeneratedColumn<String> get foreignFeePercent => $composableBuilder(
    column: $table.foreignFeePercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get crossBorderFeePercent => $composableBuilder(
    column: $table.crossBorderFeePercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rateMarkupPercent => $composableBuilder(
    column: $table.rateMarkupPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedFee =>
      $composableBuilder(column: $table.fixedFee, builder: (column) => column);

  GeneratedColumn<String> get cashbackPercent => $composableBuilder(
    column: $table.cashbackPercent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get minimumFee => $composableBuilder(
    column: $table.minimumFee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get maximumFee => $composableBuilder(
    column: $table.maximumFee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cashExchangeRate => $composableBuilder(
    column: $table.cashExchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supportedTxnTypesJson => $composableBuilder(
    column: $table.supportedTxnTypesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get billingCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billingCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tripsRefs<T extends Object>(
    Expression<T> Function($$TripsTableAnnotationComposer a) f,
  ) {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.defaultPaymentMethodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.paymentMethodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> feeCalibrationsRefs<T extends Object>(
    Expression<T> Function($$FeeCalibrationsTableAnnotationComposer a) f,
  ) {
    final $$FeeCalibrationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feeCalibrations,
      getReferencedColumn: (t) => t.paymentMethodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeeCalibrationsTableAnnotationComposer(
            $db: $db,
            $table: $db.feeCalibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PaymentMethodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentMethodsTable,
          PaymentMethod,
          $$PaymentMethodsTableFilterComposer,
          $$PaymentMethodsTableOrderingComposer,
          $$PaymentMethodsTableAnnotationComposer,
          $$PaymentMethodsTableCreateCompanionBuilder,
          $$PaymentMethodsTableUpdateCompanionBuilder,
          (PaymentMethod, $$PaymentMethodsTableReferences),
          PaymentMethod,
          PrefetchHooks Function({
            bool billingCurrency,
            bool tripsRefs,
            bool expensesRefs,
            bool feeCalibrationsRefs,
          })
        > {
  $$PaymentMethodsTableTableManager(
    _$AppDatabase db,
    $PaymentMethodsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentMethodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentMethodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> network = const Value.absent(),
                Value<String> billingCurrency = const Value.absent(),
                Value<String> foreignFeePercent = const Value.absent(),
                Value<String> crossBorderFeePercent = const Value.absent(),
                Value<String> rateMarkupPercent = const Value.absent(),
                Value<String> fixedFee = const Value.absent(),
                Value<String> cashbackPercent = const Value.absent(),
                Value<String?> minimumFee = const Value.absent(),
                Value<String?> maximumFee = const Value.absent(),
                Value<String?> cashExchangeRate = const Value.absent(),
                Value<String> supportedTxnTypesJson = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsCompanion(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                type: type,
                network: network,
                billingCurrency: billingCurrency,
                foreignFeePercent: foreignFeePercent,
                crossBorderFeePercent: crossBorderFeePercent,
                rateMarkupPercent: rateMarkupPercent,
                fixedFee: fixedFee,
                cashbackPercent: cashbackPercent,
                minimumFee: minimumFee,
                maximumFee: maximumFee,
                cashExchangeRate: cashExchangeRate,
                supportedTxnTypesJson: supportedTxnTypesJson,
                sourceUrl: sourceUrl,
                effectiveFrom: effectiveFrom,
                lastVerifiedAt: lastVerifiedAt,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> syncVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required String type,
                required String network,
                required String billingCurrency,
                required String foreignFeePercent,
                required String crossBorderFeePercent,
                required String rateMarkupPercent,
                required String fixedFee,
                required String cashbackPercent,
                Value<String?> minimumFee = const Value.absent(),
                Value<String?> maximumFee = const Value.absent(),
                Value<String?> cashExchangeRate = const Value.absent(),
                required String supportedTxnTypesJson,
                Value<String?> sourceUrl = const Value.absent(),
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PaymentMethodsCompanion.insert(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                type: type,
                network: network,
                billingCurrency: billingCurrency,
                foreignFeePercent: foreignFeePercent,
                crossBorderFeePercent: crossBorderFeePercent,
                rateMarkupPercent: rateMarkupPercent,
                fixedFee: fixedFee,
                cashbackPercent: cashbackPercent,
                minimumFee: minimumFee,
                maximumFee: maximumFee,
                cashExchangeRate: cashExchangeRate,
                supportedTxnTypesJson: supportedTxnTypesJson,
                sourceUrl: sourceUrl,
                effectiveFrom: effectiveFrom,
                lastVerifiedAt: lastVerifiedAt,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentMethodsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                billingCurrency = false,
                tripsRefs = false,
                expensesRefs = false,
                feeCalibrationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tripsRefs) db.trips,
                    if (expensesRefs) db.expenses,
                    if (feeCalibrationsRefs) db.feeCalibrations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (billingCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.billingCurrency,
                                    referencedTable:
                                        $$PaymentMethodsTableReferences
                                            ._billingCurrencyTable(db),
                                    referencedColumn:
                                        $$PaymentMethodsTableReferences
                                            ._billingCurrencyTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tripsRefs)
                        await $_getPrefetchedData<
                          PaymentMethod,
                          $PaymentMethodsTable,
                          Trip
                        >(
                          currentTable: table,
                          referencedTable: $$PaymentMethodsTableReferences
                              ._tripsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PaymentMethodsTableReferences(
                                db,
                                table,
                                p0,
                              ).tripsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.defaultPaymentMethodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          PaymentMethod,
                          $PaymentMethodsTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$PaymentMethodsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PaymentMethodsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.paymentMethodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (feeCalibrationsRefs)
                        await $_getPrefetchedData<
                          PaymentMethod,
                          $PaymentMethodsTable,
                          FeeCalibration
                        >(
                          currentTable: table,
                          referencedTable: $$PaymentMethodsTableReferences
                              ._feeCalibrationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PaymentMethodsTableReferences(
                                db,
                                table,
                                p0,
                              ).feeCalibrationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.paymentMethodId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PaymentMethodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentMethodsTable,
      PaymentMethod,
      $$PaymentMethodsTableFilterComposer,
      $$PaymentMethodsTableOrderingComposer,
      $$PaymentMethodsTableAnnotationComposer,
      $$PaymentMethodsTableCreateCompanionBuilder,
      $$PaymentMethodsTableUpdateCompanionBuilder,
      (PaymentMethod, $$PaymentMethodsTableReferences),
      PaymentMethod,
      PrefetchHooks Function({
        bool billingCurrency,
        bool tripsRefs,
        bool expensesRefs,
        bool feeCalibrationsRefs,
      })
    >;
typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      required String id,
      Value<int> syncVersion,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String name,
      required String destinationCodesJson,
      required DateTime startDate,
      required DateTime endDate,
      required String homeCurrency,
      required String localCurrenciesJson,
      Value<String?> totalBudget,
      Value<int> participantCount,
      Value<String?> defaultPaymentMethodId,
      Value<DateTime?> offlinePackUpdatedAt,
      required String status,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<String> id,
      Value<int> syncVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<String> destinationCodesJson,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<String> homeCurrency,
      Value<String> localCurrenciesJson,
      Value<String?> totalBudget,
      Value<int> participantCount,
      Value<String?> defaultPaymentMethodId,
      Value<DateTime?> offlinePackUpdatedAt,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, Trip> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _homeCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.trips.homeCurrency, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get homeCurrency {
    final $_column = $_itemColumn<String>('home_currency')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_homeCurrencyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PaymentMethodsTable _defaultPaymentMethodIdTable(_$AppDatabase db) =>
      db.paymentMethods.createAlias(
        $_aliasNameGenerator(
          db.trips.defaultPaymentMethodId,
          db.paymentMethods.id,
        ),
      );

  $$PaymentMethodsTableProcessedTableManager? get defaultPaymentMethodId {
    final $_column = $_itemColumn<String>('default_payment_method_id');
    if ($_column == null) return null;
    final manager = $$PaymentMethodsTableTableManager(
      $_db,
      $_db.paymentMethods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _defaultPaymentMethodIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(db.trips.id, db.expenses.tripId),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationCodesJson => $composableBuilder(
    column: $table.destinationCodesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCurrenciesJson => $composableBuilder(
    column: $table.localCurrenciesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get totalBudget => $composableBuilder(
    column: $table.totalBudget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get participantCount => $composableBuilder(
    column: $table.participantCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get offlinePackUpdatedAt => $composableBuilder(
    column: $table.offlinePackUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get homeCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentMethodsTableFilterComposer get defaultPaymentMethodId {
    final $$PaymentMethodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultPaymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableFilterComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationCodesJson => $composableBuilder(
    column: $table.destinationCodesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCurrenciesJson => $composableBuilder(
    column: $table.localCurrenciesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalBudget => $composableBuilder(
    column: $table.totalBudget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get participantCount => $composableBuilder(
    column: $table.participantCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get offlinePackUpdatedAt => $composableBuilder(
    column: $table.offlinePackUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get homeCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentMethodsTableOrderingComposer get defaultPaymentMethodId {
    final $$PaymentMethodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultPaymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableOrderingComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get destinationCodesJson => $composableBuilder(
    column: $table.destinationCodesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get localCurrenciesJson => $composableBuilder(
    column: $table.localCurrenciesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get totalBudget => $composableBuilder(
    column: $table.totalBudget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get participantCount => $composableBuilder(
    column: $table.participantCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get offlinePackUpdatedAt => $composableBuilder(
    column: $table.offlinePackUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get homeCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentMethodsTableAnnotationComposer get defaultPaymentMethodId {
    final $$PaymentMethodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultPaymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, $$TripsTableReferences),
          Trip,
          PrefetchHooks Function({
            bool homeCurrency,
            bool defaultPaymentMethodId,
            bool expensesRefs,
          })
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> destinationCodesJson = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<String> homeCurrency = const Value.absent(),
                Value<String> localCurrenciesJson = const Value.absent(),
                Value<String?> totalBudget = const Value.absent(),
                Value<int> participantCount = const Value.absent(),
                Value<String?> defaultPaymentMethodId = const Value.absent(),
                Value<DateTime?> offlinePackUpdatedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                destinationCodesJson: destinationCodesJson,
                startDate: startDate,
                endDate: endDate,
                homeCurrency: homeCurrency,
                localCurrenciesJson: localCurrenciesJson,
                totalBudget: totalBudget,
                participantCount: participantCount,
                defaultPaymentMethodId: defaultPaymentMethodId,
                offlinePackUpdatedAt: offlinePackUpdatedAt,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> syncVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required String destinationCodesJson,
                required DateTime startDate,
                required DateTime endDate,
                required String homeCurrency,
                required String localCurrenciesJson,
                Value<String?> totalBudget = const Value.absent(),
                Value<int> participantCount = const Value.absent(),
                Value<String?> defaultPaymentMethodId = const Value.absent(),
                Value<DateTime?> offlinePackUpdatedAt = const Value.absent(),
                required String status,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                destinationCodesJson: destinationCodesJson,
                startDate: startDate,
                endDate: endDate,
                homeCurrency: homeCurrency,
                localCurrenciesJson: localCurrenciesJson,
                totalBudget: totalBudget,
                participantCount: participantCount,
                defaultPaymentMethodId: defaultPaymentMethodId,
                offlinePackUpdatedAt: offlinePackUpdatedAt,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TripsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                homeCurrency = false,
                defaultPaymentMethodId = false,
                expensesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (expensesRefs) db.expenses],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (homeCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.homeCurrency,
                                    referencedTable: $$TripsTableReferences
                                        ._homeCurrencyTable(db),
                                    referencedColumn: $$TripsTableReferences
                                        ._homeCurrencyTable(db)
                                        .code,
                                  )
                                  as T;
                        }
                        if (defaultPaymentMethodId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.defaultPaymentMethodId,
                                    referencedTable: $$TripsTableReferences
                                        ._defaultPaymentMethodIdTable(db),
                                    referencedColumn: $$TripsTableReferences
                                        ._defaultPaymentMethodIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensesRefs)
                        await $_getPrefetchedData<Trip, $TripsTable, Expense>(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, $$TripsTableReferences),
      Trip,
      PrefetchHooks Function({
        bool homeCurrency,
        bool defaultPaymentMethodId,
        bool expensesRefs,
      })
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      Value<int> syncVersion,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> tripId,
      required String title,
      required String category,
      required String transactionAmount,
      required String transactionCurrency,
      required String referenceAmount,
      required String homeCurrency,
      required String estimatedFinalAmount,
      Value<String?> actualFinalAmount,
      Value<String?> paymentMethodId,
      required String paymentRuleSnapshotJson,
      Value<String?> rateSnapshotId,
      required String rateSnapshotJson,
      required String taxAmount,
      required String tipAmount,
      required String discountAmount,
      Value<int> participantCount,
      required DateTime occurredAt,
      Value<String?> receiptLocalPath,
      Value<String?> notes,
      Value<bool> budgetIncluded,
      required String status,
      Value<String> entryType,
      Value<String?> relatedExpenseId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<int> syncVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> tripId,
      Value<String> title,
      Value<String> category,
      Value<String> transactionAmount,
      Value<String> transactionCurrency,
      Value<String> referenceAmount,
      Value<String> homeCurrency,
      Value<String> estimatedFinalAmount,
      Value<String?> actualFinalAmount,
      Value<String?> paymentMethodId,
      Value<String> paymentRuleSnapshotJson,
      Value<String?> rateSnapshotId,
      Value<String> rateSnapshotJson,
      Value<String> taxAmount,
      Value<String> tipAmount,
      Value<String> discountAmount,
      Value<int> participantCount,
      Value<DateTime> occurredAt,
      Value<String?> receiptLocalPath,
      Value<String?> notes,
      Value<bool> budgetIncluded,
      Value<String> status,
      Value<String> entryType,
      Value<String?> relatedExpenseId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips.createAlias(
    $_aliasNameGenerator(db.expenses.tripId, db.trips.id),
  );

  $$TripsTableProcessedTableManager? get tripId {
    final $_column = $_itemColumn<String>('trip_id');
    if ($_column == null) return null;
    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _transactionCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.expenses.transactionCurrency,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get transactionCurrency {
    final $_column = $_itemColumn<String>('transaction_currency')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionCurrencyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _homeCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.expenses.homeCurrency, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get homeCurrency {
    final $_column = $_itemColumn<String>('home_currency')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_homeCurrencyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PaymentMethodsTable _paymentMethodIdTable(_$AppDatabase db) =>
      db.paymentMethods.createAlias(
        $_aliasNameGenerator(db.expenses.paymentMethodId, db.paymentMethods.id),
      );

  $$PaymentMethodsTableProcessedTableManager? get paymentMethodId {
    final $_column = $_itemColumn<String>('payment_method_id');
    if ($_column == null) return null;
    final manager = $$PaymentMethodsTableTableManager(
      $_db,
      $_db.paymentMethods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_paymentMethodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RateSnapshotsTable _rateSnapshotIdTable(_$AppDatabase db) =>
      db.rateSnapshots.createAlias(
        $_aliasNameGenerator(db.expenses.rateSnapshotId, db.rateSnapshots.id),
      );

  $$RateSnapshotsTableProcessedTableManager? get rateSnapshotId {
    final $_column = $_itemColumn<String>('rate_snapshot_id');
    if ($_column == null) return null;
    final manager = $$RateSnapshotsTableTableManager(
      $_db,
      $_db.rateSnapshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rateSnapshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FeeCalibrationsTable, List<FeeCalibration>>
  _feeCalibrationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.feeCalibrations,
    aliasName: $_aliasNameGenerator(
      db.expenses.id,
      db.feeCalibrations.expenseId,
    ),
  );

  $$FeeCalibrationsTableProcessedTableManager get feeCalibrationsRefs {
    final manager = $$FeeCalibrationsTableTableManager(
      $_db,
      $_db.feeCalibrations,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _feeCalibrationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionAmount => $composableBuilder(
    column: $table.transactionAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceAmount => $composableBuilder(
    column: $table.referenceAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estimatedFinalAmount => $composableBuilder(
    column: $table.estimatedFinalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualFinalAmount => $composableBuilder(
    column: $table.actualFinalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentRuleSnapshotJson => $composableBuilder(
    column: $table.paymentRuleSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rateSnapshotJson => $composableBuilder(
    column: $table.rateSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipAmount => $composableBuilder(
    column: $table.tipAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get participantCount => $composableBuilder(
    column: $table.participantCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptLocalPath => $composableBuilder(
    column: $table.receiptLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get budgetIncluded => $composableBuilder(
    column: $table.budgetIncluded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedExpenseId => $composableBuilder(
    column: $table.relatedExpenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get transactionCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get homeCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentMethodsTableFilterComposer get paymentMethodId {
    final $$PaymentMethodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableFilterComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RateSnapshotsTableFilterComposer get rateSnapshotId {
    final $$RateSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rateSnapshotId,
      referencedTable: $db.rateSnapshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.rateSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> feeCalibrationsRefs(
    Expression<bool> Function($$FeeCalibrationsTableFilterComposer f) f,
  ) {
    final $$FeeCalibrationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feeCalibrations,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeeCalibrationsTableFilterComposer(
            $db: $db,
            $table: $db.feeCalibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionAmount => $composableBuilder(
    column: $table.transactionAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceAmount => $composableBuilder(
    column: $table.referenceAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estimatedFinalAmount => $composableBuilder(
    column: $table.estimatedFinalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualFinalAmount => $composableBuilder(
    column: $table.actualFinalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentRuleSnapshotJson => $composableBuilder(
    column: $table.paymentRuleSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rateSnapshotJson => $composableBuilder(
    column: $table.rateSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipAmount => $composableBuilder(
    column: $table.tipAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get participantCount => $composableBuilder(
    column: $table.participantCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptLocalPath => $composableBuilder(
    column: $table.receiptLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get budgetIncluded => $composableBuilder(
    column: $table.budgetIncluded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedExpenseId => $composableBuilder(
    column: $table.relatedExpenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get transactionCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get homeCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentMethodsTableOrderingComposer get paymentMethodId {
    final $$PaymentMethodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableOrderingComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RateSnapshotsTableOrderingComposer get rateSnapshotId {
    final $$RateSnapshotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rateSnapshotId,
      referencedTable: $db.rateSnapshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateSnapshotsTableOrderingComposer(
            $db: $db,
            $table: $db.rateSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get transactionAmount => $composableBuilder(
    column: $table.transactionAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceAmount => $composableBuilder(
    column: $table.referenceAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estimatedFinalAmount => $composableBuilder(
    column: $table.estimatedFinalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actualFinalAmount => $composableBuilder(
    column: $table.actualFinalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentRuleSnapshotJson => $composableBuilder(
    column: $table.paymentRuleSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rateSnapshotJson => $composableBuilder(
    column: $table.rateSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<String> get tipAmount =>
      $composableBuilder(column: $table.tipAmount, builder: (column) => column);

  GeneratedColumn<String> get discountAmount => $composableBuilder(
    column: $table.discountAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get participantCount => $composableBuilder(
    column: $table.participantCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptLocalPath => $composableBuilder(
    column: $table.receiptLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get budgetIncluded => $composableBuilder(
    column: $table.budgetIncluded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<String> get relatedExpenseId => $composableBuilder(
    column: $table.relatedExpenseId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get transactionCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get homeCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PaymentMethodsTableAnnotationComposer get paymentMethodId {
    final $$PaymentMethodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RateSnapshotsTableAnnotationComposer get rateSnapshotId {
    final $$RateSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rateSnapshotId,
      referencedTable: $db.rateSnapshots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.rateSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> feeCalibrationsRefs<T extends Object>(
    Expression<T> Function($$FeeCalibrationsTableAnnotationComposer a) f,
  ) {
    final $$FeeCalibrationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feeCalibrations,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeeCalibrationsTableAnnotationComposer(
            $db: $db,
            $table: $db.feeCalibrations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({
            bool tripId,
            bool transactionCurrency,
            bool homeCurrency,
            bool paymentMethodId,
            bool rateSnapshotId,
            bool feeCalibrationsRefs,
          })
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> transactionAmount = const Value.absent(),
                Value<String> transactionCurrency = const Value.absent(),
                Value<String> referenceAmount = const Value.absent(),
                Value<String> homeCurrency = const Value.absent(),
                Value<String> estimatedFinalAmount = const Value.absent(),
                Value<String?> actualFinalAmount = const Value.absent(),
                Value<String?> paymentMethodId = const Value.absent(),
                Value<String> paymentRuleSnapshotJson = const Value.absent(),
                Value<String?> rateSnapshotId = const Value.absent(),
                Value<String> rateSnapshotJson = const Value.absent(),
                Value<String> taxAmount = const Value.absent(),
                Value<String> tipAmount = const Value.absent(),
                Value<String> discountAmount = const Value.absent(),
                Value<int> participantCount = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> receiptLocalPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> budgetIncluded = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> entryType = const Value.absent(),
                Value<String?> relatedExpenseId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                tripId: tripId,
                title: title,
                category: category,
                transactionAmount: transactionAmount,
                transactionCurrency: transactionCurrency,
                referenceAmount: referenceAmount,
                homeCurrency: homeCurrency,
                estimatedFinalAmount: estimatedFinalAmount,
                actualFinalAmount: actualFinalAmount,
                paymentMethodId: paymentMethodId,
                paymentRuleSnapshotJson: paymentRuleSnapshotJson,
                rateSnapshotId: rateSnapshotId,
                rateSnapshotJson: rateSnapshotJson,
                taxAmount: taxAmount,
                tipAmount: tipAmount,
                discountAmount: discountAmount,
                participantCount: participantCount,
                occurredAt: occurredAt,
                receiptLocalPath: receiptLocalPath,
                notes: notes,
                budgetIncluded: budgetIncluded,
                status: status,
                entryType: entryType,
                relatedExpenseId: relatedExpenseId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> syncVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                required String title,
                required String category,
                required String transactionAmount,
                required String transactionCurrency,
                required String referenceAmount,
                required String homeCurrency,
                required String estimatedFinalAmount,
                Value<String?> actualFinalAmount = const Value.absent(),
                Value<String?> paymentMethodId = const Value.absent(),
                required String paymentRuleSnapshotJson,
                Value<String?> rateSnapshotId = const Value.absent(),
                required String rateSnapshotJson,
                required String taxAmount,
                required String tipAmount,
                required String discountAmount,
                Value<int> participantCount = const Value.absent(),
                required DateTime occurredAt,
                Value<String?> receiptLocalPath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> budgetIncluded = const Value.absent(),
                required String status,
                Value<String> entryType = const Value.absent(),
                Value<String?> relatedExpenseId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                tripId: tripId,
                title: title,
                category: category,
                transactionAmount: transactionAmount,
                transactionCurrency: transactionCurrency,
                referenceAmount: referenceAmount,
                homeCurrency: homeCurrency,
                estimatedFinalAmount: estimatedFinalAmount,
                actualFinalAmount: actualFinalAmount,
                paymentMethodId: paymentMethodId,
                paymentRuleSnapshotJson: paymentRuleSnapshotJson,
                rateSnapshotId: rateSnapshotId,
                rateSnapshotJson: rateSnapshotJson,
                taxAmount: taxAmount,
                tipAmount: tipAmount,
                discountAmount: discountAmount,
                participantCount: participantCount,
                occurredAt: occurredAt,
                receiptLocalPath: receiptLocalPath,
                notes: notes,
                budgetIncluded: budgetIncluded,
                status: status,
                entryType: entryType,
                relatedExpenseId: relatedExpenseId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tripId = false,
                transactionCurrency = false,
                homeCurrency = false,
                paymentMethodId = false,
                rateSnapshotId = false,
                feeCalibrationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (feeCalibrationsRefs) db.feeCalibrations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tripId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.tripId,
                                    referencedTable: $$ExpensesTableReferences
                                        ._tripIdTable(db),
                                    referencedColumn: $$ExpensesTableReferences
                                        ._tripIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (transactionCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.transactionCurrency,
                                    referencedTable: $$ExpensesTableReferences
                                        ._transactionCurrencyTable(db),
                                    referencedColumn: $$ExpensesTableReferences
                                        ._transactionCurrencyTable(db)
                                        .code,
                                  )
                                  as T;
                        }
                        if (homeCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.homeCurrency,
                                    referencedTable: $$ExpensesTableReferences
                                        ._homeCurrencyTable(db),
                                    referencedColumn: $$ExpensesTableReferences
                                        ._homeCurrencyTable(db)
                                        .code,
                                  )
                                  as T;
                        }
                        if (paymentMethodId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.paymentMethodId,
                                    referencedTable: $$ExpensesTableReferences
                                        ._paymentMethodIdTable(db),
                                    referencedColumn: $$ExpensesTableReferences
                                        ._paymentMethodIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (rateSnapshotId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rateSnapshotId,
                                    referencedTable: $$ExpensesTableReferences
                                        ._rateSnapshotIdTable(db),
                                    referencedColumn: $$ExpensesTableReferences
                                        ._rateSnapshotIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (feeCalibrationsRefs)
                        await $_getPrefetchedData<
                          Expense,
                          $ExpensesTable,
                          FeeCalibration
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._feeCalibrationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).feeCalibrationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.expenseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({
        bool tripId,
        bool transactionCurrency,
        bool homeCurrency,
        bool paymentMethodId,
        bool rateSnapshotId,
        bool feeCalibrationsRefs,
      })
    >;
typedef $$FeeCalibrationsTableCreateCompanionBuilder =
    FeeCalibrationsCompanion Function({
      required String id,
      Value<int> syncVersion,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String paymentMethodId,
      required String expenseId,
      required String referenceAmount,
      required String actualFinalAmount,
      required String effectiveMarkupPercent,
      required DateTime calculatedAt,
      Value<int> rowid,
    });
typedef $$FeeCalibrationsTableUpdateCompanionBuilder =
    FeeCalibrationsCompanion Function({
      Value<String> id,
      Value<int> syncVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> paymentMethodId,
      Value<String> expenseId,
      Value<String> referenceAmount,
      Value<String> actualFinalAmount,
      Value<String> effectiveMarkupPercent,
      Value<DateTime> calculatedAt,
      Value<int> rowid,
    });

final class $$FeeCalibrationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $FeeCalibrationsTable, FeeCalibration> {
  $$FeeCalibrationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PaymentMethodsTable _paymentMethodIdTable(_$AppDatabase db) =>
      db.paymentMethods.createAlias(
        $_aliasNameGenerator(
          db.feeCalibrations.paymentMethodId,
          db.paymentMethods.id,
        ),
      );

  $$PaymentMethodsTableProcessedTableManager get paymentMethodId {
    final $_column = $_itemColumn<String>('payment_method_id')!;

    final manager = $$PaymentMethodsTableTableManager(
      $_db,
      $_db.paymentMethods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_paymentMethodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias(
        $_aliasNameGenerator(db.feeCalibrations.expenseId, db.expenses.id),
      );

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FeeCalibrationsTableFilterComposer
    extends Composer<_$AppDatabase, $FeeCalibrationsTable> {
  $$FeeCalibrationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceAmount => $composableBuilder(
    column: $table.referenceAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualFinalAmount => $composableBuilder(
    column: $table.actualFinalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveMarkupPercent => $composableBuilder(
    column: $table.effectiveMarkupPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get calculatedAt => $composableBuilder(
    column: $table.calculatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PaymentMethodsTableFilterComposer get paymentMethodId {
    final $$PaymentMethodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableFilterComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeeCalibrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $FeeCalibrationsTable> {
  $$FeeCalibrationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceAmount => $composableBuilder(
    column: $table.referenceAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualFinalAmount => $composableBuilder(
    column: $table.actualFinalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveMarkupPercent => $composableBuilder(
    column: $table.effectiveMarkupPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get calculatedAt => $composableBuilder(
    column: $table.calculatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PaymentMethodsTableOrderingComposer get paymentMethodId {
    final $$PaymentMethodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableOrderingComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeeCalibrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeeCalibrationsTable> {
  $$FeeCalibrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get referenceAmount => $composableBuilder(
    column: $table.referenceAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actualFinalAmount => $composableBuilder(
    column: $table.actualFinalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get effectiveMarkupPercent => $composableBuilder(
    column: $table.effectiveMarkupPercent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get calculatedAt => $composableBuilder(
    column: $table.calculatedAt,
    builder: (column) => column,
  );

  $$PaymentMethodsTableAnnotationComposer get paymentMethodId {
    final $$PaymentMethodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paymentMethodId,
      referencedTable: $db.paymentMethods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentMethodsTableAnnotationComposer(
            $db: $db,
            $table: $db.paymentMethods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeeCalibrationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeeCalibrationsTable,
          FeeCalibration,
          $$FeeCalibrationsTableFilterComposer,
          $$FeeCalibrationsTableOrderingComposer,
          $$FeeCalibrationsTableAnnotationComposer,
          $$FeeCalibrationsTableCreateCompanionBuilder,
          $$FeeCalibrationsTableUpdateCompanionBuilder,
          (FeeCalibration, $$FeeCalibrationsTableReferences),
          FeeCalibration,
          PrefetchHooks Function({bool paymentMethodId, bool expenseId})
        > {
  $$FeeCalibrationsTableTableManager(
    _$AppDatabase db,
    $FeeCalibrationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeeCalibrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeeCalibrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeeCalibrationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> paymentMethodId = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> referenceAmount = const Value.absent(),
                Value<String> actualFinalAmount = const Value.absent(),
                Value<String> effectiveMarkupPercent = const Value.absent(),
                Value<DateTime> calculatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeeCalibrationsCompanion(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                paymentMethodId: paymentMethodId,
                expenseId: expenseId,
                referenceAmount: referenceAmount,
                actualFinalAmount: actualFinalAmount,
                effectiveMarkupPercent: effectiveMarkupPercent,
                calculatedAt: calculatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> syncVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String paymentMethodId,
                required String expenseId,
                required String referenceAmount,
                required String actualFinalAmount,
                required String effectiveMarkupPercent,
                required DateTime calculatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FeeCalibrationsCompanion.insert(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                paymentMethodId: paymentMethodId,
                expenseId: expenseId,
                referenceAmount: referenceAmount,
                actualFinalAmount: actualFinalAmount,
                effectiveMarkupPercent: effectiveMarkupPercent,
                calculatedAt: calculatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FeeCalibrationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({paymentMethodId = false, expenseId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (paymentMethodId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.paymentMethodId,
                                    referencedTable:
                                        $$FeeCalibrationsTableReferences
                                            ._paymentMethodIdTable(db),
                                    referencedColumn:
                                        $$FeeCalibrationsTableReferences
                                            ._paymentMethodIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (expenseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.expenseId,
                                    referencedTable:
                                        $$FeeCalibrationsTableReferences
                                            ._expenseIdTable(db),
                                    referencedColumn:
                                        $$FeeCalibrationsTableReferences
                                            ._expenseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$FeeCalibrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeeCalibrationsTable,
      FeeCalibration,
      $$FeeCalibrationsTableFilterComposer,
      $$FeeCalibrationsTableOrderingComposer,
      $$FeeCalibrationsTableAnnotationComposer,
      $$FeeCalibrationsTableCreateCompanionBuilder,
      $$FeeCalibrationsTableUpdateCompanionBuilder,
      (FeeCalibration, $$FeeCalibrationsTableReferences),
      FeeCalibration,
      PrefetchHooks Function({bool paymentMethodId, bool expenseId})
    >;
typedef $$UserSettingsRecordsTableCreateCompanionBuilder =
    UserSettingsRecordsCompanion Function({
      required String id,
      Value<int> syncVersion,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      required String defaultCurrency,
      Value<String?> lastTransactionCurrency,
      required String favoriteCurrenciesJson,
      required String languageMode,
      required int refreshIntervalMinutes,
      Value<bool> wifiOnlyRefresh,
      Value<bool> syncEnabled,
      Value<int> rowid,
    });
typedef $$UserSettingsRecordsTableUpdateCompanionBuilder =
    UserSettingsRecordsCompanion Function({
      Value<String> id,
      Value<int> syncVersion,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> defaultCurrency,
      Value<String?> lastTransactionCurrency,
      Value<String> favoriteCurrenciesJson,
      Value<String> languageMode,
      Value<int> refreshIntervalMinutes,
      Value<bool> wifiOnlyRefresh,
      Value<bool> syncEnabled,
      Value<int> rowid,
    });

final class $$UserSettingsRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserSettingsRecordsTable,
          UserSettingsRecord
        > {
  $$UserSettingsRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CurrenciesTable _defaultCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.userSettingsRecords.defaultCurrency,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get defaultCurrency {
    final $_column = $_itemColumn<String>('default_currency')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultCurrencyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _lastTransactionCurrencyTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.userSettingsRecords.lastTransactionCurrency,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager? get lastTransactionCurrency {
    final $_column = $_itemColumn<String>('last_transaction_currency');
    if ($_column == null) return null;
    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastTransactionCurrencyTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserSettingsRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsRecordsTable> {
  $$UserSettingsRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get favoriteCurrenciesJson => $composableBuilder(
    column: $table.favoriteCurrenciesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageMode => $composableBuilder(
    column: $table.languageMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refreshIntervalMinutes => $composableBuilder(
    column: $table.refreshIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wifiOnlyRefresh => $composableBuilder(
    column: $table.wifiOnlyRefresh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get defaultCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get lastTransactionCurrency {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastTransactionCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserSettingsRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsRecordsTable> {
  $$UserSettingsRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get favoriteCurrenciesJson => $composableBuilder(
    column: $table.favoriteCurrenciesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageMode => $composableBuilder(
    column: $table.languageMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refreshIntervalMinutes => $composableBuilder(
    column: $table.refreshIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wifiOnlyRefresh => $composableBuilder(
    column: $table.wifiOnlyRefresh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get defaultCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get lastTransactionCurrency {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastTransactionCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserSettingsRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsRecordsTable> {
  $$UserSettingsRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get favoriteCurrenciesJson => $composableBuilder(
    column: $table.favoriteCurrenciesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get languageMode => $composableBuilder(
    column: $table.languageMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get refreshIntervalMinutes => $composableBuilder(
    column: $table.refreshIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wifiOnlyRefresh => $composableBuilder(
    column: $table.wifiOnlyRefresh,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => column,
  );

  $$CurrenciesTableAnnotationComposer get defaultCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get lastTransactionCurrency {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastTransactionCurrency,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserSettingsRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsRecordsTable,
          UserSettingsRecord,
          $$UserSettingsRecordsTableFilterComposer,
          $$UserSettingsRecordsTableOrderingComposer,
          $$UserSettingsRecordsTableAnnotationComposer,
          $$UserSettingsRecordsTableCreateCompanionBuilder,
          $$UserSettingsRecordsTableUpdateCompanionBuilder,
          (UserSettingsRecord, $$UserSettingsRecordsTableReferences),
          UserSettingsRecord,
          PrefetchHooks Function({
            bool defaultCurrency,
            bool lastTransactionCurrency,
          })
        > {
  $$UserSettingsRecordsTableTableManager(
    _$AppDatabase db,
    $UserSettingsRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserSettingsRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> defaultCurrency = const Value.absent(),
                Value<String?> lastTransactionCurrency = const Value.absent(),
                Value<String> favoriteCurrenciesJson = const Value.absent(),
                Value<String> languageMode = const Value.absent(),
                Value<int> refreshIntervalMinutes = const Value.absent(),
                Value<bool> wifiOnlyRefresh = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsRecordsCompanion(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                defaultCurrency: defaultCurrency,
                lastTransactionCurrency: lastTransactionCurrency,
                favoriteCurrenciesJson: favoriteCurrenciesJson,
                languageMode: languageMode,
                refreshIntervalMinutes: refreshIntervalMinutes,
                wifiOnlyRefresh: wifiOnlyRefresh,
                syncEnabled: syncEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> syncVersion = const Value.absent(),
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String defaultCurrency,
                Value<String?> lastTransactionCurrency = const Value.absent(),
                required String favoriteCurrenciesJson,
                required String languageMode,
                required int refreshIntervalMinutes,
                Value<bool> wifiOnlyRefresh = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsRecordsCompanion.insert(
                id: id,
                syncVersion: syncVersion,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                defaultCurrency: defaultCurrency,
                lastTransactionCurrency: lastTransactionCurrency,
                favoriteCurrenciesJson: favoriteCurrenciesJson,
                languageMode: languageMode,
                refreshIntervalMinutes: refreshIntervalMinutes,
                wifiOnlyRefresh: wifiOnlyRefresh,
                syncEnabled: syncEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserSettingsRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({defaultCurrency = false, lastTransactionCurrency = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (defaultCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.defaultCurrency,
                                    referencedTable:
                                        $$UserSettingsRecordsTableReferences
                                            ._defaultCurrencyTable(db),
                                    referencedColumn:
                                        $$UserSettingsRecordsTableReferences
                                            ._defaultCurrencyTable(db)
                                            .code,
                                  )
                                  as T;
                        }
                        if (lastTransactionCurrency) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn:
                                        table.lastTransactionCurrency,
                                    referencedTable:
                                        $$UserSettingsRecordsTableReferences
                                            ._lastTransactionCurrencyTable(db),
                                    referencedColumn:
                                        $$UserSettingsRecordsTableReferences
                                            ._lastTransactionCurrencyTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$UserSettingsRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsRecordsTable,
      UserSettingsRecord,
      $$UserSettingsRecordsTableFilterComposer,
      $$UserSettingsRecordsTableOrderingComposer,
      $$UserSettingsRecordsTableAnnotationComposer,
      $$UserSettingsRecordsTableCreateCompanionBuilder,
      $$UserSettingsRecordsTableUpdateCompanionBuilder,
      (UserSettingsRecord, $$UserSettingsRecordsTableReferences),
      UserSettingsRecord,
      PrefetchHooks Function({
        bool defaultCurrency,
        bool lastTransactionCurrency,
      })
    >;
typedef $$SyncMetadataEntriesTableCreateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      required String entityType,
      required String recordId,
      required int syncVersion,
      required String syncState,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastErrorCode,
      Value<String?> deviceId,
      Value<String?> changeId,
      Value<String?> lastSyncedPayloadJson,
      Value<int> rowid,
    });
typedef $$SyncMetadataEntriesTableUpdateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      Value<String> entityType,
      Value<String> recordId,
      Value<int> syncVersion,
      Value<String> syncState,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastErrorCode,
      Value<String?> deviceId,
      Value<String?> changeId,
      Value<String?> lastSyncedPayloadJson,
      Value<int> rowid,
    });

class $$SyncMetadataEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeId => $composableBuilder(
    column: $table.changeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncedPayloadJson => $composableBuilder(
    column: $table.lastSyncedPayloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeId => $composableBuilder(
    column: $table.changeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncedPayloadJson => $composableBuilder(
    column: $table.lastSyncedPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get changeId =>
      $composableBuilder(column: $table.changeId, builder: (column) => column);

  GeneratedColumn<String> get lastSyncedPayloadJson => $composableBuilder(
    column: $table.lastSyncedPayloadJson,
    builder: (column) => column,
  );
}

class $$SyncMetadataEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry,
          $$SyncMetadataEntriesTableFilterComposer,
          $$SyncMetadataEntriesTableOrderingComposer,
          $$SyncMetadataEntriesTableAnnotationComposer,
          $$SyncMetadataEntriesTableCreateCompanionBuilder,
          $$SyncMetadataEntriesTableUpdateCompanionBuilder,
          (
            SyncMetadataEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncMetadataEntriesTable,
              SyncMetadataEntry
            >,
          ),
          SyncMetadataEntry,
          PrefetchHooks Function()
        > {
  $$SyncMetadataEntriesTableTableManager(
    _$AppDatabase db,
    $SyncMetadataEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncMetadataEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> changeId = const Value.absent(),
                Value<String?> lastSyncedPayloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion(
                entityType: entityType,
                recordId: recordId,
                syncVersion: syncVersion,
                syncState: syncState,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                lastErrorCode: lastErrorCode,
                deviceId: deviceId,
                changeId: changeId,
                lastSyncedPayloadJson: lastSyncedPayloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required String recordId,
                required int syncVersion,
                required String syncState,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> changeId = const Value.absent(),
                Value<String?> lastSyncedPayloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion.insert(
                entityType: entityType,
                recordId: recordId,
                syncVersion: syncVersion,
                syncState: syncState,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                lastSyncedAt: lastSyncedAt,
                lastErrorCode: lastErrorCode,
                deviceId: deviceId,
                changeId: changeId,
                lastSyncedPayloadJson: lastSyncedPayloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataEntriesTable,
      SyncMetadataEntry,
      $$SyncMetadataEntriesTableFilterComposer,
      $$SyncMetadataEntriesTableOrderingComposer,
      $$SyncMetadataEntriesTableAnnotationComposer,
      $$SyncMetadataEntriesTableCreateCompanionBuilder,
      $$SyncMetadataEntriesTableUpdateCompanionBuilder,
      (
        SyncMetadataEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry
        >,
      ),
      SyncMetadataEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncRuntimeEntriesTableCreateCompanionBuilder =
    SyncRuntimeEntriesCompanion Function({
      required String id,
      Value<String?> cursor,
      required String deviceId,
      required String accountState,
      required String phase,
      Value<int> failureCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSuccessAt,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });
typedef $$SyncRuntimeEntriesTableUpdateCompanionBuilder =
    SyncRuntimeEntriesCompanion Function({
      Value<String> id,
      Value<String?> cursor,
      Value<String> deviceId,
      Value<String> accountState,
      Value<String> phase,
      Value<int> failureCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSuccessAt,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });

class $$SyncRuntimeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncRuntimeEntriesTable> {
  $$SyncRuntimeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountState => $composableBuilder(
    column: $table.accountState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncRuntimeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncRuntimeEntriesTable> {
  $$SyncRuntimeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountState => $composableBuilder(
    column: $table.accountState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRuntimeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncRuntimeEntriesTable> {
  $$SyncRuntimeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get accountState => $composableBuilder(
    column: $table.accountState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );
}

class $$SyncRuntimeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncRuntimeEntriesTable,
          SyncRuntimeEntry,
          $$SyncRuntimeEntriesTableFilterComposer,
          $$SyncRuntimeEntriesTableOrderingComposer,
          $$SyncRuntimeEntriesTableAnnotationComposer,
          $$SyncRuntimeEntriesTableCreateCompanionBuilder,
          $$SyncRuntimeEntriesTableUpdateCompanionBuilder,
          (
            SyncRuntimeEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncRuntimeEntriesTable,
              SyncRuntimeEntry
            >,
          ),
          SyncRuntimeEntry,
          PrefetchHooks Function()
        > {
  $$SyncRuntimeEntriesTableTableManager(
    _$AppDatabase db,
    $SyncRuntimeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRuntimeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRuntimeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRuntimeEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> accountState = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<int> failureCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRuntimeEntriesCompanion(
                id: id,
                cursor: cursor,
                deviceId: deviceId,
                accountState: accountState,
                phase: phase,
                failureCount: failureCount,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                nextRetryAt: nextRetryAt,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> cursor = const Value.absent(),
                required String deviceId,
                required String accountState,
                required String phase,
                Value<int> failureCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRuntimeEntriesCompanion.insert(
                id: id,
                cursor: cursor,
                deviceId: deviceId,
                accountState: accountState,
                phase: phase,
                failureCount: failureCount,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                nextRetryAt: nextRetryAt,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncRuntimeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncRuntimeEntriesTable,
      SyncRuntimeEntry,
      $$SyncRuntimeEntriesTableFilterComposer,
      $$SyncRuntimeEntriesTableOrderingComposer,
      $$SyncRuntimeEntriesTableAnnotationComposer,
      $$SyncRuntimeEntriesTableCreateCompanionBuilder,
      $$SyncRuntimeEntriesTableUpdateCompanionBuilder,
      (
        SyncRuntimeEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncRuntimeEntriesTable,
          SyncRuntimeEntry
        >,
      ),
      SyncRuntimeEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncConflictEntriesTableCreateCompanionBuilder =
    SyncConflictEntriesCompanion Function({
      required String id,
      required String entityType,
      required String recordId,
      required String fieldName,
      required String localPayloadJson,
      required String remotePayloadJson,
      required DateTime detectedAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });
typedef $$SyncConflictEntriesTableUpdateCompanionBuilder =
    SyncConflictEntriesCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> recordId,
      Value<String> fieldName,
      Value<String> localPayloadJson,
      Value<String> remotePayloadJson,
      Value<DateTime> detectedAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });

class $$SyncConflictEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictEntriesTable> {
  $$SyncConflictEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePayloadJson => $composableBuilder(
    column: $table.remotePayloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncConflictEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictEntriesTable> {
  $$SyncConflictEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePayloadJson => $composableBuilder(
    column: $table.remotePayloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictEntriesTable> {
  $$SyncConflictEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get localPayloadJson => $composableBuilder(
    column: $table.localPayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remotePayloadJson => $composableBuilder(
    column: $table.remotePayloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$SyncConflictEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncConflictEntriesTable,
          SyncConflictEntry,
          $$SyncConflictEntriesTableFilterComposer,
          $$SyncConflictEntriesTableOrderingComposer,
          $$SyncConflictEntriesTableAnnotationComposer,
          $$SyncConflictEntriesTableCreateCompanionBuilder,
          $$SyncConflictEntriesTableUpdateCompanionBuilder,
          (
            SyncConflictEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncConflictEntriesTable,
              SyncConflictEntry
            >,
          ),
          SyncConflictEntry,
          PrefetchHooks Function()
        > {
  $$SyncConflictEntriesTableTableManager(
    _$AppDatabase db,
    $SyncConflictEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncConflictEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String> localPayloadJson = const Value.absent(),
                Value<String> remotePayloadJson = const Value.absent(),
                Value<DateTime> detectedAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictEntriesCompanion(
                id: id,
                entityType: entityType,
                recordId: recordId,
                fieldName: fieldName,
                localPayloadJson: localPayloadJson,
                remotePayloadJson: remotePayloadJson,
                detectedAt: detectedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String recordId,
                required String fieldName,
                required String localPayloadJson,
                required String remotePayloadJson,
                required DateTime detectedAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictEntriesCompanion.insert(
                id: id,
                entityType: entityType,
                recordId: recordId,
                fieldName: fieldName,
                localPayloadJson: localPayloadJson,
                remotePayloadJson: remotePayloadJson,
                detectedAt: detectedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncConflictEntriesTable,
      SyncConflictEntry,
      $$SyncConflictEntriesTableFilterComposer,
      $$SyncConflictEntriesTableOrderingComposer,
      $$SyncConflictEntriesTableAnnotationComposer,
      $$SyncConflictEntriesTableCreateCompanionBuilder,
      $$SyncConflictEntriesTableUpdateCompanionBuilder,
      (
        SyncConflictEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncConflictEntriesTable,
          SyncConflictEntry
        >,
      ),
      SyncConflictEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db, _db.currencies);
  $$RateSnapshotsTableTableManager get rateSnapshots =>
      $$RateSnapshotsTableTableManager(_db, _db.rateSnapshots);
  $$PaymentMethodsTableTableManager get paymentMethods =>
      $$PaymentMethodsTableTableManager(_db, _db.paymentMethods);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$FeeCalibrationsTableTableManager get feeCalibrations =>
      $$FeeCalibrationsTableTableManager(_db, _db.feeCalibrations);
  $$UserSettingsRecordsTableTableManager get userSettingsRecords =>
      $$UserSettingsRecordsTableTableManager(_db, _db.userSettingsRecords);
  $$SyncMetadataEntriesTableTableManager get syncMetadataEntries =>
      $$SyncMetadataEntriesTableTableManager(_db, _db.syncMetadataEntries);
  $$SyncRuntimeEntriesTableTableManager get syncRuntimeEntries =>
      $$SyncRuntimeEntriesTableTableManager(_db, _db.syncRuntimeEntries);
  $$SyncConflictEntriesTableTableManager get syncConflictEntries =>
      $$SyncConflictEntriesTableTableManager(_db, _db.syncConflictEntries);
}
