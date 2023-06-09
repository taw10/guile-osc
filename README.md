Guile-OSC: Open Sound Control for Guile Scheme
==============================================

Guile-OSC is a Guile wrapper for [liblo](https://github.com/radarsat1/liblo),
enabling Open Sound Control clients and servers to be implemented from Scheme.


Getting started
---------------

You will need the development files for Guile and liblo installed, as well as
[Meson](https://mesonbuild.com/).  Then:

```
$ git clone https://github.com/taw10/guile-osc.git guile-osc
$ cd guile-osc
$ meson setup build
$ ninja -C build
$ sudo ninja -C build install
```

Then, to receive OSC messages from within a Guile program:

```
(use-modules (open-sound-control server-thread))

(define osc-server (make-osc-server-thread "osc.udp://:7770"))

(add-osc-method osc-server
                "/my/osc/method"   ;; Method name
                "fi"               ;; Argument types (see liblo manual)
                (lambda (float-arg int-arg)
                   (do-something ...)))

(add-osc-method osc-server
                "/my/other/method"   ;; Method name
                ""                   ;; No arguments
                (lambda ()
                   (do-stuff ...)))
```

If the separate server thread doesn't work for you, there's also a blocking
server option:

```
(use-modules (open-sound-control server))

(define s (make-osc-server "osc.udp://:7770"))

(add-osc-method s ....)

(osc-recv s)  ;; Blocks for 1 second, or until a message is received
```

You can even have multiple blocking servers at once: `(osc-recv server1 server2)`.

To send messages (with parameters):

```
(use-modules (open-sound-control client))

(define osc-send-addr (make-osc-address "osc.udp://localhost:7771"))

(osc-send osc-send-addr "/their/osc/method" 1 2 4)
(osc-send osc-send-addr "/their/other/method" "string-arg")
(osc-send osc-send-addr "/yet/another/method" 0.3 "hello")
```


Licence
-------

LGPL 2.1, the same as liblo itself.
