;; Recycling Reward Contract
;; Issues tokens for responsible waste disposal

(define-fungible-token recycling-token)

(define-map rewards
  { id: uint }
  {
    recipient: principal,
    amount: uint,
    verification-id: uint,
    timestamp: uint
  }
)

(define-map user-balances
  { user: principal }
  {
    total-rewards: uint
  }
)

(define-data-var last-id uint u0)
(define-constant token-owner tx-sender)

;; Initialize contract with tokens
(begin
  (try! (ft-mint? recycling-token u1000000000 token-owner))
)

;; Issue rewards for recycling activity
(define-public (issue-reward
              (recipient principal)
              (verification-id uint)
              (amount uint))
  (let
    (
      (new-id (+ (var-get last-id) u1))
      (user-balance (default-to
                    { total-rewards: u0 }
                    (map-get? user-balances { user: recipient })))
    )
    (asserts! (is-eq tx-sender token-owner) (err u403))
    (var-set last-id new-id)

    ;; Update user balance
    (map-set user-balances
      { user: recipient }
      {
        total-rewards: (+ (get total-rewards user-balance) amount)
      }
    )

    ;; Record reward
    (map-set rewards
      { id: new-id }
      {
        recipient: recipient,
        amount: amount,
        verification-id: verification-id,
        timestamp: block-height
      }
    )

    ;; Transfer tokens to recipient
    (ft-transfer? recycling-token amount token-owner recipient)
  )
)

;; Get reward details
(define-read-only (get-reward (id uint))
  (map-get? rewards { id: id })
)

;; Get user balance
(define-read-only (get-user-balance (user principal))
  (map-get? user-balances { user: user })
)

;; Get token balance
(define-read-only (get-token-balance (account principal))
  (ft-get-balance recycling-token account)
)

