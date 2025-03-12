;; Waste Collection Contract
;; Tracks garbage pickup and recycling activities

(define-map collections
  { id: uint }
  {
    collector: principal,
    location: (string-ascii 100),
    waste-type: (string-ascii 20),
    weight: uint,
    timestamp: uint,
    status: (string-ascii 20)
  }
)

(define-map collector-stats
  { collector: principal }
  {
    total-collections: uint,
    total-weight: uint
  }
)

(define-data-var last-id uint u0)

;; Register a new waste collection
(define-public (register-collection
              (location (string-ascii 100))
              (waste-type (string-ascii 20))
              (weight uint))
  (let
    (
      (new-id (+ (var-get last-id) u1))
      (collector-stat (default-to
                        { total-collections: u0, total-weight: u0 }
                        (map-get? collector-stats { collector: tx-sender })))
    )
    (var-set last-id new-id)

    ;; Update collector stats
    (map-set collector-stats
      { collector: tx-sender }
      {
        total-collections: (+ (get total-collections collector-stat) u1),
        total-weight: (+ (get total-weight collector-stat) weight)
      }
    )

    (ok (map-set collections
      { id: new-id }
      {
        collector: tx-sender,
        location: location,
        waste-type: waste-type,
        weight: weight,
        timestamp: block-height,
        status: "collected"
      }
    ))
  )
)

;; Update collection status
(define-public (update-collection-status (id uint) (status (string-ascii 20)))
  (let
    (
      (collection (unwrap! (get-collection id) (err u404)))
    )
    (asserts! (is-eq tx-sender (get collector collection)) (err u403))
    (ok (map-set collections
      { id: id }
      (merge collection {
        status: status
      })
    ))
  )
)

;; Get collection record
(define-read-only (get-collection (id uint))
  (map-get? collections { id: id })
)

;; Get collector statistics
(define-read-only (get-collector-stats (collector principal))
  (map-get? collector-stats { collector: collector })
)

;; Get total collections count
(define-read-only (get-total-collections)
  (var-get last-id)
)

