;; Sorting Verification Contract
;; Confirms proper separation of recyclables

(define-map verifications
  { id: uint }
  {
    collection-id: uint,
    verifier: principal,
    contamination-level: uint,
    quality-score: uint,
    timestamp: uint,
    status: (string-ascii 20)
  }
)

(define-map facility-stats
  { facility: principal }
  {
    total-verifications: uint,
    avg-quality-score: uint
  }
)

(define-data-var last-id uint u0)

;; Register a new sorting verification
(define-public (register-verification
              (collection-id uint)
              (contamination-level uint)
              (quality-score uint))
  (let
    (
      (new-id (+ (var-get last-id) u1))
      (facility-stat (default-to
                      { total-verifications: u0, avg-quality-score: u0 }
                      (map-get? facility-stats { facility: tx-sender })))
      (total-verifications (get total-verifications facility-stat))
      (current-avg (get avg-quality-score facility-stat))
      (new-avg (if (is-eq total-verifications u0)
                 quality-score
                 (/ (+ (* current-avg total-verifications) quality-score) (+ total-verifications u1))))
    )
    (asserts! (<= contamination-level u100) (err u400))
    (asserts! (<= quality-score u100) (err u400))
    (var-set last-id new-id)

    ;; Update facility stats
    (map-set facility-stats
      { facility: tx-sender }
      {
        total-verifications: (+ total-verifications u1),
        avg-quality-score: new-avg
      }
    )

    (ok (map-set verifications
      { id: new-id }
      {
        collection-id: collection-id,
        verifier: tx-sender,
        contamination-level: contamination-level,
        quality-score: quality-score,
        timestamp: block-height,
        status: "verified"
      }
    ))
  )
)

;; Get verification details
(define-read-only (get-verification (id uint))
  (map-get? verifications { id: id })
)

;; Get facility statistics
(define-read-only (get-facility-stats (facility principal))
  (map-get? facility-stats { facility: facility })
)

;; Get total verifications count
(define-read-only (get-total-verifications)
  (var-get last-id)
)

