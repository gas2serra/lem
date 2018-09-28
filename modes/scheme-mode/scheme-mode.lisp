(in-package :lem-scheme-mode)

(define-major-mode scheme-mode language-mode
    (:name "scheme"
     :keymap *scheme-mode-keymap*
     :syntax-table lem-scheme-syntax:*syntax-table*)
  (setf (variable-value 'beginning-of-defun-function) 'scheme-beginning-of-defun)
  (setf (variable-value 'end-of-defun-function) 'scheme-end-of-defun)
  (setf (variable-value 'indent-tabs-mode) nil)
  (setf (variable-value 'enable-syntax-highlight) t)
  (setf (variable-value 'calc-indent-function) 'calc-indent)
  (setf (variable-value 'line-comment) ";")
  (setf (variable-value 'insertion-line-comment) ";; ")
  (set-syntax-parser lem-scheme-syntax:*syntax-table* (make-tmlanguage-scheme)))

(define-key *global-keymap* "M-(" 'insert-\(\))
(define-key *global-keymap* "M-)" 'move-over-\))
(define-key *scheme-mode-keymap* "C-M-q" 'scheme-indent-sexp)

(defun calc-indent (point)
  (lem-scheme-syntax:calc-indent point))

(defun scheme-beginning-of-defun (point n)
  (lem-scheme-syntax:beginning-of-defun point (- n)))

(defun scheme-end-of-defun (point n)
  (if (minusp n)
      (scheme-beginning-of-defun point (- n))
      (dotimes (_ n)
        (with-point ((p point))
          (cond ((and (lem-scheme-syntax:beginning-of-defun p -1)
                      (point<= p point)
                      (or (form-offset p 1)
                          (progn
                            (move-point point p)
                            (return)))
                      (point< point p))
                 (move-point point p)
                 (skip-whitespace-forward point t)
                 (when (end-line-p point)
                   (character-offset point 1)))
                (t
                 (form-offset point 1)
                 (skip-whitespace-forward point t)
                 (when (end-line-p point)
                   (character-offset point 1))))))))

(define-command insert-\(\) () ()
  (let ((p (current-point)))
    (insert-character p #\()
    (insert-character p #\))
    (character-offset p -1)))

(defun backward-search-rper ()
  (save-excursion
    (do* ((p (character-offset (current-point) -1))
          (c (character-at p)
             (character-at p)))
        ((char= #\) c) p)
      (unless (syntax-space-char-p c)
        (return nil))
      (character-offset p -1))))

(defun backward-delete-to-rper ()
  (save-excursion
    (do* ((p (character-offset (current-point) -1))
          (c (character-at p)
             (character-at p)))
        ((char= #\) c) p)
      (unless (syntax-space-char-p c)
        (return nil))
      (delete-character p)
      (character-offset p -1))))

(define-command move-over-\) () ()
  (let ((rper (backward-search-rper)))
    (if rper
        (progn
          (backward-delete-to-rper)
          (scan-lists (current-point) 1 1 T)
          (lem.language-mode:newline-and-indent 1))
        (progn
          (scan-lists (current-point) 1 1 T)
          (lem.language-mode:newline-and-indent 1)))))

(define-command scheme-indent-sexp () ()
  (with-point ((end (current-point) :right-inserting))
    (when (form-offset end 1)
      (indent-region (current-point) end))))

(define-command scheme-scratch () ()
  (let ((buffer (make-buffer "*tmp*")))
    (change-buffer-mode buffer 'scheme-mode)
    (switch-to-buffer buffer)))

(pushnew (cons "\\.scm$" 'scheme-mode) *auto-mode-alist* :test #'equal)
(pushnew (cons "\\.sld$" 'scheme-mode) *auto-mode-alist* :test #'equal)
(pushnew (cons "\\.rkt$" 'scheme-mode) *auto-mode-alist* :test #'equal)