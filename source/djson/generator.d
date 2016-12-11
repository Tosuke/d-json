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
  [
    {
        "login": "ChimeraCoder",
        "id": 376414,
        "avatar_url": "https://avatars.githubusercontent.com/u/376414?v=3",
        "gravatar_id": "",
        "url": "https://api.github.com/users/ChimeraCoder",
        "html_url": "https://github.com/ChimeraCoder",
        "followers_url": "https://api.github.com/users/ChimeraCoder/followers",
        "following_url": "https://api.github.com/users/ChimeraCoder/following{/other_user}",
        "gists_url": "https://api.github.com/users/ChimeraCoder/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/ChimeraCoder/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/ChimeraCoder/subscriptions",
        "organizations_url": "https://api.github.com/users/ChimeraCoder/orgs",
        "repos_url": "https://api.github.com/users/ChimeraCoder/repos",
        "events_url": "https://api.github.com/users/ChimeraCoder/events{/privacy}",
        "received_events_url": "https://api.github.com/users/ChimeraCoder/received_events",
        "type": "User",
        "site_admin": false,
        "name": "Aditya Mukerjee",
        "company": null,
        "blog": "www.adityamukerjee.net",
        "location": "New York, NY",
        "email": null,
        "hireable": true,
        "bio": null,
        "public_repos": 87,
        "public_gists": 38,
        "followers": 127,
        "following": 39,
        "created_at": "2010-08-26T03:27:39Z",
        "updated_at": "2015-03-15T23:45:02Z"
    }
]
  `, "Foo");

  pragma(msg, s); 
  mixin(s);

  Foo test;
  pragma(msg, Foo.stringof);
}

///Generate type definition
string generateTypeFromJSON(string json, string name = "Foo", string moduleName = "") @safe {
  import std.json : parseJSON;
  return generateTypeFromJSONValue(parseJSON(json), name, moduleName);
}


///Generate type definition from JSONValue
string generateTypeFromJSONValue(immutable(JSONValue) json, string name = "Foo", string moduleName = "") pure nothrow @safe {
  immutable moduleSource = moduleName == "" ? "" : "module "~moduleName~"\n\n";
  immutable importSource = "import std.typecons : Tuple;\nimport std.variant : Algebraic;\n";
  immutable typeSource = generateType(json);
  
  try{
    return format(
      "%s%s\nalias %s = %s;",
      moduleSource, importSource, name, typeSource
    );
  }catch(Exception e){
    return "";
  }
}

private:

///Return type name
///JSONValue
string generateType(immutable(JSONValue) json) pure nothrow @safe {
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
          return json.objectNoRef;
        }catch(Exception e){
          //JSONValue.object is nothrow in this case.
          return typeof(json.objectNoRef).init;
        }
      }());
    case JSON_TYPE.ARRAY:
      return generateArray({
        try{
          return json.arrayNoRef;
        }catch(Exception e){
          //JSONValue.arrayNoRef is nothrow in this case.
          return typeof(json.arrayNoRef).init;
        }
      }());
  }
}


///Object type
string generateObject(immutable(JSONValue[string]) json) pure nothrow @trusted {
  import std.algorithm : map, reduce;
  import std.range : zip;
  
  string str = {
    try{
      if(__ctfe){
        return
          zip(json.keys, json.values).
          map!(a => generateType(a[1])~", "~(`"`~a[0].rename~`"`)).
          reduce!((a, b) => a~",\n"~b);
      }else{
        return 
          json.byKeyValue.
          map!(a => generateType(a.value)~", "~(`"`~a.key.rename~`"`)).
          reduce!((a, b) => a~",\n"~b);
      }
    }catch(Exception e){
      return "";
    }
  }();
  
  return "Tuple!("~(str == "" ? "" : "\n"~str~"\n")~")";
}


///rename member name
string rename(string name) pure nothrow @safe {
  if(name.isNeedEscape){
    return "_"~name;
  }else{
    return name;
  }
}

unittest{
  assert(rename("1pass") == "_1pass");
  assert(rename("810") == "_810");
  assert(rename("_1") == "__1");
}

bool isNeedEscape(string name) pure nothrow @safe @nogc {
  import std.string : inPattern;
  
  try{
    foreach(c; name){
      if(inPattern(c, "0-9")) return true;
      if(c != '_') return false;
    }
  }catch(Exception e){
    return false;
  }

  return false;
}


///Array type
string generateArray(immutable(JSONValue[]) json) pure nothrow @safe {
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
      return "Algebraic!(\n"~s~"\n)";
    }
  }();

  return type~"[]";
}