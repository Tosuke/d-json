module djson.generation;

private{
  import djson;

  import std.json;
  import std.format;
}


/***********************************************
* Generation error
*
* Throws when invalid key-name (as D symbol).
*/
private class GeneratorException : Exception {
  this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) pure @safe nothrow {
    super(msg, file, line, next);
  }
}

///Generate type definition
string generateTypeFromJSON(string json, string name = "Foo", string moduleName = ""){
  import std.json : parseJSON;
  return generateTypeFromJSONValue(parseJSON(json), name, moduleName);
}


///Generate type definition from JSONValue
string generateTypeFromJSONValue(immutable(JSONValue) json, string name = "Foo", string moduleName = "") pure @safe {
  immutable moduleSource = moduleName == "" ? "" : "module "~moduleName~"\n\n";
  immutable importSource = "static import std.typecons, std.variant;\n\n";
  immutable typeSource = generateType(json);
  
  try{
    return format(
      "%s%salias %s = %s;",
      moduleSource, importSource, name, typeSource
    );
  }catch(Exception e){
    return "";
  }
}

private:

///Return type name
///JSONValue
string generateType(immutable(JSONValue) json) pure @trusted {
  final switch(json.type){
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
      return generateObject({
        try{
          return json.object;
        }catch(Exception e){
          //JSONValue.object is nothrow in this case.
          return typeof(json.object).init;
        }
      }());
    case JSON_TYPE.ARRAY:
      return generateArray({
        try{
          return json.array;
        }catch(Exception e){
          //JSONValue.array is nothrow in this case.
          return typeof(json.array).init;
        }
      }());
  }
}


///Object type
string generateObject(immutable(JSONValue[string]) json) pure @trusted {
  import std.algorithm : map, reduce;
  import std.range : zip;
  import std.exception : ifThrown;
  
  string str = {
    if(__ctfe){
      auto r = zip(json.keys, json.values);
      if(r.empty) return "";
      return  r.
              map!(a => generateType(a[1])~", "~(`"`~a[0].checkIsValid~`"`)).
              reduce!((a, b) => a~",\n"~b);
    }else{
      auto r = json.byKeyValue;
      if(r.empty) return "";
      return  r.
              map!(a => generateType(a.value)~", "~(`"`~a.key.checkIsValid~`"`)).
              reduce!((a, b) => a~",\n"~b);
    }
  }();
  
  return "std.typecons.Tuple!("~(str == "" ? "" : "\n"~str~"\n")~")";
}


///check member name
string checkIsValid(string name) pure @safe {
  import std.string : inPattern;

  if(name[0].inPattern("0-9")){
    throw new GeneratorException(`invalid symbol name '`~name~`'`);
  }

  foreach(c; name[1..$]){
    if(c.inPattern("^a-zA-Z0-9_")){
      throw new GeneratorException(`invalid symbol name '`~name~`'`);
    }
  }

  return name;
}

///Array type
string generateArray(immutable(JSONValue[]) json) pure @safe {
  import std.algorithm : map, filter, reduce, uniq;
  import std.range : walkLength;
  
  string type = {
    auto r =  json.
              map!(a => generateType(a)).
              uniq;
    
    if(r.walkLength == 1){
      //single type
      return r.front;
    }else{
      //multiple types
      if(r.filter!(a => a != "long" && a != "double").empty){
        return "double";
      }

      auto s = {
        try{
          return r.reduce!((a, b) => a~",\n"~b);
        }catch(Exception e){
          return "";
        }
      }();
      return "std.variant.Algebraic!(\n"~s~"\n)";
    }
  }();

  return type~"[]";
}