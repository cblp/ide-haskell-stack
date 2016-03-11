# Node module dependencies
path = require 'path'
fs   = require 'fs'

# Atom dependencies
{CompositeDisposable, Emitter} = require 'atom'

# Internal dependencies
Util = require 'atom-haskell-utils'
CabalProcess = null

module.exports =
class IdeBackend

  constructor: (@upi, state) ->
    @disposables = new CompositeDisposable

  getActiveProjectPath: ->
    # TODO: This is far from optimal, and it would be better to allow specifying
    # active project here, but I don't have too much time on my hands right now
    # - Nick
    editor = atom.workspace.getActiveTextEditor()
    if editor?.getPath?()?
      path.dirname editor.getPath()
    else
      atom.project.getPaths()[0] ? process.cwd()

  cabalBuild: (cmd, opts) =>
    # TODO: It shouldn't be possible to call this function until cabalProcess
    # exits. Otherwise, problems will ensue.
    cabalRoot = Util.getRootDir @getActiveProjectPath()

    [cabalFile] =
      cabalRoot.getEntriesSync().filter (file) ->
        file.isFile() and file.getBaseName().endsWith '.cabal'

    if cabalFile?
      cabalArgs = atom.config.get('ide-haskell-stack.globalArguments')
      cabalArgs.push cmd
      cabalArgs.push (atom.config.get("ide-haskell-stack.#{cmd}Arguments") ? [])...
      CabalProcess ?= require './cabal-process'
      cabalProcess = new CabalProcess 'stack', cabalArgs, @spawnOpts(cabalRoot), opts
    else
      @cabalFileError()

  spawnOpts: (cabalRoot) ->
    # Setup default opts
    opts =
      cwd: cabalRoot.getPath()
      detached: true
      env: {}
    opts.env[variable] = value for variable, value of process.env

    return opts

  ### Public interface below ###

  build: ->
    @upi.setStatus status: 'progress', progress: 0.0
    @upi.clearMessages ['error', 'warning', 'build']

    cancelActionDisp = null
    @cabalBuild 'build',
      setCancelAction: (action) =>
        cancelActionDisp = @upi.addPanelControl 'ide-haskell-button',
          classes: ['cancel']
          events:
            click: ->
              action
          before: '#progressBar'
      onMsg: (messages) =>
        @upi.addMessages messages
      onProgress: (progress) =>
        @upi.setStatus {status: 'progress', progress}
      onDone: (exitCode, hasError) =>
        cancelActionDisp?.dispose?()
        @upi.setStatus status: 'ready'
        # cabal returns failure when there are type errors _or_ when it can't
        # compile the code at all (i.e., when there are missing dependencies).
        # Since it's hard to distinguish between these days, we look at the
        # parsed errors; if there are any, we assume that it at least managed to
        # start compiling (all dependencies available) and so we ignore the
        # exit code and just report the errors. Otherwise, we show an atom error
        # with the raw stderr output from cabal.
        if exitCode != 0
          if hasError
            @upi.setStatus status: 'warning'
          else
            @upi.setStatus status: 'error'

  clean: ->
    @upi.setStatus status: 'progress'
    @upi.clearMessages ['build']
    @cabalBuild 'clean',
      onMsg: (messages) =>
        @upi.addMessages messages
      onDone: (exitCode) =>
        @upi.setStatus status: 'ready'
        if exitCode != 0
          @upi.setStatus status: 'error'

  test: ->
    @upi.setStatus status: 'progress'
    @upi.clearMessages ['test']
    cancelActionDisp = null
    @cabalBuild 'test',
      setCancelAction: (action) =>
        cancelActionDisp = @upi.addPanelControl 'ide-haskell-button',
          classes: ['cancel']
          events:
            click: ->
              action
          before: '#progressBar'
      onMsg: (messages) =>
        @upi.addMessages (messages
          .filter ({severity}) -> severity is 'build'
          .map (msg) ->
            msg.severity = 'test'
            msg)
      onDone: (exitCode) =>
        cancelActionDisp?.dispose?()
        @upi.setStatus status: 'ready'
        if exitCode != 0
          @upi.setStatus status: 'error'

  cabalFileError: ->
    @upi.addMessages [
      message: 'No cabal file found'
      severity: 'error'
    ]
    @upi.setStatus status: 'error'
