// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CorrectionItem {

/// Fragment fautif, tel qu'écrit par l'utilisateur.
 String get original; String get corrected; ErrorCategory get category; String get explanation;
/// Create a copy of CorrectionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorrectionItemCopyWith<CorrectionItem> get copyWith => _$CorrectionItemCopyWithImpl<CorrectionItem>(this as CorrectionItem, _$identity);

  /// Serializes this CorrectionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CorrectionItem&&(identical(other.original, original) || other.original == original)&&(identical(other.corrected, corrected) || other.corrected == corrected)&&(identical(other.category, category) || other.category == category)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,original,corrected,category,explanation);

@override
String toString() {
  return 'CorrectionItem(original: $original, corrected: $corrected, category: $category, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $CorrectionItemCopyWith<$Res>  {
  factory $CorrectionItemCopyWith(CorrectionItem value, $Res Function(CorrectionItem) _then) = _$CorrectionItemCopyWithImpl;
@useResult
$Res call({
 String original, String corrected, ErrorCategory category, String explanation
});




}
/// @nodoc
class _$CorrectionItemCopyWithImpl<$Res>
    implements $CorrectionItemCopyWith<$Res> {
  _$CorrectionItemCopyWithImpl(this._self, this._then);

  final CorrectionItem _self;
  final $Res Function(CorrectionItem) _then;

/// Create a copy of CorrectionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? original = null,Object? corrected = null,Object? category = null,Object? explanation = null,}) {
  return _then(_self.copyWith(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ErrorCategory,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CorrectionItem].
extension CorrectionItemPatterns on CorrectionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CorrectionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CorrectionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CorrectionItem value)  $default,){
final _that = this;
switch (_that) {
case _CorrectionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CorrectionItem value)?  $default,){
final _that = this;
switch (_that) {
case _CorrectionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String original,  String corrected,  ErrorCategory category,  String explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CorrectionItem() when $default != null:
return $default(_that.original,_that.corrected,_that.category,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String original,  String corrected,  ErrorCategory category,  String explanation)  $default,) {final _that = this;
switch (_that) {
case _CorrectionItem():
return $default(_that.original,_that.corrected,_that.category,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String original,  String corrected,  ErrorCategory category,  String explanation)?  $default,) {final _that = this;
switch (_that) {
case _CorrectionItem() when $default != null:
return $default(_that.original,_that.corrected,_that.category,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CorrectionItem implements CorrectionItem {
  const _CorrectionItem({required this.original, required this.corrected, required this.category, required this.explanation});
  factory _CorrectionItem.fromJson(Map<String, dynamic> json) => _$CorrectionItemFromJson(json);

/// Fragment fautif, tel qu'écrit par l'utilisateur.
@override final  String original;
@override final  String corrected;
@override final  ErrorCategory category;
@override final  String explanation;

/// Create a copy of CorrectionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorrectionItemCopyWith<_CorrectionItem> get copyWith => __$CorrectionItemCopyWithImpl<_CorrectionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CorrectionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CorrectionItem&&(identical(other.original, original) || other.original == original)&&(identical(other.corrected, corrected) || other.corrected == corrected)&&(identical(other.category, category) || other.category == category)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,original,corrected,category,explanation);

@override
String toString() {
  return 'CorrectionItem(original: $original, corrected: $corrected, category: $category, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$CorrectionItemCopyWith<$Res> implements $CorrectionItemCopyWith<$Res> {
  factory _$CorrectionItemCopyWith(_CorrectionItem value, $Res Function(_CorrectionItem) _then) = __$CorrectionItemCopyWithImpl;
@override @useResult
$Res call({
 String original, String corrected, ErrorCategory category, String explanation
});




}
/// @nodoc
class __$CorrectionItemCopyWithImpl<$Res>
    implements _$CorrectionItemCopyWith<$Res> {
  __$CorrectionItemCopyWithImpl(this._self, this._then);

  final _CorrectionItem _self;
  final $Res Function(_CorrectionItem) _then;

/// Create a copy of CorrectionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? original = null,Object? corrected = null,Object? category = null,Object? explanation = null,}) {
  return _then(_CorrectionItem(
original: null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as String,corrected: null == corrected ? _self.corrected : corrected // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ErrorCategory,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$JournalEntry {

 String get id; LearningLanguage get language; DateTime get entryDate; String get originalText; String get correctedText;@JsonKey(name: 'correction_items') List<CorrectionItem> get items;/// Mots à réviser tirés de ce journal.
@JsonKey(name: 'vocabulary_items') List<VocabularyItem> get vocabulary;
/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryCopyWith<JournalEntry> get copyWith => _$JournalEntryCopyWithImpl<JournalEntry>(this as JournalEntry, _$identity);

  /// Serializes this JournalEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.entryDate, entryDate) || other.entryDate == entryDate)&&(identical(other.originalText, originalText) || other.originalText == originalText)&&(identical(other.correctedText, correctedText) || other.correctedText == correctedText)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.vocabulary, vocabulary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,entryDate,originalText,correctedText,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(vocabulary));

@override
String toString() {
  return 'JournalEntry(id: $id, language: $language, entryDate: $entryDate, originalText: $originalText, correctedText: $correctedText, items: $items, vocabulary: $vocabulary)';
}


}

/// @nodoc
abstract mixin class $JournalEntryCopyWith<$Res>  {
  factory $JournalEntryCopyWith(JournalEntry value, $Res Function(JournalEntry) _then) = _$JournalEntryCopyWithImpl;
@useResult
$Res call({
 String id, LearningLanguage language, DateTime entryDate, String originalText, String correctedText,@JsonKey(name: 'correction_items') List<CorrectionItem> items,@JsonKey(name: 'vocabulary_items') List<VocabularyItem> vocabulary
});




}
/// @nodoc
class _$JournalEntryCopyWithImpl<$Res>
    implements $JournalEntryCopyWith<$Res> {
  _$JournalEntryCopyWithImpl(this._self, this._then);

  final JournalEntry _self;
  final $Res Function(JournalEntry) _then;

/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? language = null,Object? entryDate = null,Object? originalText = null,Object? correctedText = null,Object? items = null,Object? vocabulary = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as LearningLanguage,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,originalText: null == originalText ? _self.originalText : originalText // ignore: cast_nullable_to_non_nullable
as String,correctedText: null == correctedText ? _self.correctedText : correctedText // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CorrectionItem>,vocabulary: null == vocabulary ? _self.vocabulary : vocabulary // ignore: cast_nullable_to_non_nullable
as List<VocabularyItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalEntry].
extension JournalEntryPatterns on JournalEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalEntry value)  $default,){
final _that = this;
switch (_that) {
case _JournalEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalEntry value)?  $default,){
final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LearningLanguage language,  DateTime entryDate,  String originalText,  String correctedText, @JsonKey(name: 'correction_items')  List<CorrectionItem> items, @JsonKey(name: 'vocabulary_items')  List<VocabularyItem> vocabulary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
return $default(_that.id,_that.language,_that.entryDate,_that.originalText,_that.correctedText,_that.items,_that.vocabulary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LearningLanguage language,  DateTime entryDate,  String originalText,  String correctedText, @JsonKey(name: 'correction_items')  List<CorrectionItem> items, @JsonKey(name: 'vocabulary_items')  List<VocabularyItem> vocabulary)  $default,) {final _that = this;
switch (_that) {
case _JournalEntry():
return $default(_that.id,_that.language,_that.entryDate,_that.originalText,_that.correctedText,_that.items,_that.vocabulary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LearningLanguage language,  DateTime entryDate,  String originalText,  String correctedText, @JsonKey(name: 'correction_items')  List<CorrectionItem> items, @JsonKey(name: 'vocabulary_items')  List<VocabularyItem> vocabulary)?  $default,) {final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
return $default(_that.id,_that.language,_that.entryDate,_that.originalText,_that.correctedText,_that.items,_that.vocabulary);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _JournalEntry implements JournalEntry {
  const _JournalEntry({required this.id, required this.language, required this.entryDate, required this.originalText, required this.correctedText, @JsonKey(name: 'correction_items') required final  List<CorrectionItem> items, @JsonKey(name: 'vocabulary_items') final  List<VocabularyItem> vocabulary = const <VocabularyItem>[]}): _items = items,_vocabulary = vocabulary;
  factory _JournalEntry.fromJson(Map<String, dynamic> json) => _$JournalEntryFromJson(json);

@override final  String id;
@override final  LearningLanguage language;
@override final  DateTime entryDate;
@override final  String originalText;
@override final  String correctedText;
 final  List<CorrectionItem> _items;
@override@JsonKey(name: 'correction_items') List<CorrectionItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Mots à réviser tirés de ce journal.
 final  List<VocabularyItem> _vocabulary;
/// Mots à réviser tirés de ce journal.
@override@JsonKey(name: 'vocabulary_items') List<VocabularyItem> get vocabulary {
  if (_vocabulary is EqualUnmodifiableListView) return _vocabulary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vocabulary);
}


/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalEntryCopyWith<_JournalEntry> get copyWith => __$JournalEntryCopyWithImpl<_JournalEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JournalEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.entryDate, entryDate) || other.entryDate == entryDate)&&(identical(other.originalText, originalText) || other.originalText == originalText)&&(identical(other.correctedText, correctedText) || other.correctedText == correctedText)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._vocabulary, _vocabulary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,entryDate,originalText,correctedText,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_vocabulary));

@override
String toString() {
  return 'JournalEntry(id: $id, language: $language, entryDate: $entryDate, originalText: $originalText, correctedText: $correctedText, items: $items, vocabulary: $vocabulary)';
}


}

/// @nodoc
abstract mixin class _$JournalEntryCopyWith<$Res> implements $JournalEntryCopyWith<$Res> {
  factory _$JournalEntryCopyWith(_JournalEntry value, $Res Function(_JournalEntry) _then) = __$JournalEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, LearningLanguage language, DateTime entryDate, String originalText, String correctedText,@JsonKey(name: 'correction_items') List<CorrectionItem> items,@JsonKey(name: 'vocabulary_items') List<VocabularyItem> vocabulary
});




}
/// @nodoc
class __$JournalEntryCopyWithImpl<$Res>
    implements _$JournalEntryCopyWith<$Res> {
  __$JournalEntryCopyWithImpl(this._self, this._then);

  final _JournalEntry _self;
  final $Res Function(_JournalEntry) _then;

/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? language = null,Object? entryDate = null,Object? originalText = null,Object? correctedText = null,Object? items = null,Object? vocabulary = null,}) {
  return _then(_JournalEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as LearningLanguage,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,originalText: null == originalText ? _self.originalText : originalText // ignore: cast_nullable_to_non_nullable
as String,correctedText: null == correctedText ? _self.correctedText : correctedText // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CorrectionItem>,vocabulary: null == vocabulary ? _self._vocabulary : vocabulary // ignore: cast_nullable_to_non_nullable
as List<VocabularyItem>,
  ));
}


}


/// @nodoc
mixin _$JournalAllowance {

 int get maxSentences; int get maxCharacters; int get correctionsLeft;
/// Create a copy of JournalAllowance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalAllowanceCopyWith<JournalAllowance> get copyWith => _$JournalAllowanceCopyWithImpl<JournalAllowance>(this as JournalAllowance, _$identity);

  /// Serializes this JournalAllowance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalAllowance&&(identical(other.maxSentences, maxSentences) || other.maxSentences == maxSentences)&&(identical(other.maxCharacters, maxCharacters) || other.maxCharacters == maxCharacters)&&(identical(other.correctionsLeft, correctionsLeft) || other.correctionsLeft == correctionsLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxSentences,maxCharacters,correctionsLeft);

@override
String toString() {
  return 'JournalAllowance(maxSentences: $maxSentences, maxCharacters: $maxCharacters, correctionsLeft: $correctionsLeft)';
}


}

/// @nodoc
abstract mixin class $JournalAllowanceCopyWith<$Res>  {
  factory $JournalAllowanceCopyWith(JournalAllowance value, $Res Function(JournalAllowance) _then) = _$JournalAllowanceCopyWithImpl;
@useResult
$Res call({
 int maxSentences, int maxCharacters, int correctionsLeft
});




}
/// @nodoc
class _$JournalAllowanceCopyWithImpl<$Res>
    implements $JournalAllowanceCopyWith<$Res> {
  _$JournalAllowanceCopyWithImpl(this._self, this._then);

  final JournalAllowance _self;
  final $Res Function(JournalAllowance) _then;

/// Create a copy of JournalAllowance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxSentences = null,Object? maxCharacters = null,Object? correctionsLeft = null,}) {
  return _then(_self.copyWith(
maxSentences: null == maxSentences ? _self.maxSentences : maxSentences // ignore: cast_nullable_to_non_nullable
as int,maxCharacters: null == maxCharacters ? _self.maxCharacters : maxCharacters // ignore: cast_nullable_to_non_nullable
as int,correctionsLeft: null == correctionsLeft ? _self.correctionsLeft : correctionsLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalAllowance].
extension JournalAllowancePatterns on JournalAllowance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalAllowance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalAllowance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalAllowance value)  $default,){
final _that = this;
switch (_that) {
case _JournalAllowance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalAllowance value)?  $default,){
final _that = this;
switch (_that) {
case _JournalAllowance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxSentences,  int maxCharacters,  int correctionsLeft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalAllowance() when $default != null:
return $default(_that.maxSentences,_that.maxCharacters,_that.correctionsLeft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxSentences,  int maxCharacters,  int correctionsLeft)  $default,) {final _that = this;
switch (_that) {
case _JournalAllowance():
return $default(_that.maxSentences,_that.maxCharacters,_that.correctionsLeft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxSentences,  int maxCharacters,  int correctionsLeft)?  $default,) {final _that = this;
switch (_that) {
case _JournalAllowance() when $default != null:
return $default(_that.maxSentences,_that.maxCharacters,_that.correctionsLeft);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _JournalAllowance implements JournalAllowance {
  const _JournalAllowance({required this.maxSentences, required this.maxCharacters, required this.correctionsLeft});
  factory _JournalAllowance.fromJson(Map<String, dynamic> json) => _$JournalAllowanceFromJson(json);

@override final  int maxSentences;
@override final  int maxCharacters;
@override final  int correctionsLeft;

/// Create a copy of JournalAllowance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalAllowanceCopyWith<_JournalAllowance> get copyWith => __$JournalAllowanceCopyWithImpl<_JournalAllowance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JournalAllowanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalAllowance&&(identical(other.maxSentences, maxSentences) || other.maxSentences == maxSentences)&&(identical(other.maxCharacters, maxCharacters) || other.maxCharacters == maxCharacters)&&(identical(other.correctionsLeft, correctionsLeft) || other.correctionsLeft == correctionsLeft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxSentences,maxCharacters,correctionsLeft);

@override
String toString() {
  return 'JournalAllowance(maxSentences: $maxSentences, maxCharacters: $maxCharacters, correctionsLeft: $correctionsLeft)';
}


}

/// @nodoc
abstract mixin class _$JournalAllowanceCopyWith<$Res> implements $JournalAllowanceCopyWith<$Res> {
  factory _$JournalAllowanceCopyWith(_JournalAllowance value, $Res Function(_JournalAllowance) _then) = __$JournalAllowanceCopyWithImpl;
@override @useResult
$Res call({
 int maxSentences, int maxCharacters, int correctionsLeft
});




}
/// @nodoc
class __$JournalAllowanceCopyWithImpl<$Res>
    implements _$JournalAllowanceCopyWith<$Res> {
  __$JournalAllowanceCopyWithImpl(this._self, this._then);

  final _JournalAllowance _self;
  final $Res Function(_JournalAllowance) _then;

/// Create a copy of JournalAllowance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxSentences = null,Object? maxCharacters = null,Object? correctionsLeft = null,}) {
  return _then(_JournalAllowance(
maxSentences: null == maxSentences ? _self.maxSentences : maxSentences // ignore: cast_nullable_to_non_nullable
as int,maxCharacters: null == maxCharacters ? _self.maxCharacters : maxCharacters // ignore: cast_nullable_to_non_nullable
as int,correctionsLeft: null == correctionsLeft ? _self.correctionsLeft : correctionsLeft // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HistoryOverview {

/// Nombre de jours d'historique lisibles.
 int get historyDays;/// Journaux plus anciens, conservés mais non lisibles avec cette offre.
 int get lockedEntries;
/// Create a copy of HistoryOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryOverviewCopyWith<HistoryOverview> get copyWith => _$HistoryOverviewCopyWithImpl<HistoryOverview>(this as HistoryOverview, _$identity);

  /// Serializes this HistoryOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryOverview&&(identical(other.historyDays, historyDays) || other.historyDays == historyDays)&&(identical(other.lockedEntries, lockedEntries) || other.lockedEntries == lockedEntries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,historyDays,lockedEntries);

@override
String toString() {
  return 'HistoryOverview(historyDays: $historyDays, lockedEntries: $lockedEntries)';
}


}

/// @nodoc
abstract mixin class $HistoryOverviewCopyWith<$Res>  {
  factory $HistoryOverviewCopyWith(HistoryOverview value, $Res Function(HistoryOverview) _then) = _$HistoryOverviewCopyWithImpl;
@useResult
$Res call({
 int historyDays, int lockedEntries
});




}
/// @nodoc
class _$HistoryOverviewCopyWithImpl<$Res>
    implements $HistoryOverviewCopyWith<$Res> {
  _$HistoryOverviewCopyWithImpl(this._self, this._then);

  final HistoryOverview _self;
  final $Res Function(HistoryOverview) _then;

/// Create a copy of HistoryOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? historyDays = null,Object? lockedEntries = null,}) {
  return _then(_self.copyWith(
historyDays: null == historyDays ? _self.historyDays : historyDays // ignore: cast_nullable_to_non_nullable
as int,lockedEntries: null == lockedEntries ? _self.lockedEntries : lockedEntries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryOverview].
extension HistoryOverviewPatterns on HistoryOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryOverview value)  $default,){
final _that = this;
switch (_that) {
case _HistoryOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryOverview value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int historyDays,  int lockedEntries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryOverview() when $default != null:
return $default(_that.historyDays,_that.lockedEntries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int historyDays,  int lockedEntries)  $default,) {final _that = this;
switch (_that) {
case _HistoryOverview():
return $default(_that.historyDays,_that.lockedEntries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int historyDays,  int lockedEntries)?  $default,) {final _that = this;
switch (_that) {
case _HistoryOverview() when $default != null:
return $default(_that.historyDays,_that.lockedEntries);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _HistoryOverview implements HistoryOverview {
  const _HistoryOverview({required this.historyDays, required this.lockedEntries});
  factory _HistoryOverview.fromJson(Map<String, dynamic> json) => _$HistoryOverviewFromJson(json);

/// Nombre de jours d'historique lisibles.
@override final  int historyDays;
/// Journaux plus anciens, conservés mais non lisibles avec cette offre.
@override final  int lockedEntries;

/// Create a copy of HistoryOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryOverviewCopyWith<_HistoryOverview> get copyWith => __$HistoryOverviewCopyWithImpl<_HistoryOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoryOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryOverview&&(identical(other.historyDays, historyDays) || other.historyDays == historyDays)&&(identical(other.lockedEntries, lockedEntries) || other.lockedEntries == lockedEntries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,historyDays,lockedEntries);

@override
String toString() {
  return 'HistoryOverview(historyDays: $historyDays, lockedEntries: $lockedEntries)';
}


}

/// @nodoc
abstract mixin class _$HistoryOverviewCopyWith<$Res> implements $HistoryOverviewCopyWith<$Res> {
  factory _$HistoryOverviewCopyWith(_HistoryOverview value, $Res Function(_HistoryOverview) _then) = __$HistoryOverviewCopyWithImpl;
@override @useResult
$Res call({
 int historyDays, int lockedEntries
});




}
/// @nodoc
class __$HistoryOverviewCopyWithImpl<$Res>
    implements _$HistoryOverviewCopyWith<$Res> {
  __$HistoryOverviewCopyWithImpl(this._self, this._then);

  final _HistoryOverview _self;
  final $Res Function(_HistoryOverview) _then;

/// Create a copy of HistoryOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? historyDays = null,Object? lockedEntries = null,}) {
  return _then(_HistoryOverview(
historyDays: null == historyDays ? _self.historyDays : historyDays // ignore: cast_nullable_to_non_nullable
as int,lockedEntries: null == lockedEntries ? _self.lockedEntries : lockedEntries // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
