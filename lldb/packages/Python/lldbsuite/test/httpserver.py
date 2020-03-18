# -*- coding: utf-8 -*-
"""
The http module contains an easy and ready-to-use HTTP file server.

o ServeDirectoryWithHTTP: Spawns an HTTP file server in a separate thread.
"""

import http.server
from threading import Thread, current_thread
from sys import stderr
from functools import partial


def ServeDirectoryWithHTTP(directory=".", port=0, hostname="localhost"):
    """Spawns an http.server.HTTPServer in a separate thread on the given port.

    The server serves files from the given *directory*.

    Parameters
    ----------
    directory : str, optional
        The directory to server files from. Defaults to the current directory.

    port : int, optional
        If port is 0 (the default), the port will be picked by the operating
        system. For testing it makes sense to use a port chosen by the OS
        because it is guaranteed to be free and not in use.

    hostname : str, optional
        The hostname to open the socket on. Defaults to "localhost".

    Returns
    -------
    http.server.HTTPServer
        The HTTP server which is serving files from a separate thread.

        It is not super necessary but you might want to call shutdown() on the
        returned HTTP server object. This will stop the inifinite request loop
        running in the thread which in turn will then exit. The reason why this
        is only optional is that the thread in which the server runs is a daemon
        thread which will be terminated when the main thread ends.

        By calling shutdown() you'll get a cleaner shutdown because the socket
        is properly closed.

    str
        The address of the server as a string, e.g. "http://localhost:1234".

    Examples
    --------
    >>> from httpserver import ServeDirectoryWithHTTP
    >>> from urllib.request import urlopen
    >>> httpd, address = ServeDirectoryWithHTTP()
    >>> print("Address:", address) # doctest:+ELLIPSIS
    ...
    Address: http://localhost...:...
    >>> try:
    ...     url = address + "/httpserver.py"
    ...     print("Getting URL:", url) # doctest:+ELLIPSIS
    ...     with urlopen(url) as f:
    ...         print("Code:", f.getcode())
    ... finally:
    ...     httpd.shutdown()
    ...
    Getting URL: http://localhost...:.../httpserver.py
    Code: 200

    In the example above, you can call f.read() to read the content of the file
    you've asked for.

    """

    handler = partial(_SimpleRequestHandler, directory=directory)
    httpd = http.server.HTTPServer((hostname, port), handler, False)
    # Block only for 0.5 seconds max
    httpd.timeout = 0.5
    # Allow for reusing the address
    # HTTPServer sets this as well but I wanted to make this more obvious.
    httpd.allow_reuse_address = True

    # Bind to get a port
    _xprint("bind server")
    httpd.server_bind()

    address = "http://%s:%d" % (httpd.server_name, httpd.server_port)

    _xprint("server is about to listen")
    httpd.server_activate()

    def serve_forever(httpd):
        with httpd:  # to make sure httpd.server_close is called
            _xprint("entering infinite request loop")
            httpd.serve_forever()
            _xprint("left infinite request loop")

    thread = Thread(target=serve_forever, args=(httpd, ))
    thread.setDaemon(True)
    thread.start()

    return httpd, address


def _xprint(*args, **kwargs):
    """Wrapper function around print() that prepends the current thread name"""
    print("[", current_thread().name, "]",
          " ".join(map(str, args)), **kwargs, file=stderr)


class _SimpleRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Same as SimpleHTTPRequestHandler except that we prefix the current thread
    name to any given log message.
    """

    def log_message(self, format, *args):
        stderr.write("[ " + current_thread().name + " ] ")
        http.server.SimpleHTTPRequestHandler.log_message(self, format, *args)


if __name__ == "__main__":
    from doctest import testmod
    testmod(verbose=True)
