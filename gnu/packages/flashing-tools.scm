;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2014 Manolis Fragkiskos Ragkousis <manolis837@gmail.com>
;;; Copyright © 2016 Hartmut Goebel <h.goebel@crazy-compilers.com>
;;; Copyright © 2016 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2017 Jonathan Brielmaier <jonathan.brielmaier@web.de>
;;; Copyright © 2017 Julien Lepiller <julien@lepiller.eu>
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

(define-module (gnu packages flashing-tools)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages libftdi)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages admin))

(define-public flashrom
  (package
    (name "flashrom")
    (version "0.9.9")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://download.flashrom.org/releases/flashrom-"
                    version ".tar.bz2"))
              (sha256
               (base32
                "0i9wg1lyfg99bld7d00zqjm9f0lk6m0q3h3n9c195c9yysq5ccfb"))))
    (build-system gnu-build-system)
    (inputs `(("dmidecode" ,dmidecode)
              ("pciutils" ,pciutils)
              ("libusb" ,libusb)
              ("libftdi" ,libftdi)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (arguments
     '(#:make-flags (list "CC=gcc"
                          (string-append "PREFIX=" %output)
                          "CONFIG_ENABLE_LIBUSB0_PROGRAMMERS=no")
       #:tests? #f   ; no 'check' target
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-before 'build 'patch-exec-paths
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "dmi.c"
               (("\"dmidecode\"")
                (format #f "~S"
                        (string-append (assoc-ref inputs "dmidecode")
                                       "/sbin/dmidecode"))))
             #t)))))
    (home-page "http://flashrom.org/")
    (synopsis "Identify, read, write, erase, and verify ROM/flash chips")
    (description
     "flashrom is a utility for identifying, reading, writing,
verifying and erasing flash chips.  It is designed to flash
BIOS/EFI/coreboot/firmware/optionROM images on mainboards,
network/graphics/storage controller cards, and various other
programmer devices.")
    (license license:gpl2)))

(define-public 0xffff
  (package
    (name "0xffff")
    (version "0.7")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://github.com/pali/0xffff/archive/"
                          version ".tar.gz"))
      (file-name (string-append "0xFFFF" version ".tar.gz" ))
      (sha256
       (base32
        "1g4032c81wkk37wvbg1dxcqq6mnd76y9x7f2crmzqi6z4q9jcxmj"))))
    (build-system gnu-build-system)
    (inputs
     `(("libusb",libusb-0.1))) ; doesn't work with libusb-compat
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (delete 'configure)) ; no configure
       #:make-flags (list (string-append "PREFIX=" %output))
       #:tests? #f)) ; no 'check' target
    (home-page "https://github.com/pali/0xFFFF")
    (synopsis "Flash FIASCO images on Maemo devices")
    (description
     "The Open Free Fiasco Firmware Flasher (0xFFFF) is a flashing tool
for FIASCO images.  It supports generating, unpacking, editing and
flashing of FIASCO images for Maemo devices.  Use it with care.  It can
brick your device.")
    (license license:gpl3+)))

(define-public avrdude
  (package
    (name "avrdude")
    (version "6.1")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://savannah/avrdude/avrdude-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0frxg0q09nrm95z7ymzddx7ysl77ilfbdix1m81d9jjpiv5bm64y"))))
    (build-system gnu-build-system)
    (inputs
     `(("libelf" ,libelf)
       ("libusb" ,libusb-compat)
       ("libftdi" ,libftdi)))
    (native-inputs
     `(("bison" ,bison)
       ("flex" ,flex)))
    (home-page "http://www.nongnu.org/avrdude/")
    (synopsis "AVR downloader and uploader")
    (description
     "AVRDUDE is a utility to download/upload/manipulate the ROM and
EEPROM contents of AVR microcontrollers using the in-system programming
technique (ISP).")
    (license license:gpl2+)))

(define-public dfu-programmer
  (package
    (name "dfu-programmer")
    (version "0.7.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://sourceforge/dfu-programmer/dfu-programmer/"
                          version "/dfu-programmer-" version ".tar.gz"))
      (sha256
       (base32
        "15gr99y1z9vbvhrkd25zqhnzhg6zjmaam3vfjzf2mazd39mx7d0x"))
      (patches (search-patches "dfu-programmer-fix-libusb.patch"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("libusb" ,libusb)))
    (home-page "http://dfu-programmer.github.io/")
    (synopsis "Device firmware update programmer for Atmel chips")
    (description
     "Dfu-programmer is a multi-platform command-line programmer for
Atmel (8051, AVR, XMEGA & AVR32) chips with a USB bootloader supporting
ISP.")
    (license license:gpl2+)))

(define-public dfu-util
  (package
    (name "dfu-util")
    (version "0.9")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://dfu-util.sourceforge.net/releases/dfu-util-"
                    version ".tar.gz"))
              (sha256
               (base32
                "0czq73m92ngf30asdzrfkzraag95hlrr74imbanqq25kdim8qhin"))))
    (build-system gnu-build-system)
    (inputs
     `(("libusb" ,libusb)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (synopsis "Host side of the USB Device Firmware Upgrade (DFU) protocol")
    (description
     "The DFU (Universal Serial Bus Device Firmware Upgrade) protocol is
intended to download and upload firmware to devices connected over USB.  It
ranges from small devices like micro-controller boards up to mobile phones.
With dfu-util you are able to download firmware to your device or upload
firmware from it.")
    (home-page "http://dfu-util.sourceforge.net/")
    (license license:gpl2+)))

(define-public teensy-loader-cli
  ;; The repo does not tag versions nor does it use releases, but a commit
  ;; message says "Importing 2.1", while the sourcce still says "2.0". So pin
  ;; to a fixed commit.
  (let ((commit "f289b7a2e5627464044249f0e5742830e052e360"))
    (package
      (name "teensy-loader-cli")
      (version (string-append "2.1-1." (string-take commit 7)))
      (source
       (origin
         (method url-fetch)
         (uri (string-append "https://github.com/PaulStoffregen/"
                             "teensy_loader_cli/archive/" commit ".tar.gz"))
         (sha256 (base32 "17wqc2q4fa473cy7f5m2yiyb9nq0qw7xal2kzrxzaikgm9rabsw8"))
         (file-name (string-append "teensy-loader-cli-" version ".tar.gz" ))
         (modules '((guix build utils)))
         (snippet
          `(begin
             ;; Remove example flash files and teensy rebooter flash binaries.
             (for-each delete-file (find-files "." "\\.(elf|hex)$"))
             ;; Fix the version
             (substitute* "teensy_loader_cli.c"
               (("Teensy Loader, Command Line, Version 2.0\\\\n")
                (string-append "Teensy Loader, Command Line, " ,version "\\n")))
             #t))
       (patches (search-patches "teensy-loader-cli-help.patch"))))
      (build-system gnu-build-system)
      (arguments
       '(#:tests? #f ;; Makefile has no test target
         #:make-flags (list "CC=gcc" (string-append "PREFIX=" %output))
         #:phases
         (modify-phases %standard-phases
           (delete 'configure)
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (let* ((out (assoc-ref outputs "out"))
                      (bin (string-append out "/bin")))
                 (install-file "teensy_loader_cli" bin)
                 #t))))))
      (inputs
       `(("libusb-compat" ,libusb-compat)))
      (synopsis "Command line firmware uploader for Teensy development boards")
      (description
       "The Teensy loader program communicates with your Teensy board when the
HalfKay bootloader is running, so you can upload new programs and run them.

You need to add the udev rules to make the Teensy update available for
non-root users.")
      (home-page "https://www.pjrc.com/teensy/loader_cli.html")
      (license license:gpl3))))

(define-public rkflashtool
  (let ((commit "094bd6410cb016e487e2ccb1050c59eeac2e6dd1")
        (revision "1"))
    (package
      (name "rkflashtool")
      (version (string-append "0.0.0-" revision "." (string-take commit 7)))
      (source
        (origin
          (method git-fetch)
          (uri (git-reference
                (url "https://github.com/linux-rockchip/rkflashtool.git")
                (commit commit)))
          (file-name (string-append name "-" version "-checkout"))
          (sha256
           (base32
            "1zkd8zxir3rfg3sy9r20bcnxclnplryn583gqpcr3iad0k3xbah7"))))
      (build-system gnu-build-system)
      (arguments
       '(#:phases
         (modify-phases %standard-phases
           (delete 'configure)) ; no configure
         #:make-flags (list (string-append "PREFIX=" %output))
         #:tests? #f)) ; no tests
      (native-inputs
       `(("pkg-config" ,pkg-config)))
      (inputs
       `(("libusb" ,libusb)))
      (home-page "https://github.com/linux-rockchip/rkflashtool")
      (synopsis "Tools for flashing Rockchip devices")
      (description "Allows flashing of Rockchip based embedded linux devices.
The list of currently supported devices is: RK2818, RK2918, RK2928, RK3026,
RK3036, RK3066, RK312X, RK3168, RK3188, RK3288, RK3368.")
      (license license:bsd-2))))

(define-public heimdall
  (package
    (name "heimdall")
    (version "1.4.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/Benjamin-Dobell/Heimdall"
                                  "/archive/v" version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1y7gwg3lipyp2zcysm2vid1qg5nwin9bxbvgzs28lz2rya4fz6sq"))))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags '("-DCMAKE_BUILD_TYPE=Release")
       #:tests? #f; no tests
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-invocations
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* '("heimdall-frontend/source/aboutform.cpp"
                            "heimdall-frontend/source/mainwindow.cpp")
               (("start[(]\"heimdall\"")
                (string-append "start(\"" (assoc-ref outputs "out")
                               "/bin/heimdall\"")))
             #t))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((bin (string-append (assoc-ref outputs "out") "/bin"))
                   (lib (string-append (assoc-ref outputs "out") "/lib")))
               (install-file "bin/heimdall" bin)
               (install-file "bin/heimdall-frontend" bin)
               (install-file "libpit/libpit.a" lib)
               #t))))))
    (inputs
     `(("libusb" ,libusb)
       ("qtbase" ,qtbase)
       ("zlib" ,zlib)))
    (home-page "http://glassechidna.com.au/heimdall/")
    (synopsis "Flash firmware onto Samsung mobile devices")
    (description "@command{heimdall} is a tool suite used to flash firmware (aka
ROMs) onto Samsung mobile devices.  Heimdall connects to a mobile device over
USB and interacts with low-level software running on the device, known as Loke.
Loke and Heimdall communicate via the custom Samsung-developed protocol typically
referred to as the \"Odin 3 protocol\".")
    (license license:expat)))
