package server

import "core:fmt"
import "core:net"
import "core:thread"

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
        thread := thread.create_and_start_with_poly_data(client, serve_thread)
    }
}

serve_thread :: proc(socket: net.TCP_Socket) {
    fmt.println("Received request")

    buffer_size :: 4096
    buff: [buffer_size]byte
   
    size, err := net.recv_tcp(socket, buff[:])
    if err != nil {
        fmt.eprintln("recv_tcp error:", err)
        return
    }

    fmt.printfln("Received: %v", string(buff[:size - 1]))
}