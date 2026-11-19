// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Exercise {

 String get id; String get question; List<String> get options;
/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseCopyWith<Exercise> get copyWith => _$ExerciseCopyWithImpl<Exercise>(this as Exercise, _$identity);

  /// Serializes this Exercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Exercise&&(identical(other.id, id) || other.id == id)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,question,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'Exercise(id: $id, question: $question, options: $options)';
}


}

/// @nodoc
abstract mixin class $ExerciseCopyWith<$Res>  {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) _then) = _$ExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String question, List<String> options
});




}
/// @nodoc
class _$ExerciseCopyWithImpl<$Res>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._self, this._then);

  final Exercise _self;
  final $Res Function(Exercise) _then;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? question = null,Object? options = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Exercise].
extension ExercisePatterns on Exercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Exercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Exercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Exercise value)  $default,){
final _that = this;
switch (_that) {
case _Exercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Exercise value)?  $default,){
final _that = this;
switch (_that) {
case _Exercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String question,  List<String> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Exercise() when $default != null:
return $default(_that.id,_that.question,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String question,  List<String> options)  $default,) {final _that = this;
switch (_that) {
case _Exercise():
return $default(_that.id,_that.question,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String question,  List<String> options)?  $default,) {final _that = this;
switch (_that) {
case _Exercise() when $default != null:
return $default(_that.id,_that.question,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Exercise implements Exercise {
  const _Exercise({required this.id, required this.question, required final  List<String> options}): _options = options;
  factory _Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);

@override final  String id;
@override final  String question;
 final  List<String> _options;
@override List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseCopyWith<_Exercise> get copyWith => __$ExerciseCopyWithImpl<_Exercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Exercise&&(identical(other.id, id) || other.id == id)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,question,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'Exercise(id: $id, question: $question, options: $options)';
}


}

/// @nodoc
abstract mixin class _$ExerciseCopyWith<$Res> implements $ExerciseCopyWith<$Res> {
  factory _$ExerciseCopyWith(_Exercise value, $Res Function(_Exercise) _then) = __$ExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String question, List<String> options
});




}
/// @nodoc
class __$ExerciseCopyWithImpl<$Res>
    implements _$ExerciseCopyWith<$Res> {
  __$ExerciseCopyWithImpl(this._self, this._then);

  final _Exercise _self;
  final $Res Function(_Exercise) _then;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? question = null,Object? options = null,}) {
  return _then(_Exercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$ExerciseBatch {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseBatch);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExerciseBatch()';
}


}

/// @nodoc
class $ExerciseBatchCopyWith<$Res>  {
$ExerciseBatchCopyWith(ExerciseBatch _, $Res Function(ExerciseBatch) __);
}


/// Adds pattern-matching-related methods to [ExerciseBatch].
extension ExerciseBatchPatterns on ExerciseBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AvailableExercises value)?  available,TResult Function( ExerciseLimitReached value)?  limitReached,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AvailableExercises() when available != null:
return available(_that);case ExerciseLimitReached() when limitReached != null:
return limitReached(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AvailableExercises value)  available,required TResult Function( ExerciseLimitReached value)  limitReached,}){
final _that = this;
switch (_that) {
case AvailableExercises():
return available(_that);case ExerciseLimitReached():
return limitReached(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AvailableExercises value)?  available,TResult? Function( ExerciseLimitReached value)?  limitReached,}){
final _that = this;
switch (_that) {
case AvailableExercises() when available != null:
return available(_that);case ExerciseLimitReached() when limitReached != null:
return limitReached(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ErrorCategory category,  bool isPersonalized,  int left,  List<Exercise> exercises)?  available,TResult Function( bool isPremium)?  limitReached,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AvailableExercises() when available != null:
return available(_that.category,_that.isPersonalized,_that.left,_that.exercises);case ExerciseLimitReached() when limitReached != null:
return limitReached(_that.isPremium);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ErrorCategory category,  bool isPersonalized,  int left,  List<Exercise> exercises)  available,required TResult Function( bool isPremium)  limitReached,}) {final _that = this;
switch (_that) {
case AvailableExercises():
return available(_that.category,_that.isPersonalized,_that.left,_that.exercises);case ExerciseLimitReached():
return limitReached(_that.isPremium);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ErrorCategory category,  bool isPersonalized,  int left,  List<Exercise> exercises)?  available,TResult? Function( bool isPremium)?  limitReached,}) {final _that = this;
switch (_that) {
case AvailableExercises() when available != null:
return available(_that.category,_that.isPersonalized,_that.left,_that.exercises);case ExerciseLimitReached() when limitReached != null:
return limitReached(_that.isPremium);case _:
  return null;

}
}

}

/// @nodoc


class AvailableExercises implements ExerciseBatch {
  const AvailableExercises({required this.category, required this.isPersonalized, required this.left, required final  List<Exercise> exercises}): _exercises = exercises;
  

/// Type d'erreur travaillé.
 final  ErrorCategory category;
/// Vrai si le type vient des erreurs de l'utilisateur (Premium).
 final  bool isPersonalized;
/// Exercices encore permis aujourd'hui par l'offre, ceux-ci compris.
 final  int left;
 final  List<Exercise> _exercises;
 List<Exercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}


/// Create a copy of ExerciseBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableExercisesCopyWith<AvailableExercises> get copyWith => _$AvailableExercisesCopyWithImpl<AvailableExercises>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableExercises&&(identical(other.category, category) || other.category == category)&&(identical(other.isPersonalized, isPersonalized) || other.isPersonalized == isPersonalized)&&(identical(other.left, left) || other.left == left)&&const DeepCollectionEquality().equals(other._exercises, _exercises));
}


@override
int get hashCode => Object.hash(runtimeType,category,isPersonalized,left,const DeepCollectionEquality().hash(_exercises));

@override
String toString() {
  return 'ExerciseBatch.available(category: $category, isPersonalized: $isPersonalized, left: $left, exercises: $exercises)';
}


}

/// @nodoc
abstract mixin class $AvailableExercisesCopyWith<$Res> implements $ExerciseBatchCopyWith<$Res> {
  factory $AvailableExercisesCopyWith(AvailableExercises value, $Res Function(AvailableExercises) _then) = _$AvailableExercisesCopyWithImpl;
@useResult
$Res call({
 ErrorCategory category, bool isPersonalized, int left, List<Exercise> exercises
});




}
/// @nodoc
class _$AvailableExercisesCopyWithImpl<$Res>
    implements $AvailableExercisesCopyWith<$Res> {
  _$AvailableExercisesCopyWithImpl(this._self, this._then);

  final AvailableExercises _self;
  final $Res Function(AvailableExercises) _then;

/// Create a copy of ExerciseBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? category = null,Object? isPersonalized = null,Object? left = null,Object? exercises = null,}) {
  return _then(AvailableExercises(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ErrorCategory,isPersonalized: null == isPersonalized ? _self.isPersonalized : isPersonalized // ignore: cast_nullable_to_non_nullable
as bool,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as int,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<Exercise>,
  ));
}


}

/// @nodoc


class ExerciseLimitReached implements ExerciseBatch {
  const ExerciseLimitReached({required this.isPremium});
  

 final  bool isPremium;

/// Create a copy of ExerciseBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseLimitReachedCopyWith<ExerciseLimitReached> get copyWith => _$ExerciseLimitReachedCopyWithImpl<ExerciseLimitReached>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseLimitReached&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium));
}


@override
int get hashCode => Object.hash(runtimeType,isPremium);

@override
String toString() {
  return 'ExerciseBatch.limitReached(isPremium: $isPremium)';
}


}

/// @nodoc
abstract mixin class $ExerciseLimitReachedCopyWith<$Res> implements $ExerciseBatchCopyWith<$Res> {
  factory $ExerciseLimitReachedCopyWith(ExerciseLimitReached value, $Res Function(ExerciseLimitReached) _then) = _$ExerciseLimitReachedCopyWithImpl;
@useResult
$Res call({
 bool isPremium
});




}
/// @nodoc
class _$ExerciseLimitReachedCopyWithImpl<$Res>
    implements $ExerciseLimitReachedCopyWith<$Res> {
  _$ExerciseLimitReachedCopyWithImpl(this._self, this._then);

  final ExerciseLimitReached _self;
  final $Res Function(ExerciseLimitReached) _then;

/// Create a copy of ExerciseBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isPremium = null,}) {
  return _then(ExerciseLimitReached(
isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ExerciseFeedback {

 bool get isCorrect; int get answerIndex; String get explanation;/// Exercices encore permis aujourd'hui après cette réponse.
 int get left;
/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseFeedbackCopyWith<ExerciseFeedback> get copyWith => _$ExerciseFeedbackCopyWithImpl<ExerciseFeedback>(this as ExerciseFeedback, _$identity);

  /// Serializes this ExerciseFeedback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseFeedback&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.answerIndex, answerIndex) || other.answerIndex == answerIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.left, left) || other.left == left));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isCorrect,answerIndex,explanation,left);

@override
String toString() {
  return 'ExerciseFeedback(isCorrect: $isCorrect, answerIndex: $answerIndex, explanation: $explanation, left: $left)';
}


}

/// @nodoc
abstract mixin class $ExerciseFeedbackCopyWith<$Res>  {
  factory $ExerciseFeedbackCopyWith(ExerciseFeedback value, $Res Function(ExerciseFeedback) _then) = _$ExerciseFeedbackCopyWithImpl;
@useResult
$Res call({
 bool isCorrect, int answerIndex, String explanation, int left
});




}
/// @nodoc
class _$ExerciseFeedbackCopyWithImpl<$Res>
    implements $ExerciseFeedbackCopyWith<$Res> {
  _$ExerciseFeedbackCopyWithImpl(this._self, this._then);

  final ExerciseFeedback _self;
  final $Res Function(ExerciseFeedback) _then;

/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isCorrect = null,Object? answerIndex = null,Object? explanation = null,Object? left = null,}) {
  return _then(_self.copyWith(
isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,answerIndex: null == answerIndex ? _self.answerIndex : answerIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExerciseFeedback].
extension ExerciseFeedbackPatterns on ExerciseFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseFeedback value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isCorrect,  int answerIndex,  String explanation,  int left)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
return $default(_that.isCorrect,_that.answerIndex,_that.explanation,_that.left);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isCorrect,  int answerIndex,  String explanation,  int left)  $default,) {final _that = this;
switch (_that) {
case _ExerciseFeedback():
return $default(_that.isCorrect,_that.answerIndex,_that.explanation,_that.left);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isCorrect,  int answerIndex,  String explanation,  int left)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseFeedback() when $default != null:
return $default(_that.isCorrect,_that.answerIndex,_that.explanation,_that.left);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ExerciseFeedback implements ExerciseFeedback {
  const _ExerciseFeedback({required this.isCorrect, required this.answerIndex, required this.explanation, required this.left});
  factory _ExerciseFeedback.fromJson(Map<String, dynamic> json) => _$ExerciseFeedbackFromJson(json);

@override final  bool isCorrect;
@override final  int answerIndex;
@override final  String explanation;
/// Exercices encore permis aujourd'hui après cette réponse.
@override final  int left;

/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseFeedbackCopyWith<_ExerciseFeedback> get copyWith => __$ExerciseFeedbackCopyWithImpl<_ExerciseFeedback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseFeedbackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseFeedback&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.answerIndex, answerIndex) || other.answerIndex == answerIndex)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.left, left) || other.left == left));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isCorrect,answerIndex,explanation,left);

@override
String toString() {
  return 'ExerciseFeedback(isCorrect: $isCorrect, answerIndex: $answerIndex, explanation: $explanation, left: $left)';
}


}

/// @nodoc
abstract mixin class _$ExerciseFeedbackCopyWith<$Res> implements $ExerciseFeedbackCopyWith<$Res> {
  factory _$ExerciseFeedbackCopyWith(_ExerciseFeedback value, $Res Function(_ExerciseFeedback) _then) = __$ExerciseFeedbackCopyWithImpl;
@override @useResult
$Res call({
 bool isCorrect, int answerIndex, String explanation, int left
});




}
/// @nodoc
class __$ExerciseFeedbackCopyWithImpl<$Res>
    implements _$ExerciseFeedbackCopyWith<$Res> {
  __$ExerciseFeedbackCopyWithImpl(this._self, this._then);

  final _ExerciseFeedback _self;
  final $Res Function(_ExerciseFeedback) _then;

/// Create a copy of ExerciseFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isCorrect = null,Object? answerIndex = null,Object? explanation = null,Object? left = null,}) {
  return _then(_ExerciseFeedback(
isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,answerIndex: null == answerIndex ? _self.answerIndex : answerIndex // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
