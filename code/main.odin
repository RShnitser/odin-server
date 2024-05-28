package server

import "core:fmt"
import "core:net"
import win "core:sys/windows"
import "core:thread"

main :: proc() {
	socket: net.Any_Socket
	endpoint: net.Endpoint
	err: net.Network_Error

	endpoint, err = net.resolve_ip4("localhost:8000")
	if err != nil {
		fmt.eprintln("resolve_ip4 error:", err)
		return
	}

	socket, err = net.create_socket(net.Address_Family.IP4, net.Socket_Protocol.TCP)
	if err != nil {
		fmt.eprintln("create_socket error:", err)
		return
	}

	tcp_socket := socket.(net.TCP_Socket)

	err = net.set_option(tcp_socket, .Reuse_Address, true)
	if err != nil {
		fmt.eprintln("set_option error:", err)
		return
	}

	err = net.bind(tcp_socket, endpoint)
	if err != nil {
		fmt.eprintln("bind error:", err)
		return
	}

	// no bind function in the net library
	BACKLOG :: 1000
	if res := win.listen(win.SOCKET(tcp_socket), BACKLOG); res == win.SOCKET_ERROR {
		err = net.Listen_Error(win.WSAGetLastError())
		fmt.eprintln("listen error:", err)
		return
	}

	defer net.close(tcp_socket)

	THREAD_COUNT :: 10
	threads: [THREAD_COUNT]^thread.Thread

	for i in 0 ..< THREAD_COUNT {
		threads[i] = thread.create_and_start_with_poly_data(tcp_socket, serve_thread)
	}

	//will replace with wait group
	for {


	}
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
}
