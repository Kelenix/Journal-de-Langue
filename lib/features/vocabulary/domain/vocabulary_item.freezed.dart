// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vocabulary_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VocabularyItem {

 String get id;/// Dans la langue apprise.
 String get term;/// Dans la langue de l'interface.
 String get translation;/// Phrase d'exemple dans la langue apprise.
 String get example;/// Null tant que le mot est à réviser.
 DateTime? get learnedAt;
/// Create a copy of VocabularyItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VocabularyItemCopyWith<VocabularyItem> get copyWith => _$VocabularyItemCopyWithImpl<VocabularyItem>(this as VocabularyItem, _$identity);

  /// Serializes this VocabularyItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VocabularyItem&&(identical(other.id, id) || other.id == id)&&(identical(other.term, term) || other.term == term)&&(identical(other.translation, translation) || other.translation == translation)&&(identical(other.example, example) || other.example == example)&&(identical(other.learnedAt, learnedAt) || other.learnedAt == learnedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,term,translation,example,learnedAt);

@override
String toString() {
  return 'VocabularyItem(id: $id, term: $term, translation: $translation, example: $example, learnedAt: $learnedAt)';
}


}

/// @nodoc
abstract mixin class $VocabularyItemCopyWith<$Res>  {
  factory $VocabularyItemCopyWith(VocabularyItem value, $Res Function(VocabularyItem) _then) = _$VocabularyItemCopyWithImpl;
@useResult
$Res call({
 String id, String term, String translation, String example, DateTime? learnedAt
});




}
/// @nodoc
class _$VocabularyItemCopyWithImpl<$Res>
    implements $VocabularyItemCopyWith<$Res> {
  _$VocabularyItemCopyWithImpl(this._self, this._then);

  final VocabularyItem _self;
  final $Res Function(VocabularyItem) _then;

/// Create a copy of VocabularyItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? term = null,Object? translation = null,Object? example = null,Object? learnedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,translation: null == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as String,example: null == example ? _self.example : example // ignore: cast_nullable_to_non_nullable
as String,learnedAt: freezed == learnedAt ? _self.learnedAt : learnedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VocabularyItem].
extension VocabularyItemPatterns on VocabularyItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VocabularyItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VocabularyItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VocabularyItem value)  $default,){
final _that = this;
switch (_that) {
case _VocabularyItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VocabularyItem value)?  $default,){
final _that = this;
switch (_that) {
case _VocabularyItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String term,  String translation,  String example,  DateTime? learnedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VocabularyItem() when $default != null:
return $default(_that.id,_that.term,_that.translation,_that.example,_that.learnedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String term,  String translation,  String example,  DateTime? learnedAt)  $default,) {final _that = this;
switch (_that) {
case _VocabularyItem():
return $default(_that.id,_that.term,_that.translation,_that.example,_that.learnedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String term,  String translation,  String example,  DateTime? learnedAt)?  $default,) {final _that = this;
switch (_that) {
case _VocabularyItem() when $default != null:
return $default(_that.id,_that.term,_that.translation,_that.example,_that.learnedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _VocabularyItem implements VocabularyItem {
  const _VocabularyItem({required this.id, required this.term, required this.translation, required this.example, this.learnedAt});
  factory _VocabularyItem.fromJson(Map<String, dynamic> json) => _$VocabularyItemFromJson(json);

@override final  String id;
/// Dans la langue apprise.
@override final  String term;
/// Dans la langue de l'interface.
@override final  String translation;
/// Phrase d'exemple dans la langue apprise.
@override final  String example;
/// Null tant que le mot est à réviser.
@override final  DateTime? learnedAt;

/// Create a copy of VocabularyItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VocabularyItemCopyWith<_VocabularyItem> get copyWith => __$VocabularyItemCopyWithImpl<_VocabularyItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VocabularyItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VocabularyItem&&(identical(other.id, id) || other.id == id)&&(identical(other.term, term) || other.term == term)&&(identical(other.translation, translation) || other.translation == translation)&&(identical(other.example, example) || other.example == example)&&(identical(other.learnedAt, learnedAt) || other.learnedAt == learnedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,term,translation,example,learnedAt);

@override
String toString() {
  return 'VocabularyItem(id: $id, term: $term, translation: $translation, example: $example, learnedAt: $learnedAt)';
}


}

/// @nodoc
abstract mixin class _$VocabularyItemCopyWith<$Res> implements $VocabularyItemCopyWith<$Res> {
  factory _$VocabularyItemCopyWith(_VocabularyItem value, $Res Function(_VocabularyItem) _then) = __$VocabularyItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String term, String translation, String example, DateTime? learnedAt
});




}
/// @nodoc
class __$VocabularyItemCopyWithImpl<$Res>
    implements _$VocabularyItemCopyWith<$Res> {
  __$VocabularyItemCopyWithImpl(this._self, this._then);

  final _VocabularyItem _self;
  final $Res Function(_VocabularyItem) _then;

/// Create a copy of VocabularyItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? term = null,Object? translation = null,Object? example = null,Object? learnedAt = freezed,}) {
  return _then(_VocabularyItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,translation: null == translation ? _self.translation : translation // ignore: cast_nullable_to_non_nullable
as String,example: null == example ? _self.example : example // ignore: cast_nullable_to_non_nullable
as String,learnedAt: freezed == learnedAt ? _self.learnedAt : learnedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
