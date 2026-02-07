import AppKit
import SwiftUI

struct FlightFinderView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                configurationPane
                    .frame(minWidth: 470, maxWidth: 560)
                    .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                resultsPane
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
            }
            .navigationTitle("FlightFinder")
        }
    }

    private var configurationPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                routesSection
                searchOptionsSection
                providerKindsSection
                actionSection
            }
            .padding(20)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Agentic Flight Search")
                .font(.title2.weight(.semibold))
            Text("Compare airlines, metasearch, OTAs, and China portals for up to 3 routes in parallel.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var routesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Routes")
                    .font(.headline)
                Spacer()
                Button("Add Route") {
                    viewModel.addRoute()
                }
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

            Text("Simultaneous route limit: 3")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var searchOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Options")
                .font(.headline)

            Picker("Trip Type", selection: $viewModel.options.tripType) {
                ForEach(TripType.allCases) { trip in
                    Text(trip.rawValue).tag(trip)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isSearching)

            Picker("Site Access", selection: $viewModel.options.siteAccessMode) {
                ForEach(SiteAccessMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isSearching)

            if viewModel.options.siteAccessMode == .chinaAccessible {
                Text("China mode probes and learns reachable sites over time, then prioritizes the most reliable set.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Picker("Cabin", selection: $viewModel.options.cabinClass) {
                    ForEach(CabinClass.allCases) { cabin in
                        Text(cabin.rawValue).tag(cabin)
                    }
                }
                .disabled(viewModel.isSearching)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Currency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("USD", text: $viewModel.options.preferredCurrency)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .disabled(viewModel.isSearching)
                }
            }

            HStack {
                Stepper("Adults: \(viewModel.options.passengers.adults)", value: $viewModel.options.passengers.adults, in: 1...9)
                Stepper("Children: \(viewModel.options.passengers.children)", value: $viewModel.options.passengers.children, in: 0...6)
            }
            .disabled(viewModel.isSearching)

            HStack {
                Stepper("Infants: \(viewModel.options.passengers.infants)", value: $viewModel.options.passengers.infants, in: 0...4)
                Stepper("Checked Bags/Traveler: \(viewModel.options.bagPolicy.checkedBagsPerTraveler)", value: $viewModel.options.bagPolicy.checkedBagsPerTraveler, in: 0...3)
            }
            .disabled(viewModel.isSearching)

            HStack {
                Toggle("Carry-on Included", isOn: $viewModel.options.bagPolicy.carryOnIncluded)
                Toggle("Nonstop Only", isOn: $viewModel.options.nonStopOnly)
            }
            .disabled(viewModel.isSearching)

            HStack {
                Picker("Max Stops", selection: Binding(
                    get: { viewModel.options.maxStops ?? -1 },
                    set: { viewModel.options.maxStops = $0 < 0 ? nil : $0 }
                )) {
                    Text("Any").tag(-1)
                    Text("0").tag(0)
                    Text("1").tag(1)
                    Text("2").tag(2)
                }
                .frame(width: 120)
                .disabled(viewModel.isSearching)

                Stepper("Flexible Days: ±\(viewModel.options.flexibleDays)", value: $viewModel.options.flexibleDays, in: 0...7)
                    .disabled(viewModel.isSearching)
            }
        }
    }

    private var providerKindsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Provider Types")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(ProviderKind.allCases) { kind in
                    ToggleChip(
                        title: kind.rawValue,
                        isOn: viewModel.enabledKinds.contains(kind),
                        action: { viewModel.toggleKind(kind) }
                    )
                    .disabled(viewModel.isSearching)
                }
            }

            Text("Airline websites, metasearch engines, OTAs, and China-focused portals can all run in the same search.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    Task {
                        await viewModel.runSearch()
                    }
                } label: {
                    if viewModel.isSearching {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 18, height: 18)
                        Text("Searching...")
                    } else {
                        Text("Find Best Flights")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSearching)

                Button("Clear Results") {
                    viewModel.resetResults()
                }
                .disabled(viewModel.isSearching)
            }

            if let error = viewModel.searchError {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            if !viewModel.progressByRoute.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.progressByRoute.values.sorted(by: { $0.routeKey < $1.routeKey }), id: \.routeKey) { progress in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(progress.routeKey) • \(progress.providerName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ProgressView(value: progress.fraction)
                        }
                    }
                }
            }
        }
    }

    private var resultsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Results")
                    .font(.title3.weight(.semibold))

                if let session = viewModel.sessionResult {
                    if !session.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(session.warnings, id: \.self) { warning in
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    ForEach(session.routes) { routeResult in
                        RouteResultCard(routeResult: routeResult)
                    }
                } else {
                    Text("No search results yet.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
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
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if canRemove {
                    Button("Remove", role: .destructive, action: onRemove)
                        .disabled(isLocked)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Origin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("SFO", text: $route.origin)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Destination")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("PVG", text: $route.destination)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled(true)
                }
            }
            .disabled(isLocked)

            HStack {
                DatePicker("Departure", selection: $route.departureDate, displayedComponents: .date)
                    .disabled(isLocked)
                if tripType.requiresReturnDate {
                    DatePicker("Return", selection: $route.returnDate, in: route.departureDate..., displayedComponents: .date)
                        .disabled(isLocked)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ToggleChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundStyle(isOn ? .white : .primary)
                .background(isOn ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}

private struct RouteResultCard: View {
    let routeResult: RouteSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let route = routeResult.route
            let routeTitle = "\(route.origin) → \(route.destination)"
            let best = routeResult.bestOffer

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(routeTitle)
                        .font(.headline)
                    Text("\(DateFormatter.flightDate.string(from: route.departureDate))" +
                         (route.returnDate.map { " to \(DateFormatter.flightDate.string(from: $0))" } ?? ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let best, let price = best.totalPrice {
                    Text("Best: \(best.currencyCode) \(price, format: .number.precision(.fractionLength(0...2)))")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if routeResult.offers.isEmpty {
                Text("No offers found.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(routeResult.offers.prefix(15)) { offer in
                    OfferRow(offer: offer)
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct OfferRow: View {
    let offer: FlightOffer

    private var statusColor: Color {
        switch offer.status {
        case .priced:
            return .green
        case .handoffRequired:
            return .orange
        case .loginRequired:
            return .red
        case .unavailable:
            return .gray
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(offer.providerName)
                        .font(.subheadline.weight(.medium))
                    Text(offer.providerKind.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(statusText)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }

                HStack(spacing: 10) {
                    if let price = offer.totalPrice {
                        Text("\(offer.currencyCode) \(price, format: .number.precision(.fractionLength(0...2)))")
                            .font(.subheadline.weight(.semibold))
                    } else {
                        Text("Price unavailable")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let departure = offer.departureTime {
                        Text("Dep: \(departure)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let arrival = offer.arrivalTime {
                        Text("Arr: \(arrival)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let stops = offer.stops {
                        Text(stops == 0 ? "Nonstop" : "\(stops) stops")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(offer.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let reachability = offer.chinaReachabilityScore {
                    Text("China Reachability: \(Int(reachability * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Button("Open") {
                NSWorkspace.shared.open(offer.deepLink)
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
