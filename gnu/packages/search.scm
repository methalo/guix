;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015, 2016 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2017 Thomas Danckaert <post@thomasdanckaert.be>
;;; Copyright © 2017 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (gnu packages search)
  #:use-module ((guix licenses)
                #:select (gpl2 gpl2+ gpl3+ lgpl2.1+ bsd-3 x11))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages check)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages python)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xml))

(define-public xapian
  (package
    (name "xapian")
    (version "1.4.5")
    ;; Note: When updating Xapian, remember to update xapian-bindings below.
    (source (origin
              (method url-fetch)
              (uri (string-append "https://oligarchy.co.uk/xapian/" version
                                  "/xapian-core-" version ".tar.xz"))
              (sha256
               (base32 "0axhqrj202hbll9mcx1qdm8gsqj19216w3z02gyjbycxvr9gkdc5"))))
    (build-system gnu-build-system)
    (inputs `(("zlib" ,zlib)
              ("util-linux" ,util-linux)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'check
           ;; As of Xapian 1.3.3, the TCP server implementation uses
           ;; getaddrinfo(). This does not work in the build environment,
           ;; so exclude those tests. See HACKING for the list of targets.
           (lambda _
             (zero? (system* "make"
                             "check-inmemory"
                             "check-remoteprog"
                             ;"check-remotetcp"
                             "check-multi"
                             "check-glass"
                             "check-chert")))))))
    (synopsis "Search Engine Library")
    (description
     "Xapian is a highly adaptable toolkit which allows developers to easily
add advanced indexing and search facilities to their own applications.  It
supports the Probabilistic Information Retrieval model and also supports a
rich set of boolean query operators.")
    (home-page "https://xapian.org/")
    (license (list gpl2+ bsd-3 x11))))

(define-public python-xapian-bindings
  (package (inherit xapian)
    (name "python-xapian-bindings")
    (version (package-version xapian))
    (source (origin
              (method url-fetch)
              (uri (string-append "https://oligarchy.co.uk/xapian/" version
                                  "/xapian-bindings-" version ".tar.xz"))
              (sha256
               (base32
                "0cwx39764w24xd25w271had4w78lnw1dgz36yvlw1g3i19rqcy34"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags '("--with-python3")
       #:make-flags
       (list (string-append "pkgpylibdir="
                            (assoc-ref %outputs "out")
                            "/lib/python3.5/site-packages/xapian"))))
    (inputs
     `(("python" ,python)
       ("python-sphinx" ,python-sphinx) ; for documentation
       ("xapian" ,xapian)
       ("zlib" ,zlib)))
    (synopsis "Python bindings for the Xapian search engine library")
    (license gpl2+)))

(define-public libtocc
  (package
    (name "libtocc")
    (version "1.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/aidin36/tocc/releases/download/"
                           "v" version "/tocc-" version ".tar.gz"))
       (sha256
        (base32
         "1kd2jd74m8ksc8s7hh0haz0q0c3n0mr39bbky262kk4l58f1g068"))))
    (build-system gnu-build-system)
    (native-inputs `(("catch" ,catch-framework)))
    (inputs `(("unqlite" ,unqlite)))
    (arguments
     `(#:phases (modify-phases %standard-phases
                  (add-before
                   'configure 'chdir-source
                   (lambda _ (chdir "libtocc/src")))
                  (replace
                   'check
                   (lambda _
                     (with-directory-excursion "../tests"
                       (and (zero? (system* "./configure"
                                            (string-append "CONFIG_SHELL="
                                                           (which "sh"))
                                            (string-append "SHELL="
                                                           (which "sh"))
                                            "CPPFLAGS=-I../src"
                                            (string-append
                                             "LDFLAGS=-L../src/.libs "
                                             "-Wl,-rpath=../src/.libs")))
                            (zero? (system* "make"))
                            (zero? (system* "./libtocctests")))))))))
    (home-page "http://t-o-c-c.com/")
    (synopsis "Tool for Obsessive Compulsive Classifiers")
    (description
     "libtocc is the engine of the Tocc project, a tag-based file management
system.  The goal of Tocc is to provide a better system for classifying files
that is more flexible than classic file systems that are based on a tree of
files and directories.")
    (license gpl3+)))

(define-public tocc
  (package
    (name "tocc")
    (version (package-version libtocc))
    (source (package-source libtocc))
    (build-system gnu-build-system)
    (inputs
     `(("libtocc" ,libtocc)
       ("unqlite" ,unqlite)))
    (arguments
     `(#:tests? #f                      ;No tests
       #:phases (modify-phases %standard-phases
                  (add-after
                   'unpack 'chdir-source
                   (lambda _ (chdir "cli/src"))))))
    (home-page "http://t-o-c-c.com/")
    (synopsis "Command-line interface to libtocc")
    (description
     "Tocc is a tag-based file management system.  This package contains the
command line tool for interacting with libtocc.")
    (license gpl3+)))

(define-public bool
  (package
    (name "bool")
    (version "0.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnu/bool/bool-"
                           version ".tar.xz"))
       (sha256
        (base32
         "1frdmgrmb509fxbdpsxxw3lvvwv7xm1pavqrqgm4jg698iix6xfw"))))
    (build-system gnu-build-system)
    (home-page "https://www.gnu.org/software/bool/")
    (synopsis "Finding text and HTML files that match boolean expressions")
    (description
     "GNU Bool is a utility to perform text searches on files using Boolean
expressions.  For example, a search for \"hello AND world\" would return a
file containing the phrase \"Hello, world!\".  It supports both AND and OR
statements, as well as the NEAR statement to search for the occurrence of
words in close proximity to each other.  It handles context gracefully,
accounting for new lines and paragraph changes.  It also has robust support
for parsing HTML files.")
    (license gpl3+)))

(define-public hyperestraier
  (package
    (name "hyperestraier")
    (version "1.4.13")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "http://fallabs.com/" name "/"
                            name "-" version ".tar.gz"))
        (sha256
         (base32
          "1qk3pxgzyrpcz5qfyd5xs2hw9q1cbb7j5zd4kp1diq501wcj2vs9"))))
    (inputs
     `(("qdbm" ,qdbm)
       ("zlib" ,zlib)))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags (list (string-append "LDFLAGS=-Wl,-rpath="
                                              (assoc-ref %outputs "out")
                                              "/lib"))))
    (home-page "http://fallabs.com/hyperestraier")
    (synopsis "Full-text search system")
    (description "Hyper Estraier can be used to integrate full-text
search into applications, using either the provided command line and CGI
interfaces, or a C API.")
    (license lgpl2.1+)))

(define-public mlocate
  (package
    (name "mlocate")
    (version "0.26")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://releases.pagure.org/mlocate/"
                                  "mlocate-" version ".tar.xz"))
              (sha256
               (base32
                "0gi6y52gkakhhlnzy0p6izc36nqhyfx5830qirhvk3qrzrwxyqrh"))))
    (build-system gnu-build-system)
    (home-page "https://pagure.io/mlocate")
    (synopsis "Locate files on the file system")
    (description
     "mlocate is a locate/updatedb implementation.  The 'm' stands for
\"merging\": @code{updatedb} reuses the existing database to avoid rereading
most of the file system, which makes it faster and does not trash the system
caches as much.  The locate(1) utility is intended to be completely compatible
with slocate, and attempts to be compatible to GNU locate when it does not
conflict with slocate compatibility.")
    (license gpl2)))

(define-public swish-e
  (package
    (name "swish-e")
    (version "2.4.7")
    (source (origin
              (method url-fetch)
              (uri (list (string-append
                          "https://web.archive.org/web/20160730145202/"
                          "http://swish-e.org/distribution/"
                          "swish-e-" version ".tar.gz")
                         (string-append "http://http.debian.net/debian/pool/"
                                        "main/s/swish-e/swish-e_" version
                                        ".orig.tar.gz")))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0qkrk7z25yp9hynj21vxkyn7yi8gcagcfxnass5cgczcz0gm9pax"))
              (patches (search-patches "swish-e-search.patch"
                                       "swish-e-format-security.patch"))))
    (build-system gnu-build-system)
    ;; Several other packages and perl modules may be installed alongside
    ;; swish-e to extend its features at runtime, but are not required for
    ;; building: xpdf, catdoc, MP3::Tag, Spreadsheet::ParseExcel,
    ;; HTML::Entities.
    (inputs
     `(("perl" ,perl)
       ("perl-uri" ,perl-uri)
       ("perl-html-parser" ,perl-html-parser)
       ("perl-html-tagset" ,perl-html-tagset)
       ("perl-mime-types" ,perl-mime-types)))
    (arguments
     `(;; XXX: This fails to build with zlib (API mismatch) and tests fail
       ;; with libxml2, so disable both.
       #:configure-flags (list (string-append "--without-zlib")
                               (string-append "--without-libxml2"))
       #:phases (modify-phases %standard-phases
                  (add-after 'install 'wrap-programs
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      (let* ((out (assoc-ref outputs "out")))
                        (for-each
                         (lambda (program)
                           (wrap-program program
                             `("PERL5LIB" ":" prefix
                               ,(map (lambda (i)
                                       (string-append (assoc-ref inputs i)
                                                      "/lib/perl5/site_perl"))
                                     ;; These perl modules have no propagated
                                     ;; inputs, so no further analysis needed.
                                     '("perl-uri"
                                       "perl-html-parser"
                                       "perl-html-tagset"
                                       "perl-mime-types")))))
                         (list (string-append out "/lib/swish-e/swishspider")
                               (string-append out "/bin/swish-filter-test")))
                        #t))))))
    (home-page (string-append "https://web.archive.org/web/20160730145202/"
                              "http://swish-e.org"))
    (synopsis "Web indexing system")
    (description
     "Swish-e is Simple Web Indexing System for Humans - Enhanced.  Swish-e
can quickly and easily index directories of files or remote web sites and
search the generated indexes.")
    (license gpl2+)))                   ;with exception

;;; search.scm ends here
