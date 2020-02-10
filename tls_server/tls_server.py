#!/usr/bin/env python3
import sys, socket, ssl

def main(port = 8888, timeout = 600):
    try:
        context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
        context.load_cert_chain(certfile="cert.pem", keyfile="key.pem")

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.settimeout(timeout)

        sock.bind(('', port))
        sock.listen(1)

        print("Started TLS server on port %i" % port)

        while True:
            conn, addr = sock.accept()
            print("Client connected:", addr)

            stream = context.wrap_socket(conn, server_side=True)
            try:
                # Simply echo back to sender
                data = stream.recv(1024)
                print("Received data", data)
                stream.send(data)
                print("Sent data back")
            except ssl.SSLEOFError:
                print("Client closed connection directly after handshake")
            finally:
                stream.shutdown(socket.SHUT_RDWR)
                stream.close()
    finally:
        sock.close()

if __name__ == '__main__':
     main()
