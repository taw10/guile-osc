(use-modules (open-sound-control client))
(use-modules (open-sound-control server))

;; Connect to Eos
(define from-eos (make-osc-server "osc.tcp://:8000"))
(define to-eos (make-osc-address "osc.tcp://192.168.178.35:8000"))
(define (eos-send! path . vals)
  (apply osc-send-from to-eos from-eos path vals))
(eos-send! "/eos/ping")


;; Connect to x1k2-midi-osc-alsa
(define from-x1k2 (make-osc-server "osc.udp://:7770"))
(define to-x1k2 (make-osc-address "osc.udp://localhost:7771"))
(osc-send to-x1k2 "/x1k2/buttons/*/set-led" 'off)


;; Set up encoders
(define (rotary-encoder enc param)
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/inc") ""
                  (lambda () (eos-send! (string-append "/eos/wheel/" param) 4)))
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/inc-fine") ""
                  (lambda () (eos-send! (string-append "/eos/wheel/" param) 1)))
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/dec") ""
                  (lambda () (eos-send! (string-append "/eos/wheel/" param) -4)))
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/dec-fine") ""
                  (lambda () (eos-send! (string-append "/eos/wheel/" param) -1))))

(rotary-encoder "1" "pan")
(rotary-encoder "2" "tilt")
(rotary-encoder "3" "zoom")
(rotary-encoder "4" "edge")
(rotary-encoder "6" "level")


;; Set up faders
(eos-send! "/eos/fader/1/config/4")
(add-osc-method from-x1k2 "/x1k2/faders/1/value-change" "i"
                (lambda (lvl) (eos-send! "/eos/fader/1/1" (/ lvl 127))))
(add-osc-method from-x1k2 "/x1k2/faders/2/value-change" "i"
                (lambda (lvl) (eos-send! "/eos/fader/1/2" (/ lvl 127))))
(add-osc-method from-x1k2 "/x1k2/faders/3/value-change" "i"
                (lambda (lvl) (eos-send! "/eos/fader/1/3" (/ lvl 127))))
(add-osc-method from-x1k2 "/x1k2/faders/4/value-change" "i"
                (lambda (lvl) (eos-send! "/eos/fader/1/4" (/ lvl 127))))


;; Go/stop-back
(define (playback-buttons go stop)
  (osc-send to-x1k2 (string-append go "/set-led") 'green)
  (osc-send to-x1k2 (string-append stop "/set-led") 'red)
  (add-osc-method from-x1k2 (string-append go "/press") ""
                  (lambda () (eos-send! "/eos/key/go_0")))
  (add-osc-method from-x1k2 (string-append stop "/press") ""
                  (lambda () (eos-send! "/eos/key/stop"))))

(playback-buttons "/x1k2/buttons/LAYER" "/x1k2/buttons/M")
(playback-buttons "/x1k2/buttons/SHIFT" "/x1k2/buttons/P")


(while 1
  (osc-recv from-eos from-x1k2))
