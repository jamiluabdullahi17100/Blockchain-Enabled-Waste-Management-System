;; Environmental Impact Contract
;; Measures and reports on waste reduction efforts

(define-map impact-metrics
  { id: uint }
  {
    metric-type: (string-ascii 20),
    value: uint,
    unit: (string-ascii 10),
    source: principal,
    timestamp: uint
  }
)

(define-map community-impact
  { community-id: (string-ascii 20) }
  {
    waste-reduced: uint,
    recycling-rate: uint,
    last-updated: uint
  }
)

(define-data-var last-id uint u0)
(define-constant admin tx-sender)

;; Record environmental impact metric
(define-public (record-metric
              (metric-type (string-ascii 20))
              (value uint)
              (unit (string-ascii 10)))
  (let
    (
      (new-id (+ (var-get last-id) u1))
    )
    (var-set last-id new-id)
    (ok (map-set impact-metrics
      { id: new-id }
      {
        metric-type: metric-type,
        value: value,
        unit: unit,
        source: tx-sender,
        timestamp: block-height
      }
    ))
  )
)

;; Update community impact
(define-public (update-community-impact
              (community-id (string-ascii 20))
              (waste-reduced uint)
              (recycling-rate uint))
  (let
    (
      (current-impact (default-to
                      { waste-reduced: u0, recycling-rate: u0, last-updated: u0 }
                      (map-get? community-impact { community-id: community-id })))
    )
    (asserts! (is-eq tx-sender admin) (err u403))
    (asserts! (<= recycling-rate u100) (err u400))

    (ok (map-set community-impact
      { community-id: community-id }
      {
        waste-reduced: (+ (get waste-reduced current-impact) waste-reduced),
        recycling-rate: recycling-rate,
        last-updated: block-height
      }
    ))
  )
)

;; Get impact metric
(define-read-only (get-metric (id uint))
  (map-get? impact-metrics { id: id })
)

;; Get community impact
(define-read-only (get-community-impact (community-id (string-ascii 20)))
  (map-get? community-impact { community-id: community-id })
)

;; Get total metrics count
(define-read-only (get-total-metrics)
  (var-get last-id)
)

