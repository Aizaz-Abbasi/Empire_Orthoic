/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import Foundation
import StoreKit

// set TRUE if you want to use in-app subscriptions
// also these subscriptions are available only on >= 15.0 ios version
let USE_STOREKIT = false

public enum StoreError: Error {
  case failedVerification
}

struct StoreSubscription {
  let expiration: Date?
  let displayPrice: String
  let displayName: String
}

@available(iOS 15, *)
class StoreKitService {

  static let shared: StoreKitService = StoreKitService()

  private var updateListenerTask: Task<Void, Error>?

  private(set) var subscriptions: [StoreKit.Product]  = []

  @Published private(set) var currentSubscription: StoreSubscription?

  var enabled: Bool {
    return USE_STOREKIT
  }

  private let availableSubscriptionIdentifiers: [String] = [
    "com.occipital.3dfacescan.monthly",
    "com.occipital.3dfacescan.yearly"
  ]

  // Start a transaction listener as close to app launch as possible so you don't miss any transactions.
  private init() {

    updateListenerTask = listenForTransactions()

    Task {
      // Initialize the store by starting a product request.
      await requestProducts()
      await activeSubscription()
    }
  }

  func trialPeriodAvailable() async -> Bool {
    guard let product = subscriptions.first else {
      return false
    }
    return await product.subscription?.isEligibleForIntroOffer ?? false
  }

  @discardableResult
  @MainActor func activeSubscription() async -> StoreSubscription? {
    for await result in Transaction.currentEntitlements {
      if case let .verified(trans) = result {
        if let prod = subscriptions.first(where: { $0.id == trans.productID }) {
          currentSubscription = .init(expiration: trans.expirationDate, displayPrice: prod.displayPrice, displayName: prod.displayName)
          return currentSubscription
        }
      }
    }
    currentSubscription = nil
    return nil
  }

  @MainActor
  func requestProducts() async {
    do {
      // Request products from the App Store using the identifiers defined in the Products.plist file.
      let storeProducts = try await Product.products(for: availableSubscriptionIdentifiers)

      var newSubscriptions: [Product] = []

      // Filter the products into different categories based on their type.
      for product in storeProducts {
        switch product.type {
        case .autoRenewable:
          newSubscriptions.append( product )
        default:
          // Ignore this product.
          print("Unknown product")
        }
      }

      // Sort each product category by price, lowest to highest, to update the store.
      subscriptions = newSubscriptions

    } catch {
      print("Failed product request: \(error)")
    }
  }

  @MainActor
  func restorePurchase() async {
    try? await AppStore.sync()
    await activeSubscription()
  }

  @MainActor
  func purchase(_ product: Product) async throws -> Transaction? {
    // Begin a purchase.
    let result = try await product.purchase()

    switch result {
    case .success(let verification):
      let transaction = try checkVerified(verification)

      // Always finish a transaction.
      await transaction.finish()
      await self.activeSubscription()
      return transaction
    case .userCancelled, .pending:
      return nil
    default:
      return nil
    }
  }

  func listenForTransactions() -> Task<Void, Error> {
    return Task.detached {
      // Iterate through any transactions which didn't come from a direct call to `purchase()`.
      for await result in Transaction.updates {
        do {
          let transaction = try self.checkVerified(result)

          // Always finish a transaction.
          await transaction.finish()
        } catch {
          // StoreKit has a receipt it can read but it failed verification. Don't deliver content to the user.
          print("Transaction failed verification")
        }
      }
      await self.activeSubscription()
    }
  }

  func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    // Check if the transaction passes StoreKit verification.
    switch result {
    case .unverified:
      // StoreKit has parsed the JWS but failed verification. Don't deliver content to the user.
      throw StoreError.failedVerification
    case .verified(let safe):
      // If the transaction is verified, unwrap and return it.
      return safe
    }
  }

  deinit {
    updateListenerTask?.cancel()
  }
}
