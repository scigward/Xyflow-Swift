import Foundation

/// What `shallowNodeData` compares of a node: its id, its type and its data. The data of a node is
/// replaced or changed as a whole, which `dataRevision` tells.
public struct NodeDataSnapshot: Equatable {
    public var id: String
    public var type: String?
    public var dataRevision: Int
    /// the node the data belongs to, for what a revision alone cannot tell apart
    public var node: ObjectIdentifier

    public init(_ node: Node) {
        self.id = node.id
        self.type = node.type
        self.dataRevision = node.dataRevision
        self.node = ObjectIdentifier(node)
    }
}

public func shallowNodeData(_ a: [NodeDataSnapshot]?, _ b: [NodeDataSnapshot]?) -> Bool {
    guard let a, let b else {
        return false
    }

    if a.count != b.count {
        return false
    }

    for index in a.indices {
        if a[index] != b[index] {
            return false
        }
    }

    return true
}
