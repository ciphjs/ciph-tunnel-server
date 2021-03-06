_      = require('underscore')
url    = require('url')
crypto = require('crypto')

WSServer = require('ws').Server

class Tunnel
    options:
        port: 8080
        host: '0.0.0.0'
        timeout: 2000
        protocol: 'ciph:'
        tunnel_name: 'tunnel'

    connections: {}

    constructor: (options) ->
        @options = _.extend {}, @options, options
        @run()

    run: ->
        @_ws = new WSServer port: @options.port, host: @options.host
        @_ws.on 'connection', _.bind @connection, @

    connection: (connection)->
        connection._startTO = setTimeout =>
            connection.close()
        , @options.timeout

        connection.on 'message', _.bind @message, @, connection

    disconnect: (cn, clientId)->
        cn.on 'close', => delete @connections[clientId]

    message: (cn, data)->
        mes = null
        try mes = url.parse data, true
        return if not mes or mes.protocol isnt @options.protocol

        if mes.host is @options.tunnel_name
            switch mes.pathname
                when '/connect'
                    @connect cn, mes.query unless cn._tunnelled

                when '/rename'
                    @rename cn, mes.query if cn._tunnelled

        else if cn._tunnelled and mes.auth
            @tunnelMessage cn, mes, data

    connect: (cn, q)->
        hasParam = !!q.client
        exists   = q.client and !!@connections[q.client]

        clientId = q.client or @getUID 'c'
        clientId = @getUID 'c' if exists

        @connections[clientId] = cn

        clearTimeout cn._startTO
        cn._tunnelled = clientId

        @disconnect cn, clientId
        @response cn, null, @options.tunnel_name, '/connected', client: clientId, exists: exists

    rename: (cn, q)->
        # Do nothing if no client parameter, or already exists or equal with current
        return if not q.client or @connections[q.client] or cn._tunnelled is q.client

        cn.removeAllListeners 'close'

        clientId = q.client
        cn._tunnelled = clientId

        @disconnect cn, clientId
        @response cn, null, @options.tunnel_name, '/connected', client: clientId, exists: false

    tunnelMessage: (cn, mes, data)->
        return if not mes.host or not @connections[mes.host]
        return if mes.auth isnt cn._tunnelled
        @connections[mes.host].send data

    response: (cn, c, h, m, q)->
        return unless h

        res = url.format
            protocol: @options.protocol
            slashes: true
            auth: c or null
            host: h
            pathname: m or null
            query: q or null

        cn?.send res

    getUID: (prefix='')->
        uid = null

        generate = ->
            hash = crypto.createHash('sha1')
            hash.update _.uniqueId prefix + new Date().getTime()
            return hash.digest('hex').slice(0, 8)

        uid = generate() while not uid or @connections[uid] # Collision protection
        return uid


module.exports = Tunnel
