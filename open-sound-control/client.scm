;;
;; open-sound-control/client.scm
;;
;; Copyright © 2023-2026 Thomas White <taw@bitwiz.me.uk>
;;
;; This file is part of Guile-OSC.
;;
;; This library is free software; you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public
;; License as published by the Free Software Foundation; either
;; version 2.1 of the License, or (at your option) any later version.
;;
;; This library is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with this library; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
;; USA

(define-module (open-sound-control client)
  #:use-module (open-sound-control api)
  #:re-export (osc-send
                osc-send-from
                make-osc-address))
