// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExamPrompt {

 String get title; String get task; int get minWords; int get maxWords;
/// Create a copy of ExamPrompt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamPromptCopyWith<ExamPrompt> get copyWith => _$ExamPromptCopyWithImpl<ExamPrompt>(this as ExamPrompt, _$identity);

  /// Serializes this ExamPrompt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamPrompt&&(identical(other.title, title) || other.title == title)&&(identical(other.task, task) || other.task == task)&&(identical(other.minWords, minWords) || other.minWords == minWords)&&(identical(other.maxWords, maxWords) || other.maxWords == maxWords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,task,minWords,maxWords);

@override
String toString() {
  return 'ExamPrompt(title: $title, task: $task, minWords: $minWords, maxWords: $maxWords)';
}


}

/// @nodoc
abstract mixin class $ExamPromptCopyWith<$Res>  {
  factory $ExamPromptCopyWith(ExamPrompt value, $Res Function(ExamPrompt) _then) = _$ExamPromptCopyWithImpl;
@useResult
$Res call({
 String title, String task, int minWords, int maxWords
});




}
/// @nodoc
class _$ExamPromptCopyWithImpl<$Res>
    implements $ExamPromptCopyWith<$Res> {
  _$ExamPromptCopyWithImpl(this._self, this._then);

  final ExamPrompt _self;
  final $Res Function(ExamPrompt) _then;

/// Create a copy of ExamPrompt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? task = null,Object? minWords = null,Object? maxWords = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,minWords: null == minWords ? _self.minWords : minWords // ignore: cast_nullable_to_non_nullable
as int,maxWords: null == maxWords ? _self.maxWords : maxWords // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExamPrompt].
extension ExamPromptPatterns on ExamPrompt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamPrompt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamPrompt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamPrompt value)  $default,){
final _that = this;
switch (_that) {
case _ExamPrompt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamPrompt value)?  $default,){
final _that = this;
switch (_that) {
case _ExamPrompt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String task,  int minWords,  int maxWords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamPrompt() when $default != null:
return $default(_that.title,_that.task,_that.minWords,_that.maxWords);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String task,  int minWords,  int maxWords)  $default,) {final _that = this;
switch (_that) {
case _ExamPrompt():
return $default(_that.title,_that.task,_that.minWords,_that.maxWords);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String task,  int minWords,  int maxWords)?  $default,) {final _that = this;
switch (_that) {
case _ExamPrompt() when $default != null:
return $default(_that.title,_that.task,_that.minWords,_that.maxWords);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ExamPrompt implements ExamPrompt {
  const _ExamPrompt({required this.title, required this.task, required this.minWords, required this.maxWords});
  factory _ExamPrompt.fromJson(Map<String, dynamic> json) => _$ExamPromptFromJson(json);

@override final  String title;
@override final  String task;
@override final  int minWords;
@override final  int maxWords;

/// Create a copy of ExamPrompt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamPromptCopyWith<_ExamPrompt> get copyWith => __$ExamPromptCopyWithImpl<_ExamPrompt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamPromptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamPrompt&&(identical(other.title, title) || other.title == title)&&(identical(other.task, task) || other.task == task)&&(identical(other.minWords, minWords) || other.minWords == minWords)&&(identical(other.maxWords, maxWords) || other.maxWords == maxWords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,task,minWords,maxWords);

@override
String toString() {
  return 'ExamPrompt(title: $title, task: $task, minWords: $minWords, maxWords: $maxWords)';
}


}

/// @nodoc
abstract mixin class _$ExamPromptCopyWith<$Res> implements $ExamPromptCopyWith<$Res> {
  factory _$ExamPromptCopyWith(_ExamPrompt value, $Res Function(_ExamPrompt) _then) = __$ExamPromptCopyWithImpl;
@override @useResult
$Res call({
 String title, String task, int minWords, int maxWords
});




}
/// @nodoc
class __$ExamPromptCopyWithImpl<$Res>
    implements _$ExamPromptCopyWith<$Res> {
  __$ExamPromptCopyWithImpl(this._self, this._then);

  final _ExamPrompt _self;
  final $Res Function(_ExamPrompt) _then;

/// Create a copy of ExamPrompt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? task = null,Object? minWords = null,Object? maxWords = null,}) {
  return _then(_ExamPrompt(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,minWords: null == minWords ? _self.minWords : minWords // ignore: cast_nullable_to_non_nullable
as int,maxWords: null == maxWords ? _self.maxWords : maxWords // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CriterionScore {

 ExamCriterion get criterion;/// Sur 5.
 int get score; String get comment;
/// Create a copy of CriterionScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CriterionScoreCopyWith<CriterionScore> get copyWith => _$CriterionScoreCopyWithImpl<CriterionScore>(this as CriterionScore, _$identity);

  /// Serializes this CriterionScore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CriterionScore&&(identical(other.criterion, criterion) || other.criterion == criterion)&&(identical(other.score, score) || other.score == score)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,criterion,score,comment);

@override
String toString() {
  return 'CriterionScore(criterion: $criterion, score: $score, comment: $comment)';
}


}

/// @nodoc
abstract mixin class $CriterionScoreCopyWith<$Res>  {
  factory $CriterionScoreCopyWith(CriterionScore value, $Res Function(CriterionScore) _then) = _$CriterionScoreCopyWithImpl;
@useResult
$Res call({
 ExamCriterion criterion, int score, String comment
});




}
/// @nodoc
class _$CriterionScoreCopyWithImpl<$Res>
    implements $CriterionScoreCopyWith<$Res> {
  _$CriterionScoreCopyWithImpl(this._self, this._then);

  final CriterionScore _self;
  final $Res Function(CriterionScore) _then;

/// Create a copy of CriterionScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? criterion = null,Object? score = null,Object? comment = null,}) {
  return _then(_self.copyWith(
criterion: null == criterion ? _self.criterion : criterion // ignore: cast_nullable_to_non_nullable
as ExamCriterion,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CriterionScore].
extension CriterionScorePatterns on CriterionScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CriterionScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CriterionScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CriterionScore value)  $default,){
final _that = this;
switch (_that) {
case _CriterionScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CriterionScore value)?  $default,){
final _that = this;
switch (_that) {
case _CriterionScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExamCriterion criterion,  int score,  String comment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CriterionScore() when $default != null:
return $default(_that.criterion,_that.score,_that.comment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExamCriterion criterion,  int score,  String comment)  $default,) {final _that = this;
switch (_that) {
case _CriterionScore():
return $default(_that.criterion,_that.score,_that.comment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExamCriterion criterion,  int score,  String comment)?  $default,) {final _that = this;
switch (_that) {
case _CriterionScore() when $default != null:
return $default(_that.criterion,_that.score,_that.comment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CriterionScore implements CriterionScore {
  const _CriterionScore({required this.criterion, required this.score, required this.comment});
  factory _CriterionScore.fromJson(Map<String, dynamic> json) => _$CriterionScoreFromJson(json);

@override final  ExamCriterion criterion;
/// Sur 5.
@override final  int score;
@override final  String comment;

/// Create a copy of CriterionScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CriterionScoreCopyWith<_CriterionScore> get copyWith => __$CriterionScoreCopyWithImpl<_CriterionScore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CriterionScoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CriterionScore&&(identical(other.criterion, criterion) || other.criterion == criterion)&&(identical(other.score, score) || other.score == score)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,criterion,score,comment);

@override
String toString() {
  return 'CriterionScore(criterion: $criterion, score: $score, comment: $comment)';
}


}

/// @nodoc
abstract mixin class _$CriterionScoreCopyWith<$Res> implements $CriterionScoreCopyWith<$Res> {
  factory _$CriterionScoreCopyWith(_CriterionScore value, $Res Function(_CriterionScore) _then) = __$CriterionScoreCopyWithImpl;
@override @useResult
$Res call({
 ExamCriterion criterion, int score, String comment
});




}
/// @nodoc
class __$CriterionScoreCopyWithImpl<$Res>
    implements _$CriterionScoreCopyWith<$Res> {
  __$CriterionScoreCopyWithImpl(this._self, this._then);

  final _CriterionScore _self;
  final $Res Function(_CriterionScore) _then;

/// Create a copy of CriterionScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? criterion = null,Object? score = null,Object? comment = null,}) {
  return _then(_CriterionScore(
criterion: null == criterion ? _self.criterion : criterion // ignore: cast_nullable_to_non_nullable
as ExamCriterion,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,comment: null == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RevisionStep {

 String get title; String get details;
/// Create a copy of RevisionStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevisionStepCopyWith<RevisionStep> get copyWith => _$RevisionStepCopyWithImpl<RevisionStep>(this as RevisionStep, _$identity);

  /// Serializes this RevisionStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevisionStep&&(identical(other.title, title) || other.title == title)&&(identical(other.details, details) || other.details == details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,details);

@override
String toString() {
  return 'RevisionStep(title: $title, details: $details)';
}


}

/// @nodoc
abstract mixin class $RevisionStepCopyWith<$Res>  {
  factory $RevisionStepCopyWith(RevisionStep value, $Res Function(RevisionStep) _then) = _$RevisionStepCopyWithImpl;
@useResult
$Res call({
 String title, String details
});




}
/// @nodoc
class _$RevisionStepCopyWithImpl<$Res>
    implements $RevisionStepCopyWith<$Res> {
  _$RevisionStepCopyWithImpl(this._self, this._then);

  final RevisionStep _self;
  final $Res Function(RevisionStep) _then;

/// Create a copy of RevisionStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? details = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RevisionStep].
extension RevisionStepPatterns on RevisionStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevisionStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevisionStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevisionStep value)  $default,){
final _that = this;
switch (_that) {
case _RevisionStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevisionStep value)?  $default,){
final _that = this;
switch (_that) {
case _RevisionStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevisionStep() when $default != null:
return $default(_that.title,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String details)  $default,) {final _that = this;
switch (_that) {
case _RevisionStep():
return $default(_that.title,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String details)?  $default,) {final _that = this;
switch (_that) {
case _RevisionStep() when $default != null:
return $default(_that.title,_that.details);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevisionStep implements RevisionStep {
  const _RevisionStep({required this.title, required this.details});
  factory _RevisionStep.fromJson(Map<String, dynamic> json) => _$RevisionStepFromJson(json);

@override final  String title;
@override final  String details;

/// Create a copy of RevisionStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevisionStepCopyWith<_RevisionStep> get copyWith => __$RevisionStepCopyWithImpl<_RevisionStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevisionStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevisionStep&&(identical(other.title, title) || other.title == title)&&(identical(other.details, details) || other.details == details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,details);

@override
String toString() {
  return 'RevisionStep(title: $title, details: $details)';
}


}

/// @nodoc
abstract mixin class _$RevisionStepCopyWith<$Res> implements $RevisionStepCopyWith<$Res> {
  factory _$RevisionStepCopyWith(_RevisionStep value, $Res Function(_RevisionStep) _then) = __$RevisionStepCopyWithImpl;
@override @useResult
$Res call({
 String title, String details
});




}
/// @nodoc
class __$RevisionStepCopyWithImpl<$Res>
    implements _$RevisionStepCopyWith<$Res> {
  __$RevisionStepCopyWithImpl(this._self, this._then);

  final _RevisionStep _self;
  final $Res Function(_RevisionStep) _then;

/// Create a copy of RevisionStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? details = null,}) {
  return _then(_RevisionStep(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ExamResult {

/// Note sur 20.
 int get score;/// Niveau du cadre européen que montre la rédaction (de A1 à C2).
 String get levelEstimate; String get summary; List<CriterionScore> get criteria; String get correctedText; List<CorrectionItem> get items; List<RevisionStep> get revisionPlan;
/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamResultCopyWith<ExamResult> get copyWith => _$ExamResultCopyWithImpl<ExamResult>(this as ExamResult, _$identity);

  /// Serializes this ExamResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExamResult&&(identical(other.score, score) || other.score == score)&&(identical(other.levelEstimate, levelEstimate) || other.levelEstimate == levelEstimate)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.criteria, criteria)&&(identical(other.correctedText, correctedText) || other.correctedText == correctedText)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.revisionPlan, revisionPlan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,score,levelEstimate,summary,const DeepCollectionEquality().hash(criteria),correctedText,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(revisionPlan));

@override
String toString() {
  return 'ExamResult(score: $score, levelEstimate: $levelEstimate, summary: $summary, criteria: $criteria, correctedText: $correctedText, items: $items, revisionPlan: $revisionPlan)';
}


}

/// @nodoc
abstract mixin class $ExamResultCopyWith<$Res>  {
  factory $ExamResultCopyWith(ExamResult value, $Res Function(ExamResult) _then) = _$ExamResultCopyWithImpl;
@useResult
$Res call({
 int score, String levelEstimate, String summary, List<CriterionScore> criteria, String correctedText, List<CorrectionItem> items, List<RevisionStep> revisionPlan
});




}
/// @nodoc
class _$ExamResultCopyWithImpl<$Res>
    implements $ExamResultCopyWith<$Res> {
  _$ExamResultCopyWithImpl(this._self, this._then);

  final ExamResult _self;
  final $Res Function(ExamResult) _then;

/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? score = null,Object? levelEstimate = null,Object? summary = null,Object? criteria = null,Object? correctedText = null,Object? items = null,Object? revisionPlan = null,}) {
  return _then(_self.copyWith(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,levelEstimate: null == levelEstimate ? _self.levelEstimate : levelEstimate // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,criteria: null == criteria ? _self.criteria : criteria // ignore: cast_nullable_to_non_nullable
as List<CriterionScore>,correctedText: null == correctedText ? _self.correctedText : correctedText // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CorrectionItem>,revisionPlan: null == revisionPlan ? _self.revisionPlan : revisionPlan // ignore: cast_nullable_to_non_nullable
as List<RevisionStep>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExamResult].
extension ExamResultPatterns on ExamResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExamResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExamResult value)  $default,){
final _that = this;
switch (_that) {
case _ExamResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExamResult value)?  $default,){
final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int score,  String levelEstimate,  String summary,  List<CriterionScore> criteria,  String correctedText,  List<CorrectionItem> items,  List<RevisionStep> revisionPlan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
return $default(_that.score,_that.levelEstimate,_that.summary,_that.criteria,_that.correctedText,_that.items,_that.revisionPlan);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int score,  String levelEstimate,  String summary,  List<CriterionScore> criteria,  String correctedText,  List<CorrectionItem> items,  List<RevisionStep> revisionPlan)  $default,) {final _that = this;
switch (_that) {
case _ExamResult():
return $default(_that.score,_that.levelEstimate,_that.summary,_that.criteria,_that.correctedText,_that.items,_that.revisionPlan);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int score,  String levelEstimate,  String summary,  List<CriterionScore> criteria,  String correctedText,  List<CorrectionItem> items,  List<RevisionStep> revisionPlan)?  $default,) {final _that = this;
switch (_that) {
case _ExamResult() when $default != null:
return $default(_that.score,_that.levelEstimate,_that.summary,_that.criteria,_that.correctedText,_that.items,_that.revisionPlan);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ExamResult implements ExamResult {
  const _ExamResult({required this.score, required this.levelEstimate, required this.summary, required final  List<CriterionScore> criteria, required this.correctedText, required final  List<CorrectionItem> items, required final  List<RevisionStep> revisionPlan}): _criteria = criteria,_items = items,_revisionPlan = revisionPlan;
  factory _ExamResult.fromJson(Map<String, dynamic> json) => _$ExamResultFromJson(json);

/// Note sur 20.
@override final  int score;
/// Niveau du cadre européen que montre la rédaction (de A1 à C2).
@override final  String levelEstimate;
@override final  String summary;
 final  List<CriterionScore> _criteria;
@override List<CriterionScore> get criteria {
  if (_criteria is EqualUnmodifiableListView) return _criteria;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_criteria);
}

@override final  String correctedText;
 final  List<CorrectionItem> _items;
@override List<CorrectionItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<RevisionStep> _revisionPlan;
@override List<RevisionStep> get revisionPlan {
  if (_revisionPlan is EqualUnmodifiableListView) return _revisionPlan;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_revisionPlan);
}


/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamResultCopyWith<_ExamResult> get copyWith => __$ExamResultCopyWithImpl<_ExamResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExamResult&&(identical(other.score, score) || other.score == score)&&(identical(other.levelEstimate, levelEstimate) || other.levelEstimate == levelEstimate)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._criteria, _criteria)&&(identical(other.correctedText, correctedText) || other.correctedText == correctedText)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._revisionPlan, _revisionPlan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,score,levelEstimate,summary,const DeepCollectionEquality().hash(_criteria),correctedText,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_revisionPlan));

@override
String toString() {
  return 'ExamResult(score: $score, levelEstimate: $levelEstimate, summary: $summary, criteria: $criteria, correctedText: $correctedText, items: $items, revisionPlan: $revisionPlan)';
}


}

/// @nodoc
abstract mixin class _$ExamResultCopyWith<$Res> implements $ExamResultCopyWith<$Res> {
  factory _$ExamResultCopyWith(_ExamResult value, $Res Function(_ExamResult) _then) = __$ExamResultCopyWithImpl;
@override @useResult
$Res call({
 int score, String levelEstimate, String summary, List<CriterionScore> criteria, String correctedText, List<CorrectionItem> items, List<RevisionStep> revisionPlan
});




}
/// @nodoc
class __$ExamResultCopyWithImpl<$Res>
    implements _$ExamResultCopyWith<$Res> {
  __$ExamResultCopyWithImpl(this._self, this._then);

  final _ExamResult _self;
  final $Res Function(_ExamResult) _then;

/// Create a copy of ExamResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? score = null,Object? levelEstimate = null,Object? summary = null,Object? criteria = null,Object? correctedText = null,Object? items = null,Object? revisionPlan = null,}) {
  return _then(_ExamResult(
score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,levelEstimate: null == levelEstimate ? _self.levelEstimate : levelEstimate // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,criteria: null == criteria ? _self._criteria : criteria // ignore: cast_nullable_to_non_nullable
as List<CriterionScore>,correctedText: null == correctedText ? _self.correctedText : correctedText // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CorrectionItem>,revisionPlan: null == revisionPlan ? _self._revisionPlan : revisionPlan // ignore: cast_nullable_to_non_nullable
as List<RevisionStep>,
  ));
}


}


/// @nodoc
mixin _$Exam {

 String get id; LearningLanguage get language; ExamLevel get level; ExamStatus get status; DateTime get createdAt; ExamPrompt? get prompt;/// Rédaction rendue, ou brouillon tant que la simulation est en cours.
 String? get answer; ExamResult? get result; DateTime? get gradedAt;
/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExamCopyWith<Exam> get copyWith => _$ExamCopyWithImpl<Exam>(this as Exam, _$identity);

  /// Serializes this Exam to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Exam&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.result, result) || other.result == result)&&(identical(other.gradedAt, gradedAt) || other.gradedAt == gradedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,level,status,createdAt,prompt,answer,result,gradedAt);

@override
String toString() {
  return 'Exam(id: $id, language: $language, level: $level, status: $status, createdAt: $createdAt, prompt: $prompt, answer: $answer, result: $result, gradedAt: $gradedAt)';
}


}

/// @nodoc
abstract mixin class $ExamCopyWith<$Res>  {
  factory $ExamCopyWith(Exam value, $Res Function(Exam) _then) = _$ExamCopyWithImpl;
@useResult
$Res call({
 String id, LearningLanguage language, ExamLevel level, ExamStatus status, DateTime createdAt, ExamPrompt? prompt, String? answer, ExamResult? result, DateTime? gradedAt
});


$ExamPromptCopyWith<$Res>? get prompt;$ExamResultCopyWith<$Res>? get result;

}
/// @nodoc
class _$ExamCopyWithImpl<$Res>
    implements $ExamCopyWith<$Res> {
  _$ExamCopyWithImpl(this._self, this._then);

  final Exam _self;
  final $Res Function(Exam) _then;

/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? language = null,Object? level = null,Object? status = null,Object? createdAt = null,Object? prompt = freezed,Object? answer = freezed,Object? result = freezed,Object? gradedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as LearningLanguage,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as ExamLevel,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExamStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,prompt: freezed == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as ExamPrompt?,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ExamResult?,gradedAt: freezed == gradedAt ? _self.gradedAt : gradedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExamPromptCopyWith<$Res>? get prompt {
    if (_self.prompt == null) {
    return null;
  }

  return $ExamPromptCopyWith<$Res>(_self.prompt!, (value) {
    return _then(_self.copyWith(prompt: value));
  });
}/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExamResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ExamResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [Exam].
extension ExamPatterns on Exam {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Exam value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Exam() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Exam value)  $default,){
final _that = this;
switch (_that) {
case _Exam():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Exam value)?  $default,){
final _that = this;
switch (_that) {
case _Exam() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LearningLanguage language,  ExamLevel level,  ExamStatus status,  DateTime createdAt,  ExamPrompt? prompt,  String? answer,  ExamResult? result,  DateTime? gradedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Exam() when $default != null:
return $default(_that.id,_that.language,_that.level,_that.status,_that.createdAt,_that.prompt,_that.answer,_that.result,_that.gradedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LearningLanguage language,  ExamLevel level,  ExamStatus status,  DateTime createdAt,  ExamPrompt? prompt,  String? answer,  ExamResult? result,  DateTime? gradedAt)  $default,) {final _that = this;
switch (_that) {
case _Exam():
return $default(_that.id,_that.language,_that.level,_that.status,_that.createdAt,_that.prompt,_that.answer,_that.result,_that.gradedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LearningLanguage language,  ExamLevel level,  ExamStatus status,  DateTime createdAt,  ExamPrompt? prompt,  String? answer,  ExamResult? result,  DateTime? gradedAt)?  $default,) {final _that = this;
switch (_that) {
case _Exam() when $default != null:
return $default(_that.id,_that.language,_that.level,_that.status,_that.createdAt,_that.prompt,_that.answer,_that.result,_that.gradedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Exam implements Exam {
  const _Exam({required this.id, required this.language, required this.level, required this.status, required this.createdAt, this.prompt, this.answer, this.result, this.gradedAt});
  factory _Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);

@override final  String id;
@override final  LearningLanguage language;
@override final  ExamLevel level;
@override final  ExamStatus status;
@override final  DateTime createdAt;
@override final  ExamPrompt? prompt;
/// Rédaction rendue, ou brouillon tant que la simulation est en cours.
@override final  String? answer;
@override final  ExamResult? result;
@override final  DateTime? gradedAt;

/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExamCopyWith<_Exam> get copyWith => __$ExamCopyWithImpl<_Exam>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Exam&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.level, level) || other.level == level)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.result, result) || other.result == result)&&(identical(other.gradedAt, gradedAt) || other.gradedAt == gradedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,level,status,createdAt,prompt,answer,result,gradedAt);

@override
String toString() {
  return 'Exam(id: $id, language: $language, level: $level, status: $status, createdAt: $createdAt, prompt: $prompt, answer: $answer, result: $result, gradedAt: $gradedAt)';
}


}

/// @nodoc
abstract mixin class _$ExamCopyWith<$Res> implements $ExamCopyWith<$Res> {
  factory _$ExamCopyWith(_Exam value, $Res Function(_Exam) _then) = __$ExamCopyWithImpl;
@override @useResult
$Res call({
 String id, LearningLanguage language, ExamLevel level, ExamStatus status, DateTime createdAt, ExamPrompt? prompt, String? answer, ExamResult? result, DateTime? gradedAt
});


@override $ExamPromptCopyWith<$Res>? get prompt;@override $ExamResultCopyWith<$Res>? get result;

}
/// @nodoc
class __$ExamCopyWithImpl<$Res>
    implements _$ExamCopyWith<$Res> {
  __$ExamCopyWithImpl(this._self, this._then);

  final _Exam _self;
  final $Res Function(_Exam) _then;

/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? language = null,Object? level = null,Object? status = null,Object? createdAt = null,Object? prompt = freezed,Object? answer = freezed,Object? result = freezed,Object? gradedAt = freezed,}) {
  return _then(_Exam(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as LearningLanguage,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as ExamLevel,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExamStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,prompt: freezed == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as ExamPrompt?,answer: freezed == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ExamResult?,gradedAt: freezed == gradedAt ? _self.gradedAt : gradedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExamPromptCopyWith<$Res>? get prompt {
    if (_self.prompt == null) {
    return null;
  }

  return $ExamPromptCopyWith<$Res>(_self.prompt!, (value) {
    return _then(_self.copyWith(prompt: value));
  });
}/// Create a copy of Exam
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExamResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ExamResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
