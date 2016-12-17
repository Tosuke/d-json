module djson.serialization.internal;

import std.meta : Erase, EraseAll, AliasSeq, anySatisfy;
import std.traits, std.typecons;
import std.range.primitives;
import std.json : JSONValue;
import std.variant : isAlgebraic;

template isSerializableType(T...){
  static if(T.length == 1){
    enum bool isSerializableType =
      is(Unqual!T == JSONValue) ||
      isAlgebraic!T ||

      isSerializableIntegerType!T ||
      isSerializableFloatingType!T ||
      isSerializableStringType!T ||
      isSerializableBooleanType!T ||
      isSerializableNullType!T ||
      isSerializableArrayType!T ||
      isSerializableObjectType!T;
  }else{
    enum bool isSerializableType = false;
  }
}


template isDeserializableType(T...){
  static if(T.length == 1){
    enum bool isDeserializableType = 
      (is(Unqual!T == JSONValue) && isMutable!T) ||
      isAlgebraic!T ||
      isDeserializableIntegerType!T ||
      isDeserializableFloatingType!T ||
      isDeserializableStringType!T ||
      isDeserializableBooleanType!T ||
      isDeserializableNullType!T ||
      isDeserializableArrayType!T ||
      isDeserializableObjectType!T;
  }else{
    enum bool isDeserializableType = false;
  }
}

alias isSerializableIntegerType = isIntegral;
alias isDeserializableIntegerType = isIntegral;
alias isIntegerType = isSerializableIntegerType;


alias isSerializableFloatingType = isFloatingPoint;
alias isDeserializableFloatingType = isFloatingPoint;
alias isFloatingType = isSerializableFloatingType;


alias isSerializableStringType = isSomeString;
alias isDeserializableStringType = isSomeString;
alias isStringType = isSerializableStringType;


alias isSerializableBooleanType = isBoolean;
alias isDeserializableBooleanType = isBoolean;
alias isBooleanType = isSerializableBooleanType;


enum isNullType(T) = is(Unqual!T == typeof(null));
alias isSerializableNullType = isNullType;
alias isDeserializableNullType = isNullType;


template isSerializableObjectType(T){
  static if(isAssociativeArray!T){
    enum bool isSerializableObjectType = is(Unqual!(KeyType!T) == string);
  }else{
    enum bool isSerializableObjectType =
      (is(T == struct) && !isTuple!T) ||
      is(T == class) ||
      isFullyNamedTuple!T;
  }
}


template isDeserializableObjectType(T){
  static if(isAssociativeArray!T){
    enum bool isDeserializableObjectType = is(Unqual!(KeyType!T) == string) && isMutable!T;
  }else{
    enum bool isDeserializableObjectType =
      (is(T == struct) && !isTuple!T) ||
      is(T == class) ||
      isFullyNamedTuple!T;
  }
}


alias isObjectType = isSerializableObjectType;


template isSerializableArrayType(T){
  enum bool isSerializableArrayType =
    !isAssociativeArray!T && !isFullyNamedTuple!T && (
      is(typeof({
        foreach(unused; T.init){}
      })) ||
      is(typeof({
        foreach(unused; T.init[]){}
      }))
    );

}


template isDeserializableArrayType(T){
  enum bool isDeserializableArrayType =
    !isAssociativeArray!T && (
      is(typeof({
        foreach(ref unused; T.init){}
      })) ||
      is(typeof({
        foreach(ref unused; T.init[]){}
      }))
    );
}


alias isArrayType = isSerializableArrayType;


template isFullyNamedTuple(T){
  static if(isTuple!T){
    enum bool isFullyNamedTuple = 
      T.Types.length == EraseAll!("", T.fieldNames).length; 
  }else{
    enum bool isFullyNamedTuple = false;
  }
}


enum members(T) = Erase!("this", AliasSeq!(__traits(derivedMembers, T)));


///Is T.init.s usable as getter?
private template isGetterTmpl(T, string s){
  static if(is(typeof({auto unused = __traits(getMember, T.init, s);}))){
    static if(is(typeof(__traits(getMember, T.init, s)) == T)){
      enum bool isGetterTmpl = false;
    }else{
      static if(is(typeof({auto unused = __traits(getMember, T.init, s)();}))){
        static if(is(typeof(&__traits(getMember, T.init, s)))){
          private template isGetterProperty(alias F){
            enum bool isGetterProperty =
              (functionAttributes!F & FunctionAttribute.property) != 0 &&
              Parameters!F.length == 0;
          }
          enum bool isGetterTmpl =
            anySatisfy!(isGetterProperty, __traits(getOverloads, T, s));
        }else{
          enum bool isGetterTmpl = false;
        }
      }else{
        enum bool isGetterTmpl = true;
      }
    }
  }else{
    enum bool isGetterTmpl = false;
  }
}


template isGetter(T, string s){
  enum bool isGetter = isSetter!(T, s) && isGetterTmpl!(T, s);
}


template isSetter(T, string s){
  static if(is(typeof(&__traits(getMember, T.init, s)))){
    static if(isSomeFunction!(typeof(&__traits(getMember, T.init, s)))){
      private template isSetterProperty(alias F){
        enum bool isSetterProperty =
          (functionAttributes!F & FunctionAttribute.property) != 0 &&
          Parameters!F.length >= 1;
      }

      enum bool isSetter =
        anySatisfy!(isSetterProperty, __traits(getOverloads, T, s));

    }else{
      alias R = typeof(__traits(getMember, T.init, s));
      enum bool isSetter = 
        is(typeof((T a){
          __traits(getMember, a, s) = R.init;
        }));
    }
  }else{
    enum bool isSetter = false;
  }
}


enum bool isProperty(T, string s) = isGetter!(T, s) && isSetter!(T, s);

enum bool isSerializable(T, string s) = isDeserializableType!(typeof(__traits(getMember, T.init, s)));

enum bool isDeserializable(T, string s) = isDeserializableType!(typeof(__traits(getMember, T.init, s)));


template LeftApply(alias Template, args...){
  alias LeftApply(right...) = Template!(args, right);
}
