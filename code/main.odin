package server

import "core:fmt"
import "core:net"
import "core:thread"
import "core:container/queue"
import "core:sync"

mutex: sync.Mutex
condition_variable: sync.Cond

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

    THREAD_COUNT :: 10
    threads: [THREAD_COUNT]^thread.Thread
    connections: queue.Queue(net.TCP_Socket)
    queue.init(&connections)

    
    for i in 0 ..< THREAD_COUNT {
		threads[i] = thread.create_and_start_with_poly_data(&connections, serve_thread)
	}

    for {
        client, source, err := net.accept_tcp(socket)
        if err != nil {
            fmt.eprintln("accept_tcp error:", err)
            return
        }
        sync.lock(&mutex)
        queue.push_back(&connections, client)
        sync.signal(&condition_variable)
        sync.unlock(&mutex)
    }
}

serve_thread :: proc(connections: ^queue.Queue(net.TCP_Socket)) {
    for {
        sync.lock(&mutex)
        sync.cond_wait(&condition_variable, &mutex)
        client, ok := queue.pop_front_safe(connections)
        sync.unlock(&mutex)
        if ok {
             fmt.println("Received request")

            BUFFER_SIZE :: 4096
            buff: [BUFFER_SIZE]byte
        
            size, err := net.recv_tcp(client, buff[:])
            if err != nil {
                fmt.eprintln("recv_tcp error:", err)
                return
            }

            fmt.printfln("Received: %v", string(buff[:size]))
        }
    }
}