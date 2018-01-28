(use-modules (gnu))
(use-package-modules hurd)

(operating-system
  (host-name "Covenant")
  (timezone "Europe/Paris")
  (locale "en_US.utf8")
  
  ;; Assuming /dev/sdX is the target hard disk, and "my-root" is
  ;; the label of the target root file system.
  (bootloader (grub-configuration (device "/dev/hd2")))

  (kernel gnumach)
  
  (file-systems (cons (file-system
                        (device "my-root")
                        (title 'label)
                        (mount-point "/guix")
                        (type "ext2"))
                      %base-file-systems))
  
  (users (cons (user-account
                (name "prometheus")
                (comment "Welcome to the Hurd")
                (group "users")
                (home-directory "/home/prometheus"))
               %base-user-accounts))

  (packages (cons* 
	     %base-packages-hurd)))
