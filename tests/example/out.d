import std.typecons : Tuple;
import std.variant : Algebraic;

alias Foo = Tuple!(
string, "following_url",
string, "avatar_url",
long, "public_gists",
string, "gravatar_id",
string, "html_url",
string, "created_at",
typeof(null), "bio",
string, "repos_url",
string, "events_url",
string, "updated_at",
string, "location",
long, "followers",
long, "following",
string, "login",
string, "company",
string, "type",
long, "public_repos",
long, "_1number_key",
string, "blog",
long, "id",
string, "subscriptions_url",
string, "received_events_url",
string, "starred_url",
string, "name",
bool, "hireable",
string, "url",
string, "gists_url",
string, "followers_url",
string, "email",
string, "organizations_url"
);