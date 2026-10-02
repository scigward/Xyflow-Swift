import Foundation

public func getMarkerId(_ marker: EdgeMarkerType?, id: String? = nil) -> String {
    guard let marker else {
        return ""
    }

    switch marker {
    case .id(let markerId):
        return markerId
    case .marker(let value):
        let idPrefix = (id?.isEmpty ?? true) ? "" : "\(id!)__"

        var pairs: [(String, String)] = []
        if let color = value.color { pairs.append(("color", color)) }
        if let height = value.height { pairs.append(("height", formatNumber(height))) }
        if let markerUnits = value.markerUnits { pairs.append(("markerUnits", markerUnits)) }
        if let orient = value.orient { pairs.append(("orient", orient)) }
        if let strokeWidth = value.strokeWidth { pairs.append(("strokeWidth", formatNumber(strokeWidth))) }
        pairs.append(("type", value.type.rawValue))
        if let width = value.width { pairs.append(("width", formatNumber(width))) }

        return idPrefix + pairs.sorted { $0.0 < $1.0 }.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
    }
}

public func createMarkerIds(
    _ edges: [Edge],
    id: String? = nil,
    defaultColor: String? = nil,
    defaultMarkerStart: EdgeMarkerType? = nil,
    defaultMarkerEnd: EdgeMarkerType? = nil
) -> [MarkerProps] {
    var ids = Set<String>()
    var markers: [MarkerProps] = []

    for edge in edges {
        for marker in [edge.markerStart ?? defaultMarkerStart, edge.markerEnd ?? defaultMarkerEnd] {
            if case .marker(var value)? = marker {
                let markerId = getMarkerId(marker, id: id)
                if !ids.contains(markerId) {
                    value.color = value.color ?? defaultColor
                    markers.append(MarkerProps(id: markerId, marker: value))
                    ids.insert(markerId)
                }
            }
        }
    }

    return markers.sorted { $0.id.localizedCompare($1.id) == .orderedAscending }
}
