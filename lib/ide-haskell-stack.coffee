module.exports =
  config:
    globalArguments:
      type: 'array'
      description: 'Global stack arguments (comma-separated)'
      default: []
      order: 10

    buildArguments:
      type: 'array'
      description: 'Stack build command arguments (comma-separated)'
      default: []
      order: 20

    testArguments:
      type: 'array'
      description: 'Stack test command arguments (comma-separated)'
      default: []
      order: 30

  subscriptions: null

  activate: (@state) ->
    @disposables = null

  deactivate: ->
    @disposables?.dispose?()
    @disposables = null

  serialize: -> {}

  consumeUPI: (service) ->
    # Atom dependencies
    {CompositeDisposable} = require 'atom'

    # Internal dependencies
    IdeBackend = require './ide-backend'

    upi = service.registerPlugin @disposables = new CompositeDisposable

    backend = new IdeBackend(upi, @state)

    upi.setMessageTypes
      error: {}
      warning: {}
      build:
        uriFilter: false
        autoScroll: true
      test:
        uriFilter: false
        autoScroll: true

    @disposables.add atom.commands.add 'atom-workspace',
      'ide-haskell-stack:build': ->
        backend.build()
      'ide-haskell-stack:clean': ->
        backend.clean()
      'ide-haskell-stack:test': ->
        backend.test()

    upi.setMenu 'Stack', [
        {label: 'Build Project', command: 'ide-haskell-stack:build'}
        {label: 'Clean Project', command: 'ide-haskell-stack:clean'}
        {label: 'Test', command: 'ide-haskell-stack:test'}
      ]

    @disposables
