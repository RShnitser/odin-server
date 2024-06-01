package server

import "core:fmt"
import "core:net"
import "core:sync"
import "core:thread"
import "core:time"

threads_closed: sync.Wait_Group

main :: proc() {
	socket: net.TCP_Socket
	endpoint: net.Endpoint
	err: net.Network_Error

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

	sync.wait_group_add(&threads_closed, THREAD_COUNT)
	for i in 0 ..< THREAD_COUNT {
		threads[i] = thread.create_and_start_with_poly_data(socket, serve_thread)
	}

	sync.wait(&threads_closed)
}

serve_thread :: proc(socket: net.TCP_Socket) {
	for {
		client, source, err := net.accept_tcp(socket)
		if err != nil {
			fmt.eprintln("accept_tcp error:", err)
		} else {

			fmt.println("Received request")

			BUFFER_SIZE :: 4096
			buff: [BUFFER_SIZE]byte

			size: int
			size, err = net.recv_tcp(client, buff[:])
			if err != nil {
				fmt.eprintln("recv_tcp error:", err)
				return
			}

			fmt.printfln("Received: %v", string(buff[:size]))
		}
	}

	sync.wait_group_done(&threads_closed)
}
