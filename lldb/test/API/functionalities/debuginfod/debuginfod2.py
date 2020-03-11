#!/usr/bin/env python3
import time
from http.server import SimpleHTTPRequestHandler
from socketserver import TCPServer
from functools import partial


def ServeDirectoryWithHTTP(
        directory="./",
        port_range_to_try=range(
            8000,
            8010),
        hostname='localhost'):
    """Serves files in a directory with HTTP.

    All ports from the port_range_to_try range are tried until we can bind to one.
    """
    Handler = partial(SimpleHTTPRequestHandler, directory=directory)
    Handler.__doc__ = 'A http.server.SimpleHTTPRequestHandler that has a pre-defined directory to serve files from.'

    address_free = False
    # Find an open port by trying to bind to it.
    for port in port_range_to_try:
        # Using "with" to automatically call socketserver.TCPServer.__exit__()
        # which internally calls socketserver.TCPServer.server_close() on the end
        # of the block.
        with TCPServer((hostname, port), Handler, bind_and_activate=False) as httpd:
            # Block only for 1 second max
            httpd.timeout = 1
            # Allow for reusing the address
            httpd.allow_reuse_address = True
            try:
                print(time.asctime(), "Try to bind on: ", httpd.server_address)
                httpd.server_bind()
                address_free = True
            except OSError:
                print(time.asctime(), "Address already in use:",
                      httpd.server_address)
                continue

            if not address_free:
                continue

            print(time.asctime(), "Serving files from ",
                  directory, " on ", httpd.server_address)
            httpd.server_activate()
            httpd.serve_forever()
            return

    # In case no free address was found
    if not address_free:
        raise Exception('No free address was found')


if __name__ == '__main__':
    try:
        ServeDirectoryWithHTTP(
            '/opt/notnfs/kkleine/debuginfod-test-data/buildroot/',
            port_range_to_try=range(
                8000,
                8010))
    except KeyboardInterrupt:
        print(time.asctime(), "Keyboard interrupt")
        # Abort for loop
        pass
