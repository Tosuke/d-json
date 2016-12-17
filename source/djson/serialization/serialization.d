module djson.serialization.serialization;

import std.json;
import std.conv : to;
import std.variant : Algebraic, isAlgebraic, visit, VariantN;


///serialize to JSON
string serializeToJSON(Type)(Type value, in bool pretty = false, in JSONOptions options = JSONOptions.none){
  auto jv = serializeToJSONValue(value);
  return toJSON(jv, pretty, options);
}

///serialize to JSONValue
JSONValue serializeToJSONValue(Type)(Type value){
  
  static assert(isSerializableType!Type, "type '"~Type.stringof~"' cannot serialize");

  JSONValue jv;

  static if(is(Unqual!Type == JSONValue)){
    jv = value;

  }else static if(isAlgebraic!Type && is(Unqual!Type == VariantN!(N, Args), size_t N, Args...)){
    import std.meta : staticMap;
    enum Func(T) = (T a) => serializeToJSONValue(a);
    jv = value.visit!(staticMap!(Func, Args));

  }else static if(isIntegerType!Type){
    jv.integer = value.to!long;
  
  }else static if(isFloatingType!Type){
    jv.floating = value.to!double;
  
  }else static if(isStringType!Type){
    jv.str = value.to!string;
  
  }else static if(isBooleanType!Type){
    jv = JSONValue(value);
  
  }else static if(isNullType!Type){
    jv = JSONValue(null);

  }else static if(isArrayType!Type){
    jv.array = serializeToJSONArray(value);
  
  }else static if(isObjectType!Type){
    jv.object = serializeToJSONObject(value);
  
  }else{
    static assert(0);
  }

  return jv;
}

private:

import djson.serialization.internal;
import std.meta, std.traits, std.typecons;


JSONValue[string] serializeToJSONObject(Type)(Type value) if(isObjectType!Type) {
  JSONValue[string] jv;

  static if(isFullyNamedTuple!Type){
    enum symbols = Filter!(ApplyLeft!(isGetter, Type), Type.fieldNames);

    foreach(sym; symbols){
      jv[sym] = serializeToJSONValue(__traits(getMember, value, sym));
    }

  }else static if((is(Type == struct) || is(Type == class))){
    alias S = Type;
    enum serializeSymbols = Filter!(ApplyLeft!(isSerializable, S), Filter!(ApplyLeft!(isGetter, S), members!S));

    foreach(sym; serializeSymbols){
      jv[sym] = serializeToJSONValue(__traits(getMember, value, sym));
    }
  }else static if(isAssociativeArray!Type){
    foreach(a; value.byKeyValue){
      jv[a.key] = serializeToJSONValue(a.value);
    }
  }

  jv.rehash;
  return jv;
}


JSONValue[] serializeToJSONArray(Type)(Type value) if(isArrayType!Type) {
  import std.algorithm : map;
  import std.array : array;
  
  JSONValue[] jv;

  static if(isStaticArray!Type || isDynamicArray!Type || isTuple!Type){
    static if(isStaticArray!Type){
      jv = new JSONValue[Type.length];
    }else static if(isDynamicArray!Type){
      jv = new JSONValue[value.length];
    }else static if(isTuple!Type){
      jv = new JSONValue[Type.Types.length];
    }

    foreach(i, a; value){
      jv[i] = serializeToJSONValue(a);
    }
  
  }else{
    import std.range.primitives : isInputRange;
    static if(isInputRange!Type){
      auto r = value;
    }else{
      auto r = value[];
    }
    jv = r.map!(a => serializeToJSONValue(a)).array;

  }

  return jv;
}

unittest{
  import std.container : SList;
  
  struct S{
    int a;
    string srt;
    double hoge = 3.14;

    int prop() @property {
      return a;
    }
    void prop(int v) @property {
      a = v;
    }

    enum Hoge = 1;

    int[] arr = [1, 1, 4, 5, 1, 4];

    interface IHoge{}
  }

  //enum variables = Filter!(ApplyLeft!(isSerializable, S), Filter!(isVariable!S, members!S));
  //pragma(msg, [variables]);

  //enum properties = Filter!(ApplyLeft!(isSerializable, S), Filter!(isProperty!S, Filter!(isFunction!S, members!S)));
  //pragma(msg, [properties]);

  import std.stdio : writeln;
  auto a = serializeToJSON(S.init);
  a.writeln;

  Tuple!(int, "x", int, "y") hoge;
  auto b = serializeToJSON(hoge);
  b.writeln;

  auto c = SList!int(8, 1, 0);
  serializeToJSONValue(c).writeln;

  ["a": JSONValue(10), "b": JSONValue(20)].serializeToJSON.writeln;
  
  alias A = Algebraic!(int, string);
  A alg;
  alg = 45;
  alg.serializeToJSON.writeln;

  null.serializeToJSON.writeln;
}
