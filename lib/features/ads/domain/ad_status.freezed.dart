// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ad_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdStatus {

 bool get adsEnabled;/// Vrai si aucune correction n'a encore été obtenue par vidéo aujourd'hui.
 bool get correctionRewardAvailable; bool get exercisesRewardAvailable;/// Unités obtenues par des vidéos et pas encore utilisées.
 int get rewardCorrections; int get rewardExercises;
/// Create a copy of AdStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdStatusCopyWith<AdStatus> get copyWith => _$AdStatusCopyWithImpl<AdStatus>(this as AdStatus, _$identity);

  /// Serializes this AdStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdStatus&&(identical(other.adsEnabled, adsEnabled) || other.adsEnabled == adsEnabled)&&(identical(other.correctionRewardAvailable, correctionRewardAvailable) || other.correctionRewardAvailable == correctionRewardAvailable)&&(identical(other.exercisesRewardAvailable, exercisesRewardAvailable) || other.exercisesRewardAvailable == exercisesRewardAvailable)&&(identical(other.rewardCorrections, rewardCorrections) || other.rewardCorrections == rewardCorrections)&&(identical(other.rewardExercises, rewardExercises) || other.rewardExercises == rewardExercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,adsEnabled,correctionRewardAvailable,exercisesRewardAvailable,rewardCorrections,rewardExercises);

@override
String toString() {
  return 'AdStatus(adsEnabled: $adsEnabled, correctionRewardAvailable: $correctionRewardAvailable, exercisesRewardAvailable: $exercisesRewardAvailable, rewardCorrections: $rewardCorrections, rewardExercises: $rewardExercises)';
}


}

/// @nodoc
abstract mixin class $AdStatusCopyWith<$Res>  {
  factory $AdStatusCopyWith(AdStatus value, $Res Function(AdStatus) _then) = _$AdStatusCopyWithImpl;
@useResult
$Res call({
 bool adsEnabled, bool correctionRewardAvailable, bool exercisesRewardAvailable, int rewardCorrections, int rewardExercises
});




}
/// @nodoc
class _$AdStatusCopyWithImpl<$Res>
    implements $AdStatusCopyWith<$Res> {
  _$AdStatusCopyWithImpl(this._self, this._then);

  final AdStatus _self;
  final $Res Function(AdStatus) _then;

/// Create a copy of AdStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? adsEnabled = null,Object? correctionRewardAvailable = null,Object? exercisesRewardAvailable = null,Object? rewardCorrections = null,Object? rewardExercises = null,}) {
  return _then(_self.copyWith(
adsEnabled: null == adsEnabled ? _self.adsEnabled : adsEnabled // ignore: cast_nullable_to_non_nullable
as bool,correctionRewardAvailable: null == correctionRewardAvailable ? _self.correctionRewardAvailable : correctionRewardAvailable // ignore: cast_nullable_to_non_nullable
as bool,exercisesRewardAvailable: null == exercisesRewardAvailable ? _self.exercisesRewardAvailable : exercisesRewardAvailable // ignore: cast_nullable_to_non_nullable
as bool,rewardCorrections: null == rewardCorrections ? _self.rewardCorrections : rewardCorrections // ignore: cast_nullable_to_non_nullable
as int,rewardExercises: null == rewardExercises ? _self.rewardExercises : rewardExercises // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AdStatus].
extension AdStatusPatterns on AdStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdStatus value)  $default,){
final _that = this;
switch (_that) {
case _AdStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AdStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool adsEnabled,  bool correctionRewardAvailable,  bool exercisesRewardAvailable,  int rewardCorrections,  int rewardExercises)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdStatus() when $default != null:
return $default(_that.adsEnabled,_that.correctionRewardAvailable,_that.exercisesRewardAvailable,_that.rewardCorrections,_that.rewardExercises);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool adsEnabled,  bool correctionRewardAvailable,  bool exercisesRewardAvailable,  int rewardCorrections,  int rewardExercises)  $default,) {final _that = this;
switch (_that) {
case _AdStatus():
return $default(_that.adsEnabled,_that.correctionRewardAvailable,_that.exercisesRewardAvailable,_that.rewardCorrections,_that.rewardExercises);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool adsEnabled,  bool correctionRewardAvailable,  bool exercisesRewardAvailable,  int rewardCorrections,  int rewardExercises)?  $default,) {final _that = this;
switch (_that) {
case _AdStatus() when $default != null:
return $default(_that.adsEnabled,_that.correctionRewardAvailable,_that.exercisesRewardAvailable,_that.rewardCorrections,_that.rewardExercises);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _AdStatus extends AdStatus {
  const _AdStatus({this.adsEnabled = false, this.correctionRewardAvailable = false, this.exercisesRewardAvailable = false, this.rewardCorrections = 0, this.rewardExercises = 0}): super._();
  factory _AdStatus.fromJson(Map<String, dynamic> json) => _$AdStatusFromJson(json);

@override@JsonKey() final  bool adsEnabled;
/// Vrai si aucune correction n'a encore été obtenue par vidéo aujourd'hui.
@override@JsonKey() final  bool correctionRewardAvailable;
@override@JsonKey() final  bool exercisesRewardAvailable;
/// Unités obtenues par des vidéos et pas encore utilisées.
@override@JsonKey() final  int rewardCorrections;
@override@JsonKey() final  int rewardExercises;

/// Create a copy of AdStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdStatusCopyWith<_AdStatus> get copyWith => __$AdStatusCopyWithImpl<_AdStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdStatus&&(identical(other.adsEnabled, adsEnabled) || other.adsEnabled == adsEnabled)&&(identical(other.correctionRewardAvailable, correctionRewardAvailable) || other.correctionRewardAvailable == correctionRewardAvailable)&&(identical(other.exercisesRewardAvailable, exercisesRewardAvailable) || other.exercisesRewardAvailable == exercisesRewardAvailable)&&(identical(other.rewardCorrections, rewardCorrections) || other.rewardCorrections == rewardCorrections)&&(identical(other.rewardExercises, rewardExercises) || other.rewardExercises == rewardExercises));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,adsEnabled,correctionRewardAvailable,exercisesRewardAvailable,rewardCorrections,rewardExercises);

@override
String toString() {
  return 'AdStatus(adsEnabled: $adsEnabled, correctionRewardAvailable: $correctionRewardAvailable, exercisesRewardAvailable: $exercisesRewardAvailable, rewardCorrections: $rewardCorrections, rewardExercises: $rewardExercises)';
}


}

/// @nodoc
abstract mixin class _$AdStatusCopyWith<$Res> implements $AdStatusCopyWith<$Res> {
  factory _$AdStatusCopyWith(_AdStatus value, $Res Function(_AdStatus) _then) = __$AdStatusCopyWithImpl;
@override @useResult
$Res call({
 bool adsEnabled, bool correctionRewardAvailable, bool exercisesRewardAvailable, int rewardCorrections, int rewardExercises
});




}
/// @nodoc
class __$AdStatusCopyWithImpl<$Res>
    implements _$AdStatusCopyWith<$Res> {
  __$AdStatusCopyWithImpl(this._self, this._then);

  final _AdStatus _self;
  final $Res Function(_AdStatus) _then;

/// Create a copy of AdStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? adsEnabled = null,Object? correctionRewardAvailable = null,Object? exercisesRewardAvailable = null,Object? rewardCorrections = null,Object? rewardExercises = null,}) {
  return _then(_AdStatus(
adsEnabled: null == adsEnabled ? _self.adsEnabled : adsEnabled // ignore: cast_nullable_to_non_nullable
as bool,correctionRewardAvailable: null == correctionRewardAvailable ? _self.correctionRewardAvailable : correctionRewardAvailable // ignore: cast_nullable_to_non_nullable
as bool,exercisesRewardAvailable: null == exercisesRewardAvailable ? _self.exercisesRewardAvailable : exercisesRewardAvailable // ignore: cast_nullable_to_non_nullable
as bool,rewardCorrections: null == rewardCorrections ? _self.rewardCorrections : rewardCorrections // ignore: cast_nullable_to_non_nullable
as int,rewardExercises: null == rewardExercises ? _self.rewardExercises : rewardExercises // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
