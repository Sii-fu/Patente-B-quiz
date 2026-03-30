// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $LocalCategoriesTable extends LocalCategories
    with TableInfo<$LocalCategoriesTable, LocalCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameBnMeta = const VerificationMeta('nameBn');
  @override
  late final GeneratedColumn<String> nameBn = GeneratedColumn<String>(
    'name_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameIt,
    nameEn,
    nameBn,
    colorHex,
    displayOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_bn')) {
      context.handle(
        _nameBnMeta,
        nameBn.isAcceptableOrUnknown(data['name_bn']!, _nameBnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameBnMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_bn'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
    );
  }

  @override
  $LocalCategoriesTable createAlias(String alias) {
    return $LocalCategoriesTable(attachedDatabase, alias);
  }
}

class LocalCategory extends DataClass implements Insertable<LocalCategory> {
  final int id;
  final String nameIt;
  final String nameEn;
  final String nameBn;
  final String colorHex;
  final int displayOrder;
  const LocalCategory({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.nameBn,
    required this.colorHex,
    required this.displayOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_it'] = Variable<String>(nameIt);
    map['name_en'] = Variable<String>(nameEn);
    map['name_bn'] = Variable<String>(nameBn);
    map['color_hex'] = Variable<String>(colorHex);
    map['display_order'] = Variable<int>(displayOrder);
    return map;
  }

  LocalCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalCategoriesCompanion(
      id: Value(id),
      nameIt: Value(nameIt),
      nameEn: Value(nameEn),
      nameBn: Value(nameBn),
      colorHex: Value(colorHex),
      displayOrder: Value(displayOrder),
    );
  }

  factory LocalCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCategory(
      id: serializer.fromJson<int>(json['id']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameBn: serializer.fromJson<String>(json['nameBn']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameIt': serializer.toJson<String>(nameIt),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameBn': serializer.toJson<String>(nameBn),
      'colorHex': serializer.toJson<String>(colorHex),
      'displayOrder': serializer.toJson<int>(displayOrder),
    };
  }

  LocalCategory copyWith({
    int? id,
    String? nameIt,
    String? nameEn,
    String? nameBn,
    String? colorHex,
    int? displayOrder,
  }) => LocalCategory(
    id: id ?? this.id,
    nameIt: nameIt ?? this.nameIt,
    nameEn: nameEn ?? this.nameEn,
    nameBn: nameBn ?? this.nameBn,
    colorHex: colorHex ?? this.colorHex,
    displayOrder: displayOrder ?? this.displayOrder,
  );
  LocalCategory copyWithCompanion(LocalCategoriesCompanion data) {
    return LocalCategory(
      id: data.id.present ? data.id.value : this.id,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameBn: data.nameBn.present ? data.nameBn.value : this.nameBn,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategory(')
          ..write('id: $id, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameBn: $nameBn, ')
          ..write('colorHex: $colorHex, ')
          ..write('displayOrder: $displayOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nameIt, nameEn, nameBn, colorHex, displayOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCategory &&
          other.id == this.id &&
          other.nameIt == this.nameIt &&
          other.nameEn == this.nameEn &&
          other.nameBn == this.nameBn &&
          other.colorHex == this.colorHex &&
          other.displayOrder == this.displayOrder);
}

class LocalCategoriesCompanion extends UpdateCompanion<LocalCategory> {
  final Value<int> id;
  final Value<String> nameIt;
  final Value<String> nameEn;
  final Value<String> nameBn;
  final Value<String> colorHex;
  final Value<int> displayOrder;
  const LocalCategoriesCompanion({
    this.id = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameBn = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.displayOrder = const Value.absent(),
  });
  LocalCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String nameIt,
    required String nameEn,
    required String nameBn,
    required String colorHex,
    required int displayOrder,
  }) : nameIt = Value(nameIt),
       nameEn = Value(nameEn),
       nameBn = Value(nameBn),
       colorHex = Value(colorHex),
       displayOrder = Value(displayOrder);
  static Insertable<LocalCategory> custom({
    Expression<int>? id,
    Expression<String>? nameIt,
    Expression<String>? nameEn,
    Expression<String>? nameBn,
    Expression<String>? colorHex,
    Expression<int>? displayOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameIt != null) 'name_it': nameIt,
      if (nameEn != null) 'name_en': nameEn,
      if (nameBn != null) 'name_bn': nameBn,
      if (colorHex != null) 'color_hex': colorHex,
      if (displayOrder != null) 'display_order': displayOrder,
    });
  }

  LocalCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? nameIt,
    Value<String>? nameEn,
    Value<String>? nameBn,
    Value<String>? colorHex,
    Value<int>? displayOrder,
  }) {
    return LocalCategoriesCompanion(
      id: id ?? this.id,
      nameIt: nameIt ?? this.nameIt,
      nameEn: nameEn ?? this.nameEn,
      nameBn: nameBn ?? this.nameBn,
      colorHex: colorHex ?? this.colorHex,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameBn.present) {
      map['name_bn'] = Variable<String>(nameBn.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameBn: $nameBn, ')
          ..write('colorHex: $colorHex, ')
          ..write('displayOrder: $displayOrder')
          ..write(')'))
        .toString();
  }
}

class $LocalTopicsTable extends LocalTopics
    with TableInfo<$LocalTopicsTable, LocalTopic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameBnMeta = const VerificationMeta('nameBn');
  @override
  late final GeneratedColumn<String> nameBn = GeneratedColumn<String>(
    'name_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    nameIt,
    nameEn,
    nameBn,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTopic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_bn')) {
      context.handle(
        _nameBnMeta,
        nameBn.isAcceptableOrUnknown(data['name_bn']!, _nameBnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameBnMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTopic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTopic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_bn'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $LocalTopicsTable createAlias(String alias) {
    return $LocalTopicsTable(attachedDatabase, alias);
  }
}

class LocalTopic extends DataClass implements Insertable<LocalTopic> {
  final int id;
  final int categoryId;
  final String nameIt;
  final String nameEn;
  final String nameBn;
  final String? imageUrl;
  const LocalTopic({
    required this.id,
    required this.categoryId,
    required this.nameIt,
    required this.nameEn,
    required this.nameBn,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['name_it'] = Variable<String>(nameIt);
    map['name_en'] = Variable<String>(nameEn);
    map['name_bn'] = Variable<String>(nameBn);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  LocalTopicsCompanion toCompanion(bool nullToAbsent) {
    return LocalTopicsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      nameIt: Value(nameIt),
      nameEn: Value(nameEn),
      nameBn: Value(nameBn),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory LocalTopic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTopic(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameBn: serializer.fromJson<String>(json['nameBn']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'nameIt': serializer.toJson<String>(nameIt),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameBn': serializer.toJson<String>(nameBn),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  LocalTopic copyWith({
    int? id,
    int? categoryId,
    String? nameIt,
    String? nameEn,
    String? nameBn,
    Value<String?> imageUrl = const Value.absent(),
  }) => LocalTopic(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    nameIt: nameIt ?? this.nameIt,
    nameEn: nameEn ?? this.nameEn,
    nameBn: nameBn ?? this.nameBn,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  LocalTopic copyWithCompanion(LocalTopicsCompanion data) {
    return LocalTopic(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameBn: data.nameBn.present ? data.nameBn.value : this.nameBn,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTopic(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameBn: $nameBn, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, nameIt, nameEn, nameBn, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTopic &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.nameIt == this.nameIt &&
          other.nameEn == this.nameEn &&
          other.nameBn == this.nameBn &&
          other.imageUrl == this.imageUrl);
}

class LocalTopicsCompanion extends UpdateCompanion<LocalTopic> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> nameIt;
  final Value<String> nameEn;
  final Value<String> nameBn;
  final Value<String?> imageUrl;
  const LocalTopicsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameBn = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  LocalTopicsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String nameIt,
    required String nameEn,
    required String nameBn,
    this.imageUrl = const Value.absent(),
  }) : categoryId = Value(categoryId),
       nameIt = Value(nameIt),
       nameEn = Value(nameEn),
       nameBn = Value(nameBn);
  static Insertable<LocalTopic> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? nameIt,
    Expression<String>? nameEn,
    Expression<String>? nameBn,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (nameIt != null) 'name_it': nameIt,
      if (nameEn != null) 'name_en': nameEn,
      if (nameBn != null) 'name_bn': nameBn,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  LocalTopicsCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<String>? nameIt,
    Value<String>? nameEn,
    Value<String>? nameBn,
    Value<String?>? imageUrl,
  }) {
    return LocalTopicsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      nameIt: nameIt ?? this.nameIt,
      nameEn: nameEn ?? this.nameEn,
      nameBn: nameBn ?? this.nameBn,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameBn.present) {
      map['name_bn'] = Variable<String>(nameBn.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTopicsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameBn: $nameBn, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $LocalSubtopicsTable extends LocalSubtopics
    with TableInfo<$LocalSubtopicsTable, LocalSubtopic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSubtopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, topicId, nameIt, imageUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_subtopics';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSubtopic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSubtopic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSubtopic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      )!,
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $LocalSubtopicsTable createAlias(String alias) {
    return $LocalSubtopicsTable(attachedDatabase, alias);
  }
}

class LocalSubtopic extends DataClass implements Insertable<LocalSubtopic> {
  final int id;
  final int topicId;
  final String nameIt;
  final String? imageUrl;
  const LocalSubtopic({
    required this.id,
    required this.topicId,
    required this.nameIt,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic_id'] = Variable<int>(topicId);
    map['name_it'] = Variable<String>(nameIt);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  LocalSubtopicsCompanion toCompanion(bool nullToAbsent) {
    return LocalSubtopicsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      nameIt: Value(nameIt),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory LocalSubtopic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSubtopic(
      id: serializer.fromJson<int>(json['id']),
      topicId: serializer.fromJson<int>(json['topicId']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topicId': serializer.toJson<int>(topicId),
      'nameIt': serializer.toJson<String>(nameIt),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  LocalSubtopic copyWith({
    int? id,
    int? topicId,
    String? nameIt,
    Value<String?> imageUrl = const Value.absent(),
  }) => LocalSubtopic(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    nameIt: nameIt ?? this.nameIt,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  LocalSubtopic copyWithCompanion(LocalSubtopicsCompanion data) {
    return LocalSubtopic(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSubtopic(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('nameIt: $nameIt, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, topicId, nameIt, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSubtopic &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.nameIt == this.nameIt &&
          other.imageUrl == this.imageUrl);
}

class LocalSubtopicsCompanion extends UpdateCompanion<LocalSubtopic> {
  final Value<int> id;
  final Value<int> topicId;
  final Value<String> nameIt;
  final Value<String?> imageUrl;
  const LocalSubtopicsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  LocalSubtopicsCompanion.insert({
    this.id = const Value.absent(),
    required int topicId,
    required String nameIt,
    this.imageUrl = const Value.absent(),
  }) : topicId = Value(topicId),
       nameIt = Value(nameIt);
  static Insertable<LocalSubtopic> custom({
    Expression<int>? id,
    Expression<int>? topicId,
    Expression<String>? nameIt,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (nameIt != null) 'name_it': nameIt,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  LocalSubtopicsCompanion copyWith({
    Value<int>? id,
    Value<int>? topicId,
    Value<String>? nameIt,
    Value<String?>? imageUrl,
  }) {
    return LocalSubtopicsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      nameIt: nameIt ?? this.nameIt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSubtopicsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('nameIt: $nameIt, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $LocalQuestionsTable extends LocalQuestions
    with TableInfo<$LocalQuestionsTable, LocalQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtopicIdMeta = const VerificationMeta(
    'subtopicId',
  );
  @override
  late final GeneratedColumn<int> subtopicId = GeneratedColumn<int>(
    'subtopic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textItMeta = const VerificationMeta('textIt');
  @override
  late final GeneratedColumn<String> textIt = GeneratedColumn<String>(
    'text_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
    'text_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textBnMeta = const VerificationMeta('textBn');
  @override
  late final GeneratedColumn<String> textBn = GeneratedColumn<String>(
    'text_bn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTrueMeta = const VerificationMeta('isTrue');
  @override
  late final GeneratedColumn<bool> isTrue = GeneratedColumn<bool>(
    'is_true',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_true" IN (0, 1))',
    ),
  );
  static const VerificationMeta _explanationItMeta = const VerificationMeta(
    'explanationIt',
  );
  @override
  late final GeneratedColumn<String> explanationIt = GeneratedColumn<String>(
    'explanation_it',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subtopicId,
    textIt,
    textEn,
    textBn,
    imageUrl,
    isTrue,
    explanationIt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subtopic_id')) {
      context.handle(
        _subtopicIdMeta,
        subtopicId.isAcceptableOrUnknown(data['subtopic_id']!, _subtopicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subtopicIdMeta);
    }
    if (data.containsKey('text_it')) {
      context.handle(
        _textItMeta,
        textIt.isAcceptableOrUnknown(data['text_it']!, _textItMeta),
      );
    } else if (isInserting) {
      context.missing(_textItMeta);
    }
    if (data.containsKey('text_en')) {
      context.handle(
        _textEnMeta,
        textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta),
      );
    } else if (isInserting) {
      context.missing(_textEnMeta);
    }
    if (data.containsKey('text_bn')) {
      context.handle(
        _textBnMeta,
        textBn.isAcceptableOrUnknown(data['text_bn']!, _textBnMeta),
      );
    } else if (isInserting) {
      context.missing(_textBnMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('is_true')) {
      context.handle(
        _isTrueMeta,
        isTrue.isAcceptableOrUnknown(data['is_true']!, _isTrueMeta),
      );
    } else if (isInserting) {
      context.missing(_isTrueMeta);
    }
    if (data.containsKey('explanation_it')) {
      context.handle(
        _explanationItMeta,
        explanationIt.isAcceptableOrUnknown(
          data['explanation_it']!,
          _explanationItMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQuestion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subtopicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtopic_id'],
      )!,
      textIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_it'],
      )!,
      textEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_en'],
      )!,
      textBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_bn'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      isTrue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_true'],
      )!,
      explanationIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_it'],
      ),
    );
  }

  @override
  $LocalQuestionsTable createAlias(String alias) {
    return $LocalQuestionsTable(attachedDatabase, alias);
  }
}

class LocalQuestion extends DataClass implements Insertable<LocalQuestion> {
  final int id;
  final int subtopicId;
  final String textIt;
  final String textEn;
  final String textBn;
  final String? imageUrl;
  final bool isTrue;
  final String? explanationIt;
  const LocalQuestion({
    required this.id,
    required this.subtopicId,
    required this.textIt,
    required this.textEn,
    required this.textBn,
    this.imageUrl,
    required this.isTrue,
    this.explanationIt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subtopic_id'] = Variable<int>(subtopicId);
    map['text_it'] = Variable<String>(textIt);
    map['text_en'] = Variable<String>(textEn);
    map['text_bn'] = Variable<String>(textBn);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['is_true'] = Variable<bool>(isTrue);
    if (!nullToAbsent || explanationIt != null) {
      map['explanation_it'] = Variable<String>(explanationIt);
    }
    return map;
  }

  LocalQuestionsCompanion toCompanion(bool nullToAbsent) {
    return LocalQuestionsCompanion(
      id: Value(id),
      subtopicId: Value(subtopicId),
      textIt: Value(textIt),
      textEn: Value(textEn),
      textBn: Value(textBn),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      isTrue: Value(isTrue),
      explanationIt: explanationIt == null && nullToAbsent
          ? const Value.absent()
          : Value(explanationIt),
    );
  }

  factory LocalQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQuestion(
      id: serializer.fromJson<int>(json['id']),
      subtopicId: serializer.fromJson<int>(json['subtopicId']),
      textIt: serializer.fromJson<String>(json['textIt']),
      textEn: serializer.fromJson<String>(json['textEn']),
      textBn: serializer.fromJson<String>(json['textBn']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      isTrue: serializer.fromJson<bool>(json['isTrue']),
      explanationIt: serializer.fromJson<String?>(json['explanationIt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subtopicId': serializer.toJson<int>(subtopicId),
      'textIt': serializer.toJson<String>(textIt),
      'textEn': serializer.toJson<String>(textEn),
      'textBn': serializer.toJson<String>(textBn),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'isTrue': serializer.toJson<bool>(isTrue),
      'explanationIt': serializer.toJson<String?>(explanationIt),
    };
  }

  LocalQuestion copyWith({
    int? id,
    int? subtopicId,
    String? textIt,
    String? textEn,
    String? textBn,
    Value<String?> imageUrl = const Value.absent(),
    bool? isTrue,
    Value<String?> explanationIt = const Value.absent(),
  }) => LocalQuestion(
    id: id ?? this.id,
    subtopicId: subtopicId ?? this.subtopicId,
    textIt: textIt ?? this.textIt,
    textEn: textEn ?? this.textEn,
    textBn: textBn ?? this.textBn,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    isTrue: isTrue ?? this.isTrue,
    explanationIt: explanationIt.present
        ? explanationIt.value
        : this.explanationIt,
  );
  LocalQuestion copyWithCompanion(LocalQuestionsCompanion data) {
    return LocalQuestion(
      id: data.id.present ? data.id.value : this.id,
      subtopicId: data.subtopicId.present
          ? data.subtopicId.value
          : this.subtopicId,
      textIt: data.textIt.present ? data.textIt.value : this.textIt,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
      textBn: data.textBn.present ? data.textBn.value : this.textBn,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      isTrue: data.isTrue.present ? data.isTrue.value : this.isTrue,
      explanationIt: data.explanationIt.present
          ? data.explanationIt.value
          : this.explanationIt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuestion(')
          ..write('id: $id, ')
          ..write('subtopicId: $subtopicId, ')
          ..write('textIt: $textIt, ')
          ..write('textEn: $textEn, ')
          ..write('textBn: $textBn, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isTrue: $isTrue, ')
          ..write('explanationIt: $explanationIt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subtopicId,
    textIt,
    textEn,
    textBn,
    imageUrl,
    isTrue,
    explanationIt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQuestion &&
          other.id == this.id &&
          other.subtopicId == this.subtopicId &&
          other.textIt == this.textIt &&
          other.textEn == this.textEn &&
          other.textBn == this.textBn &&
          other.imageUrl == this.imageUrl &&
          other.isTrue == this.isTrue &&
          other.explanationIt == this.explanationIt);
}

class LocalQuestionsCompanion extends UpdateCompanion<LocalQuestion> {
  final Value<int> id;
  final Value<int> subtopicId;
  final Value<String> textIt;
  final Value<String> textEn;
  final Value<String> textBn;
  final Value<String?> imageUrl;
  final Value<bool> isTrue;
  final Value<String?> explanationIt;
  const LocalQuestionsCompanion({
    this.id = const Value.absent(),
    this.subtopicId = const Value.absent(),
    this.textIt = const Value.absent(),
    this.textEn = const Value.absent(),
    this.textBn = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isTrue = const Value.absent(),
    this.explanationIt = const Value.absent(),
  });
  LocalQuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int subtopicId,
    required String textIt,
    required String textEn,
    required String textBn,
    this.imageUrl = const Value.absent(),
    required bool isTrue,
    this.explanationIt = const Value.absent(),
  }) : subtopicId = Value(subtopicId),
       textIt = Value(textIt),
       textEn = Value(textEn),
       textBn = Value(textBn),
       isTrue = Value(isTrue);
  static Insertable<LocalQuestion> custom({
    Expression<int>? id,
    Expression<int>? subtopicId,
    Expression<String>? textIt,
    Expression<String>? textEn,
    Expression<String>? textBn,
    Expression<String>? imageUrl,
    Expression<bool>? isTrue,
    Expression<String>? explanationIt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subtopicId != null) 'subtopic_id': subtopicId,
      if (textIt != null) 'text_it': textIt,
      if (textEn != null) 'text_en': textEn,
      if (textBn != null) 'text_bn': textBn,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isTrue != null) 'is_true': isTrue,
      if (explanationIt != null) 'explanation_it': explanationIt,
    });
  }

  LocalQuestionsCompanion copyWith({
    Value<int>? id,
    Value<int>? subtopicId,
    Value<String>? textIt,
    Value<String>? textEn,
    Value<String>? textBn,
    Value<String?>? imageUrl,
    Value<bool>? isTrue,
    Value<String?>? explanationIt,
  }) {
    return LocalQuestionsCompanion(
      id: id ?? this.id,
      subtopicId: subtopicId ?? this.subtopicId,
      textIt: textIt ?? this.textIt,
      textEn: textEn ?? this.textEn,
      textBn: textBn ?? this.textBn,
      imageUrl: imageUrl ?? this.imageUrl,
      isTrue: isTrue ?? this.isTrue,
      explanationIt: explanationIt ?? this.explanationIt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subtopicId.present) {
      map['subtopic_id'] = Variable<int>(subtopicId.value);
    }
    if (textIt.present) {
      map['text_it'] = Variable<String>(textIt.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (textBn.present) {
      map['text_bn'] = Variable<String>(textBn.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (isTrue.present) {
      map['is_true'] = Variable<bool>(isTrue.value);
    }
    if (explanationIt.present) {
      map['explanation_it'] = Variable<String>(explanationIt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('subtopicId: $subtopicId, ')
          ..write('textIt: $textIt, ')
          ..write('textEn: $textEn, ')
          ..write('textBn: $textBn, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isTrue: $isTrue, ')
          ..write('explanationIt: $explanationIt')
          ..write(')'))
        .toString();
  }
}

class $PendingUploadsTable extends PendingUploads
    with TableInfo<$PendingUploadsTable, PendingUpload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _apiEndpointMeta = const VerificationMeta(
    'apiEndpoint',
  );
  @override
  late final GeneratedColumn<String> apiEndpoint = GeneratedColumn<String>(
    'api_endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
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
  List<GeneratedColumn> get $columns => [id, apiEndpoint, payload, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_uploads';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingUpload> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('api_endpoint')) {
      context.handle(
        _apiEndpointMeta,
        apiEndpoint.isAcceptableOrUnknown(
          data['api_endpoint']!,
          _apiEndpointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_apiEndpointMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
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
  PendingUpload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingUpload(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      apiEndpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_endpoint'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingUploadsTable createAlias(String alias) {
    return $PendingUploadsTable(attachedDatabase, alias);
  }
}

class PendingUpload extends DataClass implements Insertable<PendingUpload> {
  final int id;
  final String apiEndpoint;
  final String payload;
  final DateTime createdAt;
  const PendingUpload({
    required this.id,
    required this.apiEndpoint,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['api_endpoint'] = Variable<String>(apiEndpoint);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingUploadsCompanion toCompanion(bool nullToAbsent) {
    return PendingUploadsCompanion(
      id: Value(id),
      apiEndpoint: Value(apiEndpoint),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory PendingUpload.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingUpload(
      id: serializer.fromJson<int>(json['id']),
      apiEndpoint: serializer.fromJson<String>(json['apiEndpoint']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'apiEndpoint': serializer.toJson<String>(apiEndpoint),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingUpload copyWith({
    int? id,
    String? apiEndpoint,
    String? payload,
    DateTime? createdAt,
  }) => PendingUpload(
    id: id ?? this.id,
    apiEndpoint: apiEndpoint ?? this.apiEndpoint,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingUpload copyWithCompanion(PendingUploadsCompanion data) {
    return PendingUpload(
      id: data.id.present ? data.id.value : this.id,
      apiEndpoint: data.apiEndpoint.present
          ? data.apiEndpoint.value
          : this.apiEndpoint,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingUpload(')
          ..write('id: $id, ')
          ..write('apiEndpoint: $apiEndpoint, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, apiEndpoint, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingUpload &&
          other.id == this.id &&
          other.apiEndpoint == this.apiEndpoint &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class PendingUploadsCompanion extends UpdateCompanion<PendingUpload> {
  final Value<int> id;
  final Value<String> apiEndpoint;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  const PendingUploadsCompanion({
    this.id = const Value.absent(),
    this.apiEndpoint = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingUploadsCompanion.insert({
    this.id = const Value.absent(),
    required String apiEndpoint,
    required String payload,
    required DateTime createdAt,
  }) : apiEndpoint = Value(apiEndpoint),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<PendingUpload> custom({
    Expression<int>? id,
    Expression<String>? apiEndpoint,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (apiEndpoint != null) 'api_endpoint': apiEndpoint,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingUploadsCompanion copyWith({
    Value<int>? id,
    Value<String>? apiEndpoint,
    Value<String>? payload,
    Value<DateTime>? createdAt,
  }) {
    return PendingUploadsCompanion(
      id: id ?? this.id,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (apiEndpoint.present) {
      map['api_endpoint'] = Variable<String>(apiEndpoint.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingUploadsCompanion(')
          ..write('id: $id, ')
          ..write('apiEndpoint: $apiEndpoint, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalTheoryChaptersTable extends LocalTheoryChapters
    with TableInfo<$LocalTheoryChaptersTable, LocalTheoryChapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTheoryChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedQuizTopicIdMeta =
      const VerificationMeta('relatedQuizTopicId');
  @override
  late final GeneratedColumn<int> relatedQuizTopicId = GeneratedColumn<int>(
    'related_quiz_topic_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameItMeta = const VerificationMeta('nameIt');
  @override
  late final GeneratedColumn<String> nameIt = GeneratedColumn<String>(
    'name_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameBnMeta = const VerificationMeta('nameBn');
  @override
  late final GeneratedColumn<String> nameBn = GeneratedColumn<String>(
    'name_bn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    relatedQuizTopicId,
    nameIt,
    nameEn,
    nameBn,
    imageUrl,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_theory_chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTheoryChapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('related_quiz_topic_id')) {
      context.handle(
        _relatedQuizTopicIdMeta,
        relatedQuizTopicId.isAcceptableOrUnknown(
          data['related_quiz_topic_id']!,
          _relatedQuizTopicIdMeta,
        ),
      );
    }
    if (data.containsKey('name_it')) {
      context.handle(
        _nameItMeta,
        nameIt.isAcceptableOrUnknown(data['name_it']!, _nameItMeta),
      );
    } else if (isInserting) {
      context.missing(_nameItMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('name_bn')) {
      context.handle(
        _nameBnMeta,
        nameBn.isAcceptableOrUnknown(data['name_bn']!, _nameBnMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
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
  LocalTheoryChapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTheoryChapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      relatedQuizTopicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}related_quiz_topic_id'],
      ),
      nameIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_it'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      ),
      nameBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_bn'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalTheoryChaptersTable createAlias(String alias) {
    return $LocalTheoryChaptersTable(attachedDatabase, alias);
  }
}

class LocalTheoryChapter extends DataClass
    implements Insertable<LocalTheoryChapter> {
  final int id;
  final int? relatedQuizTopicId;
  final String nameIt;
  final String? nameEn;
  final String? nameBn;
  final String? imageUrl;
  final int displayOrder;
  final DateTime createdAt;
  const LocalTheoryChapter({
    required this.id,
    this.relatedQuizTopicId,
    required this.nameIt,
    this.nameEn,
    this.nameBn,
    this.imageUrl,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || relatedQuizTopicId != null) {
      map['related_quiz_topic_id'] = Variable<int>(relatedQuizTopicId);
    }
    map['name_it'] = Variable<String>(nameIt);
    if (!nullToAbsent || nameEn != null) {
      map['name_en'] = Variable<String>(nameEn);
    }
    if (!nullToAbsent || nameBn != null) {
      map['name_bn'] = Variable<String>(nameBn);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalTheoryChaptersCompanion toCompanion(bool nullToAbsent) {
    return LocalTheoryChaptersCompanion(
      id: Value(id),
      relatedQuizTopicId: relatedQuizTopicId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedQuizTopicId),
      nameIt: Value(nameIt),
      nameEn: nameEn == null && nullToAbsent
          ? const Value.absent()
          : Value(nameEn),
      nameBn: nameBn == null && nullToAbsent
          ? const Value.absent()
          : Value(nameBn),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory LocalTheoryChapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTheoryChapter(
      id: serializer.fromJson<int>(json['id']),
      relatedQuizTopicId: serializer.fromJson<int?>(json['relatedQuizTopicId']),
      nameIt: serializer.fromJson<String>(json['nameIt']),
      nameEn: serializer.fromJson<String?>(json['nameEn']),
      nameBn: serializer.fromJson<String?>(json['nameBn']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'relatedQuizTopicId': serializer.toJson<int?>(relatedQuizTopicId),
      'nameIt': serializer.toJson<String>(nameIt),
      'nameEn': serializer.toJson<String?>(nameEn),
      'nameBn': serializer.toJson<String?>(nameBn),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalTheoryChapter copyWith({
    int? id,
    Value<int?> relatedQuizTopicId = const Value.absent(),
    String? nameIt,
    Value<String?> nameEn = const Value.absent(),
    Value<String?> nameBn = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    int? displayOrder,
    DateTime? createdAt,
  }) => LocalTheoryChapter(
    id: id ?? this.id,
    relatedQuizTopicId: relatedQuizTopicId.present
        ? relatedQuizTopicId.value
        : this.relatedQuizTopicId,
    nameIt: nameIt ?? this.nameIt,
    nameEn: nameEn.present ? nameEn.value : this.nameEn,
    nameBn: nameBn.present ? nameBn.value : this.nameBn,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalTheoryChapter copyWithCompanion(LocalTheoryChaptersCompanion data) {
    return LocalTheoryChapter(
      id: data.id.present ? data.id.value : this.id,
      relatedQuizTopicId: data.relatedQuizTopicId.present
          ? data.relatedQuizTopicId.value
          : this.relatedQuizTopicId,
      nameIt: data.nameIt.present ? data.nameIt.value : this.nameIt,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameBn: data.nameBn.present ? data.nameBn.value : this.nameBn,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTheoryChapter(')
          ..write('id: $id, ')
          ..write('relatedQuizTopicId: $relatedQuizTopicId, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameBn: $nameBn, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    relatedQuizTopicId,
    nameIt,
    nameEn,
    nameBn,
    imageUrl,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTheoryChapter &&
          other.id == this.id &&
          other.relatedQuizTopicId == this.relatedQuizTopicId &&
          other.nameIt == this.nameIt &&
          other.nameEn == this.nameEn &&
          other.nameBn == this.nameBn &&
          other.imageUrl == this.imageUrl &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class LocalTheoryChaptersCompanion extends UpdateCompanion<LocalTheoryChapter> {
  final Value<int> id;
  final Value<int?> relatedQuizTopicId;
  final Value<String> nameIt;
  final Value<String?> nameEn;
  final Value<String?> nameBn;
  final Value<String?> imageUrl;
  final Value<int> displayOrder;
  final Value<DateTime> createdAt;
  const LocalTheoryChaptersCompanion({
    this.id = const Value.absent(),
    this.relatedQuizTopicId = const Value.absent(),
    this.nameIt = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameBn = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalTheoryChaptersCompanion.insert({
    this.id = const Value.absent(),
    this.relatedQuizTopicId = const Value.absent(),
    required String nameIt,
    this.nameEn = const Value.absent(),
    this.nameBn = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required int displayOrder,
    required DateTime createdAt,
  }) : nameIt = Value(nameIt),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt);
  static Insertable<LocalTheoryChapter> custom({
    Expression<int>? id,
    Expression<int>? relatedQuizTopicId,
    Expression<String>? nameIt,
    Expression<String>? nameEn,
    Expression<String>? nameBn,
    Expression<String>? imageUrl,
    Expression<int>? displayOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (relatedQuizTopicId != null)
        'related_quiz_topic_id': relatedQuizTopicId,
      if (nameIt != null) 'name_it': nameIt,
      if (nameEn != null) 'name_en': nameEn,
      if (nameBn != null) 'name_bn': nameBn,
      if (imageUrl != null) 'image_url': imageUrl,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalTheoryChaptersCompanion copyWith({
    Value<int>? id,
    Value<int?>? relatedQuizTopicId,
    Value<String>? nameIt,
    Value<String?>? nameEn,
    Value<String?>? nameBn,
    Value<String?>? imageUrl,
    Value<int>? displayOrder,
    Value<DateTime>? createdAt,
  }) {
    return LocalTheoryChaptersCompanion(
      id: id ?? this.id,
      relatedQuizTopicId: relatedQuizTopicId ?? this.relatedQuizTopicId,
      nameIt: nameIt ?? this.nameIt,
      nameEn: nameEn ?? this.nameEn,
      nameBn: nameBn ?? this.nameBn,
      imageUrl: imageUrl ?? this.imageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (relatedQuizTopicId.present) {
      map['related_quiz_topic_id'] = Variable<int>(relatedQuizTopicId.value);
    }
    if (nameIt.present) {
      map['name_it'] = Variable<String>(nameIt.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameBn.present) {
      map['name_bn'] = Variable<String>(nameBn.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTheoryChaptersCompanion(')
          ..write('id: $id, ')
          ..write('relatedQuizTopicId: $relatedQuizTopicId, ')
          ..write('nameIt: $nameIt, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameBn: $nameBn, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalTheoryCardsTable extends LocalTheoryCards
    with TableInfo<$LocalTheoryCardsTable, LocalTheoryCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTheoryCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtopicIdMeta = const VerificationMeta(
    'subtopicId',
  );
  @override
  late final GeneratedColumn<int> subtopicId = GeneratedColumn<int>(
    'subtopic_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleItMeta = const VerificationMeta(
    'titleIt',
  );
  @override
  late final GeneratedColumn<String> titleIt = GeneratedColumn<String>(
    'title_it',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleEnMeta = const VerificationMeta(
    'titleEn',
  );
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
    'title_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleBnMeta = const VerificationMeta(
    'titleBn',
  );
  @override
  late final GeneratedColumn<String> titleBn = GeneratedColumn<String>(
    'title_bn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textItMeta = const VerificationMeta('textIt');
  @override
  late final GeneratedColumn<String> textIt = GeneratedColumn<String>(
    'text_it',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textEnMeta = const VerificationMeta('textEn');
  @override
  late final GeneratedColumn<String> textEn = GeneratedColumn<String>(
    'text_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textBnMeta = const VerificationMeta('textBn');
  @override
  late final GeneratedColumn<String> textBn = GeneratedColumn<String>(
    'text_bn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    chapterId,
    subtopicId,
    titleIt,
    titleEn,
    titleBn,
    textIt,
    textEn,
    textBn,
    imageUrl,
    displayOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_theory_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTheoryCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('subtopic_id')) {
      context.handle(
        _subtopicIdMeta,
        subtopicId.isAcceptableOrUnknown(data['subtopic_id']!, _subtopicIdMeta),
      );
    }
    if (data.containsKey('title_it')) {
      context.handle(
        _titleItMeta,
        titleIt.isAcceptableOrUnknown(data['title_it']!, _titleItMeta),
      );
    }
    if (data.containsKey('title_en')) {
      context.handle(
        _titleEnMeta,
        titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta),
      );
    }
    if (data.containsKey('title_bn')) {
      context.handle(
        _titleBnMeta,
        titleBn.isAcceptableOrUnknown(data['title_bn']!, _titleBnMeta),
      );
    }
    if (data.containsKey('text_it')) {
      context.handle(
        _textItMeta,
        textIt.isAcceptableOrUnknown(data['text_it']!, _textItMeta),
      );
    } else if (isInserting) {
      context.missing(_textItMeta);
    }
    if (data.containsKey('text_en')) {
      context.handle(
        _textEnMeta,
        textEn.isAcceptableOrUnknown(data['text_en']!, _textEnMeta),
      );
    }
    if (data.containsKey('text_bn')) {
      context.handle(
        _textBnMeta,
        textBn.isAcceptableOrUnknown(data['text_bn']!, _textBnMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
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
  LocalTheoryCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTheoryCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      subtopicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtopic_id'],
      ),
      titleIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_it'],
      ),
      titleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_en'],
      ),
      titleBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_bn'],
      ),
      textIt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_it'],
      )!,
      textEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_en'],
      ),
      textBn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_bn'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalTheoryCardsTable createAlias(String alias) {
    return $LocalTheoryCardsTable(attachedDatabase, alias);
  }
}

class LocalTheoryCard extends DataClass implements Insertable<LocalTheoryCard> {
  final int id;
  final int chapterId;
  final int? subtopicId;
  final String? titleIt;
  final String? titleEn;
  final String? titleBn;
  final String textIt;
  final String? textEn;
  final String? textBn;
  final String? imageUrl;
  final int displayOrder;
  final DateTime createdAt;
  const LocalTheoryCard({
    required this.id,
    required this.chapterId,
    this.subtopicId,
    this.titleIt,
    this.titleEn,
    this.titleBn,
    required this.textIt,
    this.textEn,
    this.textBn,
    this.imageUrl,
    required this.displayOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    if (!nullToAbsent || subtopicId != null) {
      map['subtopic_id'] = Variable<int>(subtopicId);
    }
    if (!nullToAbsent || titleIt != null) {
      map['title_it'] = Variable<String>(titleIt);
    }
    if (!nullToAbsent || titleEn != null) {
      map['title_en'] = Variable<String>(titleEn);
    }
    if (!nullToAbsent || titleBn != null) {
      map['title_bn'] = Variable<String>(titleBn);
    }
    map['text_it'] = Variable<String>(textIt);
    if (!nullToAbsent || textEn != null) {
      map['text_en'] = Variable<String>(textEn);
    }
    if (!nullToAbsent || textBn != null) {
      map['text_bn'] = Variable<String>(textBn);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalTheoryCardsCompanion toCompanion(bool nullToAbsent) {
    return LocalTheoryCardsCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      subtopicId: subtopicId == null && nullToAbsent
          ? const Value.absent()
          : Value(subtopicId),
      titleIt: titleIt == null && nullToAbsent
          ? const Value.absent()
          : Value(titleIt),
      titleEn: titleEn == null && nullToAbsent
          ? const Value.absent()
          : Value(titleEn),
      titleBn: titleBn == null && nullToAbsent
          ? const Value.absent()
          : Value(titleBn),
      textIt: Value(textIt),
      textEn: textEn == null && nullToAbsent
          ? const Value.absent()
          : Value(textEn),
      textBn: textBn == null && nullToAbsent
          ? const Value.absent()
          : Value(textBn),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
    );
  }

  factory LocalTheoryCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTheoryCard(
      id: serializer.fromJson<int>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      subtopicId: serializer.fromJson<int?>(json['subtopicId']),
      titleIt: serializer.fromJson<String?>(json['titleIt']),
      titleEn: serializer.fromJson<String?>(json['titleEn']),
      titleBn: serializer.fromJson<String?>(json['titleBn']),
      textIt: serializer.fromJson<String>(json['textIt']),
      textEn: serializer.fromJson<String?>(json['textEn']),
      textBn: serializer.fromJson<String?>(json['textBn']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'subtopicId': serializer.toJson<int?>(subtopicId),
      'titleIt': serializer.toJson<String?>(titleIt),
      'titleEn': serializer.toJson<String?>(titleEn),
      'titleBn': serializer.toJson<String?>(titleBn),
      'textIt': serializer.toJson<String>(textIt),
      'textEn': serializer.toJson<String?>(textEn),
      'textBn': serializer.toJson<String?>(textBn),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalTheoryCard copyWith({
    int? id,
    int? chapterId,
    Value<int?> subtopicId = const Value.absent(),
    Value<String?> titleIt = const Value.absent(),
    Value<String?> titleEn = const Value.absent(),
    Value<String?> titleBn = const Value.absent(),
    String? textIt,
    Value<String?> textEn = const Value.absent(),
    Value<String?> textBn = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    int? displayOrder,
    DateTime? createdAt,
  }) => LocalTheoryCard(
    id: id ?? this.id,
    chapterId: chapterId ?? this.chapterId,
    subtopicId: subtopicId.present ? subtopicId.value : this.subtopicId,
    titleIt: titleIt.present ? titleIt.value : this.titleIt,
    titleEn: titleEn.present ? titleEn.value : this.titleEn,
    titleBn: titleBn.present ? titleBn.value : this.titleBn,
    textIt: textIt ?? this.textIt,
    textEn: textEn.present ? textEn.value : this.textEn,
    textBn: textBn.present ? textBn.value : this.textBn,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalTheoryCard copyWithCompanion(LocalTheoryCardsCompanion data) {
    return LocalTheoryCard(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      subtopicId: data.subtopicId.present
          ? data.subtopicId.value
          : this.subtopicId,
      titleIt: data.titleIt.present ? data.titleIt.value : this.titleIt,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      titleBn: data.titleBn.present ? data.titleBn.value : this.titleBn,
      textIt: data.textIt.present ? data.textIt.value : this.textIt,
      textEn: data.textEn.present ? data.textEn.value : this.textEn,
      textBn: data.textBn.present ? data.textBn.value : this.textBn,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTheoryCard(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('subtopicId: $subtopicId, ')
          ..write('titleIt: $titleIt, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleBn: $titleBn, ')
          ..write('textIt: $textIt, ')
          ..write('textEn: $textEn, ')
          ..write('textBn: $textBn, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chapterId,
    subtopicId,
    titleIt,
    titleEn,
    titleBn,
    textIt,
    textEn,
    textBn,
    imageUrl,
    displayOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTheoryCard &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.subtopicId == this.subtopicId &&
          other.titleIt == this.titleIt &&
          other.titleEn == this.titleEn &&
          other.titleBn == this.titleBn &&
          other.textIt == this.textIt &&
          other.textEn == this.textEn &&
          other.textBn == this.textBn &&
          other.imageUrl == this.imageUrl &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt);
}

class LocalTheoryCardsCompanion extends UpdateCompanion<LocalTheoryCard> {
  final Value<int> id;
  final Value<int> chapterId;
  final Value<int?> subtopicId;
  final Value<String?> titleIt;
  final Value<String?> titleEn;
  final Value<String?> titleBn;
  final Value<String> textIt;
  final Value<String?> textEn;
  final Value<String?> textBn;
  final Value<String?> imageUrl;
  final Value<int> displayOrder;
  final Value<DateTime> createdAt;
  const LocalTheoryCardsCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.subtopicId = const Value.absent(),
    this.titleIt = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.titleBn = const Value.absent(),
    this.textIt = const Value.absent(),
    this.textEn = const Value.absent(),
    this.textBn = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalTheoryCardsCompanion.insert({
    this.id = const Value.absent(),
    required int chapterId,
    this.subtopicId = const Value.absent(),
    this.titleIt = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.titleBn = const Value.absent(),
    required String textIt,
    this.textEn = const Value.absent(),
    this.textBn = const Value.absent(),
    this.imageUrl = const Value.absent(),
    required int displayOrder,
    required DateTime createdAt,
  }) : chapterId = Value(chapterId),
       textIt = Value(textIt),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt);
  static Insertable<LocalTheoryCard> custom({
    Expression<int>? id,
    Expression<int>? chapterId,
    Expression<int>? subtopicId,
    Expression<String>? titleIt,
    Expression<String>? titleEn,
    Expression<String>? titleBn,
    Expression<String>? textIt,
    Expression<String>? textEn,
    Expression<String>? textBn,
    Expression<String>? imageUrl,
    Expression<int>? displayOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (subtopicId != null) 'subtopic_id': subtopicId,
      if (titleIt != null) 'title_it': titleIt,
      if (titleEn != null) 'title_en': titleEn,
      if (titleBn != null) 'title_bn': titleBn,
      if (textIt != null) 'text_it': textIt,
      if (textEn != null) 'text_en': textEn,
      if (textBn != null) 'text_bn': textBn,
      if (imageUrl != null) 'image_url': imageUrl,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalTheoryCardsCompanion copyWith({
    Value<int>? id,
    Value<int>? chapterId,
    Value<int?>? subtopicId,
    Value<String?>? titleIt,
    Value<String?>? titleEn,
    Value<String?>? titleBn,
    Value<String>? textIt,
    Value<String?>? textEn,
    Value<String?>? textBn,
    Value<String?>? imageUrl,
    Value<int>? displayOrder,
    Value<DateTime>? createdAt,
  }) {
    return LocalTheoryCardsCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      subtopicId: subtopicId ?? this.subtopicId,
      titleIt: titleIt ?? this.titleIt,
      titleEn: titleEn ?? this.titleEn,
      titleBn: titleBn ?? this.titleBn,
      textIt: textIt ?? this.textIt,
      textEn: textEn ?? this.textEn,
      textBn: textBn ?? this.textBn,
      imageUrl: imageUrl ?? this.imageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (subtopicId.present) {
      map['subtopic_id'] = Variable<int>(subtopicId.value);
    }
    if (titleIt.present) {
      map['title_it'] = Variable<String>(titleIt.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (titleBn.present) {
      map['title_bn'] = Variable<String>(titleBn.value);
    }
    if (textIt.present) {
      map['text_it'] = Variable<String>(textIt.value);
    }
    if (textEn.present) {
      map['text_en'] = Variable<String>(textEn.value);
    }
    if (textBn.present) {
      map['text_bn'] = Variable<String>(textBn.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTheoryCardsCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('subtopicId: $subtopicId, ')
          ..write('titleIt: $titleIt, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleBn: $titleBn, ')
          ..write('textIt: $textIt, ')
          ..write('textEn: $textEn, ')
          ..write('textBn: $textBn, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TheoryProgressTableTable extends TheoryProgressTable
    with TableInfo<$TheoryProgressTableTable, TheoryProgress> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TheoryProgressTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chapterId,
    cardId,
    isRead,
    lastReadAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'theory_progress_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TheoryProgress> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {chapterId, cardId},
  ];
  @override
  TheoryProgress map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TheoryProgress(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      ),
    );
  }

  @override
  $TheoryProgressTableTable createAlias(String alias) {
    return $TheoryProgressTableTable(attachedDatabase, alias);
  }
}

class TheoryProgress extends DataClass implements Insertable<TheoryProgress> {
  final int id;
  final int chapterId;
  final int cardId;
  final bool isRead;
  final DateTime? lastReadAt;
  const TheoryProgress({
    required this.id,
    required this.chapterId,
    required this.cardId,
    required this.isRead,
    this.lastReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    map['card_id'] = Variable<int>(cardId);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt);
    }
    return map;
  }

  TheoryProgressTableCompanion toCompanion(bool nullToAbsent) {
    return TheoryProgressTableCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      cardId: Value(cardId),
      isRead: Value(isRead),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
    );
  }

  factory TheoryProgress.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TheoryProgress(
      id: serializer.fromJson<int>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      cardId: serializer.fromJson<int>(json['cardId']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      lastReadAt: serializer.fromJson<DateTime?>(json['lastReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'cardId': serializer.toJson<int>(cardId),
      'isRead': serializer.toJson<bool>(isRead),
      'lastReadAt': serializer.toJson<DateTime?>(lastReadAt),
    };
  }

  TheoryProgress copyWith({
    int? id,
    int? chapterId,
    int? cardId,
    bool? isRead,
    Value<DateTime?> lastReadAt = const Value.absent(),
  }) => TheoryProgress(
    id: id ?? this.id,
    chapterId: chapterId ?? this.chapterId,
    cardId: cardId ?? this.cardId,
    isRead: isRead ?? this.isRead,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
  );
  TheoryProgress copyWithCompanion(TheoryProgressTableCompanion data) {
    return TheoryProgress(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TheoryProgress(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('cardId: $cardId, ')
          ..write('isRead: $isRead, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, chapterId, cardId, isRead, lastReadAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TheoryProgress &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.cardId == this.cardId &&
          other.isRead == this.isRead &&
          other.lastReadAt == this.lastReadAt);
}

class TheoryProgressTableCompanion extends UpdateCompanion<TheoryProgress> {
  final Value<int> id;
  final Value<int> chapterId;
  final Value<int> cardId;
  final Value<bool> isRead;
  final Value<DateTime?> lastReadAt;
  const TheoryProgressTableCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.isRead = const Value.absent(),
    this.lastReadAt = const Value.absent(),
  });
  TheoryProgressTableCompanion.insert({
    this.id = const Value.absent(),
    required int chapterId,
    required int cardId,
    this.isRead = const Value.absent(),
    this.lastReadAt = const Value.absent(),
  }) : chapterId = Value(chapterId),
       cardId = Value(cardId);
  static Insertable<TheoryProgress> custom({
    Expression<int>? id,
    Expression<int>? chapterId,
    Expression<int>? cardId,
    Expression<bool>? isRead,
    Expression<DateTime>? lastReadAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (cardId != null) 'card_id': cardId,
      if (isRead != null) 'is_read': isRead,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
    });
  }

  TheoryProgressTableCompanion copyWith({
    Value<int>? id,
    Value<int>? chapterId,
    Value<int>? cardId,
    Value<bool>? isRead,
    Value<DateTime?>? lastReadAt,
  }) {
    return TheoryProgressTableCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      cardId: cardId ?? this.cardId,
      isRead: isRead ?? this.isRead,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TheoryProgressTableCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('cardId: $cardId, ')
          ..write('isRead: $isRead, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalCategoriesTable localCategories = $LocalCategoriesTable(
    this,
  );
  late final $LocalTopicsTable localTopics = $LocalTopicsTable(this);
  late final $LocalSubtopicsTable localSubtopics = $LocalSubtopicsTable(this);
  late final $LocalQuestionsTable localQuestions = $LocalQuestionsTable(this);
  late final $PendingUploadsTable pendingUploads = $PendingUploadsTable(this);
  late final $LocalTheoryChaptersTable localTheoryChapters =
      $LocalTheoryChaptersTable(this);
  late final $LocalTheoryCardsTable localTheoryCards = $LocalTheoryCardsTable(
    this,
  );
  late final $TheoryProgressTableTable theoryProgressTable =
      $TheoryProgressTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localCategories,
    localTopics,
    localSubtopics,
    localQuestions,
    pendingUploads,
    localTheoryChapters,
    localTheoryCards,
    theoryProgressTable,
  ];
}

typedef $$LocalCategoriesTableCreateCompanionBuilder =
    LocalCategoriesCompanion Function({
      Value<int> id,
      required String nameIt,
      required String nameEn,
      required String nameBn,
      required String colorHex,
      required int displayOrder,
    });
typedef $$LocalCategoriesTableUpdateCompanionBuilder =
    LocalCategoriesCompanion Function({
      Value<int> id,
      Value<String> nameIt,
      Value<String> nameEn,
      Value<String> nameBn,
      Value<String> colorHex,
      Value<int> displayOrder,
    });

class $$LocalCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameBn =>
      $composableBuilder(column: $table.nameBn, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );
}

class $$LocalCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCategoriesTable,
          LocalCategory,
          $$LocalCategoriesTableFilterComposer,
          $$LocalCategoriesTableOrderingComposer,
          $$LocalCategoriesTableAnnotationComposer,
          $$LocalCategoriesTableCreateCompanionBuilder,
          $$LocalCategoriesTableUpdateCompanionBuilder,
          (
            LocalCategory,
            BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
          ),
          LocalCategory,
          PrefetchHooks Function()
        > {
  $$LocalCategoriesTableTableManager(
    _$AppDatabase db,
    $LocalCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameBn = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
              }) => LocalCategoriesCompanion(
                id: id,
                nameIt: nameIt,
                nameEn: nameEn,
                nameBn: nameBn,
                colorHex: colorHex,
                displayOrder: displayOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nameIt,
                required String nameEn,
                required String nameBn,
                required String colorHex,
                required int displayOrder,
              }) => LocalCategoriesCompanion.insert(
                id: id,
                nameIt: nameIt,
                nameEn: nameEn,
                nameBn: nameBn,
                colorHex: colorHex,
                displayOrder: displayOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCategoriesTable,
      LocalCategory,
      $$LocalCategoriesTableFilterComposer,
      $$LocalCategoriesTableOrderingComposer,
      $$LocalCategoriesTableAnnotationComposer,
      $$LocalCategoriesTableCreateCompanionBuilder,
      $$LocalCategoriesTableUpdateCompanionBuilder,
      (
        LocalCategory,
        BaseReferences<_$AppDatabase, $LocalCategoriesTable, LocalCategory>,
      ),
      LocalCategory,
      PrefetchHooks Function()
    >;
typedef $$LocalTopicsTableCreateCompanionBuilder =
    LocalTopicsCompanion Function({
      Value<int> id,
      required int categoryId,
      required String nameIt,
      required String nameEn,
      required String nameBn,
      Value<String?> imageUrl,
    });
typedef $$LocalTopicsTableUpdateCompanionBuilder =
    LocalTopicsCompanion Function({
      Value<int> id,
      Value<int> categoryId,
      Value<String> nameIt,
      Value<String> nameEn,
      Value<String> nameBn,
      Value<String?> imageUrl,
    });

class $$LocalTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTopicsTable> {
  $$LocalTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTopicsTable> {
  $$LocalTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTopicsTable> {
  $$LocalTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameBn =>
      $composableBuilder(column: $table.nameBn, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$LocalTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTopicsTable,
          LocalTopic,
          $$LocalTopicsTableFilterComposer,
          $$LocalTopicsTableOrderingComposer,
          $$LocalTopicsTableAnnotationComposer,
          $$LocalTopicsTableCreateCompanionBuilder,
          $$LocalTopicsTableUpdateCompanionBuilder,
          (
            LocalTopic,
            BaseReferences<_$AppDatabase, $LocalTopicsTable, LocalTopic>,
          ),
          LocalTopic,
          PrefetchHooks Function()
        > {
  $$LocalTopicsTableTableManager(_$AppDatabase db, $LocalTopicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameBn = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
              }) => LocalTopicsCompanion(
                id: id,
                categoryId: categoryId,
                nameIt: nameIt,
                nameEn: nameEn,
                nameBn: nameBn,
                imageUrl: imageUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int categoryId,
                required String nameIt,
                required String nameEn,
                required String nameBn,
                Value<String?> imageUrl = const Value.absent(),
              }) => LocalTopicsCompanion.insert(
                id: id,
                categoryId: categoryId,
                nameIt: nameIt,
                nameEn: nameEn,
                nameBn: nameBn,
                imageUrl: imageUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTopicsTable,
      LocalTopic,
      $$LocalTopicsTableFilterComposer,
      $$LocalTopicsTableOrderingComposer,
      $$LocalTopicsTableAnnotationComposer,
      $$LocalTopicsTableCreateCompanionBuilder,
      $$LocalTopicsTableUpdateCompanionBuilder,
      (
        LocalTopic,
        BaseReferences<_$AppDatabase, $LocalTopicsTable, LocalTopic>,
      ),
      LocalTopic,
      PrefetchHooks Function()
    >;
typedef $$LocalSubtopicsTableCreateCompanionBuilder =
    LocalSubtopicsCompanion Function({
      Value<int> id,
      required int topicId,
      required String nameIt,
      Value<String?> imageUrl,
    });
typedef $$LocalSubtopicsTableUpdateCompanionBuilder =
    LocalSubtopicsCompanion Function({
      Value<int> id,
      Value<int> topicId,
      Value<String> nameIt,
      Value<String?> imageUrl,
    });

class $$LocalSubtopicsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSubtopicsTable> {
  $$LocalSubtopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSubtopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSubtopicsTable> {
  $$LocalSubtopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSubtopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSubtopicsTable> {
  $$LocalSubtopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$LocalSubtopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSubtopicsTable,
          LocalSubtopic,
          $$LocalSubtopicsTableFilterComposer,
          $$LocalSubtopicsTableOrderingComposer,
          $$LocalSubtopicsTableAnnotationComposer,
          $$LocalSubtopicsTableCreateCompanionBuilder,
          $$LocalSubtopicsTableUpdateCompanionBuilder,
          (
            LocalSubtopic,
            BaseReferences<_$AppDatabase, $LocalSubtopicsTable, LocalSubtopic>,
          ),
          LocalSubtopic,
          PrefetchHooks Function()
        > {
  $$LocalSubtopicsTableTableManager(
    _$AppDatabase db,
    $LocalSubtopicsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSubtopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSubtopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSubtopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> topicId = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
              }) => LocalSubtopicsCompanion(
                id: id,
                topicId: topicId,
                nameIt: nameIt,
                imageUrl: imageUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int topicId,
                required String nameIt,
                Value<String?> imageUrl = const Value.absent(),
              }) => LocalSubtopicsCompanion.insert(
                id: id,
                topicId: topicId,
                nameIt: nameIt,
                imageUrl: imageUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSubtopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSubtopicsTable,
      LocalSubtopic,
      $$LocalSubtopicsTableFilterComposer,
      $$LocalSubtopicsTableOrderingComposer,
      $$LocalSubtopicsTableAnnotationComposer,
      $$LocalSubtopicsTableCreateCompanionBuilder,
      $$LocalSubtopicsTableUpdateCompanionBuilder,
      (
        LocalSubtopic,
        BaseReferences<_$AppDatabase, $LocalSubtopicsTable, LocalSubtopic>,
      ),
      LocalSubtopic,
      PrefetchHooks Function()
    >;
typedef $$LocalQuestionsTableCreateCompanionBuilder =
    LocalQuestionsCompanion Function({
      Value<int> id,
      required int subtopicId,
      required String textIt,
      required String textEn,
      required String textBn,
      Value<String?> imageUrl,
      required bool isTrue,
      Value<String?> explanationIt,
    });
typedef $$LocalQuestionsTableUpdateCompanionBuilder =
    LocalQuestionsCompanion Function({
      Value<int> id,
      Value<int> subtopicId,
      Value<String> textIt,
      Value<String> textEn,
      Value<String> textBn,
      Value<String?> imageUrl,
      Value<bool> isTrue,
      Value<String?> explanationIt,
    });

class $$LocalQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalQuestionsTable> {
  $$LocalQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtopicId => $composableBuilder(
    column: $table.subtopicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textIt => $composableBuilder(
    column: $table.textIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textBn => $composableBuilder(
    column: $table.textBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTrue => $composableBuilder(
    column: $table.isTrue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationIt => $composableBuilder(
    column: $table.explanationIt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalQuestionsTable> {
  $$LocalQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtopicId => $composableBuilder(
    column: $table.subtopicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textIt => $composableBuilder(
    column: $table.textIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textBn => $composableBuilder(
    column: $table.textBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTrue => $composableBuilder(
    column: $table.isTrue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationIt => $composableBuilder(
    column: $table.explanationIt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalQuestionsTable> {
  $$LocalQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get subtopicId => $composableBuilder(
    column: $table.subtopicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textIt =>
      $composableBuilder(column: $table.textIt, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);

  GeneratedColumn<String> get textBn =>
      $composableBuilder(column: $table.textBn, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<bool> get isTrue =>
      $composableBuilder(column: $table.isTrue, builder: (column) => column);

  GeneratedColumn<String> get explanationIt => $composableBuilder(
    column: $table.explanationIt,
    builder: (column) => column,
  );
}

class $$LocalQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalQuestionsTable,
          LocalQuestion,
          $$LocalQuestionsTableFilterComposer,
          $$LocalQuestionsTableOrderingComposer,
          $$LocalQuestionsTableAnnotationComposer,
          $$LocalQuestionsTableCreateCompanionBuilder,
          $$LocalQuestionsTableUpdateCompanionBuilder,
          (
            LocalQuestion,
            BaseReferences<_$AppDatabase, $LocalQuestionsTable, LocalQuestion>,
          ),
          LocalQuestion,
          PrefetchHooks Function()
        > {
  $$LocalQuestionsTableTableManager(
    _$AppDatabase db,
    $LocalQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subtopicId = const Value.absent(),
                Value<String> textIt = const Value.absent(),
                Value<String> textEn = const Value.absent(),
                Value<String> textBn = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<bool> isTrue = const Value.absent(),
                Value<String?> explanationIt = const Value.absent(),
              }) => LocalQuestionsCompanion(
                id: id,
                subtopicId: subtopicId,
                textIt: textIt,
                textEn: textEn,
                textBn: textBn,
                imageUrl: imageUrl,
                isTrue: isTrue,
                explanationIt: explanationIt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subtopicId,
                required String textIt,
                required String textEn,
                required String textBn,
                Value<String?> imageUrl = const Value.absent(),
                required bool isTrue,
                Value<String?> explanationIt = const Value.absent(),
              }) => LocalQuestionsCompanion.insert(
                id: id,
                subtopicId: subtopicId,
                textIt: textIt,
                textEn: textEn,
                textBn: textBn,
                imageUrl: imageUrl,
                isTrue: isTrue,
                explanationIt: explanationIt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalQuestionsTable,
      LocalQuestion,
      $$LocalQuestionsTableFilterComposer,
      $$LocalQuestionsTableOrderingComposer,
      $$LocalQuestionsTableAnnotationComposer,
      $$LocalQuestionsTableCreateCompanionBuilder,
      $$LocalQuestionsTableUpdateCompanionBuilder,
      (
        LocalQuestion,
        BaseReferences<_$AppDatabase, $LocalQuestionsTable, LocalQuestion>,
      ),
      LocalQuestion,
      PrefetchHooks Function()
    >;
typedef $$PendingUploadsTableCreateCompanionBuilder =
    PendingUploadsCompanion Function({
      Value<int> id,
      required String apiEndpoint,
      required String payload,
      required DateTime createdAt,
    });
typedef $$PendingUploadsTableUpdateCompanionBuilder =
    PendingUploadsCompanion Function({
      Value<int> id,
      Value<String> apiEndpoint,
      Value<String> payload,
      Value<DateTime> createdAt,
    });

class $$PendingUploadsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiEndpoint => $composableBuilder(
    column: $table.apiEndpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingUploadsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiEndpoint => $composableBuilder(
    column: $table.apiEndpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingUploadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get apiEndpoint => $composableBuilder(
    column: $table.apiEndpoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingUploadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingUploadsTable,
          PendingUpload,
          $$PendingUploadsTableFilterComposer,
          $$PendingUploadsTableOrderingComposer,
          $$PendingUploadsTableAnnotationComposer,
          $$PendingUploadsTableCreateCompanionBuilder,
          $$PendingUploadsTableUpdateCompanionBuilder,
          (
            PendingUpload,
            BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUpload>,
          ),
          PendingUpload,
          PrefetchHooks Function()
        > {
  $$PendingUploadsTableTableManager(
    _$AppDatabase db,
    $PendingUploadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> apiEndpoint = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingUploadsCompanion(
                id: id,
                apiEndpoint: apiEndpoint,
                payload: payload,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String apiEndpoint,
                required String payload,
                required DateTime createdAt,
              }) => PendingUploadsCompanion.insert(
                id: id,
                apiEndpoint: apiEndpoint,
                payload: payload,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingUploadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingUploadsTable,
      PendingUpload,
      $$PendingUploadsTableFilterComposer,
      $$PendingUploadsTableOrderingComposer,
      $$PendingUploadsTableAnnotationComposer,
      $$PendingUploadsTableCreateCompanionBuilder,
      $$PendingUploadsTableUpdateCompanionBuilder,
      (
        PendingUpload,
        BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUpload>,
      ),
      PendingUpload,
      PrefetchHooks Function()
    >;
typedef $$LocalTheoryChaptersTableCreateCompanionBuilder =
    LocalTheoryChaptersCompanion Function({
      Value<int> id,
      Value<int?> relatedQuizTopicId,
      required String nameIt,
      Value<String?> nameEn,
      Value<String?> nameBn,
      Value<String?> imageUrl,
      required int displayOrder,
      required DateTime createdAt,
    });
typedef $$LocalTheoryChaptersTableUpdateCompanionBuilder =
    LocalTheoryChaptersCompanion Function({
      Value<int> id,
      Value<int?> relatedQuizTopicId,
      Value<String> nameIt,
      Value<String?> nameEn,
      Value<String?> nameBn,
      Value<String?> imageUrl,
      Value<int> displayOrder,
      Value<DateTime> createdAt,
    });

class $$LocalTheoryChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTheoryChaptersTable> {
  $$LocalTheoryChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relatedQuizTopicId => $composableBuilder(
    column: $table.relatedQuizTopicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTheoryChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTheoryChaptersTable> {
  $$LocalTheoryChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relatedQuizTopicId => $composableBuilder(
    column: $table.relatedQuizTopicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameIt => $composableBuilder(
    column: $table.nameIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameBn => $composableBuilder(
    column: $table.nameBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTheoryChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTheoryChaptersTable> {
  $$LocalTheoryChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get relatedQuizTopicId => $composableBuilder(
    column: $table.relatedQuizTopicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameIt =>
      $composableBuilder(column: $table.nameIt, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameBn =>
      $composableBuilder(column: $table.nameBn, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalTheoryChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTheoryChaptersTable,
          LocalTheoryChapter,
          $$LocalTheoryChaptersTableFilterComposer,
          $$LocalTheoryChaptersTableOrderingComposer,
          $$LocalTheoryChaptersTableAnnotationComposer,
          $$LocalTheoryChaptersTableCreateCompanionBuilder,
          $$LocalTheoryChaptersTableUpdateCompanionBuilder,
          (
            LocalTheoryChapter,
            BaseReferences<
              _$AppDatabase,
              $LocalTheoryChaptersTable,
              LocalTheoryChapter
            >,
          ),
          LocalTheoryChapter,
          PrefetchHooks Function()
        > {
  $$LocalTheoryChaptersTableTableManager(
    _$AppDatabase db,
    $LocalTheoryChaptersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTheoryChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTheoryChaptersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalTheoryChaptersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> relatedQuizTopicId = const Value.absent(),
                Value<String> nameIt = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                Value<String?> nameBn = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalTheoryChaptersCompanion(
                id: id,
                relatedQuizTopicId: relatedQuizTopicId,
                nameIt: nameIt,
                nameEn: nameEn,
                nameBn: nameBn,
                imageUrl: imageUrl,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> relatedQuizTopicId = const Value.absent(),
                required String nameIt,
                Value<String?> nameEn = const Value.absent(),
                Value<String?> nameBn = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                required int displayOrder,
                required DateTime createdAt,
              }) => LocalTheoryChaptersCompanion.insert(
                id: id,
                relatedQuizTopicId: relatedQuizTopicId,
                nameIt: nameIt,
                nameEn: nameEn,
                nameBn: nameBn,
                imageUrl: imageUrl,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTheoryChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTheoryChaptersTable,
      LocalTheoryChapter,
      $$LocalTheoryChaptersTableFilterComposer,
      $$LocalTheoryChaptersTableOrderingComposer,
      $$LocalTheoryChaptersTableAnnotationComposer,
      $$LocalTheoryChaptersTableCreateCompanionBuilder,
      $$LocalTheoryChaptersTableUpdateCompanionBuilder,
      (
        LocalTheoryChapter,
        BaseReferences<
          _$AppDatabase,
          $LocalTheoryChaptersTable,
          LocalTheoryChapter
        >,
      ),
      LocalTheoryChapter,
      PrefetchHooks Function()
    >;
typedef $$LocalTheoryCardsTableCreateCompanionBuilder =
    LocalTheoryCardsCompanion Function({
      Value<int> id,
      required int chapterId,
      Value<int?> subtopicId,
      Value<String?> titleIt,
      Value<String?> titleEn,
      Value<String?> titleBn,
      required String textIt,
      Value<String?> textEn,
      Value<String?> textBn,
      Value<String?> imageUrl,
      required int displayOrder,
      required DateTime createdAt,
    });
typedef $$LocalTheoryCardsTableUpdateCompanionBuilder =
    LocalTheoryCardsCompanion Function({
      Value<int> id,
      Value<int> chapterId,
      Value<int?> subtopicId,
      Value<String?> titleIt,
      Value<String?> titleEn,
      Value<String?> titleBn,
      Value<String> textIt,
      Value<String?> textEn,
      Value<String?> textBn,
      Value<String?> imageUrl,
      Value<int> displayOrder,
      Value<DateTime> createdAt,
    });

class $$LocalTheoryCardsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTheoryCardsTable> {
  $$LocalTheoryCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtopicId => $composableBuilder(
    column: $table.subtopicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleIt => $composableBuilder(
    column: $table.titleIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleBn => $composableBuilder(
    column: $table.titleBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textIt => $composableBuilder(
    column: $table.textIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textBn => $composableBuilder(
    column: $table.textBn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTheoryCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTheoryCardsTable> {
  $$LocalTheoryCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtopicId => $composableBuilder(
    column: $table.subtopicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleIt => $composableBuilder(
    column: $table.titleIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleBn => $composableBuilder(
    column: $table.titleBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textIt => $composableBuilder(
    column: $table.textIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textEn => $composableBuilder(
    column: $table.textEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textBn => $composableBuilder(
    column: $table.textBn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTheoryCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTheoryCardsTable> {
  $$LocalTheoryCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<int> get subtopicId => $composableBuilder(
    column: $table.subtopicId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleIt =>
      $composableBuilder(column: $table.titleIt, builder: (column) => column);

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get titleBn =>
      $composableBuilder(column: $table.titleBn, builder: (column) => column);

  GeneratedColumn<String> get textIt =>
      $composableBuilder(column: $table.textIt, builder: (column) => column);

  GeneratedColumn<String> get textEn =>
      $composableBuilder(column: $table.textEn, builder: (column) => column);

  GeneratedColumn<String> get textBn =>
      $composableBuilder(column: $table.textBn, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalTheoryCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTheoryCardsTable,
          LocalTheoryCard,
          $$LocalTheoryCardsTableFilterComposer,
          $$LocalTheoryCardsTableOrderingComposer,
          $$LocalTheoryCardsTableAnnotationComposer,
          $$LocalTheoryCardsTableCreateCompanionBuilder,
          $$LocalTheoryCardsTableUpdateCompanionBuilder,
          (
            LocalTheoryCard,
            BaseReferences<
              _$AppDatabase,
              $LocalTheoryCardsTable,
              LocalTheoryCard
            >,
          ),
          LocalTheoryCard,
          PrefetchHooks Function()
        > {
  $$LocalTheoryCardsTableTableManager(
    _$AppDatabase db,
    $LocalTheoryCardsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTheoryCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTheoryCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTheoryCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<int?> subtopicId = const Value.absent(),
                Value<String?> titleIt = const Value.absent(),
                Value<String?> titleEn = const Value.absent(),
                Value<String?> titleBn = const Value.absent(),
                Value<String> textIt = const Value.absent(),
                Value<String?> textEn = const Value.absent(),
                Value<String?> textBn = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalTheoryCardsCompanion(
                id: id,
                chapterId: chapterId,
                subtopicId: subtopicId,
                titleIt: titleIt,
                titleEn: titleEn,
                titleBn: titleBn,
                textIt: textIt,
                textEn: textEn,
                textBn: textBn,
                imageUrl: imageUrl,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int chapterId,
                Value<int?> subtopicId = const Value.absent(),
                Value<String?> titleIt = const Value.absent(),
                Value<String?> titleEn = const Value.absent(),
                Value<String?> titleBn = const Value.absent(),
                required String textIt,
                Value<String?> textEn = const Value.absent(),
                Value<String?> textBn = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                required int displayOrder,
                required DateTime createdAt,
              }) => LocalTheoryCardsCompanion.insert(
                id: id,
                chapterId: chapterId,
                subtopicId: subtopicId,
                titleIt: titleIt,
                titleEn: titleEn,
                titleBn: titleBn,
                textIt: textIt,
                textEn: textEn,
                textBn: textBn,
                imageUrl: imageUrl,
                displayOrder: displayOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTheoryCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTheoryCardsTable,
      LocalTheoryCard,
      $$LocalTheoryCardsTableFilterComposer,
      $$LocalTheoryCardsTableOrderingComposer,
      $$LocalTheoryCardsTableAnnotationComposer,
      $$LocalTheoryCardsTableCreateCompanionBuilder,
      $$LocalTheoryCardsTableUpdateCompanionBuilder,
      (
        LocalTheoryCard,
        BaseReferences<_$AppDatabase, $LocalTheoryCardsTable, LocalTheoryCard>,
      ),
      LocalTheoryCard,
      PrefetchHooks Function()
    >;
typedef $$TheoryProgressTableTableCreateCompanionBuilder =
    TheoryProgressTableCompanion Function({
      Value<int> id,
      required int chapterId,
      required int cardId,
      Value<bool> isRead,
      Value<DateTime?> lastReadAt,
    });
typedef $$TheoryProgressTableTableUpdateCompanionBuilder =
    TheoryProgressTableCompanion Function({
      Value<int> id,
      Value<int> chapterId,
      Value<int> cardId,
      Value<bool> isRead,
      Value<DateTime?> lastReadAt,
    });

class $$TheoryProgressTableTableFilterComposer
    extends Composer<_$AppDatabase, $TheoryProgressTableTable> {
  $$TheoryProgressTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TheoryProgressTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TheoryProgressTableTable> {
  $$TheoryProgressTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TheoryProgressTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TheoryProgressTableTable> {
  $$TheoryProgressTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );
}

class $$TheoryProgressTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TheoryProgressTableTable,
          TheoryProgress,
          $$TheoryProgressTableTableFilterComposer,
          $$TheoryProgressTableTableOrderingComposer,
          $$TheoryProgressTableTableAnnotationComposer,
          $$TheoryProgressTableTableCreateCompanionBuilder,
          $$TheoryProgressTableTableUpdateCompanionBuilder,
          (
            TheoryProgress,
            BaseReferences<
              _$AppDatabase,
              $TheoryProgressTableTable,
              TheoryProgress
            >,
          ),
          TheoryProgress,
          PrefetchHooks Function()
        > {
  $$TheoryProgressTableTableTableManager(
    _$AppDatabase db,
    $TheoryProgressTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TheoryProgressTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TheoryProgressTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TheoryProgressTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
              }) => TheoryProgressTableCompanion(
                id: id,
                chapterId: chapterId,
                cardId: cardId,
                isRead: isRead,
                lastReadAt: lastReadAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int chapterId,
                required int cardId,
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> lastReadAt = const Value.absent(),
              }) => TheoryProgressTableCompanion.insert(
                id: id,
                chapterId: chapterId,
                cardId: cardId,
                isRead: isRead,
                lastReadAt: lastReadAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TheoryProgressTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TheoryProgressTableTable,
      TheoryProgress,
      $$TheoryProgressTableTableFilterComposer,
      $$TheoryProgressTableTableOrderingComposer,
      $$TheoryProgressTableTableAnnotationComposer,
      $$TheoryProgressTableTableCreateCompanionBuilder,
      $$TheoryProgressTableTableUpdateCompanionBuilder,
      (
        TheoryProgress,
        BaseReferences<
          _$AppDatabase,
          $TheoryProgressTableTable,
          TheoryProgress
        >,
      ),
      TheoryProgress,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalCategoriesTableTableManager get localCategories =>
      $$LocalCategoriesTableTableManager(_db, _db.localCategories);
  $$LocalTopicsTableTableManager get localTopics =>
      $$LocalTopicsTableTableManager(_db, _db.localTopics);
  $$LocalSubtopicsTableTableManager get localSubtopics =>
      $$LocalSubtopicsTableTableManager(_db, _db.localSubtopics);
  $$LocalQuestionsTableTableManager get localQuestions =>
      $$LocalQuestionsTableTableManager(_db, _db.localQuestions);
  $$PendingUploadsTableTableManager get pendingUploads =>
      $$PendingUploadsTableTableManager(_db, _db.pendingUploads);
  $$LocalTheoryChaptersTableTableManager get localTheoryChapters =>
      $$LocalTheoryChaptersTableTableManager(_db, _db.localTheoryChapters);
  $$LocalTheoryCardsTableTableManager get localTheoryCards =>
      $$LocalTheoryCardsTableTableManager(_db, _db.localTheoryCards);
  $$TheoryProgressTableTableTableManager get theoryProgressTable =>
      $$TheoryProgressTableTableTableManager(_db, _db.theoryProgressTable);
}
