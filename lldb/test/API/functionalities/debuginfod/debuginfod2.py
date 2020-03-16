#!/usr/bin/env python3
import time
from http.server import SimpleHTTPRequestHandler, HTTPServer
from functools import partialmethod
from contextlib import closing
import threading
import os
import urllib.request
import sys
import socket
import random


def ServeDirectoryWithHTTP(directory, max_test_requests=10):
    """Spawns an HTTPServer in a separate thread on a port picked by the OS.

    The server serves files from the given *directory*.

    This function returns after at least one proper request could be made to
    to server or raises a *TimeoutError*.

    The maximum number of test request is determined by *max_test_requests*.
    Between each test we wait for:
    min(((2^n)+random_number_milliseconds), maximum_backoff)
    where maximum_backoff is 32

    This function returns the HTTP server object and the address of the server
    as a string in the form "http://localhost:1234" where 1234 is the random
    port chosen by the OS.

    Make sure to call *shutdown* on the returned HTTP server when you no longer
    need it. This will stop the inifinite request loop running in the thread
    which will then exit.
    """

    httpd = MyHTTPServer(('localhost', 0), MyRequestHandler, False)
    # Block only for 0.5 seconds max
    httpd.timeout = 0.5
    # Allow for reusing the address
    # HTTPServer sets this as well but I wanted to make this more obvious.
    httpd.allow_reuse_address = True

    # Bind to get a port
    xprint("bind server")
    httpd.server_bind()

    address = "http://%s:%d" % (httpd.server_name, httpd.server_port)

    def serve_forever(httpd):
        with httpd:  # to make sure server_close is called
            xprint("activate server")
            httpd.server_activate()
            xprint("switch to directory:", directory)
            os.chdir(directory)
            # xprint("simulating startup time")
            # time.sleep(10)
            xprint("entering infinite request loop")
            httpd.serve_forever()
            xprint("left infinite request loop")

    thread = threading.Thread(
        target=serve_forever, args=(
            httpd, ), name='http-server')
    thread.setDaemon(True)
    thread.start()

    # query the server until it is ready?
    httpd.server_test_requests_done = False
    status_code = 0
    n = 0
    while status_code != 200:
        n += 1
        if n > 1:
            # exponential backoff
            maximum_backoff = 32
            random_number_milliseconds = random.random() / 1000
            wait_time = min(((2**n)+random_number_milliseconds), maximum_backoff)
            xprint("waiting for:", wait_time)
            time.sleep(wait_time)
        if n > max_test_requests:
            httpd.shutdown()
            raise TimeoutError('server not ready after %d tries' % n)
        try:
            res = urllib.request.urlopen(address, timeout=timeout_per_test_request)
            status_code = res.getcode()
            res.close()
        except (socket.timeout, urllib.error.HTTPError, urllib.error.URLError) as e:
            xprint('request failed:', e)

    # Turn on error handling as normal
    httpd.server_test_requests_done = True

    xprint("server is ready to accept requests (needed %d try/tries)" % n)

    return httpd, address


def xprint(*args, **kwargs):
    """Wrapper function around print() that prepends the current thread name"""
    print("[", threading.current_thread().name, "]",
          " ".join(map(str, args)), **kwargs)


class MyRequestHandler(SimpleHTTPRequestHandler):
    """Same as SimpleHTTPRequestHandler except that we prefix the current thread
    name to any given log message.
    """

    def log_message(self, format, *args):
        sys.stderr.write("[ " + threading.current_thread().name + " ] %s - - [%s] %s\n" %
                         (self.address_string(),
                          self.log_date_time_string(),
                          format % args))


class MyHTTPServer(HTTPServer):
    """Same as HTTPServer except that we can silence error during the server
    startup."""
    server_test_requests_done = False

    def handle_error(self, request, client_address):
        """Only handle errors when the server isn't in the starting phase."""
        if self.server_test_requests_done:
            HTTPServer.handle_error(self, request, client_address)


if __name__ == '__main__':
    try:
        # Block until server is ready to accept requests
        httpd, address = ServeDirectoryWithHTTP(
            '/opt/notnfs/kkleine/debuginfod-test-data/buildroot/')
        try:
            with urllib.request.urlopen(address, timeout=3) as f:
                xprint('status code:', f.getcode())
                print(f.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            xprint('failed to get %s: %s' % (address, e.msg))
        finally:
            xprint('finally shutting down server')
            httpd.shutdown()
    except KeyboardInterrupt:
        xprint("keyboard interrupt")
        pass
    xprint("shutting down")
