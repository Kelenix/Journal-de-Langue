// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'learning_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LearningStats {

 bool get isPremium;/// Jours consécutifs avec un journal corrigé, toutes langues confondues,
/// jusqu'à aujourd'hui ou hier.
 int get streakDays;/// Journaux corrigés dans cette langue.
 int get journals;/// Jours de la semaine en cours (du lundi à aujourd'hui) avec un journal
/// corrigé, toutes langues confondues.
 List<DateTime> get weekDays; int? get wordsLearned; int? get wordsTotal;/// Du type de faute le plus fréquent au moins fréquent.
 List<CategoryCount> get mistakesByCategory;/// Journaux corrigés de la langue par semaine, sur les 8 dernières, de la
/// plus ancienne à la plus récente ; une semaine sans journal est absente.
 List<WeeklyJournals> get weeklyJournals;
/// Create a copy of LearningStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LearningStatsCopyWith<LearningStats> get copyWith => _$LearningStatsCopyWithImpl<LearningStats>(this as LearningStats, _$identity);

  /// Serializes this LearningStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LearningStats&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&(identical(other.journals, journals) || other.journals == journals)&&const DeepCollectionEquality().equals(other.weekDays, weekDays)&&(identical(other.wordsLearned, wordsLearned) || other.wordsLearned == wordsLearned)&&(identical(other.wordsTotal, wordsTotal) || other.wordsTotal == wordsTotal)&&const DeepCollectionEquality().equals(other.mistakesByCategory, mistakesByCategory)&&const DeepCollectionEquality().equals(other.weeklyJournals, weeklyJournals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPremium,streakDays,journals,const DeepCollectionEquality().hash(weekDays),wordsLearned,wordsTotal,const DeepCollectionEquality().hash(mistakesByCategory),const DeepCollectionEquality().hash(weeklyJournals));

@override
String toString() {
  return 'LearningStats(isPremium: $isPremium, streakDays: $streakDays, journals: $journals, weekDays: $weekDays, wordsLearned: $wordsLearned, wordsTotal: $wordsTotal, mistakesByCategory: $mistakesByCategory, weeklyJournals: $weeklyJournals)';
}


}

/// @nodoc
abstract mixin class $LearningStatsCopyWith<$Res>  {
  factory $LearningStatsCopyWith(LearningStats value, $Res Function(LearningStats) _then) = _$LearningStatsCopyWithImpl;
@useResult
$Res call({
 bool isPremium, int streakDays, int journals, List<DateTime> weekDays, int? wordsLearned, int? wordsTotal, List<CategoryCount> mistakesByCategory, List<WeeklyJournals> weeklyJournals
});




}
/// @nodoc
class _$LearningStatsCopyWithImpl<$Res>
    implements $LearningStatsCopyWith<$Res> {
  _$LearningStatsCopyWithImpl(this._self, this._then);

  final LearningStats _self;
  final $Res Function(LearningStats) _then;

/// Create a copy of LearningStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPremium = null,Object? streakDays = null,Object? journals = null,Object? weekDays = null,Object? wordsLearned = freezed,Object? wordsTotal = freezed,Object? mistakesByCategory = null,Object? weeklyJournals = null,}) {
  return _then(_self.copyWith(
isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,journals: null == journals ? _self.journals : journals // ignore: cast_nullable_to_non_nullable
as int,weekDays: null == weekDays ? _self.weekDays : weekDays // ignore: cast_nullable_to_non_nullable
as List<DateTime>,wordsLearned: freezed == wordsLearned ? _self.wordsLearned : wordsLearned // ignore: cast_nullable_to_non_nullable
as int?,wordsTotal: freezed == wordsTotal ? _self.wordsTotal : wordsTotal // ignore: cast_nullable_to_non_nullable
as int?,mistakesByCategory: null == mistakesByCategory ? _self.mistakesByCategory : mistakesByCategory // ignore: cast_nullable_to_non_nullable
as List<CategoryCount>,weeklyJournals: null == weeklyJournals ? _self.weeklyJournals : weeklyJournals // ignore: cast_nullable_to_non_nullable
as List<WeeklyJournals>,
  ));
}

}


/// Adds pattern-matching-related methods to [LearningStats].
extension LearningStatsPatterns on LearningStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LearningStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LearningStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LearningStats value)  $default,){
final _that = this;
switch (_that) {
case _LearningStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LearningStats value)?  $default,){
final _that = this;
switch (_that) {
case _LearningStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isPremium,  int streakDays,  int journals,  List<DateTime> weekDays,  int? wordsLearned,  int? wordsTotal,  List<CategoryCount> mistakesByCategory,  List<WeeklyJournals> weeklyJournals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LearningStats() when $default != null:
return $default(_that.isPremium,_that.streakDays,_that.journals,_that.weekDays,_that.wordsLearned,_that.wordsTotal,_that.mistakesByCategory,_that.weeklyJournals);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isPremium,  int streakDays,  int journals,  List<DateTime> weekDays,  int? wordsLearned,  int? wordsTotal,  List<CategoryCount> mistakesByCategory,  List<WeeklyJournals> weeklyJournals)  $default,) {final _that = this;
switch (_that) {
case _LearningStats():
return $default(_that.isPremium,_that.streakDays,_that.journals,_that.weekDays,_that.wordsLearned,_that.wordsTotal,_that.mistakesByCategory,_that.weeklyJournals);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isPremium,  int streakDays,  int journals,  List<DateTime> weekDays,  int? wordsLearned,  int? wordsTotal,  List<CategoryCount> mistakesByCategory,  List<WeeklyJournals> weeklyJournals)?  $default,) {final _that = this;
switch (_that) {
case _LearningStats() when $default != null:
return $default(_that.isPremium,_that.streakDays,_that.journals,_that.weekDays,_that.wordsLearned,_that.wordsTotal,_that.mistakesByCategory,_that.weeklyJournals);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _LearningStats implements LearningStats {
  const _LearningStats({required this.isPremium, required this.streakDays, required this.journals, final  List<DateTime> weekDays = const <DateTime>[], this.wordsLearned, this.wordsTotal, final  List<CategoryCount> mistakesByCategory = const <CategoryCount>[], final  List<WeeklyJournals> weeklyJournals = const <WeeklyJournals>[]}): _weekDays = weekDays,_mistakesByCategory = mistakesByCategory,_weeklyJournals = weeklyJournals;
  factory _LearningStats.fromJson(Map<String, dynamic> json) => _$LearningStatsFromJson(json);

@override final  bool isPremium;
/// Jours consécutifs avec un journal corrigé, toutes langues confondues,
/// jusqu'à aujourd'hui ou hier.
@override final  int streakDays;
/// Journaux corrigés dans cette langue.
@override final  int journals;
/// Jours de la semaine en cours (du lundi à aujourd'hui) avec un journal
/// corrigé, toutes langues confondues.
 final  List<DateTime> _weekDays;
/// Jours de la semaine en cours (du lundi à aujourd'hui) avec un journal
/// corrigé, toutes langues confondues.
@override@JsonKey() List<DateTime> get weekDays {
  if (_weekDays is EqualUnmodifiableListView) return _weekDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekDays);
}

@override final  int? wordsLearned;
@override final  int? wordsTotal;
/// Du type de faute le plus fréquent au moins fréquent.
 final  List<CategoryCount> _mistakesByCategory;
/// Du type de faute le plus fréquent au moins fréquent.
@override@JsonKey() List<CategoryCount> get mistakesByCategory {
  if (_mistakesByCategory is EqualUnmodifiableListView) return _mistakesByCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mistakesByCategory);
}

/// Journaux corrigés de la langue par semaine, sur les 8 dernières, de la
/// plus ancienne à la plus récente ; une semaine sans journal est absente.
 final  List<WeeklyJournals> _weeklyJournals;
/// Journaux corrigés de la langue par semaine, sur les 8 dernières, de la
/// plus ancienne à la plus récente ; une semaine sans journal est absente.
@override@JsonKey() List<WeeklyJournals> get weeklyJournals {
  if (_weeklyJournals is EqualUnmodifiableListView) return _weeklyJournals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weeklyJournals);
}


/// Create a copy of LearningStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LearningStatsCopyWith<_LearningStats> get copyWith => __$LearningStatsCopyWithImpl<_LearningStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LearningStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LearningStats&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.streakDays, streakDays) || other.streakDays == streakDays)&&(identical(other.journals, journals) || other.journals == journals)&&const DeepCollectionEquality().equals(other._weekDays, _weekDays)&&(identical(other.wordsLearned, wordsLearned) || other.wordsLearned == wordsLearned)&&(identical(other.wordsTotal, wordsTotal) || other.wordsTotal == wordsTotal)&&const DeepCollectionEquality().equals(other._mistakesByCategory, _mistakesByCategory)&&const DeepCollectionEquality().equals(other._weeklyJournals, _weeklyJournals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPremium,streakDays,journals,const DeepCollectionEquality().hash(_weekDays),wordsLearned,wordsTotal,const DeepCollectionEquality().hash(_mistakesByCategory),const DeepCollectionEquality().hash(_weeklyJournals));

@override
String toString() {
  return 'LearningStats(isPremium: $isPremium, streakDays: $streakDays, journals: $journals, weekDays: $weekDays, wordsLearned: $wordsLearned, wordsTotal: $wordsTotal, mistakesByCategory: $mistakesByCategory, weeklyJournals: $weeklyJournals)';
}


}

/// @nodoc
abstract mixin class _$LearningStatsCopyWith<$Res> implements $LearningStatsCopyWith<$Res> {
  factory _$LearningStatsCopyWith(_LearningStats value, $Res Function(_LearningStats) _then) = __$LearningStatsCopyWithImpl;
@override @useResult
$Res call({
 bool isPremium, int streakDays, int journals, List<DateTime> weekDays, int? wordsLearned, int? wordsTotal, List<CategoryCount> mistakesByCategory, List<WeeklyJournals> weeklyJournals
});




}
/// @nodoc
class __$LearningStatsCopyWithImpl<$Res>
    implements _$LearningStatsCopyWith<$Res> {
  __$LearningStatsCopyWithImpl(this._self, this._then);

  final _LearningStats _self;
  final $Res Function(_LearningStats) _then;

/// Create a copy of LearningStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isPremium = null,Object? streakDays = null,Object? journals = null,Object? weekDays = null,Object? wordsLearned = freezed,Object? wordsTotal = freezed,Object? mistakesByCategory = null,Object? weeklyJournals = null,}) {
  return _then(_LearningStats(
isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,streakDays: null == streakDays ? _self.streakDays : streakDays // ignore: cast_nullable_to_non_nullable
as int,journals: null == journals ? _self.journals : journals // ignore: cast_nullable_to_non_nullable
as int,weekDays: null == weekDays ? _self._weekDays : weekDays // ignore: cast_nullable_to_non_nullable
as List<DateTime>,wordsLearned: freezed == wordsLearned ? _self.wordsLearned : wordsLearned // ignore: cast_nullable_to_non_nullable
as int?,wordsTotal: freezed == wordsTotal ? _self.wordsTotal : wordsTotal // ignore: cast_nullable_to_non_nullable
as int?,mistakesByCategory: null == mistakesByCategory ? _self._mistakesByCategory : mistakesByCategory // ignore: cast_nullable_to_non_nullable
as List<CategoryCount>,weeklyJournals: null == weeklyJournals ? _self._weeklyJournals : weeklyJournals // ignore: cast_nullable_to_non_nullable
as List<WeeklyJournals>,
  ));
}


}


/// @nodoc
mixin _$CategoryCount {

 ErrorCategory get category; int get count;
/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryCountCopyWith<CategoryCount> get copyWith => _$CategoryCountCopyWithImpl<CategoryCount>(this as CategoryCount, _$identity);

  /// Serializes this CategoryCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryCount&&(identical(other.category, category) || other.category == category)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,count);

@override
String toString() {
  return 'CategoryCount(category: $category, count: $count)';
}


}

/// @nodoc
abstract mixin class $CategoryCountCopyWith<$Res>  {
  factory $CategoryCountCopyWith(CategoryCount value, $Res Function(CategoryCount) _then) = _$CategoryCountCopyWithImpl;
@useResult
$Res call({
 ErrorCategory category, int count
});




}
/// @nodoc
class _$CategoryCountCopyWithImpl<$Res>
    implements $CategoryCountCopyWith<$Res> {
  _$CategoryCountCopyWithImpl(this._self, this._then);

  final CategoryCount _self;
  final $Res Function(CategoryCount) _then;

/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? count = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ErrorCategory,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryCount].
extension CategoryCountPatterns on CategoryCount {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryCount value)  $default,){
final _that = this;
switch (_that) {
case _CategoryCount():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryCount value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ErrorCategory category,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
return $default(_that.category,_that.count);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ErrorCategory category,  int count)  $default,) {final _that = this;
switch (_that) {
case _CategoryCount():
return $default(_that.category,_that.count);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ErrorCategory category,  int count)?  $default,) {final _that = this;
switch (_that) {
case _CategoryCount() when $default != null:
return $default(_that.category,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryCount implements CategoryCount {
  const _CategoryCount({required this.category, required this.count});
  factory _CategoryCount.fromJson(Map<String, dynamic> json) => _$CategoryCountFromJson(json);

@override final  ErrorCategory category;
@override final  int count;

/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryCountCopyWith<_CategoryCount> get copyWith => __$CategoryCountCopyWithImpl<_CategoryCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryCount&&(identical(other.category, category) || other.category == category)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,count);

@override
String toString() {
  return 'CategoryCount(category: $category, count: $count)';
}


}

/// @nodoc
abstract mixin class _$CategoryCountCopyWith<$Res> implements $CategoryCountCopyWith<$Res> {
  factory _$CategoryCountCopyWith(_CategoryCount value, $Res Function(_CategoryCount) _then) = __$CategoryCountCopyWithImpl;
@override @useResult
$Res call({
 ErrorCategory category, int count
});




}
/// @nodoc
class __$CategoryCountCopyWithImpl<$Res>
    implements _$CategoryCountCopyWith<$Res> {
  __$CategoryCountCopyWithImpl(this._self, this._then);

  final _CategoryCount _self;
  final $Res Function(_CategoryCount) _then;

/// Create a copy of CategoryCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? count = null,}) {
  return _then(_CategoryCount(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ErrorCategory,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WeeklyJournals {

/// Lundi de la semaine.
 DateTime get weekStart; int get journals;
/// Create a copy of WeeklyJournals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyJournalsCopyWith<WeeklyJournals> get copyWith => _$WeeklyJournalsCopyWithImpl<WeeklyJournals>(this as WeeklyJournals, _$identity);

  /// Serializes this WeeklyJournals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyJournals&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.journals, journals) || other.journals == journals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,journals);

@override
String toString() {
  return 'WeeklyJournals(weekStart: $weekStart, journals: $journals)';
}


}

/// @nodoc
abstract mixin class $WeeklyJournalsCopyWith<$Res>  {
  factory $WeeklyJournalsCopyWith(WeeklyJournals value, $Res Function(WeeklyJournals) _then) = _$WeeklyJournalsCopyWithImpl;
@useResult
$Res call({
 DateTime weekStart, int journals
});




}
/// @nodoc
class _$WeeklyJournalsCopyWithImpl<$Res>
    implements $WeeklyJournalsCopyWith<$Res> {
  _$WeeklyJournalsCopyWithImpl(this._self, this._then);

  final WeeklyJournals _self;
  final $Res Function(WeeklyJournals) _then;

/// Create a copy of WeeklyJournals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekStart = null,Object? journals = null,}) {
  return _then(_self.copyWith(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,journals: null == journals ? _self.journals : journals // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyJournals].
extension WeeklyJournalsPatterns on WeeklyJournals {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyJournals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyJournals() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyJournals value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyJournals():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyJournals value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyJournals() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime weekStart,  int journals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyJournals() when $default != null:
return $default(_that.weekStart,_that.journals);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime weekStart,  int journals)  $default,) {final _that = this;
switch (_that) {
case _WeeklyJournals():
return $default(_that.weekStart,_that.journals);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime weekStart,  int journals)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyJournals() when $default != null:
return $default(_that.weekStart,_that.journals);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _WeeklyJournals implements WeeklyJournals {
  const _WeeklyJournals({required this.weekStart, required this.journals});
  factory _WeeklyJournals.fromJson(Map<String, dynamic> json) => _$WeeklyJournalsFromJson(json);

/// Lundi de la semaine.
@override final  DateTime weekStart;
@override final  int journals;

/// Create a copy of WeeklyJournals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyJournalsCopyWith<_WeeklyJournals> get copyWith => __$WeeklyJournalsCopyWithImpl<_WeeklyJournals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyJournalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyJournals&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.journals, journals) || other.journals == journals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,journals);

@override
String toString() {
  return 'WeeklyJournals(weekStart: $weekStart, journals: $journals)';
}


}

/// @nodoc
abstract mixin class _$WeeklyJournalsCopyWith<$Res> implements $WeeklyJournalsCopyWith<$Res> {
  factory _$WeeklyJournalsCopyWith(_WeeklyJournals value, $Res Function(_WeeklyJournals) _then) = __$WeeklyJournalsCopyWithImpl;
@override @useResult
$Res call({
 DateTime weekStart, int journals
});




}
/// @nodoc
class __$WeeklyJournalsCopyWithImpl<$Res>
    implements _$WeeklyJournalsCopyWith<$Res> {
  __$WeeklyJournalsCopyWithImpl(this._self, this._then);

  final _WeeklyJournals _self;
  final $Res Function(_WeeklyJournals) _then;

/// Create a copy of WeeklyJournals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekStart = null,Object? journals = null,}) {
  return _then(_WeeklyJournals(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as DateTime,journals: null == journals ? _self.journals : journals // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
