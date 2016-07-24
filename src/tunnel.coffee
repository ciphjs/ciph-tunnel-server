_      = require('underscore')
url    = require('url')
crypto = require('crypto')

WSServer = require('ws').Server

class Tunnel
    options:
        port: 8080
        host: '0.0.0.0'
        timeout: 2000

    rooms: {}

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

    disconnect: (cn, roomId, clientId)->
        cn.on 'close', =>
            delete @rooms[roomId][clientId]
            @cleanupRooms()

    message: (cn, data)->
        mes = null
        try mes = url.parse data, true
        return if not mes or mes.protocol isnt 'ciph:'

        if mes.host is 'tunnel'
            switch mes.pathname
                when '/connect_room' then @connectRoom cn, mes.query

        else
            @tunnelMessage cn, mes, data

    connectRoom: (cn, q)->
        roomId   = q.room   or @getUID 'r'
        clientId = q.client or @getUID 'c'

        @rooms[roomId] = {} unless @rooms[roomId]
        @rooms[roomId][clientId] = cn

        clearTimeout cn._startTO
        @disconnect cn, roomId, clientId
        @response cn, clientId, roomId, '/hello'

    tunnelMessage: (cn, mes, data)->
        return if not mes.host or not @rooms[mes.host] or not @rooms[mes.host][mes.auth]
        room = @rooms[mes.host]
        currentClient = mes.auth

        for client of room
            unless client is currentClient
                room[client].send data

    response: (cn, c, h, m, q)->
        return unless h

        res = url.format
            protocol: 'ciph:'
            slashes: true
            auth: c or null
            host: h
            pathname: m or null
            query: q or null

        cn?.send res

    getUID: (prefix='')->
        hash = crypto.createHash('md5')
        hash.update _.uniqueId prefix + new Date().getTime()
        return hash.digest('hex').slice(0, 8)

    cleanupRooms: ->
        for room of @rooms
            delete @rooms[room] if _.isEmpty @rooms[room]


module.exports = Tunnel
