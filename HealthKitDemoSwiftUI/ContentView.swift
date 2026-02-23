//
        //
    //  Project: HealthKitDemoSwiftUI
    //  File: ContentView.swift
    //  Created by Noah Carpenter 
    //
    //  📺 YouTube: Noah Does Coding
    //  https://www.youtube.com/@NoahDoesCoding97
    //  Like and Subscribe for coding tutorials and fun! 💻✨
    //  Dream Big. Code Bigger 🚀
    //

//  Simple interface to demonstrate HealthKit read and write operations
//

import SwiftUI

struct ContentView: View {
    // HealthKit manager — handles all health data operations
    @State private var manager = HealthKitManager()
    @State private var isRequestingAuth = false
    @State private var isRefreshingSteps = false
    @State private var isLoggingWater = false

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                Task { await manager.fetchTodayStepCount() }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            Button(role: .destructive) {
                                // Optional: add a reset action if app supports it
                            } label: {
                                Label("Reset Demo", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .imageScale(.large)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .accessibilityLabel("More options")
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                stepCard
                actions
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            // Subtle footer with auth status
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .symbolVariant(.fill)
                    .imageScale(.medium)
                Text(manager.authStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.thinMaterial)
        }
        .background(gradientBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HealthKit Demo")
                .font(.largeTitle.weight(.bold))
            Text("Read and write Health data securely")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var stepCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "figure.walk")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.tint)

                Text("\(manager.stepCount)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)

                Spacer()
            }

            HStack(spacing: 8) {
                Text("steps today")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    isRefreshingSteps = true
                    Task {
                        await manager.fetchTodayStepCount()
                        await MainActor.run { isRefreshingSteps = false }
                    }
                } label: {
                    Label("Refresh", systemImage: isRefreshingSteps ? "hourglass" : "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRefreshingSteps)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.2))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Steps today")
        .accessibilityValue("\(manager.stepCount)")
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                isRequestingAuth = true
                Task {
                    await manager.requestAuthorization()
                    await MainActor.run { isRequestingAuth = false }
                }
            } label: {
                Label(isRequestingAuth ? "Requesting…" : "Request Permissions", systemImage: isRequestingAuth ? "hourglass" : "checkmark.shield")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
            .disabled(isRequestingAuth)
            .accessibilityHint("Authorize Health permissions to enable reading and writing data")

            Button {
                isRefreshingSteps = true
                Task {
                    await manager.fetchTodayStepCount()
                    await MainActor.run { isRefreshingSteps = false }
                }
            } label: {
                Label(isRefreshingSteps ? "Refreshing…" : "Refresh Steps", systemImage: isRefreshingSteps ? "hourglass" : "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isRefreshingSteps)

            Button {
                isLoggingWater = true
                Task {
                    await manager.logWaterIntake(milliliters: 250)
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run { isLoggingWater = false }
                }
            } label: {
                Label(isLoggingWater ? "Logging…" : "Log Water (250ml)", systemImage: isLoggingWater ? "hourglass" : "drop.fill")
            }
            .buttonStyle(.bordered)
            .tint(.cyan)
            .controlSize(.large)
            .disabled(isLoggingWater)
        }
        .padding(.top, 8)
    }

    private var gradientBackground: some View {
        LinearGradient(colors: [
            Color.blue.opacity(0.10),
            Color.mint.opacity(0.08),
            Color.clear
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        .ignoresSafeArea()
    }

    private var statusIcon: String {
        switch manager.authStatus.lowercased() {
        case let s where s.contains("granted"):
            return "checkmark.shield"
        case let s where s.contains("denied"):
            return "xmark.shield"
        default:
            return "shield"
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
