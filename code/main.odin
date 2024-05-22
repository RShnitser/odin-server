package server

import "core:fmt"
import "core:net"

main :: proc(){
    socket : net.TCP_Socket
    endpoint : net.Endpoint
    err : net.Network_Error

    endpoint, err = net.resolve_ip4("localhost:8000")
    if err != nil {
        fmt.eprintln("resolve_ip4 error:", err)
        return
    }

    socket, err = net.listen_tcp(endpoint)
    if err != nil {
        fmt.eprintln("listen_tcp error:", err)
        return
    }

    defer net.close(socket)

    for {
        client, source, err := net.accept_tcp(socket)
        if err != nil {
            fmt.eprintln("accept_tcp error:", err)
            return
        }

        fmt.println("Received request")

        buffer_size :: 4096
        buff: [buffer_size]byte
        size: int
        size, err = net.recv_tcp(client, buff[:])
        if err != nil {
            fmt.eprintln("recv_tcp error:", err)
            return
        }

        fmt.printfln("Received: %v", string(buff[:size - 1]))
    }
}