module djson.generator;

private{
  import djson;

  import std.json;
  import std.format;
  import std.typecons : Tuple;
}

unittest{
  import std.stdio : writeln;
  enum s = generateTypeFromJSON(`
    {
      "a":{
        "hoge":334
      }
    }
  `, "Foo");

  pragma(msg, s); 
  mixin(s);

  Foo test;
  test.a.hoge = 334;
}

///Generate type definition
string generateTypeFromJSON(string json, string name = "Foo", string moduleName = ""){
  import std.json : parseJSON;
  return generateTypeFromJSONValue(parseJSON(json), name, moduleName);
}


///Generate type definition from JSONValue
string generateTypeFromJSONValue(immutable(JSONValue) json, string name = "Foo", string moduleName = "") pure {
  immutable moduleSource = moduleName == "" ? "" : format("module %s;\n\n", moduleName);
  immutable importSource = "import std.typecons : Tuple;\nimport std.variant : Algebraic;\n";
  immutable typeSource = generateType(json);
  
  return format(
    "%s%s\nalias %s = %s;",
    moduleSource, importSource, name, typeSource
  );
}

private:

///Return type name
///JSONValue
string generateType(immutable(JSONValue) json) pure {
  return {
    switch(json.type){
      case JSON_TYPE.STRING:
        return `string`;
      case JSON_TYPE.INTEGER, JSON_TYPE.UINTEGER:
        return `long`;
      case JSON_TYPE.FLOAT:
        return `double`;
      case JSON_TYPE.TRUE, JSON_TYPE.FALSE:
        return `bool`;
      case JSON_TYPE.NULL:
        return typeof(null).stringof;
      case JSON_TYPE.OBJECT:
        return generateObject(json.object);
      default:
        assert(0);
    }
  }();
}

///Object type
string generateObject(immutable(JSONValue[string]) json) pure nothrow{
  import std.algorithm, std.range, std.string, std.array;
  import std.exception : ifThrown;
  string str;
  if(__ctfe){
    try{
      str = zip(json.keys, json.values).
            map!(a => generateType(a[1])~", "~(`"`~a[0]~`"`)).
            reduce!((a, b) => a~",\n"~b);
    }catch(Exception e){
      str = "";
    }
  }else{
    try{
      str = json.byKeyValue.
            map!(a => generateType(a.value)~", "~(`"`~a.key~`"`)).
            reduce!((a, b) => a~",\n"~b);
    }catch(Exception e){
      str = "";
    }
  }
  return "Tuple!("~(str == "" ? "" : "\n"~str~"\n")~")";
}