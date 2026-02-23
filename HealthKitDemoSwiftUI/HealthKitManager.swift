//
        //
    //  Project: HealthKitDemoSwiftUI
    //  File: HealthKitManager.swift
    //  Created by Noah Carpenter 
    //
    //  📺 YouTube: Noah Does Coding
    //  https://www.youtube.com/@NoahDoesCoding97
    //  Like and Subscribe for coding tutorials and fun! 💻✨
    //  Dream Big. Code Bigger 🚀
    //

    


//
//  HealthKitManager.swift
//  HealthDemo
//  Manages all HealthKit operations — authorization, reading, and writing
//

import Foundation
import HealthKit
import Observation

@Observable
class HealthKitManager {

    // MARK: - Properties

    // Single shared instance of HKHealthStore
    // Apple recommends creating only ONE per app
    let healthStore = HKHealthStore()

    // Step count displayed in the UI
    var stepCount: Int = 0

    // Authorization status message for UI feedback
    var authStatus: String = "Not requested"

    // MARK: - Authorization

    /// Requests HealthKit authorization for specific read and write types
    /// READ and WRITE permissions are handled SEPARATELY by the system
    /// The user sees a sheet with individual toggles for each data type
    func requestAuthorization() async {

        // Types we want to READ from HealthKit
        // Only request types your app actually uses
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount)           // Daily step count
        ]

        // Types we want to WRITE to HealthKit
        // User can deny write while allowing read (and vice versa)
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryWater)         // Water intake logging
        ]

        // Guard: HealthKit is NOT available on iPad
        // Always check before calling any HealthKit API
        guard HKHealthStore.isHealthDataAvailable() else {
            authStatus = "HealthKit not available on this device"
            return
        }

        do {
            // Present the system authorization sheet
            // IMPORTANT: The success/failure here only means the sheet was shown
            // It does NOT tell you if the user granted or denied access
            // Apple hides READ permission status for privacy reasons
            try await healthStore.requestAuthorization(
                toShare: writeTypes,
                read: readTypes
            )
            authStatus = "Authorization requested"
        } catch {
            authStatus = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Read Step Count

    /// Fetches today's total step count using HKStatisticsQueryDescriptor
    /// Uses .cumulativeSum to aggregate steps from all sources (iPhone, Watch, etc.)
    func fetchTodayStepCount() async {

        // Define the quantity type for steps
        let stepType = HKQuantityType(.stepCount)

        // Create a date predicate scoped to today
        // From midnight (start of day) to right now
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate  // Excludes samples that started before midnight
        )

        // Build the statistics query descriptor (modern async API)
        // .cumulativeSum adds up all step samples for the time range
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate<HKQuantitySample>.quantitySample(
                type: stepType,
                predicate: predicate
            ),
            options: .cumulativeSum
        )

        do {
            // Execute the query against the health store
            let result = try await descriptor.result(for: healthStore)

            // Extract the sum and convert to integer step count
            // .count() is the unit for step data
            if let sum = result?.sumQuantity() {
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                // Update UI on the main actor
                await MainActor.run {
                    self.stepCount = steps
                }
            }
        } catch {
            print("Step count query failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Write Water Intake

    /// Saves a water intake sample to HealthKit
    /// - Parameter milliliters: Amount of water consumed in milliliters
    /// Follows the standard write pattern: Type → Quantity → Sample → Save
    func logWaterIntake(milliliters: Double) async {

        // Define the quantity type for dietary water
        let waterType = HKQuantityType(.dietaryWater)

        // Create the quantity with milliliter units
        let quantity = HKQuantity(
            unit: .literUnit(with: .milli),
            doubleValue: milliliters
        )

        // Create a sample with start and end timestamps
        // For instantaneous events (like drinking water), both are the same
        // For duration events (like a workout), they would differ
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: Date(),
            end: Date()
        )

        do {
            // Save the sample to the encrypted health store
            try await healthStore.save(sample)
            print("Saved water intake: \(milliliters)ml")
        } catch {
            // Common failure: user denied write permission for this type
            print("Failed to save: \(error.localizedDescription)")
        }
    }

    // MARK: - Background Delivery

    /// Sets up an observer query to monitor new step count data
    /// Combined with enableBackgroundDelivery, this wakes the app
    /// when new step data is saved — even if the app is suspended
    /// Call this ONCE after authorization succeeds
    func startObservingStepCount() {

        let stepType = HKQuantityType(.stepCount)

        // Observer query watches for ANY new step data saved to HealthKit
        // Fires when iPhone, Apple Watch, or any connected source logs new steps
        let observerQuery = HKObserverQuery(
            sampleType: stepType,
            predicate: nil           // nil = all step data, no date filter
        ) { [weak self] query, completionHandler, error in

            if let error = error {
                print("Observer error: \(error.localizedDescription)")
                completionHandler()  // MUST call — even on error
                return
            }

            // New step data arrived — fetch the latest count
            Task {
                await self?.fetchTodayStepCount()
            }

            // CRITICAL: You MUST call the completion handler when done
            // Tells iOS your background work is finished
            // Failing to call this burns your background execution budget
            // and iOS will stop waking your app
            completionHandler()
        }

        // Execute the observer query — runs indefinitely until stopped
        healthStore.execute(observerQuery)

        // Enable background delivery — wakes the app when new data arrives
        // Frequency options: .immediate, .hourly, .daily
        // .hourly is the safest default — .immediate drains battery fast
        healthStore.enableBackgroundDelivery(
            for: stepType,
            frequency: .hourly
        ) { success, error in
            if success {
                print("Background delivery enabled for steps")
            } else if let error = error {
                print("Background delivery failed: \(error.localizedDescription)")
            }
        }
    }
}
