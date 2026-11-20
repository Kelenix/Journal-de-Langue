// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Wallet {

 int get correctionCredits; int get examCredits; bool get adsRemoved;/// Accès de 30 jours en cours, du plus proche de sa fin au plus lointain.
 List<LanguagePass> get languagePasses;
/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletCopyWith<Wallet> get copyWith => _$WalletCopyWithImpl<Wallet>(this as Wallet, _$identity);

  /// Serializes this Wallet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Wallet&&(identical(other.correctionCredits, correctionCredits) || other.correctionCredits == correctionCredits)&&(identical(other.examCredits, examCredits) || other.examCredits == examCredits)&&(identical(other.adsRemoved, adsRemoved) || other.adsRemoved == adsRemoved)&&const DeepCollectionEquality().equals(other.languagePasses, languagePasses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,correctionCredits,examCredits,adsRemoved,const DeepCollectionEquality().hash(languagePasses));

@override
String toString() {
  return 'Wallet(correctionCredits: $correctionCredits, examCredits: $examCredits, adsRemoved: $adsRemoved, languagePasses: $languagePasses)';
}


}

/// @nodoc
abstract mixin class $WalletCopyWith<$Res>  {
  factory $WalletCopyWith(Wallet value, $Res Function(Wallet) _then) = _$WalletCopyWithImpl;
@useResult
$Res call({
 int correctionCredits, int examCredits, bool adsRemoved, List<LanguagePass> languagePasses
});




}
/// @nodoc
class _$WalletCopyWithImpl<$Res>
    implements $WalletCopyWith<$Res> {
  _$WalletCopyWithImpl(this._self, this._then);

  final Wallet _self;
  final $Res Function(Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? correctionCredits = null,Object? examCredits = null,Object? adsRemoved = null,Object? languagePasses = null,}) {
  return _then(_self.copyWith(
correctionCredits: null == correctionCredits ? _self.correctionCredits : correctionCredits // ignore: cast_nullable_to_non_nullable
as int,examCredits: null == examCredits ? _self.examCredits : examCredits // ignore: cast_nullable_to_non_nullable
as int,adsRemoved: null == adsRemoved ? _self.adsRemoved : adsRemoved // ignore: cast_nullable_to_non_nullable
as bool,languagePasses: null == languagePasses ? _self.languagePasses : languagePasses // ignore: cast_nullable_to_non_nullable
as List<LanguagePass>,
  ));
}

}


/// Adds pattern-matching-related methods to [Wallet].
extension WalletPatterns on Wallet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Wallet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Wallet value)  $default,){
final _that = this;
switch (_that) {
case _Wallet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Wallet value)?  $default,){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int correctionCredits,  int examCredits,  bool adsRemoved,  List<LanguagePass> languagePasses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.correctionCredits,_that.examCredits,_that.adsRemoved,_that.languagePasses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int correctionCredits,  int examCredits,  bool adsRemoved,  List<LanguagePass> languagePasses)  $default,) {final _that = this;
switch (_that) {
case _Wallet():
return $default(_that.correctionCredits,_that.examCredits,_that.adsRemoved,_that.languagePasses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int correctionCredits,  int examCredits,  bool adsRemoved,  List<LanguagePass> languagePasses)?  $default,) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.correctionCredits,_that.examCredits,_that.adsRemoved,_that.languagePasses);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Wallet extends Wallet {
  const _Wallet({this.correctionCredits = 0, this.examCredits = 0, this.adsRemoved = false, final  List<LanguagePass> languagePasses = const <LanguagePass>[]}): _languagePasses = languagePasses,super._();
  factory _Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

@override@JsonKey() final  int correctionCredits;
@override@JsonKey() final  int examCredits;
@override@JsonKey() final  bool adsRemoved;
/// Accès de 30 jours en cours, du plus proche de sa fin au plus lointain.
 final  List<LanguagePass> _languagePasses;
/// Accès de 30 jours en cours, du plus proche de sa fin au plus lointain.
@override@JsonKey() List<LanguagePass> get languagePasses {
  if (_languagePasses is EqualUnmodifiableListView) return _languagePasses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_languagePasses);
}


/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletCopyWith<_Wallet> get copyWith => __$WalletCopyWithImpl<_Wallet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Wallet&&(identical(other.correctionCredits, correctionCredits) || other.correctionCredits == correctionCredits)&&(identical(other.examCredits, examCredits) || other.examCredits == examCredits)&&(identical(other.adsRemoved, adsRemoved) || other.adsRemoved == adsRemoved)&&const DeepCollectionEquality().equals(other._languagePasses, _languagePasses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,correctionCredits,examCredits,adsRemoved,const DeepCollectionEquality().hash(_languagePasses));

@override
String toString() {
  return 'Wallet(correctionCredits: $correctionCredits, examCredits: $examCredits, adsRemoved: $adsRemoved, languagePasses: $languagePasses)';
}


}

/// @nodoc
abstract mixin class _$WalletCopyWith<$Res> implements $WalletCopyWith<$Res> {
  factory _$WalletCopyWith(_Wallet value, $Res Function(_Wallet) _then) = __$WalletCopyWithImpl;
@override @useResult
$Res call({
 int correctionCredits, int examCredits, bool adsRemoved, List<LanguagePass> languagePasses
});




}
/// @nodoc
class __$WalletCopyWithImpl<$Res>
    implements _$WalletCopyWith<$Res> {
  __$WalletCopyWithImpl(this._self, this._then);

  final _Wallet _self;
  final $Res Function(_Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? correctionCredits = null,Object? examCredits = null,Object? adsRemoved = null,Object? languagePasses = null,}) {
  return _then(_Wallet(
correctionCredits: null == correctionCredits ? _self.correctionCredits : correctionCredits // ignore: cast_nullable_to_non_nullable
as int,examCredits: null == examCredits ? _self.examCredits : examCredits // ignore: cast_nullable_to_non_nullable
as int,adsRemoved: null == adsRemoved ? _self.adsRemoved : adsRemoved // ignore: cast_nullable_to_non_nullable
as bool,languagePasses: null == languagePasses ? _self._languagePasses : languagePasses // ignore: cast_nullable_to_non_nullable
as List<LanguagePass>,
  ));
}


}


/// @nodoc
mixin _$LanguagePass {

 LearningLanguage get language; DateTime get expiresAt;
/// Create a copy of LanguagePass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguagePassCopyWith<LanguagePass> get copyWith => _$LanguagePassCopyWithImpl<LanguagePass>(this as LanguagePass, _$identity);

  /// Serializes this LanguagePass to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LanguagePass&&(identical(other.language, language) || other.language == language)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,expiresAt);

@override
String toString() {
  return 'LanguagePass(language: $language, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $LanguagePassCopyWith<$Res>  {
  factory $LanguagePassCopyWith(LanguagePass value, $Res Function(LanguagePass) _then) = _$LanguagePassCopyWithImpl;
@useResult
$Res call({
 LearningLanguage language, DateTime expiresAt
});




}
/// @nodoc
class _$LanguagePassCopyWithImpl<$Res>
    implements $LanguagePassCopyWith<$Res> {
  _$LanguagePassCopyWithImpl(this._self, this._then);

  final LanguagePass _self;
  final $Res Function(LanguagePass) _then;

/// Create a copy of LanguagePass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as LearningLanguage,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LanguagePass].
extension LanguagePassPatterns on LanguagePass {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LanguagePass value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LanguagePass() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LanguagePass value)  $default,){
final _that = this;
switch (_that) {
case _LanguagePass():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LanguagePass value)?  $default,){
final _that = this;
switch (_that) {
case _LanguagePass() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LearningLanguage language,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LanguagePass() when $default != null:
return $default(_that.language,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LearningLanguage language,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _LanguagePass():
return $default(_that.language,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LearningLanguage language,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _LanguagePass() when $default != null:
return $default(_that.language,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _LanguagePass implements LanguagePass {
  const _LanguagePass({required this.language, required this.expiresAt});
  factory _LanguagePass.fromJson(Map<String, dynamic> json) => _$LanguagePassFromJson(json);

@override final  LearningLanguage language;
@override final  DateTime expiresAt;

/// Create a copy of LanguagePass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanguagePassCopyWith<_LanguagePass> get copyWith => __$LanguagePassCopyWithImpl<_LanguagePass>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LanguagePassToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LanguagePass&&(identical(other.language, language) || other.language == language)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,expiresAt);

@override
String toString() {
  return 'LanguagePass(language: $language, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$LanguagePassCopyWith<$Res> implements $LanguagePassCopyWith<$Res> {
  factory _$LanguagePassCopyWith(_LanguagePass value, $Res Function(_LanguagePass) _then) = __$LanguagePassCopyWithImpl;
@override @useResult
$Res call({
 LearningLanguage language, DateTime expiresAt
});




}
/// @nodoc
class __$LanguagePassCopyWithImpl<$Res>
    implements _$LanguagePassCopyWith<$Res> {
  __$LanguagePassCopyWithImpl(this._self, this._then);

  final _LanguagePass _self;
  final $Res Function(_LanguagePass) _then;

/// Create a copy of LanguagePass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? expiresAt = null,}) {
  return _then(_LanguagePass(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as LearningLanguage,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
