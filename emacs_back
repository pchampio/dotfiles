;; -*- mode: emacs-lisp; -*-

(require 'package) ;; load the built-in package manager
;; add popular repositories
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/") ("melpa" . "https://melpa.org/packages/"))) (setq package-enable-at-startup nil)
(package-initialize) ;; initialize list of packages

;; ensure all packages enabled by use-package are installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(menu-bar-mode -1)
(toggle-scroll-bar -1)
(tool-bar-mode -1)
(setq-default truncate-lines 1)
(toggle-frame-maximized)
;; Ask for y/n instead of "yes"/"no"
(defalias #'yes-or-no-p #'y-or-n-p)
;; Long line speed
(setq-default bidi-display-reordering nil)

(use-package whitespace
  :ensure t
  :config

  ;; don't show whitespace for those mode
  (define-global-minor-mode my-global-whitespace-mode whitespace-mode
    (lambda ()
      (when (not (memq major-mode
        (list 'term-mode 'eshell-mode)))
          (whitespace-mode))))
  (my-global-whitespace-mode 1)

  (setq
   whitespace-action nil
   whitespace-line-column 250
   show-trailing-whitespace nil

; https://emacs.stackexchange.com/questions/21863/how-can-i-visualize-trailing-whitespace-like-this/21961
   whitespace-display-mappings '((space-mark 32 [183]) (tab-mark 9 [8614 9]))
  whitespace-style '(face trailing spaces space-mark tab-mark))


  (set-face-attribute 'whitespace-space nil :inherit 'default :foreground "gray15" :background nil)
  (set-face-attribute 'whitespace-tab nil :inherit 'default :foreground "gray65" :background nil)
  (set-face-attribute 'whitespace-space-before-tab nil :inherit 'default :foreground "gray40" :background nil)
  (set-face-attribute 'whitespace-space-after-tab nil :inherit 'default :foreground "gray40" :background nil)
  )

;; Don't show whitespace in insert mode.
(defvar my-prev-whitespace-mode nil)
(make-variable-buffer-local 'my-prev-whitespace-mode)
(defun pre-popup-draw ()
  "Turn off whitespace mode before showing company complete tooltip"
  (if whitespace-mode
      (progn
        (setq my-prev-whitespace-mode t)
        (whitespace-mode -1)
        (setq my-prev-whitespace-mode t))))
(defun post-popup-draw ()
  "Restore previous whitespace mode after showing company tooltip"
  (if my-prev-whitespace-mode
      (progn
        (whitespace-mode 1)
        (setq my-prev-whitespace-mode nil))))
(add-hook 'evil-insert-state-entry-hook 'pre-popup-draw)
(add-hook 'evil-insert-state-exit-hook 'post-popup-draw)

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; Add evil-mode using use-package
(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :config
  (evil-mode t)
  :custom
  (evil-shift-round nil)
  )

(use-package evil-snipe
  :after evil
  :ensure t
  :config
  (evil-snipe-mode +1)
  ;; keep the default "s" command
(evil-define-key* '(normal motion) evil-snipe-mode-map
                  "s" #'evil-substitute
                  "S" #'evil-surround-edit)

  (add-hook 'magit-mode-hook 'turn-off-evil-snipe-override-mode))



(with-eval-after-load 'evil-maps

  (define-key evil-motion-state-map (kbd ":") 'evil-repeat-find-char)
  (define-key evil-motion-state-map (kbd ";") 'evil-ex)

  (define-key evil-normal-state-map (kbd "C-=")  'text-scale-increase)
  (define-key evil-normal-state-map (kbd "C--")  'text-scale-decrease)
  (define-key evil-normal-state-map (kbd "C-0")  'text-scale-adjust)

  (define-key evil-normal-state-map (kbd "C-h") 'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-j") 'evil-window-down)
  (define-key evil-normal-state-map (kbd "C-k") 'evil-window-up)
  (define-key evil-normal-state-map (kbd "C-l") 'evil-window-right)

  (define-key evil-normal-state-map (kbd "g /")  'counsel-rg)

  (define-key evil-normal-state-map (kbd "<down>") (lambda ()
                                                     (interactive)
                                                     (enlarge-window 4)))
  (define-key evil-normal-state-map (kbd "<up>") (lambda ()
                                                   (interactive)
                                                   (shrink-window 4)))
  (define-key evil-normal-state-map (kbd "<left>") (lambda ()
                                                     (interactive)
                                                     (enlarge-window-horizontally 6)))
(define-key evil-normal-state-map (kbd "<right>") (lambda ()
                                                    (interactive)
                                                     (shrink-window-horizontally 6)))

  (define-key evil-normal-state-map (kbd "M-n") (lambda ()
                                                  (interactive)
                                                  (perspeen-create-ws)
                                                  (kill-this-buffer)
                                                  (multi-term)
                                                  ))
  (define-key evil-normal-state-map (kbd "C-SPC ,") 'perspeen-rename-ws)
  (define-key evil-normal-state-map (kbd "C-SPC k") 'perspeen-delete-ws)
  (define-key evil-normal-state-map (kbd "M-l") 'perspeen-next-ws)
  (define-key evil-normal-state-map (kbd "M-h") 'perspeen-previous-ws)

  (define-key evil-normal-state-map (kbd "C-SPC i") 'split-and-follow-horizontally)
  (define-key evil-normal-state-map (kbd "C-SPC s") 'split-and-follow-vertically)


  (define-key evil-normal-state-map "f" 'evil-snipe-f)
  (define-key evil-normal-state-map "F" 'evil-snipe-F)
  (define-key evil-motion-state-map "f" 'evil-snipe-f)
  (define-key evil-motion-state-map "F" 'evil-snipe-F)
  (define-key evil-motion-state-map "t" 'evil-snipe-t)
  (define-key evil-motion-state-map "T" 'evil-snipe-T)

  (define-key evil-normal-state-map "t" 'avy-goto-word-1)
  (define-key evil-normal-state-map "\\" 'counsel-projectile-rg)

  (define-key evil-normal-state-map (kbd "U" ) (lambda ()
						(interactive)
						(evil-insert-newline-below)
						))

  (define-key evil-normal-state-map "L" 'evil-last-non-blank)
  (define-key evil-motion-state-map "L" 'evil-last-non-blank)
  (define-key evil-visual-state-map "L" 'evil-last-non-blank)
  (define-key evil-normal-state-map "H" 'evil-first-non-blank)
  (define-key evil-motion-state-map "H" 'evil-first-non-blank)
  (define-key evil-visual-state-map "H" 'evil-first-non-blank)

  (define-key evil-normal-state-map "gsl" 'just-one-space)
  (define-key evil-normal-state-map "gsh" 'delete-horizontal-space)
  (define-key evil-normal-state-map "gsj" 'delete-blank-lines)

  (evil-ex-define-cmd "q" (lambda()
                            (interactive)
                            (if (member major-mode '(term-mode))
                              (if (> (count-windows) 1)
                                (call-interactively 'kill-buffer-and-window)
                               (call-interactively 'perspeen-delete-ws))
                             (call-interactively 'kill-this-buffer))
                            ))
  )


;; visual hints while editing
(use-package evil-goggles
  :ensure t
  :config
  (evil-goggles-mode))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(evil-goggles-change-face ((t (:inherit diff-refine-removed))))
 '(evil-goggles-delete-face ((t (:inherit diff-refine-removed))))
 '(evil-goggles-paste-face ((t (:inherit diff-refine-added))))
 '(evil-goggles-undo-redo-add-face ((t (:inherit diff-refine-added))))
 '(evil-goggles-undo-redo-change-face ((t (:inherit diff-refine-changed))))
 '(evil-goggles-undo-redo-remove-face ((t (:inherit diff-refine-removed))))
 '(evil-goggles-yank-face ((t (:inherit diff-refine-changed))))
 '(hl-line ((t (:inherit header-line))))
 '(line-number-current-line ((t (:inherit hl-line :slant normal :weight bold))))
 '(perspeen-selected-face ((t (:inherit doom-modeline-project-root-dir))))
 '(term-color-white ((t (:foreground "#82afbd" :background "#656555"))))
 '(whitespace-space ((t (:foreground "#fdf6e3"))))
 '(whitespace-tab ((t (:foreground "seashell3"))))
 '(whitespace-trailing ((t (:inherit nil :foreground "seashell3")))))

;; like vim-surround
;; https://github.com/emacs-evil/evil-surround/issues/99
(use-package evil-surround
  :ensure t
  :config
  (global-evil-surround-mode 1)
  (define-key evil-normal-state-map (kbd "S") 'evil-surround-edit)
  (define-key evil-visual-state-map (kbd "S") 'evil-surround-region)

(evil-add-to-alist
  'evil-surround-pairs-alist
  ?\( '("(" . ")")
  ?\[ '("[" . "]")
  ?\{ '("{" . "}")
  ?\) '("( " . " )")
  ?\] '("[ " . " ]")
  ?\} '("{ " . " }"))
)

;; r operator, like vim's ReplaceWithRegister
(use-package evil-replace-with-register
  :ensure t
  :bind (:map evil-normal-state-map
	      ("r" . evil-replace-with-register)
	      :map evil-visual-state-map
	      ("r" . evil-replace-with-register)))

;; * operator in vusual mode
(use-package evil-visualstar
  :ensure t
  :bind (:map evil-visual-state-map
	      ("*" . evil-visualstar/begin-search-forward)
	      ("#" . evil-visualstar/begin-search-backward)))

(use-package evil-indent-plus
  :after evil
  :ensure t
  :init
(define-key evil-inner-text-objects-map "l" 'evil-indent-plus-i-indent)
(define-key evil-outer-text-objects-map "l" 'evil-indent-plus-a-indent)
(define-key evil-inner-text-objects-map "k" 'evil-indent-plus-i-indent-up)
(define-key evil-outer-text-objects-map "k" 'evil-indent-plus-a-indent-up)
(define-key evil-inner-text-objects-map "j" 'evil-indent-plus-i-indent-up-down)
(define-key evil-outer-text-objects-map "j" 'evil-indent-plus-a-indent-up-down)
  )

(use-package evil-textobj-anyblock
  :ensure t
  :config
    (define-key evil-inner-text-objects-map "i" 'evil-textobj-anyblock-inner-block)
    )

(use-package evil-args
  :ensure t
  :defer t
  :init (progn
          ;; bind evil-args text objects
          (define-key evil-inner-text-objects-map "a" 'evil-inner-arg)
          (define-key evil-outer-text-objects-map "a" 'evil-outer-arg)
;; bind evil-forward/backward-args
(define-key evil-normal-state-map (kbd "M-.")'evil-forward-arg)
(define-key evil-normal-state-map (kbd "M-,")'evil-backward-arg)
(define-key evil-motion-state-map (kbd "M-.")'evil-forward-arg)
(define-key evil-motion-state-map (kbd "M-,")'evil-backward-arg)


          ))


;; ein
(use-package ewoc)
(use-package websocket
  :ensure t)
(use-package ein
  :ensure t
  :config
  ; (advice-add 'request--netscape-cookie-parse :around #'fix-request-netscape-cookie-parse)
  (setq ein:worksheet-enable-undo 'yes)
  (setq ein:truncate-long-cell-output 40)
  (setq ein:connect-mode-hook 'ein:use-company-backend)
  (progn
    (setq ein:default-url-or-port "https://shell.drakirus.com")
    ))

(use-package elpy
  :ensure t)

(defun worksheet-next-center-top ()
  ; "Go the the next input cell, and clip the line to the top of the windows"
  (interactive)
  (call-interactively 'ein:worksheet-goto-next-input)
  (call-interactively 'evil-scroll-line-to-top))

(defun worksheet-prev-center-top ()
  ; "Go the the next input cell, and clip the line to the top of the windows"
  (interactive)
  (call-interactively 'ein:worksheet-goto-prev-input)
  (call-interactively 'evil-scroll-line-to-top))

;; https://github.com/cofi/evil-leader
(use-package evil-leader
  :after evil
  :ensure t
  :config
(setq evil-leader/in-all-states t)
(evil-leader/set-leader ",")
(evil-mode nil) ;; no idea
(global-evil-leader-mode)
(evil-mode 1))

(evil-leader/set-key-for-mode 'term-mode
  "r" (lambda ()
        (interactive)
        (setq-local current-directory (perspeen-ws-struct-root-dir perspeen-current-ws))
        (term-send-raw-string (format "cd %s\n" current-directory))))


(evil-leader/set-key-for-mode 'org-mode
  "td" 'org-todo
  "te" 'org-set-tags-command
  "s" 'org-schedule
  "d" 'org-deadline
)

(evil-leader/set-key-for-mode 'ein:notebook-multilang-mode
  "," 'ein:notebook-save-notebook-command
  "g" 'ein:pytools-jump-to-source-command
  "rn" 'ein:notebook-rename-command)

      ;; keybindings for ipython notebook traceback mode
      (evil-define-key 'normal  ein:traceback-mode-map
                                    (kbd "<return>") 'ein:tb-jump-to-source-at-point-command
                                    "n" 'ein:tb-next-item
                                    "p" 'ein:tb-prev-item
                                    "q" 'bury-buffer)

(evil-define-key 'normal ein:notebook-multilang-mode-map
  ;; keybindings mirror ipython web interface behavior
  "J" 'worksheet-next-center-top
  "K" 'worksheet-prev-center-top
  (kbd "<return>") 'ein:worksheet-execute-cell
  (kbd "<C-return>") 'ein:worksheet-execute-cell
  (kbd "<S-return>") 'ein:worksheet-execute-cell-and-goto-next
  (kbd "C-c c" ) 'ein:notebook-kernel-interrupt-command
  (kbd "C-c d" ) 'ein:worksheet-kill-cell
  (kbd "C-c p" ) 'ein:worksheet-yank-cell
  (kbd "C-c y" ) 'ein:worksheet-copy-cell
  (kbd "C-c o" ) 'ein:worksheet-insert-cell-below
  (kbd "C-c O" ) 'ein:worksheet-insert-cell-above
  (kbd "C-c x" ) 'ein:tb-show
  (kbd "C-o" ) 'ein:pytools-jump-back-command
  (kbd "C-c s" ) 'ein:worksheet-split-cell-at-point
  (kbd "C-c j" ) 'ein:worksheet-merge-cell
  (kbd "C-c l" ) 'ein:worksheet-clear-output
  (kbd "C-c L" ) 'ein:worksheet-clear-all-output
  (kbd "C-c r" ) 'ein:notebook-restart-kernel-command
  (kbd "C-c R" ) 'ein:worksheet-execute-all-cell
  (kbd "C-c u" ) 'ein:worksheet-change-cell-type)


(evil-leader/set-key
  "," 'save-buffer
  "oa" 'org-agenda-list
  "a" 'evil-numbers/inc-at-pt
  "x" 'evil-numbers/dec-at-pt
  "q" 'delete-window
  "b" 'ivy-switch-buffer
  "cd" (lambda ()
        (interactive)
        (call-interactively 'perspeen-change-root-dir)
        (setq-local current-directory (perspeen-ws-struct-root-dir perspeen-current-ws))
        (term-send-raw-string (format "cd %s\n" current-directory))
        (cd current-directory)
        )
  "tn" 'multi-term
  "p" 'counsel-projectile-switch-project
  "c <SPC>"  'evil-commentary-line
  "e"  'anzu-query-replace-at-cursor
  "u" 'undo-tree-visualize
  "jl" 'ein:notebooklist-login
  "jo" 'ein:notebooklist-open
  "rn" 'rename-file-and-buffer)

;; https://github.com/linktohack/evil-commentary
(use-package evil-commentary
  :ensure t
  :config
  (evil-commentary-mode))


(defun rename-file-and-buffer ()
  "Rename the current buffer and file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
	(message "Buffer is not visiting a file!")
      (let ((new-name (read-file-name "New name: " filename)))
	(cond
	 ((vc-backend filename) (vc-rename-file filename new-name))
	 (t
	  (rename-file filename new-name t)
	  (set-visited-file-name new-name t t)))))))


(use-package swiper
  :ensure t
  :config
  (global-set-key (kbd "C-s") 'swiper)
  (global-set-key (kbd "C-Y") 'ivy-immediate-done)
  (global-set-key (kbd "C-u") 'ivy-kill-whole-line)
  (global-set-key (kbd "C-w") 'ivy-backward-kill-word)
  (progn
    (ivy-mode 1)
    (setq ivy-flx-limit 2000)
    (setq ivy-use-virtual-buffers t)
    (setq ivy-count-format "(%d/%d) ")
    (setq ivy-re-builders-alist '((t . ivy--regex-fuzzy)))
(setq ivy-initial-inputs-alist nil)
				  ))

;; flx is used as the fuzzy-matching indexer backend for ivy.
(use-package flx
  :ensure t
  :after ivy)

(use-package counsel-projectile
  :ensure t
  :config
  (counsel-projectile-mode)
  (define-key evil-normal-state-map  (kbd "C-p") 'counsel-projectile-find-file)
  (define-key evil-normal-state-map  (kbd "C-f") 'counsel-find-file)
  (define-key ivy-minibuffer-map (kbd "<return>") #'ivy-alt-done)
  (define-key ivy-minibuffer-map (kbd "C-h") 'counsel-up-directory)
  (define-key ivy-minibuffer-map (kbd "C-l") 'ivy-alt-done)
  )

(use-package multi-term
  :ensure t

  :config
  (setq multi-term-program "/usr/bin/zsh")
  (add-hook 'emacs-startup-hook
    (lambda ()
      (kill-buffer "*scratch*")
      (multi-term)
      )))

(defun set-no-process-query-on-exit ()
  (let ((proc (get-buffer-process (current-buffer))))
    (when (processp proc)
      (set-process-query-on-exit-flag proc nil))))

(add-hook 'term-exec-hook 'set-no-process-query-on-exit)

(add-hook 'term-mode-hook
          (lambda ()
            (setq term-buffer-maximum-size 10000)))


(defun split-and-follow-horizontally ()
  (interactive)
  (split-window-below)
  (other-window 1)
  (multi-term)
  )

(defun split-and-follow-vertically ()
  (interactive)
  (split-window-right)
  (other-window 1)
  (multi-term)
  )

;; show tildes on empty lines
(use-package vi-tilde-fringe
  :ensure t
  :init (global-vi-tilde-fringe-mode)
  :delight (vi-tilde-fringe-mode))


(use-package counsel
  :ensure t
  :config
  (global-set-key (kbd "M-x") 'counsel-M-x)
  (define-key evil-normal-state-map  (kbd "<backspace>") 'counsel-M-x)
  )

; recently used M-x commands
(use-package smex
  :ensure t
  :init (progn
	  (smex-initialize)))

(use-package move-text
  :ensure t
  :bind
  (([(meta k)] . move-text-up)
   ([(meta j)] . move-text-down)))

(use-package company
  :ensure t
  :config
  (setq ac-auto-show-menu nil)
  (global-company-mode)
  (setq company-dabbrev-downcase nil)
  (setq company-idle-delay 0.1)
  (setq company-show-numbers t)
  (setq company-tooltip-limit 15)
  (setq company-minimum-prefix-length 1)
  (setq company-selection-wrap-around t)

  (let ((map company-active-map))
    (mapc
     (lambda (x)
       (define-key map (format "%d" x) 'ora-company-number))
     (number-sequence 0 9))

    (define-key map (kbd "<return>") nil)
    (define-key map (kbd "C-w") 'evil-delete-backward-word))

  (defun ora-company-number ()
    "Forward to `company-complete-number'.

    Unless the number is potentially part of the candidate.
    In that case, insert the number."
    (interactive)
    (let* ((k (this-command-keys))
           (re (concat "^" company-prefix k)))
      (if (cl-find-if (lambda (s) (string-match re s))
                      company-candidates)
        (self-insert-command 1)
        (company-complete-number (string-to-number k))))))

(use-package which-key
  :ensure t
  :config
  (which-key-mode +1))


(use-package doom-themes
  :ensure t
  :init
  ; (load-theme 'doom-one t)
  (load-theme 'doom-solarized-light t)

  :config
  (set-face-attribute 'default nil :font "Hack:hintstyle=hintfull:autohint=true:rgba=rgb")
  (setq-default line-spacing 5)
  (setq auto-save-list-file-prefix nil)
  (setq inhibit-startup-screen t)
  (set-face-attribute 'default nil :height 109)
  (set-frame-parameter nil 'internal-border-width 4)

  )

; (global-hl-line-mode +1)
(blink-cursor-mode -1)


(use-package evil-numbers
  :ensure t
  )

(use-package evil-anzu
  :ensure t
  :config
					; Enable global anzu mode
  (global-anzu-mode t))

(use-package undo-tree
  :ensure t
  :config
  ;; autosave the undo-tree history
  (setq undo-tree-history-directory-alist
	`((".*" . ,temporary-file-directory)))
  (setq undo-tree-auto-save-history t))

(use-package doom-modeline
  :ensure t
  :defer t
  :hook (after-init . doom-modeline-init))

(setq column-number-mode t)

;; smooth-scrolling
(use-package smooth-scrolling
  :ensure t
  :config
  (smooth-scrolling-mode t)
  (setq smooth-scroll-margin 4)
)

(use-package server
  :ensure t
  :config
  (unless (server-running-p) (server-start)))


;; Add Vim bindings to many modes
(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init)
  (evil-collection-define-key 'normal 'term-mode-map
      (kbd "C-SPC /") (kbd "? ❯ RET")
      (kbd "C-SPC /") (kbd "? ❯ RET")
      (kbd "C-h") 'evil-window-left
      (kbd "C-j") 'evil-window-down
      (kbd "C-k") 'evil-window-up
      (kbd "C-l") 'evil-window-right
      )

  (evil-collection-define-key 'insert 'term-raw-map
      (kbd "C-h") 'evil-window-left
      (kbd "C-j") 'evil-window-down
      (kbd "C-k") 'evil-window-up
      (kbd "C-l") 'evil-window-right

      (kbd "C-SPC ,") 'perspeen-rename-ws
      (kbd "C-SPC k") 'perspeen-delete-ws
      (kbd "M-l") 'perspeen-next-ws
      (kbd "M-h") 'perspeen-previous-ws

      (kbd "C-SPC i") 'split-and-follow-horizontally
      (kbd "C-SPC s") 'split-and-follow-vertically

      (kbd "M-n") (lambda ()
                    (interactive)
                    (perspeen-create-ws)
                    (kill-this-buffer)
                    (multi-term)
                    )


    )


  (evil-define-operator evil-change-line-no-yank (beg end type register yank-handler)
    "Change to end of line without yanking."
    :motion evil-end-of-line
    (interactive "<R><x><y>")
    (evil-change beg end type ?_ yank-handler #'evil-delete-line))
  (evil-define-operator evil-change-no-yank (beg end type register yank-handler)
    "Change without yanking."
    (evil-change beg end type ?_ yank-handler))
  (evil-define-operator evil-change-whole-line-no-yank (beg end type register yank-handler)
    :motion evil-line
    (interactive "<R><x>")
    (evil-change beg end type ?_ yank-handler #'evil-delete-whole-line))
  (define-key evil-normal-state-map (kbd "C") 'evil-change-line-no-yank)
  (define-key evil-normal-state-map (kbd "c") 'evil-change-no-yank)
  (define-key evil-visual-state-map (kbd "c") 'evil-change-no-yank)

  )


(use-package markdown-mode
  :ensure t
  :defer t
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  )

(use-package avy
  :after evil
  :ensure t
  :config
  (setq avy-background t))


;; keeps our parentheses balanced and allows for easy manipulation
(use-package smartparens
  :ensure t
  :diminish smartparens-mode
  :init
  (use-package evil-smartparens
    :ensure t
    :diminish evil-smartparens-mode
    :config
    (add-hook 'clojure-mode-hook #'evil-smartparens-mode)
    (add-hook 'lisp-mode-hook #'evil-smartparens-mode)
    (add-hook 'scheme-mode-hook #'evil-smartparens-mode)
    (add-hook 'emacs-lisp-mode-hook #'evil-smartparens-mode))
  :config
  (require 'smartparens-config)
  (add-hook 'after-init-hook 'smartparens-global-mode))


(use-package nlinum
  :ensure
  :config
  (progn
    ;; Preset `nlinum-format' for minimum width.
    (defun my-nlinum-mode-hook ()
      (when nlinum-mode
        (setq-local nlinum-format
                    (setq linum-format "%3d \u2502"))))
    (global-nlinum-mode 1)
    (add-hook 'nlinum-mode-hook 'my-nlinum-mode-hook))
  )

(use-package nlinum-relative
    :ensure
    :config
    ;; something else you want
    (nlinum-relative-setup-evil)
    (add-hook 'prog-mode-hook 'nlinum-relative-mode))

(use-package perspeen
  :ensure t
  :config
  (perspeen-mode)
  (add-hook 'perspeen-ws-after-switch-hook
          (lambda ()
            (setq-local new-directory (perspeen-ws-struct-root-dir perspeen-current-ws))
            (cd new-directory)
          ))
  )

(use-package highlight-parentheses
  :ensure t
  :diminish highlight-parentheses-mode
  :ensure t
  :init (global-highlight-parentheses-mode)
 :config
 (setq hl-paren-colors '("back")))

(use-package rainbow-delimiters
  :ensure t
  :hook
  (prog-mode . rainbow-delimiters-mode)
  :config
  (setq rainbow-delimiters-unmatched-face '(t (:foreground ,red
                                                       :bold t
                                                       :inverse-video t))))

(defun underscore-as-word-char ()
  (modify-syntax-entry ?- "w")
  (modify-syntax-entry ?_ "w"))
(add-hook 'after-change-major-mode-hook #'underscore-as-word-char)


(which-key-declare-prefixes "C-c l" "langtool")

(use-package langtool
  :ensure t
  :bind (("C-c l c" . langtool-check)
         ("C-c l d" . langtool-check-done)
         ("C-c l s" . langtool-switch-default-language)
         ("C-c l m" . langtool-show-message-at-point)
         ("C-c l b" . langtool-correct-buffer))
  :config
  (setq langtool-language-tool-jar "/usr/share/java/languagetool/languagetool-commandline.jar")
  (defun langtool-autoshow-detail-popup (overlays)
    (when (require 'popup nil t)
      ;; Do not interrupt current popup
      (unless (or popup-instances
                  ;; suppress popup after type `C-g` .
                  (memq last-command '(keyboard-quit)))
        (let ((msg (langtool-details-error-message overlays)))
          (popup-tip msg)))))

  (setq langtool-autoshow-message-function
        'langtool-autoshow-detail-popup))


(use-package evil-org
  :ensure t
  :after org
  :config
  (add-hook 'org-mode-hook 'evil-org-mode)
  (add-hook 'evil-org-mode-hook
            (lambda ()
              (evil-org-set-key-theme)))
  (require 'evil-org-agenda)
  ; [ org-edit-latex ] -- Org edit LaTeX block/inline like babel src block.
  ; [ org-trello ? ]

  (setq org-agenda-files (file-expand-wildcards "~/resource/my-plain-text-life/org/*.org"))
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.8))
  (evil-org-agenda-set-keys)
  )


(evil-define-key 'normal org-mode-map (kbd "L") 'org-forward-element)
(evil-define-key 'normal org-mode-map (kbd "H") 'org-backward-element)


(use-package org-bullets
  :ensure t
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

(use-package wc-mode :ensure t :defer t)


(use-package go-mode
             :ensure t
             :commands (godef-jump go-mode)
             :mode "\\.go\\'"
             :bind
             (:map go-mode-map
                   ("M-." . godef-jump)
                   ("M-*" . pop-tag-mark))
             :config
             (add-hook 'before-save-hook 'gofmt-before-save))

(use-package company-go
             :ensure t
             :after go-mode
             :config
             (add-hook 'go-mode-hook
                       (lambda ()
                         (set (make-local-variable 'company-backends)))))


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(evil-shift-round nil)
 '(package-selected-packages
   (quote
    (which-key wc-mode vi-tilde-fringe use-package smooth-scrolling smex rainbow-delimiters perspeen org-evil org-bullets nlinum-relative multi-term move-text markdown-mode langtool highlight-parentheses git-gutter-fringe flx eyebrowse evil-visualstar evil-textobj-anyblock evil-surround evil-snipe evil-smartparens evil-replace-with-register evil-org evil-numbers evil-leader evil-indent-plus evil-goggles evil-commentary evil-collection evil-args evil-anzu elpy ein doom-themes doom-modeline counsel-projectile company-go avy))))
