;;; Guix --- Nix package management from Guile.         -*- coding: utf-8 -*-
;;; Copyright (C) 2012 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of Guix.
;;;
;;; Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guix build-system gnu)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix derivations)
  #:use-module (guix build-system)
  #:use-module (guix packages)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-39)
  #:use-module (ice-9 match)
  #:export (gnu-build
            gnu-build-system
            package-with-explicit-inputs))

;; Commentary:
;;
;; Standard build procedure for packages using the GNU Build System or
;; something compatible ("./configure && make && make install").
;;
;; Code:

(define* (package-with-explicit-inputs p boot-inputs
                                       #:optional
                                       (loc (source-properties->location
                                             (current-source-location))))
  "Rewrite P, which is assumed to use GNU-BUILD-SYSTEM, to take BOOT-INPUTS
as explicit inputs instead of the implicit default, and return it."
  (define rewritten-input
    (match-lambda
     ((name (? package? p) sub-drv ...)
      (cons* name (package-with-explicit-inputs p boot-inputs) sub-drv))
     (x x)))

  (define boot-input-names
    (map car boot-inputs))

  (define (filtered-inputs inputs)
    (fold alist-delete inputs boot-input-names))

  (package (inherit p)
    (location loc)
    (arguments
     (let ((args (package-arguments p)))
       (if (procedure? args)
           (lambda (system)
             `(#:implicit-inputs? #f ,@(args system)))
           `(#:implicit-inputs? #f ,@args))))
    (native-inputs (map rewritten-input
                        (filtered-inputs (package-native-inputs p))))
    (propagated-inputs (map rewritten-input
                            (filtered-inputs
                             (package-propagated-inputs p))))
    (inputs `(,@boot-inputs
              ,@(map rewritten-input
                     (filtered-inputs (package-inputs p)))))))

(define %store
  ;; Store passed to STANDARD-INPUTS.
  (make-parameter #f))

(define standard-inputs
  (memoize
   (lambda (system)
     "Return the list of implicit standard inputs used with the GNU Build
System: GCC, GNU Make, Bash, Coreutils, etc."
     (map (match-lambda
           ((name pkg sub-drv ...)
            (cons* name (package-derivation (%store) pkg system) sub-drv))
           ((name (? derivation-path? path) sub-drv ...)
            (cons* name path sub-drv))
           (z
            (error "invalid standard input" z)))

          ;; Resolve (distro base) lazily to hide circular dependency.
          (let* ((distro (resolve-module '(distro base)))
                 (inputs (module-ref distro '%final-inputs)))
            (append inputs
                    (append-map (match-lambda
                                 ((name package _ ...)
                                  (package-transitive-propagated-inputs package)))
                                inputs)))))))

(define* (gnu-build store name source inputs
                    #:key (outputs '("out")) (configure-flags ''())
                    (make-flags ''())
                    (patches ''()) (patch-flags ''("--batch" "-p1"))
                    (out-of-source? #f)
                    (path-exclusions ''())
                    (tests? #t)
                    (parallel-build? #t) (parallel-tests? #t)
                    (patch-shebangs? #t)
                    (strip-binaries? #t)
                    (strip-flags ''("--strip-debug"))
                    (strip-directories ''("lib" "lib64" "libexec"
                                          "bin" "sbin"))
                    (phases '%standard-phases)
                    (system (%current-system))
                    (implicit-inputs? #t)         ; useful when bootstrapping
                    (modules '((guix build gnu-build-system)
                               (guix build utils))))
  "Return a derivation called NAME that builds from tarball SOURCE, with
input derivation INPUTS, using the usual procedure of the GNU Build System."
  (define builder
    `(begin
       (use-modules ,@modules)
       (gnu-build #:source ,(if (derivation-path? source)
                                (derivation-path->output-path source)
                                source)
                  #:outputs %outputs
                  #:inputs %build-inputs
                  #:patches ,patches
                  #:patch-flags ,patch-flags
                  #:phases ,phases
                  #:configure-flags ,configure-flags
                  #:make-flags ,make-flags
                  #:out-of-source? ,out-of-source?
                  #:path-exclusions ,path-exclusions
                  #:tests? ,tests?
                  #:parallel-build? ,parallel-build?
                  #:parallel-tests? ,parallel-tests?
                  #:patch-shebangs? ,patch-shebangs?
                  #:strip-binaries? ,strip-binaries?
                  #:strip-flags ,strip-flags
                  #:strip-directories ,strip-directories)))

  (build-expression->derivation store name system
                                builder
                                `(("source" ,source)
                                  ,@inputs
                                  ,@(if implicit-inputs?
                                        (parameterize ((%store store))
                                          (standard-inputs system))
                                        '()))
                                #:outputs outputs
                                #:modules modules))

(define gnu-build-system
  (build-system (name 'gnu)
                (description
                 "The GNU Build System—i.e., ./configure && make && make install")
                (build gnu-build)))             ; TODO: add `gnu-cross-build'
