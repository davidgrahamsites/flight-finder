import AppKit
import SwiftUI

struct FlightFinderView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                FlightFinderTheme.background
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    configurationPane
                        .frame(minWidth: 520, idealWidth: 560, maxWidth: 620)
                        .background(FlightFinderTheme.background)

                    Rectangle()
                        .fill(FlightFinderTheme.border)
                        .frame(width: 2)

                    resultsPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FlightFinderTheme.muted)
                }
            }
            .navigationTitle("FlightFinder")
        }
        .alert(
            "Login Required",
            isPresented: Binding(
                get: { viewModel.pendingLoginOffer != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissPendingLoginOffer()
                    }
                }
            )
        ) {
            Button("Cancel", role: .cancel) {
                viewModel.dismissPendingLoginOffer()
            }
            Button("Open Login Page") {
                viewModel.confirmLoginAndOpenPendingOffer()
            }
        } message: {
            Text(loginPromptMessage)
        }
    }

    private var configurationPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                heroSection
                presetsSection
                routesSection
                searchOptionsSection
                providerKindsSection
                actionSection
                watchlistSection
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(FlightFinderTheme.primary)

            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 140, height: 140)
                .offset(x: -28, y: -32)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.14))
                .frame(width: 132, height: 132)
                .rotationEffect(.degrees(20))
                .offset(x: 332, y: -38)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(FlightFinderTheme.secondary.opacity(0.22))
                .frame(width: 112, height: 70)
                .rotationEffect(.degrees(-10))
                .offset(x: 280, y: 122)

            VStack(alignment: .leading, spacing: 10) {
                Text("AGENTIC FLIGHT SEARCH")
                    .font(outfit(size: 12, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.95))

                Text("Compare Airlines + Aggregators in One Run")
                    .font(outfit(size: 30, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text("Three simultaneous routes, one-way or round-trip, with bag options and China-aware source selection.")
                    .font(outfit(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineSpacing(2)

                HStack(spacing: 10) {
                    heroPill(text: "3 routes", tint: FlightFinderTheme.accent)
                    heroPill(text: "No-shadow flat UI", tint: FlightFinderTheme.secondary)
                    heroPill(text: "Live progress", tint: .white.opacity(0.2), textColor: .white)
                }
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 255)
    }

    private func heroPill(text: String, tint: Color, textColor: Color = FlightFinderTheme.foreground) -> some View {
        Text(text.uppercased())
            .font(outfit(size: 11, weight: .semibold))
            .tracking(0.8)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(tint)
            .foregroundStyle(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
    }

    private var presetsSection: some View {
        PosterSection(
            title: "Search Presets",
            subtitle: "One-tap route templates optimized for domestic and USA→PVG runs.",
            background: FlightFinderTheme.muted
        ) {
            VStack(spacing: 10) {
                ForEach(SearchPreset.allCases) { preset in
                    Button {
                        viewModel.applyPreset(preset)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(preset.rawValue)
                                    .font(outfit(size: 15, weight: .bold))
                                Text(preset.subtitle)
                                    .font(outfit(size: 12, weight: .regular))
                                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.72))
                                    .lineLimit(2)
                            }

                            Spacer()

                            if viewModel.selectedPreset == preset {
                                Text("ACTIVE")
                                    .font(outfit(size: 10, weight: .semibold))
                                    .tracking(1.2)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 8)
                                    .background(FlightFinderTheme.primary)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(viewModel.selectedPreset == preset ? FlightFinderTheme.primary.opacity(0.14) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(viewModel.selectedPreset == preset ? FlightFinderTheme.primary : FlightFinderTheme.border, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSearching)
                }
            }
        }
    }

    private var routesSection: some View {
        PosterSection(
            title: "Routes",
            subtitle: "Configure up to three routes that will search in parallel.",
            background: .white
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Configured: \(viewModel.routes.count)/3")
                        .font(outfit(size: 12, weight: .semibold))
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.75))

                    Spacer()

                    Button("Add Route") {
                        viewModel.addRoute()
                    }
                    .buttonStyle(OutlinePosterButtonStyle(color: FlightFinderTheme.primary))
                    .disabled(viewModel.routes.count >= 3 || viewModel.isSearching)
                }

                ForEach($viewModel.routes) { $route in
                    RouteInputCard(
                        route: $route,
                        tripType: viewModel.options.tripType,
                        onRemove: { viewModel.removeRoute(id: route.id) },
                        canRemove: viewModel.routes.count > 1,
                        isLocked: viewModel.isSearching
                    )
                }
            }
        }
    }

    private var searchOptionsSection: some View {
        PosterSection(
            title: "Search Options",
            subtitle: "Trip, cabin, passenger, and bag preferences applied across all enabled providers.",
            background: Color(hex: 0xEFF6FF)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Trip Type")
                        .font(outfit(size: 12, weight: .semibold))
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.75))

                    Picker("Trip Type", selection: $viewModel.options.tripType) {
                        ForEach(TripType.allCases) { trip in
                            Text(trip.rawValue).tag(trip)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(FlightFinderTheme.primary)
                }
                .disabled(viewModel.isSearching)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Rank Results By")
                        .font(outfit(size: 12, weight: .semibold))
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.75))

                    Picker("Ranking Mode", selection: $viewModel.options.rankingMode) {
                        ForEach(OfferRankingMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(FlightFinderTheme.accent)
                }
                .disabled(viewModel.isSearching)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Site Access")
                        .font(outfit(size: 12, weight: .semibold))
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.75))

                    Picker("Site Access", selection: $viewModel.options.siteAccessMode) {
                        ForEach(SiteAccessMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(FlightFinderTheme.secondary)
                }
                .disabled(viewModel.isSearching)

                if viewModel.options.siteAccessMode == .chinaAccessible {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("China mode probes accessibility and updates reliability scores over time without calling any AI model.")
                            .font(outfit(size: 12, weight: .medium))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(FlightFinderTheme.secondary.opacity(0.15))
                            .foregroundStyle(FlightFinderTheme.foreground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("China Accessibility Snapshot")
                                    .font(outfit(size: 12, weight: .semibold))
                                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.75))

                                Spacer()

                                Button {
                                    Task {
                                        await viewModel.runChinaAccessibilitySweep()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if viewModel.isRunningChinaAccessibilitySweep {
                                            ProgressView()
                                                .controlSize(.small)
                                        }
                                        Text(viewModel.isRunningChinaAccessibilitySweep ? "Probing..." : "Probe Sites")
                                    }
                                }
                                .buttonStyle(OutlinePosterButtonStyle(color: FlightFinderTheme.secondary))
                                .disabled(viewModel.isRunningChinaAccessibilitySweep || viewModel.isSearching)
                            }

                            Toggle(
                                "Probe All Sites (ignore provider-type filter)",
                                isOn: Binding(
                                    get: { viewModel.chinaSweepIncludesAllProviders },
                                    set: { viewModel.setChinaSweepIncludesAllProviders($0) }
                                )
                            )
                            .font(outfit(size: 11, weight: .semibold))
                            .disabled(viewModel.isRunningChinaAccessibilitySweep || viewModel.isSearching)

                            if let summary = viewModel.chinaAccessSummary, !summary.isEmpty {
                                Text(summary)
                                    .font(outfit(size: 11, weight: .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(FlightFinderTheme.accent.opacity(0.16))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }

                            if viewModel.chinaAccessSnapshots.isEmpty {
                                Text("No reachability stats yet. Run a probe to learn which sites are reachable from China.")
                                    .font(outfit(size: 12, weight: .regular))
                                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(viewModel.chinaAccessSnapshots.prefix(8)) { snapshot in
                                        ChinaAccessibilityRow(snapshot: snapshot)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(FlightFinderTheme.border, lineWidth: 2)
                        )
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    LabeledPickerCard(title: "Cabin") {
                        Picker("Cabin", selection: $viewModel.options.cabinClass) {
                            ForEach(CabinClass.allCases) { cabin in
                                Text(cabin.rawValue).tag(cabin)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .disabled(viewModel.isSearching)

                    LabeledTextFieldCard(
                        title: "Currency",
                        text: $viewModel.options.preferredCurrency,
                        placeholder: "USD",
                        disabled: viewModel.isSearching
                    )
                }

                HStack(spacing: 10) {
                    Stepper("Adults: \(viewModel.options.passengers.adults)", value: $viewModel.options.passengers.adults, in: 1...9)
                    Stepper("Children: \(viewModel.options.passengers.children)", value: $viewModel.options.passengers.children, in: 0...6)
                }
                .disabled(viewModel.isSearching)
                .font(outfit(size: 13, weight: .medium))

                HStack(spacing: 10) {
                    Stepper("Infants: \(viewModel.options.passengers.infants)", value: $viewModel.options.passengers.infants, in: 0...4)
                    Stepper("Checked Bags: \(viewModel.options.bagPolicy.checkedBagsPerTraveler)", value: $viewModel.options.bagPolicy.checkedBagsPerTraveler, in: 0...3)
                }
                .disabled(viewModel.isSearching)
                .font(outfit(size: 13, weight: .medium))

                HStack(spacing: 12) {
                    Toggle("Carry-on Included", isOn: $viewModel.options.bagPolicy.carryOnIncluded)
                    Toggle("Nonstop Only", isOn: $viewModel.options.nonStopOnly)
                }
                .disabled(viewModel.isSearching)
                .font(outfit(size: 13, weight: .medium))

                HStack(spacing: 12) {
                    Picker(
                        "Max Stops",
                        selection: Binding(
                            get: { viewModel.options.maxStops ?? -1 },
                            set: { viewModel.options.maxStops = $0 < 0 ? nil : $0 }
                        )
                    ) {
                        Text("Any").tag(-1)
                        Text("0").tag(0)
                        Text("1").tag(1)
                        Text("2").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 190)

                    Stepper("Flexible Days: ±\(viewModel.options.flexibleDays)", value: $viewModel.options.flexibleDays, in: 0...7)
                        .font(outfit(size: 13, weight: .medium))
                }
                .disabled(viewModel.isSearching)
            }
        }
        .onChange(of: viewModel.options.siteAccessMode) { _, mode in
            guard mode == .chinaAccessible else { return }
            Task {
                await viewModel.refreshChinaAccessibilitySnapshot()
            }
        }
    }

    private var providerKindsSection: some View {
        PosterSection(
            title: "Provider Types",
            subtitle: "Mix airline websites with metasearch, OTA, and China portal sources in the same run.",
            background: Color(hex: 0xECFDF5)
        ) {
            HStack(spacing: 8) {
                ForEach(ProviderKind.allCases) { kind in
                    ToggleChip(
                        title: kind.rawValue,
                        isOn: viewModel.enabledKinds.contains(kind),
                        tint: color(for: kind),
                        action: { viewModel.toggleKind(kind) }
                    )
                    .disabled(viewModel.isSearching)
                }
            }
        }
    }

    private var actionSection: some View {
        PosterSection(
            title: "Run Search",
            subtitle: "Launch a concurrent comparison and rank by value, reliability, and route fit.",
            background: FlightFinderTheme.slate,
            foreground: .white
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await viewModel.runSearch()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSearching {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            }
                            Text(searchButtonTitle)
                                .font(outfit(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .buttonStyle(PrimaryPosterButtonStyle(color: FlightFinderTheme.primary))
                    .disabled(viewModel.isSearching)

                    Button("Save Defaults") {
                        viewModel.saveDefaults()
                    }
                    .buttonStyle(SecondaryPosterButtonStyle(background: .white.opacity(0.14), foreground: .white))
                    .disabled(viewModel.isSearching)

                    Button("Clear Results") {
                        viewModel.resetResults()
                    }
                    .buttonStyle(SecondaryPosterButtonStyle(background: .white.opacity(0.14), foreground: .white))
                    .disabled(viewModel.isSearching)
                }

                if let error = viewModel.searchError {
                    Text(error)
                        .font(outfit(size: 12, weight: .medium))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)
                        .background(Color.red.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                if !viewModel.progressByRoute.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(viewModel.progressByRoute.values.sorted(by: { $0.routeKey < $1.routeKey }), id: \.routeKey) { progress in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(progress.routeKey) • \(progress.providerName)")
                                    .font(outfit(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.88))
                                ProgressView(value: progress.fraction)
                                    .tint(FlightFinderTheme.accent)
                            }
                            .padding(10)
                            .background(.white.opacity(0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }

                if !viewModel.watchlistAlerts.isEmpty {
                    HStack(spacing: 10) {
                        Text("\(viewModel.watchlistAlerts.count) watchlist target hit\(viewModel.watchlistAlerts.count == 1 ? "" : "s") ready.")
                            .font(outfit(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))

                        Spacer()

                        Button("Clear Alerts") {
                            viewModel.clearWatchlistAlerts()
                        }
                        .buttonStyle(SecondaryPosterButtonStyle(background: .white.opacity(0.14), foreground: .white))
                    }
                }
            }
        }
    }

    private var watchlistSection: some View {
        PosterSection(
            title: "Watchlist",
            subtitle: "Persisted targets from best priced offers. Update automatically after each search.",
            background: Color(hex: 0xFFFBEB)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(
                        "Auto Re-check Watchlist",
                        isOn: Binding(
                            get: { viewModel.autoWatchlistRecheckEnabled },
                            set: { viewModel.setAutoWatchlistRecheckEnabled($0) }
                        )
                    )
                    .font(outfit(size: 13, weight: .semibold))
                    .disabled(viewModel.isSearching)

                    HStack(spacing: 10) {
                        Text("Interval")
                            .font(outfit(size: 12, weight: .semibold))
                            .foregroundStyle(FlightFinderTheme.foreground.opacity(0.72))

                        Picker(
                            "Interval",
                            selection: Binding(
                                get: { viewModel.autoWatchlistRecheckIntervalMinutes },
                                set: { viewModel.setAutoWatchlistRecheckIntervalMinutes($0) }
                            )
                        ) {
                            ForEach([5, 10, 15, 30, 45, 60, 90, 120, 180], id: \.self) { minutes in
                                Text("Every \(minutes)m").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(!viewModel.autoWatchlistRecheckEnabled || viewModel.isSearching)

                        Spacer()

                        Toggle(
                            "Desktop Alerts",
                            isOn: Binding(
                                get: { viewModel.watchlistNotificationsEnabled },
                                set: { viewModel.setWatchlistNotificationsEnabled($0) }
                            )
                        )
                        .font(outfit(size: 12, weight: .semibold))
                    }
                }
                .padding(10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(FlightFinderTheme.border, lineWidth: 2)
                )

                if let session = viewModel.sessionResult, !session.watchCandidates.isEmpty {
                    Button("Merge Latest Candidates (\(session.watchCandidates.count))") {
                        viewModel.mergeWatchCandidates(session.watchCandidates)
                    }
                    .buttonStyle(OutlinePosterButtonStyle(color: FlightFinderTheme.accent))
                }

                Button {
                    Task {
                        await viewModel.runWatchlistRecheck()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSearching {
                            ProgressView()
                                .controlSize(.small)
                                .tint(FlightFinderTheme.foreground)
                        }
                        Text("Re-check Watchlist")
                            .font(outfit(size: 13, weight: .bold))
                    }
                }
                .buttonStyle(OutlinePosterButtonStyle(color: FlightFinderTheme.secondary))
                .disabled(viewModel.watchlist.isEmpty || viewModel.isSearching)

                if let summary = viewModel.watchlistRecheckSummary, !summary.isEmpty {
                    Text(summary)
                        .font(outfit(size: 12, weight: .medium))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FlightFinderTheme.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                if viewModel.watchlist.isEmpty {
                    Text("No watchlist entries yet. Run a search and merge candidates from results.")
                        .font(outfit(size: 13, weight: .regular))
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.72))
                } else {
                    ForEach(viewModel.watchlist.prefix(20)) { candidate in
                        WatchlistRow(
                            candidate: candidate,
                            onOpen: { NSWorkspace.shared.open(candidate.deepLink) },
                            onRemove: { viewModel.removeWatchCandidate(id: candidate.id) }
                        )
                    }
                }
            }
        }
    }

    private var resultsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(FlightFinderTheme.secondary)

                    Circle()
                        .fill(.white.opacity(0.14))
                        .frame(width: 160, height: 160)
                        .offset(x: -30, y: -50)

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.18))
                        .frame(width: 140, height: 90)
                        .rotationEffect(.degrees(15))
                        .offset(x: 540, y: -24)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("RESULTS")
                            .font(outfit(size: 12, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.94))

                        Text(viewModel.sessionResult == nil ? "No search has been run yet" : "Best offers ranked and ready")
                            .font(outfit(size: 28, weight: .black))
                            .foregroundStyle(.white)

                        Text("Open any offer to complete booking directly on the provider website.")
                            .font(outfit(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .padding(20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 190)

                if !viewModel.watchlistAlerts.isEmpty {
                    PosterSection(
                        title: "Watchlist Alerts",
                        subtitle: "These providers are at or below your target threshold right now.",
                        background: Color(hex: 0xFEF3C7)
                    ) {
                        VStack(spacing: 8) {
                            ForEach(viewModel.watchlistAlerts.prefix(10)) { alert in
                                WatchlistAlertRow(
                                    alert: alert,
                                    onOpen: { NSWorkspace.shared.open(alert.deepLink) },
                                    onDismiss: { viewModel.dismissWatchlistAlert(id: alert.id) }
                                )
                            }
                        }
                    }
                }

                if let session = viewModel.sessionResult {
                    SessionObservabilityCard(session: session)
                    ResultsQuickStatsStrip(
                        session: session,
                        options: viewModel.options,
                        alertCount: viewModel.watchlistAlerts.count
                    )

                    PosterSection(
                        title: "Results View",
                        subtitle: "Filter by offer status and control row density per route.",
                        background: .white
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker(
                                "Status Filter",
                                selection: Binding(
                                    get: { viewModel.resultStatusFilter },
                                    set: { viewModel.setResultStatusFilter($0) }
                                )
                            ) {
                                ForEach(ResultStatusFilter.allCases) { filter in
                                    Text(filter.title).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack(spacing: 8) {
                                Text("Rows Per Route")
                                    .font(outfit(size: 12, weight: .semibold))
                                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.75))

                                Picker(
                                    "Rows Per Route",
                                    selection: Binding(
                                        get: { viewModel.resultMaxOffersPerRoute },
                                        set: { viewModel.setResultMaxOffersPerRoute($0) }
                                    )
                                ) {
                                    ForEach([5, 10, 15, 20, 25], id: \.self) { count in
                                        Text("\(count)").tag(count)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }

                    if !session.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(session.warnings, id: \.self) { warning in
                                Text(warning)
                                    .font(outfit(size: 12, weight: .medium))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(FlightFinderTheme.accent.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }

                    if !session.watchCandidates.isEmpty {
                        Text("\(session.watchCandidates.count) watch candidate\(session.watchCandidates.count == 1 ? "" : "s") generated from current best priced offers.")
                            .font(outfit(size: 12, weight: .medium))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(FlightFinderTheme.secondary.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    ForEach(session.routes) { routeResult in
                        let displayOffers = viewModel.displayOffers(for: routeResult)
                        RouteResultCard(
                            routeResult: routeResult,
                            offers: displayOffers,
                            onOfferOpen: { viewModel.handleOfferOpenRequest($0) }
                        )
                    }
                } else {
                    PosterSection(
                        title: "Awaiting First Run",
                        subtitle: "Configure routes, pick provider kinds, and launch a search to populate this panel.",
                        background: .white
                    ) {
                        Text("When results arrive, each route will show the best fare first, then alternate provider options below.")
                            .font(outfit(size: 13, weight: .regular))
                            .foregroundStyle(FlightFinderTheme.foreground.opacity(0.72))
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    private var searchButtonTitle: String {
        if viewModel.isSearching {
            return "Searching..."
        }
        return "Find \(viewModel.options.rankingMode.title) Flights"
    }

    private var loginPromptMessage: String {
        guard let offer = viewModel.pendingLoginOffer else {
            return "This provider requires login before booking."
        }
        return "\(offer.providerName) requires login or captcha verification. Open the provider site to continue booking."
    }

    private func color(for kind: ProviderKind) -> Color {
        switch kind {
        case .airline:
            return FlightFinderTheme.primary
        case .metasearch:
            return FlightFinderTheme.secondary
        case .ota:
            return FlightFinderTheme.accent
        case .chinaPortal:
            return FlightFinderTheme.slate
        }
    }

    private func outfit(size: CGFloat, weight: Font.Weight) -> Font {
        Font.custom("Outfit", size: size).weight(weight)
    }
}

private struct PosterSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let background: Color
    var foreground: Color = FlightFinderTheme.foreground
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.custom("Outfit", size: 20).weight(.black))
                    .foregroundStyle(foreground)

                if let subtitle {
                    Text(subtitle)
                        .font(Font.custom("Outfit", size: 13).weight(.regular))
                        .foregroundStyle(foreground.opacity(0.78))
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .hoverLift(1.004)
    }
}

private struct PrimaryPosterButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

private struct SecondaryPosterButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("Outfit", size: 12).weight(.semibold))
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

private struct OutlinePosterButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.custom("Outfit", size: 12).weight(.semibold))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .foregroundStyle(configuration.isPressed ? .white : color)
            .background(configuration.isPressed ? color : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color, lineWidth: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

private struct LabeledPickerCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(Font.custom("Outfit", size: 11).weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))

            content
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(FlightFinderTheme.border, lineWidth: 2)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LabeledTextFieldCard: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let disabled: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(Font.custom("Outfit", size: 11).weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Font.custom("Outfit", size: 13).weight(.medium))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isFocused ? FlightFinderTheme.primary : FlightFinderTheme.border, lineWidth: 2)
                )
                .focused($isFocused)
                .disabled(disabled)
        }
        .frame(width: 120, alignment: .leading)
    }
}

private struct RouteInputCard: View {
    @Binding var route: RouteInputState
    let tripType: TripType
    let onRemove: () -> Void
    let canRemove: Bool
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Route")
                    .font(Font.custom("Outfit", size: 14).weight(.bold))

                Spacer()

                if canRemove {
                    Button("Remove", role: .destructive, action: onRemove)
                        .buttonStyle(OutlinePosterButtonStyle(color: .red))
                        .disabled(isLocked)
                }
            }

            HStack(spacing: 10) {
                FlatTextInput(title: "Origin", placeholder: "SFO", text: $route.origin, disabled: isLocked)
                FlatTextInput(title: "Destination", placeholder: "PVG", text: $route.destination, disabled: isLocked)
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DEPARTURE")
                        .font(Font.custom("Outfit", size: 11).weight(.semibold))
                        .tracking(1.1)
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))

                    DatePicker("", selection: $route.departureDate, displayedComponents: .date)
                        .labelsHidden()
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FlightFinderTheme.muted)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                if tripType.requiresReturnDate {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RETURN")
                            .font(Font.custom("Outfit", size: 11).weight(.semibold))
                            .tracking(1.1)
                            .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))

                        DatePicker("", selection: $route.returnDate, in: route.departureDate..., displayedComponents: .date)
                            .labelsHidden()
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(FlightFinderTheme.muted)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .disabled(isLocked)
        }
        .padding(14)
        .background(FlightFinderTheme.muted)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct FlatTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let disabled: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(Font.custom("Outfit", size: 11).weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Font.custom("Outfit", size: 15).weight(.medium))
                .autocorrectionDisabled(true)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isFocused ? FlightFinderTheme.primary : FlightFinderTheme.border, lineWidth: 2)
                )
                .focused($isFocused)
                .disabled(disabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ToggleChip: View {
    let title: String
    let isOn: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Font.custom("Outfit", size: 12).weight(.semibold))
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .foregroundStyle(isOn ? .white : FlightFinderTheme.foreground)
                .background(isOn ? tint : .white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isOn ? tint : FlightFinderTheme.border, lineWidth: isOn ? 0 : 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ChinaAccessibilityRow: View {
    let snapshot: ChinaAccessibilityPlanner.ProviderSnapshot

    private var kindText: String {
        switch snapshot.providerKind {
        case .airline:
            return "Airline"
        case .metasearch:
            return "Metasearch"
        case .ota:
            return "OTA"
        case .chinaPortal:
            return "China Portal"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.providerName)
                    .font(Font.custom("Outfit", size: 12).weight(.semibold))

                Text("\(kindText) • checks: \(snapshot.totalChecks)")
                    .font(Font.custom("Outfit", size: 10).weight(.medium))
                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.65))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Score \(snapshot.blendedScore, format: .number.precision(.fractionLength(2)))")
                    .font(Font.custom("Outfit", size: 11).weight(.bold))
                Text("Success \(snapshot.successRate, format: .percent.precision(.fractionLength(0)))")
                    .font(Font.custom("Outfit", size: 10).weight(.medium))
                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.68))
            }
        }
        .padding(8)
        .background(FlightFinderTheme.muted)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct RouteResultCard: View {
    let routeResult: RouteSearchResult
    let offers: [FlightOffer]
    let onOfferOpen: (FlightOffer) -> Void

    private var title: String {
        "\(routeResult.route.origin) → \(routeResult.route.destination)"
    }

    private var dateLine: String {
        let outbound = DateFormatter.flightDate.string(from: routeResult.route.departureDate)
        if let returnDate = routeResult.route.returnDate {
            return "\(outbound) to \(DateFormatter.flightDate.string(from: returnDate))"
        }
        return outbound
    }

    var body: some View {
        PosterSection(
            title: title,
            subtitle: dateLine,
            background: .white
        ) {
            let observability = routeResult.observability

            HStack(spacing: 8) {
                ObservabilityChip(label: "Providers", value: "\(observability.providerAttempts)")
                ObservabilityChip(label: "Deduped", value: "\(observability.deduplicatedOffers)")
                ObservabilityChip(label: "Avg ms", value: "\(Int(observability.averageProviderLatencyMs.rounded()))")
                ObservabilityChip(label: "Audit", value: "\(routeResult.auditTrail.count)")
            }

            if let best = routeResult.bestOffer, let price = best.totalPrice {
                Text("Best: \(best.currencyCode) \(price, format: .number.precision(.fractionLength(0...2)))")
                    .font(Font.custom("Outfit", size: 15).weight(.black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(FlightFinderTheme.accent.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if offers.isEmpty {
                Text("No offers match the current filter.")
                    .font(Font.custom("Outfit", size: 13).weight(.regular))
                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.72))
            } else {
                VStack(spacing: 8) {
                    ForEach(offers) { offer in
                        OfferRow(
                            offer: offer,
                            onOpen: { onOfferOpen(offer) }
                        )
                    }
                }
            }
        }
        .hoverLift(1.006)
    }
}

private struct OfferRow: View {
    let offer: FlightOffer
    let onOpen: () -> Void

    private var statusColor: Color {
        switch offer.status {
        case .priced:
            return FlightFinderTheme.secondary
        case .handoffRequired:
            return FlightFinderTheme.accent
        case .loginRequired:
            return Color.red
        case .unavailable:
            return FlightFinderTheme.slate
        }
    }

    private var statusText: String {
        switch offer.status {
        case .priced: return "Priced"
        case .handoffRequired: return "Handoff"
        case .loginRequired: return "Login Needed"
        case .unavailable: return "Unavailable"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(offer.providerName)
                        .font(Font.custom("Outfit", size: 14).weight(.bold))

                    Text(offer.providerKind.rawValue)
                        .font(Font.custom("Outfit", size: 11).weight(.medium))
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.68))

                    Text(statusText)
                        .font(Font.custom("Outfit", size: 10).weight(.semibold))
                        .tracking(0.8)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 7)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
                }

                HStack(spacing: 10) {
                    if let price = offer.totalPrice {
                        Text("\(offer.currencyCode) \(price, format: .number.precision(.fractionLength(0...2)))")
                            .font(Font.custom("Outfit", size: 15).weight(.black))
                    } else {
                        Text("Price unavailable")
                            .font(Font.custom("Outfit", size: 13).weight(.medium))
                            .foregroundStyle(FlightFinderTheme.foreground.opacity(0.72))
                    }

                    if let stops = offer.stops {
                        Text(stops == 0 ? "Nonstop" : "\(stops) stops")
                            .font(Font.custom("Outfit", size: 12).weight(.medium))
                            .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))
                    }

                    if let departure = offer.departureTime {
                        Text("Dep: \(departure)")
                            .font(Font.custom("Outfit", size: 12).weight(.medium))
                            .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))
                    }
                }

                Text(offer.notes)
                    .font(Font.custom("Outfit", size: 12).weight(.regular))
                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.7))
                    .lineLimit(2)

                if let reachability = offer.chinaReachabilityScore {
                    Text("China Reachability: \(Int(reachability * 100))%")
                        .font(Font.custom("Outfit", size: 11).weight(.medium))
                        .foregroundStyle(FlightFinderTheme.foreground.opacity(0.68))
                }
            }

            Spacer(minLength: 0)

            Button("Open", action: onOpen)
            .buttonStyle(OutlinePosterButtonStyle(color: FlightFinderTheme.primary))
        }
        .padding(10)
        .background(FlightFinderTheme.muted)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .hoverLift(1.008)
    }
}

private struct SessionObservabilityCard: View {
    let session: SearchSessionResult

    var body: some View {
        let info = session.observability

        PosterSection(
            title: "Session Metrics",
            subtitle: "Live observability snapshot for provider attempts, dedupe, and outcomes.",
            background: .white
        ) {
            HStack(spacing: 8) {
                ObservabilityChip(label: "Routes", value: "\(info.routeCount)")
                ObservabilityChip(label: "Attempts", value: "\(info.providerAttempts)")
                ObservabilityChip(label: "Offers", value: "\(info.offersCollected)")
                ObservabilityChip(label: "Priced", value: "\(info.pricedOffers)")
                ObservabilityChip(label: "Deduped", value: "\(info.deduplicatedOffers)")
                ObservabilityChip(label: "Avg ms", value: "\(Int(info.averageProviderLatencyMs.rounded()))")
            }
        }
    }
}

private struct ObservabilityChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(Font.custom("Outfit", size: 10).weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(FlightFinderTheme.foreground.opacity(0.65))
            Text(value)
                .font(Font.custom("Outfit", size: 14).weight(.black))
                .foregroundStyle(FlightFinderTheme.foreground)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(FlightFinderTheme.muted)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct WatchlistRow: View {
    let candidate: WatchCandidate
    let onOpen: () -> Void
    let onRemove: () -> Void

    private var dropPercent: Double {
        guard candidate.observedPrice > 0 else { return 0 }
        return max(0, (candidate.observedPrice - candidate.targetPrice) / candidate.observedPrice)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(candidate.routeKey) • \(candidate.providerName)")
                    .font(Font.custom("Outfit", size: 13).weight(.bold))

                Text("Observed: \(candidate.currencyCode) \(candidate.observedPrice, format: .number.precision(.fractionLength(0...2)))  •  Target: \(candidate.currencyCode) \(candidate.targetPrice, format: .number.precision(.fractionLength(0...2)))")
                    .font(Font.custom("Outfit", size: 12).weight(.medium))
                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.72))

                Text("Target drop: \((dropPercent * 100), format: .number.precision(.fractionLength(0...1)))%")
                    .font(Font.custom("Outfit", size: 11).weight(.semibold))
                    .foregroundStyle(FlightFinderTheme.accent)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Button("Open", action: onOpen)
                    .buttonStyle(OutlinePosterButtonStyle(color: FlightFinderTheme.primary))

                Button("Remove", role: .destructive, action: onRemove)
                    .buttonStyle(OutlinePosterButtonStyle(color: .red))
            }
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(FlightFinderTheme.border, lineWidth: 2)
        )
        .hoverLift(1.008)
    }
}

private struct WatchlistAlertRow: View {
    let alert: WatchlistAlert
    let onOpen: () -> Void
    let onDismiss: () -> Void

    private var savedAmount: Double {
        max(0, alert.targetPrice - alert.observedPrice)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(alert.routeKey) • \(alert.providerName)")
                    .font(Font.custom("Outfit", size: 13).weight(.bold))

                Text("Hit: \(alert.currencyCode) \(alert.observedPrice, format: .number.precision(.fractionLength(0...2)))  •  Target: \(alert.currencyCode) \(alert.targetPrice, format: .number.precision(.fractionLength(0...2)))")
                    .font(Font.custom("Outfit", size: 12).weight(.medium))
                    .foregroundStyle(FlightFinderTheme.foreground.opacity(0.74))

                Text("Under target by \(alert.currencyCode) \(savedAmount, format: .number.precision(.fractionLength(0...2))) • \(alert.hitAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(Font.custom("Outfit", size: 11).weight(.semibold))
                    .foregroundStyle(FlightFinderTheme.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Button("Open", action: onOpen)
                    .buttonStyle(OutlinePosterButtonStyle(color: FlightFinderTheme.primary))

                Button("Dismiss", role: .destructive, action: onDismiss)
                    .buttonStyle(OutlinePosterButtonStyle(color: .red))
            }
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(FlightFinderTheme.border, lineWidth: 2)
        )
        .hoverLift(1.008)
    }
}

private struct ResultsQuickStatsStrip: View {
    let session: SearchSessionResult
    let options: FlightSearchOptions
    let alertCount: Int

    private var pricedOffers: [FlightOffer] {
        session.routes
            .flatMap(\.offers)
            .filter { $0.status == .priced && $0.totalPrice != nil }
    }

    private var bestFareText: String {
        guard
            let best = pricedOffers.min(by: { ($0.totalPrice ?? .greatestFiniteMagnitude) < ($1.totalPrice ?? .greatestFiniteMagnitude) }),
            let price = best.totalPrice
        else {
            return "N/A"
        }
        return "\(best.currencyCode) \(price.formatted(.number.precision(.fractionLength(0...2))))"
    }

    var body: some View {
        HStack(spacing: 8) {
            ResultsStatBlock(
                label: "Mode",
                value: options.rankingMode.title,
                background: FlightFinderTheme.primary.opacity(0.14),
                foreground: FlightFinderTheme.primary
            )
            ResultsStatBlock(
                label: "Best Fare",
                value: bestFareText,
                background: FlightFinderTheme.accent.opacity(0.18),
                foreground: FlightFinderTheme.foreground
            )
            ResultsStatBlock(
                label: "Priced",
                value: "\(pricedOffers.count)",
                background: FlightFinderTheme.secondary.opacity(0.16),
                foreground: FlightFinderTheme.secondary
            )
            ResultsStatBlock(
                label: "Alerts",
                value: "\(alertCount)",
                background: Color.red.opacity(0.14),
                foreground: Color.red
            )
        }
    }
}

private struct ResultsStatBlock: View {
    let label: String
    let value: String
    let background: Color
    let foreground: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(Font.custom("Outfit", size: 10).weight(.semibold))
                .tracking(0.9)
                .foregroundStyle(foreground.opacity(0.85))
            Text(value)
                .font(Font.custom("Outfit", size: 14).weight(.black))
                .foregroundStyle(FlightFinderTheme.foreground)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct HoverLiftModifier: ViewModifier {
    let scale: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1)
            .animation(.easeOut(duration: 0.18), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

private extension View {
    func hoverLift(_ scale: CGFloat = 1.006) -> some View {
        modifier(HoverLiftModifier(scale: scale))
    }
}
