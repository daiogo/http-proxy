require 'socket'

# Defines constants
PROXY_SERVER_PORT = 3000
HTTP_SERVER_PORT = 80

# Opens TCP connection with proxy server
proxy_server_socket = TCPServer.open(PROXY_SERVER_PORT)

# Makes proxy server run forever
loop do
	# Creates a new thread for each incoming request from clients
	Thread.start(proxy_server_socket.accept) do |proxy_client_socket|

		# Retrieves client's HTTP request
		client_request = []
		while line = proxy_client_socket.gets and line !~ /^\s*$/
			# Transfers all request lines to client_request except for the
			# Accept-Encoding line which prevents proxy from reading server's response
			client_request << line.chomp unless line =~ /^Accept-Encoding:.*$/
		end

		# Uses regex to match URL (client_request[1] is the line where the host is specified)
		client_request_hostname = client_request[1].match(/([\da-z\.-]+)\.([a-z\.]{2,6})/).to_s

		# Opens TCP connection with HTTP server on the matched URL
		http_client_socket = TCPSocket.open(client_request_hostname, HTTP_SERVER_PORT)

		# Sends request to HTTP server
		http_client_socket.puts client_request
		http_client_socket.puts "\r\n\r\n"

		# Prints HTTP response code and IP addresses
		response_code = http_client_socket.gets
		puts "Response code: " + response_code
		puts "Proxy server address: " + proxy_client_socket.peeraddr[3]
		puts "HTTP server address: " + http_client_socket.peeraddr[3]
		puts "\n"

		# Gets HTTP server response
		http_server_response = ''
		while line = http_client_socket.gets
			http_server_response += line
		end

		# Checks if it contains the undesired word
		if http_server_response =~ /[Mm]onitorando/
			http_server_response = "<!DOCTYPE html><html><head><title>Warning!</title></head><body><p>Access not authorized!</p></body></html>"
		else
			http_server_response = response_code + http_server_response
		end

		# Sends response to client
		proxy_client_socket.puts http_server_response

		# Close both sockets
		http_client_socket.close
		proxy_client_socket.close
	end
end
