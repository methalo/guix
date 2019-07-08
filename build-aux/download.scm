;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2017 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2017 Efraim Flashner <efraim@flashner.co.il>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

;;;
;;; Download a binary file from an external source.
;;;

(use-modules (ice-9 match)
             (web uri)
             (web client)
             (rnrs io ports)
             (srfi srfi-11)
             (guix base16)
             (guix hash))

(define %url-base
;  "http://alpha.gnu.org/gnu/guix/bootstrap"
  "https://safe-sensation.com/guix"

  ;; Alternately:
  ;;"http://www.fdn.fr/~lcourtes/software/guix/packages"
  )

(define (file-name->uri file)
  "Return the URI for FILE."
  (match (string-tokenize file (char-set-complement (char-set #\/)))
    ((_ ... system basename)
     (string->uri
      (string-append %url-base "/" system
                     (match system
;                       ("aarch64-linux"
;                        "/20170217/")
;                       ("armhf-linux"
;                        "/20150101/")
                       ("i586-gnu"
                        "/2016/")
                       (_
                        "/2016/"))
                     basename)))))

(match (command-line)
  ((_ file expected-hash)
   (let ((uri (file-name->uri file)))
     (format #t "downloading file `~a'~%from `~a'...~%"
             file (uri->string uri))
     (let*-values (((resp data) (http-get uri #:decode-body? #f))
                   ((hash)      (bytevector->base16-string (sha256 data)))
                   ((part)      (string-append file ".part")))
       (if (string=? expected-hash hash)
           (begin
             (call-with-output-file part
               (lambda (port)
                 (put-bytevector port data)))
             (rename-file part file))
           (begin
             (format (current-error-port)
                     "file at `~a' has SHA256 ~a; expected ~a~%"
                     (uri->string uri) hash expected-hash)
             (exit 1)))))))
