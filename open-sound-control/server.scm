;;
;; open-sound-control/server.scm
;;
;; Copyright © 2023 Thomas White <taw@bitwiz.me.uk>
;;
;; This file is part of Guile-OSC.
;;
;; Guile-OSC is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
(define-module (open-sound-control server)
  #:use-module (open-sound-control api)
  #:re-export (make-osc-server
                add-osc-method
                add-osc-wildcard
                osc-recv))
