-module(erlang_target).
-export([public_function/1, public_function/2, other_public_function/0]).

public_function(A) ->
	private_function(A).

public_function(A, B) ->
	{ok, A, B}.

other_public_function() ->
	ok.

private_function(A) ->
	{ok, A}.