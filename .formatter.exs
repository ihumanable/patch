# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [
    assert_any_call: 2,
    assert_called: 1,
    refute_any_call: 2,
    refute_called: 1
  ],
  exports: [
    locals_without_parens: [
      assert_any_call: 2,
      assert_called: 1,
      refute_any_call: 2,
      refute_called: 1
    ]
  ]
]
