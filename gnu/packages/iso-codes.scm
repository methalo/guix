;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Cyril Roelandt <tipecaml@gmail.com>
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2018 Tobias Geerinckx-Rice <me@tobias.gr>
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

(define-module (gnu packages iso-codes)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages python))

(define-public iso-codes
  (package
    (name "iso-codes")
    (version "3.77")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "https://pkg-isocodes.alioth.debian.org/downloads/iso-codes-"
                   version ".tar.xz"))
             (sha256
              (base32
               "140dgygv22a49xb8x1941xr5ff12cphd9zzwxds98pgrqsj77k91"))))
    (build-system gnu-build-system)
    (inputs
     `(("gettext" ,gettext-minimal)
       ("perl" ,perl)
       ("python" ,python-wrapper)))
    (home-page "https://pkg-isocodes.alioth.debian.org/")
    (synopsis "Various ISO standards")
    (description
     "This package provides lists of various ISO standards (e.g. country,
language, language scripts, and currency names) in one place, rather
than repeated in many programs throughout the system.

Currently there are lists of languages and countries embedded in
several different programs, which leads to dozens of lists of
200 languages, translated into more than 30 languages... not
very efficient.

With this package, we create a single \"gettext domain\" for every
supported ISO standard which contains the translations of
that domain.  It is easy for a programmer to re-use those
translations instead of maintaining their own translation
infrastructure.  Moreover, the programmer does not need to follow
changes in the ISO standard and will not work with outdated
information.")
    (license license:gpl2+)))           ; some bits use the lgpl2
