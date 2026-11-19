// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Offer {

 SubscriptionPlan get plan;/// Prix de la période, déjà mis en forme par le store (« 29,99 € »).
 String get priceLabel; double get price;/// Code ISO de la devise (« EUR »).
 String get currencyCode;/// Durée de l'essai gratuit ; `null` si l'utilisateur n'y a pas droit.
 int? get trialDays;
/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfferCopyWith<Offer> get copyWith => _$OfferCopyWithImpl<Offer>(this as Offer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Offer&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.priceLabel, priceLabel) || other.priceLabel == priceLabel)&&(identical(other.price, price) || other.price == price)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays));
}


@override
int get hashCode => Object.hash(runtimeType,plan,priceLabel,price,currencyCode,trialDays);

@override
String toString() {
  return 'Offer(plan: $plan, priceLabel: $priceLabel, price: $price, currencyCode: $currencyCode, trialDays: $trialDays)';
}


}

/// @nodoc
abstract mixin class $OfferCopyWith<$Res>  {
  factory $OfferCopyWith(Offer value, $Res Function(Offer) _then) = _$OfferCopyWithImpl;
@useResult
$Res call({
 SubscriptionPlan plan, String priceLabel, double price, String currencyCode, int? trialDays
});




}
/// @nodoc
class _$OfferCopyWithImpl<$Res>
    implements $OfferCopyWith<$Res> {
  _$OfferCopyWithImpl(this._self, this._then);

  final Offer _self;
  final $Res Function(Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? priceLabel = null,Object? price = null,Object? currencyCode = null,Object? trialDays = freezed,}) {
  return _then(_self.copyWith(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan,priceLabel: null == priceLabel ? _self.priceLabel : priceLabel // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,trialDays: freezed == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Offer].
extension OfferPatterns on Offer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Offer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Offer value)  $default,){
final _that = this;
switch (_that) {
case _Offer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Offer value)?  $default,){
final _that = this;
switch (_that) {
case _Offer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubscriptionPlan plan,  String priceLabel,  double price,  String currencyCode,  int? trialDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.plan,_that.priceLabel,_that.price,_that.currencyCode,_that.trialDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubscriptionPlan plan,  String priceLabel,  double price,  String currencyCode,  int? trialDays)  $default,) {final _that = this;
switch (_that) {
case _Offer():
return $default(_that.plan,_that.priceLabel,_that.price,_that.currencyCode,_that.trialDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubscriptionPlan plan,  String priceLabel,  double price,  String currencyCode,  int? trialDays)?  $default,) {final _that = this;
switch (_that) {
case _Offer() when $default != null:
return $default(_that.plan,_that.priceLabel,_that.price,_that.currencyCode,_that.trialDays);case _:
  return null;

}
}

}

/// @nodoc


class _Offer implements Offer {
  const _Offer({required this.plan, required this.priceLabel, required this.price, required this.currencyCode, this.trialDays});
  

@override final  SubscriptionPlan plan;
/// Prix de la période, déjà mis en forme par le store (« 29,99 € »).
@override final  String priceLabel;
@override final  double price;
/// Code ISO de la devise (« EUR »).
@override final  String currencyCode;
/// Durée de l'essai gratuit ; `null` si l'utilisateur n'y a pas droit.
@override final  int? trialDays;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfferCopyWith<_Offer> get copyWith => __$OfferCopyWithImpl<_Offer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Offer&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.priceLabel, priceLabel) || other.priceLabel == priceLabel)&&(identical(other.price, price) || other.price == price)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.trialDays, trialDays) || other.trialDays == trialDays));
}


@override
int get hashCode => Object.hash(runtimeType,plan,priceLabel,price,currencyCode,trialDays);

@override
String toString() {
  return 'Offer(plan: $plan, priceLabel: $priceLabel, price: $price, currencyCode: $currencyCode, trialDays: $trialDays)';
}


}

/// @nodoc
abstract mixin class _$OfferCopyWith<$Res> implements $OfferCopyWith<$Res> {
  factory _$OfferCopyWith(_Offer value, $Res Function(_Offer) _then) = __$OfferCopyWithImpl;
@override @useResult
$Res call({
 SubscriptionPlan plan, String priceLabel, double price, String currencyCode, int? trialDays
});




}
/// @nodoc
class __$OfferCopyWithImpl<$Res>
    implements _$OfferCopyWith<$Res> {
  __$OfferCopyWithImpl(this._self, this._then);

  final _Offer _self;
  final $Res Function(_Offer) _then;

/// Create a copy of Offer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? priceLabel = null,Object? price = null,Object? currencyCode = null,Object? trialDays = freezed,}) {
  return _then(_Offer(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan,priceLabel: null == priceLabel ? _self.priceLabel : priceLabel // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,trialDays: freezed == trialDays ? _self.trialDays : trialDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
