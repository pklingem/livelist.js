class window.Utilities
  setOptions: (options, context = @) =>
    _.each( options, (value, option) => context[option] = value )
