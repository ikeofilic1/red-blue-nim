;; Make red bigger than blue to win
(defparameter *arr* '("XX" "4" "3" "standard" "human" "0"))
(defparameter *debug* nil) ;; Set to FALSE before shipping

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(deftype nim-version() '(member :standard :misere))
(declaim (type (nim-version) *game-version*))

(defparameter *game-state* nil)
(defparameter *game-version* :standard)
(defparameter actions nil)

(defun make-state(num_red num_blue) (cons num_red num_blue))
(defun reds  (state) (car state))
(defun blues (state) (cdr state))

(defconstant +red-weight+ 2)
(defconstant +blue-weight+ 3)

;; for ease of typing
(defconstant inf double-float-positive-infinity)
(defconstant -inf double-float-negative-infinity)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun calculate-score (state)
  (+ (* +red-weight+ (reds state)) (* +blue-weight+ (blues state))))

(defun terminal-test (state) (or (= 0 (reds state)) (= 0 (blues state))))

(defun utility(max-node state)
  "Return the utility of a terminal state"
  (unless (terminal-test state) (error "You can only find the utility of a terminal state"))

  (let
      ((score (case *game-version*
		(:standard (- (calculate-score state))) ;; In standard, we lose in the terminal state
		(:misere   (calculate-score state)))))
    (if max-node score (- score)))) ;; If we are at a min-node, we negate the score since a negative value mins a win

(defun eval-fn(max-node state &aux (red (reds state)) (blue (blues state)) (sum (+ red blue)))
    "Evaluate the state and report a score"
    (if (terminal-test state) (utility max-node state) 
      (let ((min-weight (min +red-weight+ +blue-weight+)) (max-weight (max +red-weight+ +blue-weight+)))            
        (case *game-version*
          (:standard
            (if (and (= 1 red) (= 1 blue)) (if max-node max-weight (- max-weight))

              (if (= 1 red) (* blue (if max-node +blue-weight+ (- +blue-weight+)))

                (if (= 1 blue) (* red (if max-node +red-weight+ (- +red-weight+)))

                  (* -2 min-weight (if max-node 1 -1) (if (evenp sum) 1 -1))))))

          (:misere 
              (* min-weight (if max-node 1 -1) (if (oddp sum) 1 -1)))))))


(defun apply-action(action state)
    "apply an action to a state and return the consequent state"
    (cond  ((string-equal action "blue") (make-state (reds state) (1- (blues state))))
        ((string-equal action "red") (make-state (1- (reds state)) (blues state)))
        (t (error "Should not reach here! Woopsie!!"))))

(defun min-max-with-alpha-beta(&optional depth)
  "Return the next action to take that will maximize my chance of winning based on the game"
  (loop for a in actions
    as util = (min-value (apply-action a *game-state*) -inf inf depth)
    collect util into utils
    maximizing util into max-util
    finally (return (nth (position max-util utils) actions))))

(defun min-value(state alpha beta &optional depth)
  "Returns the action that gives the smallest utility/eval values from the current state"
  (if (terminal-test state) (return-from min-value (utility nil state)))
  (if (and depth (<= depth 0)) (progn (write-line "eval-fn called!!") (return-from min-value (eval-fn nil state))))
  
  (let ((v inf))
    (loop for action in actions
      for sucessor = (apply-action action state) do 

      (setq v (min v (max-value sucessor alpha beta (if depth (1- depth)))))
      (when (<= v alpha) (return v))
      (setq beta (min beta v)))
      v))

(defun max-value(state alpha beta &optional depth)
  "Returns the action that gives the largest utility/eval values from the current state"
  (if (terminal-test state) (return-from max-value (utility t state)))
  (if (and depth (<= depth 0)) (progn (write-line "eval-fn called!!") (return-from max-value (eval-fn t state))))
  
  (let ((v -inf))
    (loop for action in actions
      for sucessor = (apply-action action state) do 

      (setq v (max v (min-value sucessor alpha beta (if depth (1- depth)))))
      (when (>= v beta) (return v))
      (setq alpha (max alpha v)))
    v))

(if *debug* (setq *posix-argv* *arr*))

; FUNCTIONS
(defun shift()
  "Deletes the current command-line argument and then returns the next one"
  (setq *posix-argv* (cdr *posix-argv*))
  (car *posix-argv*))

;; Debug mode. Stop closing my slime please
(if *debug*
  (defun error-exit (message)
    (write-line message *error-output*)
    (error "Byee"))

  (defun error-exit (message)
    (write-line message *error-output*)
    (exit :code 1)))

(defun print-winner(computer-turn)
  (terpri)
  (write-string "Game over! ")
  (if (eq *game-version* :standard) (setq computer-turn (not computer-turn)))
  (if computer-turn
    (format t "You lost, Computer won ~d points~%" (calculate-score *game-state*))
    (format t "You won ~d points~%" (calculate-score *game-state*)))
)

(defun print-game-state(&optional (state *game-state*))
  (format t "Game state: ~a red marbles, ~a blue marbles~%" (reds state) (blues state)))

(defun get-user-input()
  "Get either a \"blue\" or a \"red\" and return it if gotten"
  (loop
    (write-string "Enter \"blue\" or \"red\": ")
    (force-output)
    (let ((input (read-line)))
      (if (or (string= input "red") (string= input "blue"))
        (return input)
        (write-line "Invalid option!")))))

(if t (let (
    (num_red (shift))
    (num_blue (shift))
    (version (shift))
    (firstp (shift))
    (depth (shift))
    (computer-turn t))

  (when (or (null num_red) (null num_blue))
    (error-exit "Number of red and blue marbles must be given"))

  (setq num_red (parse-integer num_red :junk-allowed t))
  (setq num_blue (parse-integer num_blue :junk-allowed t))
  (when (or (null num_red) (null num_blue) (< num_red 1) (< num_blue 1))
    (error-exit "Number of red and blue marbles must be positive integers"))

  (when version
    (cond   ((string= version "standard") (setq *game-version* :standard))
            ((string= version "misere") (setq *game-version* :misere))
            (t (error-exit (format nil "Invalid version `~A`. version must be either \"standard\" or \"misere\"" version)))))

  (when firstp
    (cond  ((string= firstp "computer") (setq computer-turn t))
           ((string= firstp "human") (setq computer-turn nil))
           (t (error-exit "Invalid string. Expected \"computer\" or \"human\""))))

  (setq depth (if depth (parse-integer depth :junk-allowed t)))
  (setq actions (if (eq *game-version* :standard) (list "blue" "red") (list "red" "blue")))
  (setq *game-state* (make-state num_red num_blue))

  (loop
    (print-game-state)
    (when (terminal-test *game-state*) (print-winner computer-turn) (return))

    (terpri)
    (let ((choice
            (if computer-turn
                (min-max-with-alpha-beta depth)
                (progn (write-string "Your turn! ") (get-user-input)))))

      (if computer-turn (format t "Computer chose ~a!~%" choice)) ; Add a continue check here?
      (setf *game-state* (apply-action choice *game-state*)))

    (setq computer-turn (not computer-turn)))))