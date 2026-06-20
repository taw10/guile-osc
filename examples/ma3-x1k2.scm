(use-modules (open-sound-control client))
(use-modules (open-sound-control server))

;; Connect to MA3
(define from-ma (make-osc-server "osc.udp://:8001"))
(define to-ma (make-osc-address "osc.udp://127.0.0.1:8000"))
(define (ma-send! path . vals)
  (display path)
  (display vals)
  (newline)
  (apply osc-send-from to-ma from-ma path vals))


;; Connect to x1k2-midi-osc-alsa
(define from-x1k2 (make-osc-server "osc.udp://:7770"))
(define to-x1k2 (make-osc-address "osc.udp://127.0.0.1:7771"))
(osc-send to-x1k2 "/x1k2/buttons/*/set-led" 'off)

(define (send-param param val)
  (lambda () (ma-send! "/cmd"
                       (string-append
                         "Attribute "
                         param
                         " At "
                         (if (> val 0) "+" "-")
                         " "
                         (number->string (abs val))))))

;; Set up encoders
(define (rotary-encoder enc param)
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/inc") ""
                  (send-param param +4))
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/inc-fine") ""
                  (send-param param +1))
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/dec") ""
                  (send-param param -4))
  (add-osc-method from-x1k2 (string-append "/x1k2/encoders/" enc "/dec-fine") ""
                  (send-param param -1)))

(rotary-encoder "1" "Pan")
(rotary-encoder "2" "Tilt")
(rotary-encoder "3" "Zoom")
(rotary-encoder "4" "Focus1")
(rotary-encoder "6" "Dimmer")


(define (executor-fader fadernum button execnum)
  (add-osc-method from-x1k2 (string-append "/x1k2/faders/" fadernum "/value-change")
                  "i" (lambda (lvl) (ma-send! (string-append "/Fader" execnum)
                                              lvl)))
  (add-osc-method from-x1k2 (string-append "/x1k2/buttons/" button "/press")
                  "" (lambda () (ma-send! (string-append "/Key" execnum) 1)))
  (add-osc-method from-x1k2 (string-append "/x1k2/buttons/" button "/release")
                  "" (lambda () (ma-send! (string-append "/Key" execnum) 0)))
  (osc-send to-x1k2 (string-append "/x1k2/buttons/" button "/set-led") 'orange))


(define (executor-pot fadernum button execnum)
  (add-osc-method from-x1k2 (string-append "/x1k2/potentiometers/" fadernum "/value-change")
                  "i" (lambda (lvl) (ma-send! (string-append "/Fader" execnum)
                                              lvl)))
  (add-osc-method from-x1k2 (string-append "/x1k2/buttons/" button "/press")
                  "" (lambda () (ma-send! (string-append "/Key" execnum) 1)))
  (add-osc-method from-x1k2 (string-append "/x1k2/buttons/" button "/release")
                  "" (lambda () (ma-send! (string-append "/Key" execnum) 0)))
  (osc-send to-x1k2 (string-append "/x1k2/buttons/" button "/set-led") 'orange)
  (osc-send to-x1k2 (string-append "/x1k2/potentiometers/" button "/enable")))


;; Set up faders
(executor-fader "1" "A" "201")
(executor-fader "2" "B" "202")
(executor-fader "3" "C" "203")
(executor-fader "4" "D" "204")
(executor-pot "1" "1" "206")

;; Go/stop-back
(define (playback-buttons go stop)
  (osc-send to-x1k2 (string-append go "/set-led") 'green)
  (osc-send to-x1k2 (string-append stop "/set-led") 'red)
  (add-osc-method from-x1k2 (string-append go "/press") ""
                  (lambda () (ma-send! "/cmd" "Go+")))
  (add-osc-method from-x1k2 (string-append stop "/press") ""
                  (lambda () (ma-send! "/cmd" "Go-"))))

(playback-buttons "/x1k2/buttons/LAYER" "/x1k2/buttons/M")
(playback-buttons "/x1k2/buttons/SHIFT" "/x1k2/buttons/P")

(while 1
  (osc-recv from-ma from-x1k2))
