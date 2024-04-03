// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTestCollection on Isar {
  IsarCollection<Test> get tests => this.collection();
}

const TestSchema = CollectionSchema(
  name: r'Test',
  id: -5479267249076327074,
  properties: {
    r'createdTime': PropertySchema(
      id: 0,
      name: r'createdTime',
      type: IsarType.dateTime,
    ),
    r'updatedTime': PropertySchema(
      id: 1,
      name: r'updatedTime',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _testEstimateSize,
  serialize: _testSerialize,
  deserialize: _testDeserialize,
  deserializeProp: _testDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _testGetId,
  getLinks: _testGetLinks,
  attach: _testAttach,
  version: '3.1.0+1',
);

int _testEstimateSize(
  Test object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _testSerialize(
  Test object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdTime);
  writer.writeDateTime(offsets[1], object.updatedTime);
}

Test _testDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Test();
  object.createdTime = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.updatedTime = reader.readDateTimeOrNull(offsets[1]);
  return object;
}

P _testDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _testGetId(Test object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _testGetLinks(Test object) {
  return [];
}

void _testAttach(IsarCollection<dynamic> col, Id id, Test object) {
  object.id = id;
}

extension TestQueryWhereSort on QueryBuilder<Test, Test, QWhere> {
  QueryBuilder<Test, Test, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TestQueryWhere on QueryBuilder<Test, Test, QWhereClause> {
  QueryBuilder<Test, Test, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Test, Test, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Test, Test, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Test, Test, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TestQueryFilter on QueryBuilder<Test, Test, QFilterCondition> {
  QueryBuilder<Test, Test, QAfterFilterCondition> createdTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdTime',
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> createdTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdTime',
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> createdTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> createdTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> createdTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> createdTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> updatedTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedTime',
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> updatedTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedTime',
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> updatedTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> updatedTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> updatedTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedTime',
        value: value,
      ));
    });
  }

  QueryBuilder<Test, Test, QAfterFilterCondition> updatedTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TestQueryObject on QueryBuilder<Test, Test, QFilterCondition> {}

extension TestQueryLinks on QueryBuilder<Test, Test, QFilterCondition> {}

extension TestQuerySortBy on QueryBuilder<Test, Test, QSortBy> {
  QueryBuilder<Test, Test, QAfterSortBy> sortByCreatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.asc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> sortByCreatedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.desc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> sortByUpdatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTime', Sort.asc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> sortByUpdatedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTime', Sort.desc);
    });
  }
}

extension TestQuerySortThenBy on QueryBuilder<Test, Test, QSortThenBy> {
  QueryBuilder<Test, Test, QAfterSortBy> thenByCreatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.asc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> thenByCreatedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdTime', Sort.desc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> thenByUpdatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTime', Sort.asc);
    });
  }

  QueryBuilder<Test, Test, QAfterSortBy> thenByUpdatedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedTime', Sort.desc);
    });
  }
}

extension TestQueryWhereDistinct on QueryBuilder<Test, Test, QDistinct> {
  QueryBuilder<Test, Test, QDistinct> distinctByCreatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdTime');
    });
  }

  QueryBuilder<Test, Test, QDistinct> distinctByUpdatedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedTime');
    });
  }
}

extension TestQueryProperty on QueryBuilder<Test, Test, QQueryProperty> {
  QueryBuilder<Test, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Test, DateTime?, QQueryOperations> createdTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdTime');
    });
  }

  QueryBuilder<Test, DateTime?, QQueryOperations> updatedTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedTime');
    });
  }
}
